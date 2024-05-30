//
//  CircleSetupInfo.swift
//  Circles
//
//  Created by Charles Wright on 5/28/24.
//

import Foundation

class CircleSetupInfo: ObservableObject, Identifiable {
    var name: String
    var avatar: UIImage?
    
    var id: String {
        name
    }
    
    init(name: String, avatar: UIImage? = nil) {
        self.name = name
        self.avatar = avatar
    }
}
