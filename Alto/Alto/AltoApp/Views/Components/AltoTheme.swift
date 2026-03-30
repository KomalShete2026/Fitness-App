import SwiftUI

enum AltoTheme {
    static let background = Color(red: 0.13, green: 0.10, blue: 0.06)
    static let card = Color(red: 0.18, green: 0.12, blue: 0.07)
    static let cardAlt = Color(red: 0.15, green: 0.17, blue: 0.23)
    static let primary = Color(red: 0.96, green: 0.55, blue: 0.15)
    static let textPrimary = Color(red: 0.93, green: 0.93, blue: 0.95)
    static let textSecondary = Color(red: 0.56, green: 0.58, blue: 0.64)
    static let border = Color(red: 0.35, green: 0.23, blue: 0.13)
}

struct AltoCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(AltoTheme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AltoTheme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

extension View {
    func altoCard() -> some View {
        modifier(AltoCardModifier())
    }
}
