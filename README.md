# AuthKit

A modern, type-safe Swift framework for OAuth 2.0 and OpenID Connect authentication in iOS applications. AuthKit provides a complete solution for managing user authentication, sessions, and role-based access control with minimal setup.

## Features

- ✅ **OAuth 2.0 & OpenID Connect Support** - Works with any OAuth provider (Google, GitHub, Facebook, custom backends)
- 🔐 **Secure Token Storage** - Automatic keychain integration for secure credential persistence
- 🎭 **Role-Based Access Control (RBAC)** - Generic role system with built-in UI components
- 🔄 **Session Management** - Automatic session restoration across app launches
- 🎨 **Pre-built UI Components** - Ready-to-use login screens and buttons
- ⚡️ **SwiftUI Native** - Built with modern SwiftUI and Combine
- 🧩 **Type-Safe** - Fully generic architecture supporting custom role types
- 📱 **ASWebAuthenticationSession** - Native iOS authentication flow

## Installation

### Swift Package Manager

Add AuthKit to your project using Xcode:

1. File → Add Package Dependencies
2. Enter the repository URL
3. Select the version you want to use

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/MishaTarasenko/AuthKit", from: "1.0.0")
]
```

### CocoaPods

Add AuthKit to your `Podfile`:

```ruby
pod 'AuthKit', '~> 1.0'
```

Then run:

```bash
pod install
```

### Requirements

- iOS 15.0+
- Swift 5.5+
- Xcode 13.0+

## Quick Start

### 1. Define Your Roles

Create an enum conforming to `UserRole`:

```swift
enum AppRole: String, UserRole {
    case admin
    case editor
    case viewer
    case guest
    
    static var guestRole: AppRole { .guest }
}
```

### 2. Configure Your OAuth Provider

```swift
let googleConfig = OAuthConfig(
    authUrl: URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!,
    tokenUrl: URL(string: "https://oauth2.googleapis.com/token")!,
    userInfoUrl: URL(string: "https://www.googleapis.com/oauth2/v2/userinfo")!,
    clientId: "YOUR_CLIENT_ID",
    redirectUri: "com.yourapp://callback",
    scope: "openid profile email"
)
```

### 3. Set Up the App Structure

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            AuthCoordinator(roleType: AppRole.self) {
                // Main app content (shown when logged in)
                DashboardView()
            } loginContent: {
                // Login screen (shown when logged out)
                LoginView()
            }
        }
    }
}
```

### 4. Create a Login Screen

```swift
struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager<AppRole>
    
    var body: some View {
        LoginScreen(
            title: "Welcome to MyApp",
            subtitle: "Sign in to continue",
            roleType: AppRole.self
        ) {
            LogInButton(
                text: "Continue with Google",
                color: .blue,
                icon: Image(systemName: "person.circle")
            ) {
                authManager.login(with: googleConfig) { userData in
                    // Map user data to role
                    guard let user = try? JSONDecoder().decode(GoogleUser.self, from: userData) else {
                        return nil
                    }
                    return user.isAdmin ? .admin : .viewer
                }
            }
        }
    }
}
```

## Usage Examples

### Access Authentication State

```swift
struct DashboardView: View {
    @EnvironmentObject var authManager: AuthManager<AppRole>
    
    var body: some View {
        VStack {
            Text("Current role: \(authManager.role.rawValue)")
            
            Button("Log Out") {
                authManager.logout()
            }
        }
    }
}
```

### Role-Based Access Control

```swift
struct AdminPanel: View {
    var body: some View {
        VStack {
            // Only visible to admins
            RoleProtectedView(allowed: [.admin], roleType: AppRole.self) {
                Button("Delete All Data") {
                    // Dangerous action
                }
            }
            
            // Visible to admins and editors, with fallback
            RoleProtectedView(
                allowed: [.admin, .editor],
                roleType: AppRole.self
            ) {
                EditContentView()
            } fallback: {
                Text("You need editor permissions")
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

### Check Roles Programmatically

```swift
if authManager.hasRole(.admin) {
    // Execute admin-only logic
}

if authManager.hasAnyRole([.admin, .editor]) {
    // Execute logic for multiple roles
}
```

### Custom Login Button

```swift
LogInButton(
    text: "Sign in with GitHub",
    color: Color(red: 0.13, green: 0.13, blue: 0.13),
    icon: Image("github-logo").renderingMode(.original)
) {
    authManager.login(with: githubConfig) { data in
        // Custom role mapping logic
        let user = try? JSONDecoder().decode(GitHubUser.self, from: data)
        return user?.type == "organization" ? .admin : .viewer
    }
}
```

## License

AuthKit is available under the MIT license. See the LICENSE file for more info.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.
