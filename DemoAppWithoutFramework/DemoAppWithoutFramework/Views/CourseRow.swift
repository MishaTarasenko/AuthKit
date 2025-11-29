import SwiftUI

struct CourseRow: View {
    let title: String
    let progress: Double

    var body: some View {
        HStack {
            Image(systemName: "book.fill")
                .foregroundColor(.blue)
                .padding(10)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading) {
                Text(title).fontWeight(.medium)
                ProgressView(value: progress)
                    .tint(.blue)
            }
            Spacer()
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
