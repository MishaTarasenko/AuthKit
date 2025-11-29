import SwiftUI

/// A standardized, customizable button component designed for authentication actions.
///
/// `LogInButton` provides a consistent look and feel for social login providers (e.g., Google, GitHub, Apple)
/// or custom authentication actions. It automatically handles styling, including corner radius,
/// shadow, and layout spacing.
///
/// The button text is always white. To preserve the original colors of an icon (like the Google logo),
/// apply `.renderingMode(.original)` to the image before passing it.
///
/// ### Usage Example:
/// ```swift
/// VStack {
///     LogInButton(
///         text: "Sign in with Google",
///         color: .blue,
///         icon: Image("google_logo").renderingMode(.original)
///     ) {
///         authManager.login(...)
///     }
///
///     LogInButton(
///         text: "Sign in with GitHub",
///         color: .black,
///         icon: Image(systemName: "github_logo")
///     ) {
///         // Handle GitHub login
///     }
/// }
/// ```
public struct LogInButton: View {

    private let text: String
    private let color: Color
    private let icon: Image
    private let action: () -> Void

    /// Creates a new login button instance.
    ///
    /// - Parameters:
    ///   - text: The label text displayed on the button (e.g., "Continue with GitHub").
    ///   - color: The background color of the button.
    ///   - icon: The image to display next to the text.
    ///   - action: The closure to execute when the button is tapped.
    public init(
        text: String,
        color: Color,
        icon: Image,
        action: @escaping () -> Void
    ) {
        self.text = text
        self.color = color
        self.icon = icon
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                icon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)

                Text(text)
                    .fontWeight(.semibold)
                    .font(.body)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 3)
        }
    }
}
