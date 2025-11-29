import AuthenticationServices
import Combine
import Foundation

/// The central controller responsible for managing the authentication lifecycle and user session.
///
/// `AuthManager` handles the OAuth 2.0 and OpenID Connect (OIDC) flows via `ASWebAuthenticationSession`.
/// It manages the state of the current user (`isLoggedIn`, `role`) and securely stores credentials using the `TokenManager`.
///
/// This class is generic over a `Role` type, allowing you to define your own role system (e.g., Admin, Student, Teacher).
///
/// ### Usage Example:
/// ```swift
/// @StateObject var authManager = AuthManager<AppRole>()
///
/// // Initiating login
/// authManager.login(with: googleConfig) { data in
///     // 1. Decode JSON
///     guard let user = try? JSONDecoder().decode(GoogleUser.self, from: data) else { return nil }
///
///     // 2. Map to Role
///     return user.email.contains("admin") ? .admin : .user
/// }
/// ```
@MainActor
public class AuthManager<Role: UserRole>: NSObject, ObservableObject,
    ASWebAuthenticationPresentationContextProviding
{

    /// Indicates whether a user is currently authenticated.
    @Published public private(set) var isLoggedIn: Bool = false
    /// Indicates whether an authentication network request or flow is in progress.
    /// Use this to show spinners or disable buttons.
    @Published public private(set) var isLoading: Bool = false
    /// Contains a readable error message if the last operation failed. `nil` if no error occurred.
    @Published public private(set) var errorMessage: String?
    /// The current role of the user. Defaults to `.guestRole` if not logged in.
    @Published public private(set) var role: Role = Role.guestRole

    private var accessToken: String?

    private let tokenManager = TokenManager()

    /// Initializes the manager and immediately attempts to restore a session from the Keychain.
    public override init() {
        super.init()
        restoreSession()
    }

    private func restoreSession() {
        if let savedToken = tokenManager.getToken() {
            self.accessToken = savedToken
            self.isLoggedIn = true

            if let savedRole: Role = tokenManager.getRole() {
                self.role = savedRole
            } else {
                // Token found, but role is missing. Fallback to guest.
                // TODO: Consider fetching fresh user info from the API here.
            }
        }
    }

    /// Starts the OAuth 2.0 or OpenID Connect authentication flow.
    ///
    /// This method opens a system browser to authenticate the user. Upon success, it exchanges the authorization code
    /// for an access token (and ID token if OIDC is used), fetches user data, and uses the `roleMapper` to determine the user's role.
    ///
    /// - Parameters:
    ///   - config: The configuration object containing OAuth URLs, Client IDs, and scopes.
    ///   - roleMapper: A closure that takes the raw user data (JSON `Data`) and returns a `Role`.
    ///                 If this closure returns `nil`, the login is considered failed.
    public func login(
        with config: OAuthConfig,
        roleMapper: @escaping (Data) -> Role?
    ) {
        isLoading = true
        errorMessage = nil

        var components = URLComponents(
            url: config.authUrl,
            resolvingAgainstBaseURL: true
        )!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: config.clientId),
            URLQueryItem(name: "redirect_uri", value: config.redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: config.scope),
        ]

        guard let finalAuthURL = components.url else {
            fail(with: "Invalid Auth URL")
            return
        }

        let scheme =
            URL(string: config.redirectUri)?.scheme
            ?? config.redirectUri.components(separatedBy: ":").first

        guard let finalScheme = scheme else {
            fail(with: "Invalid Redirect URI Scheme")
            return
        }

        let session = ASWebAuthenticationSession(
            url: finalAuthURL,
            callbackURLScheme: finalScheme
        ) { [weak self] callbackURL, error in
            guard let self = self else { return }

            if let error = error {
                self.fail(
                    with: "Login cancelled: \(error.localizedDescription)"
                )
                return
            }

            guard let callbackURL = callbackURL,
                let queryItems = URLComponents(
                    url: callbackURL,
                    resolvingAgainstBaseURL: true
                )?.queryItems,
                let code = queryItems.first(where: { $0.name == "code" })?.value
            else {
                self.fail(with: "No code found")
                return
            }

            Task {
                await self.processLogin(
                    code: code,
                    config: config,
                    roleMapper: roleMapper
                )
            }
        }

        session.presentationContextProvider = self
        session.start()
    }

    private func processLogin(
        code: String,
        config: OAuthConfig,
        roleMapper: @escaping (Data) -> Role?
    ) async {
        var request = URLRequest(url: config.tokenUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(
            "application/x-www-form-urlencoded",
            forHTTPHeaderField: "Content-Type"
        )

        var bodyComponents = [
            "client_id": config.clientId,
            "code": code,
            "grant_type": "authorization_code",
            "redirect_uri": config.redirectUri,
        ]

        if let secret = config.clientSecret {
            bodyComponents["client_secret"] = secret
        }

        request.httpBody =
            bodyComponents
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        do {
            let (tokenData, tokenResponse) = try await URLSession.shared.data(
                for: request
            )
            guard (tokenResponse as? HTTPURLResponse)?.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }

            let tokenObj = try JSONDecoder().decode(
                TokenResponse.self,
                from: tokenData
            )

            var roleData: Data?

            if let idToken = tokenObj.idToken,
                let decodedData = JWTHelper.decode(jwtToken: idToken)
            {
                roleData = decodedData
            } else {
                var userRequest = URLRequest(url: config.userInfoUrl)
                userRequest.addValue(
                    "Bearer \(tokenObj.accessToken)",
                    forHTTPHeaderField: "Authorization"
                )

                let (data, userResponse) = try await URLSession.shared.data(
                    for: userRequest
                )
                if (userResponse as? HTTPURLResponse)?.statusCode == 200 {
                    roleData = data
                }
            }

            guard let finalUserData = roleData else {
                fail(with: "Failed to fetch user info")
                return
            }

            await MainActor.run {
                if let mappedRole = roleMapper(finalUserData) {
                    self.role = mappedRole
                    self.accessToken = tokenObj.accessToken
                    self.isLoggedIn = true
                    self.tokenManager.save(
                        token: tokenObj.accessToken,
                        role: mappedRole
                    )
                } else {
                    self.errorMessage = "Could not map user data to a role"
                }
                self.isLoading = false
            }

        } catch {
            fail(with: "Login failed: \(error.localizedDescription)")
        }
    }

    /// Logs the user out by clearing the session state and removing credentials from the Keychain.
    public func logout() {
        self.isLoggedIn = false
        self.accessToken = nil
        self.role = Role.guestRole

        tokenManager.clear()
    }

    private func fail(with message: String) {
        Task { @MainActor in
            self.errorMessage = message
            self.isLoading = false
        }
    }

    public func presentationAnchor(for session: ASWebAuthenticationSession)
        -> ASPresentationAnchor
    {
        return ASPresentationAnchor()
    }
}

extension AuthManager {

    /// Checks if the current user holds a specific role.
    ///
    /// - Parameter targetRole: The role to check against.
    /// - Returns: `true` if the user has the specified role, otherwise `false`.
    public func hasRole(_ targetRole: Role) -> Bool {
        return self.role == targetRole
    }

    /// Checks if the current user holds *any* of the specified roles.
    ///
    /// Useful for restricting access to a view that is shared by multiple high-level roles (e.g., both Admin and Editor).
    ///
    /// - Parameter roles: A set of allowed roles.
    /// - Returns: `true` if the user's role is contained within the set.
    public func hasAnyRole(_ roles: Set<Role>) -> Bool {
        return roles.contains(self.role)
    }
}
