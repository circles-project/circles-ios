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
    @Environment(\.presentationMode) var presentation
    
    @State var lastSeenIP: String?
    @State var lastSeenTS: Date?
    
    @State var isConfirmingDelete: Bool = false
    
    private var formatter: DateFormatter
    
    //var publicKeys: OrderedDictionary<String,String>
    
    init(session: Matrix.Session, device: Matrix.CryptoDevice) {
        self.session = session
        self.device = device
        self.formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
    }
    
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
                             .textSelection(.enabled)
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
                    .textSelection(.enabled)
                Text("Status")
                    .badge(verificationStatusDescription)
            }
            
            if device.userId == session.creds.userId.stringValue {
                Section("Last Seen Online") {
                    if let ts = lastSeenTS {
                        Text("Date & Time")
                            .badge("\(self.formatter.string(from: ts))")
                    }
                    if let ip = lastSeenIP {
                        Text("IP Address")
                            .badge(ip)
                    }
                }
                .onAppear() {
                    let _ = Task {
                        if let basicDevice = try? await session.getDevice(deviceId: device.deviceId) {
                            await MainActor.run {
                                self.lastSeenTS = basicDevice.lastSeenTs
                                self.lastSeenIP = basicDevice.lastSeenIp
                            }
                        }
                    }
                }
            } else {
                Section("First Seen Online") {
                    let ts = Date(timeIntervalSince1970: Double(device.firstTimeSeenTs)/1000.0)
                    Text("Date & Time")
                        .badge("\(self.formatter.string(from: ts))")
                }
            }
            
            Section("Verification Details") {
                Text("Cross-Signing Verified")
                    .badge(device.crossSigningTrusted ? "Yes" : "No")
                Text("Locally Verified")
                    .badge(device.locallyTrusted ? "Yes" : "No")
            }
            
            keysSection
            
            if device.userId == session.creds.userId.stringValue {
                
                if device.deviceId == session.creds.deviceId {
                    // This is our current device.  To delete it is to log out
                } else {
                    
                    Section("Delete") {
                        Button(role: .destructive, action: {
                            isConfirmingDelete = true
                        }) {
                            Text("Delete Session")
                        }
                        .confirmationDialog(
                            "Are you sure you want to delete this session?",
                            isPresented: $isConfirmingDelete,
                            presenting: device.displayName ?? device.deviceId,
                            actions: { deviceName in
                                AsyncButton(role: .destructive, action: {
                                    do {
                                        try await session.deleteDevice(deviceId: device.deviceId) { (_,_) in
                                            print("Successfully deleted device \(device.deviceId)")
                                            self.presentation.wrappedValue.dismiss()
                                        }
                                    } catch {
                                        print("Failed to delete device \(device.deviceId)")
                                    }
                                }) {
                                    Text("Delete session \(deviceName)")
                                }
                            },
                            message: { deviceName in
                                
                            })
                        
                    }
                }
            }
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
