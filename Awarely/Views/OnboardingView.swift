import SwiftUI

struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var userName = ""
    @State private var activeDaysPreset = ActiveDaysPreset.weekdays
    @State private var notificationStartTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    @State private var notificationEndTime = Calendar.current.date(from: DateComponents(hour: 18, minute: 0)) ?? Date()
    @State private var selectedTags: Set<String> = []
    @State private var pushNotificationsEnabled = false
    
    @ObservedObject var coreDataManager = CoreDataManager.shared
    @Environment(\.dismiss) private var dismiss
    
    private let availableTags = [
        "Read", "Exercise", "Meditate", "Work", "Journal", 
        "Practice", "Study", "Walk", "Cook", "Clean"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.secondarySystemBackground).opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress indicator
                    ProgressView(value: Double(currentStep + 1), total: 6)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    
                    // Step content
                    TabView(selection: $currentStep) {
                        WelcomeStepView()
                            .tag(0)
                        
                        NameStepView(userName: $userName)
                            .tag(1)
                        
                        ActiveDaysStepView(activeDaysPreset: $activeDaysPreset)
                            .tag(2)
                        
                        NotificationWindowStepView(
                            startTime: $notificationStartTime,
                            endTime: $notificationEndTime
                        )
                        .tag(3)
                        
                        TagsStepView(
                            selectedTags: $selectedTags,
                            availableTags: availableTags
                        )
                        .tag(4)
                        
                        PushNotificationsStepView(
                            pushNotificationsEnabled: $pushNotificationsEnabled
                        )
                        .tag(5)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentStep)
                    
                    // Navigation buttons
                    HStack(spacing: 16) {
                        if currentStep > 0 {
                            Button("Back") {
                                withAnimation {
                                    currentStep -= 1
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            
                            Spacer()
                            
                            if currentStep < 5 {
                                Button("Next") {
                                    withAnimation {
                                        currentStep += 1
                                    }
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                .disabled(!canProceedToNext)
                            } else {
                                Button("Get Started") {
                                    completeOnboarding()
                                }
                                .buttonStyle(PrimaryButtonStyle())
                            }
                        } else {
                            // Center the Next button on the first step
                            if currentStep < 5 {
                                Button("Next") {
                                    withAnimation {
                                        currentStep += 1
                                    }
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                .disabled(!canProceedToNext)
                            } else {
                                Button("Get Started") {
                                    completeOnboarding()
                                }
                                .buttonStyle(PrimaryButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private var canProceedToNext: Bool {
        switch currentStep {
        case 0: return true
        case 1: return !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 2: return true
        case 3: return true
        case 4: return !selectedTags.isEmpty
        default: return true
        }
    }
    
    private func completeOnboarding() {
        // Save all onboarding data
        let userProfile = coreDataManager.fetchOrCreateUserProfile()
        userProfile.name = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        userProfile.notificationEnabled = pushNotificationsEnabled
        userProfile.notificationStartTime = notificationStartTime
        userProfile.notificationEndTime = notificationEndTime
        userProfile.customTags = Array(selectedTags) as NSArray
        
        // Note: reminderInterval is not set during onboarding - it keeps the default 30 minutes
        // The active days preset is stored separately and can be used for other features later
        
        coreDataManager.saveUserProfile()
        
        // Post notification to inform ContentView that onboarding was completed
        NotificationCenter.default.post(name: .profileCreated, object: nil)
        
        // Dismiss onboarding
        dismiss()
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
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
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.blue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.blue, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    OnboardingView()
}
