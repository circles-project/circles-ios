//
//  SetupSession.swift
//  Circles
//
//  Created by Charles Wright on 6/14/22.
//

import Foundation
import UIKit

class SetupSession: ObservableObject {
    var creds: MatrixCredentials
    var store: CirclesStore
    var api: MatrixAPI
    
    @Published var stages = ["avatar", "circles"]
    
    init(creds: MatrixCredentials, store: CirclesStore) throws {
        self.creds = creds
        self.store = store
        self.api = try MatrixAPI(creds: creds)
    }
    
    func setAvatar(_ image: UIImage) async throws {
        try await api.setAvatarImage(image)
        await MainActor.run {
            self.stages.removeAll(where: {
                $0 == "avatar"
            })
        }
    }
    
    func setDisplayName(_ name: String) async throws {
        try await api.setDisplayName(name)
    }
}
