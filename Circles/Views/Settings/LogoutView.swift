//
//  LogoutView.swift
//  Circles
//
//  Created by Charles Wright on 6/15/23.
//

import SwiftUI
import Matrix

struct LogoutView: View {
    @ObservedObject var store: CirclesStore
    //@ObservedObject var user: Matrix.User
    
    var body: some View {
        AsyncButton(action:{
            try await store.logout()
        }) {
            Label("Log Out", systemImage: "power")
        }
    }
}

/*
struct LogoutView_Previews: PreviewProvider {
    static var previews: some View {
        LogoutView()
    }
}
*/
