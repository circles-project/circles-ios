//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  DevicesScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 2/26/21.
//

import SwiftUI

struct DevicesScreen: View {
    @ObservedObject var user: MatrixUser
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            let unverifiedDevices = user.devices.filter { !$0.isVerified }
            if !unverifiedDevices.isEmpty {
                Label("Unverified Devices", systemImage: "display.trianglebadge.exclamationmark")
                    .font(.headline)
                ForEach(unverifiedDevices) { device in
                //ForEach(user.devices) { device in
                    DeviceInfoView(device: device)
                    //Text(device.displayName ?? "(unnamed device)")
                }
                .padding(.leading)
                Divider()
            }

            let verifiedDevices = user.devices.filter { $0.isVerified }
            if !verifiedDevices.isEmpty {
                Label("My Verified Devices", systemImage: "desktopcomputer")
                    .font(.headline)
                ForEach(verifiedDevices) { device in
                    DeviceInfoView(device: device)
                }
                .padding(.leading)
            }
            
            Spacer()
        }
        .navigationBarTitle(Text("My Devices"))
        .padding()
    }
}

/*
struct DevicesScreen_Previews: PreviewProvider {
    static var previews: some View {
        DevicesScreen()
    }
}
*/
