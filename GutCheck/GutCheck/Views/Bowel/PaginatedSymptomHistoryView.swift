//
//  PaginatedSymptomHistoryView.swift
//  GutCheck
//
//  Example of paginated symptom history using new pagination components
//

import SwiftUI

struct PaginatedSymptomHistoryView: View {
    @StateObject private var viewModel = SymptomHistoryViewModel()
    @EnvironmentObject var authService: AuthService
    @State private var optionalStartDate: Date? = nil
    @State private var optionalEndDate: Date? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter bar
                FilterBar(selectedFilter: $viewModel.selectedFilter) { filter in
                    Task {
                        await viewModel.loadSymptoms(filter: filter, refresh: true)
                    }
                }
                .background(ColorTheme.background)
                
                // Date range picker
                DateRangePicker(
                    startDate: $optionalStartDate,
                    endDate: $optionalEndDate
                ) {
                    Task {
                        await viewModel.refreshSymptoms(filter: viewModel.selectedFilter)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Main content
                if viewModel.isLoading && viewModel.groupedSymptoms.isEmpty {
                    LoadingView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.groupedSymptoms.isEmpty {
                    EmptyStateView(
                        message: "No symptoms recorded. Start logging your symptoms to see patterns.",
                        imageName: "heart.text.square"
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    symptomList
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Symptom History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export") {
                        Task {
                            await viewModel.exportSymptoms()
                        }
                    }
                }
            }
            .task {
                await viewModel.loadSymptoms()
            }
        }
    }
    
    private var symptomList: some View {
        PullToRefreshScrollView {
            await viewModel.refreshSymptoms(filter: viewModel.selectedFilter)
        } content: {
            LazyVStack(spacing: 0) {
                ForEach(sortedDateKeys, id: \.self) { date in
                    if let symptoms = viewModel.groupedSymptoms[date] {
                        SymptomDaySection(
                            date: date,
                            symptoms: symptoms,
                            onSymptomTap: { symptom in
                                // Navigate to symptom detail
                            },
                            onSymptomDelete: { symptom in
                                Task {
                                    await viewModel.deleteSymptom(symptom)
                                }
                            }
                        )
                    }
                }
                
                // Load more trigger
                if viewModel.hasMoreData {
                    LoadMoreTrigger(
                        isLoading: viewModel.isLoadingMore,
                        action: {
                            Task {
                                await viewModel.loadMoreSymptoms()
                            }
                        }
                    )
                } else if !viewModel.groupedSymptoms.isEmpty {
                    Text("No more symptoms")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var sortedDateKeys: [Date] {
        viewModel.groupedSymptoms.keys.sorted(by: >)
    }
}

// MARK: - Symptom Day Section

struct SymptomDaySection: View {
    let date: Date
    let symptoms: [Symptom]
    let onSymptomTap: (Symptom) -> Void
    let onSymptomDelete: (Symptom) -> Void
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dayFormatter.string(from: date))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(ColorTheme.primary)
                    
                    Text(dateFormatter.string(from: date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Symptom count badge
                Text("\(symptoms.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ColorTheme.accent)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Symptoms for this day
            VStack(spacing: 8) {
                ForEach(symptoms.sorted { $0.date > $1.date }) { symptom in
                    SymptomRowView(
                        symptom: symptom,
                        onTap: { onSymptomTap(symptom) },
                        onDelete: { onSymptomDelete(symptom) }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

// MARK: - Symptom Row View

struct SymptomRowView: View {
    let symptom: Symptom
    let onTap: () -> Void
    let onDelete: () -> Void
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        HStack(spacing: 12) {
            // Time
            Text(timeFormatter.string(from: symptom.date))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(ColorTheme.primary)
                .frame(width: 60, alignment: .leading)
            
            // Stool type indicator
            Circle()
                .fill(stoolTypeColor)
                .frame(width: 12, height: 12)
            
            // Details
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Type \(symptom.stoolType.typeNumber)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if symptom.painLevel != .none {
                        SimpleIndicator(
                            icon: "exclamationmark.triangle.fill",
                            text: symptom.painLevel.displayName,
                            color: symptom.painLevel.color
                        )
                    }
                    
                    if symptom.urgencyLevel != .none {
                        SimpleIndicator(
                            icon: "timer",
                            text: symptom.urgencyLevel.displayName,
                            color: symptom.urgencyLevel.color
                        )
                    }
                    
                    Spacer()
                }
                
                if let notes = symptom.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Circle().fill(Color.red.opacity(0.1)))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
    
    private var stoolTypeColor: Color {
        switch symptom.stoolType {
        case .type1, .type2:
            return .red
        case .type3, .type4:
            return .green
        case .type5, .type6, .type7:
            return .orange
        }
    }
}

// MARK: - Simple Indicator

struct SimpleIndicator: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            
            Text(text)
                .font(.caption2)
                .foregroundColor(color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Extensions

extension PainLevel {
    var color: Color {
        switch self {
        case .none: return .gray
        case .mild: return .yellow
        case .moderate: return .orange
        case .severe: return .red
        }
    }
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .severe: return "Severe"
        }
    }
}

extension UrgencyLevel {
    var color: Color {
        switch self {
        case .none: return .gray
        case .mild: return .blue
        case .moderate: return .orange
        case .urgent: return .red
        }
    }
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .urgent: return "Urgent"
        }
    }
}

extension StoolType {
    var typeNumber: Int {
        switch self {
        case .type1: return 1
        case .type2: return 2
        case .type3: return 3
        case .type4: return 4
        case .type5: return 5
        case .type6: return 6
        case .type7: return 7
        }
    }
}

// MARK: - Preview

#if DEBUG
struct PaginatedSymptomHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        PaginatedSymptomHistoryView()
            .environmentObject(AuthService())
    }
}
#endif