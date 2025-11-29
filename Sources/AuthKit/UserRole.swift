import Foundation

public protocol UserRole: Codable, Hashable, Sendable {

    static var guestRole: Self { get }
}

public enum DefaultRole: String, UserRole {
    case admin
    case user
    case guest

    public static var guestRole: DefaultRole {
        return .guest
    }
}
