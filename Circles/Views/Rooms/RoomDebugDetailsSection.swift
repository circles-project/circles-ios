//
//  RoomDebugDetailsSection.swift
//  Circles
//
//  Created by Charles Wright on 2/6/24.
//

import SwiftUI
import Matrix

struct RoomDebugDetailsSection: View {
    @ObservedObject var room: Matrix.Room
    
    var body: some View {
        if DebugModel.shared.debugMode {
            Section("Matrix Debug Details") {
                Text("History visibiilty")
                    .badge(room.historyVisibility?.rawValue ?? "unknown")
                Text("Join rule")
                    .badge(room.joinRule?.rawValue ?? "unknown")
                Text("Encryption algorithm")
                    .badge(room.encryptionParams?.algorithm.rawValue ?? "none")
                if let ms = room.encryptionParams?.rotationPeriodMs {
                    let sec = ms / 1000
                    Text("Rotation (sec)")
                        .badge("\(sec)")
                }
                if let msgs = room.encryptionParams?.rotationPeriodMsgs {
                    Text("Rotation (msgs)")
                        .badge("\(msgs)")
                }
            }
        }
    }
}

