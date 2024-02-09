//
//  UpdateStatusMessageView.swift
//  Circles
//
//  Created by Charles Wright on 7/6/23.
//

import SwiftUI
import Matrix

struct UpdateStatusMessageView: View {
    @ObservedObject var session: Matrix.Session
    @Environment(\.presentationMode) var presentation
    //@ObservedObject var user: Matrix.User
    @State var newStatus = ""
    
    var body: some View {
        VStack(alignment: .center, spacing: 100) {
            //Text("Update displayname for user \(user.userId.stringValue)")
            
            Spacer()
            
            TextField(session.me.statusMessage ?? "", text: $newStatus, prompt: Text("New status message"))
                .frame(width: 300, height: 40)
            
            AsyncButton(action: {
                try await session.setMyStatus(message: newStatus)
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
struct UpdateStatusMessageView_Previews: PreviewProvider {
    static var previews: some View {
        UpdateStatusMessageView()
    }
}
*/
