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
    @ObservedObject var profile: ProfileSpace
    @ObservedObject var circles: ContainerRoom<CircleSpace>
    @ObservedObject var groups: ContainerRoom<GroupRoom>
    
    @State var selectedUserId: UserId?
    
    @State var connections: [Matrix.User] = []
    @State var following: [Matrix.User] = []
    @State var followers: [Matrix.User] = []
    //@State var invitations: [Matrix.InvitedRoom]? = nil
    
    @State var friendsOfFriends: [UserId]? = nil
    
    /*
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

    }
    */
    
    func loadFriendsOfFriends() async {
        CirclesApp.logger.debug("Loading friends of friends")
        let myUserId = profile.session.creds.userId
        // First find all of the timeline rooms that I'm following
        let timelines: Set<Matrix.Room> = circles.rooms.values.reduce([]) { (curr,circle) in
            CirclesApp.logger.debug("Looking for followed timelines in circle \(circle.name ?? circle.roomId.stringValue)")
            // Don't include my own timelines in the list
            let followedRooms = circle.rooms.values.filter { $0.creator != myUserId }
            return curr.union(followedRooms)
        }
        CirclesApp.logger.debug("Found \(timelines.count) timelines we are following")
        
        let userIds: Set<UserId> = timelines.reduce([]) { (curr,room) in
            let creator = room.creator
            let followers = room.joinedMembers.filter { $0 != creator && $0 != room.session.creds.userId }
            CirclesApp.logger.debug("Found \(followers.count) friends of a friend in room \(room.name ?? room.roomId.stringValue)")
            return curr.union(followers)
        }
        CirclesApp.logger.debug("Found a total of \(userIds.count) user ids following friends' timelines")
        
        let sorted = userIds.sorted {
            $0.stringValue < $1.stringValue
        }
        
        await MainActor.run {
            self.friendsOfFriends = sorted
        }
    }

    
    enum PeopleTabSection: String, Hashable, Identifiable {
        var id: String { rawValue }
        
        case me = "Me"
        case connections = "My Connections"
        case following = "People I'm Following"
        case followers = "My Followers"
        case friendsOfFriends = "Friends of Friends"
    }

    @State var selected: PeopleTabSection?
    
    var body: some View {
        NavigationSplitView {
            VStack {
                                
                List(selection: $selected) {
                    Section("Me") {
                        NavigationLink(value: PeopleTabSection.me) {
                            let me = profile.session.me
                            PersonHeaderRow(user: me, profile: profile)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Section("My Connections") {
                        let count = connections.count
                        if count > 0 {
                            let units = count > 1 ? "Connections" : "Connection"
                            NavigationLink(value: PeopleTabSection.connections) {
                                Text("See \(count) \(units)")
                            }
                        } else {
                            Text("No connections")
                        }
                    }
                    .onAppear {
                        let userIds = people.rooms.values.compactMap { $0.creator }
                        let sorted = Set(userIds).sorted { $0 < $1 }
                        connections = sorted.compactMap {
                            profile.session.getUser(userId: $0)
                        }
                    }
                    
                    Section("People I'm Following") {
                        let count = following.count
                        if count > 0 {
                            let units = count > 1 ? "People" : "Person"
                            NavigationLink(value: PeopleTabSection.following) {
                                Text("See \(count) \(units) I'm Following")
                            }
                        } else {
                            Text("Not following anyone")
                        }
                    }
                    .onAppear {
                        let followingUserIds: [UserId] = circles.rooms.values.reduce([], {(curr,room) in
                            curr + room.following
                        })
                        let sortedUserIds: [UserId] = Set(followingUserIds).sorted {
                            $0.stringValue < $1.stringValue
                        }
                        following = sortedUserIds.compactMap { userId -> Matrix.User in
                            circles.session.getUser(userId: userId)
                        }
                    }
                    
                    Section("My Followers") {
                        let count = followers.count
                        if count > 0 {
                            let units = count > 1 ? "Followers" : "Follower"
                            NavigationLink(value: PeopleTabSection.followers) {
                                Text("See \(count) \(units)")
                            }
                        } else {
                            Text("No followers")
                        }
                    }
                    .onAppear {
                        let followersUserIds = circles.rooms.values.reduce([], {(curr,room) in
                            curr + room.followers
                        })
                        let sortedUserIds: [UserId] = Set(followersUserIds).sorted {
                            $0.stringValue < $1.stringValue
                        }
                        followers = sortedUserIds.compactMap { userId -> Matrix.User in
                            circles.session.getUser(userId: userId)
                        }
                    }
                    
                    Section("Friends of Friends") {
                        if let count = friendsOfFriends?.count {
                            if count > 0 {
                                let units = count > 1 ? "Friends of friends" : "Friend of a Friend"
                                NavigationLink(value: PeopleTabSection.friendsOfFriends) {
                                    Text("See \(count) \(units)")
                                }
                            }
                            else {
                                Text("No friends of friends")
                            }
                        } else {
                            ProgressView("Loading friends of friends")
                        }
                    }
                    .task {
                        await loadFriendsOfFriends()
                    }
                }
                .listStyle(.plain)
                .accentColor(.secondaryBackground)
                
                /*
                List(selection: $selection) {
                    ForEach(subsections) { subsection in
                        Text(subsection.rawValue)
                    }
                    /*

                     */
                }
                */
            }
            .navigationTitle("People")
            .navigationBarTitleDisplayMode(.inline)
        } detail: {
            NavigationStack {
                switch selected {
                case .me:
                    SelfDetailView(profile: profile, circles: circles)
                case .connections:
                    MyConnectionsView(profile: profile, people: people)
                case .following:
                    FollowingView(profile: profile, following: $following)
                case .followers:
                    FollowersView(profile: profile, followers: $followers)
                case .friendsOfFriends:
                    FriendsOfFriendsView(profile: profile, people: people, friendsOfFriends: $friendsOfFriends)
                default:
                    Text("default")
                }
            }
        }
    }
}

/*
struct PeopleOverviewScreen_Previews: PreviewProvider {
    static var previews: some View {
        PeopleOverviewScreen()
    }
}
*/
