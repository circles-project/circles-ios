//
//  ViewModifier+Extensions.swift
//  Circles
//
//  Created by Dmytro Ryshchuk on 6/6/24.
//

import SwiftUI
import PhotosUI

struct CustomEmailTextFieldStyle: ViewModifier {
    var contentType: UITextContentType
    var keyboardType: UIKeyboardType
    
    func body(content: Content) -> some View {
        content
            .textContentType(contentType)
            .keyboardType(keyboardType)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
    }
}

struct DeleteMediaOverlay: ViewModifier {
    @Binding var selectedItem: PhotosPickerItem?
    @Binding var messageState: PostComposer.MessageState
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Button(action: {
                    selectedItem = nil
                    messageState = .text
                }) {
                    Image(systemName: SystemImages.xCircleFill.rawValue)
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 30))
                        .foregroundColor(.red)
                }
                    .alignmentGuide(.trailing) { $0[.trailing] - 0 }
                    .alignmentGuide(.top) { $0[.top] + 0 },
                alignment: .topTrailing
            )
    }
}

struct ChangeMediaOverlay: ViewModifier {
    @Binding var selectedItem: PhotosPickerItem?
    @Binding var matching: PHPickerFilter
    
    func body(content: Content) -> some View {
        content
            .overlay(
                PhotosPicker(selection: $selectedItem, matching: matching) {
                    Image(systemName: SystemImages.pencilCircleFill.rawValue)
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 30))
                        .foregroundColor(.accentColor)
                }
                    .alignmentGuide(.trailing) { $0[.trailing] - 0 }
                    .alignmentGuide(.bottom) { $0[.bottom] + 0 },
                alignment: .bottomTrailing
            )
    }
}

extension View {
    func customEmailTextFieldStyle(contentType: UITextContentType,
                              keyboardType: UIKeyboardType) -> some View {
        self.modifier(CustomEmailTextFieldStyle(contentType: contentType,
                                                keyboardType: keyboardType))
    }
    
    func deleteMediaOverlay(selectedItem: Binding<PhotosPickerItem?>, messageState: Binding<PostComposer.MessageState>) -> some View {
        self.modifier(DeleteMediaOverlay(selectedItem: selectedItem, messageState: messageState))
    }
    
    func changeMediaOverlay(selectedItem: Binding<PhotosPickerItem?>, matching: Binding<PHPickerFilter>) -> some View {
        self.modifier(ChangeMediaOverlay(selectedItem: selectedItem, matching: matching))
    }
}
