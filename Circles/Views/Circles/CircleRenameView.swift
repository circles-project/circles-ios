//
//  CircleRenameView.swift
//  Circles
//
//  Created by Charles Wright on 4/15/24.
//

import SwiftUI
import Matrix

struct CircleRenameView: View {
    @ObservedObject var space: CircleSpace
    @Environment(\.presentationMode) var presentation

    @State var newName: String
    
    enum FocusField {
        case circleName
    }
    @FocusState var focus: FocusField?
    
    init(space: CircleSpace) {
        self.space = space
        self._newName = State(wrappedValue: space.name ?? "")
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 100) {
            Spacer()

            HStack {
                TextField(space.name ?? "", text: $newName, prompt: Text("New name"))
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
                try await space.setName(newName: newName)
                try await space.wall?.setName(newName: newName)
                self.presentation.wrappedValue.dismiss()
            }) {
                Text("Update")
            }
            
            Spacer()
        }
        .navigationTitle("Rename \(space.name ?? space.wall?.name ?? "")")
    }
}
