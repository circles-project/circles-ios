//
//  MatrixMyDevice.swift
//  Circles
//
//  Created by Charles Wright on 6/23/22.
//

import Foundation

class MatrixMyDevice: ObservableObject {
    var matrix: MatrixAPI
    var deviceId: String
    @Published var displayName: String?
    @Published var lastSeenIp: String?
    @Published var lastSeenTs: Date?
    
    init(matrix: MatrixAPI, deviceId: String, displayName: String? = nil, lastSeenIp: String? = nil, lastSeenUnixMs: Int? = nil) {
        self.matrix = matrix
        self.deviceId = deviceId
        self.displayName = displayName
        self.lastSeenIp = lastSeenIp
        if let unixMs = lastSeenUnixMs {
            let interval = TimeInterval(1000 * unixMs)
            self.lastSeenTs = Date(timeIntervalSince1970: interval)
        }
    }
}
