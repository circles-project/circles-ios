//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  RecentActivityScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 2/26/21.
//

import SwiftUI

struct RecentActivityView: View {
    //@State var showReplyComposer = false
    var store: KSStore

    @State var recentCircles: [SocialCircle] = []
    @State var recentGroups: [SocialGroup] = []

    @State var pending = true

    func refreshData() {
        store.loadCircles() { response in
            guard case let .success(circles) = response else {
                print("RECENT\tCouldn't get an updated list of circles")
                return
            }
            recentCircles = circles.filter {
                $0.stream.latestMessage != nil
            }
        }

        recentGroups = store.getGroups().groups.filter {
            $0.room.last != nil
        }
    }

    var activityList: some View {
        VStack {
            ForEach(recentCircles) { circle in
                if let message = circle.stream.latestMessage {
                    Text("From Circle: \(circle.name)")
                        //.font(.caption)
                        .fontWeight(.bold)
                        .padding(.top, 2)
                    Button(action: {
                        // Set the tab to be "Circles"
                        // Set the selected circle to be this one
                    }) {
                        MessageCard(message: message, displayStyle: .timeline)
                            .padding(.leading)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            ForEach(recentGroups) { group in
                if let message = group.room.last {
                    Text("From Group: \(group.room.displayName ?? "(unnamed group)")")
                        //.font(.caption)
                        .fontWeight(.bold)
                        .padding(.top, 2)
                    MessageCard(message: message, displayStyle: .timeline)
                        .padding(.leading)
                }
            }
        }
    }

    var refreshView: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()

                if pending {
                    ProgressView()
                } else {
                    VStack {
                        Text("No recent activity to display")
                            .padding()
                        Button(action: {
                            self.refreshData()
                        }) {
                            Label("Refresh", systemImage: "arrow.clockwise.circle")
                        }
                        .padding()
                    }
                }

                Spacer()
            }
            Spacer()
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            if recentCircles.isEmpty && recentGroups.isEmpty {
                refreshView
            } else {
                activityList
            }
        }
        .onAppear {
            if recentCircles.isEmpty || recentGroups.isEmpty {
                // Maybe the UI loaded before the data was ready
                // Wait a couple of seconds and try again
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.refreshData()
                    self.pending = false
                }
            }
        }
    }
}

struct RecentActivityScreen: View {
    var store: KSStore
    var body: some View {
        ScrollView {
            RecentActivityView(store: store)
                //.padding()
        }
        .navigationBarTitle(Text("Recent Activity"))

    }
}

/*
struct RecentActivityScreen_Previews: PreviewProvider {
    static var previews: some View {
        RecentActivityScreen()
    }
}
*/
