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

    @State var recentCircles: [SocialCircle]
    @State var recentGroups: [SocialGroup]

    init(store: KSStore) {
        self.store = store
        self.recentCircles = store.getCircles().filter {
            $0.stream.latestMessage != nil
        }
        self.recentGroups = store.getGroups().groups.filter {
            $0.room.last != nil
        }
    }

    var body: some View {
        // Having multiple ScrollViews one inside the other makes things wonky
        // We're making the HomeScreen the only one with the ScrollView now
        //ScrollView {
            VStack(alignment: .leading) {

                if recentCircles.isEmpty && recentGroups.isEmpty {
                    HStack {
                        Spacer()
                        VStack {
                            Text("No recent activity to display")
                                .padding()
                            Button(action: {
                                recentCircles = store.getCircles().filter {
                                    $0.stream.latestMessage != nil
                                }
                                recentGroups = store.getGroups().groups.filter {
                                    $0.room.last != nil
                                }
                            }) {
                                Label("Refresh", systemImage: "arrow.clockwise.circle")
                            }
                            .padding()
                        }
                        Spacer()
                    }
                }

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
            //}
        }
        //.navigationBarTitle(Text("Recent Activity"))
        //.padding()
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
