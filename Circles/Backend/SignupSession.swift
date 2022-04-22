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
class SignupSession {
    
    enum State {
        case notInitialized
        case initialized(UIAA.SessionState)
        case inProgress(UIAA.SessionState,UIAA.Flow)
        case finished
    }
    
    let url: URL
    var state: State
    let username: String?
    let deviceId: String?
    let initialDeviceDisplayName: String?
    let inhibitLogin = true
        
    init(_ url: URL, username: String? = nil, deviceId: String? = nil, initialDeviceDisplayName: String? = nil) {
        self.url = url
        self.username = username
        self.state = .notInitialized
        self.deviceId = deviceId
        self.initialDeviceDisplayName = initialDeviceDisplayName
        
        let initTask = Task {
            try await self.initialize()
        }
    }
    
    var sessionId: String? {
        switch state {
        case .inProgress(let (uiaaState, selectedFlow)):
            return uiaaState.session
        default:
            return nil
        }
    }
    
    private func _checkBasicSanity(userInput: String) -> Bool {
        if userInput.contains(" ")
            || userInput.contains("\"")
            || userInput.isEmpty
        {
            return false
        }
        return true
    }
    
    private func _looksLikeValidEmail(userInput: String) -> Bool {
        if !_checkBasicSanity(userInput: userInput) {
            return false
        }
        if !userInput.contains("@")
            || userInput.hasPrefix("@") // Must have a user part before the @
            || userInput.hasSuffix("@") // Must have a domain part after the @
            || !userInput.contains(".") // Must have a dot somewhere
        {
            return false
        }
        
        // OK now we can bring out the big guns
        // See https://multithreaded.stitchfix.com/blog/2016/11/02/email-validation-swift/
        // And Apple's documentation on the DataDetector
        // https://developer.apple.com/documentation/foundation/nsdatadetector
        guard let dataDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        else {
            return false
        }
        
        let range = NSMakeRange(0, NSString(string: userInput).length)
        let allMatches = dataDetector.matches(in: userInput,
                                              options: [],
                                              range: range)
        if allMatches.count == 1,
            allMatches.first?.url?.absoluteString.contains("mailto:") == true
        {
            return true
        }
        return false
    }
    
    func initialize() async throws {
        let tag = "SIGNUP(start)"
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = """
        {
            "x_show_msisdn": false
        }
        """
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .data(using: .ascii)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        print("SIGNUP(start)\tTrying to parse the response")
        guard let httpResponse = response as? HTTPURLResponse else {
            let msg = "Couldn't decode HTTP response"
            print("SIGNUP(start)\t\(msg)")
            return
        }
        
        guard httpResponse.statusCode == 401 else {
            let msg = "Got unexpected HTTP response code (\(httpResponse.statusCode))"
            print("SIGNUP(start)\t\(msg)")
            return
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        guard let sessionState = try? decoder.decode(UIAA.SessionState.self, from: data) else {
            let msg = "Couldn't decode response"
            print("SIGNUP(start)\t\(msg)")
            return
        }
        
        //self.state = .inProgress(sessionState)
        self.state = .initialized(sessionState)
    }
    
    func selectFlow(flow: UIAA.Flow) {
        guard case .initialized(let uiaState) = state else {
            // throw some error
            return
        }
        guard uiaState.flows.contains(flow) else {
            // throw some error
            return
        }
        self.state = .inProgress(uiaState, flow)
    }
    
    func doPasswordStage(password: String) async throws {

        // Added base64 encoding here to prevent a possible injection attack on the password field
        let base64Password = Data(password.utf8).base64EncodedString()

        let passwordAuthDict: [String: String] = [
            "type": "m.login.password",
            "password": base64Password,
        ]
        
        try await doGenericUIAuthStage(auth: passwordAuthDict)
    }
    
    func doEmailRequestTokenStage(email: String) async throws -> String? {

        guard _looksLikeValidEmail(userInput: email) == true
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
        try await doGenericUIAuthStage(auth: emailAuthDict)
        
        return clientSecret
    }
    
    func doEmailSubmitTokenStage(token: String, secret: String) async throws {
        let emailAuthDict: [String: String] = [
            "type": "m.enroll.email.submit_token",
            "token": token,
            "client_secret": secret,
        ]
        try await doGenericUIAuthStage(auth: emailAuthDict)
    }
    
    func doTokenRegistrationStage(token: String) async throws {
        guard _checkBasicSanity(userInput: token) == true
        else {
            // Throw some kind of error
            print("Error: Invalid token")
            return
        }
        
        let tokenAuthDict: [String: String] = [
            "type": "m.login.registration_token",
            "token": token,
        ]
        try await doGenericUIAuthStage(auth: tokenAuthDict)
    }
    
    func doTermsStage() async throws {
        let auth: [String: String] = [
            "type": "m.login.terms",
        ]
        try await doGenericUIAuthStage(auth: auth)
    }
    
    // FIXME: We need some way to know if this succeeded or failed
    func doGenericUIAuthStage(auth: [String:String]) async throws {
        guard let AUTH_TYPE = auth["type"] else {
            print("No auth type")
            return
        }
        let tag = "SIGNUP(\(AUTH_TYPE))"
        
        guard case .inProgress(let (uiaState,selectedFlow)) = state else {
            let msg = "Signup session must be started before attempting email stage"
            print("\(tag) \(msg)")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        struct GenericRegisterUIAuthRequestBody: Codable {
            var username: String?
            var deviceId: String?
            var initialDeviceDisplayName: String?
            var inhibitLogin: Bool
            var auth: [String: String]
            init(username: String? = nil,
                 deviceId: String? = nil,
                 initialDeviceDisplayName: String? = nil,
                 inhibitLogin: Bool,
                 auth: [String:String],
                 sessionId: String)
            {
                self.username = username
                self.deviceId = deviceId
                self.inhibitLogin = inhibitLogin
                
                self.auth = .init()
                self.auth.merge(auth, uniquingKeysWith: { (a,b) -> String in
                    a
                })
                self.auth["session"] = sessionId
            }
        }
        let gruiarb = GenericRegisterUIAuthRequestBody(
            username: self.username,
            deviceId: self.deviceId,
            initialDeviceDisplayName: self.initialDeviceDisplayName,
            inhibitLogin: self.inhibitLogin,
            auth: auth,
            sessionId: uiaState.session)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(gruiarb)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
          [200,401].contains(httpResponse.statusCode)
        else {
            let msg = "UI auth stage failed"
            print("\(tag) Error: \(msg)")
            return
        }
        
        if httpResponse.statusCode == 200 {
            print("\(tag) All done!")
            state = .finished
            return
        }
        
        let decoder = JSONDecoder()
        guard let newUiaaState = try? decoder.decode(UIAA.SessionState.self, from: data)
        else {
            let msg = "Couldn't decode UIA response"
            print("\(tag) Error: \(msg)")
            return
        }
        
        if let completed = newUiaaState.completed as? [String] {
            if completed.contains(AUTH_TYPE) {
                // Swift: You can't have a .dropFirst() method on your String array
                // Me: Fuck you, I do what I want.
                let newFlow = UIAA.Flow(stages: selectedFlow.stages.reversed().dropLast().reversed())
            }
        }
        
        state = .inProgress(newUiaaState,selectedFlow)
    }
}
