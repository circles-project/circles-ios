//
//  SignupSession.swift
//  Circles
//
//  Created by Charles Wright on 4/20/22.
//

import Foundation
import AnyCodable

// Implements the Matrix UI Auth for the Matrix /register endpoint
// https://spec.matrix.org/v1.2/client-server-api/#post_matrixclientv3register

class SignupSession: UIASession {
    var uia: UIAuthSession
    //var username: String?
    //let deviceId: String?
    //let initialDeviceDisplayName: String?
    //let inhibitLogin = false
    
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
}

