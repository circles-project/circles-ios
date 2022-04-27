//
//  UIAuthSession.swift
//  Circles
//
//  Created by Charles Wright on 4/26/22.
//

import Foundation
import AnyCodable
import BlindSaltSpeke

protocol UIASession {
    var url: URL { get }
    
    var state: UIAuthSession.State { get }
    
    var sessionId: String? { get }
    
    func initialize() async throws
    
    func selectFlow(flow: UIAA.Flow)
    
    func doUIAuthStage(auth: [String:String]) async throws
    
    func doTermsStage() async throws
    
}

class UIAuthSession: UIASession {
        
    enum State {
        case notInitialized
        case initialized(UIAA.SessionState)
        case inProgress(UIAA.SessionState,UIAA.Flow)
        case finished(MatrixCredentials)
    }
    
    let url: URL
    //let accessToken: String? // FIXME: Make this MatrixCredentials ???
    let creds: MatrixCredentials?
    var state: State
    var realRequestDict: [String:AnyCodable] // The JSON fields for the "real" request behind the UIA protection
    var storage = [String: Any]() // For holding onto data between requests, like we do on the server side
    
    // Shortcut to get around a bunch of `case let` nonsense everywhere
    var sessionState: UIAA.SessionState? {
        switch state {
        case .initialized(let sessionState):
            return sessionState
        case .inProgress(let sessionState, _):
            return sessionState
        default:
            return nil
        }
    }
        
    init(_ url: URL, credentials: MatrixCredentials? = nil, requestDict: [String:AnyCodable]) {
        self.url = url
        //self.accessToken = accessToken
        self.creds = credentials
        self.state = .notInitialized
        self.realRequestDict = requestDict
        
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
    
    func _checkBasicSanity(userInput: String) -> Bool {
        if userInput.contains(" ")
            || userInput.contains("\"")
            || userInput.isEmpty
        {
            return false
        }
        return true
    }
    
    func _looksLikeValidEmail(userInput: String) -> Bool {
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
        if let accessToken = self.creds?.accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(self.realRequestDict)
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
    
    func doPasswordAuthStage(password: String) async throws {

        // Added base64 encoding here to prevent a possible injection attack on the password field
        let base64Password = Data(password.utf8).base64EncodedString()

        let passwordAuthDict: [String: String] = [
            "type": "m.login.password",
            "password": base64Password,
        ]
        
        try await doUIAuthStage(auth: passwordAuthDict)
    }
    
    func doPasswordEnrollStage(newPassword: String) async throws {
        let base64Password = Data(newPassword.utf8).base64EncodedString()

        let passwordAuthDict: [String: String] = [
            "type": "m.enroll.password",
            "new_password": base64Password,
        ]
        
        try await doUIAuthStage(auth: passwordAuthDict)
    }

    
    func doTermsStage() async throws {
        let auth: [String: String] = [
            "type": "m.login.terms",
        ]
        try await doUIAuthStage(auth: auth)
    }
    
    // FIXME: We need some way to know if this succeeded or failed
    func doUIAuthStage(auth: [String:String]) async throws {
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
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // We want to be generic: Handle both kinds of use cases: (1) signup (no access token) and (2) re-auth (already have an access token, but need to re-verify identity)
        if let accessToken = self.creds?.accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        var requestBodyDict: [String: AnyCodable] = self.realRequestDict
        requestBodyDict["auth"] = AnyCodable(auth)
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestBodyDict)
        
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
            let decoder = JSONDecoder()
            guard let newCreds = try? decoder.decode(MatrixCredentials.self, from: data)
            else {
                // Throw some error
                print("\(tag) Error: Couldn't decode Matrix credentials")
                return
            }
            state = .finished(newCreds)
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

// BS-SPEKE protocol support
extension UIAuthSession {
    
    // NOTE: The ..Enroll.. functions are *almost* but not exactly duplicates of those in the SignupSession implementation
    func doBSSpekeEnrollOprfStage(password: String) async throws {
        let stage = AUTH_TYPE_BSSPEKE_ENROLL_OPRF
        
        guard let userId = self.creds?.userId else {
            return
        }
        
        let bss = try BlindSaltSpeke.ClientSession(clientId: userId, serverId: self.url.host!, password: password)
        let blind = bss.generateBlind()
        let args: [String: String] = [
            "blind": Data(blind).base64EncodedString(),
            "curve": "curve25519",
        ]
        self.storage[stage+".state"] = bss
        try await doUIAuthStage(auth: args)
    }
    
    // OK this one *is* exactly the same as in SignupSession
    func doBSSpekeEnrollSaveStage() async throws {
        // Need to send
        // V, our long-term public key (from "verifier"?  Although here the actual verifiers are hashes.)
        // P, our base point on the curve
        let stage = AUTH_TYPE_BSSPEKE_ENROLL_SAVE
        
        guard let bss = self.storage[AUTH_TYPE_BSSPEKE_ENROLL_OPRF+".state"] as? BlindSaltSpeke.ClientSession
        else {
            print("BS-SPEKE\tError: Couldn't find saved BS-SPEKE session")
            return
        }
        guard let params = self.sessionState?.params?[stage] as? BSSpekeEnrollParams
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
            "type": stage,
            "P": Data(P).base64EncodedString(),
            "V": Data(V).base64EncodedString(),
        ]
        try await doUIAuthStage(auth: args)
    }
    
    func doBSSpekeLoginOprfStage(password: String) async throws {
        let stage = AUTH_TYPE_BSSPEKE_LOGIN_OPRF
        
        guard let userId = self.creds?.userId else {
            return
        }
        
        let bss = try BlindSaltSpeke.ClientSession(clientId: userId, serverId: self.url.host!, password: password)
        let blind = bss.generateBlind()
        let args: [String: String] = [
            "type": stage,
            "blind": Data(blind).base64EncodedString(),
            "curve": "curve25519",
        ]
        self.storage[stage+".state"] = bss
        try await doUIAuthStage(auth: args)
    }
    
    func doBSSpekeLoginVerifyStage() async throws {
        // Need to send
        // V, our long-term public key (from "verifier"?  Although here the actual verifiers are hashes.)
        // P, our base point on the curve
        let stage = AUTH_TYPE_BSSPEKE_LOGIN_VERIFY
        
        guard let bss = self.storage[AUTH_TYPE_BSSPEKE_LOGIN_OPRF+".state"] as? BlindSaltSpeke.ClientSession
        else {
            print("BS-SPEKE\tError: Couldn't find saved BS-SPEKE session")
            return
        }
        guard let params = self.sessionState?.params?[stage] as? BSSpekeEnrollParams
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
            "type": stage,
            "P": Data(P).base64EncodedString(),
            "V": Data(V).base64EncodedString(),
        ]
        try await doUIAuthStage(auth: args)
    }
    
}