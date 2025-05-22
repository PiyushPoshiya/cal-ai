import SwiftUI
import Charts

struct FontWithLineHeight: ViewModifier {
    let props: FontWithLineHeightProps

    func body(content: Content) -> some View {
        content
            .font(Font(props.font))
            .lineSpacing(props.lineHeight - props.font.lineHeight)
            .padding(.vertical, (props.lineHeight - props.font.lineHeight) / 2)
    }
}

struct FlippedUpsideDown: ViewModifier {
    func body(content: Content) -> some View {
        content
            .rotationEffect(.radians(Double.pi))
            .scaleEffect(x: -1, y: 1, anchor: .center)
    }
}

struct InputBorder: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.white)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.medium))
    }
}

struct ShadowModifier: ViewModifier {
    let enabled: Bool
    func body(content: Content) -> some View {
        if enabled {
            content
                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 6)
        } else {
            content
        }
    }
}

struct FontWithLineHeightProps {
    let font: UIFont
    let lineHeight: CGFloat
    let kerning: CGFloat
}

extension View {
    func flippedUpsideDown() -> some View {
        modifier(FlippedUpsideDown())
    }
    
    func hideKeyboard() {
        let resign = #selector(UIResponder.resignFirstResponder)
        UIApplication.shared.sendAction(resign, to: nil, from: nil, for: nil)
    }

    func fontWithLineHeight(_ props: FontWithLineHeightProps) -> some View {
        ModifiedContent(content: self, modifier: FontWithLineHeight(props: props))
    }

    func getRootViewController() -> UIViewController {
        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return .init()
        }

        guard let root = screen.windows.first?.rootViewController else {
            return .init()
        }

        return root
    }

    func largShadow(_ enabled: Bool = true) -> some View {
        modifier(ShadowModifier(enabled: enabled))
    }

    func inputBorder() -> some View {
        modifier(InputBorder())
    }
    
    func card(small: Bool = false) -> some View {
        return self
            .padding(.horizontal, Theme.Spacing.xlarge)
            .padding(.vertical, small ? Theme.Spacing.xlarge : Theme.Spacing.xxlarge)
            .background(Theme.Colors.SurfacePrimary100)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xlarge))
    }
    
    func detailCard() -> some View {
        return self
            .padding(.vertical, Theme.Spacing.medium)
            .padding(.horizontal, Theme.Spacing.medium)
            .background(Theme.Colors.SurfacePrimary100)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
    }
    
    func sheet() -> some View {
        return self
        .padding(.top, Theme.Spacing.medium)
        .padding(.horizontal, Theme.Spacing.small)
        .background(Theme.Colors.SurfaceNeutral05.ignoresSafeArea(edges: .all))
    }
    
    func wellingTextFieldStyleWithTitle(focused: Bool, disabled: Bool = false, error: Bool = false) -> some View {
        return self
            .padding(.vertical, Theme.Spacing.xsmall)
            .padding(.horizontal, Theme.Spacing.medium)
            .background(disabled ? Theme.Colors.SurfaceNeutral3 : Theme.Colors.SurfaceNeutral05)
            .foregroundStyle(Theme.Colors.TextPrimary100)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .inset(by: 1)
                .stroke(error ? Theme.Colors.SemanticError : focused ? Theme.Colors.SemanticInfoFocus : Theme.Colors.BorderNeutral2, lineWidth: 2))
    }
    
    func wellingTextFieldStyle(focused: Bool, disabled: Bool = false, error: Bool = false) -> some View {
        return self
            .padding(Theme.Spacing.medium)
            .background(disabled ? Theme.Colors.SurfaceNeutral3 : Theme.Colors.SurfaceNeutral05)
            .foregroundStyle(Theme.Colors.TextPrimary100)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .inset(by: 1)
                .stroke(error ? Theme.Colors.SemanticError : focused ? Theme.Colors.SemanticInfoFocus : Theme.Colors.BorderNeutral2, lineWidth: 2))
    }
    
    func signInEmailTextFieldStyle(focused: Bool, disabled: Bool = false) -> some View {
        return self
            .padding(.vertical, Theme.Spacing.medium)
            .padding(.horizontal, Theme.Spacing.medium)
            .background(disabled ? Theme.Colors.SurfaceNeutral3 : Theme.Colors.SurfaceNeutral05)
            .foregroundStyle(Theme.Colors.TextPrimary100)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .inset(by: 1)
                .stroke(focused ? Theme.Colors.SemanticInfoFocus : Theme.Colors.BorderNeutral2, lineWidth: 2))
    }
    
    func withoutDefaultNavBar() -> some View {
        return self
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarHidden(true)
    }
    
    func navbar() -> some View {
        return self
            .padding(.horizontal, Theme.Spacing.horizontalPadding)
            .padding(.top, Theme.Spacing.medium)
            .padding(.bottom, Theme.Spacing.large)
            .background(.clear)
    }
    
    func sheetNavbar() -> some View {
        return self
            .padding(.bottom, Theme.Spacing.large)
    }
    
    func iconButton() -> some View {
        return self
         .padding(.horizontal, Theme.Spacing.medium)
         .padding(.vertical,Theme.Spacing.xsmall)
         .background(Theme.Colors.SurfaceNeutral2)
         .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.full))
    }
    
    func primaryButton() -> some View {
        return self
            .foregroundStyle(Theme.Colors.TextPrimary100)
            .padding(.horizontal, Theme.Spacing.large)
            .padding(.vertical, Theme.Spacing.medium)
            .background(Theme.Colors.SurfaceSecondary100)
            .cornerRadius(Theme.Radius.full)
    }

    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct SafeAreaBottomPadding: ViewModifier {
    func body(content: Content) -> some View {
        if UIApplication.shared.windows.first?.safeAreaInsets.bottom == 0 {
            content.padding(.bottom)
        } else {
            content
        }
    }
}

extension View {
    func safeAreaBottomPadding() -> some View {
        modifier(SafeAreaBottomPadding())
    }
}

struct GetHeightModifier: ViewModifier {
    @Binding var height: CGFloat

    func body(content: Content) -> some View {
        content.background(
            GeometryReader { geo -> Color in
                DispatchQueue.main.async {
                    height = geo.size.height
                }
                return Color.clear
            }
        )
    }
}
