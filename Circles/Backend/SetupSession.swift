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
    var creds: Matrix.Credentials
    var store: CirclesStore
    var client: Matrix.Client
    
    enum State {
        case profile
        case circles(String)
        case allDone
    }
    @Published var state: State
    
    init(creds: Matrix.Credentials, store: CirclesStore) async throws {
        let logger = os.Logger(subsystem: "circles", category: "setup")
        self.logger = logger
        self.creds = creds
        self.store = store
        //self.client = try Matrix.Client(creds: creds)
        //logger.debug("Initializing Matrix session")
        //self.client = try await Matrix.Session(creds: creds, startSyncing: false, secretStorageKeyInfo: s4keyInfo)
        logger.debug("Intialzing Matrix client")
        self.client = try await Matrix.Client(creds: creds)
        logger.debug("Setting state to .profile")
        self.state = .profile
    }
    
    func setupProfile(name: String, avatar: UIImage) async throws {
        logger.debug("Setting displayname")
        try await client.setMyDisplayName(name)
        logger.debug("Setting avatar image")
        try await client.setMyAvatarImage(avatar)
        logger.debug("Setting state to .circles")
        await MainActor.run {
            self.state = .circles(name)
        }
    }
    
    func setAllDone() async {
        logger.debug("Setting state to .allDone")
        await MainActor.run {
            self.state = .allDone
        }
    }
    
}
