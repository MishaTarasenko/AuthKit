import SwiftUI

struct ActionCard: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(color)
                .padding(.bottom, 5)
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}
