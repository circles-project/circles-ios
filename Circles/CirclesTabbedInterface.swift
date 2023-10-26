//
//  CirclesTabbedInterface.swift
//  Circles
//
//  Created by Charles Wright on 7/24/23.
//

import SwiftUI
import Matrix

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
    @State var knockRoomId: RoomId?

    @ViewBuilder
    var tabview: some View {
        TabView(selection: $selection) {
            
            CirclesOverviewScreen(container: self.session.circles)
                .environmentObject(session)
                .tabItem {
                    Image(systemName: "circles.hexagonpath")
                    Text("Circles")
                }
                .tag(Tab.circles)
            
            PeopleOverviewScreen(people: self.session.people,
                                 profile: self.session.profile,
                                 circles: self.session.circles,
                                 groups: self.session.groups)
                .environmentObject(session)
                .tabItem {
                    Image(systemName: "rectangle.stack.person.crop")
                    Text("People")
                }
                .tag(Tab.people)
            
            GroupsOverviewScreen(container: self.session.groups)
                .environmentObject(session)
                .tabItem {
                    Image(systemName: "person.2.square.stack")
                    Text("Groups")
                }
                .tag(Tab.groups)
            
            PhotosOverviewScreen(container: self.session.galleries)
                .environmentObject(session)
                .tabItem {
                    Image(systemName: "photo.fill.on.rectangle.fill")
                    Text("Photos")
                }
                .tag(Tab.photos)
            
            SettingsScreen(store: store, session: session)
                .environmentObject(session)
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
        .onOpenURL{ url in
            guard let host = url.host()
            else {
                print("DEEPLINK Not processing URL \(url) -- No host")
                return
            }
            let components = url.pathComponents
            
            print("DEEPLINK URL: Host = \(host)")
            print("DEEPLINK URL: Path = \(components)")
            
            guard url.pathComponents.count >= 3,
                  url.pathComponents[0] == "/",
                  let roomId = RoomId(url.pathComponents[2])
            else {
                print("DEEPLINK Not processing URL \(url) -- No first path component")
                return
            }
            
            let prefix = url.pathComponents[1]
            switch prefix {
            
            case "timeline":
                print("DEEPLINK Setting tab to Circles")
                selection = .circles
            
            case "profile":
                print("DEEPLINK Setting tab to People")
                selection = .people
            
            case "group":
                print("DEEPLINK Setting tab to Groups")
                selection = .groups
            
            case "gallery":
                print("DEEPLINK Setting tab to Photos")
                selection = .photos
            
            case "room":
                
                // Are we already in this room?
                if let room = self.session.matrix.rooms[roomId] {
                    // We're in the room.  Let's see what type of room it is, and use that to set the selected tab.
                    switch room.type {
                    case ROOM_TYPE_CIRCLE:
                        selection = .circles
                    case "m.space":
                        selection = .people
                    case ROOM_TYPE_GROUP:
                        selection = .groups
                    case ROOM_TYPE_PHOTOS:
                        selection = .photos
                    default:
                        print("DEEPLINK Room type doesn't match any of our tabs - doing nothing")
                    }
                } else {
                    // We're not in the room, but we can knock on it to request access
                    self.knockRoomId = roomId
                }

            default:
                print("DEEPLINK Unknown URL prefix [\(prefix)]")
            }
            
        }
        .sheet(item: $knockRoomId) { roomId in
            ScanQrCodeAndKnockSheet(session: self.session.matrix, roomId: roomId)
        }

    }

    var body: some View {
        ZStack {
            tabview
            
            UiaOverlayView(circles: session, matrix: session.matrix)
        }
    }
}
