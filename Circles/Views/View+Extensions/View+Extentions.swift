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
    var aspectRatio: ContentMode = .fit
    
    var body: some View {
        if let uiImage {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: aspectRatio)
        } else if let systemName {
            Image(systemName: systemName)
                .resizable()
                .aspectRatio(contentMode: aspectRatio)
        } else if let name {
            Image(name)
                .resizable()
                .aspectRatio(contentMode: aspectRatio)
        } else {
            Image(systemName: SystemImages.xmarkIcloudFill.rawValue)
                .resizable()
                .aspectRatio(contentMode: aspectRatio)
        }
    }
}
