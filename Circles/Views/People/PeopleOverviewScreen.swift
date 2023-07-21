//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  PeopleOverviewScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 12/1/20.
//

import SwiftUI
import Matrix

struct PeopleOverviewScreen: View {
    @ObservedObject var people: ContainerRoom<Matrix.SpaceRoom>
    @ObservedObject var circles: ContainerRoom<CircleSpace>
    @ObservedObject var groups: ContainerRoom<GroupRoom>
    
    @State var following: [Matrix.User] = []
    @State var followers: [Matrix.User] = []
    
    @ViewBuilder
    var contactsSection: some View {
        VStack(alignment: .leading) {
            Text("CONNECTIONS")
                .font(.subheadline)
                .foregroundColor(.gray)

            ForEach(people.rooms) { room in
                let user = people.session.getUser(userId: room.creator)
                Divider()

                VStack(alignment: .leading) {
                    NavigationLink(destination: PersonDetailView(space: room)) {
                        //Text("\(user.displayName ?? user.id)")
                        PersonHeaderRow(user: user)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                }
                //.padding(.leading)
                //}
            }
        }
        .padding()

    }
    
    @ViewBuilder
    var followingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PEOPLE I'M FOLLOWING")
                .font(.subheadline)
                .foregroundColor(.gray)

            ForEach(following) { user in
                Divider()
                PersonHeaderRow(user: user)
            }
        }
        .padding()
        .onAppear {
            let followingUserIds: [UserId] = circles.rooms.reduce([], {(curr,room) in
                curr + room.following
            })
            let sortedUserIds: [UserId] = Set(followingUserIds).sorted {
                $0.stringValue < $1.stringValue
            }
            following = sortedUserIds.compactMap { userId -> Matrix.User in
                circles.session.getUser(userId: userId)
            }
        }
    }
    
    @ViewBuilder
    var followersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FOLLOWERS")
                .font(.subheadline)
                .foregroundColor(.gray)
            ForEach(followers) { user in
                Divider()
                PersonHeaderRow(user: user)
            }
        }
        .padding()
        .onAppear {
            let followersUserIds = circles.rooms.reduce([], {(curr,room) in
                curr + room.followers
            })
            let sortedUserIds: [UserId] = Set(followersUserIds).sorted {
                $0.stringValue < $1.stringValue
            }
            followers = sortedUserIds.compactMap { userId -> Matrix.User in
                circles.session.getUser(userId: userId)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    
                    //Text("\(container.rooms.count) People")
                    
                    contactsSection
                    
                    followingSection
                    
                    followersSection
                }
            }
            .navigationBarTitle("People", displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())

    }
}

/*
struct PeopleOverviewScreen_Previews: PreviewProvider {
    static var previews: some View {
        PeopleOverviewScreen()
    }
}
*/
