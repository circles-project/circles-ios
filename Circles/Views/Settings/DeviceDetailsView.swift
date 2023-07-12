//
//  DeviceDetailsView.swift
//  Circles
//
//  Created by Charles Wright on 7/12/23.
//

import SwiftUI
import Collections
import Matrix

struct DeviceDetailsView: View {
    var session: Matrix.Session
    var device: Matrix.CryptoDevice
    
    /*
    //var publicKeys: OrderedDictionary<String,String>
    
    init(session: Matrix.Session, device: Matrix.CryptoDevice) {
        self.session = session
        self.device = device
        self.publicKeys = .init(uniqueKeys: device.keys.keys, values: device.keys.values)
    }
    */
    
    var verifyButtons: some View {
        HStack(alignment: .center, spacing: 20){

            if device.userId == "\(session.creds.userId)" {
                    Button(action: {
                        //self.showRemoveDialog = true
                    }) {
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
    
    var oldbody: some View {
        VStack(alignment: .leading, spacing: 10) {
            //ScrollView {
                
                DeviceInfoView(session: session, device: device)
                    .padding()
                
                VStack(alignment: .leading) {
                    Text("Verification Status")
                        .font(.headline)
                        .padding(.vertical)
                    
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
                }
                
                VStack(alignment: .leading) {
                    Text("Public Keys")
                        .font(.headline)
                        .padding(.vertical)
                    
                    Grid(verticalSpacing: 10) {
                        ForEach(device.keys.sorted(by: >), id: \.key) { (keyId,publicKey) in
                            if let algo = keyId.split(separator: ":").first {
                                GridRow {
                                    Text(algo)
                                    Text(publicKey)
                                }
                            }
                        }
                    }
                }
            
            Spacer()
            //}
        }
        .padding(.leading)
        .navigationTitle(Text("Session Details"))
    }
    
    var verificationStatusDescription: String {
        if device.crossSigningTrusted || device.locallyTrusted {
            return "Verified"
        } else if device.isBlocked {
            return "Blocked"
        } else {
            return "Unverified"
        }
    }
    
    var keysSection: some View {
        Section("Public Keys") {
            
            ForEach(device.keys.sorted(by: >), id: \.key) { (keyId,publicKey) in
                
                 if let algo = keyId.split(separator: ":").first {
                     HStack {
                         Text(algo)
                         Spacer()
                         Text(publicKey)
                             .lineLimit(4)
                     }
                 }
                 
                //Text(keyId)
            }
        }
    }
    
    var body: some View {
        Form {
            
            Section("Basic Information") {
                Text("Name")
                    .badge(device.displayName ?? "(none)")
                Text("Session ID")
                    .badge(device.deviceId)
                Text("Status")
                    .badge(verificationStatusDescription)
            }
            
            Section("Verification Details") {
                Text("Cross-Signing Verified")
                    .badge(device.crossSigningTrusted ? "Yes" : "No")
                Text("Locally Verified")
                    .badge(device.locallyTrusted ? "Yes" : "No")
            }
            
            keysSection
        }
        .navigationTitle(Text("Session Details"))

    }
}

/*
struct DeviceDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceDetailsView()
    }
}
*/
