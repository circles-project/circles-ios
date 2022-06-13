//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  LoggedinScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/3/20.
//

import SwiftUI
import MatrixSDK

struct LoggedinScreen: View {
    @ObservedObject var store: CirclesStore
    @ObservedObject var legacyStore: LegacyStore
    
    var errorView: some View {
        VStack {
            Text("Something went wrong")
            AsyncButton(action: {
                do {
                    try await self.store.disconnect()
                } catch {
                    
                }
            }) {
                Text("Logout and try again...")
            }
        }
    }
    
    var body: some View {
        switch(legacyStore.sessionState) {

        case MXSessionState.initialised,
             MXSessionState.syncInProgress:
            VStack {
                ProgressView("Syncing latest data from the server")
            }

        case MXSessionState.running,
             MXSessionState.backgroundSyncInProgress:
            TabbedInterface(store: legacyStore)


        case MXSessionState.homeserverNotReachable:
            // FIXME This should be some sort of pop-up that then sends you back to the login screen
            // FIXME Alternatively, if we have a (seemingly) valid access token, we could allow the user to browse the data that we already have locally, in some sort of "offline" mode
            VStack {
                ProgressView("Reconnecting to server \(legacyStore.homeserver?.host ?? "")")
            }
        case MXSessionState.pauseRequested:
            VStack {
                ProgressView("Logging out...")
            }
            
        case MXSessionState.paused, MXSessionState.closed:
            VStack {
                Text("Logout successful")

                AsyncButton(action: {
                    do {
                        try await self.store.disconnect()
                    } catch {
                        
                    }
                }) {
                    Text("Return to login screen")
                        .padding()
                        .frame(width: 300.0, height: 40.0)
                        .foregroundColor(.white)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
            }

        default:
            errorView
        }
    }
    
    enum Tab: String {
        case home
        case circles
        case people
        case groups
        case photos
    }
    
    struct TabbedInterface: View {
        @ObservedObject var store: LegacyStore
        
        @State private var selection: Tab = .home

        
        var body: some View {
            TabView(selection: $selection) {

                /*
                HomeTabMasterView(store: self.store,
                                  user: self.store.me(),
                                  tab: self.$selection
                )
                */
                HomeScreen(store: self.store,
                           user: self.store.me(),
                           tab: self.$selection)
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .tag(Tab.home)
                
                CirclesOverviewScreen(store: self.store)
                    .tabItem {
                        Image(systemName: "circles.hexagonpath")
                        Text("Circles")
                    }
                    .tag(Tab.circles)
                
                PeopleOverviewScreen(container: self.store.getPeopleContainer())
                    .tabItem {
                        Image(systemName: "rectangle.stack.person.crop")
                        Text("People")
                    }
                    .tag(Tab.people)
                
                GroupsOverviewScreen(container: self.store.getGroups())
                    .tabItem {
                        Image(systemName: "person.2.square.stack")
                        Text("Groups")
                    }
                    .tag(Tab.groups)
                
                PhotosOverviewScreen(container: self.store.getPhotoGalleries())
                    .tabItem {
                        Image(systemName: "photo.fill.on.rectangle.fill")
                        Text("Photos")
                    }
                    .tag(Tab.photos)
                
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
            //.accentColor(.green)


        }

    }
    
}


/*
struct LoggedinScreen_Previews: PreviewProvider {
    static var previews: some View {
        LoggedinScreen(store: LegacyStore())
    }
}
*/
