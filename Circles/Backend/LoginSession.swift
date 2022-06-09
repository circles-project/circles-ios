//
//  LoginSession.swift
//  Circles
//
//  Created by Charles Wright on 6/8/22.
//

import Foundation

public class LoginSession: ObservableObject {
    var homeserverUrl: URL
    var store: CirclesStore
    let version = "v3"
    
    struct Error: Swift.Error {
        var msg: String
        init(_ msg: String) {
            self.msg = msg
        }
    }
    
    enum State {
        case notInitialized
        case initialized([String])
        case inProgress(String)
        case failed(String)
        case succeeded(MatrixCredentials)
    }
    @Published var state: State
    
    init(homeserverUrl: URL, store: CirclesStore) {
        self.homeserverUrl = homeserverUrl
        self.store = store
        self.state = .notInitialized
        
        // Launch an async task to initialize ourselves
        let _ = Task {
            try await self.initialize()
        }
    }
    
    // Make a call to GET /_matrix/client/v3/login to find out which login types are supported
    // https://spec.matrix.org/v1.2/client-server-api/#get_matrixclientv3login
    func initialize() async throws {
        let url = URL(string: "_matrix/client/\(version)/login", relativeTo: homeserverUrl)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
          200 == httpResponse.statusCode
        else {
            let msg = "Could not get the list of allowable login types from server \(homeserverUrl.host!)"
            self.state = .failed(msg)
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
            self.state = .failed(msg)
        }
        
        // Extract the list of all the different auth types that we have been offered
        let authTypes = responseBody.flows.map {
            $0.type
        }
        
        // And update our state with the initialized list from the server
        self.state = .initialized(authTypes)
    }
    
}
