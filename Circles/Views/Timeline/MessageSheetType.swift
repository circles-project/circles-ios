//
//  MessageSheetType.swift
//  Circles
//
//  Created by Charles Wright on 7/13/21.
//

import Foundation

enum MessageSheetType: String {
    case composer
    case reactions
    case reporting
}

extension MessageSheetType: Identifiable {
    var id: String { rawValue }
}
