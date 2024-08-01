//
//  SetupAddNewCircleSheet.swift
//  Circles
//
//  Created by Charles Wright on 5/30/24.
//

import SwiftUI
import PhotosUI
import Matrix

struct SetupAddNewCircleSheet: View {
    @ObservedObject var me: Matrix.User
    @Binding var circles: [CircleSetupInfo]
    @Environment(\.presentationMode) var presentation
    
    @State private var circleName: String = ""
    @State private var avatarImage: UIImage? = nil
    @State private var showPicker = false
    @State private var item: PhotosPickerItem?
        
    @State private var showErrorMessage = false
    
    @FocusState var inputFocused
    
    @ViewBuilder
    var buttonBar: some View {
        HStack {
            Button(action: {
                self.presentation.wrappedValue.dismiss()
            })
            {
                Text("Cancel")
            }
            
            Spacer()
        }
        .font(.subheadline)
    }
    
    var mockup: some View {
        HStack {
            let cardSize: CGFloat = 120
            
            //Spacer()
            
            ZStack {
                if let img = avatarImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.gray
                }
            }
            .frame(width: cardSize, height: cardSize)
            .clipShape(Circle())
            //.overlay(Circle().stroke(Color.gray, lineWidth: 2))
            .overlay(alignment: .bottomTrailing) {
                PhotosPicker(selection: $item, matching: .images) {
                    Image(systemName: SystemImages.pencilCircleFill.rawValue)
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 30))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.borderless)
            }
            .shadow(radius: 5)
            .padding(.horizontal, 5)
            .onChange(of: item) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        let img = UIImage(data: data)
                        await MainActor.run {
                            self.avatarImage = img
                        }
                    }
                }
            }

            VStack(alignment: .leading) {
                Text(circleName.isEmpty ? "New Circle" : circleName)
                    .lineLimit(3)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(me.displayName ?? me.userId.username)
                    .font(.title2)
                    //.fontWeight(.bold)
                
                Text(me.userId.stringValue)
                    .font(.body)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }

    var body: some View {
        ZStack {
            Color.greyCool200
            
            ScrollView {
                let elementWidth = UIScreen.main.bounds.width - 48
                let elementHeight = 48.0
                
                buttonBar
                
                mockup
                    .padding()
                
                TextField("Circle name", text: $circleName)
                    .frame(width: elementWidth - 24, height: elementHeight)
                    .padding([.horizontal], 12)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.greyCool400))
                    .textInputAutocapitalization(.words)
                    .focused($inputFocused)
                    .onAppear {
                        self.inputFocused = true
                    }
                    .onSubmit {
                        self.showErrorMessage = circles.contains(where: { $0.name == circleName })
                    }
                
                if showErrorMessage {
                    Label("You already have a circle with this name", systemImage: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                Button(action: {
                    let name = circleName.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    guard !name.isEmpty
                    else { return }
                    
                    guard !circles.contains(where: { $0.name == name })
                    else {
                        self.showErrorMessage = true
                        return
                    }
                    
                    let info = CircleSetupInfo(name: name, avatar: avatarImage)
                    circles.append(info)
                    presentation.wrappedValue.dismiss()
                }) {
                    Text("Add circle \"\(circleName.isEmpty ? "New Circle" : circleName)\"")
                }
                .buttonStyle(BigRoundedButtonStyle(width: elementWidth, height: elementHeight))
                .font(CustomFonts.nunito16)
                .disabled(circleName.isEmpty)
                
                Spacer()
            }
            .scrollIndicators(.hidden)
            .padding()
        }
    }
}

/*
struct StreamCreationSheet_Previews: PreviewProvider {
    static var previews: some View {
        CircleCreationSheet(store: LegacyStore())
    }
}
*/
