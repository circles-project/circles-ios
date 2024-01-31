//
//  RoomCryptoInfoView.swift
//  Circles
//
//  Created by Charles Wright on 1/27/24.
//

import SwiftUI
import Matrix
import MatrixSDKCrypto

struct RoomCryptoInfoView: View {
    @ObservedObject var room: Matrix.Room
    
    var body: some View {
        Form {
            ForEach(room.joinedMembers) { userId in
                let user = room.session.getUser(userId: userId)
                if !user.devices.isEmpty {
                    Section(user.displayName ?? user.userId.stringValue) {
                        ForEach(user.devices) { device in
                            NavigationLink(destination: DeviceDetailsView(session: room.session, device: device)) {
                                DeviceInfoView(session: room.session, device: device)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .navigationTitle("Crypto Info")
    }
}
