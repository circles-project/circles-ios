//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  HomeScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/3/20.
//

import SwiftUI

struct HomeScreen: View {
    @ObservedObject var store: KSStore
    @ObservedObject var user: MatrixUser
    //@Binding var screen: HomeTabMasterView.Screen?
    @Binding var tab: LoggedinScreen.Tab
    
    @State var showAcceptSheet = false
    @State var showImagePicker = false
    
    @State var showConfirmLogout = false

    enum SheetType: String, Identifiable {
        var id: String {
            self.rawValue
        }

        case profile
        case account
        case notices
        case invites
        case sessions
        case credits
    }
    @State var sheetType: SheetType?


    var image: Image {
        if let img = user.avatarImage {
            return Image(uiImage: img)
        } else {
            return Image(systemName: "person.crop.square.fill")
        }
    }

    var profile: some View {
        VStack(alignment: .leading) {
            
            Button(action: {self.sheetType = .profile}) {
                ProfileView(user: user)
            }
            .buttonStyle(PlainButtonStyle())
            
            Divider()
        }
    }
    
    var notices: some View {
        // Here we need to look in all rooms tagged with m.server_notice
        VStack(alignment: .leading) {
            if let room = store.getSystemNoticesRoom() {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")

                    Text("System Notices")
                        .font(.headline)
                }
                
                //TimelineView(room: room)
                
                Divider()
            }
        }
    }
    
    var invitations: some View {
        VStack(alignment: .leading) {
            var invitedRooms = store.getInvitedRooms()
            if !invitedRooms.isEmpty {
                Label("New Invitations", systemImage:"envelope.open.fill")

                /*
                InvitationsView(store: store)
                    .padding(.trailing, 2)
                */
                
                Button(action: {
                    self.sheetType = .invites
                }) {
                    Label("See \(invitedRooms.count) new invitations", systemImage: "envelope.circle")
                }
                .padding(.leading)
                
                Divider()
            }
        }

    }
    
    var devices: some View {
        VStack(alignment: .leading) {

            let unverifiedDevices = user.devices.filter { !$0.isVerified }
            if !unverifiedDevices.isEmpty {
                HStack {
                    //Image(systemName: "desktopcomputer")
                    Image(systemName: "exclamationmark.triangle.fill")

                    Text("Unverified Sessions")
                        .font(.headline)
                }
                
                Text("It appears that you have some unverified sessions(s) active for your account. Please take a look at these.")
                    .font(.footnote)
                Text("If a new session is legitimate, please verify it so that other users can trust it. Otherwise you will not be able to see other users' postings from your new session.")
                    .font(.footnote)
                
                ForEach(unverifiedDevices) { device in
                //ForEach(user.devices) { device in
                    DeviceInfoView(device: device)
                    //Text(device.displayName ?? "(unnamed device)")
                }
                .padding(.leading)
                
            }
            Divider()
        }

    }
    
    var events: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "calendar")

                Text("Upcoming Events")
                    .font(.headline)
            }
            Divider()
        }
    }
    
    var recents: some View {
        // Newest version -- Call out to the RecentActivityView to render here
        VStack(alignment: .leading) {
            Label("Latest Posts From My Network", systemImage: "bubble.left.and.bubble.right.fill")
                .font(.headline)
            RecentActivityView(store: store)
                .padding(.trailing, 2)
        }
    }
    
    var testing: some View {
        EmptyView()
    }

    var menu: some View {
        Menu {
            Button(action: {
                self.sheetType = .account
            }) {
                Label("My Account", systemImage: "folder.badge.person.crop")
            }

            Button(action: {
                self.sheetType = .notices
            }) {
                Label("System Notices", systemImage: "exclamationmark.triangle.fill")
            }

            Button(action: {
                self.sheetType = .invites
            }) {
                Label("New Invitations", systemImage: "envelope.open.fill")
            }

            Button(action: {
                self.sheetType = .sessions
            }) {
                Label("Login Sessions", systemImage: "desktopcomputer")
            }

            Button(action: {
                self.sheetType = .credits
            }) {
                Label("Credits", systemImage: "scroll")
            }

            Button(action: {
                self.showConfirmLogout = true
            }) {
                Label("Logout", systemImage: "power")
            }
        }
        label: {
            Label("More", systemImage: "ellipsis.circle")
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {

                        profile

                        notices

                        invitations

                        //events

                        devices

                        //testing

                        recents
                            .padding(.bottom, 10)
                }
            }
            .navigationBarTitle("Welcome!", displayMode: .inline)
            .navigationBarItems(trailing: menu)
        }
        .sheet(item: $sheetType) { st in
            VStack {
                switch st {
                case .profile:
                    ProfileScreen(user: self.user)
                case .account:
                    AccountScreen(user: self.user)
                case .notices:
                    SystemNoticesScreen(store: self.store)
                case .invites:
                    InvitationsScreen(store: self.store)
                case .sessions:
                    DevicesScreen(user: self.user)
                case .credits:
                    AcknowledgementsSheet()
                /*
                default:
                    Text("Sheet for \(st.rawValue)")
                */
                }
            }
        }
        .actionSheet(isPresented: $showConfirmLogout) {
            ActionSheet(
                title: Text("Confirm Logout"),
                message: Text("Do you really want to log out?"),
                buttons: [
                    .cancel {self.showConfirmLogout = false},
                    .destructive(Text("Yes, log me out")) {
                        //self.store.logout()
                        self.store.pause()
                        //self.presentation.wrappedValue.dismiss()
                    }
                ]
            )
        }

            //.padding()
        //}
    }
}

/*
struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen(store: KSStore())
    }
}
*/
