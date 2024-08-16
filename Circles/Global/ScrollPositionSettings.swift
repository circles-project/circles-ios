//
//  ScrollPositionSettings.swift
//  Circles
//
//  Created by Dmytro Ryshchuk on 8/16/24.
//

import SwiftUI

class ScrollPositionSettings {
    static let shared = ScrollPositionSettings()

    @AppStorage("needToRestoreScrollPosition") var needToRestoreScrollPosition: Bool = false

    private init() {}
}
