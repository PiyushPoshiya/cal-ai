//
//  ConversationInputView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-25.
//

import SwiftUI
import SuperwallKit
import Mixpanel

struct ConversationInputView: View {
    static let AnalyticsScreen: String = "Conversation"
    @EnvironmentObject var keyboardHeightProvider: KeyboardHeightProvider
    @EnvironmentObject var realmDataManager: DM
    @EnvironmentObject var um: UserManager
    @Environment(ConversationScreenViewModel.self) var conversationScreenViewModel: ConversationScreenViewModel
    @FocusState var isTyping: Bool
    @State var viewModel: ViewModel = .init()
    @State var inputState: ConversationinputViewState = .idle
    
    static let extrasAnimationDuration: Double = 0.25
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Theme.Spacing.small) {
                ConversationTextInputView(inputText: $viewModel.inputText, isTyping: $isTyping)
                
                if viewModel.inputText.isEmpty {
                    IconButtonView("camera", defaultPadding: false) {
                        Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"Camera Icon", "screen": Self.AnalyticsScreen])
                        viewModel.onCameraButtonTapped()
                    }
                    .padding(.vertical, Theme.Spacing.xsmall)
                    
                    IconButtonView("plus-circle", defaultPadding: false) {
                        Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"Extras Icon", "screen": Self.AnalyticsScreen])
                        viewModel.onExtrasButtonTapped()
                    }
                    .rotationEffect(.degrees(viewModel.viewState == .extras ? 135 : 0))
                    .padding(.vertical, Theme.Spacing.xsmall)
                } else {
                    SendButton (isSaving: .constant(false)) {
                        if um.checkIsSubscribedUsingFirebase() {
                            viewModel.handleSendButton(realmDataManager: realmDataManager, text: viewModel.inputText, meal: nil, localImagePath: nil, onMessageSaved: {
                                conversationScreenViewModel.messageAppended = !conversationScreenViewModel.messageAppended
                            })
                        } else {
                            Superwall.shared.register(event: "send_message", handler: viewModel.paywallHandler(um: self.um) {
                                viewModel.handleSendButton(realmDataManager: realmDataManager, text: viewModel.inputText, meal: nil, localImagePath: nil, onMessageSaved: {
                                    conversationScreenViewModel.messageAppended = !conversationScreenViewModel.messageAppended
                                })
                            })
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.medium)
            .padding(.vertical, Theme.Spacing.xsmall)
            if inputState == .extras {
                ConversationExtrasView(onFavorited: {
                    viewModel.onFavorited()
                })
                .frame(height: keyboardHeightProvider.keyboardHeight)
            }
        }
        .environment(viewModel)
        .background(Theme.Colors.SurfaceNeutral05)
        .ignoresSafeArea()
        .fullScreenCover(isPresented: $viewModel.presentCameraInput) {
            ConversationPhotoInputView(present: $viewModel.presentCameraInput, onSend: {message, meal, localImagePath in
                viewModel.handleSendButton(realmDataManager: realmDataManager, text: message, meal: meal, localImagePath: localImagePath, onMessageSaved: { @MainActor in
                    conversationScreenViewModel.messageAppended = !conversationScreenViewModel.messageAppended
                })
            })
        }
        .onAppear {
            viewModel.onAppear(conversationScreenViewModel: conversationScreenViewModel)
        }
        .onChange(of: conversationScreenViewModel.onTappedOutsideInput) {
            viewModel.onTappedOutsideInput()
        }
        .onChange(of: isTyping) { _, newValue in
            viewModel.onTextFieldGainedFocus(focused: newValue)
        }
        .onChange(of: viewModel.inputTextFieldHasFocus) { _, newValue in
            isTyping = newValue
        }
        .onChange(of: viewModel.viewState, initial: false) { oldState, newState in
            if newState == .extras {
                withAnimation(.easeInOut(duration: Self.extrasAnimationDuration)) {
                    self.inputState = newState
                }
                return
            } else if oldState == .extras {
                withAnimation(.easeInOut(duration: Self.extrasAnimationDuration)) {
                    self.inputState = newState
                }
                return
            }
        }
    }
}

#Preview {
    VStack {
        Spacer()
        ConversationInputView()
    }
}
