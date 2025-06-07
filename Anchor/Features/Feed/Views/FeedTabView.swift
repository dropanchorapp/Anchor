import SwiftUI
import AnchorKit

struct FeedTabView: View {
    @Environment(BlueskyService.self) private var blueskyService
    
    var body: some View {
        VStack(spacing: 16) {
            if blueskyService.isAuthenticated {
                VStack(spacing: 12) {
                    Text("🌊 Following Feed")
                        .font(.headline)
                    
                    Text("Check-ins from people you follow")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    
                    // Placeholder for feed content
                    VStack(spacing: 8) {
                        Text("Coming soon!")
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                        Text("This will show recent check-ins from people you follow on Bluesky.")
                            .foregroundStyle(.tertiary)
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "person.slash")
                        .foregroundStyle(.orange)
                        .font(.title)
                    
                    Text("Sign in to see your feed")
                        .font(.headline)
                    
                    Text("Connect your Bluesky account to see check-ins from people you follow.")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                    
                    Text("Click the gear button to open Settings")
                        .foregroundStyle(.blue)
                        .font(.caption2)
                }
                .padding()
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    FeedTabView()
        .environment(BlueskyService())
} 