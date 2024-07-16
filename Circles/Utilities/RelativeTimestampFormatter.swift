//
//  RelativeTimestampFormatter.swift
//  Circles
//
//  Created by Charles Wright on 7/16/24.
//

import Foundation

enum RelativeTimestampFormatter {
    
    public static func format(date: Date) -> String {
        
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "now"
        } else if interval < 3600 {
            let minutes = Int(interval) / 60
            return "\(minutes)m"
        } else if interval < 86400 {
            let hours = Int(interval) / 3600
            return "\(hours)h"
        } else if interval < 604800 {
            let days = Int(interval) / 86400
            return "\(days)d"
        } else if interval < 31449600 {
            let weeks = Int(interval) / 604800
            return "\(weeks)w"
        } else {
            let years = Int(interval) / 31449600
            return "\(years)y"
        }
    }
}
