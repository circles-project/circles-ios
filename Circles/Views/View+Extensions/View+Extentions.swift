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
    var aspectRation: ContentMode = .fit
    
    var body: some View {
        if let uiImage {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: aspectRation)
        } else if let systemName {
            Image(systemName: systemName)
                .resizable()
                .aspectRatio(contentMode: aspectRation)
        } else if let name {
            Image(name)
                .resizable()
                .aspectRatio(contentMode: aspectRation)
        } else {
            Image(systemName: "xmark.icloud.fill")
                .resizable()
                .aspectRatio(contentMode: aspectRation)
        }
    }
}
