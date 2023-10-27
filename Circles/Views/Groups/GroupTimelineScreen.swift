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
    case members
    case invite
    case configure
    case security
    case composer
    case share
    //case pickHeaderImage
    //case pickProfileImage
    //case pickMessageImage
    //case confirmHeaderImage
    //case confirmProfileImage
    // Don't need to confirm a new image if it's for a message... We put it into the composer, and the user looks at it there before clicking 'Send'
}
extension GroupScreenSheetType: Identifiable {
    var id: String { rawValue }
}

struct GroupTimelineScreen: View {
    @ObservedObject var room: Matrix.Room
    //@ObservedObject var group: SocialGroup
    @Environment(\.presentationMode) var presentation
    @EnvironmentObject var galleries: ContainerRoom<GalleryRoom>
    
    @State var showComposer = false

    @State private var sheetType: GroupScreenSheetType? = nil

    @State private var newImageForHeader = UIImage()
    @State private var newImageForProfile = UIImage()
    @State private var newImageForMessage = UIImage()
    
    @State private var confirmNewProfileImage = false
    @State private var confirmNewHeaderImage = false
    
    @State private var newTopic = ""
    @State private var showTopicPopover = false

    @State var nilParentMessage: Matrix.Message? = nil
    
    /*
    var composer: some View {
        HStack {
            if showComposer {
                RoomMessageComposer(room: group.room, isPresented: self.$showComposer)
                    .padding([.top, .leading, .trailing], 3)
            }
            else {
                Button(action: {self.showComposer = true}) {
                    Label("Post a New Message", systemImage: "rectangle.badge.plus")
                }
            }
        }
        .padding(.top, 5)
    }
    */
    
    var timeline: some View {
        TimelineView<MessageCard>(room: room)
    }
    
    var toolbarMenu: some View {
        Menu {
            
            if room.iCanChangeState(type: M_ROOM_NAME) || room.iCanChangeState(type: M_ROOM_AVATAR) {
                Button(action: {self.sheetType = .configure}) {
                    Label("Configure Group", systemImage: "gearshape")
                }
            }

            if room.iCanBan || room.iCanKick {
                Button(action: {
                    self.sheetType = .members
                }) {
                    Label("Manage members", systemImage: "person.2.circle.fill")
                }
            }
            
            if room.iCanInvite {
                Button(action: {
                    self.sheetType = .invite
                }) {
                    Label("Invite new members", systemImage: "person.crop.circle.badge.plus")
                }
            }
            
            Button(action: {
                self.sheetType = .share
            }) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            
            Button(action: {
                self.sheetType = .security
            }) {
                Label("Security", systemImage: "shield.fill")
            }
            
        }
        label: {
            Label("More", systemImage: "ellipsis.circle")
        }
    }
    
    var title: Text {
        Text(room.name ?? "(Unnamed Group)")
    }
    
    var body: some View {
        
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
                        case .members:
                            RoomMembersSheet(room: room, title: "Group members for \(room.name ?? "(unnamed group)")")
                        
                        case .invite:
                            RoomInviteSheet(room: room, title: "Invite new members to \(room.name ?? "(unnamed group)")")
                            
                        case .configure:
                            GroupConfigSheet(room: room)
                            
                        case .security:
                            RoomSecurityInfoSheet(room: room)
                            
                        case .composer:
                            MessageComposerSheet(room: room, parentMessage: nilParentMessage, galleries: galleries)
                            
                        case .share:
                            let url = URL(string: "https://\(CIRCLES_PRIMARY_DOMAIN)/group/\(room.roomId.stringValue)")
                            RoomShareSheet(room: room, url: url)
                        }
                    }
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        self.sheetType = .composer
                    }) {
                        Image(systemName: "plus.bubble.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .padding()
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

    }
}

/*
struct ChannelView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelView()
    }
}
 */
