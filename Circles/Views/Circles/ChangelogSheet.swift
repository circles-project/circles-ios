//
//  BuildChangesMarkdownSheet.swift
//  Circles
//
//  Created by Dmytro Ryshchuk on 6/12/24.
//

import MarkdownUI
import SwiftUI

struct ChangelogSheet: View {
    enum TitleDescription: String {
        case lastUpdates = "New in this version of Circles"
        case fullList = "All updates in the app"
    }
    
    let content: String
    var title: TitleDescription = .lastUpdates
    @Binding var showChangelog: Bool
    
    var body: some View {
        ScrollView {
            HStack {
                Spacer()
                Button("", systemImage: SystemImages.xmark.rawValue) {
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
            Text(title.rawValue)
                .font(.largeTitle)
            
            Markdown(content)
                .padding()
            
            Button("Got it") {
                showChangelog = false
            }
            .buttonStyle(BigBlueButtonStyle())
        }
        .navigationTitle("Markdown Content")
    }
}

struct ChangelogFile {
    enum ChangelogFile: String {
        case lastUpdates = "CHANGELOG_LastUpdates"
        case fullList = "CHANGELOG_Full"
    }
    
    func loadMarkdown(named name: ChangelogFile) -> String {
        guard let url = Bundle.main.url(forResource: name.rawValue, withExtension: "md"),
              let content = try? String(contentsOf: url) else {
            return "Error loading file."
        }
        return content
    }
        
    func checkLastUpdates(for name: ChangelogFile, showChangelog: inout Bool, changelogLastUpdate: inout TimeInterval) {
        if let modificationDate = getModificationDate(named: name.rawValue) {
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
