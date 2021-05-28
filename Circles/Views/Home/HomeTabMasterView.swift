//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  HomeTabMasterView.swift
//  Circles for iOS
//
//  Created by Charles Wright on 2/26/21.
//

import SwiftUI

struct HomeTabMasterView: View {
    var store: KSStore
    var user: MatrixUser
    @Environment(\.presentationMode) var presentation

    @Binding var tab: LoggedinScreen.Tab
    
    @State var showConfirmLogout = false

    enum Screen: String {
        case home
        case profile
        case account
        case notices
        case invites
        case devices
        case recents
    }
    @State var selected: Screen? = .home
    //@SceneStorage("homeScreen") var selected: Screen? = .home
    
    var logoutButton: some View {
        //HStack(alignment: .top) {
        //    Spacer()
            
            Button(action: {
                //self.store.logout()
                self.showConfirmLogout = true
            }) {
                //HStack {
                    Text("Logout")
                        .font(.subheadline)
                //}
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
                            self.presentation.wrappedValue.dismiss()
                        }
                    ]
                )
            }
        //}
    }
    
    var home: some View {
        VStack(alignment: .leading) {
            NavigationLink(destination: HomeScreen(store: store, user: user, screen: $selected),
                           tag: Screen.home,
                           selection: $selected) {
                HStack {
                    Label("Welcome", systemImage: "house")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                }
            }
            .buttonStyle(PlainButtonStyle())
            Divider()
        }
    }
    
    var profile: some View {
        VStack(alignment: .leading) {
            NavigationLink(destination: ProfileScreen(user: user),
                           tag: Screen.profile,
                           selection: $selected) {
                HStack {
                    Label("My Public Profile", systemImage: "person.crop.square.fill")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                }
            }
            .buttonStyle(PlainButtonStyle())
            Divider()
        }
    }
    
    var account: some View {
        VStack(alignment: .leading) {
            NavigationLink(destination: AccountScreen(user: user),
                           tag: Screen.account,
                           selection: $selected) {
                HStack {
                    Label("My Account", systemImage: "folder.badge.person.crop")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                }
            }
            .buttonStyle(PlainButtonStyle())
            Divider()
        }
    }
    
    var notices: some View {
        VStack(alignment: .leading) {
            NavigationLink(destination: SystemNoticesScreen(store: store),
                           tag: Screen.notices,
                           selection: $selected) {
                HStack {
                    Label("System Notices", systemImage: "exclamationmark.triangle.fill")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                }

            }
            .buttonStyle(PlainButtonStyle())
            Divider()
        }
    }
    
    var invitations: some View {
        VStack(alignment: .leading) {
            NavigationLink(destination: InvitationsScreen(store: store),
                           tag: Screen.invites,
                           selection: $selected) {
                HStack {
                    Label("New Invitations", systemImage: "envelope.open.fill")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                }
            }
            .buttonStyle(PlainButtonStyle())
            Divider()
        }
    }
    
    var devices: some View {
        VStack(alignment: .leading) {
            NavigationLink(destination: DevicesScreen(user: user),
                           tag: Screen.devices,
                           selection: $selected) {
                HStack {
                    Label("My Devices", systemImage: "desktopcomputer")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                }
            }
            .buttonStyle(PlainButtonStyle())
            Divider()
        }
    }
    
    var recents: some View {
        VStack(alignment: .leading) {
            NavigationLink(destination: RecentActivityScreen(store: store),
                       tag: Screen.recents,
                       selection: $selected) {
                HStack {
                    Label("Latest Posts From My Network", systemImage: "bubble.left.and.bubble.right.fill")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                }
            }
            .buttonStyle(PlainButtonStyle())
            Divider()
        }
    }
    

    
    var body: some View {
        NavigationView {
            ScrollView {

                VStack(alignment: .leading) {
                    
                    RandomizedCircles()
                        .clipped()
                        .frame(minWidth: 100, idealWidth: 250, maxWidth: 350, minHeight: 100, idealHeight: 250, maxHeight: 350, alignment: .center)
                
                    home
                    
                    profile
                    
                    account
                    
                    notices

                    invitations
                        
                    //events
                                        
                    devices
                    
                    recents
                }
            }
            .padding()
            .navigationBarTitle("Home", displayMode: .inline)
            .navigationBarItems(trailing: logoutButton)
        }
    }
}

/*
struct HomeTabMasterView_Previews: PreviewProvider {
    static var previews: some View {
        HomeTabMasterView()
    }
}
*/
