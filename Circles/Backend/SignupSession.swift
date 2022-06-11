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
    
    
    func doTokenRegistrationStage(token: String) async throws {
        guard _checkBasicSanity(userInput: token) == true
        else {
            let msg = "Invalid token"
            print("Token registration Error: \(msg)")
            throw CirclesError(msg)
        }
        
        let tokenAuthDict: [String: String] = [
            "type": "m.login.registration_token",
            "token": token,
        ]
        try await doUIAuthStage(auth: tokenAuthDict)
    }
    
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
}

