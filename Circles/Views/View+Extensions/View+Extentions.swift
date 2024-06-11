//
//  View+Extentions.swift
//  Circles
//
//  Created by Dmytro Ryshchuk on 6/10/24.
//

import SwiftUI

struct BasicImage: View {
    var uiImage: UIImage? = nil
    var systemName: String? = nil
    var name: String? = nil
    
    var body: some View {
        if let uiImage {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
        } else if let systemName {
            Image(systemName: systemName)
                .resizable()
                .scaledToFit()
        } else if let name {
            Image(name)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "xmark.icloud.fill")
                .resizable()
                .scaledToFit()
        }
    }
}
