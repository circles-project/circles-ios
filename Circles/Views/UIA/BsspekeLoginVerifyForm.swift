//
//  BsspekeLoginVerifyForm.swift
//  Circles
//
//  Created by Charles Wright on 4/3/23.
//

import Foundation
import SwiftUI
import Matrix

struct BsspekeLoginVerifyForm: View {
    var session: any UIASession
    
    var body: some View {
        VStack {
            Spacer()
            ProgressView {
                Text("Verifying password")
            }
            Spacer()
        }
        .onAppear {
            Task {
                try await session.doBSSpekeLoginVerifyStage()
            }
        }
    }
}
