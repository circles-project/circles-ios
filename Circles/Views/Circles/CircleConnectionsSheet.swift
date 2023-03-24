//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  CircleConnectionsSheet.swift
//  Circles for iOS
//
//  Created by Charles Wright on 12/18/20.
//

import SwiftUI
import Matrix

struct CircleConnectionsSheet: View {
    @ObservedObject var space: CircleSpace
    @Environment(\.presentationMode) var presentation
    @State var roomsToLeave: [Matrix.Room] = []
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
    
    func leaveRooms() async throws {
        for room in roomsToLeave {
            try await space.leaveChildRoom(room.roomId)
        }
    }
    
    var confirmationString: String {
        let roomNames = roomsToLeave.map { room in
            "\(room.creator): \(room.name ?? "(untitled)")"
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
                ForEach(space.rooms) { room in
                    let user = space.session.getUser(userId: room.creator)
                    //PersonsCircleRow(room: room)
                    VStack {
                        Text("User: \(room.creator.description)")
                        Text("Room: \(room.name ?? room.roomId.description)")
                    }
                    .padding()
                }
                .onDelete { indexes in
                    for index in indexes {
                        roomsToLeave.append(space.rooms[index])
                    }
                    self.showConfirmLeave = true
                }
            }
            // FIXME: Show a confirmation dialog
            
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
