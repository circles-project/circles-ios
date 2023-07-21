//
//  HtmlView.swift
//  Circles
//
//  Created by Charles Wright on 3/29/23.
//

import Foundation
import SwiftUI
import UIKit

// Loosely based on https://stackoverflow.com/a/62281735

struct HtmlView: UIViewRepresentable {
    let html: String
    
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UILabel {
        let label = UILabel()
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        
        if let data = html.data(using: .utf8),
           let mutable = try? NSMutableAttributedString(data: data,
                                                          options: [
                                                            .documentType: NSAttributedString.DocumentType.html,
                                                          ],
                                                          documentAttributes: nil)
        {
            //mutable.addAttribute(.font, value: UIFont.systemFont(ofSize: 24), range: NSRange(location: 0, length: mutable.length))
            let attributedString = NSAttributedString(attributedString: mutable)
            DispatchQueue.main.async {
                label.attributedText = attributedString
            }
        }
        
        return label
    }
    
    func updateUIView(_ uiView: UILabel, context: Context) {
        // Do nothing
    }
}
