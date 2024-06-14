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
        
    @State private var sheetType: CirclesOverviewSheetType? = nil
    
    @State var confirmDeleteCircle = false
    @State var circleToDelete: CircleSpace? = nil
    
    @State var showChangelog = false
    @AppStorage("changelogLastUpdate") var changelogLastUpdate: TimeInterval = 0
    @AppStorage("showCirclesHelpText") var showHelpText = false
    var changelogFile = ChangelogFile()
    
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
        print("Leaving \(circle.rooms.count) rooms that were in the circle")
        for room in circle.rooms.values {
            print("Leaving timeline room \(room.name ?? "??") (\(room.roomId))")
            try await room.leave()
        }
        print("Leaving circle space \(circle.roomId)")
        try await container.leaveChild(circle.roomId, reason: "Deleting circle")
    }
    
    @ViewBuilder
    var baseLayer: some View {
        let invitations = container.session.invitations.values.filter { $0.type == ROOM_TYPE_CIRCLE }

        if !container.rooms.isEmpty || !invitations.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                            
                if invitations.count > 0 {
                    CircleInvitationsIndicator(session: container.session, container: container)
                }
                
                // Sort intro _reverse_ chronological order
                let circles = container.rooms.values.sorted(by: { $0.timestamp > $1.timestamp })
                                
                List(selection: $selected) {
                    ForEach(circles) { circle in
                        NavigationLink(value: circle.roomId) {
                            CircleOverviewCard(space: circle)
                                .contentShape(Rectangle())
                                //.padding(.top)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive, action: {
                                //try await deleteCircle(circle: circle)
                                self.circleToDelete = circle
                                self.confirmDeleteCircle = true
                            }) {
                                Label("Delete", systemImage: "xmark.circle")
                            }
                        }
                         
                    }
                }
                .listStyle(.plain)
                .accentColor(.secondaryBackground)
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
            VStack {
                CirclesHelpView()

                Button(action: {self.showHelpText = false}) {
                    Label("Got it", systemImage: "hand.thumbsup.fill")
                        .padding()
                }
                .buttonStyle(BigBlueButtonStyle())
                Spacer()
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            master
                .onAppear {
                    changelogFile.checkLastUpdates(for: .lastUpdates, showChangelog: &showChangelog, changelogLastUpdate: &changelogLastUpdate)
                }
                .sheet(isPresented: $showChangelog) {
                    ChangelogSheet(content: changelogFile.loadMarkdown(named: .lastUpdates), showChangelog: $showChangelog)
                }
                .refreshable {
                    await MainActor.run {
                        container.objectWillChange.send()
                    }
                }
        } detail: {
            if let roomId = selected,
               let space = container.rooms[roomId]
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
