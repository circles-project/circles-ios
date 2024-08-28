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

    var body: some View {
        let markdown = MarkdownContent(text)
        Markdown(markdown)
            .textSelection(.enabled)
    }
}
