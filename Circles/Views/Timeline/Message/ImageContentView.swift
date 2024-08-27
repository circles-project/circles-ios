//
//  ImageContentView.swift
//  Circles
//
//  Created by Charles Wright on 8/20/24.
//

import SwiftUI
import Matrix
import MarkdownUI

struct ImageContentView: View {
    @ObservedObject var message: Matrix.Message
    //var width: CGFloat
    
    var body: some View {
        HStack {
            if let imageContent = message.content as? Matrix.mImageContent {
                //Spacer()
                VStack(alignment: .center) {
                    HStack {
                        Spacer()
                        MessageMediaThumbnail(message: message)
                        Spacer()
                    }
                    
                    HStack {
                        if let caption = imageContent.caption {
                            let markdown = MarkdownContent(caption)
                            Markdown(markdown)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(Font.custom("Inter", size: 14))

                            
                            //Spacer()
                        }
                    }
                }
                //Spacer()
            } else {
                EmptyView()
            }
        }
    }
}

