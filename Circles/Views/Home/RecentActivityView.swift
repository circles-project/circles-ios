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
    var session: CirclesSession

    var activityList: some View {
        VStack {
            ForEach(session.circles.rooms) { space in
                if let message = space.latestMessage {
                    Text("From Circle: \(space.name ?? "(unnamed circle)")")
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
            ForEach(session.groups.rooms) { room in
                if let message = room.latestMessage {
                    Text("From Group: \(room.name ?? "(unnamed group)")")
                        //.font(.caption)
                        .fontWeight(.bold)
                        .padding(.top, 2)
                    MessageCard(message: message, displayStyle: .timeline)
                        .padding(.leading)
                }
            }
        }
    }

    var body: some View {
        activityList
    }
}

struct RecentActivityScreen: View {
    var session: CirclesSession
    var body: some View {
        ScrollView {
            RecentActivityView(session: session)
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
