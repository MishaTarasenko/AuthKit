import AuthKit
import SwiftUI

struct ContentView: View {

    let googleConfig = OAuthConfig(
        authUrl: URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!,
        tokenUrl: URL(string: "https://oauth2.googleapis.com/token")!,
        userInfoUrl: URL(
            string: "https://www.googleapis.com/oauth2/v3/userinfo"
        )!,
        clientId:
            "282467819494-dknbr1vbam4r6g7bqmvvonth5g1aj8ag.apps.googleusercontent.com",
        clientSecret: nil,
        redirectUri:
            "com.googleusercontent.apps.282467819494-dknbr1vbam4r6g7bqmvvonth5g1aj8ag:/oauth2redirect/google",
        scope: "openid profile email"
    )

    var body: some View {
        AuthCoordinator(roleType: CourseRole.self) {
            CourseDashboard()
        } loginContent: {
            LoginFlow(googleConfig: googleConfig)
        }
    }
}

#Preview {
    ContentView()
}
