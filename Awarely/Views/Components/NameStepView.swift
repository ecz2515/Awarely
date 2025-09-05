import SwiftUI

struct NameStepView: View {
    @Binding var userName: String
    @Binding var textFieldBorderFlash: Bool
    @Binding var isKeyboardVisible: Bool
    @FocusState private var isTextFieldFocused: Bool
    let onReturnPressed: () -> Void
    
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
                }
            }
            .padding(.horizontal, 32)
            
            // Name Input
            VStack(spacing: 20) {
                TextField("Enter your name", text: $userName)
                    .font(.title2.weight(.medium))
                    .multilineTextAlignment(.center)
                    .focused($isTextFieldFocused)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .onSubmit {
                        // Just dismiss the keyboard
                        isTextFieldFocused = false
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        textFieldBorderFlash ? Color.red : Color(.systemGray4), 
                                        lineWidth: textFieldBorderFlash ? 2 : 1
                                    )
                            )
                    )
                    .onAppear {
                        isTextFieldFocused = true
                    }
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .onTapGesture {
            isTextFieldFocused = false
        }
        .onChange(of: isTextFieldFocused) { focused in
            isKeyboardVisible = focused
        }
    }
}

#Preview {
    NameStepView(userName: .constant(""), textFieldBorderFlash: .constant(false), isKeyboardVisible: .constant(false), onReturnPressed: {})
}
