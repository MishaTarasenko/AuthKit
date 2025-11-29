import AuthenticationServices
import Combine
import SwiftUI

@MainActor
class AppViewModel: NSObject, ObservableObject,
    ASWebAuthenticationPresentationContextProviding
{

    @Published var role: UserRole = .guest
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = false

    private let clientId =
        "282467819494-dknbr1vbam4r6g7bqmvvonth5g1aj8ag.apps.googleusercontent.com"
    private let redirectUri =
        "com.googleusercontent.apps.282467819494-dknbr1vbam4r6g7bqmvvonth5g1aj8ag:/oauth2redirect/google"

    override init() {
        super.init()
        checkSession()
    }

    func loginWithGoogle() {
        isLoading = true

        var components = URLComponents(
            string: "https://accounts.google.com/o/oauth2/v2/auth"
        )!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "openid profile email"),
        ]

        guard let authURL = components.url else { return }

        let scheme =
            redirectUri.components(separatedBy: ":").first ?? redirectUri

        let session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: scheme
        ) { [weak self] callbackURL, error in
            guard let self = self else { return }

            if let error = error {
                print("Login error: \(error.localizedDescription)")
                Task { @MainActor in self.isLoading = false }
                return
            }

            guard let callbackURL = callbackURL,
                let queryItems = URLComponents(
                    url: callbackURL,
                    resolvingAgainstBaseURL: true
                )?.queryItems,
                let code = queryItems.first(where: { $0.name == "code" })?.value
            else {
                Task { @MainActor in self.isLoading = false }
                return
            }

            Task {
                await self.exchangeCodeForToken(code: code)
            }
        }

        session.presentationContextProvider = self
        session.start()
    }

    private func exchangeCodeForToken(code: String) async {
        let tokenUrl = URL(string: "https://oauth2.googleapis.com/token")!
        var request = URLRequest(url: tokenUrl)
        request.httpMethod = "POST"
        request.setValue(
            "application/x-www-form-urlencoded",
            forHTTPHeaderField: "Content-Type"
        )

        let body = [
            "client_id": clientId,
            "code": code,
            "grant_type": "authorization_code",
            "redirect_uri": redirectUri,
        ]

        request.httpBody = body.map { "\($0.key)=\($0.value)" }.joined(
            separator: "&"
        ).data(using: .utf8)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)

            if let json = try? JSONSerialization.jsonObject(with: data)
                as? [String: Any],
                let accessToken = json["access_token"] as? String
            {
                await fetchUserInfo(token: accessToken)
            }
        } catch {
            print("Token Error: \(error)")
            Task { @MainActor in self.isLoading = false }
        }
    }

    private func fetchUserInfo(token: String) async {
        let userUrl = URL(
            string: "https://www.googleapis.com/oauth2/v3/userinfo"
        )!
        var request = URLRequest(url: userUrl)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let user = try JSONDecoder().decode(GoogleUser.self, from: data)

            print("Logged in as: \(user.email)")

            let determinedRole: UserRole
            if user.email.contains("misha") {
                determinedRole = .admin
            } else if user.email.contains("teacher") {
                determinedRole = .teacher
            } else {
                determinedRole = .student
            }

            await MainActor.run {
                self.role = determinedRole
                self.isLoggedIn = true
                self.isLoading = false
                self.saveSession(role: determinedRole)
            }

        } catch {
            print("User Info Error: \(error)")
            Task { @MainActor in self.isLoading = false }
        }
    }

    private func saveSession(role: UserRole) {
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        UserDefaults.standard.set(role.rawValue, forKey: "savedRole")
    }

    private func checkSession() {
        if UserDefaults.standard.bool(forKey: "isLoggedIn"),
            let roleString = UserDefaults.standard.string(forKey: "savedRole"),
            let savedRole = UserRole(rawValue: roleString)
        {
            self.role = savedRole
            self.isLoggedIn = true
        }
    }

    func logout() {
        UserDefaults.standard.removeObject(forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "savedRole")
        self.role = .guest
        self.isLoggedIn = false
    }

    func presentationAnchor(for session: ASWebAuthenticationSession)
        -> ASPresentationAnchor
    {
        return ASPresentationAnchor()
    }
}
