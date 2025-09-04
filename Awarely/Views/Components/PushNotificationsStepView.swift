import SwiftUI
import UserNotifications

struct PushNotificationsStepView: View {
    @Binding var pushNotificationsEnabled: Bool
    @State private var showingPermissionAlert = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Header
            VStack(spacing: 16) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.red)
                
                VStack(spacing: 8) {
                    Text("Stay mindful")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("Get gentle reminders to check in with yourself")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Benefits
            VStack(spacing: 20) {
                BenefitRow(icon: "clock.badge.checkmark", text: "Timely reminders throughout your day")
                BenefitRow(icon: "brain.head.profile", text: "Build consistent mindfulness habits")
                BenefitRow(icon: "chart.line.uptrend.xyaxis", text: "Track your progress over time")
            }
            .padding(.horizontal, 20)
            
            // Permission Button
            VStack(spacing: 16) {
                Button(action: requestNotificationPermission) {
                    HStack {
                        Image(systemName: "bell.badge")
                            .font(.headline)
                        
                        Text("Allow Notifications")
                            .font(.headline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.red, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                
                Text("You can change this later in Settings")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .alert("Notification Permission", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable notifications in Settings to receive mindful reminders.")
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    pushNotificationsEnabled = true
                } else {
                    pushNotificationsEnabled = false
                    showingPermissionAlert = true
                }
            }
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.red)
                .frame(width: 32)
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            Spacer()
        }
    }
}

#Preview {
    PushNotificationsStepView(pushNotificationsEnabled: .constant(false))
}
