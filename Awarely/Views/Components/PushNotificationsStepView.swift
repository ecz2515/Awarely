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
                    Text("Notifications")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("Get gentle reminders to check in")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)
            
            // Benefits
            VStack(spacing: 20) {
                BenefitRow(icon: "clock.badge.checkmark", text: "Timely reminders throughout your day")
                BenefitRow(icon: "brain.head.profile", text: "Consistently log your productivity")
            }
            .padding(.horizontal, 32)
            
            // Permission Button
            VStack(spacing: 16) {
                Button(action: pushNotificationsEnabled ? {} : requestNotificationPermission) {
                    HStack {
                        Image(systemName: pushNotificationsEnabled ? "bell.badge.fill" : "bell.badge")
                            .font(.headline)
                        
                        Text(pushNotificationsEnabled ? "Notifications Enabled" : "Allow Notifications")
                            .font(.headline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: pushNotificationsEnabled ? [.green, .mint] : [.red, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .disabled(pushNotificationsEnabled)
                
                Text(pushNotificationsEnabled ? "Notifications are enabled for this app" : "You can change this later in Settings")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
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
        .onAppear {
            checkCurrentNotificationStatus()
        }
    }
    
    private func checkCurrentNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                print("📱 Current notification settings:")
                print("   Authorization Status: \(settings.authorizationStatus.rawValue)")
                print("   Alert Setting: \(settings.alertSetting.rawValue)")
                print("   Badge Setting: \(settings.badgeSetting.rawValue)")
                print("   Sound Setting: \(settings.soundSetting.rawValue)")
                
                // Update the binding based on current status
                switch settings.authorizationStatus {
                case .authorized:
                    pushNotificationsEnabled = true
                case .denied, .notDetermined, .provisional, .ephemeral:
                    pushNotificationsEnabled = false
                @unknown default:
                    pushNotificationsEnabled = false
                }
            }
        }
    }
    
    private func requestNotificationPermission() {
        print("🔔 Requesting notification permission...")
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                print("🔔 Permission result: granted=\(granted), error=\(String(describing: error))")
                
                if granted {
                    pushNotificationsEnabled = true
                    print("✅ Notification permission granted")
                } else {
                    pushNotificationsEnabled = false
                    if let error = error {
                        print("❌ Notification permission error: \(error)")
                    } else {
                        print("❌ Notification permission denied by user")
                    }
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
