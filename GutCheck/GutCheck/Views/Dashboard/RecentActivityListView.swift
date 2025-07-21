import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct RecentActivityListView: View {
    @StateObject private var viewModel = RecentActivityViewModel()
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    let selectedDate: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with "See All" button
            HStack {
                Text("Today's Activity")
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                
                Spacer()
                
                Button("See All") {
                    navigationCoordinator.navigateTo(.calendar(selectedDate))
                }
                .font(.caption)
                .foregroundColor(ColorTheme.primary)
            }
            
            if viewModel.isLoading {
                LoadingStateView()
            } else if viewModel.recentEntries.isEmpty {
                EmptyStateView()
            } else {
                // Recent entries list
                VStack(spacing: 8) {
                    ForEach(viewModel.recentEntries) { entry in
                        ActivityRowView(entry: entry) {
                            handleEntryTap(entry)
                        }
                    }
                }
            }
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: ColorTheme.shadowColor, radius: 4, x: 0, y: 2)
        .onAppear {
            viewModel.loadRecentActivity(for: selectedDate)
        }
        .onChange(of: selectedDate) { _, newDate in
            viewModel.loadRecentActivity(for: newDate)
        }
    }
    
    private func handleEntryTap(_ entry: ActivityEntry) {
        switch entry.type {
        case .meal(let meal):
            navigationCoordinator.navigateTo(.mealDetail(meal))
        case .symptom(let symptom):
            navigationCoordinator.navigateTo(.symptomDetail(symptom))
        }
    }
}

// MARK: - Activity Row View
struct ActivityRowView: View {
    let entry: ActivityEntry
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: entry.icon)
                    .font(.title3)
                    .foregroundColor(entry.iconColor)
                    .frame(width: 24, height: 24)
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(entry.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(ColorTheme.primaryText)
                        
                        if case .symptom(let symptom) = entry.type {
                            BristolStoolBadge(stoolType: symptom.stoolType)
                        }
                        
                        Spacer()
                    }
                    
                    if let subtitle = entry.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                }
                
                // Timestamp
                VStack(alignment: .trailing) {
                    Text(entry.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(ColorTheme.secondaryText)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(ColorTheme.secondaryText)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(ColorTheme.surface)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Bristol Stool Badge
struct BristolStoolBadge: View {
    let stoolType: StoolType
    
    var body: some View {
        Text("\(stoolType.rawValue)")
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(width: 20, height: 20)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(bristolColor)
            )
    }
    
    private var bristolColor: Color {
        switch stoolType.rawValue {
        case 1, 2:
            return Color.red
        case 3, 4:
            return Color.green
        case 5, 6, 7:
            return Color.orange
        default:
            return Color.gray
        }
    }
}

// MARK: - Loading State
struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { _ in
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 24, height: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 16)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 12)
                    }
                    
                    Spacer()
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 12)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(ColorTheme.surface)
                .cornerRadius(8)
            }
        }
        .redacted(reason: .placeholder)
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.title2)
                .foregroundColor(ColorTheme.secondaryText)
            
            Text("No activity logged today")
                .font(.subheadline)
                .foregroundColor(ColorTheme.secondaryText)
            
            Text("Start by logging a meal or symptom")
                .font(.caption)
                .foregroundColor(ColorTheme.secondaryText)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Activity Entry Model
struct ActivityEntry: Identifiable, Hashable {
    let id = UUID()
    let type: ActivityType
    let timestamp: Date
    
    var title: String {
        switch type {
        case .meal(let meal):
            return meal.name
        case .symptom:
            return "Symptom Logged"
        }
    }
    
    var subtitle: String? {
        switch type {
        case .meal(let meal):
            return meal.notes
        case .symptom(let symptom):
            var components: [String] = []
            if symptom.painLevel != .none {
                components.append("Pain: \(symptom.painLevel.description)")
            }
            if symptom.urgencyLevel != .none {
                components.append("Urgency: \(symptom.urgencyLevel.description)")
            }
            return components.isEmpty ? nil : components.joined(separator: " • ")
        }
    }
    
    var icon: String {
        switch type {
        case .meal:
            return "fork.knife"
        case .symptom:
            return "exclamationmark.triangle"
        }
    }
    
    var iconColor: Color {
        switch type {
        case .meal:
            return ColorTheme.accent
        case .symptom:
            return ColorTheme.warning
        }
    }
}

enum ActivityType: Hashable {
    case meal(Meal)
    case symptom(Symptom)
}

// MARK: - Recent Activity ViewModel

@MainActor
class RecentActivityViewModel: ObservableObject {
    @Published var recentEntries: [ActivityEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Repository dependencies
    private let mealRepository: MealRepository
    private let symptomRepository: SymptomRepository
    private let maxEntries = 5
    
    init(mealRepository: MealRepository = MealRepository.shared,
         symptomRepository: SymptomRepository = SymptomRepository.shared) {
        self.mealRepository = mealRepository
        self.symptomRepository = symptomRepository
    }
    
    func loadRecentActivity(for date: Date) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let entries = try await fetchActivityEntries(for: date)
                await MainActor.run {
                    self.recentEntries = entries
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("Error loading recent activity: \(error)")
                }
            }
        }
    }
    
    // MARK: - Refactored using Repositories
    
    private func fetchActivityEntries(for date: Date) async throws -> [ActivityEntry] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw RepositoryError.noAuthenticatedUser
        }
        
        var entries: [ActivityEntry] = []
        
        // Fetch meals using repository
        let meals = try await mealRepository.fetchMealsForDate(date, userId: userId)
        for meal in meals {
            entries.append(ActivityEntry(type: .meal(meal), timestamp: meal.date))
        }
        
        // Fetch symptoms using repository
        let symptoms = try await symptomRepository.fetchSymptomsForDate(date, userId: userId)
        for symptom in symptoms {
            entries.append(ActivityEntry(type: .symptom(symptom), timestamp: symptom.date))
        }
        
        // Sort by timestamp (most recent first) and limit
        return entries
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(maxEntries)
            .map { $0 }
    }
}

// MARK: - Extensions for better display
extension PainLevel {
    var description: String {
        switch self {
        case .none:
            return "None"
        case .mild:
            return "Mild"
        case .moderate:
            return "Moderate"
        case .severe:
            return "Severe"
        }
    }
}

extension UrgencyLevel {
    var description: String {
        switch self {
        case .none:
            return "None"
        case .mild:
            return "Mild"
        case .moderate:
            return "Moderate"
        case .urgent:
            return "Urgent"
        }
    }
}
