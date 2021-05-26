//
//  RecentActivityScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 2/26/21.
//

import SwiftUI

struct RecentActivityView: View {
    var store: KSStore
    var body: some View {
        // Having multiple ScrollViews one inside the other makes things wonky
        // We're making the HomeScreen the only one with the ScrollView now
        //ScrollView {
            VStack(alignment: .leading) {
                ForEach(store.getCircles()) { circle in
                    if let message = circle.stream.latestMessage {
                        Text("From Circle: \(circle.name)")
                            .font(.caption)
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
                ForEach(store.getGroups().groups) { group in
                    if let message = group.room.last {
                        Text("From Group: \(group.room.displayName ?? "(unnamed group)")")
                            .font(.caption)
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
                .navigationBarTitle(Text("Recent Activity"))
                //.padding()
        }
    }
}

/*
struct RecentActivityScreen_Previews: PreviewProvider {
    static var previews: some View {
        RecentActivityScreen()
    }
}
*/
