//
//  TextContentView.swift
//  Circles
//
//  Created by Charles Wright on 8/20/24.
//

import SwiftUI
import Matrix
import MarkdownUI

struct TextContentView: View {
    var text: String
    var markdown: MarkdownContent
    
    init(_ text: String) {
        self.text = text
        self.markdown = MarkdownContent(text)
    }
    
    var body: some View {
        Markdown(markdown)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
