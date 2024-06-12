//
//  BuildChangesMarkdownSheet.swift
//  Circles
//
//  Created by Dmytro Ryshchuk on 6/12/24.
//

import MarkdownUI
import SwiftUI

struct ChangelogSheet: View {
    let content: String
    @Binding var showChangelog: Bool
    
    var body: some View {
        ScrollView {
            HStack {
                Spacer()
                Button("", systemImage: "xmark") {
                    showChangelog = false
                }
                .padding()
            }
            CirclesLogoView()
                .frame(minWidth: 60,
                       idealWidth: 90,
                       maxWidth: 120,
                       minHeight: 60,
                       idealHeight: 90,
                       maxHeight: 120,
                       alignment: .center)
            Text("What's New")
                .font(.largeTitle)
            
            Markdown(content)
                .padding()
        }
        .navigationTitle("Markdown Content")
    }
}

struct ChangelogFile {
    func loadMarkdown(named name: String) -> String {
        guard let url = Bundle.main.url(forResource: name, withExtension: "md"),
              let content = try? String(contentsOf: url) else {
            return "Error loading file."
        }
        return content
    }
        
    func checkLastUpdates(showChangelog: inout Bool, changelogLastUpdate: inout TimeInterval) {
        if let modificationDate = getModificationDate(named: "CHANGELOG") {
            if changelogLastUpdate != modificationDate.timeIntervalSince1970 {
                changelogLastUpdate = modificationDate.timeIntervalSince1970
                showChangelog = true
            }
        } else {
            showChangelog = false
        }
    }
    
    private func getModificationDate(named name: String) -> Date? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "md") else {
            return nil
        }
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.modificationDate] as? Date
        } catch {
            return nil
        }
    }
}
