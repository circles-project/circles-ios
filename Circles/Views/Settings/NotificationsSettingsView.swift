//
//  NotificationsSettingsView.swift
//  Circles
//
//  Created by Charles Wright on 7/6/23.
//

import SwiftUI
import Matrix
import UserNotifications

struct NotificationsSettingsView: View {
    @ObservedObject var store: CirclesStore
    @ObservedObject var matrix: Matrix.Session
    
    @EnvironmentObject var delegate: CirclesAppDelegate
    
    @State var notificationsEnabled: Bool?
    @State var notifyOnInvite: Bool = true
    //@AppStorage("notify_on_reaction") var notifyOnReaction: Bool = false
    @State var notifyOnMessage: Bool = true
    
    @ViewBuilder
    var configSection: some View {
        Section("Send notifications") {
            Toggle("For invitations", isOn: $notifyOnInvite)
                .onChange(of: notifyOnInvite) { value in
                    print("Notify on invite = \(value)")
                    let actions: [Matrix.PushRules.Action] = value ? [.notify] : [.dontNotify]
                    Task {
                        try await matrix.setPushRuleActions(kind: .override, ruleId: M_RULE_INVITE_FOR_ME, actions: actions)
                    }
                }
                .onAppear {
                    Task {
                        let actions = try await matrix.getPushRuleActions(kind: .override, ruleId: M_RULE_INVITE_FOR_ME)
                        let enabled = actions.contains(.notify)
                        print("Invite notifications enabled? \(enabled)")
                        await MainActor.run {
                            self.notifyOnInvite = enabled
                        }
                    }
                }
            
            Toggle("For new posts", isOn: $notifyOnMessage)
                .onChange(of: notifyOnMessage) { value in
                    print("Notify on message = \(value)")
                    let actions: [Matrix.PushRules.Action] = value ? [.notify] : [.dontNotify]
                    Task {
                        try await matrix.setPushRuleActions(kind: .underride, ruleId: M_RULE_MESSAGE, actions: actions)
                    }
                }
                .onAppear {
                    Task {
                        let actions = try await matrix.getPushRuleActions(kind: .underride, ruleId: M_RULE_MESSAGE)
                        let enabled = actions.contains(.notify)
                        print("Message notifications enabled? \(enabled)")
                        await MainActor.run {
                            self.notifyOnMessage = enabled
                        }
                    }
                }
        }
    }
    
    var body: some View {
        Form {
                        
            if let notificationsAreEnabled = self.notificationsEnabled {
                if notificationsAreEnabled {
                    configSection
                } else {
                    Label("Notifications are disabled", systemImage: "bell.slash.fill")
                    Text("To enable notifications in Circles, open the Settings app on your device and go to Circles > Notifications")
                }
            } else {
                ProgressView("Loading...")

            }

        }
        .onAppear {
            UNUserNotificationCenter.current().getNotificationSettings() { settings in
                let enabled = settings.authorizationStatus == .authorized
                self.notificationsEnabled = enabled
            }
        }
        .navigationTitle(Text("Notifications"))
    }
}

