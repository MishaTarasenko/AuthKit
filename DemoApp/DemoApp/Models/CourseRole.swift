import AuthKit
import Foundation

enum CourseRole: String, UserRole {
    case admin
    case teacher
    case student
    case guest
    
    static var guestRole: CourseRole {
        return .guest
    }
}
