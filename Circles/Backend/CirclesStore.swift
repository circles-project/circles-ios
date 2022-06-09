//
//  CirclesStore.swift
//  Circles
//
//  Created by Charles Wright on 6/7/22.
//

import Foundation
import StoreKit

//import MatrixSDK

public class CirclesStore: ObservableObject {
    
    enum State {
        case nothing(Error?)
        case loggingIn(LoginSession) // Because /login will soon take more than a simple username/password
        case haveCreds(MatrixCredentials)
        case online(MatrixInterface)
        case signingUp(SignupSession)
        case settingUp(MatrixCredentials) // or should this be (MatrixInterface) ???
    }
    @Published var state: State
    
    
    init() {
        // Ok, we're just starting out
        // We can realistically be in one of just two states.
        // Either:
        // .haveCreds - if we can find credentials in the user defaults
        // or
        // .nothing - if there are no creds to be found

        guard let userId = UserDefaults.standard.string(forKey: "user_id"),
              !userId.isEmpty,
              let deviceId = UserDefaults.standard.string(forKey: "device_id[\(userId)]"),
              let accessToken = UserDefaults.standard.string(forKey: "access_token[\(userId)]"),
              !accessToken.isEmpty
        else {
            // Apparently we're offline, waiting for (valid) credentials to log in
            print("STORE\tDidn't find valid login credentials - Setting state to .nothing")
            self.state = .nothing(nil)
            return
        }

        let creds = MatrixCredentials(accessToken: accessToken,
                                      deviceId: deviceId,
                                      userId: userId)
        self.state = .haveCreds(creds)
        
        // Might as well try to connect while we're here, right?
        _ = Task  {
            try await connect(creds: creds)
        }
    }
    
    func connect(creds: MatrixCredentials) async throws {
        // Fetch homeserver info using well-known URL
        // Init a new MatrixSession with that homeserver and these creds
        // Set our state to be online with that session
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
        let homeserverUrl = URL(string: wellKnown.homeserver.base_url)!
        let loginSession = LoginSession(homeserverUrl: homeserverUrl, store: self)
        self.state = .loggingIn(loginSession)
    }
    
    func signup() async throws {
        // We only support signing up on our own servers
        // Look at the country code of the user's StoreKit storefront to decide which server we should use
        // Create a SignupSession and set our state to .signingUp
    }
    
    func setup(creds: MatrixCredentials) async throws {
        self.state = .settingUp(creds)
    }
    
    func disconnect() async throws {
        // First disconnect any connected session
        // Then set our state to .nothing
        self.state = .nothing(nil)
    }
    
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
        //decoder.keyDecodingStrategy = .convertFromSnakeCase
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
