import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            List {
                NavigationLink("Agents") {
                    PlaceholderView(title: "Agents")
                }

                NavigationLink("Prompts") {
                    PlaceholderView(title: "Prompts")
                }

                NavigationLink("Workflows") {
                    PlaceholderView(title: "Workflows")
                }

                NavigationLink("Handoffs") {
                    PlaceholderView(title: "Handoffs")
                }

                NavigationLink("Settings") {
                    PlaceholderView(title: "Settings")
                }
            }
            .navigationTitle("Agent Manager")
        } detail: {
            PlaceholderView(title: "Agent Manager")
        }
    }
}

struct PlaceholderView: View {
    let title: String

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.largeTitle)
                .fontWeight(.semibold)

            Text("M01 native macOS foundation.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    ContentView()
}
