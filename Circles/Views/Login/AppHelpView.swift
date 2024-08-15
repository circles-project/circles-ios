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
        # Our mission
                
        We wanted the social features of Facebook with the security and privacy of Signal, so we built Circles.
        
        Circles helps you stay connected with family, friends, and your community, all with the safety of end-to-end encryption.
        
        Share your moments, thoughts, and memories safely with those closest to you, without worrying about who else can see.
        
        Post to your timeline to share with all of your people in one place.
        
        Connect with neighbors, coworkers, and friends from every sphere of life.
        
        Circles doesn't track you and doesn't show you ads. We work for you, not for advertisers.
        Your data belongs to you. You can never be locked in to a single provider.
        
        All posts in Circles are encrypted using the same cryptography from state-of-the-art secure messaging tools like Signal and Matrix.
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
