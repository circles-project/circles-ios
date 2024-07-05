//
//  MessageView.swift
//  Circles
//
//  Created by Charles Wright on 4/13/23.
//

import Foundation
import SwiftUI
import Matrix

protocol MessageView: View {
    var message: Matrix.Message { get }
    var isLocalEcho: Bool { get }
    var isThreaded: Bool { get }
    var isMessageFromReply: Bool { get }
    
    init(message: Matrix.Message, isLocalEcho: Bool, isThreaded: Bool, isMessageFromReply: Bool)
}
