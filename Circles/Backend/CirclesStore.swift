//
//  CirclesStore.swift
//  Circles
//
//  Created by Charles Wright on 6/7/22.
//

import Foundation
import os
import StoreKit
import LocalAuthentication


import CryptoKit
import IDZSwiftCommonCrypto
import KeychainAccess
import BlindSaltSpeke
import Matrix


public class CirclesStore: ObservableObject {
    
    enum State {
        case starting
        case nothing(CirclesError?)
        case signingUp(SignupSession)
        case loggingInUIA(UiaLoginSession)          // Because /login can now take more than a simple username/password
        case loggingInNonUIA(LegacyLoginSession)    // For accounts without fancy swiclops authentication
        case haveCreds(Matrix.Credentials)
        case needSSKey(Matrix.Session,String,KeyDescriptionContent)
        case settingUp(SetupSession)
        case online(CirclesApplicationSession)
    }
    @Published var state: State
    
    var logger: os.Logger
    
    // MARK: init
    
    init() {
        self.logger = Logger(subsystem: "Circles", category: "Store")
        
        // Ok, we're just starting out
        self.state = .starting

        // We can realistically be in one of just two states.
        // Either:
        // .haveCreds - if we can find credentials in the user defaults
        // or
        // .nothing - if there are no creds to be found

        let _ = Task {
            guard let creds = loadCredentials()
            else {
                // Apparently we're offline, waiting for (valid) credentials to log in
                logger.info("Didn't find valid login credentials - Setting state to .nothing")
                await MainActor.run {
                    self.state = .nothing(nil)
                }
                return
            }
                     
            // Woo we have credentials
            await MainActor.run {
                self.state = .haveCreds(creds)
            }
            
            // Don't connect yet.  Let the UI call connect() on its own.
        }
    }
    
    // MARK: Sync tokens
    
    private func loadSyncToken(userId: UserId, deviceId: String) -> String? {
        UserDefaults.standard.string(forKey: "sync_token[\(userId)::\(deviceId)]")
    }
    
    private func saveSyncToken(token: String, userId: UserId, deviceId: String) {
        UserDefaults.standard.set(token, forKey: "sync_token[\(userId)::\(deviceId)]")
    }
    
    // MARK: Credentials
    
    private func loadCredentials(_ user: String? = nil) -> Matrix.Credentials? {
        
        guard let uid = user ?? UserDefaults.standard.string(forKey: "user_id"),
              let userId = UserId(uid)
        else {
            return nil
        }
        guard let deviceId = UserDefaults.standard.string(forKey: "device_id[\(userId)]"),
              let accessToken = UserDefaults.standard.string(forKey: "access_token[\(userId)]")
        else {
            return nil
        }
        
        return Matrix.Credentials(userId: userId,
                                  accessToken: accessToken,
                                  deviceId: deviceId)
    }
    
    private func saveCredentials(creds: Matrix.Credentials) {
        UserDefaults.standard.set("\(creds.userId)", forKey: "user_id")
        UserDefaults.standard.set(creds.deviceId, forKey: "device_id[\(creds.userId)]")
        UserDefaults.standard.set(creds.accessToken, forKey: "access_token[\(creds.userId)]")
    }
    
    private func saveS4Key(key: Data, keyId: String, for userId: UserId) async throws {
        UserDefaults.standard.set(keyId, forKey: "bsspeke_ssss_keyid[\(userId)]")
        
        let keychainStore = Matrix.KeychainSecretStore(userId: userId)
        try await keychainStore.saveKey(key: key, keyId: keyId)
    }
    
    // MARK: Load Config
    
    private func loadConfig(matrix: Matrix.Session) async throws -> CirclesConfigContent? {
        Matrix.logger.debug("Loading Circles configuration")
        // Easy mode: Do we have our config saved in the Account Data?
        if let config = try await matrix.getAccountData(for: EVENT_TYPE_CIRCLES_CONFIG, of: CirclesConfigContent.self) {
            Matrix.logger.debug("Found Circles config in the account data")
            return config
        }
        
        Matrix.logger.debug("No Circles config in account data.  Looking for rooms based on tags...")
        
        // Not so easy mode: Do we have a room with our special tag?
        var tags = [RoomId: [String]]()
        let roomIds = try await matrix.getJoinedRoomIds()
        for roomId in roomIds {
            tags[roomId] = try await matrix.getTags(roomId: roomId)
            Matrix.logger.debug("\(roomId): \(tags[roomId]?.joined(separator: " ") ?? "(none)")")
        }
        
        guard let rootId: RoomId = roomIds.filter({
            if let t = tags[$0] {
                return t.contains(ROOM_TAG_CIRCLES_SPACE_ROOT)
            } else {
                return false
            }
        }).first
        else {
            Matrix.logger.error("Couldn't find Circles space root")
            throw CirclesError("Failed to find Circles space root")
        }
        Matrix.logger.debug("Found Circles space root \(rootId)")
        
        let childRoomIds = try await matrix.getSpaceChildren(rootId)
        
        guard let circlesId: RoomId = childRoomIds.filter({
                if let t = tags[$0] {
                    return t.contains(ROOM_TAG_MY_CIRCLES)
                } else {
                    return false
                }
            }).first
        else {
            Matrix.logger.error("Failed to find circles space")
            throw CirclesError("Failed to find circles space")
        }
        Matrix.logger.debug("Found circles space \(circlesId)")
                    
        guard let groupsId: RoomId = childRoomIds.filter({
                if let t = tags[$0] {
                    return t.contains(ROOM_TAG_MY_GROUPS)
                } else {
                    return false
                }
            }).first
        else {
            Matrix.logger.error("Failed to find groups space")
            throw CirclesError("Failed to find groups space")
        }
        Matrix.logger.debug("Found groups space \(groupsId)")
        
        guard let photosId: RoomId = childRoomIds.filter({
                if let t = tags[$0] {
                    return t.contains(ROOM_TAG_MY_PHOTOS)
                } else {
                    return false
                }
            }).first
        else {
            Matrix.logger.error("Failed to find photos space")
            throw CirclesError("Failed to find photos space")
        }
        Matrix.logger.debug("Found photos space \(photosId)")
        
        // People and Profile space are a bit different - They might not exist in previous Circles Android versions
        // So if we don't find them, it's ok.  Just create them now.
        
        func getSpaceId(tag: String, name: String) async throws -> RoomId {
            if let existingProfileSpaceId = childRoomIds.filter({
                    if let t = tags[$0] {
                        return t.contains(tag)
                    } else {
                        return false
                    }
            }).first {
                Matrix.logger.debug("Found space \(existingProfileSpaceId) with tag \(tag)")
                return existingProfileSpaceId
            }
            else {
                let newProfileSpaceId = try await matrix.createSpace(name: name)
                try await matrix.addTag(roomId: newProfileSpaceId, tag: tag)
                try await matrix.addSpaceChild(newProfileSpaceId, to: rootId)
                return newProfileSpaceId
            }
        }
        
        let displayName = try await matrix.getDisplayName(userId: matrix.creds.userId) ?? matrix.creds.userId.stringValue
        let profileId = try await getSpaceId(tag: ROOM_TAG_MY_PROFILE, name: displayName)
        let peopleId = try await getSpaceId(tag: ROOM_TAG_MY_PEOPLE, name: "My People")
        
        let config = CirclesConfigContent(root: rootId,
                                          circles: circlesId,
                                          groups: groupsId,
                                          galleries: photosId,
                                          people: peopleId,
                                          profile: profileId)
        // Also save this config for future use
        try await matrix.putAccountData(config, for: EVENT_TYPE_CIRCLES_CONFIG)
        
        return config
    }
    
    // MARK: Connect
    
    func connect(creds: Matrix.Credentials, s4Key: Matrix.SecretStorageKey? = nil) async throws {
        logger.debug("connect()")
        let token = loadSyncToken(userId: creds.userId, deviceId: creds.deviceId)
        logger.debug("Got token = \(token ?? "none")")
        
        if let key = s4Key {
            logger.debug("Connecting with s4 keyId [\(key.keyId)]")
        } else {
            logger.debug("No s4 key / keyId")
        }
        
        guard let matrix = try? await Matrix.Session(creds: creds,
                                                     syncToken: token,
                                                     startSyncing: false,
                                                     secretStorageKey: s4Key)
        else {
            logger.error("Failed to initialize Matrix session")
            let error = CirclesError("Failed to initialize Matrix session")
            await MainActor.run {
                self.state = .nothing(error)
            }
            throw error
        }
        
        guard let ssss = matrix.secretStore
        else {
            logger.warning("Matrix session needs secret storage")
            let error = CirclesError("Matrix session has no secret storage")
            await MainActor.run {
                self.state = .nothing(error)
            }
            throw error
        }
        
        switch ssss.state {
            
        case .online(let defaultKeyId):
            logger.debug("Matrix secret storage is online")

            // Ok great we are connected to the Matrix account, and we have a valid Secret Storage key
            
            // Next thing to check: Do we have a Circles space hierarchy in this account?
            if let config = try? await loadConfig(matrix: matrix) {
                // Awesome - Everything should be good to go, so let's get it started
                try await launch(matrix: matrix, config: config)
                return
            } else {
                // Looks like we haven't configured Circles on this account yet
                let setupSession = SetupSession(matrix: matrix)
                await MainActor.run {
                    self.state = .settingUp(setupSession)
                }
                return
            }

            
        case .error(let msg):
            logger.error("Matrix secret storage failed: \(msg, privacy: .public)")
            let error = CirclesError("Matrix secret storage failed")
            await MainActor.run {
                self.state = .nothing(error)
            }
            throw error
            
        case .uninitialized:
            logger.error("Matrix secret storage did not initialize")
            let error = CirclesError("Matrix secret storage did not initialize")
            await MainActor.run {
                self.state = .nothing(error)
            }
            throw error
            
        case .needKey(let keyId, let keyDescription):
            logger.info("Matrix secret storage needs a key")
            await MainActor.run {
                self.state = .needSSKey(matrix, keyId, keyDescription)
            }
            return
        }
    }

    // MARK: Add missing SSSS key
    
    func addMissingKey(key: Matrix.SecretStorageKey) async throws {
        
        guard case .needSSKey(let matrix, let needKeyId, let description) = self.state
        else {
            logger.error("Can't finish connecting unless we're waiting on a secret storage key")
            throw CirclesError("Can't finish connecting unless we're waiting on a secret storage key")
        }
        
        guard key.keyId == needKeyId
        else {
            logger.error("This is not the secret storage key that we're looking for")
            throw CirclesError("This is not the secret storage key that we're looking for")
        }
        
        guard let ssss = matrix.secretStore
        else {
            logger.error("Can't go online without secret storage")
            throw CirclesError("Can't go online without secret storage")
        }
        
        // Add our new secret storage key
        try await ssss.addNewSecretStorageKey(key)
        
        guard case .online(let defaultKeyId) = ssss.state
        else {
            logger.error("Secret storage is still not online")
            throw CirclesError("Secret storage is still not online")
        }
        
        // Yay we're online with secret storage
        // Make sure that our Matrix session has cross-signing and encrypted key backup enabled
        try await matrix.setupCrossSigning()
        try await matrix.setupKeyBackup()
        
        guard let config = try? await loadConfig(matrix: matrix)
        else {
            let setupSession = SetupSession(matrix: matrix)
            await MainActor.run {
                self.state = .settingUp(setupSession)
            }
            return
        }
        
        try await launch(matrix: matrix, config: config)
    }
    
    // MARK: Generate S4 key
    
    private func generateS4Key(bsspeke: BlindSaltSpeke.ClientSession) throws -> Matrix.SecretStorageKey {
        let key = Data(bsspeke.generateHashedKey(label: MATRIX_SSSS_KEY_LABEL))
        
        let keyId = bsspeke.generateHashedKey(label: MATRIX_SSSS_KEYID_LABEL)
                        .prefix(16)
                        .map {
                            String(format: "%02hhx", $0)
                        }
                        .joined()
        
        let description = try Matrix.SecretStore.generateKeyDescription(key: key, keyId: keyId, passphrase: .init(algorithm: ORG_FUTO_BSSPEKE_ECC))
        
        let s4Key = Matrix.SecretStorageKey(key: key, keyId: keyId, description: description)
        
        return s4Key
    }
    
    // MARK: Launch
    func launch(matrix: Matrix.Session, config: CirclesConfigContent) async throws {
        guard let session = try? await CirclesApplicationSession(matrix: matrix, config: config)
        else {
            // If anything went wrong here, we don't know what it was
            // Fail and give up :(
            let error = CirclesError("Failed to establish Circles application session for \(matrix.creds.userId)")
            await MainActor.run {
                self.state = .nothing(error)
            }
            throw error
        }
        logger.debug("Set up Matrix and Circles application session")
        
        await MainActor.run {
            self.state = .online(session)
        }
        logger.debug("Set state to .online")
    }
    
    // MARK: Login
    
    func login(userId: UserId) async throws {
        logger.debug("Logging in as \(userId)")
        
        // First - Check to see if we already have a device_id and access_token for this user
        //         e.g. maybe they didn't log out, but only "switched"
        if let creds = loadCredentials(userId.stringValue) {
            logger.debug("Found saved credentials for \(userId)")
            
            // Save the full credentials including the userId, so we can automatically connect next time
            self.saveCredentials(creds: creds)
            try await self.connect(creds: creds)
            return
        }
        
        // Second - Check wether the server supports UIA on /login
        guard let wellKnown = try? await Matrix.fetchWellKnown(for: userId.domain),
              let serverURL = URL(string: wellKnown.homeserver.baseUrl)
        else {
            logger.error("Failed to look up a valid homeserver URL for domain \(userId.domain)")
            throw CirclesError("Failed to look up well known")
        }
        
        let doUIA = try await Matrix.checkForUiaLogin(homeserver: serverURL)
        
        if doUIA {
            // Start the User-Interactive Auth with a LoginSession
            let loginSession = try await UiaLoginSession(userId: userId, completion: { session, data in
                self.logger.debug("Login was successful")
                
                let decoder = JSONDecoder()
                guard let creds = try? decoder.decode(Matrix.Credentials.self, from: data)
                else {
                    self.logger.error("Failed to decode credentials")
                    await MainActor.run {
                        self.state = .nothing(CirclesError("Failed to decode credentials"))
                    }
                    return
                }
                self.saveCredentials(creds: creds)
                //try await self.connect(creds: creds)
                
                // Check for a BS-SPEKE session, and if we have one, use it to generate our SSSS key
                if let bsspeke = session.getBSSpekeClient() {
                    self.logger.debug("Got BS-SPEKE client")
                    let s4Key = try self.generateS4Key(bsspeke: bsspeke)
                    self.logger.debug("BS-SPEKE key: id = \(s4Key.keyId), key = \(s4Key.key.base64EncodedString())")
                    
                    // Save the keys into our device Keychain, so they will be available to future Matrix sessions where we load creds and connect, without logging in
                    let store = Matrix.KeychainSecretStore(userId: creds.userId)
                    try await store.saveKey(key: s4Key.key, keyId: s4Key.keyId)
                    
                    self.logger.debug("Connecting with keyId [\(s4Key.keyId)]")
                    try await self.connect(creds: creds, s4Key: s4Key)
                } else {
                    self.logger.warning("Could not find BS-SPEKE client")
                    try await self.connect(creds: creds)
                }
            })
            await MainActor.run {
                self.state = .loggingInUIA(loginSession)
            }
            
        } else {
            // No UIA
            
            let loginSession = LegacyLoginSession(userId: userId, 
                                                  completion: { creds in
                                                        self.saveCredentials(creds: creds)
                                                        try await self.connect(creds: creds)
                                                    },
                                                  cancellation: {
                                                        await MainActor.run {
                                                            self.state = .nothing(nil)
                                                        }
                                                    })
            
            await MainActor.run {
                self.state = .loggingInNonUIA(loginSession)
            }
        }
    }
    
    // MARK: Signup
    
    func signup(domain: String) async throws {
        // We only support signing up on our own servers
        // Look at the country code of the user's StoreKit storefront to decide which server we should use
        // Create a SignupSession and set our state to .signingUp
        
        let deviceModel = await UIDevice.current.model
        let signupSession = try await SignupSession(domain: domain, initialDeviceDisplayName: "Circles (\(deviceModel))", completion: { session,data in
            self.logger.debug("Signup was successful")
            
            let decoder = JSONDecoder()
            guard let creds = try? decoder.decode(Matrix.Credentials.self, from: data)
            else {
                self.logger.error("Failed to decode credentials")
                await MainActor.run {
                    self.state = .nothing(CirclesError("Failed to decode credentials"))
                }
                return
            }
            self.saveCredentials(creds: creds)
            
            // Check for a BS-SPEKE session, and if we have one, use it to generate our SSSS key
            if let bsspeke = session.getBSSpekeClient() {
                self.logger.debug("Got BS-SPEKE client")
                let s4Key = try self.generateS4Key(bsspeke: bsspeke)
                self.logger.debug("BS-SPEKE key: id = \(s4Key.keyId), key = \(s4Key.key.base64EncodedString())")

                // Save the keys into our device Keychain, so they will be available to future Matrix sessions where we load creds and connect, without logging in
                let store = Matrix.KeychainSecretStore(userId: creds.userId)
                try await store.saveKey(key: s4Key.key, keyId: s4Key.keyId)

                self.logger.debug("Configuring with keyId [\(s4Key.keyId)]")
                try await self.beginSetup(creds: creds)
            } else {
                self.logger.warning("Could not find BS-SPEKE client")
            }
        })
        await MainActor.run {
            self.state = .signingUp(signupSession)
        }
    }
    
    // MARK: Begin setup
    
    func beginSetup(creds: Matrix.Credentials) async throws {
        
        var fullCreds = creds
        
        if fullCreds.wellKnown == nil {
            let domain = creds.userId.domain
            fullCreds.wellKnown = try await Matrix.fetchWellKnown(for: domain)
        }
        
        let session = try await SetupSession(creds: fullCreds)
        await MainActor.run {
            self.state = .settingUp(session)
        }
    }
    
    // MARK: Remove credentials
    
    public func removeCredentials(for userId: UserId) {
        UserDefaults.standard.removeObject(forKey: "user_id")
        UserDefaults.standard.removeObject(forKey: "device_id[\(userId)]")
        UserDefaults.standard.removeObject(forKey: "access_token[\(userId)]")
    }
    
    // MARK: Logout
    
    func logout() async throws {
        switch state {
        case .online(let session):
            let creds = session.matrix.creds
            logger.info("Logging out active session for \(creds.userId)")
            //try await disconnect()
            try await session.matrix.logout()
            removeCredentials(for: creds.userId)
            await MainActor.run {
                self.state = .nothing(nil)
            }
            
        case .haveCreds(let creds):
            logger.info("Logging out offline session for \(creds.userId)")
            if let client = try? await Matrix.Client(creds: creds) {
                try await client.logout()
            }
            removeCredentials(for: creds.userId)
            await MainActor.run {
                self.state = .nothing(nil)
            }
            
        case .needSSKey(let matrix, let keyId, let keyDescription):
            logger.info("Logging out of session that was blocked waiting for keys")
            let creds = matrix.creds
            try await matrix.logout()
            removeCredentials(for: creds.userId)
            await MainActor.run {
                self.state = .nothing(nil)
            }
            
        case .settingUp(let session):
            let client = session.client
            let creds = session.client.creds
            
            try await client.logout()
            removeCredentials(for: creds.userId)

            await MainActor.run {
                self.state = .nothing(nil)
            }
            
        default:
            logger.warning("Can't log out because we are not online")
        }
    }
    
    // MARK: Disconnect
    
    func disconnect() async throws {
        // First disconnect any connected session
        if case let .online(session) = self.state {
            try await session.close()
        }
        // Then set our state to .nothing
        await MainActor.run {
            self.state = .nothing(nil)
        }
    }
    
    // MARK: Soft logout
    
    func softLogout() async throws {
        // If we are online, we must first disconnect
        try await self.disconnect()
       
        // Remove the setting that marks this account as the one to automatically log in
        UserDefaults.standard.removeObject(forKey: "user_id")
        // However, don't remove the device_id or access_token - That's what makes this a "soft" logout
    }
    
    // MARK: Deactivate
    
    func deactivate() async throws {
        guard case let .online(session) = self.state
        else {
            logger.error("Can't deactivate unless we have an active session")
            throw CirclesError("Can't deactivate unless we have an active session")
        }
        
        let creds = session.matrix.creds
        try await session.matrix.deactivateAccount() { (uia, data) in
            try await self.disconnect()
            self.removeCredentials(for: creds.userId)
        }
    }
    
    // MARK: Domain handling

    private var ourDomains = [
        usDomain,
        euDomain,
    ]
    
    public var countryCode: String? {
        SKPaymentQueue.default().storefront?.countryCode
    }
    
    public var defaultDomain: String {
        if let code = countryCode {
            return getOurDomain(countryCode: code)
        } else {
            return CIRCLES_PRIMARY_DOMAIN
        }
    }
    
    public func getOurDomain(countryCode: String) -> String {

        switch countryCode {
        case "USA":
            return usDomain

        // EU Countries
        case "AUT", // Austria
             "BEL", // Belgium
             "BGR", // Bulgaria
             "HRV", // Croatia
             "CYP", // Cyprus
             "CZE", // Czech
             "DNK", // Denmark
             "EST", // Estonia
             "FIN", // Finland
             "FRA", // France
             "DEU", // Germany
             "GRC", // Greece
             "HUN", // Hungary
             "IRL", // Ireland
             "ITA", // Italy
             "LVA", // Latvia
             "LTU", // Lithuania
             "LUX", // Luxembourg
             "MLT", // Malta
             "NLD", // Netherlands
             "POL", // Poland
             "PRT", // Portugal
             "ROU", // Romania
             "SVK", // Slovakia
             "ESP", // Spain
             "SWE"  // Sweden
            :
            return euDomain

        // EEA Countries
        case "ISL", // Iceland
             "LIE", // Liechtenstein
             "NOR"  // Norway
            :
            return euDomain

        // Other European-region countries
        case "ALB", // Albania
             "AND", // Andorra
             "ARM", // Armenia
             "BLR", // Belarus
             "BIH", // Bosnia and Herzegovina
             "GEO", // Georgia
             "MDA", // Moldova
             "MCO", // Monaco
             "MNE", // Montenegro
             "MKD", // North Macedonia
             "SMR", // San Marino
             "SRB", // Serbia
             "SVN", // Slovenia
             "CHE", // Switzerland
             "TUR", // Turkey
             "UKR", // Ukraine
             "GBR", // UK
             "VAT"  // Holy See
            :
            return euDomain

        // Everybody else uses the US server
        default:
            return usDomain
        }
    }
    
}
