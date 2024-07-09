//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  RoomSecurityInfoSheet.swift
//  Circles for iOS
//
//  Created by Charles Wright on 1/20/21.
//

import SwiftUI
import Matrix


struct RoomSecurityInfoSheet: View {
    @ObservedObject var room: Matrix.Room
    @Environment(\.presentationMode) var presentation

    var buttonBar: some View {
        HStack {
            Spacer()
            
            Button(action: {
                    self.presentation.wrappedValue.dismiss()
            }) {
                Text("Done")
                    .font(.subheadline)
            }
        }
    }

    var olmStuff: some View {
        VStack(alignment: .leading) {
            Text("Olm Stuff")
                .font(.title2)
                .fontWeight(.bold)
            VStack(alignment: .leading, spacing: 10) {
                Text("Algorithm: \(room.encryptionParams?.algorithm.rawValue ?? "None")")

                Text("Inbound Sessions:")
                    .fontWeight(.bold)
                /*
                ForEach(room.inboundOlmSessions) { inbound in
                    HStack(alignment: .top) {
                        Image(systemName: SystemImages.keyFill.rawValue)
                        //Image(systemName: SystemImages.key.rawValue)
                        //    .rotationEffect(Angle(degrees: 180.0))
                        VStack(alignment: .leading) {
                            Text("ID: \(inbound.id)")
                                .lineLimit(1)
                            Text("Sender: \(inbound.senderKey)")
                                .lineLimit(1)
                        }
                    }
                }
                */

                Text("Outbound Sessions:")
                    .fontWeight(.bold)
                /*
                ForEach(room.outboundOlmSessions, id: \.sessionId) { session in
                    HStack(alignment: .top) {
                        Image(systemName: SystemImages.keyFill.rawValue)
                        Image(systemName: SystemImages.key.rawValue)
                            .rotationEffect(Angle(degrees: 180.0))
                        VStack(alignment: .leading) {
                            Text("ID: \(session.sessionId)")
                                .lineLimit(1)
                            Text("Key: \(session.sessionKey)")
                                .lineLimit(1)
                        }
                    }
                }
                */
            }
            .padding(.leading)
        }
    }

    
    
    var body: some View {
        VStack {
            buttonBar
            
            Text(room.name ?? "(untitled)")
                .font(.title)
                .fontWeight(.bold)
            
            Divider()
            
            ScrollView {
            
                VStack(alignment: .leading) {
                    Text("Users")
                        .font(.title2)
                        .fontWeight(.bold)
                    //VStack {
                    //    List {
                            ForEach(room.joinedMembers) { userId in
                                let user = room.session.getUser(userId: userId)
                                VStack(alignment: .leading) {
                                    //HStack {
                                    MessageAuthorHeader(user: user)

                                    //}
                                    //Divider()
                                    
                                    ForEach(user.devices, id: \.deviceId) { device in
                                        DeviceInfoView(session: room.session, device: device)
                                            .padding(.leading)
                                    }
                                    
                                }
                                Divider()
                            }
                    //    }
                    //}
                }
                

                Spacer()
                

                olmStuff

            }
            
            Spacer()
            
        }
        .padding()
    }
}

/*
struct RoomSecurityInfoSheet_Previews: PreviewProvider {
    static var previews: some View {
        RoomSecurityInfoSheet()
    }
}
*/
