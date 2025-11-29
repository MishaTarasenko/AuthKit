import SwiftUI

/// The root coordinator view that orchestrates the authentication flow of the application.
///
/// `AuthCoordinator` acts as the entry point of your app's UI. It automatically manages the visibility
/// of the main content versus the login screen based on the user's authentication state.
///
/// It also initializes the `AuthManager` and injects it into the SwiftUI environment, making it available
/// to all child views via `@EnvironmentObject`.
///
/// ### Usage Example:
/// ```swift
/// @main
/// struct MyApp: App {
///     var body: some Scene {
///         WindowGroup {
///             AuthCoordinator(roleType: MyAppRole.self) {
///                 // Shown when logged in
///                 DashboardView()
///             } loginContent: {
///                 // Shown when logged out
///                 LoginScreen(roleType: MyAppRole.self) { ... }
///             }
///         }
///     }
/// }
/// ```
public struct AuthCoordinator<
    Role: UserRole,
    MainContent: View,
    LoginContent: View
>: View {

    /// The source of truth for authentication state.
    /// Owned by the coordinator and shared via environment.
    @StateObject private var authManager = AuthManager<Role>()

    private let mainContent: () -> MainContent
    private let loginContent: () -> LoginContent

    /// Creates a new authentication coordinator.
    ///
    /// - Parameters:
    ///   - roleType: The concrete type of the `UserRole` enum used in your app.
    ///               Pass `.self` (e.g., `AppRole.self`) to help the compiler infer the generic type.
    ///   - mainContent: A view builder closure that returns the content to display when the user is **authenticated**.
    ///   - loginContent: A view builder closure that returns the content to display when the user is **not authenticated**.
    public init(
        roleType: Role.Type = Role.self,
        @ViewBuilder mainContent: @escaping () -> MainContent,
        @ViewBuilder loginContent: @escaping () -> LoginContent
    ) {
        self.mainContent = mainContent
        self.loginContent = loginContent
    }

    public var body: some View {
        Group {
            if authManager.isLoggedIn {
                mainContent()
                    .transition(.opacity.animation(.easeInOut))
            } else {
                loginContent()
                    .transition(.opacity.animation(.easeInOut))
            }
        }
        .environmentObject(authManager)
    }
}
