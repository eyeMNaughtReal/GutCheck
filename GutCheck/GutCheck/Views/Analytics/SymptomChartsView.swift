import SwiftUI
import Charts

struct SymptomChartsView: View {
    @State private var viewModel = SymptomChartsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    ProgressView("Loading chart data…")
                        .padding(.top, 40)
                } else if let error = viewModel.error {
                    errorState(error)
                } else {
                    filterBar
                    chartTabPicker
                    chartContent
                }
            }
            .padding()
        }
        .navigationTitle("Symptom Charts")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier(AccessibilityIdentifiers.Insights.symptomChartsView)
        .task {
            await viewModel.loadData()
        }
        .onChange(of: viewModel.selectedTimeRange) { _, _ in
            Task { await viewModel.loadData() }
        }
        .onChange(of: viewModel.selectedFilter) { _, _ in
            viewModel.recomputeChartData()
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        VStack(spacing: 12) {
            Picker("Time Range", selection: $viewModel.selectedTimeRange) {
                ForEach(ChartTimeRange.allCases) { range in
                    Text(range.displayName).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier(AccessibilityIdentifiers.Insights.chartTimeRangePicker)

            Picker("Filter", selection: $viewModel.selectedFilter) {
                ForEach(SymptomChartFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier(AccessibilityIdentifiers.Insights.chartSymptomFilterPicker)
        }
    }

    // MARK: - Chart Tab Picker

    private var chartTabPicker: some View {
        Picker("Chart Type", selection: $viewModel.selectedTab) {
            ForEach(ChartTab.allCases) { tab in
                Label(tab.rawValue, systemImage: tab.icon).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier(AccessibilityIdentifiers.Insights.chartTabPicker)
    }

    // MARK: - Chart Content

    @ViewBuilder
    private var chartContent: some View {
        switch viewModel.selectedTab {
        case .timeline:
            timelineChart
        case .severity:
            severityLineChart
        case .weekly:
            weeklyBarChart
        case .ingredients:
            ingredientPieChart
        }
    }

    // MARK: - Timeline Chart

    private var timelineChart: some View {
        chartCard(title: "Daily Symptom Timeline", icon: "calendar.day.timeline.left") {
            if viewModel.timelineData.isEmpty {
                chartEmptyState("No symptom data for this period")
            } else {
                Chart(viewModel.timelineData) { point in
                    PointMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Severity", point.severityLevel)
                    )
                    .foregroundStyle(point.severityColor)
                    .symbolSize(CGFloat(point.symptomCount * 40 + 40))
                }
                .chartYScale(domain: 0...3)
                .chartYAxis {
                    AxisMarks(values: [0, 1, 2, 3]) { value in
                        AxisValueLabel {
                            if let intVal = value.as(Int.self) {
                                Text(severityAxisLabel(intVal))
                                    .font(.caption2)
                            }
                        }
                        AxisGridLine()
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day,
                        count: viewModel.selectedTimeRange == .last7Days ? 1 : 7)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        AxisGridLine()
                    }
                }
                .frame(height: 250)
            }
        }
    }

    // MARK: - Severity Line Chart

    private var severityLineChart: some View {
        chartCard(title: "Severity Over Time", icon: "chart.xyaxis.line") {
            if viewModel.severityData.isEmpty {
                chartEmptyState("No severity data for this period")
            } else {
                Chart(viewModel.severityData) { point in
                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Severity", point.value)
                    )
                    .foregroundStyle(by: .value("Type", point.series))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Severity", point.value)
                    )
                    .foregroundStyle(by: .value("Type", point.series))
                    .symbolSize(30)
                }
                .chartYScale(domain: 0...3)
                .chartYAxis {
                    AxisMarks(values: [0, 1, 2, 3]) { value in
                        AxisValueLabel {
                            if let intVal = value.as(Int.self) {
                                Text(severityAxisLabel(intVal))
                                    .font(.caption2)
                            }
                        }
                        AxisGridLine()
                    }
                }
                .chartForegroundStyleScale([
                    "Pain": Color.red,
                    "Urgency": Color.orange
                ])
                .chartLegend(position: .bottom)
                .frame(height: 250)
            }
        }
    }

    // MARK: - Weekly Bar Chart

    private var weeklyBarChart: some View {
        chartCard(title: "Symptoms Per Week", icon: "chart.bar.fill") {
            if viewModel.weeklyData.isEmpty {
                chartEmptyState("No weekly data for this period")
            } else {
                Chart(viewModel.weeklyData) { point in
                    BarMark(
                        x: .value("Week", point.weekLabel),
                        y: .value("Count", point.count)
                    )
                    .foregroundStyle(ColorTheme.accent.gradient)
                    .cornerRadius(4)
                    .annotation(position: .top) {
                        Text("\(point.count)")
                            .font(.caption2.bold())
                            .foregroundStyle(ColorTheme.secondaryText)
                    }
                }
                .frame(height: 250)
            }
        }
    }

    // MARK: - Ingredient Pie Chart

    private var ingredientPieChart: some View {
        chartCard(title: "Top Ingredients", icon: "chart.pie.fill") {
            if viewModel.ingredientData.isEmpty {
                chartEmptyState("No ingredient data for this period")
            } else {
                Chart(viewModel.ingredientData) { slice in
                    SectorMark(
                        angle: .value("Count", slice.count),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .foregroundStyle(by: .value("Ingredient", slice.name))
                    .cornerRadius(4)
                }
                .chartLegend(position: .bottom, alignment: .center, spacing: 12)
                .frame(height: 300)

                // Ingredient list below chart
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.ingredientData) { item in
                        HStack {
                            Text(item.name)
                                .font(.subheadline)
                                .foregroundStyle(ColorTheme.primaryText)
                            Spacer()
                            Text("\(item.count)×")
                                .font(.subheadline.bold())
                                .foregroundStyle(ColorTheme.secondaryText)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Chart Card Wrapper

    private func chartCard<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(ColorTheme.primaryText)

            content()
        }
        .padding()
        .background(ColorTheme.surface)
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    // MARK: - Empty & Error States

    private func chartEmptyState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.title)
                .foregroundStyle(ColorTheme.secondaryText)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(ColorTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(ColorTheme.warning)
            Text("Unable to Load Charts")
                .font(.headline)
                .foregroundStyle(ColorTheme.primaryText)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(ColorTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }

    // MARK: - Helpers

    private func severityAxisLabel(_ level: Int) -> String {
        switch level {
        case 0: return "None"
        case 1: return "Mild"
        case 2: return "Mod"
        default: return "Sev"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SymptomChartsView()
            .environment(AuthService())
            .environment(AppRouter.shared)
    }
}
