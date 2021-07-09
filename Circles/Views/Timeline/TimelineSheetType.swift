//
//  TimelineSheetType.swift
//  Circles
//
//  Created by Charles Wright on 7/7/21.
//

import Foundation

enum TimelineSheetType: String {
    case composer
    case detail
    case reporting
}
extension TimelineSheetType: Identifiable {
    var id: String { rawValue }
}
