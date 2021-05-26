//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  InvitationAcceptSheet.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/9/20.
//

import SwiftUI

struct InvitationAcceptSheet: View {
    //@EnvironmentObject var store: KSStore
    @ObservedObject var store: KSStore
    @ObservedObject var room: MatrixRoom
    @Environment(\.presentationMode) var presentation
    @State var circles: Set<SocialCircle> = []
    
    var body: some View {
        VStack {
            
            Text("You are now following:")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            HStack {
                ZStack {
                    Circle()
                        .frame(width: 100, height: 100)
                        .foregroundColor(Color.gray)
                    
                    Image(uiImage: room.avatarImage ?? UIImage())
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        //.clipped()
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                        .shadow(radius: 5)
                        .padding(5)
                }
                VStack {
                    let inviterId = room.whoInvitedMe()!
                    let inviter = store.getUser(userId: inviterId)!
                    //MessageAuthorHeader(user: inviter)
                    Text("\(inviter.displayName ?? inviter.id):")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(room.displayName ?? room.id)
                        .font(.title2)
                        .fontWeight(.bold)
                        //.foregroundColor(Color.white)
                        //.shadow(color: .black, radius: 3)
                }
            }
            
            //Text("You have been invited to follow the channel \"\(room.displayName ?? room.id)\"")
            
            Spacer()
                        
            Text("You can also connect this Circle to see updates in one of your Circles.")
                //.padding(.horizontal)
            CirclePicker(store: store, selected: $circles)
        
            Spacer()
            
            
            Button(action: {
                let dgroup = DispatchGroup()
                var errors: Error? = nil
                //let tags = [ROOM_TAG_FOLLOWING]
                
                for circle in circles {
                    print("Tagging room \(room.displayName ?? room.id) with tag: \(circle.tag)")
                    dgroup.enter()
                    room.addTag(tag: circle.tag) { response in
                        switch(response) {
                        case .failure(let error):
                            let msg = "Failed to tag room: \(error)"
                            print(msg)
                            errors = errors ?? KSError(message: msg)
                        case .success:
                            print("Successfully tagged room \(room.displayName ?? room.id) for Circle \(circle.name)")
                        }
                        dgroup.leave()
                    }
                }
                
                // Once we've added it to our Circles, we can take it out of the list
                store.newestRooms.removeAll(where: { $0 == room })
                
                dgroup.notify(queue: .main) {
                    if errors == nil {
                        // Yay we're done
                        self.presentation.wrappedValue.dismiss()
                    }
                }
            }) {
                Image(systemName: "checkmark")
                Text("Done")
            }
            .padding()
            
            /* // No canceling anymore -- In the new model, we already accepted the invitation
            Button(action: {
                    self.presentation.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
                Text("Cancel")
            }
            .padding()
            */
        }
        .padding()
    }
}
