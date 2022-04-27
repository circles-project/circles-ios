//
//  SignupSession.swift
//  Circles
//
//  Created by Charles Wright on 4/20/22.
//

import Foundation
import AnyCodable
import BlindSaltSpeke

let AUTH_TYPE_BSSPEKE_ENROLL_OPRF = "m.enroll.bsspeke-ecc.oprf"
let AUTH_TYPE_BSSPEKE_ENROLL_SAVE = "m.enroll.bsspeke-ecc.save"

// Implements the Matrix UI Auth for the Matrix /register endpoint
// https://spec.matrix.org/v1.2/client-server-api/#post_matrixclientv3register

class SignupSession: UIASession {
    var uia: UIAuthSession
    var desiredUsername: String?
    //let deviceId: String?
    //let initialDeviceDisplayName: String?
    //let inhibitLogin = false
    private var storage = [String: Any]()
    
    var url: URL {
        self.uia.url
    }
    
    var state: UIAuthSession.State {
        self.uia.state
    }
    
    var sessionId: String? {
        self.uia.sessionId
    }

    init(homeserver: URL,
         username: String? = nil,
         deviceId: String? = nil,
         initialDeviceDisplayName: String? = nil,
         showMSISDN: Bool = false,
         inhibitLogin: Bool = false
    ) {
        
        let signupURL = URL(string: "/_matrix/client/v3/register", relativeTo: homeserver.baseURL)!
        let requestDict: [String: AnyCodable] = [
            "username": AnyCodable(username),
            "device_id": AnyCodable(deviceId),
            "initial_device_display_name": AnyCodable(initialDeviceDisplayName),
            "x_show_msisdn": AnyCodable(showMSISDN),
            "inhibit_login": AnyCodable(inhibitLogin),
        ]
        self.uia = UIAuthSession(signupURL, requestDict: requestDict)
        self.desiredUsername = username
    }
    
    func initialize() async throws {
        try await self.uia.initialize()
    }
    
    func selectFlow(flow: UIAA.Flow) {
        self.uia.selectFlow(flow: flow)
    }

    func doUIAuthStage(auth: [String : String]) async throws {
        try await self.uia.doUIAuthStage(auth: auth)
    }
    
    func doTokenRegistrationStage(token: String) async throws {
        guard self.uia._checkBasicSanity(userInput: token) == true
        else {
            // Throw some kind of error
            print("Error: Invalid token")
            return
        }
        
        let tokenAuthDict: [String: String] = [
            "type": "m.login.registration_token",
            "token": token,
        ]
        try await doUIAuthStage(auth: tokenAuthDict)
    }
    
    func doTermsStage() async throws {
        try await self.uia.doTermsStage()
    }
    
    func doEmailRequestTokenStage(email: String) async throws -> String? {

        guard self.uia._looksLikeValidEmail(userInput: email) == true
        else {
            // Throw some kind of error
            print("Error: Invalid email")
            return nil
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
    
    func doBSSpekeEnrollOprfStage(password: String) async throws {
        let stage = AUTH_TYPE_BSSPEKE_ENROLL_OPRF
        
        guard let username = self.desiredUsername else {
            return
        }
        
        let userId = _canonicalize(username)
        let bss = try BlindSaltSpeke.ClientSession(clientId: userId, serverId: SIGNUP_HOMESERVER_URL.host!, password: password)
        let blind = bss.generateBlind()
        let args: [String: String] = [
            "blind": Data(blind).base64EncodedString(),
            "curve": "curve25519",
        ]
        self.storage[AUTH_TYPE_BSSPEKE_ENROLL_OPRF+".state"] = bss
        try await doUIAuthStage(auth: args)
    }
    
    func doBSSpekeEnrollSaveStage() async throws {
        // Need to send
        // * A, our ephemeral public key
        // * verifier, to prove that we derived the correct secret key
        //   - To do this, we have to derive the secret key
        let stage = AUTH_TYPE_BSSPEKE_ENROLL_SAVE
        
        guard let bss = self.storage[AUTH_TYPE_BSSPEKE_ENROLL_OPRF+".state"] as? BlindSaltSpeke.ClientSession
        else {
            print("BS-SPEKE\tError: Couldn't find saved BS-SPEKE session")
            return
        }
        guard let params = self.uia.sessionState?.params?[stage] as? BSSpekeEnrollParams
        else {
            print("BS-SPEKE\tCouldn't find BS-SPEKE enroll params")
            return
        }
        guard let blindSalt = b64decode(params.blindSalt)
        else {
            print("BS-SPEKE\tFailed to decode base64 blind salt")
            return
        }
        let blocks = params.phfParams.blocks
        let iterations = params.phfParams.iterations
        guard let (P,V) = try? bss.generatePandV(blindSalt: blindSalt, phfBlocks: UInt32(blocks), phfIterations: UInt32(iterations))
        else {
            print("BS-SPEKE\tFailed to generate public key")
            return
        }
        
        let args: [String: String] = [
            "type": AUTH_TYPE_BSSPEKE_ENROLL_SAVE,
            "P": Data(P).base64EncodedString(),
            "V": Data(V).base64EncodedString(),
        ]
        try await doUIAuthStage(auth: args)
    }
}

