//  Copyright 2021 Kombucha Digital Privacy Systems LLC
//
//  SetupCircleCard.swift
//  Circles for iOS
//
//  Created by Charles Wright on 5/24/21.
//

import SwiftUI

struct SetupCircleCard: View {
    var matrix: MatrixInterface
    var circleName: String
    var userDisplayName: String
    
    @Binding var avatar: UIImage?
    @State var showPicker = false
    
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
                        Button(action: {
                            self.showPicker = true
                        }) {
                            Label("Change", systemImage: "photo")
                                .font(.subheadline)
                        }
                        .sheet(isPresented: $showPicker) {
                            ImagePicker(selectedImage: self.$avatar)
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
                        
                        Button(action: {
                            self.showPicker = true
                        }) {
                            Text("Choose a cover photo")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 3.0, x: 2.0, y: 2.0)
                                .padding(10)
                        }
                        .sheet(isPresented: $showPicker) {
                            ImagePicker(selectedImage: self.$avatar)
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
