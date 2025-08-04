//
//  PaginationComponents.swift
//  GutCheck
//
//  Reusable pagination UI components
//

import SwiftUI

// MARK: - Load More Button

struct LoadMoreButton: View {
    let isLoading: Bool
    let hasMoreData: Bool
    let action: () -> Void
    
    var body: some View {
        if hasMoreData {
            Button(action: action) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.down.circle")
                    }
                    
                    Text(isLoading ? "Loading..." : "Load More")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(ColorTheme.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(ColorTheme.background)
                        .stroke(ColorTheme.primary, lineWidth: 1)
                )
            }
            .disabled(isLoading)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Infinite Scroll View

struct InfiniteScrollView<Content: View>: View {
    let content: Content
    let isLoadingMore: Bool
    let hasMoreData: Bool
    let loadMore: () -> Void
    
    init(
        isLoadingMore: Bool,
        hasMoreData: Bool,
        loadMore: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.isLoadingMore = isLoadingMore
        self.hasMoreData = hasMoreData
        self.loadMore = loadMore
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                content
                
                if hasMoreData {
                    LoadMoreTrigger(
                        isLoading: isLoadingMore,
                        action: loadMore
                    )
                }
            }
        }
    }
}

// MARK: - Load More Trigger

struct LoadMoreTrigger: View {
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Loading more...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Spacer()
            }
        }
        .padding()
        .onAppear {
            if !isLoading {
                action()
            }
        }
    }
}

// MARK: - Pagination Status Bar

struct PaginationStatusBar: View {
    let totalItems: Int?
    let currentPage: Int
    let isLoading: Bool
    let hasMoreData: Bool
    
    var body: some View {
        HStack {
            if let totalItems = totalItems {
                Text("\(totalItems) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                }
                
                Text("Page \(currentPage)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if hasMoreData {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(ColorTheme.background.opacity(0.9))
    }
}

// MARK: - Pull to Refresh Wrapper

struct PullToRefreshScrollView<Content: View>: View {
    let content: Content
    let onRefresh: () async -> Void
    
    @State private var isRefreshing = false
    
    init(
        onRefresh: @escaping () async -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.onRefresh = onRefresh
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            content
        }
        .refreshable {
            isRefreshing = true
            await onRefresh()
            isRefreshing = false
        }
    }
}

// MARK: - Paginated List View

struct PaginatedListView<Item: Identifiable, ItemView: View>: View {
    let items: [Item]
    let isLoading: Bool
    let isLoadingMore: Bool
    let hasMoreData: Bool
    let onRefresh: () async -> Void
    let onLoadMore: () -> Void
    let itemView: (Item) -> ItemView
    
    init(
        items: [Item],
        isLoading: Bool,
        isLoadingMore: Bool,
        hasMoreData: Bool,
        onRefresh: @escaping () async -> Void,
        onLoadMore: @escaping () -> Void,
        @ViewBuilder itemView: @escaping (Item) -> ItemView
    ) {
        self.items = items
        self.isLoading = isLoading
        self.isLoadingMore = isLoadingMore
        self.hasMoreData = hasMoreData
        self.onRefresh = onRefresh
        self.onLoadMore = onLoadMore
        self.itemView = itemView
    }
    
    var body: some View {
        if isLoading && items.isEmpty {
            LoadingView()
        } else if items.isEmpty {
            EmptyStateView(
                message: "No items found. Pull down to refresh.",
                imageName: "tray"
            )
        } else {
            PullToRefreshScrollView(onRefresh: onRefresh) {
                LazyVStack(spacing: 8) {
                    ForEach(items) { item in
                        itemView(item)
                    }
                    
                    if hasMoreData {
                        LoadMoreTrigger(
                            isLoading: isLoadingMore,
                            action: onLoadMore
                        )
                    } else if !items.isEmpty {
                        Text("No more items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorTheme.background)
    }
}

// MARK: - Filter Bar

struct FilterBar<FilterType: RawRepresentable & CaseIterable & Equatable>: View where FilterType.RawValue == String {
    @Binding var selectedFilter: FilterType
    let onFilterChange: (FilterType) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(FilterType.allCases), id: \.rawValue) { filter in
                    FilterChip(
                        title: (filter as? any FilterDisplayable)?.displayName ?? filter.rawValue.capitalized,
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                        onFilterChange(filter)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? ColorTheme.primary : ColorTheme.background)
                        .stroke(ColorTheme.primary, lineWidth: 1)
                )
                .foregroundColor(isSelected ? .white : ColorTheme.primary)
        }
    }
}

// MARK: - Supporting Protocols

protocol FilterDisplayable {
    var displayName: String { get }
}

extension SymptomFilter: FilterDisplayable {}
extension MealFilter: FilterDisplayable {}

// MARK: - Date Range Picker

struct DateRangePicker: View {
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    let onRangeChange: () -> Void
    
    @State private var showingDatePicker = false
    
    var body: some View {
        HStack {
            Button(action: { showingDatePicker.toggle() }) {
                HStack {
                    Image(systemName: "calendar")
                    Text(dateRangeText)
                        .font(.subheadline)
                }
                .foregroundColor(ColorTheme.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(ColorTheme.primary, lineWidth: 1)
                )
            }
            
            if startDate != nil || endDate != nil {
                Button("Clear") {
                    startDate = nil
                    endDate = nil
                    onRangeChange()
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .sheet(isPresented: $showingDatePicker) {
            DateRangePickerSheet(
                startDate: $startDate,
                endDate: $endDate,
                onRangeChange: onRangeChange
            )
        }
    }
    
    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        
        if let start = startDate, let end = endDate {
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        } else if let start = startDate {
            return "From \(formatter.string(from: start))"
        } else if let end = endDate {
            return "Until \(formatter.string(from: end))"
        } else {
            return "Select dates"
        }
    }
}

// MARK: - Date Range Picker Sheet

struct DateRangePickerSheet: View {
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    let onRangeChange: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                DatePicker("Start Date", selection: Binding(
                    get: { startDate ?? Date() },
                    set: { startDate = $0 }
                ), displayedComponents: .date)
                .datePickerStyle(.compact)
                
                DatePicker("End Date", selection: Binding(
                    get: { endDate ?? Date() },
                    set: { endDate = $0 }
                ), displayedComponents: .date)
                .datePickerStyle(.compact)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Select Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onRangeChange()
                        dismiss()
                    }
                }
            }
        }
    }
}