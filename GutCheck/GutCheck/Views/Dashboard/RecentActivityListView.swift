import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct RecentActivityListView: View {
    @StateObject private var viewModel = RecentActivityViewModel()
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var authService: AuthService
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
                    // Switch to meals tab which shows the calendar view
                    router.selectedTab = .meals
                }
                .font(.caption)
                .foregroundColor(ColorTheme.primary)
            }
            
            if viewModel.isLoading {
                LoadingStateView()
            } else if viewModel.recentEntries.isEmpty {
                RecentActivityEmptyStateView()
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
            viewModel.loadRecentActivity(for: selectedDate, authService: authService)
        }
        .onChange(of: selectedDate) { _, newDate in
            viewModel.loadRecentActivity(for: newDate, authService: authService)
        }
    }
    
    private func handleEntryTap(_ entry: ActivityEntry) {
        switch entry.type {
        case .meal(let meal):
            router.viewMealDetails(id: meal.id)
        case .symptom(let symptom):
            router.viewSymptomDetails(id: symptom.id)
        case .medication(let medication):
            // For now, we'll just show a simple alert since we don't have a medication detail view yet
            // In the future, this could navigate to a medication detail view
            break
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
struct RecentActivityEmptyStateView: View {
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
