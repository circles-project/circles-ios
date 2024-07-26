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
    
    @AppStorage("debugMode") var debugMode: Bool = false
    @AppStorage(DEFAULTS_KEY_ENABLE_GALLERIES, store: .standard) var enableGalleries: Bool = false
    @AppStorage("changelogLastUpdate") var changelogLastUpdate: TimeInterval = 0
    @AppStorage("mediaViewHeight") var mediaViewHeight: Double = 0
    @State var showChangelog = false
    var changelogFile = ChangelogFile()
    
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
            
            CirclesOverviewScreen(container: self.session.timelines,
                                  selected: $session.viewState.selectedTimelineId)
                .environmentObject(session)
                .onAppear {
                    changelogFile.checkLastUpdates(for: .lastUpdates, showChangelog: &showChangelog, changelogLastUpdate: &changelogLastUpdate)
                }
                .sheet(isPresented: $showChangelog) {
                    ChangelogSheet(content: changelogFile.loadMarkdown(named: .lastUpdates), showChangelog: $showChangelog)
                }
                .tabItem {
                    Image(systemName: SystemImages.circlesHexagonpath.rawValue)
                    Text("Circles")
                }
                .tag(Tab.circles)
   
            GroupsOverviewScreen(container: self.session.groups,
                                 selected: $session.viewState.selectedGroupId)
                .environmentObject(session)
                .tabItem {
                    Image(systemName: SystemImages.person2SquareStack.rawValue)
                    Text("Groups")
                }
                .tag(Tab.groups)
            
            ChatOverviewScreen(session: self.session.matrix,
                               selected: $session.viewState.selectedChatId)
            .environmentObject(session)
            .tabItem {
                Image(systemName: SystemImages.bubble.rawValue)
                Text("Messages")
            }
            .tag(Tab.chat)
            
            PeopleOverviewScreen(people: self.session.people,
                                 profile: self.session.profile,
                                 timelines: self.session.timelines,
                                 groups: self.session.groups)
                .environmentObject(session)
                .tabItem {
                    Image(systemName: SystemImages.rectangleStackPersonCrop.rawValue)
                    Text("People")
                }
                .tag(Tab.people)

            if enableGalleries {
                PhotosOverviewScreen(container: self.session.galleries,
                                     selected: $session.viewState.selectedGalleryId)
                    .environmentObject(session)
                    .tabItem {
                        Image(systemName: SystemImages.photoFillOnRectangleFill.rawValue)
                        Text("Photos")
                    }
                    .tag(Tab.photos)
            }
            
            SettingsScreen(store: store, session: session)
                .environmentObject(session)
                .tabItem {
                    Image(systemName: SystemImages.gearshape.rawValue)
                    Text("Settings")
                }
                .tag(Tab.settings)
            
            /*
            Text("Chat Screen")
                .tabItem {
                    Image(systemName: SystemImages.bubbleLeftAndBubbleRightFill.rawValue)
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
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        if mediaViewHeight == 0 {
                            mediaViewHeight = geometry.size.height
                        }
                    }
            }
        )
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
