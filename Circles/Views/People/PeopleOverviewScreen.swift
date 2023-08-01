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
    @ObservedObject var profile: ContainerRoom<Matrix.Room>
    @ObservedObject var circles: ContainerRoom<CircleSpace>
    @ObservedObject var groups: ContainerRoom<GroupRoom>
    
    @State var following: [Matrix.User] = []
    @State var followers: [Matrix.User] = []
    //@State var invitations: [Matrix.InvitedRoom]? = nil
    @State var showInviteSheet = false
    
    @ViewBuilder
    var meSection: some View {
        VStack(alignment: .leading) {
            let matrix = people.session

            Text("ME")
                .font(.subheadline)
                .foregroundColor(.gray)
            Divider()
            NavigationLink(destination: SelfDetailView(matrix: matrix, profile: profile, circles: circles)) {
                HStack(alignment: .top) {
                    Image(uiImage: matrix.avatar ?? UIImage(systemName: "person.crop.square")!)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 70, height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                    
                    VStack(alignment: .leading) {
                        Text(matrix.displayName ?? matrix.creds.userId.username)
                            .font(.title)
                            .fontWeight(.bold)
                            .lineLimit(1)
                        Text(matrix.creds.userId.stringValue)
                            .font(.subheadline)
                            .foregroundColor(Color.gray)
                            .lineLimit(1)
                    }
                }
            }
            .buttonStyle(.plain)
            Divider()
        }
        .padding()
    }
    
    @ViewBuilder
    var invitesSection: some View {
        HStack {
            Spacer()
            
            let invitations = profile.session.invitations.values.filter { room in
                room.type == M_SPACE
            }
            
            if !invitations.isEmpty {
                NavigationLink(destination: PeopleInvitationsView(people: people)) {
                    Text("\(invitations.count) invitation(s) to connect")
                }
            }

            Spacer()
        }
    }
    
    @ViewBuilder
    var contactsSection: some View {
        LazyVStack(alignment: .leading) {
            Text("MY CONNECTIONS")
                .font(.subheadline)
                .foregroundColor(.gray)
            Divider()


            if people.rooms.isEmpty {
                Text("Not connected with anyone")
                    .padding()
                Button(action: {
                    showInviteSheet = true
                }) {
                    Label("Invite friends to connect", systemImage: "plus.circle")
                }
                .padding(.leading)
                .sheet(isPresented: $showInviteSheet) {
                    RoomInviteSheet(room: profile, title: "Invite friends to connect")
                }
            } else {
                ForEach(people.rooms) { room in
                    let user = people.session.getUser(userId: room.creator)
                    
                    VStack(alignment: .leading) {
                        NavigationLink(destination: ConnectedPersonDetailView(space: room)) {
                            //Text("\(user.displayName ?? user.id)")
                            PersonHeaderRow(user: user, profile: profile)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                    }
                    //.padding(.leading)
                    //}
                    Divider()
                }
            }
        }
        .padding()

    }
    
    @ViewBuilder
    var followingSection: some View {
        LazyVStack(alignment: .leading, spacing: 10) {
            Text("PEOPLE I'M FOLLOWING")
                .font(.subheadline)
                .foregroundColor(.gray)
            Divider()

            ForEach(following) { user in
                NavigationLink(destination: UnconnectedPersonDetailView(user: user)) {
                    PersonHeaderRow(user: user, profile: profile)
                }
                .buttonStyle(.plain)
                Divider()
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
        LazyVStack(alignment: .leading, spacing: 10) {
            Text("MY FOLLOWERS")
                .font(.subheadline)
                .foregroundColor(.gray)
            Divider()

            ForEach(followers) { user in
                NavigationLink(destination: UnconnectedPersonDetailView(user: user)) {
                    PersonHeaderRow(user: user, profile: profile)
                }
                .buttonStyle(.plain)
                Divider()
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
                    
                    meSection
                    
                    invitesSection
                    
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
