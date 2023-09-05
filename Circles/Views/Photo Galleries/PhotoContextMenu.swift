//  Copyright 2023 FUTO Holdings Inc
//
//  PhotoContextMenu.swift
//  Circles
//
//  Created by Charles Wright on 4/18/23.
//

import Foundation
import SwiftUI

import Matrix

struct PhotoContextMenu: View {
    @ObservedObject var message: Matrix.Message
    @Binding var sheetType: PhotoSheetType?
    @Binding var showDetail: Bool
    
    @EnvironmentObject var matrix: Matrix.Session
    
    var body: some View {
        
        if let content = message.content as? Matrix.MessageContent,
            content.msgtype == M_IMAGE
        {
            Button(action: {
                // FIXME: TODO
            }) {
                Label("Save image", systemImage: "square.and.arrow.down")
            }

            if message.sender.userId == matrix.creds.userId {
                Button(action: {
                    // FIXME: TODO
                }) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
        }
        
        Button(action: {
            message.objectWillChange.send()
        }) {
            Label("Refresh", systemImage: "arrow.clockwise")
        }
        
        Button(action: {
            self.showDetail = true
        }) {
            Label("Show detailed view", systemImage: "magnifyingglass")
        }
    }
}
