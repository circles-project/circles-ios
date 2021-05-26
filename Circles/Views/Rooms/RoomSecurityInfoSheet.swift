//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  RoomSecurityInfoSheet.swift
//  Circles for iOS
//
//  Created by Charles Wright on 1/20/21.
//

import SwiftUI
import MatrixSDK

extension MXOlmInboundGroupSession: Identifiable {
    public var id: String {
        session.sessionIdentifier()
    }
}

struct RoomSecurityInfoSheet: View {
    @ObservedObject var room: MatrixRoom
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
    
    var body: some View {
        VStack {
            buttonBar
            
            Text(room.displayName ?? "(untitled)")
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
                            ForEach(room.joinedMembers) { user in
                                VStack(alignment: .leading) {
                                    //HStack {
                                    MessageAuthorHeader(user: user)

                                    //}
                                    //Divider()
                                    
                                    ForEach(user.devices) { device in
                                        DeviceInfoView(device: device)
                                            .padding(.leading)
                                    }
                                    
                                }
                                Divider()
                            }
                    //    }
                    //}
                }
                
                /*
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("MXCrypto Stuff")
                        .font(.title2)
                        .fontWeight(.bold)
                    VStack(alignment: .leading) {
                        Text("Algorithm: \(room.cryptoAlgorithm)")
                        
                        Text("Inbound Sessions:")
                        ForEach(room.inboundOlmSessions) { inbound in
                            HStack(alignment: .top) {
                                Image(systemName: "key.fill")
                                Image(systemName: "key")
                                    .rotationEffect(Angle(degrees: 180.0))
                                VStack(alignment: .leading) {
                                    Text("ID: \(inbound.id)")
                                        .lineLimit(1)
                                    Text("Sender: \(inbound.senderKey)")
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    .padding(.leading)
                }
                */

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
