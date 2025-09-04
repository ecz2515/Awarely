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
                    Text("Welcome to Awarely")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("Build awareness of how you spend your time")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Key Features
            VStack(spacing: 20) {
                FeatureRow(icon: "clock", title: "Gentle Reminders", description: "Get mindful prompts throughout your day")
                FeatureRow(icon: "list.bullet", title: "Activity Logging", description: "Track what matters to you")
                FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Progress Insights", description: "See patterns in your daily life")
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.horizontal, 20)
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
            
            Spacer()
        }
    }
}

#Preview {
    WelcomeStepView()
}
