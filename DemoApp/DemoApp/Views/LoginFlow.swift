import AuthKit
import SwiftUI

struct LoginFlow: View {
    @EnvironmentObject var authManager: AuthManager<CourseRole>

    let googleConfig: OAuthConfig

    var body: some View {
        LoginScreen(
            title: "EduSystem",
            subtitle: "Log in to the learning space",
            roleType: CourseRole.self
        ) {
            SocialButton(
                text: "Sign in with Google",
                color: .blue,
                icon: Image("google_logo").renderingMode(.original)
            ) {
                authManager.login(with: googleConfig) { data in
                    do {
                        let user = try JSONDecoder().decode(
                            GoogleUser.self,
                            from: data
                        )
                        print("Login Success: \(user.email)")
                        
                        if user.email.contains("misha") {
                            return .admin
                        } else if user.email.contains("teacher") {
                            return .teacher
                        } else {
                            return .student
                        }
                    } catch {
                        print("Decoding Error: \(error)")
                        return nil
                    }
                }
            }
        }
    }
}
