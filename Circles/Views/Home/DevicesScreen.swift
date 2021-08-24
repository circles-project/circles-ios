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

    var currentDeviceView: some View {
        VStack(alignment: .leading, spacing: 15) {
            let myDevice = user.matrix.getCurrentDevice()
            if let dev = myDevice {
                    let myDeviceModel = UIDevice.current.model
                    let iconName = myDeviceModel.components(separatedBy: .whitespaces).first?.lowercased() ?? "desktopcomputer"
                    Label("This \(myDeviceModel)", systemImage: iconName)
                        .font(.headline)

                    DeviceInfoView(device: dev)
                        .padding(.leading)
                    Divider()
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text("Active Login Sessions")
                    .font(.title2)
                    .padding()

                currentDeviceView

                let myDevice = user.matrix.getCurrentDevice()

                let unverifiedDevices = user.devices.filter { !$0.isVerified }
                if !unverifiedDevices.isEmpty {
                    Label("Other Unverified Sessions", systemImage: "display.trianglebadge.exclamationmark")
                        .font(.headline)
                    ForEach(unverifiedDevices) { device in
                    //ForEach(user.devices) { device in
                        if myDevice == nil || device != myDevice {
                            DeviceInfoView(device: device)
                        }
                        //Text(device.displayName ?? "(unnamed device)")
                    }
                    .padding(.leading)
                    Divider()
                }

                let verifiedDevices = user.devices.filter { $0.isVerified }
                if !verifiedDevices.isEmpty {
                    Label("Other Verified Sessions", systemImage: "desktopcomputer")
                        .font(.headline)
                    ForEach(verifiedDevices) { device in
                        if myDevice == nil || device != myDevice {
                            DeviceInfoView(device: device)
                        }
                    }
                    .padding(.leading)
                }

                Spacer()
            }
            //.navigationBarTitle(Text("Login Sessions"))
            .padding()
        }
    }
}

/*
struct DevicesScreen_Previews: PreviewProvider {
    static var previews: some View {
        DevicesScreen()
    }
}
*/
