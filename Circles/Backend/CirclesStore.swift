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
        case loggingIn(LoginSession) // Because /login can now take more than a simple username/password
        case haveCreds(Matrix.Credentials)
        case online(CirclesSession)
        case signingUp(SignupSession)
        case settingUp(SetupSession)
    }
    @Published var state: State
    
    var logger: os.Logger
    
    
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
    
    private func loadSyncToken(userId: UserId, deviceId: String) -> String? {
        UserDefaults.standard.string(forKey: "sync_token[\(userId)::\(deviceId)]")
    }
    
    private func saveSyncToken(token: String, userId: UserId, deviceId: String) {
        UserDefaults.standard.set(token, forKey: "sync_token[\(userId)::\(deviceId)]")
    }
    
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
    
    
    func connect(creds: Matrix.Credentials, s4KeyInfo: (String,Data)? = nil) async throws {
        logger.debug("connect()")
        let token = loadSyncToken(userId: creds.userId, deviceId: creds.deviceId)
        logger.debug("Got token = \(token ?? "none")")
        
        if let keyInfo = s4KeyInfo {
            let (keyId, key) = keyInfo
            logger.debug("Connecting with s4 keyId [\(keyId)]")
        } else {
            logger.debug("No s4 key / keyId")
        }
        
        guard let matrix = try? await Matrix.Session(creds: creds,
                                                     syncToken: token,
                                                     startSyncing: false,
                                                     secretStorageKeyInfo: s4KeyInfo),
              let session = try? await CirclesSession(matrix: matrix)
        else {
            let err = CirclesError("Failed to connect as \(creds.userId)")
            await MainActor.run {
                self.state = .nothing(err)
            }
            return
        }
        
        logger.debug("Set up Matrix+CirclesSession")
        await MainActor.run {
            self.state = .online(session)
        }
        logger.debug("Set state to .online")
    }

    /*
    private func computeKeyId(key: Data) throws -> String {
        guard let keyHash = Digest(algorithm: .sha256).update(data: key)?.final()
        else {
            throw Matrix.Error("Failed to hash key")
        }
        let keyId = "m.secret_storage.key." + Data(keyHash[0..<16]).base64EncodedString().trimmingCharacters(in: CharacterSet(charactersIn: "="))
        return keyId
    }
    */
    
    private func generateS4Key(bsspeke: BlindSaltSpeke.ClientSession) throws -> (String, Data) {
        let ssssKey = Data(bsspeke.generateHashedKey(label: MATRIX_SSSS_KEY_LABEL))
        let ssssKeyId = try Matrix.SecretStore.computeKeyId(key: ssssKey)
        return (ssssKeyId, ssssKey)
    }
    
    func login(userId: UserId) async throws {
        logger.debug("Logging in as \(userId)")
        let loginSession = try await LoginSession(userId: userId, completion: { session, data in
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
                let (keyId, key) = try self.generateS4Key(bsspeke: bsspeke)
                self.logger.debug("BS-SPEKE key: id = \(keyId), key = \(key.base64EncodedString())")
                let keyInfo = (keyId, key)
                /*
                // Save the keys into our device Keychain, so they will be available to future Matrix sessions where we load creds and connect, without logging in
                let store = Matrix.KeychainSecretStore(userId: creds.userId)
                try await store.saveKey(key: key, keyId: keyId)
                */

                self.logger.debug("Connecting with keyId [\(keyId)]")
                try await self.connect(creds: creds, s4KeyInfo: keyInfo)
            } else {
                self.logger.warning("Could not find BS-SPEKE client")
                try await self.connect(creds: creds)
            }
        })
        await MainActor.run {
            self.state = .loggingIn(loginSession)
        }
    }
    
    func signup() async throws {
        // We only support signing up on our own servers
        // Look at the country code of the user's StoreKit storefront to decide which server we should use
        // Create a SignupSession and set our state to .signingUp
        
        guard let domain = ourDomain else {
            print("SIGNUP\tCouldn't find domain from StoreKit info")
            return
        }

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
            //try await self.connect(creds: creds)
            
            // The UI will show the user their new user id, and give them a button to tap to log out and go back to the login screen
        })
        await MainActor.run {
            self.state = .signingUp(signupSession)
        }
    }
    
    func beginSetup(creds: Matrix.Credentials) async throws {
        
        var fullCreds = creds
        
        if fullCreds.wellKnown == nil {
            let domain = creds.userId.domain
            fullCreds.wellKnown = try await Matrix.fetchWellKnown(for: domain)
        }
        
        let session = try await SetupSession(creds: fullCreds, store: self)
        await MainActor.run {
            self.state = .settingUp(session)
        }
    }
    
    private func removeCredentials(for userId: UserId) {
        UserDefaults.standard.removeObject(forKey: "user_id")
        UserDefaults.standard.removeObject(forKey: "device_id[\(userId)]")
        UserDefaults.standard.removeObject(forKey: "access_token[\(userId)]")
    }
    
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
            
        case .settingUp(let session):
            let creds = session.creds
            if let client = try? await Matrix.Client(creds: creds) {
                try await client.logout()
            }
            removeCredentials(for: creds.userId)
            
            await MainActor.run {
                self.state = .nothing(nil)
            }
            
        default:
            logger.warning("Can't log out because we are not online")
        }
    }
    
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
    
    // MARK: Domain handling

    
    private var ourDomain: String? {

        guard let countryCode = SKPaymentQueue.default().storefront?.countryCode else {
            print("DOMAIN\tCouldn't get country code from SKPaymentQueue")
            return nil
        }

        let DEBUG = true
        
        let usDomain: String
        let euDomain: String
        
        if DEBUG {
            usDomain = "us.circles-dev.net"
            euDomain = "nl.circles-dev.net"
        } else {
            usDomain = "circu.li"
            euDomain = "eu.circu.li"
        }

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
