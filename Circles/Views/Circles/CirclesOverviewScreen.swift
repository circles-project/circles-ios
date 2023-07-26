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
    
    @State private var sheetType: CirclesOverviewSheetType? = nil
    
    @State var confirmDeleteCircle = false
    @State var circleToDelete: CircleSpace? = nil
    
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
    
    private func deleteCircle(circle: CircleSpace) async throws {
        print("Removing circle \(circle.name ?? "??") (\(circle.roomId))")
        try await container.removeChildRoom(circle.roomId)
        print("Leaving \(circle.rooms.count) rooms that were in the circle")
        for room in circle.rooms {
            print("Leaving timeline room \(room.name ?? "??") (\(room.roomId))")
            try await room.leave()
        }
        print("Leaving circle space \(circle.roomId)")
        try await circle.leave(reason: "Deleting circle Space room")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        
                        CircleInvitationsIndicator(session: container.session, container: container)
                        
                        ForEach(container.rooms) { circle in
                            NavigationLink(destination: CircleTimelineScreen(space: circle)) {
                                CircleOverviewCard(space: circle)
                                //.padding(.top)
                            }
                            .onTapGesture {
                                print("DEBUGUI\tNavigationLink tapped for Circle \(circle.id)")
                            }
                            .contextMenu {
                                Button(role: .destructive, action: {
                                    //try await deleteCircle(circle: circle)
                                    self.circleToDelete = circle
                                    self.confirmDeleteCircle = true
                                }) {
                                    Label("Delete", systemImage: "xmark.circle")
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
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
            .navigationBarTitle("Circles", displayMode: .inline)
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
            .confirmationDialog("Confirm deleting circle", isPresented: $confirmDeleteCircle, presenting: circleToDelete) { circle in
                AsyncButton(role: .destructive, action: {
                    try await deleteCircle(circle: circle)
                }) {
                    Label("Delete \"\(circle.name ?? "??")\"", systemImage: "xmark.bin")
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
