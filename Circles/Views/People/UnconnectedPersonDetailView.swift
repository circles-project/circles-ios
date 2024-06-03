//
//  UnconnectedPersonDetailView.swift
//  Circles
//
//  Created by Charles Wright on 7/31/23.
//

import SwiftUI
import Matrix

struct UnconnectedPersonDetailView: View {
    @ObservedObject var user: Matrix.User
    @ObservedObject var myProfileRoom: ProfileSpace

    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showAlert = false
    
    var status: some View {
        HStack {
            Text("Latest Status:")
                .fontWeight(.bold)
            Text(user.statusMessage ?? "(no status message)")
        }
        .font(.subheadline)
    }
    
    var header: some View {
        HStack {
            Spacer()
            
            VStack {
                UserAvatarView(user: user)
                    .frame(width: 160, height: 160, alignment: .center)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                //.padding(.leading)
                Text(user.displayName ?? "")
                    .font(.title)
                    .fontWeight(.bold)
                Text(user.userId.stringValue)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                NavigationLink(destination: InviteToFollowMeView(user: user)) {
                    Label("Invite to follow me", systemImage: "circle.hexagonpath")
                }
            }
            
            Spacer()
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {

                header

                //status
                
                Divider()
            
                MutualFriendsSection(user: user, profile: myProfileRoom)
            
            }
        }
        .padding()
        .onAppear {
            // Hit the Homeserver to make sure we have the latest
            //user.matrix.getDisplayName(userId: user.id) { _ in }
            user.refreshProfile()
        }
        .navigationTitle(Text(user.displayName ?? user.userId.username))
    }
}

/*
struct UnconnectedPersonDetailView_Previews: PreviewProvider {
    static var previews: some View {
        UnconnectedPersonDetailView()
    }
}
*/
