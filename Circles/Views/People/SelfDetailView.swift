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
                Text("VISIBLE CIRCLES")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.top, 20)
                if profile.rooms.isEmpty {
                    Text("No circles are visible to my connections.")
                        .padding()
                    Button(action: {}) {
                        Label("Add circle(s)", systemImage: "plus.circle")
                    }
                    .padding(.leading)
                } else {
                    ForEach(profile.rooms) { room in
                        HStack {
                            RoomAvatar(room: room, avatarText: .roomInitials)
                                .frame(width: 80, height: 80)
                            Text(room.name ?? "??")
                                .font(.title3)
                            Spacer()
                        }
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
