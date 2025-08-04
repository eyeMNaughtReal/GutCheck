import SwiftUI

struct SymptomHistoryView: View {
    @StateObject private var viewModel = SymptomHistoryViewModel()
    @State private var selectedFilter: SymptomFilter = .all
    @State private var showingDatePicker = false
    
    private var symptomsList: some View {
        ForEach(viewModel.groupedSymptoms.keys.sorted(by: >), id: \.self) { date in
            Section(header: Text(formatDate(date))) {
                ForEach(viewModel.groupedSymptoms[date] ?? []) { symptom in
                    NavigationLink(destination: SymptomDetailView(
                        symptom: symptom,
                        onEdit: { updatedSymptom in
                            Task {
                                await viewModel.updateSymptom(updatedSymptom)
                            }
                        },
                        onDelete: { symptomToDelete in
                            Task {
                                await viewModel.deleteSymptom(symptomToDelete)
                            }
                        }
                    )) {
                        SymptomRow(symptom: symptom)
                    }
                }
            }
        }
    }
    
    var body: some View {
        List {
            Section {
                FilterPickerView(selectedFilter: $selectedFilter) {
                    Task {
                        await viewModel.loadSymptoms(filter: selectedFilter)
                    }
                }
            }
            
            symptomsList
        }
        .navigationTitle("Symptom History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingDatePicker = true }) {
                        Label("Choose Date", systemImage: "calendar")
                    }
                    
                    Button(action: { exportSymptoms() }) {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            DateRangePickerView(
                startDate: $viewModel.startDate,
                endDate: $viewModel.endDate,
                isPresented: $showingDatePicker
            )
        }
        .refreshable {
            await viewModel.loadSymptoms(filter: selectedFilter)
        }
        .task {
            await viewModel.loadSymptoms(filter: selectedFilter)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return date.formatted(.dateTime.month().day().weekday())
        }
    }
    
    private func getSymptomDescription(_ symptom: Symptom) -> String {
        if symptom.painLevel != .none {
            return "Pain (\(symptom.painLevel.rawValue))"
        } else if symptom.urgencyLevel != .none {
            return "Urgency (\(symptom.urgencyLevel.rawValue))"
        } else {
            return "BM (Type \(symptom.stoolType.rawValue))"
        }
    }
    
    private func exportSymptoms() {
        Task {
            await viewModel.exportSymptoms()
        }
    }
}

// MARK: - Supporting Views

private struct SeverityIndicator: View {
    let severity: Int
    var style: Style = .dots
    
    enum Style {
        case single
        case dots
    }
    
    var body: some View {
        switch style {
        case .single:
            Circle()
                .fill(severityColor)
                .frame(width: 12, height: 12)
        case .dots:
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { index in
                    Circle()
                        .fill(index <= (severity + 1) / 2 ? severityColor : severityColor.opacity(0.2))
                        .frame(width: 6, height: 6)
                }
            }
        }
    }
    
    private var severityColor: Color {
        switch severity {
        case 0...3: return .green
        case 4...7: return .yellow
        case 8...10: return .red
        default: return .gray
        }
    }
}

private struct FilterPickerView: View {
    @Binding var selectedFilter: SymptomFilter
    let onFilterChange: () -> Void
    
    var body: some View {
        Picker("Filter", selection: $selectedFilter) {
            ForEach(SymptomFilter.allCases, id: \.self) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedFilter) { oldValue, newValue in
            onFilterChange()
        }
    }
}

private struct SymptomRow: View {
    let symptom: Symptom
    
    private func getSymptomDescription(_ symptom: Symptom) -> String {
        if symptom.painLevel != .none {
            return "Pain (\(symptom.painLevel.rawValue))"
        } else if symptom.urgencyLevel != .none {
            return "Urgency (\(symptom.urgencyLevel.rawValue))"
        } else {
            return "BM (Type \(symptom.stoolType.rawValue))"
        }
    }
    
    private func calculateSeverity(_ symptom: Symptom) -> Int {
        let painSeverity = symptom.painLevel.rawValue
        let urgencySeverity = symptom.urgencyLevel.rawValue
        let stoolSeverity = abs(4 - symptom.stoolType.rawValue) // Type 4 is ideal, deviation indicates severity
        
        return max(painSeverity, urgencySeverity, stoolSeverity)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(getSymptomDescription(symptom))
                    .font(.headline)
                Spacer()
                Text(symptom.date.formatted(.dateTime.hour().minute()))
                    .foregroundColor(.secondary)
            }
            
            HStack {
                SeverityIndicator(severity: calculateSeverity(symptom))
                
                if let notes = symptom.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// Using the unified SeverityIndicator view

private struct DateRangePickerView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            Form {
                DatePicker("Start Date", selection: $startDate, displayedComponents: [.date])
                DatePicker("End Date", selection: $endDate, displayedComponents: [.date])
            }
            .navigationTitle("Select Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Types

#Preview {
    NavigationView {
        SymptomHistoryView()
    }
}
