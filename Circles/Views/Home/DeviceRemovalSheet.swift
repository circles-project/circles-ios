//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  DeviceRemovalSheet.swift
//  Circles for iOS
//
//  Created by Charles Wright on 2/26/21.
//

import SwiftUI
import Matrix

struct DeviceRemovalSheet: View {
    var device: Matrix.CryptoDevice
    var session: Matrix.Session
    @Environment(\.presentationMode) var presentation

    @State var alertTitle: String = ""
    @State var alertMessage: String = ""
    @State var showAlert = false
        
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
                .font(.title)
                .fontWeight(.bold)
            HStack {
                ZStack {
                    icon
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60, alignment: .center)
                    
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50, alignment: .center)
                        .foregroundColor(.red)
                }
                VStack(alignment: .leading) {
                    Text("\(device.displayName ?? "(unknown)")")
                        .font(.title2)
                    Text(device.deviceId)
                        .fontWeight(.bold)
                }
            }
        }
    }
    
    var buttons: some View {
        VStack(alignment: .center, spacing: 30) {
            
            AsyncButton(action: {
                // First we have to get an MXAuthenticationSession
                // Then we can delete the device
                // We should probably just have the MatrixInterface handle all of this for us...
                
                // FIXME: This is going to give us a UIA session.  Need to handle UIA at a deeper layer.
                try await session.deleteDevice(deviceId: device.deviceId)
                
            }) {
                Label("Delete Session", systemImage: "xmark.shield")
                    .foregroundColor(Color.red)
            }
            .disabled(true) // FIXME: This is disabled until we figure out how to do UIA
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
    
    var body: some View {
        VStack {
            header
            
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
