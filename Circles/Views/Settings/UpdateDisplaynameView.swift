//
//  UpdateDisplaynameView.swift
//  Circles
//
//  Created by Charles Wright on 7/6/23.
//

import SwiftUI
import Matrix

struct UpdateDisplaynameView: View {
    @ObservedObject var session: Matrix.Session
    @Environment(\.presentationMode) var presentation
    //@ObservedObject var user: Matrix.User
    @State var newDisplayname: String
    
    enum FocusField {
        case displayname
    }
    @FocusState var focus: FocusField?
    
    init(session: Matrix.Session) {
        self.session = session
        self._newDisplayname = State(wrappedValue: session.me.displayName ?? "")
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 100) {
            //Text("Update displayname for user \(user.userId.stringValue)")
            Spacer()
            
            HStack {
                TextField(abbreviate(session.me.displayName, textIfEmpty: ""), text: $newDisplayname, prompt: Text("Your name"))
                    .textContentType(.name)
                    .textFieldStyle(.roundedBorder)
                    .focused($focus, equals: .displayname)
                    .frame(width: 300, height: 40)
                    .onAppear {
                        self.focus = .displayname
                    }
                
                Button(action: {
                    self.newDisplayname = ""
                }) {
                    Image(systemName: SystemImages.xmark.rawValue)
                        .foregroundColor(.gray)
                }
            }

            AsyncButton(action: {
                try await session.setMyDisplayName(newDisplayname)
                self.presentation.wrappedValue.dismiss()
            }) {
                Text("Update")
            }
            
            Spacer()
        }
        .navigationTitle("Change Name")
    }
}

/*
struct UpdateDisplaynameView_Previews: PreviewProvider {
    static var previews: some View {
        UpdateDisplaynameView()
    }
}
*/
