//
//  EmojiPicker.swift
//  Circles
//
//  Created by Charles Wright on 7/20/21.
//

import SwiftUI
import Matrix
import KeyboardKit

struct EmojiPicker: View {
    var message: Matrix.Message
    @Environment(\.presentationMode) var presentation

    //let categories: [EmojiCategory] = [.smileys, .animals, .foods, .activities, .travels, .objects, .symbols, .flags] // Everything but "recent" and "frequent"
    let categories = EmojiCategory.all

    @State var selectedCategory: EmojiCategory = .frequent

    var buttonBar: some View {
        HStack {
            Spacer()

            Button(action: {
                self.presentation.wrappedValue.dismiss()
            }) {
                Text("Cancel")
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                buttonBar
                
                // Quick reactions
                Text("QUICK REACTIONS")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                HStack {
                    let emojis = ["👍", "👎", "😀", "😢", "❤️", "🎉", "🔥"]
                    ForEach(emojis, id: \.self) { emoji in
                        AsyncButton(action: {
                            guard let _ = try? await self.message.sendReaction(emoji) // let reactionEventId
                            else {
                                // FIXME: Set some error message
                                return
                            }
                            
                            // Log that we've used this emoji
                            let provider = MostRecentEmojiProvider()
                            provider.registerEmoji(Emoji(emoji))

                            self.presentation.wrappedValue.dismiss()
                        }) {
                            Text(emoji)
                                .font(.title)
                                .padding(3)
                        }
                    }
                }
            
                let columns: [GridItem] =
                        Array(repeating: .init(.flexible()), count: 6)

                ForEach(categories) { category in
                    
                    Divider()

                    Text(category.title.uppercased())
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    LazyVGrid(columns: columns) {
                        
                        let emojis: [Emoji] = category.emojis
                        let reactions = emojis.map { $0.char }
                        
                        ForEach(reactions, id: \.self) { reaction in
                            //let reaction: String = emoji.char
                            AsyncButton(action: {
                                guard let _ = try? await self.message.sendReaction(reaction) // let reactionEventId
                                else {
                                    // FIXME: Set some error message
                                    return
                                }
                                
                                // Log that we've used this emoji
                                let provider = MostRecentEmojiProvider()
                                provider.registerEmoji(Emoji(reaction))
                                
                                self.presentation.wrappedValue.dismiss()
                            }) {
                                Text(reaction)
                                    .font(.title)
                                    .padding(3)
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
}

/*
struct EmojiPicker_Previews: PreviewProvider {
    static var previews: some View {
        EmojiPicker()
    }
}
*/
