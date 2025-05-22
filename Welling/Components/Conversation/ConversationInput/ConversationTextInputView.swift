//
//  ConversationTextInputView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-25.
//

import SwiftUI

struct ConversationTextInputView: View {
    @Binding var inputText: String
    @State var height: CGFloat = 24.0
    @FocusState.Binding var isTyping: Bool
    
    var body: some View {
        HStack(spacing: Theme.Spacing.medium) {
            
            ///MARK :- WEL-886: Update preview message to 'Type a message...'
            ///Task :- change test Type a message…
            ///Date :- 27 August, 2024
            ///By Piyush Poshiya

            TextField("", text: $inputText, prompt: Text("Type a message…")
                .foregroundStyle(Theme.Colors.TextNeutral9.opacity(0.5)),  axis: .vertical)
            
            .focused($isTyping)
            .scrollContentBackground(.hidden)
            .lineLimit(10)
            .fontWithLineHeight(Theme.Text.mediumMedium)
            .padding(.vertical, Theme.Spacing.medium)
            .padding(.horizontal, Theme.Spacing.medium)
            //
            //            IconButtonView("microphone", foregroundColor: Theme.Colors.TextNeutral9.opacity(0.5), defaultPadding: false) {}
            //
        }
        .background(Theme.Colors.SurfaceNeutral3)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .onAppear {
//            updateHeight()
        }
        .onChange(of: inputText) {
//            updateHeight()
        }
    }
    
    func updateHeight() {
        let lines = inputText.filter { $0 == "\n" }.count + 1
        if lines >= 3 {
            height = 72
        } else {
            height = 24.0 * CGFloat(lines)
        }
    }
}


#Preview {
    struct PreviewWrapper: View {
        @State var inputText: String = "Type a message…"
        @FocusState private var focused: Bool
        
        var body: some View {
            ConversationTextInputView(inputText: $inputText, isTyping: $focused)
        }
    }
    return PreviewWrapper()
}
