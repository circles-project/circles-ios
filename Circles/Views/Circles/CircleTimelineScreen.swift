//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  CircleTimelineScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 12/17/20.
//

import SwiftUI

enum CircleSheetType: String {
    case settings
    case followers
    case following
    case invite
    case photo
    case composer
}
extension CircleSheetType: Identifiable {
    var id: String { rawValue }
}

struct CircleTimelineScreen: View {
    @ObservedObject var circle: SocialCircle
    @Environment(\.presentationMode) var presentation
    
    //@State var showComposer = false
    @State var sheetType: CircleSheetType? = nil
    @State var image: UIImage?
    
    var toolbarMenu: some View {
        Menu {
            Menu {
                Button(action: {
                    circle.graph.removeCircle(circle: circle)
                    self.presentation.wrappedValue.dismiss()
                }) {
                    Label("Delete this Circle", systemImage: "trash")
                }
                
                Button(action: {
                    self.sheetType = .photo
                }) {
                    Label("New Cover Photo", systemImage: "photo")
                }
            }
            label: {
                Label("Settings", systemImage: "gearshape")
            }
            
            Menu {
                Button(action: {self.sheetType = .followers}) {
                    Label("My followers", systemImage: "person.2.circle")
                }
                Button(action: {self.sheetType = .following}) {
                    Label("People I'm following", systemImage: "person.2.circle.fill")
                }
            }
            label: {
                Label("Connections", systemImage: "person.2.circle")
            }
            
            Button(action: {self.sheetType = .invite}) {
                Label("Invite Followers", systemImage: "person.crop.circle.badge.plus")
            }
            
            Button(action: {self.sheetType = .composer}) {
                Label("Post a New Message", systemImage: "plus.bubble")
            }
            
            /*
            Button(action:{
                circle.matrix.createRoom(name: circle.name,
                                         with: ROOM_TAG_OUTBOUND,
                                         insecure: false
                ) { response1 in
                    switch response1 {
                    case .failure( _):
                        print("OUTBOUND\tFailed to create room")
                    case .success(let mxroom):
                        print("OUTBOUND\tSuccess creating room")
                        
                        guard let room = circle.matrix.getRoom(roomId: mxroom.roomId) else {
                            print("OUTBOUND\tFailed to create room from mxroom")
                            return
                        }
                        
                        room.setRoomType(type: ROOM_TYPE_CIRCLE) { roomtypeResponse in
                            if roomtypeResponse.isSuccess {
                                print("OUTBOUND\tSuccessfully set room type")
                            }
                            else {
                                print("OUTBOUND\tFailed to set room type")
                            }
                        }
                        
                        circle.stream.addRoom(roomId: mxroom.roomId) { response2 in
                            if response2.isSuccess {
                                circle.graph.saveCircles() { _ in }
                            }
                        }
                    }
                }
            }) {
                Label("Recreate Outbound Room", systemImage: "stethoscope")
            }
            */
            

        }
        label: {
            Label("More", systemImage: "ellipsis.circle")
        }
    }

    var stupidSwiftUiTrick: Int {
        print("DEBUGUI\tStreamTimeline rendering for Circle \(circle.id)")
        return 0
    }
    
    var body: some View {
        //VStack {
            /*
            composer
                .layoutPriority(1)
            */
        let foo = self.stupidSwiftUiTrick
            
            StreamTimeline(stream: circle.stream)
                .navigationBarTitle(circle.name, displayMode: .inline)
                .toolbar {
                    ToolbarItemGroup(placement: .automatic) {
                        toolbarMenu
                    }
                }
                .onAppear {
                    print("DEBUGUI\tStreamTimeline appeared for Circle \(circle.id)")
                }
                .onDisappear {
                    print("DEBUGUI\tStreamTimeline disappeared for Circle \(circle.id)")
                }
                .sheet(item: $sheetType) { st in
                    switch(st) {
                    case .invite:
                        RoomInviteSheet(room: circle.wall!)
                    case .followers:
                        RoomMembersSheet(room: circle.wall!)
                    case .following:
                        CircleConnectionsSheet(circle: circle)
                    case .photo:
                        ImagePicker(selectedImage: self.$image, sourceType: .photoLibrary, allowEditing: false) { maybeImage in
                            guard let room = self.circle.outbound,
                                  let newImage = maybeImage
                            else {
                                print("CIRCLEIMAGE\tEither we couldn't find an outbound room, or the user didn't pick an image")
                                return
                            }
                            room.setAvatarImage(image: newImage)
                            
                        }
                    case .composer:
                        MessageComposerSheet(room: circle.wall!)
                    default:
                        Text("Coming soon!")
                    }
                }
        //}
    }
}

/*
struct CircleTimelineScreen_Previews: PreviewProvider {
    static var previews: some View {
        CircleTimelineScreen()
    }
}
*/
