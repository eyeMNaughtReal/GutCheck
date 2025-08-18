//
//  HealthcareExportView.swift
//  GutCheck
//
//  View for healthcare professionals to configure and generate health data export reports.
//  Allows customization of export options, date ranges, and data types to include.
//
//  Created by Mark Conley on 8/11/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct HealthcareExportView: View {
    @StateObject private var exportService = HealthcareExportService.shared
    @State private var exportOptions = ExportOptions.default
    @State private var showingExportOptions = false
    @State private var showingShareSheet = false
    @State private var exportData: Data?
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // Date range picker states
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
    @State private var endDate = Date()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Export Options
                    exportOptionsSection
                    
                    // Data Preview
                    dataPreviewSection
                    
                    // Export Button
                    exportButtonSection
                    
                    // Instructions
                    instructionsSection
                }
                .padding()
            }
            .navigationTitle("Healthcare Export")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export") {
                        showingExportOptions = true
                    }
                    .disabled(exportService.isExporting)
                }
            }
            .sheet(isPresented: $showingExportOptions) {
                ExportOptionsSheet(
                    options: $exportOptions,
                    startDate: $startDate,
                    endDate: $endDate
                )
            }
            .sheet(isPresented: $showingShareSheet) {
                if let data = exportData {
                    ShareSheet(activityItems: [data])
                }
            }
            .alert("Export Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("Healthcare Professional Export")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Generate comprehensive health reports for medical professionals, nutritionists, and healthcare providers.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Export Options Section
    
    private var exportOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Export Configuration")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Date Range:")
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(startDate.formatted(date: .abbreviated, time: .omitted)) - \(endDate.formatted(date: .abbreviated, time: .omitted))")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Format:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(exportOptions.format.displayName)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Include Private Data:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(exportOptions.includePrivateData ? "Yes" : "No")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Data Preview Section
    
    private var dataPreviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data Preview")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                DataPreviewRow(
                    title: "Meals",
                    count: "\(exportOptions.includeMealData ? "Included" : "Excluded")",
                    icon: "fork.knife",
                    color: exportOptions.includeMealData ? .green : .gray
                )
                
                DataPreviewRow(
                    title: "Symptoms",
                    count: "\(exportOptions.includeSymptomData ? "Included" : "Excluded")",
                    icon: "heart.text.square",
                    color: exportOptions.includeSymptomData ? .green : .gray
                )
                
                DataPreviewRow(
                    title: "Medications",
                    count: "\(exportOptions.includeMedicationData ? "Included" : "Excluded")",
                    icon: "pills",
                    color: exportOptions.includeMedicationData ? .green : .gray
                )
                
                DataPreviewRow(
                    title: "Nutrition Insights",
                    count: "\(exportOptions.includeNutritionData ? "Included" : "Excluded")",
                    icon: "chart.bar",
                    color: exportOptions.includeNutritionData ? .green : .gray
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Export Button Section
    
    private var exportButtonSection: some View {
        VStack(spacing: 16) {
            if exportService.isExporting {
                VStack(spacing: 12) {
                    ProgressView(value: exportService.exportProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    Text("Generating Report...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Button(action: generateExport) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Generate Healthcare Report")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .disabled(exportService.isExporting)
            }
        }
    }
    
    // MARK: - Instructions Section
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Instructions for Healthcare Professionals")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                InstructionRow(
                    number: "1",
                    text: "Review the export configuration to ensure all relevant data types are included."
                )
                
                InstructionRow(
                    number: "2",
                    text: "Set the appropriate date range for the health assessment period."
                )
                
                InstructionRow(
                    number: "3",
                    text: "Choose your preferred export format (PDF recommended for medical records)."
                )
                
                InstructionRow(
                    number: "4",
                    text: "Generate the report and share it with the patient's healthcare team."
                )
                
                InstructionRow(
                    number: "5",
                    text: "Use the data to correlate with medical testing and provide informed recommendations."
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Actions
    
    private func generateExport() {
        // Update export options with current date range
        exportOptions = ExportOptions(
            dateRange: startDate...endDate,
            includePrivateData: exportOptions.includePrivateData,
            includeNutritionData: exportOptions.includeNutritionData,
            includeSymptomData: exportOptions.includeSymptomData,
            includeMedicationData: exportOptions.includeMedicationData,
            includeMealData: exportOptions.includeMealData,
            format: exportOptions.format,
            anonymizeData: exportOptions.anonymizeData
        )
        
        Task {
            do {
                let data = try await exportService.exportHealthData(options: exportOptions)
                await MainActor.run {
                    exportData = data
                    showingShareSheet = true
                }
            } catch {
                await MainActor.run {
                    if let exportError = error as? ExportError {
                        switch exportError {
                        case .reauthenticationRequired:
                            errorMessage = "Re-authentication required. Please sign in again to export your data."
                            showingError = true
                        case .userNotAuthenticated:
                            errorMessage = "You must be signed in to export data."
                            showingError = true
                        default:
                            errorMessage = exportError.errorDescription ?? error.localizedDescription
                            showingError = true
                        }
                    } else {
                        errorMessage = error.localizedDescription
                        showingError = true
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct DataPreviewRow: View {
    let title: String
    let count: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(count)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct InstructionRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Color.blue)
                .clipShape(Circle())
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
}

struct ExportOptionsSheet: View {
    @Binding var options: ExportOptions
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Date Range") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                
                Section("Data Types") {
                    Toggle("Include Meals", isOn: $options.includeMealData)
                    Toggle("Include Symptoms", isOn: $options.includeSymptomData)
                    Toggle("Include Medications", isOn: $options.includeMedicationData)
                    Toggle("Include Nutrition Insights", isOn: $options.includeNutritionData)
                }
                
                Section("Export Settings") {
                    Picker("Format", selection: $options.format) {
                        ForEach([ExportFormat.pdf, .csv, .json, .summary], id: \.self) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    
                    Toggle("Include Private Data", isOn: $options.includePrivateData)
                    Toggle("Anonymize Data", isOn: $options.anonymizeData)
                }
                
                Section("Privacy Note") {
                    Text("Private data includes personal notes, detailed symptoms, and medication information. Only include if required for medical assessment.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Export Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Extensions

extension ExportFormat {
    var displayName: String {
        switch self {
        case .pdf:
            return "PDF Report"
        case .csv:
            return "CSV Data"
        case .json:
            return "JSON Data"
        case .summary:
            return "Summary Report"
        }
    }
}

// MARK: - Preview

struct HealthcareExportView_Previews: PreviewProvider {
    static var previews: some View {
        HealthcareExportView()
    }
}
