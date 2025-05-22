//
//  PrewallView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-07-15.
//

import SwiftUI
import Mixpanel
import AVKit

struct PrewallView: View {
    @State var currentPage: Int = 0
    var viewModel: SignUpViewModel
    
    var body: some View {
        VStack (spacing: Theme.Spacing.small) {
            Spacer()
            if currentPage == 0 {
                PrewallScreen1View()
                    .transition(.asymmetric(insertion: .push(from: .trailing), removal: .move(edge: .leading)))
            } else if currentPage == 1 {
                PrewallScreen2View()
                    .transition(.asymmetric(insertion: .push(from: .trailing), removal: .move(edge: .leading)))
            } else if currentPage == 2 {
                PrewallScreen3View()
                    .transition(.asymmetric(insertion: .push(from: .trailing), removal: .move(edge: .leading)))
            } else {
                PrewallScreen4View()
                    .transition(.asymmetric(insertion: .push(from: .trailing), removal: .move(edge: .leading)))
            }
            Spacer()
            WBlobkButton("Next") {
                if currentPage == 0 {
                    Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"Prewall Next 1"])
                    withAnimation {
                        currentPage = 1
                    }
                } else if currentPage == 1 {
                    Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"Prewall Next 2"])
                    withAnimation {
                        currentPage = 2
                    }
                } else if currentPage == 2 {
                    Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"Prewall Next 3"])
                    withAnimation {
                        currentPage = 3
                    }
                } else {
                    Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"Prewall Next 4"])
                    viewModel.onPrewallSeen()
                }
            }
        }
        .foregroundStyle(Theme.Colors.TextNeutral9)
        .background(Theme.Colors.SurfaceNeutral05)
        .padding(.horizontal, Theme.Spacing.horizontalPadding)
    }
}

fileprivate struct PrewallScreen1View: View {
    @State var player = AVPlayer(url: Bundle.main.url(forResource: "prewall_video_1", withExtension: "mp4", subdirectory: "static/videos")!)
    
    @State var videoFrame: CGSize = .zero
    
    var body: some View {
        PrewallVideoPlayer(player: $player, label: "Easy photo logging")
    }
}

fileprivate struct PrewallScreen2View: View {
    @State var player = AVPlayer(url: Bundle.main.url(forResource: "prewall_video_2", withExtension: "mp4", subdirectory: "static/videos")!)
    
    var body: some View {
        PrewallVideoPlayer(player: $player, label: "Or use chat")
    }
}

fileprivate struct PrewallScreen3View: View {
    @State var player = AVPlayer(url: Bundle.main.url(forResource: "prewall_video_3", withExtension: "mp4", subdirectory: "static/videos")!)
    
    var body: some View {
        PrewallVideoPlayer(player: $player, label: "And see results")
    }
}

fileprivate struct PrewallVideoPlayer: View {
    @Binding var player: AVPlayer
    let label: String
    
    @State var videoFrame: CGSize = .zero
    
    var body: some View {
        VStack (spacing: Theme.Spacing.medium) {
            ZStack {
                GeometryReader { geo in
                    VStack {
                        Spacer()
                    }
                    .onAppear {
                        videoFrame = geo.size
                    }
                }
                VStack (spacing: 0) {
                    PlayerView(player: $player)
                        .allowsHitTesting(false)
                        .frame(width: videoFrame.height * 9.0 / 16.0, height: videoFrame.height, alignment: .center)
                        .background(.clear)
                        .onAppear {
                            player.play()
                            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main) { _ in
                                player.seek(to: .zero)
                                player.play()
                            }
                        }
                        .onDisappear {
                            player.pause()
                        }
                }
            }
            
            Text(label)
                .fontWithLineHeight(Theme.Text.h5)
        }
    }
}

fileprivate struct PrewallScreen4View: View {
    
    var body: some View {
        VStack (alignment: .leading, spacing: Theme.Spacing.xlarge) {
            HStack (spacing: Theme.Spacing.xxsmall) {
                ColoredIconView(imageName: "heart",  foregroundColor: Theme.Colors.TextNeutral9)
                Text("Loved by users:")
                    .fontWithLineHeight(Theme.Text.mediumMedium)
                Spacer()
            }
            
            VStack (alignment: .leading, spacing: 0) {
                Text("“My trusted health companion“")
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fontWithLineHeight(Theme.Text.h2)
                
                Text("-Shu Wei")
                    .fontWithLineHeight(Theme.Text.regularRegular)
                    .foregroundStyle(Theme.Colors.TextNeutral3)
            }
            
            VStack (alignment: .leading, spacing: 0) {
                Text("“I switched from MyFitnessPal“")
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fontWithLineHeight(Theme.Text.h2)
                
                Text("-Chiroani")
                    .fontWithLineHeight(Theme.Text.regularRegular)
                    .foregroundStyle(Theme.Colors.TextNeutral3)
            }

            VStack (alignment: .leading, spacing: 0) {
                Text("“Amazing app!“")
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fontWithLineHeight(Theme.Text.h2)
                
                Text("-Yoshua")
                    .fontWithLineHeight(Theme.Text.regularRegular)
                    .foregroundStyle(Theme.Colors.TextNeutral3)
            }
            
            Divider()
                .overlay(Theme.Colors.BorderNeutral95)
            
            Text("Welling is rated **4.3 Excellent** on Trustpilot")
                .fontWithLineHeight(Theme.Text.mediumRegular)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.bottom, Theme.Spacing.large)
                .frame(alignment: .center)
        }
        .card()
    }
}

class PlayerUIView: UIView {
    
    // MARK: Class Property
    
    let playerLayer = AVPlayerLayer()
    
    // MARK: Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(player: AVPlayer) {
        super.init(frame: .zero)
        self.playerSetup(player: player)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Life-Cycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
    
    // MARK: Class Methods
    
    private func playerSetup(player: AVPlayer) {
        playerLayer.player = player
        player.actionAtItemEnd = .none
        layer.addSublayer(playerLayer)
        playerLayer.backgroundColor = UIColor.clear.cgColor
    }
}

struct PlayerView: UIViewRepresentable {
    
    @Binding var player: AVPlayer
    
    func makeUIView(context: Context) -> PlayerUIView {
        return PlayerUIView(player: player)
    }
    
    func updateUIView(_ uiView: PlayerUIView, context: UIViewRepresentableContext<PlayerView>) {
        uiView.playerLayer.player = player
    }
}

#Preview {
    PrewallView(viewModel: SignUpViewModel())
}
