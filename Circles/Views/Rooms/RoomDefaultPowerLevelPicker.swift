//
//  RoomDefaultPowerLevelPicker.swift
//  Circles
//
//  Created by Charles Wright on 4/9/24.
//

import SwiftUI
import Matrix

struct RoomDefaultPowerLevelPicker: View {
    @ObservedObject var room: Matrix.Room
        
    @State var selected: PowerLevel
    
    init(room: Matrix.Room) {
        self.room = room
        let level = PowerLevel(power: room.powerLevels?.usersDefault ?? 0)
        self._selected = State(wrappedValue: level)
    }
    
    var body: some View {
        Picker("Default", selection: $selected) {
            ForEach(CIRCLES_POWER_LEVELS) { level in
                Text(level.description)
                    .tag(level)
            }
        }
        .onChange(of: selected) { newLevel in
            Task {
                print("Setting new power level")
                try await room.setPowerLevel(usersDefault: newLevel.power)
            }
        }
    }
}
