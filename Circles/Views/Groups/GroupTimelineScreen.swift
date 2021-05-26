//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  ChannelView.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/3/20.
//

import SwiftUI

enum GroupScreenSheetType: String {
    case members
    case invite
    case configure
    case security
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
    //@ObservedObject var room: MatrixRoom
    @ObservedObject var group: SocialGroup
    @Environment(\.presentationMode) var presentation

    @State var showComposer = false

    @State private var sheetType: GroupScreenSheetType? = nil
    
    @State private var newImageForHeader = UIImage()
    @State private var newImageForProfile = UIImage()
    @State private var newImageForMessage = UIImage()
    
    @State private var confirmNewProfileImage = false
    @State private var confirmNewHeaderImage = false
    
    @State private var newTopic = ""
    @State private var showTopicPopover = false
    
    var composer: some View {
        HStack {
            if showComposer {
                RoomMessageComposer(room: group.room, isPresented: self.$showComposer)
                    .padding([.top, .leading, .trailing])
            }
            else {
                Button(action: {self.showComposer = true}) {
                    Label("Post a New Message", systemImage: "rectangle.badge.plus")
                }
                //.padding([.top, .leading, .trailing])
                .padding()
                .background(RoundedRectangle(cornerRadius: 10)
                                .stroke(lineWidth: 2)
                                .foregroundColor(.accentColor))
            }
        }
        .padding(.top)
    }
    
    var timeline: some View {
        TimelineView(room: group.room, displayStyle: .timeline)
    }
    
    var toolbarMenu: some View {
        Menu {
            
            Button(action: {self.sheetType = .configure}) {
                Label("Configure Group", systemImage: "gearshape")
            }
            
            Button(action: {
                self.sheetType = .members
            }) {
                Label("Manage members", systemImage: "person.2.circle.fill")
            }
            
            Button(action: {
                self.sheetType = .invite
            }) {
                Label("Invite new members", systemImage: "person.crop.circle.badge.plus")
            }
            
            Button(action: {
                self.group.container.leave(group: self.group, completion: { _ in })
                self.presentation.wrappedValue.dismiss()
            }) {
                Label("Leave group", systemImage: "xmark")
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
        Text(group.room.displayName ?? "(Unnamed Group)")
    }
    
    var body: some View {
        VStack(alignment: .center) {

            composer

            timeline
                .sheet(item: $sheetType) { st in
                    let room = group.room
                    switch(st) {
                    case .members:
                        RoomMembersSheet(room: room, title: "Group members for \(room.displayName ?? "(unnamed group)")")
                    case .invite:
                        RoomInviteSheet(room: room, title: "Invite new members to \(room.displayName ?? "(unnamed group)")")
                        
                    case .configure:
                        GroupConfigSheet(room: room)
                        
                    case .security:
                        RoomSecurityInfoSheet(room: room)

                        /*
                    case .pickHeaderImage:
                        ImagePicker(selectedImage: $newImageForHeader, sourceType: .photoLibrary) { image in
                            print("Picked new header image!")
                            self.newImageForHeader = image
                            self.sheetType = .confirmHeaderImage
                        }
                        
                    case .confirmHeaderImage:
                        ConfirmImageSheet(
                            title: "Confirm New Header Image",
                            image: $newImageForHeader,
                            onAccept: {
                                // Send the new image to Matrix
                                room.setAvatarImage(image: self.newImageForHeader)
                            },
                            onGoBack: {
                                self.sheetType = .pickProfileImage
                            }
                        )

                    case .pickProfileImage:
                        ImagePicker(selectedImage: $newImageForProfile, sourceType: .photoLibrary)
                        { image in
                            print("Picked new profile image!")
                            self.newImageForProfile = image // Kind of defeats the point of the binding, eh?  But if it makes the profile image show up in the confirm sheet, ...
                            self.sheetType = .confirmProfileImage
                        }

                    case .confirmProfileImage:
                        ConfirmImageSheet(
                            title: "Confirm New Profile Picture",
                            image: $newImageForProfile,
                            onAccept: {
                                // Send the image to Matrix as our new profile
                            },
                            onGoBack: {
                                self.sheetType = .pickProfileImage
                            }
                        )
                    */
                      
                    /*
                    case .pickMessageImage:
                        ImagePicker(selectedImage: $newImageForMessage, sourceType: .photoLibrary) { image in
                            print("Picked image for a message!")
                        }
                    */
                    default:
                        Text("Something went wrong")
                    }
                }
        }
        //.padding()
            //.navigationBarTitle(room.displayName ?? room.id, displayMode: .inline)

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
