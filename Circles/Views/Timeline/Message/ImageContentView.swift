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
    var alignment: HorizontalAlignment
    //var width: CGFloat
    
    var body: some View {
        if let imageContent = message.content as? Matrix.mImageContent {
            //Spacer()
            
            VStack(alignment: alignment) {

                HStack {
                    if alignment == .center {
                        Spacer()
                    }
                    
                    MessageMediaThumbnail(message: message)
                    
                    if alignment == .center {
                        Spacer()
                    }
                }
                
                if let caption = imageContent.caption {
                    HStack {
                        let markdown = MarkdownContent(caption)
                        Markdown(markdown)
                        
                        if alignment == .center {
                            Spacer()
                        }
                    }
                }

            }
            //Spacer()
        } else {
            EmptyView()
        }
    }
}

