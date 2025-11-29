import Foundation

/// A protocol defining the requirements for a user role model within the authentication framework.
///
/// By conforming to `UserRole`, you allow `AuthManager` to handle your custom application roles
/// (e.g., `Student`, `Teacher`, `Manager`) generically.
///
/// The type must conform to:
/// * `Codable`: To allow the framework to securely save and restore the role from the Keychain.
/// * `Hashable`: To allow roles to be stored in sets (used in `RoleProtectedView`).
/// * `Sendable`: To ensure thread safety when passing roles across concurrency contexts.
///
/// ### Usage Example:
/// ```swift
/// enum AppRole: String, UserRole {
///     case superAdmin
///     case editor
///     case viewer
///     case guest
///
///     static var guestRole: AppRole { .guest }
/// }
/// ```
public protocol UserRole: Codable, Hashable, Sendable {

    /// The default fallback role used when the user is not logged in or the session is invalid.
    /// Typically represents a "Guest" or "Anonymous" state.
    static var guestRole: Self { get }
}

/// A standard, ready-to-use implementation of `UserRole`.
///
/// Use `DefaultRole` if your application has simple requirements and only needs to distinguish
/// between an Administrator, a Standard User, and a Guest.
///
/// If your app requires domain-specific roles (e.g., `Driver` vs `Passenger`),
/// define your own enum conforming to `UserRole` instead.
public enum DefaultRole: String, UserRole {
    /// Represents a user with elevated privileges.
    case admin

    /// Represents a standard authenticated user.
    case user

    /// Represents an unauthenticated user.
    case guest

    /// Returns `.guest` as the default fallback role.
    public static var guestRole: DefaultRole {
        return .guest
    }
}
