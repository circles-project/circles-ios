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
        if let name = device.displayName {
            if name.contains("iPhone") {
                return Image(systemName: "iphone")
            }
            else if name.contains("iPad") {
                return Image(systemName: "ipad")
            }
            else {
                return Image(systemName: "desktopcomputer")
            }
        }
        else {
            return Image(systemName: "desktopcomputer")
        }
    }
    
    var verificationStatus: some View {
        HStack {
            if device.crossSigningTrusted || device.locallyTrusted {
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

            if device.userId == "\(session.creds.userId)" {
                    Button(action: { self.showRemoveDialog = true }) {
                        Label("Remove ", systemImage: "xmark.shield")
                    }
                    .padding(3)
                    .foregroundColor(Color.red)
                    .overlay(RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red))
                    /*
                    .sheet(isPresented: $showRemoveDialog) {
                        DeviceRemovalSheet(device: device, session: session)
                    }
                    */
            } else {
                Spacer()
            }
                
            AsyncButton(action: {
                // FIXME: Figure out what to do here
                //device.verify()
            }) {
                Label("Verify ", systemImage: "checkmark.shield")
                    .padding(3)
                    .foregroundColor(Color.accentColor)
                    .overlay(RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.accentColor))
            }
            .disabled(true)

            //}

        }
    }
    
    var details: some View {
        VStack(alignment: .leading) {
            if !showDetails {
                Button(action: {self.showDetails = true}) {
                    //Text("> Details")
                    HStack {
                        Image(systemName: "chevron.right")
                        Text("Show session details")
                    }
                }
            } else {
                Button(action: {self.showDetails = false}) {
                    HStack {
                        Image(systemName: "chevron.down")
                        Text("Hide session details")
                    }
                }
                VStack(alignment: .leading) {
                    /*
                    HStack {
                        Text("Fingerprint: ")
                        Text(device.fingerprint ?? "(No session fingerprint)")
                            .lineLimit(1)
                    }
                    HStack {
                        Label("Public key", systemImage: "key.fill")
                        Text(device.key)
                            .lineLimit(1)
                    }
                    */
                    HStack {
                        if device.crossSigningTrusted {
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
                        if device.locallyTrusted {
                            Image(systemName: "checkmark.shield")
                                .foregroundColor(Color.green)
                        }
                        else {
                            Image(systemName: "xmark.shield")
                                .foregroundColor(Color.red)
                        }
                        Text("Local Verification")
                    }
                    /*
                    VStack(alignment: .leading) {
                        Text("MXOlm Sessions")
                            .fontWeight(.bold)
                        let sessions = device.matrix.getOlmSessions(deviceKey: device.key)
                        ForEach(sessions, id: \.self) { session in
                            let olmSession = session.session
                            Text("Session: \(olmSession.sessionIdentifier())")
                        }
                    }
                    */
                }
                .padding(.leading)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40, alignment: .center)
                VStack(alignment: .leading) {
                    Text(device.displayName ?? "(Unnamed Session)")
                    Text(device.deviceId)
                        .fontWeight(.bold)
                }
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
        .contextMenu(menuItems: {
            /*
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
            */
            Button(action: {
                // FIXME: Re-implement all this junk...
                //device.verify()
            }) {
                Label("Verify Session", systemImage: "checkmark.shield")
            }.disabled(true)
        })
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
