import SwiftUI

struct OnboardingHealthKitStep: View {
    @StateObject private var permissionManager = PermissionManager.shared
    @Binding var currentStep: Int
    
    @State private var isRequesting = false
    @State private var showPermissionExplanation = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "heart.text.square")
                    .font(.system(size: 64))
                    .foregroundColor(ColorTheme.primary)
                
                Text("Health Data Integration")
                    .font(.largeTitle.bold())
                    .foregroundColor(ColorTheme.primaryText)
                
                Text("Connect with Apple Health to sync your nutrition and symptom data for comprehensive health tracking.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(ColorTheme.secondaryText)
            }
            
            Spacer()
            
            // Benefits section
            healthKitBenefitsView
            
            // Privacy section
            privacySection
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 16) {
                Button(action: {
                    requestHealthKitPermission()
                }) {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text("Connect to Apple Health")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(ColorTheme.primary)
                .cornerRadius(12)
                .disabled(isRequesting)
                
                Button("Learn More") {
                    showPermissionExplanation = true
                }
                .font(.subheadline)
                .foregroundColor(ColorTheme.primary)
                
                Button("Skip for Now") {
                    currentStep += 1
                }
                .font(.subheadline)
                .foregroundColor(ColorTheme.secondaryText)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .background(ColorTheme.background.ignoresSafeArea())
        .sheet(isPresented: $showPermissionExplanation) {
            HealthKitPermissionExplanationView()
        }
        .onAppear {
            permissionManager.updateAllPermissionStates()
        }
    }
    
    private var healthKitBenefitsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What you'll get:")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
            
            VStack(spacing: 12) {
                healthKitBenefit("📊", "Comprehensive tracking", "All your health data in one place")
                healthKitBenefit("🏥", "Share with doctors", "Easy data sharing with healthcare providers")
                healthKitBenefit("🔄", "Automatic sync", "No manual data entry required")
                healthKitBenefit("📈", "Better insights", "Correlate nutrition with other health metrics")
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
    }
    
    private func healthKitBenefit(_ icon: String, _ title: String, _ description: String) -> some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(ColorTheme.primaryText)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText)
            }
            
            Spacer()
        }
    }
    
    private var privacySection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 20))
                    .foregroundColor(ColorTheme.success)
                
                Text("Your health data stays secure")
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("• Data is encrypted and stored securely")
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText)
                Text("• You control what data to share")
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText)
                Text("• Can be revoked anytime in Settings")
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText)
            }
        }
        .padding(16)
        .background(ColorTheme.success.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func requestHealthKitPermission() {
        isRequesting = true
        
        Task {
            let granted = await permissionManager.requestHealthKitPermission()
            
            await MainActor.run {
                self.isRequesting = false
                if granted {
                    // Move to next step on successful permission
                    self.currentStep += 1
                }
                // If denied, stay on this step but show they can continue
            }
        }
    }
}

struct HealthKitPermissionExplanationView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Health Data We'll Access")
                            .font(.title2.bold())
                            .foregroundColor(ColorTheme.primaryText)
                        
                        Text("GutCheck will request permission to read and write specific health data types:")
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        healthDataSection("Write to Health App", [
                            ("Dietary Energy", "Calories from meals you log"),
                            ("Dietary Carbohydrates", "Carbs from your food tracking"),
                            ("Dietary Protein", "Protein intake data"),
                            ("Dietary Fat", "Fat consumption tracking"),
                            ("Dietary Fiber", "Fiber intake from meals"),
                            ("Dietary Sodium", "Sodium content monitoring"),
                            ("Dietary Sugar", "Sugar intake tracking")
                        ])
                        
                        healthDataSection("Read from Health App", [
                            ("Body Mass", "Your weight for better nutrition calculations"),
                            ("Height", "For accurate calorie and portion recommendations")
                        ])
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Privacy & Control")
                            .font(.title3.bold())
                            .foregroundColor(ColorTheme.primaryText)
                        
                        Text("• You can choose which data types to allow or deny\n• Permissions can be changed anytime in Health app settings\n• GutCheck never shares your health data with third parties\n• All data is encrypted and stored securely")
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                    .padding(16)
                    .background(ColorTheme.cardBackground)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .navigationTitle("HealthKit Integration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func healthDataSection(_ title: String, _ items: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
            
            VStack(spacing: 8) {
                ForEach(items, id: \.0) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(ColorTheme.primary)
                            .padding(.top, 6)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.0)
                                .font(.subheadline.bold())
                                .foregroundColor(ColorTheme.primaryText)
                            
                            Text(item.1)
                                .font(.caption)
                                .foregroundColor(ColorTheme.secondaryText)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(ColorTheme.surface)
        .cornerRadius(12)
    }
}
