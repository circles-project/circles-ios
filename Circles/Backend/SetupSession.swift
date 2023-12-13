//
//  SetupSession.swift
//  Circles
//
//  Created by Charles Wright on 6/14/22.
//

import Foundation
import UIKit
import os
import Matrix

class SetupSession: ObservableObject {
    var logger: os.Logger
    var client: Matrix.Client
    
    enum State {
        case profile
        case circles(String)
        case allDone(CirclesConfigContent)
    }
    @Published var state: State
    
    init(creds: Matrix.Credentials) async throws {
        let logger = os.Logger(subsystem: "circles", category: "setup")
        self.logger = logger

        logger.debug("Intialzing Matrix client")
        let client = try await Matrix.Client(creds: creds)
        self.client = client
        
        let userId = client.creds.userId
        let (displayName, mxc) = try await client.getProfileInfo(userId: userId)
        
        if let displayName = displayName,
           let _ = mxc
        {
            if let config = try? await client.getAccountData(for: EVENT_TYPE_CIRCLES_CONFIG, of: CirclesConfigContent.self) {
                logger.debug("Setting state to .allDone")
                self.state = .allDone(config)
            } else {
                logger.debug("Setting state to .circles")
                self.state = .circles(displayName)
            }
        } else {
            logger.debug("Setting state to .profile")
            self.state = .profile
        }
    }
    
    init(matrix client: Matrix.Client) {
        self.logger = os.Logger(subsystem: "circles", category: "setup")
        logger.debug("Intialzing Matrix client")
        self.client = client
        logger.debug("Setting state to .profile")
        self.state = .profile
    }
    
    func setupProfile(name: String, avatar: UIImage?) async throws {
        logger.debug("Setting displayname")
        try await client.setMyDisplayName(name)
        if let image = avatar {
            logger.debug("Setting avatar image")
            try await client.setMyAvatarImage(image)
        }
        logger.debug("Setting state to .circles")
        await MainActor.run {
            self.state = .circles(name)
        }
    }
    
    func setAllDone(config: CirclesConfigContent) async {
        logger.debug("Setting state to .allDone")
        await MainActor.run {
            self.state = .allDone(config)
        }
    }
    
}
