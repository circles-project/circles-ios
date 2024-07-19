//
//  MessageSheetType.swift
//  Circles
//
//  Created by Charles Wright on 7/13/21.
//

import Foundation

enum MessageSheetType: String {
    case edit
    case reporting
    case liked
}

extension MessageSheetType: Identifiable {
    var id: String { rawValue }
}
