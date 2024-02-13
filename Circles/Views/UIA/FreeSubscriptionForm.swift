//
//  FreeSubscriptionForm.swift
//  Circles
//
//  Created by Charles Wright on 1/3/24.
//

import SwiftUI
import Matrix

struct FreeSubscriptionForm: View {
    var session: any UIASession

    var body: some View {
        VStack {
            Spacer()

            if let signup = session as? SignupSession {
                ProgressView("Registering free subscription with the server...")
                    .task {
                        try? await signup.doFreeSubscriptionStage()
                    }
            } else {
                Label("Error: Free subscriptions are only available at registration time", systemImage: "exclamationmark.triangle")
            }
            
            Spacer()
        }
    }
}

