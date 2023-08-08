//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  CirclesOverviewScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/5/20.
//

import SwiftUI
import MarkdownUI
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
    
    let helpTextMarkdown = """
        # Circles
                
        Tip: A **circle** works like Facebook or Twitter.  Everyone posts to their own timeline, and you see posts from all the timelines that you're following.
        
        A circle is a good way to share things with lots of people who don't all know each other, like all the aunts and uncles and cousins from both sides of your family.
        Or with all your friends from all the places you've ever lived, or with all your former coworkers across multiple jobs.

        If you want to connect a bunch of people who *do* all know each other, it's better to create a **Group** instead.
        """
    
    @AppStorage("showCirclesHelpText") var showHelpText = true
    
    var toolbarMenu: some View {
        Menu {
            Button(action: {self.sheetType = .create}) {
                Label("New Circle", systemImage: "plus")
            }
            Button(action: {self.showHelpText = true }) {
                Label("Help", systemImage: "questionmark.circle")
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
        NavigationView {
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
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    toolbarMenu
                }
            }
            .sheet(item: $sheetType) { st in
                switch(st) {
                case .create:
                    CircleCreationSheet(container: container)
                }
            }
            .confirmationDialog("Confirm deleting circle", isPresented: $confirmDeleteCircle, presenting: circleToDelete) { circle in
                AsyncButton(role: .destructive, action: {
                    try await deleteCircle(circle: circle)
                }) {
                    Label("Delete \"\(circle.name ?? "??")\"", systemImage: "xmark.bin")
                }
            }
            .sheet(isPresented: $showHelpText) {
                VStack {
                    HStack {
                        Image("iStock-1356527683")
                            .resizable()
                            .scaledToFit()
                        Image("iStock-1304744459")
                            .resizable()
                            .scaledToFit()
                        Image("iStock-1225782571")
                            .resizable()
                            .scaledToFit()
                        Image("iStock-640313068")
                            .resizable()
                            .scaledToFit()
                    }
                    Markdown(helpTextMarkdown)
                    
                    Button(action: {self.showHelpText = false}) {
                        Label("Got it", systemImage: "hand.thumbsup.fill")
                            .padding()
                    }
                    .buttonStyle(.bordered)
                    .padding()
                }
                .padding()
                //.frame(minWidth: 300, minHeight: 300)
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
