//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  MessageReportingSheet.swift
//  Circles for iOS
//
//  Created by Charles Wright on 2/4/21.
//

import SwiftUI
import Matrix

struct MessageReportingSheet: View {
    @ObservedObject var message: Matrix.Message
    //@Binding var show: Bool
    @Environment(\.presentationMode) var presentation
    @State private var reportedSeverity: Double = 0.0
    let categories: [String] = [
        "Crude language",
        "Copyright violation (\"piracy\")",
        "Nudity",
        "Pornographic or sexual material",
        "Gore",
        "Self harm",
        "Demeaning or disparaging groups of people (racism, sexism, ...)",
        "Insults or personal attacks",
        "Targeted harassment or doxxing",
        "Threatening or planning violence",
        "Other prohibited content"
    ]
    @State private var selectedCategories: Set<String> = []
    @State private var other: String = ""
    
    var buttonBar: some View {
        HStack {
            let buttonPadding: CGFloat = 5

            Button(action: {
                self.presentation.wrappedValue.dismiss()
            }) {
                Label("Cancel", systemImage: "xmark")
            }
            .padding(buttonPadding)
            Spacer()
            AsyncButton(action: {
                let reasons = Array(selectedCategories)
                try await message.room.report(eventId: message.eventId, score: Int(reportedSeverity), reason: reasons.joined(separator: "; "))
                self.presentation.wrappedValue.dismiss()
            }) {
                Label("Submit Report", systemImage: "exclamationmark.shield")
            }
            .padding(buttonPadding)
        }
    }
    
    var introSection: some View {
        VStack {
            Label("Reporting Inappropriate Content", systemImage: "exclamationmark.shield")
                .font(.title2)
                //.fontWeight(.bold)

            VStack(alignment: .leading, spacing: 5) {
                Text("Thank you for helping to keep this community safe and pleasant for everyone.")
                    .font(.subheadline)

                Text("The following brief questions will help us respond most effectively to your report.")
                    .font(.subheadline)
            }
            .padding(.top, 5)
        }
    }
    
    var severitySection: some View {
        VStack {
            Text("How inappropriate is the reported content?")
                .font(.headline)
                .padding(.top)
            VStack(alignment: .leading) {
                Text("  0: Very mild (fart jokes, toilet humor)")
                Text("100: Illegal content (child abuse; terrorism)")

                Slider(value: $reportedSeverity, in: 0...100, step: 1.0)
                HStack {
                    Text("0")
                    Spacer()
                    Text("100")
                }
                .font(.caption)
                HStack(alignment: .center) {
                    Spacer()
                    Text("Severity: \(Int(reportedSeverity))")
                    Spacer()
                }
            }
            .padding(.leading)
            .font(.subheadline)
        }
    }
    
    var categoriesSection: some View {
        VStack {
            Text("Which of the following categories does the inappropriate message contain?")
                .font(.headline)
                .padding(.top)
            VStack(alignment: .leading) {
                ForEach(categories, id: \.self) { category in
                    HStack {
                        if selectedCategories.contains(category) {
                            //Image(systemName: "checkmark.circle")
                            Button(action: {selectedCategories.remove(category)}) {
                                //Text(category)
                                Label(category, systemImage: "checkmark.circle")
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        else {
                            //Image(systemName: "circle")
                            Button(action: { selectedCategories.insert(category)}) {
                                //Text(category)
                                Label(category, systemImage: "circle")
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .font(.subheadline)
                }
            }
            .padding(.leading)
        }
    }
    
    var body: some View {
        VStack {

            introSection
            
            Divider()
            
            // FIXME Add a mini-size, blurred version of the original content here
            
            severitySection
            
            Divider()
            
            categoriesSection
            
            Divider()
            
            buttonBar
        }
        .padding()
    }
}

/*
struct MessageReportingSheet_Previews: PreviewProvider {
    static var previews: some View {
        MessageReportingSheet()
    }
}
*/
