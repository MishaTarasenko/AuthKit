import SwiftUI

/// A container view that implements Role-Based Access Control (RBAC) by conditionally displaying content.
///
/// `RoleProtectedView` listens to the `AuthManager` in the environment and checks if the current user's role
/// matches any of the roles specified in the `allowed` set.
///
/// Use this view to hide sensitive UI elements (like "Delete" buttons or Admin panels) from unauthorized users.
/// You can either hide the content completely or provide a `fallback` view (e.g., a "Access Denied" message).
///
/// ### Usage Example:
/// ```swift
/// VStack {
///     // Example 1: Completely hide content (if not Admin)
///     RoleProtectedView(allowed: [.admin], roleType: AppRole.self) {
///         Button("Delete Database") { ... }
///     }
///
///     // Example 2: Show alternative content (if not Premium)
///     RoleProtectedView(allowed: [.premium], roleType: AppRole.self) {
///         AdvancedChart()
///     } fallback: {
///         Text("Upgrade to Premium to see charts")
///             .foregroundColor(.secondary)
///     }
/// }
/// ```
public struct RoleProtectedView<Role: UserRole, Content: View>: View {

    @EnvironmentObject var authManager: AuthManager<Role>

    private let allowedRoles: Set<Role>
    private let content: () -> Content
    private let fallback: AnyView?

    /// Creates a view that is visible only to users with specific roles.
    /// If the user does not have permission, nothing is rendered (EmptyView).
    ///
    /// - Parameters:
    ///   - allowed: A set of roles that are granted access to the content.
    ///   - roleType: The concrete type of your `UserRole`. Pass `.self` to help the compiler.
    ///   - content: The UI to display if the user is authorized.
    public init(
        allowed: Set<Role>,
        roleType: Role.Type = Role.self,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.allowedRoles = allowed
        self.content = content
        self.fallback = nil
    }

    /// Creates a view that displays content to authorized users, or a fallback view to unauthorized users.
    ///
    /// - Parameters:
    ///   - allowed: A set of roles that are granted access to the content.
    ///   - roleType: The concrete type of your `UserRole`. Pass `.self` to help the compiler.
    ///   - content: The UI to display if the user is authorized.
    ///   - fallback: The UI to display if the user is **not** authorized (e.g., a lock icon or placeholder).
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
