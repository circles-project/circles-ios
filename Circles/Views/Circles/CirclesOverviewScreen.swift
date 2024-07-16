//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  CirclesOverviewScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/5/20.
//

import SwiftUI
import MarkdownUI
import Matrix

enum CirclesOverviewSheetType: String {
    case create
    case scanQr
}
extension CirclesOverviewSheetType: Identifiable {
    var id: String { rawValue }
}

struct CirclesOverviewScreen: View {
    @ObservedObject var container: TimelineSpace
    //@State var selectedSpace: CircleSpace?
    @Binding var selected: RoomId?
    
    //@State private var columnVisibility = NavigationSplitViewVisibility.detailOnly // Apparently iPhone ignores this and just shows the master view by default. iPad respects it and thus looks ugly, because we set the timeline column width to fit next to the sidebar.  Ugh what a waste.
    // @State private var preferredColumn = NavigationSplitViewColumn.detail       // We can upgrade to this once we drop support for iOS 16
        
    @State private var sheetType: CirclesOverviewSheetType? = nil
    
    @State var confirmDeleteCircle = false
    @State var timelineToDelete: Matrix.Room? = nil
    
    @AppStorage("showCirclesHelpText") var showHelpText = false
    
    var toolbarMenu: some View {
        Menu {
            Button(action: {self.sheetType = .create}) {
                Label("New Circle", systemImage: "plus")
            }
            Button(action: {self.sheetType = .scanQr}) {
                Label("Scan QR code", systemImage: "qrcode")
            }
            Button(action: {self.showHelpText = true }) {
                Label("Help", systemImage: SystemImages.questionmarkCircle.rawValue)
            }
        }
        label: {
            Label("More", systemImage: SystemImages.ellipsisCircle.rawValue)
        }
    }
    
    private func removeTimeline(room: Matrix.Room) async throws {
        print("Removing timeline \(room.name ?? "??") (\(room.roomId))")

        if room.creator == room.session.creds.userId {
            print("Deleting timeline \(room.roomId)")
            let roomId = room.roomId
            try await room.close(reason: "Deleting this circle", kickEveryone: false)
            try await container.removeChild(roomId)
        } else {
            print("Leaving timeline \(room.roomId)")
            try await container.leaveChild(room.roomId)
        }
    }
    
    private func roomSortComparator(_ room0: Matrix.Room, _ room1: Matrix.Room) -> Bool {
        let session = container.session
        let user0 = session.getUser(userId: room0.creator)
        let user1 = session.getUser(userId: room1.creator)
        
        let title0 = "\(user0.displayName ?? user0.userId.username) \(room0.name ?? "")"
        let title1 = "\(user1.displayName ?? user1.userId.username) \(room1.name ?? "")"
        
        return title0 < title1
    }
    
    @ViewBuilder
    var baseLayer: some View {
        let invitations = container.session.invitations.values.filter { $0.type == ROOM_TYPE_CIRCLE }

        if !container.rooms.isEmpty || !invitations.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                            
                if invitations.count > 0 {
                    CircleInvitationsIndicator(session: container.session, container: container)
                }
                
                let session = container.session
                // Sort intro _reverse_ chronological order
                let circles = container.circles.sorted(by: {
                    roomSortComparator($0, $1)
                })
                let following = container.following.sorted(by: {
                    roomSortComparator($0, $1)
                })
                                
                List(selection: $selected) {
                    
                    NavigationLink(value: container.roomId) {
                        HStack {
                            CirclesLogoView()
                                .clipShape(Circle())
                                .frame(width: 60, height: 60)

                            Text("All Posts")
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .minimumScaleFactor(0.8)
                        }
                    }
                    .buttonStyle(.plain)

                    Section("My Circles") {
                        ForEach(circles) { circle in
                            NavigationLink(value: circle.roomId) {
                               
                                TimelineOverviewCard(room: circle, user: session.me)
                                    .contentShape(Rectangle())
                                    //.padding(.top)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive, action: {
                                    //try await deleteCircle(circle: circle)
                                    self.timelineToDelete = circle
                                    self.confirmDeleteCircle = true
                                }) {
                                    Label("Delete", systemImage: SystemImages.xmarkCircle.rawValue)
                                }
                            }
                        }
                    }
                    
                    if following.count > 0 {
                        Section("Others I'm Following") {
                            ForEach(following) { room in
                                NavigationLink(value: room.roomId) {
                                    let user = session.getUser(userId: room.creator)
                                    TimelineOverviewCard(room: room, user: user)
                                        .contentShape(Rectangle())
                                    //.padding(.top)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive, action: {
                                        //try await deleteCircle(circle: circle)
                                        self.timelineToDelete = room
                                        self.confirmDeleteCircle = true
                                    }) {
                                        Label("Delete", systemImage: SystemImages.xmarkCircle.rawValue)
                                    }
                                }
                                
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .accentColor(.secondaryBackground)
            }
        }
        else {
            Text("Create a circle to get started")
        }
    }
    
    @ViewBuilder
    var overlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                Menu {
                    Button(action: {
                        self.sheetType = .create
                    }) {
                        Label("Create new circle", systemImage: "plus.circle")
                    }
                    
                    Button(action: {
                        self.sheetType = .scanQr
                    }) {
                        Label("Scan QR code", systemImage: "qrcode")
                    }
                }
                label: {
                    Image(systemName: SystemImages.plusCircleFill.rawValue)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .padding()
                }
            }
        }
    }
    

    
    var master: some View {
        ZStack {
            baseLayer
            
            overlay
        }
        .padding(.top)
        .navigationBarTitle("Circles", displayMode: .inline)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                toolbarMenu
            }
        }
        .sheet(item: $sheetType) { st in
            switch(st) {
            case .create:
                CircleCreationSheet(container: container)
            case .scanQr:
                ScanQrCodeAndKnockSheet(session: container.session)
            }
        }
        .confirmationDialog("Confirm deleting circle", isPresented: $confirmDeleteCircle, presenting: timelineToDelete) { circle in
            AsyncButton(role: .destructive, action: {
                try await removeTimeline(room: circle)
            }) {
                Label("Delete circle \"\(circle.name ?? "??")\"", systemImage: SystemImages.xmarkBin.rawValue)
            }
        }
        .sheet(isPresented: $showHelpText) {
            VStack {
                CirclesHelpView()

                Button(action: {self.showHelpText = false}) {
                    Label("Got it", systemImage: "hand.thumbsup.fill")
                        .padding()
                }
                .buttonStyle(BigRoundedButtonStyle())
                Spacer()
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            master
                .refreshable {
                    await MainActor.run {
                        container.objectWillChange.send()
                    }
                }
        } detail: {
            if let roomId = selected,
               let timeline = container.rooms[roomId]
            {
               SingleTimelineView(room: timeline)
            } else {
                UnifiedTimelineView(space: container)
            }
        }
    }
}

/*
struct CirclesOverviewScreen_Previews: PreviewProvider {
    static var previews: some View {
        CirclesOverviewScreen(store: LegacyStore())
    }
}
*/
