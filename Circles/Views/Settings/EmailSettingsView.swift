//
//  EmailSettingsView.swift
//  Circles
//
//  Created by Charles Wright on 6/17/24.
//

import SwiftUI
import Matrix

struct EmailSettingsView: View {
    var session: Matrix.Session
    @State var emails: [String]?
    
    @ViewBuilder
    var enrollEmailButton: some View {
        AsyncButton(action: {
            try await session.updateAuth(filter: { $0.stages.contains(AUTH_TYPE_ENROLL_EMAIL_SUBMIT_TOKEN)})
        }) {
            //Text("Change Password")
            Label("Enroll new email address", systemImage: "envelope")
        }
        .buttonStyle(.plain)
    }
    
    func getThreepids() async {
        do {
            let threepids = try await session.getThreepids()
            print("Got \(threepids.count) 3pids")
            let newEmails = threepids.filter { $0.medium == "email" }
                                     .compactMap { $0.address }
            await MainActor.run {
                self.emails = newEmails
            }
        } catch {
            print("Failed to get 3pids")
        }
    }
    
    var body: some View {
        Form {
            Section("Email Addresses") {
                
                if let emails = emails {
                    if !emails.isEmpty {
                        ForEach(emails, id: \.self) { email in
                            Text(email)
                        }
                    } else {
                        Text("No email addresses")
                    }
                } else {
                    ProgressView()
                        .task {
                            await self.getThreepids()
                        }
                }
            }
            
            enrollEmailButton
        }
        .refreshable {
            await self.getThreepids()
        }

    }
}


