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
        case signedUp(Matrix.Credentials, Matrix.SecretStorageKey?)
        case loggingInUIA(UiaLoginSession, Matrix.AuthFlowFilter)          // Because /login can now take more than a simple username/password
        case loggingInNonUIA(LegacyLoginSession)    // For accounts without fancy swiclops authentication
        case haveCreds(Matrix.Credentials, Matrix.SecretStorageKey?, String?)
        case needSecretStorage(Matrix.Session)
        case needSecretStorageKey(Matrix.Session, String, Matrix.KeyDescriptionContent)
        case haveSecretStorageAndKey(Matrix.Session)
        case haveCrossSigning(Matrix.Session)
        case haveKeyBackup(Matrix.Session)
        case needSpaceHierarchy(Matrix.Session)
        case haveSpaceHierarchy(Matrix.Session, CirclesConfigContentV2)
        case online(CirclesApplicationSession)
    }
    @Published var state: State
    var appStore: AppStoreInterface
    
    var logger: os.Logger
    var defaults: UserDefaults
    
    // MARK: init
    
    init() {
        self.logger = Logger(subsystem: "Circles", category: "Store")
        
        self.defaults = UserDefaults(suiteName: CIRCLES_APP_GROUP_NAME)!
        
        self.appStore = AppStoreInterface()
        
        // Ok, we're just starting out
        self.state = .startingUp
    }
    
    // MARK: Sync tokens
    
    private func loadSyncToken(userId: UserId, deviceId: String) -> String? {
        logger.debug("Loading sync token")
        return self.defaults.string(forKey: "sync_token[\(userId)::\(deviceId)]")
    }
    
    private func saveSyncToken(token: String, userId: UserId, deviceId: String) {
        logger.debug("Saving sync token")
        self.defaults.set(token, forKey: "sync_token[\(userId)::\(deviceId)]")
    }
    
    // MARK: Credentials
    
    private func dump(defaults: UserDefaults) {
        let dictionary = defaults.dictionaryRepresentation()
        for (key, _) in dictionary { // (key, value)
            logger.debug("DEFAULTS Found key \(key)")
        }
    }
    
    private func loadUserId() -> UserId? {
        // First look in the "new" location, in the Circles app group
        if let newString = self.defaults.string(forKey: "user_id"),
           let userId = UserId(newString)
        {
            return userId
        }
        // Fall back to looking in the "old" location, the standard defaults without suite name
        else if let oldString = UserDefaults.standard.string(forKey: "user_id"),
                let userId = UserId(oldString)
        {
            // Because we had to look in the old location,
            // we should save this in the new location for future re-use
            self.defaults.set(userId.stringValue, forKey: "user_id")
            
            return userId
        }
        // Guess we didn't find anything in either location
        else {
            return nil
        }
    }
    
    private func loadCredentials(_ userId: UserId? = nil) throws -> Matrix.Credentials? {
        
        guard let userId = userId ?? loadUserId()
        else {
            logger.error("Failed to find current user_id")
            
            /*
            logger.debug("Circles group defaults:")
            dump(defaults: self.defaults)
            
            logger.debug("Standard defaults:")
            dump(defaults: UserDefaults.standard)
            */
            
            return nil
        }
        
        if let creds = try? Matrix.Credentials.load(for: userId, defaults: self.defaults) {
            logger.debug("Loaded creds from Circles group defaults")
            return creds
        } else if let oldCreds = try? Matrix.Credentials.load(for: userId, defaults: UserDefaults.standard) { // Fall back to trying without the suite name
            logger.debug("Loaded creds from standard UserDefaults")
            // Make sure that these creds get stored in the new location too, so we can find them in the future
            try self.saveCredentials(creds: oldCreds)
            return oldCreds
        } else {
            // No luck :(
            logger.error("No creds for \(userId)")
            return nil
        }
    }
    
    private func saveCredentials(creds: Matrix.Credentials) throws {
        logger.debug("Saving credentials for \(creds.userId)")
        defaults.set("\(creds.userId)", forKey: "user_id")
        
        try creds.save(defaults: defaults)
    }

    public func removeCredentials(for userId: UserId) {
        removeCredentials(for: userId, defaults: self.defaults)
        removeCredentials(for: userId, defaults: UserDefaults.standard)
    }
    
    public func removeCredentials(for userId: UserId, defaults: UserDefaults) {
        defaults.removeObject(forKey: "user_id")
        defaults.removeObject(forKey: "credentials[\(userId)]")
        defaults.removeObject(forKey: "device_id[\(userId)]")
        defaults.removeObject(forKey: "access_token[\(userId)]")
        defaults.removeObject(forKey: "expiration[\(userId)]")
        defaults.removeObject(forKey: "refresh_token[\(userId)]")
    }
    
    private func saveS4Key(key: Data, keyId: String, for userId: UserId) async throws {
        // Save the keyId -- but NOT the key itself -- in user defaults, so we know which key to use in the future
        self.defaults.set(keyId, forKey: "bsspeke_ssss_keyid[\(userId)]")
        
        // Save the actual key in the Keychain
        let keyStore = Matrix.LocalKeyStore(userId: userId)
        try await keyStore.saveKey(key: key, keyId: keyId)
    }
    
    // MARK: Upgrade Old Config
    private func upgradeConfigV1toV2(_ old: CirclesConfigContentV1, matrix: Matrix.Session) async throws -> CirclesConfigContentV2 {
        logger.debug("Upgrading old config v1 to new config v2")
        var timelineRoomIds: [RoomId] = []
        let oldCirclesRoomId = old.circles
        logger.debug("Found old circles space \(oldCirclesRoomId)")
        let circleRoomIds = try await matrix.getSpaceChildren(oldCirclesRoomId)
        logger.debug("Found \(circleRoomIds.count) circles in the space")
        
        for circleRoomId in circleRoomIds {
            let roomIds = try await matrix.getSpaceChildren(circleRoomId)
            logger.debug("Found \(roomIds.count) timelines for circle \(circleRoomId)")
            timelineRoomIds.append(contentsOf: roomIds)
        }
        
        logger.debug("Creating new 'Timelines' space")
        let newTimelineSpaceId = try await matrix.createSpace(name: "Timelines")
        logger.debug("New Timelines space is \(newTimelineSpaceId)")
        for roomId in timelineRoomIds {
            // Sanity check - Make sure that this is actually an org.futo.social.timeline room
            guard let createContent = try? await matrix.getRoomState(roomId: roomId, eventType: M_ROOM_CREATE) as? RoomCreateContent
            else {
                logger.error("Failed to get room creation event for timeline room \(roomId)")
                throw CirclesError("Failed to get room creation event")
            }
            guard createContent.type == ROOM_TYPE_CIRCLE
            else {
                logger.warning("Timeline room \(roomId) is not actually a timeline - its type is \(createContent.type ?? "none")")
                continue
            }
            // All good - it's really a timeline room, so it's safe to add this to our Timelines space
            logger.debug("Adding timeline \(roomId) as child of the Timelines space")
            try await matrix.addSpaceChild(roomId, to: newTimelineSpaceId)
        }
        logger.debug("Adding new Timelines space as a child of our root space")
        try await matrix.addSpaceChild(newTimelineSpaceId, to: old.root)
        logger.debug("Adding root space as the parent of Timelines space")
        try await matrix.addSpaceParent(old.root, to: newTimelineSpaceId, canonical: true)
        
        logger.debug("Upgrade success!")
        return CirclesConfigContentV2(root: old.root,
                                      groups: old.groups,
                                      galleries: old.galleries,
                                      people: old.people,
                                      profile: old.profile,
                                      timelines: newTimelineSpaceId)
    }
    
    // MARK: Load Config
    
    private func loadConfig(matrix: Matrix.Session) async throws -> CirclesConfigContentV2? {
        Matrix.logger.debug("Loading Circles configuration")
        // Easy mode: Do we have our config saved in the Account Data?
        if let config = try await matrix.getAccountData(for: EVENT_TYPE_CIRCLES_CONFIG_V2, of: CirclesConfigContentV2.self) {
            Matrix.logger.debug("Found Circles config in the account data")
            return config
        }
        
        if let oldConfig = try await matrix.getAccountData(for: EVENT_TYPE_CIRCLES_CONFIG_V1, of: CirclesConfigContentV1.self) {
            Matrix.logger.debug("Found old config in the account data")
            let config = try await upgradeConfigV1toV2(oldConfig, matrix: matrix)
            Matrix.logger.debug("Upgraded old config to v2")
            try await matrix.putAccountData(config, for: EVENT_TYPE_CIRCLES_CONFIG_V2)
            Matrix.logger.debug("Saved new config v2")
            return config
        }
        
        Matrix.logger.error("Failed to load circles config")
        throw CirclesError("Failed to load circles config")
    }
    
    func lookForCreds() async throws {
        logger.debug("Looking for creds")
        if let creds = try? loadCredentials() {
            logger.debug("Found creds for \(creds.userId.stringValue)")
            let token = loadSyncToken(userId: creds.userId, deviceId: creds.deviceId)
            logger.debug("Setting state to .haveCreds")
            await MainActor.run {
                self.state = .haveCreds(creds, nil, token)
            }
        } else {
            logger.debug("No creds")
            logger.debug("Setting state to .needCreds")
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
                                                     defaults: self.defaults,
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
            
        case .online(_): // (let defaultKeyId)
            logger.debug("Matrix secret storage is online")

            // Ok great we are connected to the Matrix account, and we have a valid Secret Storage key
            // Don't worry about making everything perfect right now
            // Just set our status to the next step.  The UI will drive the next steps.
            await MainActor.run {
                self.state = .haveSecretStorageAndKey(matrix)
            }
            return
            
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
        
        guard case .needSecretStorageKey(let matrix, let needKeyId, _) = self.state // (let matrix, let needKeyId, let description)
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
        
        guard case .online(_) = ssss.state // (let defaultKeyId)
        else {
            logger.error("Secret storage is still not online")
            throw CirclesError("Secret storage is still not online")
        }
        

        
        await MainActor.run {
            self.state = .haveSecretStorageAndKey(matrix)
        }
    }

    // MARK: Cross Signing
    
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
    
    // MARK: Key Backup
    
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

        if let config = try? await loadConfig(matrix: matrix) {
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
                              circles: [CircleSetupInfo],
                              onProgress: ((Int,Int,String) -> Void)? = nil
    ) async throws {
        
        guard case .needSpaceHierarchy(let matrix) = state else {
            logger.error("Can't create space hierarchy unless we're in the 'need space hierarchy' state")
            throw CirclesError("Invalid state transition (create space hierarchy)")
        }

        let total: Int = 13
        
        let sleepMS = 5
        
        logger.debug("Creating Spaces hierarchy for Circles rooms")
        onProgress?(0, total, "Creating Matrix Spaces")

        try await Task.sleep(for: .milliseconds(sleepMS))
        let topLevelSpace = try await matrix.createSpace(name: "Circles")
        logger.debug("Created top-level Circles space \(topLevelSpace)")
        onProgress?(1, total, "Creating Matrix Spaces")

        try await Task.sleep(for: .milliseconds(sleepMS))
        let timelines = try await matrix.createSpace(name: "Timelines")
        logger.debug("Created My Circles space \(timelines)")
        onProgress?(2, total, "Creating Matrix Spaces")

        try await Task.sleep(for: .milliseconds(sleepMS))
        let myGroups = try await matrix.createSpace(name: "My Groups")
        logger.debug("Created My Groups space \(myGroups)")
        onProgress?(3, total, "Creating Matrix Spaces")

        try await Task.sleep(for: .milliseconds(sleepMS))
        let myGalleries = try await matrix.createSpace(name: "My Photo Galleries")
        logger.debug("Created My Galleries space \(myGalleries)")
        onProgress?(4, total, "Creating Matrix Spaces")

        try await Task.sleep(for: .milliseconds(sleepMS))
        let myPeople = try await matrix.createSpace(name: "My People")
        logger.debug("Created My People space \(myPeople)")
        onProgress?(5, total, "Creating Matrix Spaces")

        try await Task.sleep(for: .milliseconds(sleepMS))
        let myProfile = try await matrix.createSpace(name: displayName, joinRule: .knock)  // Profile room is m.knock because we might share it with other users
        logger.debug("Created My Profile space \(myProfile)")
        onProgress?(6, total, "Creating Matrix Spaces")

        logger.debug("- Adding Space child relationships")
        onProgress?(6, total, "Initializing Spaces")
        try await Task.sleep(for: .milliseconds(sleepMS))
        // Space child relations
        try await matrix.addSpaceChild(timelines, to: topLevelSpace)
        try await matrix.addSpaceChild(myGroups, to: topLevelSpace)
        try await matrix.addSpaceChild(myGalleries, to: topLevelSpace)
        try await matrix.addSpaceChild(myPeople, to: topLevelSpace)
        try await matrix.addSpaceChild(myProfile, to: topLevelSpace)
        // Space parent relations
        try await matrix.addSpaceParent(topLevelSpace, to: timelines, canonical: true)
        try await matrix.addSpaceParent(topLevelSpace, to: myGroups, canonical: true)
        try await matrix.addSpaceParent(topLevelSpace, to: myGalleries, canonical: true)
        try await matrix.addSpaceParent(topLevelSpace, to: myPeople, canonical: true)
        // Don't add the parent event to the profile space, because we will share that one with others and we don't need them to know our private room id for the top-level space
        // It's not a big deal but this is probably safer...  otherwise the user might somehow be tricked into accepting a knock for the top-level space
        
        logger.debug("- Uploading Circles config to account data")
        onProgress?(8, total, "Saving configuration")
        try await Task.sleep(for: .milliseconds(sleepMS))
        let config = CirclesConfigContentV2(root: topLevelSpace, groups: myGroups, galleries: myGalleries, people: myPeople, profile: myProfile, timelines: timelines)
        try await matrix.putAccountData(config, for: EVENT_TYPE_CIRCLES_CONFIG_V2)
        
        var count = 9
        for circle in circles {
            logger.debug("- Creating circle [\(circle.name, privacy: .public)]")
            //status = "Creating circle \"\(circle.name)\""
            onProgress?(count, total, "Creating circle \"\(circle.name)\"")
            try await Task.sleep(for: .milliseconds(sleepMS))
            let wallRoomId = try await matrix.createRoom(name: circle.name, type: ROOM_TYPE_CIRCLE, joinRule: .knock)
            if let image = circle.avatar {
                try await matrix.setAvatarImage(roomId: wallRoomId, image: image)
            }
            try await matrix.addSpaceChild(wallRoomId, to: timelines)
            count += 1
        }
        
        //status = "All done!"
        onProgress?(total, total, "All done!")
        
        // Update: Don't do this, just set our state to "have space hierarchy"
        // Now transition to the next state, which for us is online
        await MainActor.run {
            self.state = .haveSpaceHierarchy(matrix, config)
        }
    }
    
    // MARK: Add config
    func addConfig(config: CirclesConfigContentV2) async throws {
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
    
    func login(userId: UserId, filter: @escaping Matrix.AuthFlowFilter) async throws {
        logger.debug("Logging in as \(userId)")
        
        // First - Check to see if we already have a device_id and access_token for this user
        //         e.g. maybe they didn't log out, but only "switched"
        if let creds = try? loadCredentials(userId) {
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
        logger.debug("No existing credentials for \(userId.stringValue)")
        
        // Second - Check wether the server supports UIA on /login
        guard let wellKnown = try? await Matrix.fetchWellKnown(for: userId.domain),
              let serverURL = URL(string: wellKnown.homeserver.baseUrl)
        else {
            logger.error("Failed to look up a valid homeserver URL for domain \(userId.domain)")
            throw CirclesError("Failed to look up well known")
        }
        logger.debug("Got well-known for \(userId.domain)")
        
        let doUIA = try await Matrix.checkForUiaLogin(homeserver: serverURL)
        
        if doUIA {
            logger.debug("Starting UIA login for \(userId.stringValue)")
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
                self.state = .loggingInUIA(loginSession, filter)
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
        let signupSession = try await SignupSession(domain: domain,
                                                    initialDeviceDisplayName: "Circles (\(deviceModel))",
                                                    refreshToken: true,
                                                    completion: { session,data in
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
                    self.state = .signedUp(creds, s4Key)
                }
            } else {
                self.logger.warning("Could not find BS-SPEKE client -- Unable to generate SSSS key from passphrase")
                await MainActor.run {
                    self.state = .signedUp(creds, nil)
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
        case .signedUp(_, _):
            return nil
        case .loggingInUIA(_, _):
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
            
        case .loggingInUIA(let loginSession, _): // (let loginSession, let filter)
            try await loginSession.cancel()
            await MainActor.run {
                self.state = .needCreds
            }
            
        case .loggingInNonUIA(_): // (let legacyLoginSessio)
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
                logger.debug("Closing Matrix session")
                try await matrix.close()
                logger.debug("Logging out Matrix session")
                try await matrix.logout()
                logger.debug("Removing credentials")
                removeCredentials(for: creds.userId)
                logger.debug("Setting state back to 'need creds'")
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
        try await session.matrix.deactivateAccount(erase: true) { (uia, data) in
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
