//
//  CircleSetupInfo.swift
//  Circles
//
//  Created by Charles Wright on 5/28/24.
//

import Foundation
import UIKit

class CircleSetupInfo: ObservableObject, Identifiable {
    var name: String
    @Published var avatar: UIImage?
    
    var id: String {
        name
    }
    
    init(name: String, avatar: UIImage? = nil) {
        self.name = name
        self.avatar = avatar
    }
    
    @MainActor
    func setAvatar(_ img: UIImage) {
        self.avatar = img
    }
}
