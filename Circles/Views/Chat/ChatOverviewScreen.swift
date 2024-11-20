//
//  MessagesOverviewScreen.swift
//  Circles
//
//  Created by Charles Wright on 7/26/24.
//

import SwiftUI

import Matrix
import MarkdownUI
import CodeScanner

enum ChatOverviewSheetType: String {
    case create
    case scanQR
}
extension ChatOverviewSheetType: Identifiable {
    var id: String { rawValue }
}

struct ChatOverviewScreen: View {
    @ObservedObject var container: ContainerRoom<Matrix.ChatRoom>
    @State var sheetType: ChatOverviewSheetType?
    
    @State var invitations: [Matrix.InvitedRoom] = []
            
    //@State var selectedRoom: Matrix.Room?
    @Binding var selected: RoomId?
    
    @ViewBuilder
    var baseLayer: some View {
       let chatInvitations = container.session.invitations.values.filter { $0.type == nil }
        
        if !container.rooms.isEmpty || !invitations.isEmpty  {
            VStack(alignment: .leading, spacing: 0) {
                ChatInvitationsIndicator(session: container.session, container: container)
                
                // Sort into _reverse_ chronological order
                let rooms = container.rooms.values.sorted(by: { $0.timestamp > $1.timestamp })
                
                List(selection: $selected) {
                    ForEach(rooms) { room in
                        NavigationLink(value: room.roomId) {
                            ChatOverviewRow(room: room)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(selected == room.roomId ? Color.accentColor.opacity(0.20) : Color.greyCool200)
                    }
                }
                .listStyle(.plain)
            }
        }
        else {
            Text("Create a new chat to get started")
                .onAppear {
                    self.reload()
                }
        }
        
        if DebugModel.shared.debugMode {
            Text("\(container.rooms.values.count) known chat rooms")
            let nilRooms = container.session.rooms.values.filter { $0.type == nil }
            Text("\(nilRooms.count) rooms with type == nil")
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
                        Label("New chat", systemImage: "plus.square.fill")
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
    
    @ViewBuilder
    var master: some View {
        ZStack {
            baseLayer
                .scrollContentBackground(.hidden)

            
            overlay
        }
        .padding(.top)
        .navigationBarTitle(Text("Messages"), displayMode: .inline)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Menu {
                    Button(action: {
                        self.sheetType = .create
                    }) {
                        Label("New Chat", systemImage: "plus.circle")
                    }
                }
                label: {
                    Label("More", systemImage: SystemImages.ellipsisCircle.rawValue)
                }
            }
        }
        .sheet(item: $sheetType) { st in
            // Figure out what kind of sheet we need
            switch(st) {
            case .create:
                ChatCreationSheet(chats: container)
            case .scanQR:
                ScanQrCodeAndKnockSheet(session: container.session)
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            master
                .background(Color.greyCool200)
                .refreshable {
                    self.reload()
                }
                .task {
                    // It's possible that we don't have all of the user's (untyped) chat rooms in our space
                    // Look for them and add any that appear to be missing
                    let nilRooms = container.session.rooms.values.filter {
                        $0.type == nil && !container.children.contains($0.roomId)
                    }
                    for room in nilRooms {
                        try? await container.addChild(room.roomId)
                    }
                }
        } detail: {
            if let roomId = selected,
               let room = container.session.rooms[roomId] as? Matrix.ChatRoom
            {
                ChatTimelineScreen(room: room, container: container)
            } else {
                Text("Select a chat to see the most recent posts, or create a new chat")
            }
        }

    }
}

