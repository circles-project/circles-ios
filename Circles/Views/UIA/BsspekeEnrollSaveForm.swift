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
    var session: UIAuthSession<Matrix.Credentials>
    
    var body: some View {
        VStack {
            Spacer()
            ProgressView {
                Text("Completing password registration")
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
