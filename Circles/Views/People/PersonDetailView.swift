//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  PersonDetailView.swift
//  Circles for iOS
//
//  Created by Charles Wright on 2/3/21.
//

import SwiftUI

struct PersonDetailView: View {
    @ObservedObject var user: MatrixUser
    @State var showComposer = false
    @State var selectedRoom: MatrixRoom? = nil
    
    var avatar: Image {
        return (user.avatarImage != nil)
            ? Image(uiImage: user.avatarImage!)
            : Image(systemName: "person.crop.square")
    }
    
    var status: some View {
        HStack {
            Text("Latest Status:")
                .fontWeight(.bold)
            Text(user.statusMsg ?? "(no status message)")
        }
        .font(.subheadline)
    }
    
    var circles: some View {
        VStack {
            Text("\(user.displayName ?? "This user")'s Circles")
                .font(.headline)
                .fontWeight(.bold)
            VStack(alignment: .leading) {
                ForEach(user.rooms.filter({$0.tags.contains(ROOM_TAG_FOLLOWING)})) { room in
                    PersonsCircleRow(room: room)
                }
            }
            .padding(.leading, 20)
        }
    }
    
    var composer: some View {
        HStack {
            if let room = self.selectedRoom {
                if self.showComposer {
                    RoomMessageComposer(room: room, isPresented: $showComposer)
                }
                else {
                    Button(action: {self.showComposer = true}) {
                        Label("Post a new message to \(user.displayName ?? "this user")'s circle \"\(room.displayName ?? "(untitled)")\"", systemImage: "rectangle.badge.plus")
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10)
                                    .stroke(lineWidth: 2)
                                    .foregroundColor(.accentColor))
                }
            }
        }
        .padding(.leading, 10)
    }
    
    var timeline: some View {
        VStack {
            let rooms = user.rooms
                .filter({ room in
                    room.tags.contains(ROOM_TAG_FOLLOWING)
                })
            
            if !rooms.isEmpty {
                Text("\(user.displayName ?? "This user")'s Circles")
                    .font(.headline)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading) {
                    ForEach(rooms) { room in
                        if self.selectedRoom == room {
                            PersonsCircleRow(room: room)
                                .padding(.vertical, 5)
                                .foregroundColor(Color.white)
                                .background(Color.accentColor)
                        }
                        else {
                            Button(action: {
                                self.selectedRoom = room
                                self.showComposer = false
                            }) {
                                PersonsCircleRow(room: room)
                            }
                        }
                    }
                    
                    if self.selectedRoom == nil {
                        PersonsDummyCircleRow(user: user)
                            .padding(.vertical, 5)
                            .foregroundColor(Color.white)
                            .background(Color.accentColor)
                    }
                    else {
                        Button(action: {
                            self.selectedRoom = nil
                            self.showComposer = false
                        }) {
                            PersonsDummyCircleRow(user: user)
                        }
                    }
                }
                
                Divider()
                
                if let room = self.selectedRoom {
                    composer
                        .padding([.top,.leading,.trailing])
                    
                    TimelineView(room: room)
                        .padding(.leading, 10)
                }
                else {
                    StreamTimeline(stream: SocialStream(for: user))
                        .padding(.leading, 10)
                }
            }
            else {
                Text("Not following any Circles for \(user.displayName ?? "This user")")
            }
        }
    }
    
    var header: some View {
        HStack {
            avatar
                .resizable()
                .scaledToFill()
                .frame(width: 160, height: 160, alignment: .center)
                .clipShape(RoundedRectangle(cornerRadius: 40))
                //.padding(.leading)
            VStack {
                Text(user.displayName ?? "")
                    .font(.title2)
                    .fontWeight(.bold)
                Text(user.id)
                    .font(.subheadline)
            }
        }
    }
    
    var body: some View {
        VStack { ScrollView {

            header

            //status
            
            Divider()
            
            timeline
            
        } }
        .padding()
        .onAppear {
            // Hit the Homeserver to make sure we have the latest
            //user.matrix.getDisplayName(userId: user.id) { _ in }
            user.refreshProfile(completion: { _ in })
        }
    }
}

/*
struct PersonView_Previews: PreviewProvider {
    static var previews: some View {
        PersonView()
    }
}
*/
