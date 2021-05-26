//
//  ChannelHeader.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/18/20.
//

import SwiftUI

struct GroupHeader<Content: View>: View {
    @ObservedObject var room: MatrixRoom
    let content: Content
    
    init(room: MatrixRoom, @ViewBuilder content: () -> Content) {
        self.room = room
        self.content = content()
    }
    
    var title: some View {
        Text(room.displayName ?? room.id)
            .font(.title)
            .fontWeight(.bold)
    }
    
    var subtitle: some View {
        Text(room.topic ?? "")
            .font(.headline)
            .foregroundColor(Color.gray)
    }
    
    var avatar: some View {
        Image(uiImage: room.avatarImage ?? UIImage())
            .resizable()
            .scaledToFill()
            .frame(maxWidth: 150, minHeight: 120, maxHeight: 120)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 3)
            .padding(5)
    }
    
    var body: some View {
        HStack {

            avatar
            
            VStack(alignment: .center) {
                title
                    .multilineTextAlignment(.center)
                
                subtitle
                    .multilineTextAlignment(.center)
                    .padding(.bottom)
                
                content
            }
            
            Spacer()
        }
        .padding(.top, 5)
    }
}

/*
struct GroupHeader_Previews: PreviewProvider {
    static var previews: some View {
        GroupHeader()
    }
}
*/
