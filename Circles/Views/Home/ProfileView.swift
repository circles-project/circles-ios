//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  ProfileView.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/9/20.
//

import SwiftUI
import Matrix

struct ProfileView: View {
    @ObservedObject var user: Matrix.User
    
    @State var showImagePicker = false
    @State var showNameSheet = false
    @State var newAvatarImage = UIImage()
    
    var profile_picture: Image {
        return (user.avatar != nil)
            ? Image(uiImage: user.avatar!)
            : Image(systemName: "person.crop.square")
    }
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                profile_picture
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    //.clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .padding(5)
            }
            VStack(alignment: .leading) {
                HStack {
                    Text(user.displayName ?? "")
                        .font(.title)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                
                    Spacer()
                }
                .padding(.top)
                
                Text("\(user.userId)")
                    .font(.footnote)
                    .foregroundColor(Color.gray)
                    .lineLimit(1)
            
                if let status = user.statusMessage {
                    Text("\"\(status)\"")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(3)
                }
            }
        }
    }
}
