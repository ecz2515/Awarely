import SwiftUI

struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var userName = ""
    @State private var activeDaysPreset = ActiveDaysPreset.weekdays
    @State private var notificationStartTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    @State private var notificationEndTime = Calendar.current.date(from: DateComponents(hour: 18, minute: 0)) ?? Date()
    @State private var selectedTags: Set<String> = []
    @State private var pushNotificationsEnabled = false
    @State private var textFieldBorderFlash = false
    @State private var buttonWiggle = false
    @State private var isKeyboardVisible = false
    
    @ObservedObject var coreDataManager = CoreDataManager.shared
    @Environment(\.dismiss) private var dismiss
    
    
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
                    Group {
                        switch currentStep {
                        case 0:
                            WelcomeStepView()
                        case 1:
                            NameStepView(
                                userName: $userName, 
                                textFieldBorderFlash: $textFieldBorderFlash,
                                isKeyboardVisible: $isKeyboardVisible,
                                onReturnPressed: {
                                    if canProceedToNext {
                                        withAnimation {
                                            currentStep += 1
                                        }
                                    } else {
                                        handleInvalidInput()
                                    }
                                }
                            )
                        case 2:
                            ActiveDaysStepView(activeDaysPreset: $activeDaysPreset)
                        case 3:
                            NotificationWindowStepView(
                                startTime: $notificationStartTime,
                                endTime: $notificationEndTime
                            )
                        case 4:
                            TagsStepView(
                                selectedTags: $selectedTags,
                                textFieldBorderFlash: $textFieldBorderFlash,
                                isKeyboardVisible: $isKeyboardVisible,
                                onReturnPressed: {
                                    if canProceedToNext {
                                        withAnimation {
                                            currentStep += 1
                                        }
                                    } else {
                                        handleInvalidInput()
                                    }
                                }
                            )
                        case 5:
                            PushNotificationsStepView(
                                pushNotificationsEnabled: $pushNotificationsEnabled
                            )
                        default:
                            WelcomeStepView()
                        }
                    }
                    .animation(.easeInOut, value: currentStep)
                    
                    // Navigation buttons - hide when keyboard is visible on name step or tags step
                    if !((currentStep == 1 || currentStep == 4) && isKeyboardVisible) {
                        HStack(spacing: 12) {
                        if currentStep > 0 {
                            Button("Back") {
                                withAnimation {
                                    currentStep -= 1
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            
                            if currentStep < 5 {
                                Button("Next") {
                                    if canProceedToNext {
                                        withAnimation {
                                            currentStep += 1
                                        }
                                    } else {
                                        // Show feedback for invalid input
                                        handleInvalidInput()
                                    }
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                .scaleEffect(buttonWiggle ? 0.95 : 1.0)
                                .animation(.easeInOut(duration: 0.1), value: buttonWiggle)
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
                                    if canProceedToNext {
                                        withAnimation {
                                            currentStep += 1
                                        }
                                    } else {
                                        // Show feedback for invalid input
                                        handleInvalidInput()
                                    }
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                .scaleEffect(buttonWiggle ? 0.95 : 1.0)
                                .animation(.easeInOut(duration: 0.1), value: buttonWiggle)
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
    
    private func handleInvalidInput() {
        // Trigger wiggle animation
        withAnimation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)) {
            buttonWiggle = true
        }
        
        // Flash text field border for name step and tags step
        if currentStep == 1 || currentStep == 4 {
            withAnimation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)) {
                textFieldBorderFlash = true
            }
        }
        
        // Reset animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            buttonWiggle = false
            textFieldBorderFlash = false
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
