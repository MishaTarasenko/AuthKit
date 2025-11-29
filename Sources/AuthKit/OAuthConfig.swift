import Foundation

public struct OAuthConfig {
    public let authUrl: URL
    public let tokenUrl: URL
    public let userInfoUrl: URL
    public let clientId: String
    public let clientSecret: String?
    public let redirectUri: String
    public let scope: String

    public init(
        authUrl: URL,
        tokenUrl: URL,
        userInfoUrl: URL,
        clientId: String,
        clientSecret: String? = nil,
        redirectUri: String,
        scope: String = ""
    ) {
        self.authUrl = authUrl
        self.tokenUrl = tokenUrl
        self.userInfoUrl = userInfoUrl
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.redirectUri = redirectUri
        self.scope = scope
    }
}
