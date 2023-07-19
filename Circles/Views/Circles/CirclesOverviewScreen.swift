//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  CirclesOverviewScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/5/20.
//

import SwiftUI
import Matrix

enum CirclesOverviewSheetType: String {
    case create
}
extension CirclesOverviewSheetType: Identifiable {
    var id: String { rawValue }
}

struct CirclesOverviewScreen: View {
    @ObservedObject var container: ContainerRoom<CircleSpace>
    @State var selection: String = ""
    
    @State var invitations: [Matrix.InvitedRoom] = []
    @State private var sheetType: CirclesOverviewSheetType? = nil
    
    var toolbarMenu: some View {
        Menu {
            Button(action: {self.sheetType = .create}) {
                Label("New Circle", systemImage: "plus")
            }
        }
        label: {
            Label("More", systemImage: "ellipsis.circle")
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    
                    NavigationLink(destination: CircleInvitationsView(invitations: $invitations)) {
                        Text("You have \(invitations.count) pending invitation(s)")
                    }
                    
                    ForEach(container.rooms) { circle in
                        NavigationLink(destination: CircleTimelineScreen(space: circle)) {
                            CircleOverviewCard(space: circle)
                                //.padding(.top)
                        }
                        .onTapGesture {
                            print("DEBUGUI\tNavigationLink tapped for Circle \(circle.id)")
                        }
                        .buttonStyle(PlainButtonStyle())
                        Divider()
                    }
                }
                
            }
            .padding(.top)
            .navigationBarTitle("My Circles", displayMode: .inline)
            .onAppear {
                self.invitations = container.session.invitations.values.filter {
                    $0.type == ROOM_TYPE_CIRCLE
                }
            }
            .sheet(item: $sheetType) { st in
                switch(st) {
                case .create:
                    CircleCreationSheet(container: container)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    toolbarMenu
                }
            }
        }
    }
}

/*
struct CirclesOverviewScreen_Previews: PreviewProvider {
    static var previews: some View {
        CirclesOverviewScreen(store: LegacyStore())
    }
}
*/
