//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//  Copyright 2022 FUTO Holdings, Inc
//
//  GroupTimelineScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/3/20.
//

import SwiftUI
import Matrix

enum GroupScreenSheetType: String {
    case invite
    case share
}
extension GroupScreenSheetType: Identifiable {
    var id: String { rawValue }
}

struct GroupTimelineScreen: View {
    @ObservedObject var room: GroupRoom
    var container: ContainerRoom<GroupRoom>
    //@ObservedObject var group: SocialGroup
    @Environment(\.presentationMode) var presentation
    
    @State private var sheetType: GroupScreenSheetType? = nil

    @State private var newImageForHeader = UIImage()
    @State private var newImageForProfile = UIImage()
    @State private var newImageForMessage = UIImage()
    
    @State private var confirmNewProfileImage = false
    @State private var confirmNewHeaderImage = false
    
    @State private var newTopic = ""
    @State private var showTopicPopover = false

    @State var nilParentMessage: Matrix.Message? = nil
    @State var showNewPostInSheetStyle = false
    
    @State var viewModel = TimelineViewModel()
    
    var timeline: some View {
        TimelineView<MessageCard>(room: room)
    }
    
    var toolbarMenu: some View {
        Menu {
            NavigationLink(destination: GroupSettingsView(room: room, container: container)) {
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
    
    var title: Text {
        Text(room.name ?? "(Unnamed Group)")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(alignment: .center) {
                    /*
                     VStack(alignment: .leading) {
                     Text("Debug Info")
                     Text("roomId: \(group.room.id)")
                     Text("type: \(group.room.type ?? "(none)")")
                     }
                     .font(.footnote)
                     */
                    
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
                        if room.iCanSendEvent(type: M_ROOM_MESSAGE) {
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
            if room.iCanSendEvent(type: M_ROOM_MESSAGE) {
                PostComposer(room: room).navigationTitle("New Post")
            }
        }
        .background(Color.greyCool200)
        .environmentObject(viewModel)

    }
}

/*
struct ChannelView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelView()
    }
}
 */
