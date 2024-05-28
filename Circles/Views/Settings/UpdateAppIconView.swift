//
//  UpdateAppIconView.swift
//  Circles
//
//  Created by Dmytro Ryshchuk on 5/28/24.
//

import SwiftUI

struct AppIconModel {
    let name: String
    let appIconName: String
    let description: String
}

struct UpdateAppIconView: View {
    @AppStorage("appIcon") var appIcon = ""
    
    private let availableIcons: [AppIconModel] = [
        .init(name: "AppIcon0", appIconName: "RegularIcon", description: "Standart"),
        .init(name: "AppIcon1", appIconName: "PremiumIcon1", description: "Vibrant"),
        .init(name: "AppIcon2", appIconName: "PremiumIcon2", description: "Hypnotic"),
        .init(name: "AppIcon3", appIconName: "PremiumIcon3", description: "Colorful")
    ]
    
    private let columns: [GridItem] = [
        .init(.flexible(), spacing: 1),
        .init(.flexible(), spacing: 1),
        .init(.flexible(), spacing: 1),
        .init(.flexible(), spacing: 1)
    ]
    
    private func changeAppIcon(to iconName: String) {
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error = error {
                print("Error setting alternate icon \(error.localizedDescription)")
            }
        }
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 1) {
            ForEach(availableIcons, id: \.name) { icon in
                Button(action: {
                    appIcon = icon.name
                    changeAppIcon(to: icon.appIconName)
                }, label: {
                    VStack {
                        Text(icon.description)
                        Image(icon.name)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                })
                .buttonStyle(.plain)
            }
        }
    }
}
