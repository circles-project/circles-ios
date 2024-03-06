//
//  Data+hex.swift
//  Circles
//
//  Created by Charles Wright on 3/6/24.
//

import Foundation

extension Data {
    var hexString: String {
        let string = self.map {
            String(format: "%02hhx", $0)
        }.joined()
        
        return string
    }
}
