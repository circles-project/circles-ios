//
//  CirclesStore.swift
//  Circles
//
//  Created by Charles Wright on 6/7/22.
//

import Foundation
import StoreKit

import CryptoKit


public class CirclesStore: ObservableObject {
    
    enum State {
        case starting
        case nothing(CirclesError?)
        case loggingIn(LoginSession) // Because /login will soon take more than a simple username/password
        case haveCreds(MatrixCredentials)
        case online(LegacyStore)
        case signingUp(SignupSession)
        case settingUp(MatrixCredentials) // or should this be (MatrixInterface) ???
    }
    @Published var state: State
    
    
    init() {
        // Ok, we're just starting out
        self.state = .starting

        // We can realistically be in one of just two states.
        // Either:
        // .haveCreds - if we can find credentials in the user defaults
        // or
        // .nothing - if there are no creds to be found

        guard let creds = loadCredentials()
        else {
            // Apparently we're offline, waiting for (valid) credentials to log in
            print("STORE\tDidn't find valid login credentials - Setting state to .nothing")
            self.state = .nothing(nil)
            return
        }

        self.state = .haveCreds(creds)
    }
    
    private func loadCredentials(_ user: String? = nil) -> MatrixCredentials? {
        
        guard let userId = user ?? UserDefaults.standard.string(forKey: "user_id")
        else {
            return nil
        }
        guard let deviceId = UserDefaults.standard.string(forKey: "device_id[\(userId)]"),
              let accessToken = UserDefaults.standard.string(forKey: "access_token[\(userId)]")
        else {
            return nil
        }
        
        return MatrixCredentials(accessToken: accessToken,
                                 deviceId: deviceId,
                                 userId: userId)
    }
    
    func connect(creds: MatrixCredentials) async throws {
        // If the creds don't already include well-known, then fetch homeserver info using well-known URL from the given domain
        // Init a new MatrixSession with that homeserver and these creds
        // Set our state to be online with that session
        
        var fullCreds = creds
        if fullCreds.wellKnown == nil {
            guard let domain = getDomainFromUserId(creds.userId) else {
                let msg = "Could not determine domain for user id"
                print("CONNECT\t\(msg)")
                throw CirclesError(msg)
            }
            fullCreds.wellKnown = try await fetchWellKnown(for: domain)
        }
        
        let ls = LegacyStore(creds: fullCreds)
        await MainActor.run {
            self.state = .online(ls)
        }
    }
    
    func connectNewDevice(creds: MatrixCredentials, password: String) async throws {
        // Connect to the homeserver using the given creds, as usual
        try await connect(creds: creds)
        // But since we're a new device, we have some housekeeping work to do
        // 1. Cross-signing
        // 2. Generate the key for Recovery / S4 / Encrypted Backup and connect to it
        guard case let .online(legacyStore) = self.state
        else {
            // Guess we failed to connect.  No need to do the post-connect setup then.
            return
        }
        
        // 1. Cross-signing
        legacyStore.setupCrossSigning(password: password)
        
        // 2. Recovery
        let recoveryKey = try await generateRecoveryKey(userId: creds.userId, password: password)
        UserDefaults.standard.set(recoveryKey, forKey: "recovery_key[\(creds.userId)]")
        legacyStore.setupRecovery(key: recoveryKey)
    }
    
    func generateRecoveryKey(userId: String, password: String) async throws -> Data {
        guard let userData = userId.data(using: .utf8) else {
            let msg = "Failed to convert user id to data"
            print("KEYGEN\t\(msg)")
            throw CirclesError(msg)
        }

        let saltDigest = SHA256.hash(data: userData)
        let saltString = saltDigest
            .map { String(format: "%02hhx", $0) }
            .prefix(16)
            .joined()
        print("KEYGEN\tComputed salt string = [\(saltString)]")

        let numRounds = 14
        guard let bcrypt = try? BCrypt.Hash(password, salt: "$2a$\(numRounds)$\(saltString)")
        else {
            let msg = "BCrypt KDF failed"
            print("KEYGEN\t\(msg)")
            throw CirclesError(msg)
        }
        //print("KEYGEN\tGot bcrypt hash = [\(bcrypt)]")
        //print("       \t                   12345678901234567890123456789012345678901234567890")

        // Grabbing only the last 31 chars gives us just the hash
        let root = String(bcrypt.suffix(31))

        let recoveryKey = SHA256.hash(data: "Recovery|\(root)".data(using: .utf8)!)
            .withUnsafeBytes {
                Data(Array($0))
            }
        print("KEYGEN\tGot new recovery key = [\(recoveryKey)]")

        return recoveryKey
    }
    
    func login(username: String) async throws {
        // First we have to look at what the user entered for their username
        // - Is it a full Matrix user id?  If so, we need to find the homeserver for their domain.
        // - If it's not a full user id, then we assume the domain is our own, and we find the homeserver based on the country code of the user's StoreKit storefront
        // Then we create a LoginSession with the given homeserver, and set our state to .loggingIn
        
        let userDomain = getDomainFromUserId(username)
        guard let domain = userDomain ?? ourDomain
        else {
            let err = CirclesError("Couldn't find domain for \(username)")
            self.state = .nothing(err)
            return
        }
        
        let wellKnown = try await fetchWellKnown(for: domain)
        let homeserverUrl = URL(string: wellKnown.homeserver.baseUrl)!
        let loginSession = LoginSession(username: username,
                                        homeserverUrl: homeserverUrl,
                                        store: self)
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
        let wellKnown = try await fetchWellKnown(for: domain)
        if let hsUrl = URL(string: wellKnown.homeserver.baseUrl) {
            let deviceModel = await UIDevice.current.model
            let signupSession = SignupSession(homeserver: hsUrl, initialDeviceDisplayName: "Circles (\(deviceModel))")
            await MainActor.run {
                self.state = .signingUp(signupSession)
            }
        }
    }
    
    func beginSetup(creds: MatrixCredentials) async throws {
        await MainActor.run {
            self.state = .settingUp(creds)
        }
    }
    
    func disconnect() async throws {
        // First disconnect any connected session
        // Then set our state to .nothing
        await MainActor.run {
            self.state = .nothing(nil)
        }
    }
    
    // MARK: Domain handling
    
    func getDomainFromUserId(_ userId: String) -> String? {
        let toks = userId.split(separator: ":")
        if toks.count != 2 {
            return nil
        }

        let domain = String(toks[1])
        return domain
    }
    
    private var ourDomain: String? {

        guard let countryCode = SKPaymentQueue.default().storefront?.countryCode else {
            print("DOMAIN\tCouldn't get country code from SKPaymentQueue")
            return nil
        }

        let usDomain = "kombucha.social"
        let euDomain = "eu.kombucha.social"

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
    
    // MARK: Well known
    
    private func fetchWellKnown(for domain: String) async throws -> MatrixWellKnown {
        
        guard let url = URL(string: "https://\(domain)/.well-known/matrix/client") else {
            let msg = "Couldn't construct well-known URL"
            print("WELLKNOWN\t\(msg)")
            throw CirclesError(msg)
        }
        print("WELLKNOWN\tURL is \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        //request.cachePolicy = .reloadIgnoringLocalCacheData
        request.cachePolicy = .returnCacheDataElseLoad

        
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            let msg = "Couldn't decode HTTP response"
            print("WELLKNOWN\t\(msg)")
            throw CirclesError(msg)
        }
        guard httpResponse.statusCode == 200 else {
            let msg = "HTTP request failed"
            print("WELLKNOWN\t\(msg)")
            throw CirclesError(msg)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let stuff = String(data: data, encoding: .utf8)!
        print("WELLKNOWN\tGot response data:\n\(stuff)")
        guard let wellKnown = try? decoder.decode(MatrixWellKnown.self, from: data) else {
            let msg = "Couldn't decode response data"
            print("WELLKNOWN\t\(msg)")
            throw CirclesError(msg)
        }
        print("WELLKNOWN\tSuccess!")
        return wellKnown
    }
}
