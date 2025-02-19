//
//  CircleRenameView.swift
//  Circles
//
//  Created by Charles Wright on 4/15/24.
//

import SwiftUI
import Matrix

struct CircleRenameView: View {
    @ObservedObject var room: Matrix.Room
    @Environment(\.presentationMode) var presentation

    @State var newName: String
    
    enum FocusField {
        case circleName
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
                    .focused($focus, equals: .circleName)
                    .frame(width: 300, height: 40)
                    .onAppear {
                        self.focus = .circleName
                    }
                Button(action: {
                    self.newName = ""
                }) {
                    Image(systemName: SystemImages.xmark.rawValue)
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
        .navigationTitle("Rename \(room.name ?? "circle")")
    }
}
