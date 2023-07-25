//
//  CirclesTabbedInterface.swift
//  Circles
//
//  Created by Charles Wright on 7/24/23.
//

import SwiftUI

struct CirclesTabbedInterface: View {
    @ObservedObject var store: CirclesStore
    @ObservedObject var session: CirclesApplicationSession
    
    /*
    init(store: CirclesStore, session: CirclesApplicationSession) {
        self.store = store
        self.session = session
    }
    */
    
    enum Tab: String {
        case home
        case circles
        case people
        case groups
        case photos
        case settings
    }
    
    @State private var selection: Tab = .home

    @ViewBuilder
    var tabview: some View {
        TabView(selection: $selection) {
            
            CirclesOverviewScreen(container: self.session.circles)
                .tabItem {
                    Image(systemName: "circles.hexagonpath")
                    Text("Circles")
                }
                .tag(Tab.circles)
            
            PeopleOverviewScreen(people: self.session.people,
                                 circles: self.session.circles,
                                 groups: self.session.groups)
                .tabItem {
                    Image(systemName: "rectangle.stack.person.crop")
                    Text("People")
                }
                .tag(Tab.people)
            
            GroupsOverviewScreen(container: self.session.groups)
                .tabItem {
                    Image(systemName: "person.2.square.stack")
                    Text("Groups")
                }
                .tag(Tab.groups)
            
            PhotosOverviewScreen(container: self.session.galleries)
                .tabItem {
                    Image(systemName: "photo.fill.on.rectangle.fill")
                    Text("Photos")
                }
                .tag(Tab.photos)
            
            SettingsScreen(store: store, session: session)
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
                .tag(Tab.settings)
            
            /*
            Text("Chat Screen")
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    //Text("Direct Messages")}
                    Text("Chat")
                }
                .tag(5)
            */
        }

    }

    var body: some View {
        ZStack {
            tabview
            
            UiaOverlayView(circles: session, matrix: session.matrix)
        }
    }
}
