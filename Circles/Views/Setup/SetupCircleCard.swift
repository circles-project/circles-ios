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
                if let img = self.avatar {
                    VStack {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .clipShape(Circle())
                            .frame(width: 120, height: 120, alignment: .center)
                            //.padding()

                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Label("Change", systemImage: "photo")
                                .font(.subheadline)
                        }
                    }
                }
                else {
                    ZStack {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFill()
                            .overlay(Color.gray.opacity(0.50))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .frame(width: 120, height: 120, alignment: .center)
                            .foregroundColor(.gray)
                            .padding()
                        
                        PhotosPicker(selection: $selectedItem) {
                            Text("Choose a cover photo")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 3.0, x: 2.0, y: 2.0)
                                .padding(10)
                        }
                    }
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
