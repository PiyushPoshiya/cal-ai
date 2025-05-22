import SwiftUI

public struct Effect {
    /// Namespace to prevent naming collisions.
    ///
    /// Xcode's autocomplete allows for easy discovery of design system effects.
    /// At any call site that requires an effect, type `Effect.DesignSystem.<esc>`
    public struct DesignSystem {

        public struct Xxsmall: ViewModifier {
            public func body(content: Content) -> some View {
                return content
                    .shadow(color: Color(red:0, green: 0, blue: 0, opacity: 0.05000000074505806), radius: 2, x: 0, y:2)
            }
            public init() {}
        }

        public struct Xsmall: ViewModifier {
            public func body(content: Content) -> some View {
                return content
                    .shadow(color: Color(red:0, green: 0, blue: 0, opacity: 0.019999999552965164), radius: 2, x: 0, y:2)
                    .shadow(color: Color(red:0, green: 0, blue: 0, opacity: 0.07999999821186066), radius: 4, x: 0, y:2)
            }
            public init() {}
        }

        public struct Small: ViewModifier {
            public func body(content: Content) -> some View {
                return content
                    .shadow(color: Color(red:0, green: 0, blue: 0, opacity: 0.05999999865889549), radius: 2, x: 0, y:2)
                    .shadow(color: Color(red:0, green: 0, blue: 0, opacity: 0.10000000149011612), radius: 8, x: 0, y:4)
            }
            public init() {}
        }

        public struct Medium: ViewModifier {
            public func body(content: Content) -> some View {
                return content
                    .shadow(color: Color(red:0, green: 0, blue: 0, opacity: 0.029999999329447746), radius: 8, x: 0, y:4)
                    .shadow(color: Color(red:0, green: 0, blue: 0, opacity: 0.07999999821186066), radius: 16, x: 0, y:12)
            }
            public init() {}
        }

        public struct Large: ViewModifier {
            public func body(content: Content) -> some View {
                return content
                    .shadow(color: Color(red:0, green: 0, blue: 0, opacity: 0.029999999329447746), radius: 8, x: 0, y:8)
                    .shadow(color: Color(red:0, green: 0, blue: 0, opacity: 0.07999999821186066), radius: 24, x: 0, y:20)
            }
            public init() {}
        }

        public struct Xlarge: ViewModifier {
            public func body(content: Content) -> some View {
                return content
                    .shadow(color: Color(red:0, green: 0, blue: 0, opacity: 0.019999999552965164), radius: 8, x: 0, y:4)
                    .shadow(color: Color(red:0, green: 0, blue: 0, opacity: 0.18000000715255737), radius: 48, x: 0, y:24)
            }
            public init() {}
        }

        public struct Xxlarge: ViewModifier {
            public func body(content: Content) -> some View {
                return content
                    .shadow(color: Color(red:0, green: 0, blue: 0, opacity: 0.019999999552965164), radius: 8, x: 0, y:8)
                    .shadow(color: Color(red:0, green: 0, blue: 0, opacity: 0.18000000715255737), radius: 64, x: 0, y:32)
            }
            public init() {}
        }

    }
}

public extension View {
    func xxsmall() -> some View {modifier(Effect.DesignSystem.Xxsmall())}
    func xsmall() -> some View {modifier(Effect.DesignSystem.Xsmall())}
    func small() -> some View {modifier(Effect.DesignSystem.Small())}
    func medium() -> some View {modifier(Effect.DesignSystem.Medium())}
    func large() -> some View {modifier(Effect.DesignSystem.Large())}
    func xlarge() -> some View {modifier(Effect.DesignSystem.Xlarge())}
    func xxlarge() -> some View {modifier(Effect.DesignSystem.Xxlarge())}
}