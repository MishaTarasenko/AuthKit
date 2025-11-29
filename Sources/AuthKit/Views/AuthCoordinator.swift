import SwiftUI

public struct AuthCoordinator<
    Role: UserRole,
    MainContent: View,
    LoginContent: View
>: View {

    @StateObject private var authManager = AuthManager<Role>()

    private let mainContent: () -> MainContent
    private let loginContent: () -> LoginContent

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
