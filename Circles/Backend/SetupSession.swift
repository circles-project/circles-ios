//
//  SetupSession.swift
//  Circles
//
//  Created by Charles Wright on 6/14/22.
//

import Foundation
import UIKit

import Matrix

class SetupSession: ObservableObject {
    var creds: Matrix.Credentials
    var store: CirclesStore
    var client: Matrix.Client
    
    enum State {
        case profile
        case circles(String)
        case allDone
    }
    @Published var state: State
    
    init(creds: Matrix.Credentials, s4keyInfo: (String, Data), store: CirclesStore) async throws {
        self.creds = creds
        self.store = store
        //self.client = try Matrix.Client(creds: creds)
        self.client = try await Matrix.Session(creds: creds, startSyncing: false, secretStorageKeyInfo: s4keyInfo)
        self.state = .profile
    }
    
    func setupProfile(name: String, avatar: UIImage) async throws {
        try await client.setMyDisplayName(name)
        try await client.setMyAvatarImage(avatar)
        await MainActor.run {
            self.state = .circles(name)
        }
    }
    
    func setAllDone() async {
        await MainActor.run {
            self.state = .allDone
        }
    }
    
}
