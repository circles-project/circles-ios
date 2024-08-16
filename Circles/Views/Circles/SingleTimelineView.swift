//
//  SingleTimelineView.swift
//  Circles
//
//  Created by Charles Wright on 4/12/24.
//

import SwiftUI
import Matrix

enum SingleTimelineSheetType: String {
    case invite
    case share
}
extension SingleTimelineSheetType: Identifiable {
    var id: String { rawValue }
}

struct SingleTimelineView: View {
    @ObservedObject var room: Matrix.Room
    
    @State var viewModel = TimelineViewModel()

    @State private var sheetType: SingleTimelineSheetType? = nil
    @State var showNewPostInSheetStyle = false

    @ViewBuilder
    var toolbarMenu: some View {
        Menu {
            NavigationLink(destination: SingleTimelineSettingsView(room: room)) {
                Label("Settings", systemImage: SystemImages.gearshapeFill.rawValue)
            }
            
            if room.iCanInvite {
                Button(action: {
                    self.sheetType = .invite
                }) {
                    Label("Invite new members", systemImage: SystemImages.personCropCircleBadgePlus.rawValue)
                }
            }
            
            Button(action: {
                self.sheetType = .share
            }) {
                Label("Share", systemImage: SystemImages.squareAndArrowUp.rawValue)
            }
        }
        label: {
            Label("Settings", systemImage: SystemImages.gearshapeFill.rawValue)
        }
    }
    
    @ViewBuilder
    var timeline: some View {
        TimelineView<MessageCard>(room: room)
    }
    
    var body: some View {
        let user = room.session.getUser(userId: room.creator)
        let title = "\(user.displayName ?? user.userId.stringValue) - \(room.name ?? "Timeline")"
        
        NavigationStack {
            ZStack {
                VStack(alignment: .center) {
                    if !room.knockingMembers.isEmpty {
                        RoomKnockIndicator(room: room)
                    }
                    
                    timeline
                        .sheet(item: $sheetType) { st in
                            switch(st) {
                            case .invite:
                                RoomInviteSheet(room: room, title: "Invite new members to \(room.name ?? "(unnamed group)")")
                                
                            case .share:
                                let url = URL(string: "https://\(CIRCLES_PRIMARY_DOMAIN)/group/\(room.roomId.stringValue)")
                                RoomShareSheet(room: room, url: url)
                            }
                        }
                        .padding([.top], -4)
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        if room.creator == room.session.creds.userId,
                            room.iCanSendEvent(type: M_ROOM_MESSAGE)
                        {
                            Button(action: {
                                showNewPostInSheetStyle = true
                            }) {
                                Label("New post", systemImage: SystemImages.plusCircleFill.rawValue)
                            }
                            .buttonStyle(PillButtonStyle())
                            .padding(10)
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                toolbarMenu
            }
        }
        .navigationBarTitle(title, displayMode: .inline)
        .sheet(isPresented: $showNewPostInSheetStyle) {
            PostComposer(room: room).navigationTitle("New Post")
        }
        .background(Color.greyCool200)
        .environmentObject(viewModel)
    }
}


