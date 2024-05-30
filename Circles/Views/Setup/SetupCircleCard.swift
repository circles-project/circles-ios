//  Copyright 2021 Kombucha Digital Privacy Systems LLC
//
//  SetupCircleCard.swift
//  Circles for iOS
//
//  Created by Charles Wright on 5/24/21.
//

import SwiftUI
import PhotosUI
import Matrix

struct SetupCircleCard: View {
    var matrix: Matrix.Session
    @ObservedObject var user: Matrix.User
    @ObservedObject var info: CircleSetupInfo
    
    //@State var showPicker = false
    @State var selectedItem: PhotosPickerItem?
    
    var body: some View {
        VStack(alignment: .leading) {
            
            HStack {
                
                ZStack {
                    Color.gray
                    
                    if let img = info.avatar {
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
                    Text(info.name)
                        .font(.title)
                        .fontWeight(.bold)
                    Text(self.user.displayName ?? "")
                }
                .padding(.leading)
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let img = UIImage(data: data)
                    {
                        await MainActor.run {
                            info.avatar = img
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
