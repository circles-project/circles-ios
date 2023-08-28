//  Copyright 2021 Kombucha Digital Privacy Systems LLC
//
//  SetupCircleCard.swift
//  Circles for iOS
//
//  Created by Charles Wright on 5/24/21.
//

import SwiftUI
import PhotosUI

struct SetupCircleCard: View {
    var session: SetupSession
    var circleName: String
    var userDisplayName: String
    
    @Binding var avatar: UIImage?
    //@State var showPicker = false
    @State var selectedItem: PhotosPickerItem?
    
    var body: some View {
        VStack(alignment: .leading) {
            
            HStack {
                
                ZStack {
                    Color.gray
                    
                    if let img = self.avatar {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                    }
                }
                .clipShape(Circle())
                .frame(width: 120, height: 120, alignment: .center)
                .foregroundColor(.gray)
                .overlay(alignment: .bottomTrailing) {
                    PhotosPicker(selection: $selectedItem) {
                        Image(systemName: "pencil.circle.fill")
                            .symbolRenderingMode(.multicolor)
                            .font(.system(size: 30))
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.borderless)
                }

                VStack(alignment: .leading) {
                    Text(self.circleName)
                        .font(.title)
                        .fontWeight(.bold)
                    Text(self.userDisplayName)
                }
                .padding(.leading)
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let img = UIImage(data: data)
                    {
                        await MainActor.run {
                            self.avatar = img
                        }
                    }
                }
            }
        }
    }
}

/*
struct SetupCircleCard_Previews: PreviewProvider {
    static var previews: some View {
        SetupCircleCard()
    }
}
*/
