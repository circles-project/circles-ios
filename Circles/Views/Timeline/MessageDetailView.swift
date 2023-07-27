//
//  MessageDetailView.swift
//  Circles
//
//  Created by Charles Wright on 4/13/23.
//

import Foundation
import SwiftUI

import Matrix

struct MessageDetailView: MessageView {
    var message: Matrix.Message
    var isLocalEcho: Bool
    var isThreaded: Bool
    
    init(message: Matrix.Message, isLocalEcho: Bool, isThreaded: Bool) {
        self.message = message
        self.isLocalEcho = isLocalEcho
        self.isThreaded = isThreaded
    }
    
    var body: some View {
        Text("Message detail view for \(message.eventId)")
    }
    
}
