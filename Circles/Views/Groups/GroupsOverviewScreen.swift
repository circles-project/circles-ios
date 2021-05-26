//
//  ChannelsScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/3/20.
//

import SwiftUI

enum GroupsSheetType: String {
    case create
    case edit
    case other
}
extension GroupsSheetType: Identifiable {
    var id: String { rawValue }
}

struct GroupsOverviewScreen: View {
    @ObservedObject var container: GroupsContainer
    @State var sheetType: GroupsSheetType?
    
    var body: some View {
        //let groups = container.groups
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(container.groups) { group in
                        NavigationLink(destination: GroupTimelineScreen(group: group)) {
                            GroupOverviewRow(room: group.room)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 2)
                        Divider()
                    }
                }
            }
            .padding(.top)
            .navigationBarTitle(Text("My Groups"), displayMode: .inline)
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
