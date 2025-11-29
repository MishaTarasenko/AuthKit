import Foundation

/// A configuration object defining the endpoints and credentials for an OAuth 2.0 provider.
///
/// Use this struct to define how `AuthManager` should connect to a specific identity provider
/// (such as Google, GitHub, Facebook, or your own backend).
///
/// ### Usage Example:
/// ```swift
/// let githubConfig = OAuthConfig(
///     authUrl: URL(string: "[https://github.com/login/oauth/authorize](https://github.com/login/oauth/authorize)")!,
///     tokenUrl: URL(string: "[https://github.com/login/oauth/access_token](https://github.com/login/oauth/access_token)")!,
///     userInfoUrl: URL(string: "[https://api.github.com/user](https://api.github.com/user)")!,
///     clientId: "YOUR_CLIENT_ID",
///     clientSecret: "YOUR_CLIENT_SECRET", // Note: Avoid storing secrets in code for production
///     redirectUri: "myapp://callback",
///     scope: "user repo"
/// )
/// ```
public struct OAuthConfig {
    /// The authorization endpoint URL.
    /// This is the page where the user logs in and approves access in the browser.
    public let authUrl: URL

    /// The token exchange endpoint URL.
    /// The framework sends the authorization code here to exchange it for an access token.
    public let tokenUrl: URL

    /// The user info endpoint URL.
    /// Used to fetch user details (JSON) after a successful login.
    /// If the provider supports OpenID Connect, this can be the OIDC UserInfo endpoint.
    public let userInfoUrl: URL

    /// The public identifier for your application, obtained from the provider's developer console.
    public let clientId: String

    /// The client secret, if required by the provider.
    ///
    /// - Warning: Native mobile apps are considered "Public Clients". Storing a secret in the app binary
    /// is generally insecure. Many providers (like Google) do not require a secret for iOS apps.
    /// Only use this if the provider strictly enforces it (e.g., GitHub).
    public let clientSecret: String?

    /// The callback URI where the provider redirects after authentication.
    /// This must match the URL Scheme defined in your `Info.plist`.
    public let redirectUri: String

    /// A space-separated list of permissions requested by the application.
    /// Example: `"openid profile email"`.
    public let scope: String

    /// Creates a new OAuth configuration.
    ///
    /// - Parameters:
    ///   - authUrl: The authorization endpoint URL.
    ///   - tokenUrl: The token exchange endpoint URL.
    ///   - userInfoUrl: The endpoint to fetch user details.
    ///   - clientId: The application's Client ID.
    ///   - clientSecret: The application's Client Secret (optional).
    ///   - redirectUri: The callback URI (e.g., `com.myapp://callback`).
    ///   - scope: The requested scopes (default is empty).
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
