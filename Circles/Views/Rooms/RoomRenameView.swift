//
//  RoomRenameView.swift
//  Circles
//
//  Created by Charles Wright on 4/15/24.
//

import SwiftUI
import Matrix

struct RoomRenameView: View {
    @ObservedObject var room: Matrix.Room
    @Environment(\.presentationMode) var presentation

    @State var newName: String
    
    enum FocusField {
        case roomName
    }
    @FocusState var focus: FocusField?
    
    init(room: Matrix.Room) {
        self.room = room
        self._newName = State(wrappedValue: room.name ?? "")
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 100) {
            Spacer()

            HStack {
                TextField(room.name ?? "", text: $newName, prompt: Text("New name"))
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.words)
                    .focused($focus, equals: .roomName)
                    .frame(width: 300, height: 40)
                    .onAppear {
                        self.focus = .roomName
                    }
                Button(action: {
                    self.newName = ""
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                }
            }
            
            AsyncButton(action: {
                try await room.setName(newName: newName)
                self.presentation.wrappedValue.dismiss()
            }) {
                Text("Update")
            }
            
            Spacer()
        }
        .navigationTitle("Rename \(room.name ?? "")")
    }
}
