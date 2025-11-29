import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all)

            VStack(spacing: 30) {

                VStack(spacing: 10) {
                    Text("EduSystem")
                        .font(.system(size: 32, weight: .bold))
                    Text("Log in to the learning space")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 50)

                Button(action: {
                    viewModel.loginWithGoogle()
                }) {
                    HStack(spacing: 12) {
                        Image("google_logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)

                        Text("Sign in with Google")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(radius: 3)
                }
                .padding(.horizontal, 24)
                .disabled(viewModel.isLoading)

                Spacer()
            }

            if viewModel.isLoading {
                Color.black.opacity(0.2).edgesIgnoringSafeArea(.all)
                ProgressView()
            }
        }
    }
}
