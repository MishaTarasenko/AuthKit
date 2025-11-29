import Foundation
import KeychainAccess

class TokenManager {

    private let keychain = Keychain(service: "com.authkit.storage")

    private let tokenKey = "auth_token"
    private let roleKey = "user_role"

    func save<T: Encodable>(token: String, role: T) {
        try? keychain.set(token, key: tokenKey)

        if let roleData = try? JSONEncoder().encode(role),
            let roleString = String(data: roleData, encoding: .utf8)
        {
            try? keychain.set(roleString, key: roleKey)
        }
    }

    func getToken() -> String? {
        return try? keychain.get(tokenKey)
    }

    func getRole<T: Decodable>() -> T? {
        guard let roleString = try? keychain.get(roleKey),
            let roleData = roleString.data(using: .utf8)
        else {
            return nil
        }

        return try? JSONDecoder().decode(T.self, from: roleData)
    }

    func clear() {
        try? keychain.removeAll()
    }
}
