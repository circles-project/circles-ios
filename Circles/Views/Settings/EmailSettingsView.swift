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
            await CirclesApp.logger.debug("Updating email addresses")
            do {
                try await session.updateAuth(filter: { $0.stages.contains(AUTH_TYPE_ENROLL_EMAIL_SUBMIT_TOKEN) } ) { _,_ in
                    await CirclesApp.logger.debug("Successfully updated email addresses")
                    await MainActor.run {
                        self.emails = nil
                    }
                }
                print("Back from updateAuth")
            } catch {
                await CirclesApp.logger.error("Failed to update email authentication")
                return
            }

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
            Section("Verified Email Addresses") {
                
                if let emails = emails {
                    if !emails.isEmpty {
                        List(emails, id: \.self) { email in
                            Text(email)
                                .swipeActions {
                                    AsyncButton(action: {
                                        // Call the API endpoint to remove this address
                                        CirclesApp.logger.debug("Deleting email address \(email)")
                                        try await session.deleteThreepid(medium: "email", address: email) { _,_ in
                                            CirclesApp.logger.debug("Successfully deleted email address \(email)")
                                            // Reset our list of addresses back to nil to force a reload
                                            await MainActor.run {
                                                self.emails = nil
                                            }
                                        }
                                    }) {
                                        Text("Delete")
                                    }
                                    .tint(.red)
                                }
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
        .navigationTitle("Email Settings")
    }
}


