//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  DeviceInfoView.swift
//  Circles for iOS
//
//  Created by Charles Wright on 1/21/21.
//

import SwiftUI
import Matrix


struct DeviceInfoView: View {
    var session: Matrix.Session
    var device: Matrix.CryptoDevice
    
    @State var showDetails = false
    @State var showRemoveDialog = false
    
    var icon: Image {
        if device.userId == session.creds.userId.stringValue && device.deviceId == session.device?.deviceId {
            // This is us
            let model = UIDevice().model
            if model.contains("iPhone") {
                return Image(systemName: SystemImages.iphone.rawValue)
            }
            else if model.contains("iPad") {
                return Image(systemName: SystemImages.ipad.rawValue)
            }
            else {
                return Image(systemName: SystemImages.desktopcomputer.rawValue)
            }
        }
        if let name = device.displayName {
            if name.contains("iPhone") {
                return Image(systemName: SystemImages.iphone.rawValue)
            }
            else if name.contains("iPad") {
                return Image(systemName: SystemImages.ipad.rawValue)
            }
            else {
                return Image(systemName: SystemImages.desktopcomputer.rawValue)
            }
        }
        else {
            return Image(systemName: SystemImages.desktopcomputer.rawValue)
        }
    }
    
    var verificationStatus: some View {
        HStack {
            if device.crossSigningTrusted || device.locallyTrusted {
                Image(systemName: SystemImages.checkmarkShield.rawValue)
                    .foregroundColor(Color.green)
                Text("Verified")
            } else if device.isBlocked {
                Image(systemName: SystemImages.xmarkShield.rawValue)
                    .foregroundColor(Color.red)
                Text("Blocked")
            } else {
                Image(systemName: SystemImages.exclamationmarkShield.rawValue)
                    .foregroundColor(Color.orange)
                Text("Unverified")
            }
        }
    }
    
    var name: String {
        if device.userId == session.creds.userId.stringValue && device.deviceId == session.device?.deviceId {
            return "This \(UIDevice().model)"
        }
        if let displayName = device.displayName {
            return displayName
        }
        return "(Unnamed Session)"
    }
    
    var body: some View {
        //VStack(alignment: .leading) {
            HStack {
                icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40, alignment: .center)
                VStack(alignment: .leading) {
                    Text(name)
                    Text(device.deviceId)
                        .fontWeight(.bold)
                }
                Spacer()
                verificationStatus
            }
        //}
        //.padding()
        .contextMenu(menuItems: {
            
            if device.userId == session.creds.userId.stringValue {
                if device.deviceId != session.creds.deviceId {
                    // Can't remove our own session, but we can remove others
                    AsyncButton(role: .destructive, action: {
                        //throw CirclesError("Not implemented")
                    }) {
                        Label("Remove Session", systemImage: SystemImages.xmarkCircle.rawValue)
                    }
                }
            } else {
                AsyncButton(action: {
                    //throw CirclesError("Not implemented")
                }) {
                    Label("Verify User", systemImage: "person.fill.checkmark")
                }
                .disabled(true)
            }
            
            Button(action: {
                //throw CirclesError("Not implemented")
            }) {
                Label("Show Details", systemImage: "info.circle")
            }
            
            if !device.crossSigningTrusted && !device.locallyTrusted {
                Button(action: {
                    // FIXME: Re-implement all this junk...
                    //device.verify()
                }) {
                    Label("Verify Session", systemImage: SystemImages.checkmarkShield.rawValue)
                }.disabled(true)
            }
        })
    }
}

/*
struct DeviceInfoView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceInfoView()
    }
}
*/
