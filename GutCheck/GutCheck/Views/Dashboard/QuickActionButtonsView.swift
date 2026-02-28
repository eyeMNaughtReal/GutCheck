import SwiftUI

struct QuickActionButtonsView: View {
    @State private var showingLogMedication = false

    var body: some View {
        HStack(spacing: 16) {
            NavigationLink(destination: MealBuilderView()) {
                ActionButton(icon: "fork.knife", label: "Log Meal", color: ColorTheme.accent)
            }
            NavigationLink(destination: LogSymptomView()) {
                ActionButton(icon: "stethoscope", label: "Log Symptom", color: ColorTheme.secondary)
            }
            Button {
                showingLogMedication = true
            } label: {
                ActionButton(icon: "pills.fill", label: "Log Meds", color: .purple)
            }
            .sheet(isPresented: $showingLogMedication) {
                LogMedicationDoseView()
            }
        }
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(ColorTheme.lightText)
                .padding()
                .background(Circle().fill(color))
            Text(label)
                .font(.caption)
                .foregroundColor(ColorTheme.primaryText)
        }
        .frame(width: 100, height: 100)
        .background(ColorTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: ColorTheme.shadowColor, radius: 4, x: 0, y: 2)
    }
}
