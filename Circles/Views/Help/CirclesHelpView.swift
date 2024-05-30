//
//  CirclesHelpView.swift
//  Circles
//
//  Created by Charles Wright on 5/28/24.
//

import SwiftUI
import MarkdownUI

struct CirclesHelpView: View {
    
    let helpTextMarkdown = """
        # Circles
                
        Tip: A **circle** works like a secure, private version of Facebook or Twitter.  Everyone posts to their own timeline, and you see posts from all the timelines that you're following.
        
        A circle is a good way to share things with lots of people who don't all know each other, but they all know you.
        
        For example, think about all the aunts and uncles and cousins from the different sides of your family.
        Or, think about all of your friends across all of the places you've ever lived.

        If you want to connect a bunch of people who *do* all know each other, then it's better to create a **Group** instead.
        """
    
    var body: some View {
        VStack {
            HStack {
                Image("iStock-1356527683")
                    .resizable()
                    .scaledToFit()
                Image("iStock-1304744459")
                    .resizable()
                    .scaledToFit()
                Image("iStock-1225782571")
                    .resizable()
                    .scaledToFit()
                Image("iStock-640313068")
                    .resizable()
                    .scaledToFit()
            }
            
            Markdown(helpTextMarkdown)
        }
        .padding()
    }
}

#Preview {
    CirclesHelpView()
}
