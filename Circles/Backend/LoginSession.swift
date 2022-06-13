//
//  LoginSession.swift
//  Circles
//
//  Created by Charles Wright on 6/8/22.
//

import Foundation

public class LoginSession: ObservableObject {
    let username: String
    let homeserverUrl: URL
    var store: CirclesStore
    let version = "r0"
    
    struct Error: Swift.Error {
        var msg: String
        init(_ msg: String) {
            self.msg = msg
        }
    }
    
    enum State {
        case notConnected
        case connected([String],String?)
        case inProgress(String)
        case failed(String)
        case succeeded(MatrixCredentials,String)
    }
    @Published var state: State
    
    init(username: String, homeserverUrl: URL, store: CirclesStore) {
        self.username = username
        self.homeserverUrl = homeserverUrl
        self.store = store
        self.state = .notConnected
        
        // Launch an async task to initialize ourselves
        let _ = Task {
            try await self.connect()
        }
    }
    
    // Make a call to GET /_matrix/client/v3/login to find out which login types are supported
    // https://spec.matrix.org/v1.2/client-server-api/#get_matrixclientv3login
    func connect() async throws {
        let url = URL(string: "_matrix/client/\(version)/login", relativeTo: homeserverUrl)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
          200 == httpResponse.statusCode
        else {
            let msg = "Could not get the list of allowable login types from server \(homeserverUrl.host!)"
            await MainActor.run {
                self.state = .failed(msg)
            }
            return
        }
        
        struct ResponseBody: Codable {
            struct LoginFlow: Codable {
                var type: String
            }
            var flows: [LoginFlow]
        }
        
        let decoder = JSONDecoder()
        guard let responseBody = try? decoder.decode(ResponseBody.self, from: data)
        else {
            let msg = "Could not parse the list of allowable login types from server \(homeserverUrl.host!)"
            await MainActor.run {
                self.state = .failed(msg)
            }
            return
        }
        
        // Extract the list of all the different auth types that we have been offered
        let authTypes = responseBody.flows.map {
            $0.type
        }
        
        // And update our state with the initialized list from the server
        await MainActor.run {
            self.state = .connected(authTypes, nil)
        }
    }
    
    func passwordLogin(_ password: String) async throws {
        
        guard case .connected(let flows, let error) = state
        else {
            print("LOGIN\tCan't log in until we're connected!")
            return
        }
                
        struct RequestBody: Encodable {
            let type = "m.login.password"
            struct Identifier: Encodable {
                let type = "m.id.user"
                var user: String
            }
            var identifier: Identifier
            var password: String
            
            init(user: String, password: String) {
                self.identifier = Identifier(user: user)
                self.password = password
            }
        }
        var requestBody = RequestBody(user: username, password: password)
        
        var url = URL(string: "_matrix/client/\(version)/login", relativeTo: homeserverUrl)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let encoder = JSONEncoder()
        
        request.httpBody = try encoder.encode(requestBody)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
          [200].contains(httpResponse.statusCode)
        else {
            let msg = "Login request failed"
            print("LOGIN\t\(msg)")
            await MainActor.run {
                self.state = .connected(flows, msg)
            }
            return
        }
        print("LOGIN\tLogin request success!")
        let raw = String(decoding: data, as: UTF8.self)
        print("LOGIN\tRaw response data = \(raw)")
            
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let creds = try? decoder.decode(MatrixCredentials.self, from: data)
        else {
            let msg = "Could not decode credentials"
            await MainActor.run {
                self.state = .connected(flows, msg)
            }
            return
        }
        
        //let creds = MatrixCredentials(accessToken: creds1.accessToken, deviceId: creds1.deviceId, userId: creds1.userId)
        
        await MainActor.run {
            self.state = .succeeded(creds, password)
        }
        
        saveCredentials(username: username, creds: creds)
        
        // Anyway, we might as well try to connect now, right?
        _ = Task {
            try await self.store.connect(creds: creds)
        }
    }
    
    private func saveCredentials(username: String, creds: MatrixCredentials) {
        // Save credentials in case the app is closed and re-started
        let defaults = UserDefaults.standard
        defaults.set(creds.userId, forKey: "user_id")
        defaults.set(creds.deviceId, forKey: "device_id[\(creds.userId)]")
        defaults.set(creds.accessToken, forKey: "access_token[\(creds.userId)]")
 
        print("LOGIN\tSaved credentials to UserDefaults")

    }
}
