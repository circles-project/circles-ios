//
//  CirclesTabbedInterface.swift
//  Circles
//
//  Created by Charles Wright on 7/24/23.
//

import SwiftUI
import Matrix

#if DEBUG
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
#endif

struct CirclesTabbedInterface: View {
    @ObservedObject var store: CirclesStore
    @ObservedObject var session: CirclesApplicationSession
    @ObservedObject var viewState: CirclesApplicationSession.ViewState
    
    typealias Tab = CirclesApplicationSession.ViewState.Tab

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
        TabView(selection: $session.viewState.tab) {
            
            CirclesOverviewScreen(container: self.session.circles,
                                  selected: $session.viewState.selectedCircleId)
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
                                 selected: $session.viewState.selectedGroupId)
                .environmentObject(session)
                .tabItem {
                    Image(systemName: "person.2.square.stack")
                    Text("Groups")
                }
                .tag(Tab.groups)
            
            PhotosOverviewScreen(container: self.session.galleries,
                                 selected: $session.viewState.selectedGalleryId)
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
            session.onOpenURL(url: url)
        }
        .sheet(item: $session.viewState.knockRoomId) { roomId in
            ScanQrCodeAndKnockSheet(session: self.session.matrix, roomId: roomId)
        }

    }

    var body: some View {
        ZStack {
            #if DEBUG
            if DebugModel.shared.debugMode {
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
