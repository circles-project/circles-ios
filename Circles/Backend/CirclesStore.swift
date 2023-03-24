//
//  CirclesStore.swift
//  Circles
//
//  Created by Charles Wright on 6/7/22.
//

import Foundation
import StoreKit

import CryptoKit
import Matrix


public class CirclesStore: ObservableObject {
    
    enum State {
        case starting
        case nothing(CirclesError?)
        case loggingIn(LoginSession) // Because /login can now take more than a simple username/password
        case haveCreds(Matrix.Credentials)
        case online(CirclesSession)
        case signingUp(SignupSession)
        case settingUp(SetupSession) // or should this be (MatrixInterface) ???
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

        let _ = Task {
            guard let creds = loadCredentials()
            else {
                // Apparently we're offline, waiting for (valid) credentials to log in
                print("STORE\tDidn't find valid login credentials - Setting state to .nothing")
                await MainActor.run {
                    self.state = .nothing(nil)
                }
                return
            }
         
            // Woo we have credentials
            await MainActor.run {
                self.state = .haveCreds(creds)
            }
            
            // Now let's see if we can use them to connect
            try await self.connect(creds: creds)
        }
    }
    
    private func loadSyncToken(userId: UserId, deviceId: String) -> String? {
        UserDefaults.standard.string(forKey: "sync_token[\(userId)::\(deviceId)]")
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
    
    func connect(creds: Matrix.Credentials) async throws {
        let token = loadSyncToken(userId: creds.userId, deviceId: creds.deviceId)
        let matrix = try await Matrix.Session(creds: creds, syncToken: token)
        let session = try await CirclesSession.factory(matrix: matrix)
        await MainActor.run {
            self.state = .online(session)
        }
    }

    
    func login(userId: UserId) async throws {
        let loginSession = try await LoginSession(username: userId.username, domain: userId.domain)
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
        let signupSession = try await SignupSession(domain: domain, initialDeviceDisplayName: "Circles (\(deviceModel))")
        await MainActor.run {
            self.state = .signingUp(signupSession)
        }
    }
    
    func beginSetup(creds: Matrix.Credentials, displayName: String) async throws {
        
        var fullCreds = creds
        
        if fullCreds.wellKnown == nil {
            let domain = creds.userId.domain
            fullCreds.wellKnown = try await Matrix.fetchWellKnown(for: domain)
        }
        
        let session = try SetupSession(creds: fullCreds, store: self, displayName: displayName)
        await MainActor.run {
            self.state = .settingUp(session)
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

        let usDomain = "circu.li"
        let euDomain = "eu.circu.li"

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
