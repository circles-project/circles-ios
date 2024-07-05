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
    
    func byteSize(_ numBytes: Int) -> String {
        
        let kb = 1024
        let mb = 1024*1024
        let gb = 1024*1024*1024
        let tb = 1024*1024*1024*1024
        
        if numBytes > tb {
            let tbs = Double(numBytes) / Double(tb)
            return String(format: "%.1f TB", tbs)
        } else if numBytes > gb {
            let gbs = Double(numBytes) / Double(gb)
            return String(format: "%.1f GB", gbs)
        } else if numBytes > mb {
            let mbs = Double(numBytes) / Double(mb)
            return String(format: "%.1f MB", mbs)
        } else if numBytes > kb {
            let kbs = Double(numBytes) / Double(kb)
            return String(format: "%.1f KB", kbs)
        } else {
            return String(format: "%d B", numBytes)
        }
    }
    
    var body: some View {
        Form {
            if let usage = usageInfo,
               (usage.storageUsed != nil || usage.storageFiles != nil)
            {
                Section("Current Usage") {
                    if let storageUsed = usage.storageUsed {
                        Text("Storage used")
                            .badge(byteSize(storageUsed))
                    }
                    if let storageFiles = usage.storageFiles {
                        Text("Files uploaded")
                            .badge(byteSize(storageFiles))
                    }
                }
            }
            
            if let config = configInfo,
               (config.maxUploadSize != nil || config.storageSize != nil || config.maxFiles != nil)
            {
                Section("Storage Limits") {
                    if let maxUploadSize = config.maxUploadSize {
                        Text("Max file size")
                            .badge(byteSize(maxUploadSize))
                    }
                    if let storageSize = config.storageSize {
                        Text("Available storage")
                            .badge(byteSize(storageSize))
                    }
                    if let maxFiles = config.maxFiles {
                        Text("Max files allowed")
                            .badge(byteSize(maxFiles))
                    }
                }
            }
            
            if usageInfo == nil && configInfo == nil {
                Section("No information available") {
                    Text("Your server does not provide storage status")
                    AsyncButton(action: {
                        await self.refresh()
                    }) {
                        Text("Retry fetching storage status")
                    }
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

