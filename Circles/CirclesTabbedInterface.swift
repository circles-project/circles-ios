//
//  CirclesTabbedInterface.swift
//  Circles
//
//  Created by Charles Wright on 7/24/23.
//

import SwiftUI
import Matrix

struct SyncDebugView: View {
    @ObservedObject var matrix: Matrix.Session
    
    var body: some View {
        HStack {
            Text(matrix.syncToken ?? "no sync token")
            
            Spacer()
            
            Text("\(matrix.syncSuccessCount)")
            
            Spacer()
            
            Text("\(matrix.syncFailureCount)")
        }
        .font(.caption)
        .padding(.horizontal)
    }
}

struct CirclesTabbedInterface: View {
    @ObservedObject var store: CirclesStore
    @ObservedObject var session: CirclesApplicationSession
    
    @AppStorage("debugMode") var debugMode: Bool = false

    
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
    
    @State var selectedGroupId: RoomId?
    @State var selectedCircleId: RoomId?
    @State var selectedGalleryId: RoomId?

    #if DEBUG
    @ViewBuilder
    var debugTabView: some View {
        VStack(spacing: 0) {
            SyncDebugView(matrix: session.matrix)
            
            tabview
        }
    }
    #endif
    
    @ViewBuilder
    var tabview: some View {
        TabView(selection: $selection) {
            
            CirclesOverviewScreen(container: self.session.circles,
                                  selected: $selectedCircleId)
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
            
            GroupsOverviewScreen(container: self.session.groups,
                                 selected: $selectedGroupId)
                .environmentObject(session)
                .tabItem {
                    Image(systemName: "person.2.square.stack")
                    Text("Groups")
                }
                .tag(Tab.groups)
            
            PhotosOverviewScreen(container: self.session.galleries,
                                 selected: $selectedGalleryId)
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
            
            guard let room = self.session.matrix.rooms[roomId]
            else {
                print("DEEPLINK Not in room \(roomId) -- Knocking on it")
                knockRoomId = roomId
                return
            }
            
            let prefix = url.pathComponents[1]
            switch prefix {
            
            case "timeline":
                print("DEEPLINK Setting tab to Circles")
                selection = .circles
                
                // Do we have a Circle space that contains the given room?
                if let matchingSpace = session.circles.rooms.first(where: { space in
                    // Does this Circle space contain the given room?
                    let matchingRoom = space.rooms.first(where: {room in
                        // Is this room the given room?
                        room.roomId == roomId
                    })
                    return matchingRoom != nil
                }) {
                    print("DEEPLINKS CIRCLES Setting selected circle to \(matchingSpace.name ?? matchingSpace.roomId.stringValue)")
                    selectedCircleId = matchingSpace.roomId
                } else {
                    print("DEEPLINKS CIRCLES Room \(roomId) is not one of ours")
                }
            
            case "profile":
                print("DEEPLINK Setting tab to People")
                selection = .people
            
            case "group":
                print("DEEPLINK Setting tab to Groups")
                selection = .groups
                selectedGroupId = roomId
            
            case "gallery":
                print("DEEPLINK Setting tab to Photos")
                selection = .photos
                selectedGalleryId = roomId
            
            case "room":
                
                // Let's see what type of room it is, and use that to set the selected tab.
                switch room.type {
                    
                case ROOM_TYPE_CIRCLE:
                    selection = .circles
                    selectedCircleId = roomId
                    
                case "m.space":
                    selection = .people
                    
                case ROOM_TYPE_GROUP:
                    selection = .groups
                    selectedGroupId = roomId
                    
                case ROOM_TYPE_PHOTOS:
                    selection = .photos
                    selectedGalleryId = roomId
                    
                default:
                    print("DEEPLINK Room type doesn't match any of our tabs - doing nothing")
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
            #if DEBUG
            if debugMode {
                debugTabView
            } else {
                tabview
            }
            #else
            tabview
            #endif

            UiaOverlayView(circles: session, matrix: session.matrix)
        }
    }
}
