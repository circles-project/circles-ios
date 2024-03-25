//
//  BsspekeEnrollSaveForm.swift
//  Circles
//
//  Created by Charles Wright on 3/31/23.
//

import Foundation
import SwiftUI
import Matrix

struct BsspekeEnrollSaveForm: View {
    var session: any UIASession
    
    var body: some View {
        VStack {
            Spacer()
            ProgressView {
                Text("Completing passphrase enrollment")
            }
            Spacer()
        }
        .onAppear {
            Task {
                try await session.doBSSpekeEnrollSaveStage()
            }
        }
    }
}
