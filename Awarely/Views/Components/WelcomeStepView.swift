import SwiftUI

struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // App Icon and Title
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 50, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(spacing: 12) {
                    Text("Awarely")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("Your mindful companion for \n awareness-driven productivity")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            // Key Features
            VStack(spacing: 20) {
                FeatureRow(icon: "clock", title: "Gentle Reminders", description: "Check in every 30 minutes")
                FeatureRow(icon: "list.bullet", title: "Activity Logging", description: "Track what matters to you")
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    WelcomeStepView()
}
