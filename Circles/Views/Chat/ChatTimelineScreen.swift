//
//  ChatTimelineScreen.swift
//  Circles
//
//  Created by Charles Wright on 7/26/24.
//

import SwiftUI
import Matrix

enum ChatScreenSheetType: String {
    case invite
    case share
}
extension ChatScreenSheetType: Identifiable {
    var id: String { rawValue }
}

struct ChatTimelineScreen: View {
    @ObservedObject var room: Matrix.Room

    @Environment(\.presentationMode) var presentation
    
    @State private var sheetType: ChatScreenSheetType? = nil

    @State private var newImageForHeader = UIImage()
    @State private var newImageForProfile = UIImage()
    @State private var newImageForMessage = UIImage()
    
    @State private var confirmNewProfileImage = false
    @State private var confirmNewHeaderImage = false
    
    @State private var newTopic = ""
    @State private var showTopicPopover = false

    @State var nilParentMessage: Matrix.Message? = nil
    
    var timeline: some View {
        TimelineView<MessageCard>(room: room)
    }
    
    var toolbarMenu: some View {
        Menu {
            NavigationLink(destination: ChatSettingsView(room: room)) {
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
        Text(room.name ?? "(Unnamed Chat)")
    }
    
    var body: some View {
        NavigationStack {
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
                            RoomInviteSheet(room: room, title: "Invite new members to \(room.name ?? "(unnamed chat)")")
                            
                        case .share:
                            let url = URL(string: "https://\(CIRCLES_PRIMARY_DOMAIN)/chat/\(room.roomId.stringValue)")
                            RoomShareSheet(room: room, url: url)
                        }
                    }
                    .padding([.top], -4)
            }
                
            Text("Composer goes here")
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                toolbarMenu
            }
        }
        .navigationBarTitle(title, displayMode: .inline)
        .background(Color.greyCool200)
    }
}
