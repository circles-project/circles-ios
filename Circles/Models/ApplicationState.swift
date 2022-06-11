//
//  ApplicationState.swift
//  Circles
//
//  Created by Charles Wright on 5/10/22.
//

import Foundation

/*
class ApplicationState: ObservableObject {
    enum State {
        case loading
        case none
        case signingUp(SignupSession)
        case loggingIn(UIAuthSession)
        case loggedInDisconnected(MatrixCredentials)
        case connected(MatrixInterface)
    }
    
    @Published var state: State
    
    init() {
        self.state = .loading
        _ = Task {
            await load()
        }
    }
    
    func load() async {
        guard let userId = UserDefaults.standard.string(forKey: "user_id"),
              !userId.isEmpty,
              let deviceId = UserDefaults.standard.string(forKey: "device_id[\(userId)]"),
              let accessToken = UserDefaults.standard.string(forKey: "access_token[\(userId)]"),
              !accessToken.isEmpty
        else {
            // Apparently we're offline, waiting for (valid) credentials to log in
            self.state = .none
            return
        }
        
        // Update our state so that the application knows we're working on connecting to the server
        self.state = .loggedInDisconnected(MatrixCredentials(accessToken: accessToken, deviceId: deviceId, userId: userId))
        
        // Now actually start trying to connect
        do {
            self.state = .connected(<#T##MatrixInterface#>)
        } catch {
            // Apparently it didn't work :(
        }
    }
}
*/
