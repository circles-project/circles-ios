//
//  SettingsScreen.swift
//  Circles
//
//  Created by Charles Wright on 4/12/23.
//

import Foundation
import SwiftUI

import Matrix

struct SettingsScreen: View {
    @ObservedObject var session: CirclesSession
    
    var body: some View {
        VStack {
            Spacer()
            Text("Settings")
            Spacer()
        }
    }
}
