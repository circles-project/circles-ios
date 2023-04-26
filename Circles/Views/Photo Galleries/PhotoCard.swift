//
//  PhotoCard.swift
//  Circles
//
//  Created by Charles Wright on 4/13/23.
//

import Foundation
import SwiftUI

import Matrix

enum PhotoSheetType: String, Identifiable {
    case composer
    case reactions
    case reporting
    
    var id: String { rawValue }
}

struct PhotoCard: MessageView {
    
    let photoWidth: CGFloat = 800
    
    @ObservedObject var message: Matrix.Message
    var isLocalEcho: Bool
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var galleries: ContainerRoom<GalleryRoom>
    
    @State var sheetType: PhotoSheetType? = nil
    @State var showFullScreen: Bool = false
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
        }
    }

    var menuButton: some View {
        Menu {
            PhotoContextMenu(message: message,
                             sheetType: $sheetType,
                             showDetail: $showFullScreen)
        }
        label: {
            //Label("More", systemImage: "ellipsis.circle")
            Image(systemName: "ellipsis.circle")
                .resizable()
                .scaledToFit()
        }
    }
    
    
    @ViewBuilder
    var mainCard: some View {
        ZStack {
            if let img = message.thumbnail {
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
                
                GeometryReader { geometry in
                    let size: CGFloat = geometry.size.width > 500 ? 30 : 20
                    let pad: CGFloat = geometry.size.width > 500 ? 2 : 1
                    HStack {
                        Spacer()
                        
                        likeButton.frame(width: size, height: size)
                        
                        replyButton.frame(width: size, height: size)
                        
                        menuButton.frame(width: size, height: size)
                    }
                    .padding(pad)
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 10)
                    .padding(.horizontal, 2)
                }
                .frame(height: 35)
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
        .sheet(item: $sheetType) { st in
            switch st {
            case .composer:
                MessageComposerSheet(room: message.room, parentMessage: message, galleries: galleries)
            case .reactions:
                EmojiPicker(message: message)
            case .reporting:
                MessageReportingSheet(message: message)
            }
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            PhotoDetailView(message: message)
        }
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
