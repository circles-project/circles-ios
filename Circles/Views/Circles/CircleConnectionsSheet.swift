//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  CircleConnectionsSheet.swift
//  Circles for iOS
//
//  Created by Charles Wright on 12/18/20.
//

import SwiftUI

struct CircleConnectionsSheet: View {
    @ObservedObject var circle: SocialCircle
    @Environment(\.presentationMode) var presentation
    @State var roomsToLeave: Set<MatrixRoom> = []
    @State var showConfirmLeave = false
    
    var buttonBar: some View {
        HStack {
            Button(action: {
                self.presentation.wrappedValue.dismiss()
            }) {
                Text("Cancel")
            }
            Spacer()
            Button(action: {
                self.presentation.wrappedValue.dismiss()
            }) {
                Text("Done")
                    .fontWeight(.bold)
            }
        }
    }
    
    func unfollow() async throws {
        for room in roomsToLeave {
            try await circle.unfollow(room: room)
        }
    }
    
    func leaveRooms() {
        let dgroup = DispatchGroup()
        
        for room in roomsToLeave {
            dgroup.enter()
            room.matrix.leaveRoom(roomId: room.id) { success in
                if success {
                    roomsToLeave.remove(room)
                }
                dgroup.leave()
            }
        }
        
        dgroup.notify(queue: .main) {
            // Nothing else to do
        }
    }
    
    var confirmationString: String {
        let roomNames = roomsToLeave.map { room in
            "\(room.owners.first?.displayName ?? "(unknown)"): \(room.displayName ?? "(untitled)")"
        }
            .sorted {
                $0 < $1
            }
        return "Do you really want to remove \(roomNames.joined(separator: ", "))?"
    }
    
    var body: some View {
        VStack() {
            buttonBar
            
            Text("People I am following")
                .font(.title2)
                .fontWeight(.bold)
            
            List {
                let rooms = circle.stream.rooms
                
                ForEach(rooms) { room in
                    PersonsCircleRow(room: room, showOwners: true)
                        .actionSheet(isPresented: $showConfirmLeave) {
                            ActionSheet(title: Text("Confirm Removal"),
                                        message: Text(confirmationString),
                                        buttons: [
                                            .destructive(Text("Remove from this circle, but do not unfollow"), action: {
                                                // Remove the selected Room(s) from the given circle
                                                
                                                _ = Task { try await circle.unfollow(room: room) }
                                            }),
                                            .destructive(Text("Unfollow completely (remove from all circles)"), action: { _ = Task { try await unfollow() } }),
                                            .cancel() {
                                                roomsToLeave.removeAll()
                                            }
                                        ]
                            )
                        }
                }
                .onDelete { indexes in
                    for index in indexes {
                        roomsToLeave.insert(rooms[index])
                    }
                    self.showConfirmLeave = true
                }
            }
            
            Spacer()

        }
        .padding(5)
    }
}

/*
struct CircleConnectionsSheet_Previews: PreviewProvider {
    static var previews: some View {
        CircleConnectionsSheet()
    }
}
*/
