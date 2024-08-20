//
//  CommentCard.swift
//  Circles
//
//  Created by Charles Wright on 7/19/24.
//

import SwiftUI
import Matrix

struct CommentCard: View {
    @ObservedObject var message: Matrix.Message
    
    @ViewBuilder
    var contents: some View {
        
        let width: CGFloat = UIDevice.isPhone ? 300 : 500
        
        let latest = message.replacement ?? message
            
        if let content = latest.content as? Matrix.MessageContent {
            switch content.msgtype {
            case M_TEXT:
                if let textContent = content as? Matrix.mTextContent {
                    Text(textContent.body)
                        .font(
                            Font.custom("Inter", size: 12)
                                .weight(.medium)
                        )
                        .foregroundColor(Color.greyCool1100)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            case M_IMAGE:
                ImageContentView(message: latest)
            case M_VIDEO:
                VideoContentView(message: latest)
            case M_ROOM_ENCRYPTED:
                Text("Error: Failed to decrypt comment")
                    .font(
                        Font.custom("Inter", size: 12)
                            .weight(.medium)
                    )
                    .foregroundColor(Color.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            default:
                Text("Error: This version of Circles does not support this message type")
                    .font(
                        Font.custom("Inter", size: 12)
                            .weight(.medium)
                    )
                    .foregroundColor(Color.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            UserAvatarView(user: message.sender)
                .frame(width: 24, height: 24)
                .padding(.trailing, 8)
            
            VStack(alignment: .leading, spacing: 4) {
                UserNameView(user: message.sender)
                    .font(
                        Font.custom("Nunito", size: 14)
                            .weight(.heavy)
                    )
                    .foregroundColor(Color.greyCool1100)
                
                HStack(alignment: .top, spacing: 0) {
                    contents
                        .font(
                            Font.custom("Inter", size: 12)
                                .weight(.medium)
                        )
                        .foregroundColor(Color.greyCool1100)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                    
                    LikeButton(message: message)
                }
            }
            
        }
        .padding(.horizontal, 0)
        .padding(.top, 0)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

