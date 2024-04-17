//
//  VideoDetailView.swift
//  Circles
//
//  Created by Charles Wright on 4/17/24.
//

import SwiftUI
import Matrix

struct VideoDetailView: View {
    @ObservedObject var message: Matrix.Message
    
    var body: some View {
        VideoContentView(message: message, autoplay: true, fullscreen: true)
    }
}

