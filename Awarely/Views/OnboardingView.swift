import SwiftUI

struct OnboardingView: View {
    @State private var userName: String = ""
    @State private var currentStep = 0
    @State private var isProfileCreated = false
    @ObservedObject var coreDataManager = CoreDataManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemBackground).opacity(0.95),
                        Color(.secondarySystemBackground).opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // App Icon and Title
                    VStack(spacing: 20) {
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
                        
                        VStack(spacing: 8) {
                            Text("Welcome to Awarely")
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(.primary)
                            
                            Text("Let's set up your mindfulness journey")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    // Profile Creation Form
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What should we call you?")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.primary)
                            
                            Text("This helps personalize your experience")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        TextField("Enter your name", text: $userName)
                            .textFieldStyle(.roundedBorder)
                            .font(.title3)
                            .padding(.horizontal, 20)
                    }
                    .padding(.horizontal, 20)
                    
                    // Create Profile Button
                    Button(action: createProfile) {
                        HStack {
                            Text("Create Profile")
                                .font(.headline.weight(.semibold))
                            
                            Image(systemName: "arrow.right")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    }
                    .disabled(userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // App Description
                    VStack(spacing: 16) {
                        Text("Awarely helps you build awareness of how you spend your time through mindful logging and gentle reminders.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        HStack(spacing: 20) {
                            FeatureBadge(icon: "clock", title: "Timed Reminders")
                            FeatureBadge(icon: "list.bullet", title: "Activity Logging")
                            FeatureBadge(icon: "chart.line.uptrend.xyaxis", title: "Progress Tracking")
                        }
                    }
                    .padding(.bottom, 40)
                }
                .onTapGesture {
                    // Dismiss keyboard when tapping outside text field
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func createProfile() {
        let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // Create user profile
        let userProfile = coreDataManager.fetchOrCreateUserProfile()
        userProfile.name = trimmedName
        coreDataManager.saveUserProfile()
        
        // Post notification to inform ContentView that profile was created
        NotificationCenter.default.post(name: .profileCreated, object: nil)
    }
}

struct FeatureBadge: View {
    let icon: String
    let title: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    OnboardingView()
}
