//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  DeviceInfoView.swift
//  Circles for iOS
//
//  Created by Charles Wright on 1/21/21.
//

import SwiftUI
import MatrixSDK

extension MXOlmSession: Identifiable {
    public var id: String {
        session.sessionIdentifier()
    }
}

struct OlmSessionView: View {
    var session: MXOlmSession
    
    var timestamp: some View {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        return Text(dateFormatter.string(from: Date(timeIntervalSince1970: session.lastReceivedMessageTs)) )
    }
    
    var body: some View {
        HStack {
            Image(systemName: "key.fill")
            Image(systemName: "key")
                .rotationEffect(Angle(degrees: 180.0))
                .offset(x: -10.0, y: 0.0)
            VStack {
                Text(session.session.sessionIdentifier())
                    .lineLimit(1)
                timestamp
            }
        }
    }
}

struct DeviceInfoView: View {
    @ObservedObject var device: MatrixDevice
    
    @State var showDetails = false
    @State var showRemoveDialog = false
    
    var icon: some View {
        HStack {
            if let name = device.displayName {
                if name.contains("iPhone") {
                    Image(systemName: "iphone")
                }
                else if name.contains("iPad") {
                    Image(systemName: "ipad")
                }
                else {
                    Image(systemName: "desktopcomputer")
                }
            }
            else {
                Image(systemName: "desktopcomputer")
            }
        }
    }
    
    var verificationStatus: some View {
        HStack {
            if device.isVerified {
                Image(systemName: "checkmark.shield")
                    .foregroundColor(Color.green)
                Text("Verified")
            } else if device.isBlocked {
                Image(systemName: "xmark.shield")
                    .foregroundColor(Color.red)
                Text("Blocked")
            } else {
                Image(systemName: "exclamationmark.shield")
                    .foregroundColor(Color.orange)
                Text("Unverified")
            }
        }
    }
    
    var verifyButtons: some View {
        HStack(alignment: .center, spacing: 20){
            
            if !device.isVerified {
                // Only offer to remove the device if it's really ours
                if device.userId == device.matrix.whoAmI() {
                    Button(action: { self.showRemoveDialog = true }) {
                        Label("Remove ", systemImage: "xmark.shield")
                    }
                    .padding(3)
                    .foregroundColor(Color.red)
                    .overlay(RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red))
                    .sheet(isPresented: $showRemoveDialog) {
                        DeviceRemovalSheet(device: device)
                    }
                } else {
                    Spacer()
                }
                
                Button(action: { device.verify() }) {
                    Label("Verify ", systemImage: "checkmark.shield")
                }
                .padding(3)
                .foregroundColor(Color.accentColor)
                .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor))
            }

        }
    }
    
    var details: some View {
        VStack(alignment: .leading) {
            if !showDetails {
                Button(action: {self.showDetails = true}) {
                    //Text("> Details")
                    HStack {
                        Image(systemName: "chevron.right")
                        Text("Show device details")
                    }
                }
            } else {
                Button(action: {self.showDetails = false}) {
                    HStack {
                        Image(systemName: "chevron.down")
                        Text("Hide device details")
                    }
                }
                VStack(alignment: .leading) {
                    HStack {
                        Text("Fingerprint: ")
                        Text(device.fingerprint ?? "(No device fingerprint)")
                            .lineLimit(1)
                    }
                    HStack {
                        Label("Public key", systemImage: "key.fill")
                        Text(device.key)
                            .lineLimit(1)
                    }
                    HStack {
                        if device.isCrossSigningVerified {
                            Image(systemName: "checkmark.shield")
                                .foregroundColor(Color.green)
                        }
                        else {
                            Image(systemName: "xmark.shield")
                                .foregroundColor(Color.red)
                        }
                        Text("Cross Signing")
                    }
                    HStack {
                        if device.isLocallyVerified {
                            Image(systemName: "checkmark.shield")
                                .foregroundColor(Color.green)
                        }
                        else {
                            Image(systemName: "xmark.shield")
                                .foregroundColor(Color.red)
                        }
                        Text("Local Verification")
                    }
                    VStack(alignment: .leading) {
                        Text("MXOlm Sessions")
                            .fontWeight(.bold)
                        let sessions = device.matrix.getOlmSessions(deviceKey: device.key)
                        ForEach(sessions, id: \.self) { session in
                            let olmSession = session.session
                            Text("Session: \(olmSession.sessionIdentifier())")
                        }
                    }
                }
                .padding(.leading)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                icon
                Text(device.displayName ?? "(Unnamed Device)")
                Text(device.id)
                    .fontWeight(.bold)
                Spacer()
                verificationStatus
            }
            VStack(alignment: .leading) {
                details

                verifyButtons
                
                /*
                Text("Olm Sessions")
                VStack(alignment: .leading) {
                    ForEach(device.sessions) { session in
                        OlmSessionView(session: session)
                        //Text("Foo")
                    }
                }
                .padding(.leading)
                */
                
            }
            .padding(.leading, 25)
        }
        .contextMenu {
            if let user = device.user {
                if user != device.matrix.me() {
                    Button(action: { user.verify() }) {
                        Label("Verify User", systemImage: "person.fill.checkmark")
                    }
                    /*  // Apparently this isn't a thing... :-(
                    Button(action: {user.unverify()}) {
                        Label("Unverify User", systemImage: "person.fill.xmark")
                    }
                    */
                }
            }
            Button(action: {device.verify()}) {
                Label("Verify Device", systemImage: "checkmark.shield")
            }
        }
    }
    
    /*
    var menu: some View {
        Menu {
            Button(action: {device.verify()}) {
                Label("Verify", systemImage: "checkmark.shield")
            }
        }
    }
    */
}

/*
struct DeviceInfoView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceInfoView()
    }
}
*/
