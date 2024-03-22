//
//  NotificationsSettingsView.swift
//  Circles
//
//  Created by Charles Wright on 7/6/23.
//

import SwiftUI
import Matrix
import UserNotifications

import UIKit

struct NotificationsSettingsView: View {
    @ObservedObject var store: CirclesStore
    @ObservedObject var matrix: Matrix.Session
        
    @State var notificationsEnabled: Bool?
    @State var notifyOnInvite: Bool = true
    //@AppStorage("notify_on_reaction") var notifyOnReaction: Bool = false
    @State var notifyOnMessage: Bool = true
    
    var logger = CirclesApp.logger
    
    @ViewBuilder
    var configSection: some View {
        Section("Send notifications") {
            Toggle("For invitations", isOn: $notifyOnInvite)
                .onChange(of: notifyOnInvite) { value in
                    logger.debug("Notify on invite = \(value)")
                    let actions: [Matrix.PushRules.Action] = value ? [.notify] : [.dontNotify]
                    Task {
                        try await matrix.setPushRuleActions(kind: .override, ruleId: M_RULE_INVITE_FOR_ME, actions: actions)
                    }
                }
                .onAppear {
                    Task {
                        let actions = try await matrix.getPushRuleActions(kind: .override, ruleId: M_RULE_INVITE_FOR_ME)
                        let enabled = actions.contains(.notify)
                        logger.debug("Invite notifications enabled? \(enabled)")
                        await MainActor.run {
                            self.notifyOnInvite = enabled
                        }
                    }
                }
            
            Toggle("For new posts", isOn: $notifyOnMessage)
                .onChange(of: notifyOnMessage) { value in
                    logger.debug("Notify on message = \(value)")
                    let actions: [Matrix.PushRules.Action] = value ? [.notify] : [.dontNotify]
                    Task {
                        try await matrix.setPushRuleActions(kind: .underride, ruleId: M_RULE_MESSAGE, actions: actions)
                    }
                }
                .onAppear {
                    Task {
                        let actions = try await matrix.getPushRuleActions(kind: .underride, ruleId: M_RULE_MESSAGE)
                        let enabled = actions.contains(.notify)
                        logger.debug("Message notifications enabled? \(enabled)")
                        await MainActor.run {
                            self.notifyOnMessage = enabled
                        }
                    }
                }
        }
    }
    
    @MainActor
    func loadCurrentSettings() {
        logger.debug("Loading current notification settings")
        UNUserNotificationCenter.current().getNotificationSettings() { settings in
            let enabled = settings.authorizationStatus == .authorized
            self.notificationsEnabled = enabled
        }
    }
    
    var body: some View {
        Form {
                        
            if let notificationsAreEnabled = self.notificationsEnabled {
                if notificationsAreEnabled {
                    configSection
                } else {
                    Group {
                        Label("Notifications are disabled", systemImage: "bell.slash.fill")
                        Text("To enable notifications in Circles, open the System Settings app on your device and go to Circles > Notifications")
                        if let url = URL(string: UIApplicationOpenNotificationSettingsURLString),
                           UIApplication.shared.canOpenURL(url)
                        {
                            Button(action: {
                                UIApplication.shared.open(url)
                            }) {
                                Label("Open System Settings app", systemImage: "gearshape.fill")
                            }
                        }
                    }
                    .task {
                        var stop = false
                        
                        while !notificationsAreEnabled && !stop {
                            // NOTE: The do...catch block is critical here
                            //       When the user enables notifications, the Task.sleep() in this loop begins to fail
                            //       When that happens we must catch the error and abort the loop
                            //       Otherwise we run loadCurrentSettings() in an infinite loop at maximum speed forever
                            do {
                                try await Task.sleep(for: .seconds(5))
                                logger.debug("task: loading settings")
                                loadCurrentSettings()
                            } catch {
                                logger.debug("NotificationSettingsView: Failed to sleep and load settings")
                                stop = true
                            }
                        }
                    }
                    
                    Group {
                        Button(action: {
                            loadCurrentSettings()
                        }) {
                            Label("Refresh", systemImage: "arrow.counterclockwise")
                        }
                    }
                }
            } else {
                ProgressView("Loading...")
            }

        }
        .onAppear {
            if self.notificationsEnabled == nil {
                logger.debug("onAppear: Loading settings")
                loadCurrentSettings()
            }
        }
        .navigationTitle(Text("Notifications"))
    }
}

