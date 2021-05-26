//
//  DeviceRemovalSheet.swift
//  Circles for iOS
//
//  Created by Charles Wright on 2/26/21.
//

import SwiftUI
import MatrixSDK

struct DeviceRemovalSheet: View {
    @ObservedObject var device: MatrixDevice
    @Environment(\.presentationMode) var presentation

    @State var password: String = ""
    
    var header: some View {
        VStack {
            Text("Removing Device")
                .font(.title2)
                .fontWeight(.bold)
            Text("\(device.displayName ?? "(unknown)") (\(device.id))")
                .font(.title2)
                .fontWeight(.bold)
        }
    }
    
    var buttons: some View {
        HStack(alignment: .center, spacing: 20) {
            Button(action: {self.presentation.wrappedValue.dismiss()}) {
                Label("Cancel", systemImage: "xmark")
            }
            Button(action: {
                // First we have to get an MXAuthenticationSession
                // Then we can delete the device
                // We should probably just have the MatrixInterface handle all of this for us...
                device.matrix.deleteDevice(deviceId: device.id, password: password) { response in
                    if response.isSuccess {
                        print("Successfully deleted device \(device.id)")
                        self.presentation.wrappedValue.dismiss()
                    }
                    else {
                        print("Failed to delete device \(device.id)")
                    }
                }
            }) {
                Label("Delete Device", systemImage: "xmark.shield")
                    .foregroundColor(Color.red)
            }
            .disabled(password.isEmpty)
        }
    }
    
    var passwordForm: some View {
        VStack {
            Text("Removing a device requires authentication.")
            //Spacer()
            Text("Please enter your password to proceed:")
            SecureField("Password", text: $password)
                .frame(width: 250, height: 40)
        }
    }
    
    var body: some View {
        VStack {
            header
            
            Spacer()

            passwordForm
            
            Spacer()

            buttons
            
            Spacer()
        }
        .padding()
    }
}

/*
struct DeviceRemovalSheet_Previews: PreviewProvider {
    static var previews: some View {
        DeviceRemovalSheet()
    }
}
*/
