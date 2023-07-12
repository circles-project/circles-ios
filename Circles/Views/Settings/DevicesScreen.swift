//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  DevicesScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 2/26/21.
//

import SwiftUI
import Matrix

struct DevicesScreen: View {
    @ObservedObject var session: Matrix.Session


    var currentDeviceView: some View {
        VStack(alignment: .leading, spacing: 15) {
            if let dev = session.device {
                let myDeviceModel = UIDevice.current.model
                let iconName = myDeviceModel.components(separatedBy: .whitespaces).first?.lowercased() ?? "desktopcomputer"
                Label("This \(myDeviceModel)", systemImage: iconName)
                    .font(.headline)

                DeviceInfoView(session: session, device: dev)
                    .padding(.leading)
                Divider()
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            
            ScrollView {

                //currentDeviceView

                ForEach(session.devices, id: \.deviceId) { device in
                    DeviceInfoView(session: session, device: device)
                }

                Spacer()
            }
            //.navigationBarTitle(Text("Login Sessions"))
        }
        .padding()
        .navigationTitle(Text("Active Login Sessions"))
    }
}

/*
struct DevicesScreen_Previews: PreviewProvider {
    static var previews: some View {
        DevicesScreen()
    }
}
*/
