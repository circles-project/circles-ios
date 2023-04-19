//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  ContentView.swift
//  Circles for iOS
//
//  Created by Charles Wright on 10/16/20.
//

import SwiftUI
import Matrix

struct ContentView: View {
    @ObservedObject var store: CirclesStore
    
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

        switch(store.state) {
            
        case .nothing:
            WelcomeScreen(store: store)
            
        case .haveCreds(let creds):
            VStack {
                Text("Connecting as \(creds.userId.description)")
                ProgressView()
                    .onAppear {
                        _ = Task {
                            try await store.connect(creds: creds)
                        }
                    }
            }
            
        case .signingUp(let signupSession):
            SignupScreen(session: signupSession, store: store)
        
        case .settingUp(let setupSession):
            SetupScreen(session: setupSession, store: store)
            
        case .loggingIn(let loginSession):
            LoginScreen(session: loginSession, store: store)

        case .online(let circlesSession):
            TabbedInterface(session: circlesSession)
                .environmentObject(circlesSession.galleries)
                //.environmentObject(circlesSession)
            
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
        case settings
    }
    
    struct TabbedInterface: View {
        @ObservedObject var session: CirclesSession
        
        @State private var selection: Tab = .home

        
        var body: some View {
            TabView(selection: $selection) {
                
                CirclesOverviewScreen(container: self.session.circles)
                    .tabItem {
                        Image(systemName: "circles.hexagonpath")
                        Text("Circles")
                    }
                    .tag(Tab.circles)
                
                PeopleOverviewScreen(container: self.session.people)
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
                
                SettingsScreen(session: session)
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
            //.accentColor(.green)


        }

    }
    
}

/*
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: CirclesStore())
    }
}
*/
