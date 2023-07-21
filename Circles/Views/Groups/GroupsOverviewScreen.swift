//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  GroupsOverviewScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/3/20.
//

import SwiftUI
import Matrix

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
