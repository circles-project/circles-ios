//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
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
    @State var alertTitle: String = ""
    @State var alertMessage: String = ""
    @State var showAlert = false
    
    @State var pending = false
    
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

    
    var header: some View {
        VStack {
            Text("Removing Session")
                .font(.title2)
                .fontWeight(.bold)
            HStack {
                icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60, alignment: .center)
                VStack(alignment: .leading) {
                    Text("\(device.displayName ?? "(unknown)")")
                        .font(.title2)
                    Text(device.id)
                        .fontWeight(.bold)
                }
            }
        }
    }
    
    var buttons: some View {
        VStack(alignment: .center, spacing: 30) {
            
            Button(action: {
                self.pending = true
                // First we have to get an MXAuthenticationSession
                // Then we can delete the device
                // We should probably just have the MatrixInterface handle all of this for us...
                device.matrix.deleteDevice(deviceId: device.id, password: password) { response in
                    if response.isSuccess {
                        print("Successfully deleted device \(device.id)")
                        self.presentation.wrappedValue.dismiss()
                    }
                    else {
                        print("Failed to remove session \(device.id)")
                        self.password = ""
                        self.alertTitle = "Failed to remove session"
                        self.alertMessage = "Double-check the password and try again"
                        self.showAlert = true
                    }
                    self.pending = false
                }
            }) {
                Label("Delete Session", systemImage: "xmark.shield")
                    .foregroundColor(Color.red)
            }
            .disabled(password.isEmpty || pending)
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertTitle),
                      message: Text(alertMessage),
                      dismissButton: .default(Text("OK")))
            }
            
            Button(action: {self.presentation.wrappedValue.dismiss()}) {
                Label("Cancel", systemImage: "xmark")
            }

        }
    }
    
    var passwordForm: some View {
        VStack {
            Text("Removing a login session requires authentication.")
            //Spacer()
            Text("Please enter your password to proceed:")
            SecureFieldWithEye(label: "Password", text: $password)
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
            
            //Spacer()
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
