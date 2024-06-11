//
//  DebugMode.swift
//  Circles
//
//  Created by Dmytro Ryshchuk on 6/2/24.
//

import Foundation
import SwiftUI

class DebugModel {
    static let shared = DebugModel()
    
    @AppStorage("debugMode") var debugMode: Bool = false
    
    private init(debugMode: Bool = false) {
        self.debugMode = debugMode
    }
}
