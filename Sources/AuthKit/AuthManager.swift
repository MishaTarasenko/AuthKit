import AuthenticationServices
import Combine
import Foundation

@MainActor
public class AuthManager<Role: UserRole>: NSObject, ObservableObject,
    ASWebAuthenticationPresentationContextProviding
{

    @Published public private(set) var isLoggedIn: Bool = false
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var role: Role = Role.guestRole

    private var accessToken: String?

    private let tokenManager = TokenManager()

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

    public func hasRole(_ targetRole: Role) -> Bool {
        return self.role == targetRole
    }

    public func hasAnyRole(_ roles: Set<Role>) -> Bool {
        return roles.contains(self.role)
    }
}
