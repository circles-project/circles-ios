//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  GroupsOverviewScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/3/20.
//

import SwiftUI
import Matrix
import MarkdownUI
import CodeScanner

enum GroupsSheetType: String {
    case create
    case scanQR
}
extension GroupsSheetType: Identifiable {
    var id: String { rawValue }
}

struct GroupsOverviewScreen: View {
    @ObservedObject var container: ContainerRoom<GroupRoom>
    @State var sheetType: GroupsSheetType?
    @AppStorage("showGroupsHelpText") var showHelpText = true
    
    @State var showConfirmLeave = false
    @State var roomToLeave: GroupRoom?
    
    @State var invitations: [Matrix.InvitedRoom] = []
    
    //@State var selectedRoom: Matrix.Room?
    @Binding var selected: RoomId?
    
    let helpTextMarkdown = """
        # Groups
        
        Tip: A **group** is the best way to connect a bunch of people where everyone is connected to everyone else.
        
        Everyone in the group posts to the same timeline, and everyone in the group can see every post.
        
        For example, you might want to create a group for your book club, or your sports team, or your scout troop.
        
        If you want to share with lots of different people who don't all know each other, then you should invite those people to follow you in a **Circle** instead.
        """
    
    @ViewBuilder
    var baseLayer: some View {
       // let groupInvitations = container.session.invitations.values.filter { $0.type == ROOM_TYPE_GROUP }
        
        if !container.rooms.isEmpty || !invitations.isEmpty  {
            VStack(alignment: .leading, spacing: 0) {
                GroupInvitationsIndicator(session: container.session, container: container)
                
                // Sort into _reverse_ chronological order
                let rooms = container.rooms.sorted(by: { $0.timestamp > $1.timestamp })
                
                List(selection: $selected) {
                    ForEach(rooms) { room in
                        NavigationLink(value: room.roomId) {
                            GroupOverviewRow(container: container, room: room)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive, action: {
                                self.showConfirmLeave = true
                                self.roomToLeave = room
                            }) {
                                Label("Leave group", systemImage: "xmark.bin")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .accentColor(.secondaryBackground)
            }
        }
        else {
            Text("Create a group to get started")
                .onAppear {
                    self.reload()
                }
        }
    }
    
    @MainActor
    func reload() {
        print("RELOAD\tSession has \(container.session.invitations.count) invitations total")
        self.invitations = container.session.invitations.values.filter { $0.type == ROOM_TYPE_GROUP }
        print("RELOAD\tFound \(self.invitations.count) invitations for this screen")
        container.objectWillChange.send()
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
                        Label("Create group", systemImage: "plus.square.fill")
                    }
                    
                    Button(action: {
                        self.sheetType = .scanQR
                    }) {
                        Label("Scan QR code", systemImage: "qrcode")
                    }
                }
                label: {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .padding()
                }
            }
        }
    }
    
    @ViewBuilder
    var master: some View {
        ZStack {
            baseLayer
            
            overlay
        }
        .padding(.top)
        .navigationBarTitle(Text("Groups"), displayMode: .inline)
        .refreshable {
            self.reload()
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Menu {
                    Button(action: {
                        self.sheetType = .create
                    }) {
                        Label("New Group", systemImage: "plus.circle")
                    }
                    Button(action: {
                        self.sheetType = .scanQR
                    }) {
                        Label("Scan QR code", systemImage: "qrcode")
                    }
                    Button(action: {
                        self.showHelpText = true
                    }) {
                        Label("Help", systemImage: "questionmark.circle")
                    }
                }
                label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog(Text("Confirm Leaving Group"),
                            isPresented: $showConfirmLeave,
                            actions: { //rm in
                                if let room = self.roomToLeave {
                                    AsyncButton(role: .destructive, action: {
                                        try await container.leaveChild(room.roomId)
                                    }) {
                                        Text("Leave \(room.name ?? "this group")")
                                    }
                                }
                            })
        .sheet(item: $sheetType) { st in
            // Figure out what kind of sheet we need
            switch(st) {
            case .create:
                GroupCreationSheet(groups: container)
            case .scanQR:
                ScanQrCodeAndKnockSheet(session: container.session)
            }
        }
        .sheet(isPresented: $showHelpText) {
            VStack {
                Image("iStock-1176559812")
                    .resizable()
                    .scaledToFit()
                
                Markdown(helpTextMarkdown)
                
                Button(action: {self.showHelpText = false}) {
                    Label("Got it", systemImage: "hand.thumbsup.fill")
                        .padding()
                }
                .buttonStyle(.bordered)
                .padding()
            }
            .padding()
        }
    }
    
    var body: some View {
        NavigationSplitView {
            master
        } detail: {
            if let roomId = selected,
               let room = container.rooms.first(where: { $0.roomId == roomId })
            {
                GroupTimelineScreen(room: room)
            } else {
                Text("Select a group to see the most recent posts, or create a new group")
            }
        }

    }
}

/*
struct ChannelsScreen_Previews: PreviewProvider {
    static var previews: some View {
        ChannelsScreen()
    }
}
*/
