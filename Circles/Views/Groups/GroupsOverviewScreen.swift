//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  GroupsOverviewScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/3/20.
//

import SwiftUI
import Matrix
import MarkdownUI

enum GroupsSheetType: String {
    case create
    case edit
    case other
}
extension GroupsSheetType: Identifiable {
    var id: String { rawValue }
}

struct GroupsOverviewScreen: View {
    @ObservedObject var container: ContainerRoom<GroupRoom>
    @State var sheetType: GroupsSheetType?
    @AppStorage("showGroupsHelpText") var showHelpText = true
    
    let helpTextMarkdown = """
        # Groups
        
        Tip: A **group** is the best way to connect a bunch of people where everyone is connected to everyone else.
        
        Everyone in the group posts to the same timeline, and everyone in the group can see every post.
        
        For example, you might want to create a group for your book club, or your sports team, or your scout troop.
        
        If you want to share with lots of different people who don't all know each other, then you should invite those people to follow you in a **Circle** instead.
        """
    
    var body: some View {
        //let groups = container.groups
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        let invitations = container.session.invitations.values.filter { $0.type == ROOM_TYPE_GROUP }
                        ForEach(invitations) { invitation in
                            let user = container.session.getUser(userId: invitation.sender)
                            GroupInviteCard(room: invitation, user: user, container: container)
                        }
                        
                        ForEach(container.rooms) { room in
                            NavigationLink(destination: GroupTimelineScreen(room: room)) {
                                GroupOverviewRow(room: room)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.vertical, 2)
                            Divider()
                        }
                    }
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            self.sheetType = .create
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .padding()
                        }
                    }
                }
            }
            .padding(.top)
            .navigationBarTitle(Text("Groups"), displayMode: .inline)
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    Menu {
                        Button(action: {
                            self.sheetType = .create
                        }) {
                            Label("New Group", systemImage: "plus.circle")
                        }
                        Button(action: {
                            self.showHelpText = true
                        }) {
                            Label("Help", systemImage: "questionmark.circle")
                        }
                    }
                    label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                }
            }
            .sheet(item: $sheetType) { st in
                // Figure out what kind of sheet we need
                switch(st) {
                case .create:
                    GroupCreationSheet(groups: container)

                default:
                    Text("Coming soon")
                }
            }
            .sheet(isPresented: $showHelpText) {
                VStack {
                    Image("iStock-1176559812")
                        .resizable()
                        .scaledToFit()
                    
                    Markdown(helpTextMarkdown)
                    
                    Button(action: {self.showHelpText = false}) {
                        Label("Got it", systemImage: "hand.thumbsup.fill")
                            .padding()
                    }
                    .buttonStyle(.bordered)
                    .padding()
                }
                .padding()
            }
        }
    }
}

/*
struct ChannelsScreen_Previews: PreviewProvider {
    static var previews: some View {
        ChannelsScreen()
    }
}
*/
