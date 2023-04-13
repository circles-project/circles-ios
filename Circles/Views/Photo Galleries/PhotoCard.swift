//
//  PhotoCard.swift
//  Circles
//
//  Created by Charles Wright on 4/13/23.
//

import Foundation
import SwiftUI

import Matrix

struct PhotoCard: MessageView {
    
    let photoWidth: CGFloat = 800
    let buttonSize: CGFloat = 20
    
    @ObservedObject var message: Matrix.Message
    var isLocalEcho: Bool
    @Environment(\.colorScheme) var colorScheme
    @State var sheetType: MessageSheetType? = nil
    private var formatter: DateFormatter

    init(message: Matrix.Message, isLocalEcho: Bool) {
        self.message = message
        self.isLocalEcho = isLocalEcho
        self.formatter = DateFormatter()
        self.formatter.dateStyle = .medium
        self.formatter.timeStyle = .medium
    }
    
    var likeButton: some View {
        Button(action: {
            self.sheetType = .reactions
        }) {
            //Label("Like", systemImage: "heart")
            Image(systemName: "heart")
                .resizable()
                .scaledToFit()
                .frame(width: buttonSize, height: buttonSize)
        }
    }

    var replyButton: some View {
        Button(action: {
            self.sheetType = .composer
        }) {
            //Label("Reply", systemImage: "bubble.right")
            Image(systemName: "bubble.right")
                .resizable()
                .scaledToFit()
                .frame(width: buttonSize, height: buttonSize)
        }
    }

    var menuButton: some View {
        Menu {
        MessageContextMenu(message: message,
                           sheetType: $sheetType)
        }
        label: {
            //Label("More", systemImage: "ellipsis.circle")
            Image(systemName: "ellipsis.circle")
                .resizable()
                .scaledToFit()
                .frame(width: buttonSize, height: buttonSize)
        }
    }
    
    @ViewBuilder
    var footer: some View {
        HStack(spacing: 10) {
            /*
            let user = message.sender
            let img = user.avatar ?? UIImage(systemName: "person")!
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .frame(width: 40, height: 40)
                //.padding(.leading, 10)
            
            Spacer()
            
            Text("\(message.timestamp, formatter: formatter)")
                .font(.callout)
            */
            
            Spacer()
            
            likeButton
            replyButton
            menuButton
        }
        .padding(2)
        .foregroundColor(.white)
        .shadow(color: .black, radius: 10)
        .padding(.horizontal, 2)
        //.background(RoundedRectangle(cornerRadius: 4).opacity(0.3))
    }
    
    
    @ViewBuilder
    var mainCard: some View {
        ZStack {
            if let img = message.thumbnail ?? message.thumbhashImage ?? message.blurhashImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            }
            else {
                ZStack {
                    Image(uiImage: UIImage())
                        .resizable()
                        .scaledToFill()
                    ProgressView()
                }
            }
            
            VStack {
                Spacer()
                footer
            }
            .frame(maxWidth: photoWidth)

        }
        .frame(maxWidth: photoWidth)
        //.padding(.all, 3.0)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .foregroundColor(colorScheme == .dark ? .black : .white)
                .shadow(color: .gray, radius: 2, x: 0, y: 1)
        )
        .onAppear {
            Task {
                try await message.fetchThumbnail()
            }
        }
    }
    
    var body: some View {
        mainCard
    }
    
}
