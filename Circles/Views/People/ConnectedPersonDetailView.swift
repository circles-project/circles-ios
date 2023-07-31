//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  PersonDetailView.swift
//  Circles for iOS
//
//  Created by Charles Wright on 2/3/21.
//

import SwiftUI
import Matrix

struct ConnectedPersonDetailView: View {
    @ObservedObject var space: PersonRoom
    @ObservedObject var user: Matrix.User
    @State var rooms: [Matrix.SpaceChildRoom] = []
    
    init(space: PersonRoom) {
        self.space = space
        self.user = space.session.getUser(userId: space.creator)
    }
    
    var avatar: Image {
        return (user.avatar != nil)
            ? Image(uiImage: user.avatar!)
            : Image(systemName: "person.crop.square")
    }
    
    var status: some View {
        HStack {
            Text("Latest Status:")
                .fontWeight(.bold)
            Text(user.statusMessage ?? "(no status message)")
        }
        .font(.subheadline)
    }
    
    var circles: some View {
        VStack {
            Text("\(user.displayName ?? "This user")'s Circles")
                .font(.headline)
                .fontWeight(.bold)
            VStack(alignment: .leading) {
                ForEach(rooms) { room in
                    PersonsCircleRow(room: room)
                }
            }
            .padding(.leading, 20)
        }
    }

    /*
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
    */
    
    var timeline: some View {
        VStack {
            
            if !rooms.isEmpty {
                Text("\(user.displayName ?? "This user")'s Circles")
                    .font(.headline)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading) {
                    ForEach(rooms) { room in
                        PersonsCircleRow(room: room)
                            .padding(.vertical, 5)
                            .foregroundColor(Color.white)
                            .background(Color.accentColor)

                    }
                }
            }
            else {
                Text("No Circles for \(user.displayName ?? "this user")")
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
            let _ = Task {
                try await user.refreshProfile()
            }
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
