import SwiftUI

public struct LoginScreen<Role: UserRole, Content: View>: View {

    @EnvironmentObject var authManager: AuthManager<Role>

    private let title: String
    private let subtitle: String?
    private let buttonsContent: () -> Content

    public init(
        title: String,
        subtitle: String? = nil,
        roleType: Role.Type = Role.self,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.buttonsContent = content
    }

    public var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 30) {

                VStack(spacing: 10) {
                    Text(title)
                        .font(.system(size: 32, weight: .bold))

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 50)

                VStack(spacing: 16) {
                    buttonsContent()
                }
                .padding(.horizontal, 24)

                if let error = authManager.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .transition(.opacity)
                }

                Spacer()
            }
            .disabled(authManager.isLoading)
            .blur(radius: authManager.isLoading ? 3 : 0)

            if authManager.isLoading {
                ZStack {
                    Color.black.opacity(0.2)
                        .edgesIgnoringSafeArea(.all)
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                }
            }
        }
    }
}
