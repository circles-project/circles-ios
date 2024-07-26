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
    @ObservedObject var session: Matrix.Session
    @State var sheetType: ChatOverviewSheetType?
        
    @State var invitations: [Matrix.InvitedRoom] = []
    
    //@State var selectedRoom: Matrix.Room?
    @Binding var selected: RoomId?
    
    @ViewBuilder
    var baseLayer: some View {
       // let groupInvitations = container.session.invitations.values.filter { $0.type == ROOM_TYPE_GROUP }
        
        let rooms = session.rooms.values
            .filter({ $0.type == nil })
            .sorted(by: {$0.timestamp > $1.timestamp} )
        
        if !rooms.isEmpty || !invitations.isEmpty  {
            VStack(alignment: .leading, spacing: 0) {
                //ChatInvitationsIndicator(session: session)
                
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
    }
    
    @MainActor
    func reload() {
        print("RELOAD\tSession has \(session.invitations.count) invitations total")
        self.invitations = session.invitations.values.filter { $0.type == nil }
        print("RELOAD\tFound \(self.invitations.count) invitations for this screen")
        session.objectWillChange.send()
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
        .refreshable {
            self.reload()
        }
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
                ChatCreationSheet(session: session)
            case .scanQR:
                ScanQrCodeAndKnockSheet(session: session)
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            master
                .background(Color.greyCool200)
        } detail: {
            if let roomId = selected,
               let room = session.rooms[roomId]
            {
                ChatTimelineScreen(room: room)
            } else {
                Text("Select a chat to see the most recent posts, or create a new chat")
            }
        }

    }
}

