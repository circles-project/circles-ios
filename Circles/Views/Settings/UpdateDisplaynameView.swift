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
    @State var newDisplayname = ""
    
    var body: some View {
        VStack(alignment: .center, spacing: 100) {
            //Text("Update displayname for user \(user.userId.stringValue)")
            
            Spacer()
            
            TextField(session.displayName ?? "", text: $newDisplayname, prompt: Text("Your name"))
                .frame(width: 300, height: 40)

            AsyncButton(action: {
                try await session.setMyDisplayName(newDisplayname)
                self.presentation.wrappedValue.dismiss()
            }) {
                Text("Update")
            }
            
            Spacer()
        }
        .padding()
    }
}

/*
struct UpdateDisplaynameView_Previews: PreviewProvider {
    static var previews: some View {
        UpdateDisplaynameView()
    }
}
*/
