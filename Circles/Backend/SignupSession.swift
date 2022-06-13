//
//  SignupSession.swift
//  Circles
//
//  Created by Charles Wright on 4/20/22.
//

import Foundation
import AnyCodable
import BlindSaltSpeke

// Implements the Matrix UI Auth for the Matrix /register endpoint
// https://spec.matrix.org/v1.2/client-server-api/#post_matrixclientv3register

class SignupSession: UIAuthSession {
    var desiredUsername: String?
    //let deviceId: String?
    //let initialDeviceDisplayName: String?
    //let inhibitLogin = false

    init(homeserver: URL,
         username: String? = nil,
         deviceId: String? = nil,
         initialDeviceDisplayName: String? = nil,
         showMSISDN: Bool = false,
         inhibitLogin: Bool = false
    ) {
        
        let signupURL = URL(string: "https://matrix.kombucha.social/_matrix/client/r0/register")!
        print("SIGNUP\tURL is \(signupURL)")
        var requestDict: [String: AnyCodable] = [:]
        if let u = username {
            requestDict["username"] = AnyCodable(u)
        } else {
            // doh..  Matrix wants us to have a username when we start trying to sign up
            let u = UInt32.random(in: UInt32.min ... UInt32.max)
            requestDict["username"] = AnyCodable("signup\(u)")
        }
        if let d = deviceId {
            requestDict["device_id"] = AnyCodable(d)
        }
        if let iddn = initialDeviceDisplayName {
            requestDict["initial_device_display_name"] = AnyCodable(iddn)
        }
        requestDict["x_show_msisdn"] = AnyCodable(showMSISDN)
        requestDict["inhibit_login"] = AnyCodable(inhibitLogin)
        super.init(signupURL, requestDict: requestDict)
        self.desiredUsername = username
    }
    
    // MARK: Set username and password
    
    func setUsername(_ username: String) {
        self.realRequestDict["username"] = AnyCodable(username)
    }
    
    func setPassword(_ password: String) {
        self.realRequestDict["password"] = AnyCodable(password)
    }
    
    // MARK: Token registration
    
    func doTokenRegistrationStage(token: String) async throws {
        guard _checkBasicSanity(userInput: token) == true
        else {
            let msg = "Invalid token"
            print("Token registration Error: \(msg)")
            throw CirclesError(msg)
        }
        
        // There are several different names for this thing.
        // Fortunately they all work the same way.
        // So we should just call it whatever the server calls it, and it should work.
        let authTypes = [
            LOGIN_STAGE_TOKEN_MATRIX,
            LOGIN_STAGE_TOKEN_MSC3231,
            LOGIN_STAGE_TOKEN_KOMBUCHA
        ]

        guard let uiaa = self.sessionState
        else {
            let msg = "No active auth session"
            print("Token registration error: \(msg)")
            throw CirclesError(msg)
        }
        
        guard let authType = authTypes.first(where: {
            for flow in uiaa.flows {
                if flow.stages.contains($0) {
                    return true
                }
            }
            return false
        })
        else {
            let msg = "Token registration not supported by server"
            print("Token registration error: \(msg)")
            throw CirclesError(msg)
        }
        print("TOKEN\tFound auth type = \(authType)")
        
        let tokenAuthDict: [String: String] = [
            "type": authType,
            "token": token,
        ]
        try await doUIAuthStage(auth: tokenAuthDict)
    }
    
    // MARK: (New) Email stages
    
    func doEmailRequestTokenStage(email: String) async throws -> String? {

        guard _looksLikeValidEmail(userInput: email) == true
        else {
            let msg = "Invalid email address"
            print("Email signup Error: \(msg)")
            throw CirclesError(msg)
        }
        
        let clientSecretNumber = UInt64.random(in: 0 ..< UInt64.max)
        let clientSecret = String(format: "%016x", clientSecretNumber)
        
        let emailAuthDict: [String: String] = [
            "type": "m.enroll.email.request_token",
            "email": email,
            "client_secret": clientSecret,
        ]
        
        // FIXME: We need to know if this succeeded or failed
        try await doUIAuthStage(auth: emailAuthDict)
        
        return clientSecret
    }
    
    func doEmailSubmitTokenStage(token: String, secret: String) async throws {
        let emailAuthDict: [String: String] = [
            "type": "m.enroll.email.submit_token",
            "token": token,
            "client_secret": secret,
        ]
        try await doUIAuthStage(auth: emailAuthDict)
    }
    
    private func _canonicalize(_ username: String) -> String {
        let tmp = username.starts(with: "@") ? username : "@\(username)"
        let userId = tmp.contains(":") ? tmp : "\(tmp):\(DEFAULT_DOMAIN)"
        return userId
    }
    
    // MARK: BS-SPEKE
    
    override func doBSSpekeEnrollOprfStage(password: String) async throws {
        let stage = AUTH_TYPE_BSSPEKE_ENROLL_OPRF
        
        guard let username = self.desiredUsername else {
            let msg = "Desired username must be set before attempting BS-SPEKE stages"
            print(msg)
            throw CirclesError(msg)
        }
        
        let userId = _canonicalize(username)
        let bss = try BlindSaltSpeke.ClientSession(clientId: userId, serverId: SIGNUP_HOMESERVER_URL.host!, password: password)
        let blind = bss.generateBlind()
        let args: [String: String] = [
            "type": stage,
            "blind": Data(blind).base64EncodedString(),
            "curve": "curve25519",
        ]
        self.storage[stage+".state"] = bss
        try await doUIAuthStage(auth: args)
    }
    
    override func doBSSpekeEnrollSaveStage() async throws {
        // Need to send
        // * A, our ephemeral public key
        // * verifier, to prove that we derived the correct secret key
        //   - To do this, we have to derive the secret key
        let stage = AUTH_TYPE_BSSPEKE_ENROLL_SAVE
        
        guard let bss = self.storage[AUTH_TYPE_BSSPEKE_ENROLL_OPRF+".state"] as? BlindSaltSpeke.ClientSession
        else {
            let msg = "Couldn't find saved BS-SPEKE session"
            print("BS-SPEKE\tError: \(msg)")
            throw CirclesError(msg)
        }
        guard let params = sessionState?.params?[stage] as? BSSpekeEnrollParams
        else {
            let msg = "Couldn't find BS-SPEKE enroll params"
            print("BS-SPEKE\t\(msg)")
            throw CirclesError(msg)
        }
        guard let blindSalt = b64decode(params.blindSalt)
        else {
            let msg = "Failed to decode base64 blind salt"
            print("BS-SPEKE\t\(msg)")
            throw CirclesError(msg)
        }
        let blocks = params.phfParams.blocks
        let iterations = params.phfParams.iterations
        guard let (P,V) = try? bss.generatePandV(blindSalt: blindSalt, phfBlocks: UInt32(blocks), phfIterations: UInt32(iterations))
        else {
            let msg = "Failed to generate public key"
            print("BS-SPEKE\t\(msg)")
            throw CirclesError(msg)
        }
        
        let args: [String: String] = [
            "type": stage,
            "P": Data(P).base64EncodedString(),
            "V": Data(V).base64EncodedString(),
        ]
        try await doUIAuthStage(auth: args)
    }
    
    // MARK: Apple Subscriptions
    
    func doAppleSubscriptionStage(receipt: String) async throws {
        let stage = LOGIN_STAGE_APPLE_SUBSCRIPTION
        let args = [
            "type": stage,
            "receipt": receipt,
        ]
        try await doUIAuthStage(auth: args)
    }
    
    // MARK: Legacy email handling
    
    struct LegacyEmailRequestTokenResponse: Codable {
        var sid: String
        var submitUrl: URL?
    }
    
    func doLegacyEmailRequestToken(address: String) async throws -> LegacyEmailRequestTokenResponse {
        let version = "r0"
        let url = URL(string: "https://\(url.host!)/_matrix/client/\(version)/register/email/requestToken")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        struct RequestBody: Codable {
            var clientSecret: String
            var email: String
            var sendAttempt: Int
        }
        guard let sessionId = self.sessionState?.session else {
            let msg = "Must have an active session before attempting email stage"
            print("LEGACY-EMAIL\t\(msg)")
            throw CirclesError(msg)
        }
        
        let requestBody = RequestBody(clientSecret: sessionId, email: address, sendAttempt: 1)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
          [200,401].contains(httpResponse.statusCode)
        else {
            let msg = "Email token request failed"
            print("LEGACY-EMAIL\tError: \(msg)")
            throw CirclesError(msg)
        }
        

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let responseBody = try? decoder.decode(LegacyEmailRequestTokenResponse.self, from: data)
        else {
            let msg = "Could not decode response from server"
            print("LEGACY-EMAIL\tError: \(msg)")
            throw CirclesError(msg)
        }
        
        // FIXME Why not just return the whole thing?
        // Don't we need both the sid and the url???
        // Or we could save them in our local storage in the session!
        return responseBody
    }
    
    func doLegacyEmailValidateAddress(token: String, sid: String, url: URL) async throws -> Bool {
        
        guard let sessionId = self.sessionId else {
            let msg = "No active signup session"
            print("LEGACY-EMAIL\t\(msg)")
            throw CirclesError(msg)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let args = [
            "sid": sid,
            "client_secret": sessionId,
            "token": token,
        ]
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(args)
        
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
          [200,401].contains(httpResponse.statusCode)
        else {
            let msg = "Email token validation request failed"
            print("LEGACY-EMAIL\tError: \(msg)")
            throw CirclesError(msg)
        }
        
        struct SubmitTokenResponse: Codable {
            var success: Bool
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let contents = try? decoder.decode(SubmitTokenResponse.self, from: data) else {
            let msg = "Failed to decode response from server"
            print("LEGACY-EMAIL\t\(msg)")
            throw CirclesError(msg)
        }
        
        return contents.success
    }
    
    func doLegacyEmailStage(emailSessionId: String) async throws {
        guard let sessionId = self.sessionId else {
            let msg = "No active signup session"
            print("LEGACY-EMAIL\t\(msg)")
            throw CirclesError(msg)
        }
        let auth: [String: Codable] = [
            "type": "m.login.email.identity",
            "threepid_creds": [
                "sid": emailSessionId,
                "client_secret": sessionId,
            ],
        ]
        
        try await doUIAuthStage(auth: auth)
    }
}

