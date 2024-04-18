//
//  MyConnectionsView.swift
//  Circles
//
//  Created by Charles Wright on 4/17/24.
//

import SwiftUI
import Matrix

struct MyConnectionsView: View {
    @ObservedObject var profile: ProfileSpace
    @ObservedObject var people: ContainerRoom<Matrix.SpaceRoom>
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                let rooms = people.rooms.values.sorted { $0.creator < $1.creator }
                ForEach(rooms) { room in
                    let user = people.session.getUser(userId: room.creator)
                    
                    VStack(alignment: .leading) {
                        NavigationLink(destination: ConnectedPersonDetailView(space: room, profile: profile)) {
                            //Text("\(user.displayName ?? user.id)")
                            PersonHeaderRow(user: user, profile: profile)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                    }
                    .contentShape(Rectangle())
                    //.padding(.leading)
                    //}
                    Divider()
                }
            }
        }
        .padding()
        .navigationTitle("My Connections")
    }
}

