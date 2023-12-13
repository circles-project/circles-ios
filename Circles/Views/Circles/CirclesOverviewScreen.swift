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
    case scanQr
}
extension CirclesOverviewSheetType: Identifiable {
    var id: String { rawValue }
}

struct CirclesOverviewScreen: View {
    @ObservedObject var container: ContainerRoom<CircleSpace>
    //@State var selectedSpace: CircleSpace?
    @Binding var selected: RoomId?
    
    @State var circleInvitations: [Matrix.InvitedRoom] = []
    
    @State private var sheetType: CirclesOverviewSheetType? = nil
    
    @State var confirmDeleteCircle = false
    @State var circleToDelete: CircleSpace? = nil
    
    let helpTextMarkdown = """
        # Circles
                
        Tip: A **circle** works like a secure, private version of Facebook or Twitter.  Everyone posts to their own timeline, and you see posts from all the timelines that you're following.
        
        A circle is a good way to share things with lots of people who don't all know each other, but they all know you.
        
        For example, think about all the aunts and uncles and cousins from the different sides of your family.
        Or, think about all of your friends across all of the places you've ever lived.

        If you want to connect a bunch of people who *do* all know each other, then it's better to create a **Group** instead.
        """
    
    @AppStorage("showCirclesHelpText") var showHelpText = true
    
    var toolbarMenu: some View {
        Menu {
            Button(action: {self.sheetType = .create}) {
                Label("New Circle", systemImage: "plus")
            }
            Button(action: {self.sheetType = .scanQr}) {
                Label("Scan QR code", systemImage: "qrcode")
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
    
    @ViewBuilder
    var baseLayer: some View {
        
        if !container.rooms.isEmpty || !circleInvitations.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                            
                if circleInvitations.count > 0 {
                    CircleInvitationsIndicator(session: container.session, container: container)
                }
                
                // Sort intro _reverse_ chronological order
                let circles = container.rooms.sorted(by: { $0.timestamp > $1.timestamp })
                                
                List(selection: $selected) {
                    ForEach(circles) { circle in
                        NavigationLink(value: circle.roomId) {
                            CircleOverviewCard(space: circle)
                                .contentShape(Rectangle())
                                //.padding(.top)
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
                         
                    }
                }
                .listStyle(.plain)
            }
        }
        else {
            Text("Create a circle to get started")
        }
    }
    
    @ViewBuilder
    var overlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                Menu {
                    Button(action: {
                        self.sheetType = .create
                    }) {
                        Label("Create new circle", systemImage: "plus.circle")
                    }
                    
                    Button(action: {
                        self.sheetType = .scanQr
                    }) {
                        Label("Scan QR code", systemImage: "qrcode")
                    }
                }
                label: {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .padding()
                }
            }
        }
    }
    
    @ViewBuilder
    var help: some View {
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
    }
    
    var master: some View {
        ZStack {
            baseLayer
            
            overlay
        }
        .padding(.top)
        .navigationBarTitle("Circles", displayMode: .inline)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                toolbarMenu
            }
        }
        .onAppear {
            circleInvitations = container.session.invitations.values.filter { $0.type == ROOM_TYPE_CIRCLE }
        }
        .sheet(item: $sheetType) { st in
            switch(st) {
            case .create:
                CircleCreationSheet(container: container)
            case .scanQr:
                ScanQrCodeAndKnockSheet(session: container.session)
            }
        }
        .confirmationDialog("Confirm deleting circle", isPresented: $confirmDeleteCircle, presenting: circleToDelete) { circle in
            AsyncButton(role: .destructive, action: {
                try await deleteCircle(circle: circle)
            }) {
                Label("Delete circle \"\(circle.name ?? "??")\"", systemImage: "xmark.bin")
            }
        }
        .sheet(isPresented: $showHelpText) {
            help
        }
    }
    
    var body: some View {
        NavigationSplitView {
            master
        } detail: {
            if let roomId = selected,
               let space = container.rooms.first(where: { $0.roomId == roomId })
            {
                CircleTimelineView(space: space)
            } else {
                Text("Select a circle to see the most recent posts")
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
