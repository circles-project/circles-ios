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

    struct PowerLevel: Identifiable, Equatable, Hashable {
        var power: Int
        
        var id: Int {
            power
        }
        
        var description: String {
            if power < 0 {
                return "Can View"
            } else if power < 50 {
                return "Can Post"
            } else if power < 100 {
                return "Moderator"
            } else {
                return "Admin"
            }
        }
        
        static func ==(lhs: PowerLevel, rhs: PowerLevel) -> Bool {
            lhs.power == rhs.power
        }
    }
    
    let levels: [PowerLevel] = [-10, 0, 50, 100].map { PowerLevel(power: $0) }
    
    @State var selected: PowerLevel
    
    init(room: Matrix.Room) {
        self.room = room
        let level = PowerLevel(power: room.powerLevels?.usersDefault ?? 0)
        self._selected = State(wrappedValue: level)
    }
    
    var body: some View {
        Picker("Default", selection: $selected) {
            ForEach(levels) { level in
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
