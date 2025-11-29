import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Welcome!")
                                .font(.headline)
                            Text(
                                "Your role: \(viewModel.role.rawValue.uppercased())"
                            )
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fontWeight(.bold)
                        }
                        Spacer()
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    if viewModel.role == .admin {
                        VStack(alignment: .leading) {
                            Text("🛠 Administrator Panel")
                                .font(.title3).bold()
                                .padding(.bottom, 5)

                            HStack {
                                ActionCard(
                                    icon: "server.rack",
                                    title: "Servers",
                                    color: .purple
                                )
                                ActionCard(
                                    icon: "person.3.fill",
                                    title: "Users",
                                    color: .purple
                                )
                            }

                            Button(action: { print("Delete database tapped") })
                            {
                                Label(
                                    "Delete all courses",
                                    systemImage: "trash"
                                )
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(10)
                            }
                        }
                        .padding()
                        .background(Color.purple.opacity(0.05))
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15).stroke(
                                Color.purple,
                                lineWidth: 1
                            )
                        )
                        .padding(.horizontal)
                    }

                    if viewModel.role == .admin || viewModel.role == .teacher {
                        VStack(alignment: .leading) {
                            Text("🎓 Teachers' room")
                                .font(.title3).bold()
                                .padding(.bottom, 5)

                            HStack {
                                ActionCard(
                                    icon: "plus.circle.fill",
                                    title: "Create a course",
                                    color: .orange
                                )
                                ActionCard(
                                    icon: "checkmark.seal.fill",
                                    title: "Grades",
                                    color: .orange
                                )
                            }
                        }
                        .padding()
                        .background(Color.orange.opacity(0.05))
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15).stroke(
                                Color.orange,
                                lineWidth: 1
                            )
                        )
                        .padding(.horizontal)
                    } else {
                        if viewModel.role == .student {
                            Text(
                                "You do not have permission to create courses."
                            )
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical)
                        }
                    }

                    VStack(alignment: .leading) {
                        Text("📚 My Courses")
                            .font(.title3).bold()

                        LazyVStack {
                            CourseRow(
                                title: "SwiftUI Basics",
                                progress: 0.8
                            )
                            CourseRow(
                                title: "iOS application development",
                                progress: 0.3
                            )
                            CourseRow(
                                title: "Selected frameworks for iOS",
                                progress: 0.1
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Log out") {
                        viewModel.logout()
                    }
                    .tint(.red)
                }
            }
        }
    }
}
