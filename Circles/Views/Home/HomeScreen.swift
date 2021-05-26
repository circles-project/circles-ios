//
//  HomeScreen.swift
//  Kombucha Social
//
//  Created by Macro Ramius on 11/3/20.
//

import SwiftUI

struct HomeScreen: View {
    @ObservedObject var store: KSStore
    @ObservedObject var user: MatrixUser
    @Binding var screen: HomeTabMasterView.Screen?
    
    @State var showAcceptSheet = false
    @State var showImagePicker = false
    
    @State var showConfirmLogout = false
    
    var image: Image {
        if let img = user.avatarImage {
            return Image(uiImage: img)
        } else {
            return Image(systemName: "person.crop.square.fill")
        }
    }
    
    var profile: some View {
        VStack(alignment: .leading) {
            
            Button(action: {self.screen = .profile}) {
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
                    self.screen = .invites
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

                    Text("Unverified Devices")
                        .font(.headline)
                }
                
                Text("It appears that you have some unverified device(s) connected to your account. Please take a look at these.")
                    .font(.footnote)
                Text("If a new device is legitimate, please verify it so that other users can trust it. Otherwise you will not be able to see other users' postings from your new device.")
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
    
    var body: some View {
        //NavigationView {
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
            //.padding()
            .navigationBarTitle("Welcome!", displayMode: .inline)
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
