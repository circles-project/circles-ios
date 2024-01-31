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
        case startingUp
        case error(CirclesError)
        case needCreds
        case signingUp(SignupSession)
        case loggingInUIA(UiaLoginSession)          // Because /login can now take more than a simple username/password
        case loggingInNonUIA(LegacyLoginSession)    // For accounts without fancy swiclops authentication
        case haveCreds(Matrix.Credentials, Matrix.SecretStorageKey?, String?)
        case needSecretStorage(Matrix.Session)
        case needSecretStorageKey(Matrix.Session, String, KeyDescriptionContent)
        case haveSecretStorageAndKey(Matrix.Session)
        case haveCrossSigning(Matrix.Session)
        case haveKeyBackup(Matrix.Session)
        case needSpaceHierarchy(Matrix.Session)
        case haveSpaceHierarchy(Matrix.Session, CirclesConfigContent)
        case online(CirclesApplicationSession)
    }
    @Published var state: State
    var appStore: AppStoreInterface
    
    var logger: os.Logger
    
    // MARK: init
    
    init() {
        self.logger = Logger(subsystem: "Circles", category: "Store")
        
        self.appStore = AppStoreInterface()
        
        // Ok, we're just starting out
        self.state = .startingUp
    }
    
    // MARK: Sync tokens
    
    private func loadSyncToken(userId: UserId, deviceId: String) -> String? {
        UserDefaults.standard.string(forKey: "sync_token[\(userId)::\(deviceId)]")
    }
    
    private func saveSyncToken(token: String, userId: UserId, deviceId: String) {
        UserDefaults.standard.set(token, forKey: "sync_token[\(userId)::\(deviceId)]")
    }
    
    // MARK: Credentials
    
    private func loadCredentials(_ user: String? = nil) throws -> Matrix.Credentials? {
        
        guard let uid = user ?? UserDefaults.standard.string(forKey: "user_id"),
              let userId = UserId(uid)
        else {
            return nil
        }
        
        return try Matrix.Credentials.load(for: userId)
    }
    
    private func saveCredentials(creds: Matrix.Credentials) throws {
        UserDefaults.standard.set("\(creds.userId)", forKey: "user_id")
        
        try creds.save()
    }
        
    public func removeCredentials(for userId: UserId) {
        UserDefaults.standard.removeObject(forKey: "user_id")
        UserDefaults.standard.removeObject(forKey: "credentials[\(userId)]")
        UserDefaults.standard.removeObject(forKey: "device_id[\(userId)]")
        UserDefaults.standard.removeObject(forKey: "access_token[\(userId)]")
        UserDefaults.standard.removeObject(forKey: "expiration[\(userId)]")
        UserDefaults.standard.removeObject(forKey: "refresh_token[\(userId)]")
    }
    
    private func saveS4Key(key: Data, keyId: String, for userId: UserId) async throws {
        // Save the keyId -- but NOT the key itself -- in user defaults, so we know which key to use in the future
        UserDefaults.standard.set(keyId, forKey: "bsspeke_ssss_keyid[\(userId)]")
        
        // Save the actual key in the Keychain
        let keyStore = Matrix.LocalKeyStore(userId: userId)
        try await keyStore.saveKey(key: key, keyId: keyId)
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
    
    func lookForCreds() async throws {
        if let creds = try? loadCredentials() {
            let token = loadSyncToken(userId: creds.userId, deviceId: creds.deviceId)
            await MainActor.run {
                self.state = .haveCreds(creds, nil, token)
            }
        } else {
            await MainActor.run {
                self.state = .needCreds
            }
        }
    }
    
    // MARK: Sync filter
    // If the user is joined to any large rooms (eg Matrix HQ) then the default initial sync can be brutal
    // Lazy-loading room members and opting in to per-thread unread notifications made this bearable on Circles Android
    // So we do the same thing here
    var filter: Matrix.SyncFilter {
        Matrix.SyncFilter(room: Matrix.RoomFilter(state: Matrix.StateFilter(lazyLoadMembers: true, unreadThreadNotifications: true)))
    }
    
    // MARK: Connect
    
    func connect(creds: Matrix.Credentials,
                 s4Key: Matrix.SecretStorageKey? = nil,
                 token: String? = nil
    ) async throws {
        logger.debug("connect()")
        
        if let key = s4Key {
            logger.debug("Connecting with s4 keyId [\(key.keyId)]")
        } else {
            logger.debug("No s4 key / keyId")
        }
        
        guard let matrix = try? await Matrix.Session(creds: creds,
                                                     syncToken: token,
                                                     startSyncing: true,
                                                     initialSyncFilter: self.filter,
                                                     secretStorageKey: s4Key)
        else {
            logger.error("Failed to initialize Matrix session")
            let error = CirclesError("Failed to initialize Matrix session")
            await MainActor.run {
                self.state = .error(error)
            }
            throw error
        }
        
        guard let ssss = matrix.secretStore
        else {
            logger.warning("Matrix session needs secret storage")
            await MainActor.run {
                self.state = .needSecretStorage(matrix)
            }
            return
        }
        
        switch ssss.state {
            
        case .online(let defaultKeyId):
            logger.debug("Matrix secret storage is online")

            // Ok great we are connected to the Matrix account, and we have a valid Secret Storage key
            // Don't worry about making everything perfect right now
            // Just set our status to the next step.  The UI will drive the next steps.
            await MainActor.run {
                self.state = .haveSecretStorageAndKey(matrix)
            }
            return
            
            /* // FIXME: Move this into its own function
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
            */
            
        case .error(let msg):
            logger.error("Matrix secret storage failed: \(msg, privacy: .public)")
            let error = CirclesError("Matrix secret storage failed")
            await MainActor.run {
                self.state = .error(error)
            }
            throw error
            
        case .uninitialized:
            // FIXME: This is an easy case!  Just initialize the Secret Storage with a new key!
            logger.error("Matrix secret storage did not initialize")
            await MainActor.run {
                self.state = .needSecretStorage(matrix)
            }
            return
            
        case .needKey(let keyId, let keyDescription):
            logger.info("Matrix secret storage needs a key")
            await MainActor.run {
                self.state = .needSecretStorageKey(matrix, keyId, keyDescription)
            }
            return
        }
    }
    
    // MARK: Initialize secret storage
    
    func initSecretStorage(key: Matrix.SecretStorageKey) async throws {
        // Sanity check -- Are we in the right state to do this?
        guard case .needSecretStorage(let matrix) = state else {
            logger.error("Can't initialize secret storage unless we're in the 'need secret storage' state")
            throw CirclesError("Can't initialize secret storage unless we're in the 'need secret storage' state")
        }
        
        // Set up SSSS with our new default key
        try await matrix.enableSecretStorage(defaultKey: key)

        // Check to make sure that SSSS is now set up like we wanted
        guard let ssss = matrix.secretStore,
              case .online(let defaultKeyId) = ssss.state,
              defaultKeyId == key.keyId
        else {
            logger.error("Failed to initialize secret storage with default key id \(key.keyId, privacy: .public)")
            throw CirclesError("Failed to initialize secret storage")
        }
        
        // Set our state to the next step in our sequence of checks
        await MainActor.run {
            self.state = .haveSecretStorageAndKey(matrix)
        }
    }

    // MARK: Add missing SSSS key
    
    func addMissingKey(key: Matrix.SecretStorageKey) async throws {
        
        guard case .needSecretStorageKey(let matrix, let needKeyId, let description) = self.state
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
        

        
        await MainActor.run {
            self.state = .haveSecretStorageAndKey(matrix)
        }
    }

    // MARK: Cross Signing and Key Backup
    
    func ensureCrossSigning() async throws {
        guard case .haveSecretStorageAndKey(let matrix) = state else {
            logger.error("Can't do cross signing before SSSS")
            throw CirclesError("Can't do cross signing before SSSS")
        }
        
        try await matrix.setupCrossSigning()
    
        // FIXME: Check to verify that it succeeded
        
        await MainActor.run {
            self.state = .haveCrossSigning(matrix)
        }
    }
    
    func ensureKeyBackup() async throws {
        guard case .haveCrossSigning(let matrix) = state else {
            logger.error("Can't do key backup before cross signing")
            throw CirclesError("Can't do key backup before cross signing")
        }
        
        try await matrix.setupKeyBackup()
        
        // FIXME: Check to verify that it succeeded
        
        await MainActor.run {
            self.state = .haveKeyBackup(matrix)
        }
    }
    
    // MARK: Check for Circles config
    
    func checkForSpaceHierarchy() async throws {
        guard case .haveKeyBackup(let matrix) = state else {
            logger.error("Don't check for space hierarchy before key backup")
            throw CirclesError("Don't check for space hierarchy before key backup")
        }

        if let config = try await matrix.getAccountData(for: EVENT_TYPE_CIRCLES_CONFIG, of: CirclesConfigContent.self) {
            logger.debug("Found space hierarchy with root at \(config.root.stringValue)")
            await MainActor.run {
                self.state = .haveSpaceHierarchy(matrix, config)
            }
        } else {
            logger.debug("Failed to retrieve Circles config object from account data")
            await MainActor.run {
                self.state = .needSpaceHierarchy(matrix)
            }
        }
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
    
    // MARK: Space hierarchy
    func createSpaceHierarchy(displayName: String,
                              circles: [(String,UIImage?)],
                              onProgress: ((Int,Int,String) -> Void)? = nil
    ) async throws {
        
        guard case .needSpaceHierarchy(let matrix) = state else {
            logger.error("Can't create space hierarchy unless we're in the 'need space hierarchy' state")
            throw CirclesError("Invalid state transition (create space hierarchy)")
        }

        let total: Int = 13
        
        logger.debug("Creating Spaces hierarchy for Circles rooms")
        onProgress?(0, total, "Creating Matrix Spaces")

        try await Task.sleep(for: .seconds(1))
        let topLevelSpace = try await matrix.createSpace(name: "Circles")
        logger.debug("Created top-level Circles space \(topLevelSpace)")
        onProgress?(1, total, "Creating Matrix Spaces")

        try await Task.sleep(for: .seconds(1))
        let myCircles = try await matrix.createSpace(name: "My Circles")
        logger.debug("Created My Circles space \(myCircles)")
        onProgress?(2, total, "Creating Matrix Spaces")

        try await Task.sleep(for: .seconds(1))
        let myGroups = try await matrix.createSpace(name: "My Groups")
        logger.debug("Created My Groups space \(myGroups)")
        onProgress?(3, total, "Creating Matrix Spaces")

        try await Task.sleep(for: .seconds(1))
        let myGalleries = try await matrix.createSpace(name: "My Photo Galleries")
        logger.debug("Created My Galleries space \(myGalleries)")
        onProgress?(4, total, "Creating Matrix Spaces")

        try await Task.sleep(for: .seconds(1))
        let myPeople = try await matrix.createSpace(name: "My People")
        logger.debug("Created My People space \(myPeople)")
        onProgress?(5, total, "Creating Matrix Spaces")

        try await Task.sleep(for: .seconds(1))
        let myProfile = try await matrix.createSpace(name: displayName, joinRule: .knock)  // Profile room is m.knock because we might share it with other users
        logger.debug("Created My Profile space \(myProfile)")
        onProgress?(6, total, "Creating Matrix Spaces")

        logger.debug("- Adding Space child relationships")
        onProgress?(6, total, "Initializing Spaces")
        try await Task.sleep(for: .seconds(1))
        // Space child relations
        try await matrix.addSpaceChild(myCircles, to: topLevelSpace)
        try await matrix.addSpaceChild(myGroups, to: topLevelSpace)
        try await matrix.addSpaceChild(myGalleries, to: topLevelSpace)
        try await matrix.addSpaceChild(myPeople, to: topLevelSpace)
        try await matrix.addSpaceChild(myProfile, to: topLevelSpace)
        // Space parent relations
        try await matrix.addSpaceParent(topLevelSpace, to: myCircles, canonical: true)
        try await matrix.addSpaceParent(topLevelSpace, to: myGroups, canonical: true)
        try await matrix.addSpaceParent(topLevelSpace, to: myGalleries, canonical: true)
        try await matrix.addSpaceParent(topLevelSpace, to: myPeople, canonical: true)
        // Don't add the parent event to the profile space, because we will share that one with others and we don't need them to know our private room id for the top-level space
        // It's not a big deal but this is probably safer...  otherwise the user might somehow be tricked into accepting a knock for the top-level space
        
        logger.debug("- Adding tags to spaces")
        onProgress?(7, total, "Tagging Spaces")
        try await Task.sleep(for: .seconds(1))
        try await matrix.addTag(roomId: topLevelSpace, tag: ROOM_TAG_CIRCLES_SPACE_ROOT)
        try await matrix.addTag(roomId: myCircles, tag: ROOM_TAG_MY_CIRCLES)
        try await matrix.addTag(roomId: myGroups, tag: ROOM_TAG_MY_GROUPS)
        try await matrix.addTag(roomId: myGalleries, tag: ROOM_TAG_MY_PHOTOS)
        try await matrix.addTag(roomId: myPeople, tag: ROOM_TAG_MY_PEOPLE)
        try await matrix.addTag(roomId: myProfile, tag: ROOM_TAG_MY_PROFILE)
        
        logger.debug("- Uploading Circles config to account data")
        onProgress?(8, total, "Saving configuration")
        try await Task.sleep(for: .seconds(1))
        let config = CirclesConfigContent(root: topLevelSpace, circles: myCircles, groups: myGroups, galleries: myGalleries, people: myPeople, profile: myProfile)
        try await matrix.putAccountData(config, for: EVENT_TYPE_CIRCLES_CONFIG)
        
        var count = 9
        for (name, avatar) in circles {
            logger.debug("- Creating circle [\(name, privacy: .public)]")
            //status = "Creating circle \"\(circle.name)\""
            onProgress?(count, total, "Creating circle \"\(name)\"")
            try await Task.sleep(for: .seconds(1))
            let circleRoomId = try await matrix.createSpace(name: name)
            let wallRoomId = try await matrix.createRoom(name: name, type: ROOM_TYPE_CIRCLE, joinRule: .knock)
            if let image = avatar {
                try await matrix.setAvatarImage(roomId: wallRoomId, image: image)
            }
            try await matrix.addSpaceChild(wallRoomId, to: circleRoomId)
            try await matrix.addSpaceChild(circleRoomId, to: myCircles)
            count += 1
        }
        
        logger.debug("- Creating photo gallery [Photos]")
        //status = "Creating photo gallery"
        onProgress?(12, total, "Creating photo gallery")
        try await Task.sleep(for: .seconds(1))
        let photosGallery = try await matrix.createRoom(name: "Photos", type: ROOM_TYPE_PHOTOS, joinRule: .knock)
        try await matrix.addSpaceChild(photosGallery, to: myGalleries)
        
        //status = "All done!"
        onProgress?(total, total, "All done!")
        
        // Update: Don't do this, just set our state to "have space hierarchy"
        // Now transition to the next state, which for us is online
        await MainActor.run {
            self.state = .haveSpaceHierarchy(matrix, config)
        }
    }
    
    // MARK: Add config
    func addConfig(config: CirclesConfigContent) async throws {
        guard case .needSpaceHierarchy(let matrix) = state else {
            logger.error("Can't add circles config until we're ready")
            throw CirclesError("Invalid state transition")
        }

        await MainActor.run {
            self.state = .haveSpaceHierarchy(matrix, config)
        }
    }
    
    // MARK: Go online
    func goOnline() async throws {
        guard case .haveSpaceHierarchy(let matrix, let config) = state else {
            logger.error("Can't go online without our space hierarchy")
            throw CirclesError("Can't go online without our space hierarchy")
        }

        guard let appSession = try? await CirclesApplicationSession(store: self, matrix: matrix, config: config)
        else {
            logger.error("Failed to create Circles application session")
            throw CirclesError("Failed to create Circles application session")
        }
        
        await MainActor.run {
            self.state = .online(appSession)
        }
    }
    
    // MARK: Login
    
    func login(userId: UserId) async throws {
        logger.debug("Logging in as \(userId)")
        
        // First - Check to see if we already have a device_id and access_token for this user
        //         e.g. maybe they didn't log out, but only "switched"
        if let creds = try? loadCredentials(userId.stringValue) {
            logger.debug("Found saved credentials for \(userId)")
            
            // Save the full credentials including the userId, so we can automatically connect next time
            try self.saveCredentials(creds: creds)
            
            // Load the initial sync token, if there is one
            let token = self.loadSyncToken(userId: creds.userId, deviceId: creds.deviceId)
            
            await MainActor.run {
                self.state = .haveCreds(creds, nil, token)
            }
            
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
            let loginSession = try await UiaLoginSession(userId: userId, refreshToken: true, completion: { session, data in
                self.logger.debug("Login was successful")
                
                let decoder = JSONDecoder()
                guard let creds = try? decoder.decode(Matrix.Credentials.self, from: data)
                else {
                    self.logger.error("Failed to decode credentials")
                    await MainActor.run {
                        self.state = .error(CirclesError("Failed to decode credentials"))
                    }
                    return
                }
                try self.saveCredentials(creds: creds)
                //try await self.connect(creds: creds)
                
                // Check for a BS-SPEKE session, and if we have one, use it to generate our SSSS key
                if let bsspeke = session.getBSSpekeClient() {
                    self.logger.debug("Got BS-SPEKE client")
                    let s4Key = try self.generateS4Key(bsspeke: bsspeke)
                    self.logger.debug("BS-SPEKE key: id = \(s4Key.keyId), key = \(s4Key.key.base64EncodedString())")
                    
                    // Save the keys into our device Keychain, so they will be available to future Matrix sessions where we load creds and connect, without logging in
                    let store = Matrix.LocalKeyStore(userId: creds.userId)
                    try await store.saveKey(key: s4Key.key, keyId: s4Key.keyId)
                    
                    self.logger.debug("Connecting with keyId [\(s4Key.keyId)]")
                    await MainActor.run {
                        self.state = .haveCreds(creds, s4Key, nil)
                    }
                } else {
                    self.logger.warning("Could not find BS-SPEKE client")
                    await MainActor.run {
                        self.state = .haveCreds(creds, nil, nil)
                    }
                }
            })
            await MainActor.run {
                self.state = .loggingInUIA(loginSession)
            }
            
        } else {
            // No UIA
            
            let loginSession = LegacyLoginSession(userId: userId,
                                                  refreshToken: true,
                                                  completion: { creds in
                                                        try self.saveCredentials(creds: creds)
                                                        await MainActor.run {
                                                            self.state = .haveCreds(creds, nil, nil)
                                                        }
                                                    },
                                                  cancellation: {
                                                        await MainActor.run {
                                                            self.state = .needCreds
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
                    self.state = .error(CirclesError("Failed to decode credentials"))
                }
                return
            }
            try self.saveCredentials(creds: creds)
            
            // Check for a BS-SPEKE session, and if we have one, use it to generate our SSSS key
            if let bsspeke = session.getBSSpekeClient() {
                self.logger.debug("Got BS-SPEKE client")
                let s4Key = try self.generateS4Key(bsspeke: bsspeke)
                self.logger.debug("BS-SPEKE key: id = \(s4Key.keyId), key = \(s4Key.key.base64EncodedString())")

                // Save the keys into our device Keychain, so they will be available to future Matrix sessions where we load creds and connect, without logging in
                let store = Matrix.LocalKeyStore(userId: creds.userId)
                try await store.saveKey(key: s4Key.key, keyId: s4Key.keyId)

                self.logger.debug("Configuring with keyId [\(s4Key.keyId)]")
                
                await MainActor.run {
                    self.state = .haveCreds(creds, s4Key, nil)
                }
            } else {
                self.logger.warning("Could not find BS-SPEKE client -- Unable to generate SSSS key from passphrase")
                await MainActor.run {
                    self.state = .haveCreds(creds, nil, nil)
                }
            }
        })
        await MainActor.run {
            self.state = .signingUp(signupSession)
        }
    }
    
    // MARK: Matrix session
    var matrix: Matrix.Session? {
        switch state {
            
        case .startingUp:
            return nil
        case .error(_):
            return nil
        case .needCreds:
            return nil
        case .signingUp(_):
            return nil
        case .loggingInUIA(_):
            return nil
        case .loggingInNonUIA(_):
            return nil
        case .haveCreds(_, _, _):
            return nil
        case .needSecretStorage(let matrix):
            return matrix
        case .needSecretStorageKey(let matrix, _, _):
            return matrix
        case .haveSecretStorageAndKey(let matrix):
            return matrix
        case .haveCrossSigning(let matrix):
            return matrix
        case .haveKeyBackup(let matrix):
            return matrix
        case .needSpaceHierarchy(let matrix):
            return matrix
        case .haveSpaceHierarchy(let matrix, _):
            return matrix
        case .online(let appSession):
            return appSession.matrix
        }
    }

    
    // MARK: Logout
    
    func logout() async throws {
        switch state {
            
        case .error(_):
            await MainActor.run {
                self.state = .needCreds
            }
            
        case .startingUp:
            // WTF?!?  Way too early to actually do anything
            return
            
        case .needCreds:
            // Nothing to log out
            return
            
        case .signingUp(let signupSession):
            try await signupSession.cancel()
            await MainActor.run {
                self.state = .needCreds
            }
            
        case .loggingInUIA(let loginSession):
            try await loginSession.cancel()
            await MainActor.run {
                self.state = .needCreds
            }
            
        case .loggingInNonUIA(let legacyLoginSession):
            // There's really nothing to cancel
            await MainActor.run {
                self.state = .needCreds
            }
            
        case .haveCreds(let creds, _, _):
            logger.info("Logging out offline session for \(creds.userId)")
            if let client = try? await Matrix.Client(creds: creds) {
                try await client.logout()
            }
            removeCredentials(for: creds.userId)
            await MainActor.run {
                self.state = .needCreds
            }
            
        default:
            if let matrix = self.matrix {
                let creds = matrix.creds
                try await matrix.close()
                try await matrix.logout()
                removeCredentials(for: creds.userId)
                await MainActor.run {
                    self.state = .needCreds
                }
            }
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
            self.state = .needCreds
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
