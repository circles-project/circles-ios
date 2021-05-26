//
//  PersonHeaderRow.swift
//  Circles for iOS
//
//  Created by Charles Wright on 12/3/20.
//

import SwiftUI

struct PersonHeaderRow: View {
    @ObservedObject var user: MatrixUser
    
    var image: Image {
        guard let img = user.avatarImage else {
            return Image(systemName: "person.crop.square")
        }
        
        return Image(uiImage: img)
    }
    
    var displayName: String {
        guard let name = user.displayName else {
            return user.id.components(separatedBy: ":").first ?? user.id
        }
        return name
    }
    
    var status: String {
        guard let msg = user.statusMsg else {
            return ""
        }
        return "\"" + msg + "\""
    }
    
    var body: some View {
        HStack(alignment: .top) {
            image
                .resizable()
                .scaledToFill()
                .frame(width: 70, height:70)
                //.clipped()
                //.clipShape(Circle())
                .clipShape(RoundedRectangle(cornerRadius: 7))

            
            VStack(alignment: .leading) {
                Text(displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(1)
                
                Text(user.id)
                    .font(.subheadline)
                    .foregroundColor(Color.gray)
                    .lineLimit(1)
                
                Text(status)
                    .font(.headline)
                    .fontWeight(.regular)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .padding(.trailing, 2)
        }
        .padding([.leading, .top], 5)
    }
}

/*
struct PersonHeaderRow_Previews: PreviewProvider {
    static var previews: some View {
        PersonHeaderRow()
    }
}
*/
