import SwiftUI

struct NameStepView: View {
    @Binding var userName: String
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Header
            VStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                
                VStack(spacing: 8) {
                    Text("What's your name?")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("We'll use this to personalize your experience")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Name Input
            VStack(spacing: 20) {
                TextField("Enter your name", text: $userName)
                    .textFieldStyle(.roundedBorder)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .focused($isTextFieldFocused)
                    .onAppear {
                        isTextFieldFocused = true
                    }
                
                Text("This helps us make your reminders feel more personal")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .onTapGesture {
            isTextFieldFocused = false
        }
    }
}

#Preview {
    NameStepView(userName: .constant(""))
}
