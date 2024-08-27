//
//  AppHelpView.swift
//  Circles
//
//  Created by Dmytro Ryshchuk on 8/15/24.
//

import SwiftUI
import MarkdownUI

struct AppHelpView: View {
    
    let helpTextMarkdown = """
        Circle is a secure social app where you can store and share your best moments with your loved ones without worrying that your data will be sold to anyone.
        """
    
    var body: some View {
        ScrollView {
            HStack {
                BasicImage(name: "iStock-1356527683")
                BasicImage(name: "iStock-1304744459")
                BasicImage(name: "iStock-1225782571")
                BasicImage(name: "iStock-640313068")
            }
            
            Markdown(helpTextMarkdown)
        }
        .scrollIndicators(.hidden)
        .padding()
    }
}
