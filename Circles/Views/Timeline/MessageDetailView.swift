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
    
    init(message: Matrix.Message, isLocalEcho: Bool) {
        self.message = message
        self.isLocalEcho = isLocalEcho
    }
    
    var body: some View {
        Text("Message detail view for \(message.eventId)")
    }
    
}
