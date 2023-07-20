//
//  InvitedCircleCard.swift
//  Circles
//
//  Created by Charles Wright on 7/19/23.
//

import SwiftUI
import Matrix

struct InvitedCircleCard: View {
    @ObservedObject var room: Matrix.InvitedRoom
    @ObservedObject var user: Matrix.User
    @ObservedObject var container: ContainerRoom<CircleSpace>
    
    @State var showAcceptSheet = false
    @State var selectedCircles: Set<CircleSpace> = []
    
    var body: some View {
        HStack(spacing: 1) {
            Image(uiImage: room.avatar ?? UIImage())
                .resizable()
                .clipShape(Circle())
                //.overlay(Circle().stroke(Color.primary, lineWidth: 2))
                .scaledToFit()
                .frame(width: 180, height: 180)
                .padding(-20)
            
            VStack(alignment: .leading) {
                Text(room.name ?? "(unnamed circle)")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("From:")
                HStack(alignment: .top) {
                    VStack {
                        if let name = user.displayName {
                            Text(name)
                            Text(user.userId.stringValue)
                                .font(.footnote)
                                .foregroundColor(.gray)
                        } else {
                            Text(user.userId.stringValue)
                        }
                    }
                }
                
                HStack {
                    AsyncButton(role: .destructive, action: {
                        try await room.reject()
                    }) {
                        Label("Reject", systemImage: "hand.thumbsdown.fill")
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        self.showAcceptSheet = true
                    }) {
                        Label("Accept", systemImage: "hand.thumbsup.fill")
                    }
                    .sheet(isPresented: $showAcceptSheet) {
                        ScrollView {
                            VStack {
                                Text("Where would you like to follow updates from \(room.name ?? "this friend's timeline")?")
                                
                                Text("You can choose one or more of your circles")
                                
                                CirclePicker(container: container, selected: $selectedCircles)
                                
                                AsyncButton(action: {
                                    try await room.accept()
                                    for circle in selectedCircles {
                                        try await circle.addChildRoom(room.roomId)
                                    }
                                }) {
                                    Label("Accept invite and follow", systemImage: "thumbsup")
                                }
                                .disabled(selectedCircles.isEmpty)
                            }
                            .padding()
                        }
                    }
                    
                    Spacer()
                    
                    NavigationLink(destination: InvitedCircleDetailView(room: room, user: user)) {
                        Label("Details", systemImage: "ellipsis.circle")
                            .labelStyle(.iconOnly)

                    }
                }
                .padding(.top, 5)
                .padding(.trailing, 10)
            }
        }
        .onAppear {
             room.updateAvatarImage()
        }
    }
}

/*
struct InvitedCircleCard_Previews: PreviewProvider {
    static var previews: some View {
        InvitedCircleCard()
    }
}
*/
