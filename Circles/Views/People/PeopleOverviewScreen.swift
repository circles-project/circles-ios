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
    
    @State var selectedUserId: UserId?
    
    @State var following: [Matrix.User] = []
    @State var followers: [Matrix.User] = []
    //@State var invitations: [Matrix.InvitedRoom]? = nil
    
    @State var friendsOfFriends: [UserId]? = nil
    
    @State var showInviteSheet = false
    
    @State var sheetType: SheetType?
    enum SheetType: String, Identifiable {
        case invite
        case scanQr
        case share
        
        var id: String {
            self.rawValue
        }
    }

    @ViewBuilder
    var meSection: some View {
        VStack(alignment: .leading) {
            let matrix = people.session

            Text("ME")
                .font(.subheadline)
                .foregroundColor(.gray)
            Divider()
            NavigationLink(destination: SelfDetailView(matrix: matrix, profile: profile, circles: circles),
                           tag: profile.session.creds.userId,
                           selection: $selectedUserId
            ) {
                HStack(alignment: .top) {
                    UserAvatarView(user: people.session.me)
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                    
                    VStack(alignment: .leading) {
                        Text(matrix.me.displayName ?? matrix.creds.userId.username)
                            .font(.title)
                            .fontWeight(.bold)
                            .lineLimit(1)
                        Text(matrix.creds.userId.stringValue)
                            .font(.subheadline)
                            .foregroundColor(Color.gray)
                            .lineLimit(1)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Divider()
        }
        .padding()
    }
    
    @ViewBuilder
    var contactsSection: some View {
        LazyVStack(alignment: .leading) {
            HStack {
                Text("MY CONNECTIONS")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
                Menu {
                    Button(action: { self.sheetType = .invite }) {
                        Label("Invite friends to connect", systemImage: "person.2.fill")
                    }
                    Button(action: { self.sheetType = .share }) {
                        Label("Share my profile", systemImage: "square.and.arrow.up")
                    }
                    Button(action: { self.sheetType = .scanQr }) {
                        Label("Scan a friend's QR code", systemImage: "qrcode.viewfinder")
                    }
                }
                label: {
                    Image(systemName: "plus.circle")
                }
            }
            Divider()
            
            if profile.knockingMembers.count > 0 {
                RoomKnockIndicator(room: profile)
            }
                
            ForEach(people.rooms) { room in
                let user = people.session.getUser(userId: room.creator)
                
                VStack(alignment: .leading) {
                    NavigationLink(destination: ConnectedPersonDetailView(space: room),
                                   tag: user.userId,
                                   selection: $selectedUserId
                    ) {
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
        .padding()
        .sheet(item: $sheetType) { type in
            switch type {
            case .invite:
                RoomInviteSheet(room: profile, title: "Invite friends to connect")
            case .scanQr:
                ScanQrCodeAndKnockSheet(session: profile.session)
            case .share:
                RoomShareSheet(room: profile)
            }
        }

    }
    
    @ViewBuilder
    var followingSection: some View {
        LazyVStack(alignment: .leading, spacing: 10) {
            Text("PEOPLE I'M FOLLOWING")
                .font(.subheadline)
                .foregroundColor(.gray)
            Divider()

            ForEach(following) { user in
                NavigationLink(destination: UnconnectedPersonDetailView(user: user, myProfileRoom: profile),
                               tag: user.userId,
                               selection: $selectedUserId
                ) {
                    PersonHeaderRow(user: user, profile: profile)
                        .contentShape(Rectangle())
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
                NavigationLink(destination: UnconnectedPersonDetailView(user: user, myProfileRoom: profile),
                               tag: user.userId,
                               selection: $selectedUserId
                ) {
                    PersonHeaderRow(user: user, profile: profile)
                        .contentShape(Rectangle())
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
    
    func loadFriendsOfFriends() async {
        let myUserId = profile.session.creds.userId
        // First find all of the timeline rooms that I'm following
        let timelines: Set<Matrix.Room> = circles.rooms.reduce([]) { (curr,room) in
            // Don't include my own timelines in the list
            if room.creator == myUserId {
                return curr
            } else {
                return curr.union([room])
            }
        }
        
        let userIds: Set<UserId> = timelines.reduce([]) { (curr,room) in
            let creator = room.creator
            let followers = room.joinedMembers.filter { $0 != creator && $0 != room.session.creds.userId }
            return curr.union(followers)
        }
        
        let sorted = userIds.sorted {
            $0.stringValue < $1.stringValue
        }
        
        await MainActor.run {
            self.friendsOfFriends = sorted
        }
    }
    
    @ViewBuilder
    var friendsOfFriendsSection: some View {
        LazyVStack(alignment: .leading, spacing: 10) {
            Text("FRIENDS OF FRIENDS")
                .font(.subheadline)
                .foregroundColor(.gray)
            Divider()
            
            if let userIds = friendsOfFriends {
                ForEach(userIds, id: \.self) { userId in
                    if userId != profile.session.creds.userId {
                        let user = profile.session.getUser(userId: userId)
                        HStack {
                            UserAvatarView(user: user)
                            UserNameView(user: user)
                        }
                    }
                }
            } else {
                ProgressView("Loading...")
                    .task {
                        await loadFriendsOfFriends()
                    }
            }
        }
        .padding()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    
                    //Text("\(container.rooms.count) People")
                    
                    meSection
                    
                    PeopleInvitationsIndicator(session: people.session, container: people)
                    
                    contactsSection
                    
                    followingSection
                    
                    followersSection
                    
                    friendsOfFriendsSection
                    
                    Spacer()
                        .frame(minHeight: TIMELINE_BOTTOM_PADDING)
                }
            }
            .navigationBarTitle("People", displayMode: .inline)
            
            Text("Select a profile to view additional information")
        }
        //.navigationViewStyle(StackNavigationViewStyle())

    }
}

/*
struct PeopleOverviewScreen_Previews: PreviewProvider {
    static var previews: some View {
        PeopleOverviewScreen()
    }
}
*/
