import SwiftUI

public struct LogInButton: View {

    private let text: String
    private let color: Color
    private let icon: Image
    private let action: () -> Void

    public init(
        text: String,
        color: Color,
        icon: Image,
        action: @escaping () -> Void
    ) {
        self.text = text
        self.color = color
        self.icon = icon
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                icon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                
                Text(text)
                    .fontWeight(.semibold)
                    .font(.body)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 3)
        }
    }
}
