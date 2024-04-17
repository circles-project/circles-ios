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
    @ObservedObject var profile: ProfileSpace
    @State var rooms: [Matrix.SpaceChildRoom] = []
    
    init(space: PersonRoom, profile: ProfileSpace) {
        self.space = space
        self.user = space.session.getUser(userId: space.creator)
        self.profile = profile
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
            UserAvatarView(user: user)
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
            
            circles
            
            Divider()
            
            MutualFriendsSection(user: user, profile: profile)
            
            
        } }
        .padding()
        .onAppear {
            // Hit the Homeserver to make sure we have the latest
            //user.matrix.getDisplayName(userId: user.id) { _ in }
                user.refreshProfile()
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
