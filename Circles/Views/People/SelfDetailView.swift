//
//  SelfDetailView.swift
//  Circles
//
//  Created by Charles Wright on 7/31/23.
//

import SwiftUI
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Matrix

struct SelfDetailView: View {
    @ObservedObject var matrix: Matrix.Session
    @ObservedObject var profile: ContainerRoom<Matrix.Room>
    @ObservedObject var circles: ContainerRoom<CircleSpace>
    
    @State var showPicker = false
    @State var showConfirmRemove = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {

                HStack {
                    Spacer()
                    VStack(alignment: .center) {
                        Image(uiImage: matrix.avatar ?? UIImage(systemName: "person.circle")!)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 240, height: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        Text(matrix.displayName ?? matrix.creds.userId.username)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(matrix.creds.userId.stringValue)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        if let url = URL(string: "https://\(CIRCLES_PRIMARY_DOMAIN)/profile/\(profile.roomId.stringValue)"),
                           let qr = qrCode(url: url)
                        {
                             Image(uiImage: qr)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 180, height: 180)
                                //.border(Color.red)
                         } else {
                             Text("🙁 Failed to generate QR code")
                         }
                    }
                    Spacer()
                }
                
                Divider()
                HStack(alignment: .bottom) {
                    Text("SHARED CIRCLES")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                    
                    Spacer()
                    
                    Button(action: {
                        self.showPicker = true
                    }) {
                        //Label("Add circle(s)", systemImage: "plus.circle")
                        Label("Add", systemImage: "plus.circle")
                    }
                    .padding(.leading)
                    .sheet(isPresented: $showPicker) {
                        SharedCirclesPicker(circles: circles, profile: profile)
                    }
                }
                if profile.rooms.isEmpty {
                    Text("No circles are visible to my connections.")
                        .padding()
                } else {
                    ForEach(profile.rooms) { room in
                        HStack {
                            RoomAvatar(room: room, avatarText: .roomInitials)
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())

                            Text(room.name ?? "??")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button(action: {
                                self.showConfirmRemove = true
                            }) {
                                Image(systemName: "trash")
                            }
                            .confirmationDialog("Stop sharing circle?", isPresented: $showConfirmRemove) {
                                AsyncButton(role: .destructive, action: {
                                    try await profile.removeChildRoom(room.roomId)
                                }) {
                                    Text("Stop sharing \(room.name ?? "this circle")")
                                }
                            }
                        }
                        .padding()
                    }
                }

            }
            .padding()

        }
        .navigationTitle(Text("Me"))
    }
}

/*
struct SelfDetailView_Previews: PreviewProvider {
    static var previews: some View {
        SelfDetailView()
    }
}
*/
