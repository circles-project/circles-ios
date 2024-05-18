//
//  StorageSettingsView.swift
//  Circles
//
//  Created by Charles Wright on 4/11/24.
//

import SwiftUI
import Matrix

struct StorageSettingsView: View {
    var session: Matrix.Session
    
    @State var configInfo: Matrix.MediaConfigInfo?
    @State var usageInfo: Matrix.MediaUsageInfo?
    
    func refresh() async {
        let newConfigInfo = try? await session.getMediaConfig()
        let newUsageInfo = try? await session.getMediaUsage()
        
        await MainActor.run {
            self.configInfo = newConfigInfo
            self.usageInfo = newUsageInfo
        }
    }
    
    func byteSize(_ numBytes: Int?) -> String {
        guard let num = numBytes
        else { return "???" }
        
        let kb = 1024
        let mb = 1024*1024
        let gb = 1024*1024*1024
        let tb = 1024*1024*1024*1024
        
        if num > tb {
            let tbs = Double(num) / Double(tb)
            return String(format: "%.1f TB", tbs)
        } else if num > gb {
            let gbs = Double(num) / Double(gb)
            return String(format: "%.1f GB", gbs)
        } else if num > mb {
            let mbs = Double(num) / Double(mb)
            return String(format: "%.1f MB", mbs)
        } else if num > kb {
            let kbs = Double(num) / Double(kb)
            return String(format: "%.1f KB", kbs)
        } else {
            return String(format: "%d B", num)
        }
    }
    
    var body: some View {
        Form {
            if configInfo == nil && usageInfo == nil {
                Text("Server does not provide media usage info") // TODO: check if still needed after upload media
            }
            
            if let usage = usageInfo {
                Section("Current Usage") {
                    Text("Storage used")
                        .badge(byteSize(usage.storageUsed))
                    Text("Files uploaded")
                        .badge(byteSize(usage.storageFiles))
                }
            }
            
            if let config = configInfo {
                Section("Storage Limits") {
                    Text("Max file size")
                        .badge(byteSize(config.maxUploadSize))
                    Text("Available storage")
                        .badge(byteSize(config.storageSize))
                    Text("Max files allowed")
                        .badge(byteSize(config.maxFiles))
                }
            }
        }
        .navigationTitle("Storage")
        .refreshable {
            await self.refresh()
        }
        .task {
            await self.refresh()
        }
    }
}

