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
        
        A circle is a good way to share things with lots of people who don't all know each other, but who all know you.
        
        For example, you may have lots of aunts and uncles and cousins from the different sides of your family.
        Or, you might have several friends from many different places where you've lived.

        If you want to connect a bunch of people who *do* all know each other, then it's better to create a **Group** instead.
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

#Preview {
    CirclesHelpView()
}
