import SwiftUI

public struct RoleProtectedView<Role: UserRole, Content: View>: View {

    @EnvironmentObject var authManager: AuthManager<Role>

    private let allowedRoles: Set<Role>
    private let content: () -> Content
    private let fallback: AnyView?

    public init(
        allowed: Set<Role>,
        roleType: Role.Type = Role.self,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.allowedRoles = allowed
        self.content = content
        self.fallback = nil
    }

    public init<Fallback: View>(
        allowed: Set<Role>,
        roleType: Role.Type = Role.self,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder fallback: @escaping () -> Fallback
    ) {
        self.allowedRoles = allowed
        self.content = content
        self.fallback = AnyView(fallback())
    }

    public var body: some View {
        if authManager.hasAnyRole(allowedRoles) {
            content()
        } else {
            if let fallbackView = fallback {
                fallbackView
            }
        }
    }
}
