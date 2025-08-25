import SwiftUI

struct BudgetTrackingView: View {
    @StateObject private var viewModel = BudgetViewModel()
    @State private var showingAddBudget = false
    @State private var showingFilters = false
    @State private var selectedTab: BudgetTab = .overview
    
    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab Selector
                    BudgetTabSelector(selectedTab: $selectedTab)
                    
                    // Content based on selected tab
                    switch selectedTab {
                    case .overview:
                        BudgetOverviewView(viewModel: viewModel)
                    case .budgets:
                        BudgetListView(viewModel: viewModel)
                    case .alerts:
                        BudgetAlertsView(viewModel: viewModel)
                    }
                }
            }
            .navigationTitle("Budgets")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingFilters = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(Constants.Colors.primaryButton)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddBudget = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Constants.Colors.primaryButton)
                    }
                }
            }
            .sheet(isPresented: $showingAddBudget) {
                AddBudgetView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingFilters) {
                BudgetFiltersView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Tab Selector
struct BudgetTabSelector: View {
    @Binding var selectedTab: BudgetTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(BudgetTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(Constants.Animation.standard) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: Constants.Spacing.xs) {
                        Image(systemName: tab.icon)
                            .font(.title3)
                        
                        Text(tab.title)
                            .font(Constants.Fonts.caption)
                    }
                    .foregroundColor(selectedTab == tab ? Constants.Colors.primaryButton : Constants.Colors.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Constants.Spacing.md)
                }
            }
        }
        .background(Constants.Colors.white.opacity(0.05))
        .cornerRadius(Constants.CornerRadius.medium)
        .padding(.horizontal, Constants.Spacing.md)
    }
}

// MARK: - Budget Overview View
struct BudgetOverviewView: View {
    @ObservedObject var viewModel: BudgetViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.Spacing.lg) {
                // Budget Summary
                BudgetSummaryCard(viewModel: viewModel)
                
                // Budget Status Overview
                BudgetStatusOverview(viewModel: viewModel)
                
                // Category Performance
                CategoryPerformanceView(viewModel: viewModel)
                
                // Expiring Budgets
                if !viewModel.expiringBudgets.isEmpty {
                    ExpiringBudgetsView(viewModel: viewModel)
                }
            }
            .padding(.horizontal, Constants.Spacing.md)
        }
    }
}

// MARK: - Budget List View
struct BudgetListView: View {
    @ObservedObject var viewModel: BudgetViewModel
    
    var body: some View {
        VStack(spacing: Constants.Spacing.md) {
            // Search and Filter
            HStack {
                TextField("Search budgets...", text: $viewModel.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Toggle("Active Only", isOn: $viewModel.showOnlyActive)
                    .font(Constants.Fonts.caption)
                    .tint(Constants.Colors.primaryButton)
            }
            .padding(.horizontal, Constants.Spacing.md)
            
            // Budget List
            if viewModel.filteredBudgets().isEmpty {
                EmptyStateView(
                    icon: "target",
                    title: "No Budgets Yet",
                    message: "Create your first budget to start tracking your spending goals."
                )
            } else {
                List {
                    ForEach(viewModel.filteredBudgets()) { budget in
                        BudgetRowView(budget: budget, viewModel: viewModel) {
                            viewModel.selectedBudget = budget
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    .onDelete { indexSet in
                        let budgets = viewModel.filteredBudgets()
                        for index in indexSet {
                            viewModel.deleteBudget(budgets[index])
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
}

// MARK: - Budget Alerts View
struct BudgetAlertsView: View {
    @ObservedObject var viewModel: BudgetViewModel
    
    var body: some View {
        VStack(spacing: Constants.Spacing.md) {
            if viewModel.alerts.isEmpty {
                EmptyStateView(
                    icon: "bell.circle",
                    title: "No Alerts",
                    message: "You'll see budget alerts and notifications here when they're available."
                )
            } else {
                List {
                    ForEach(viewModel.alerts.sorted { $0.date > $1.date }) { alert in
                        BudgetAlertRowView(alert: alert, viewModel: viewModel)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .padding(.horizontal, Constants.Spacing.md)
    }
}

// MARK: - Budget Summary Card
struct BudgetSummaryCard: View {
    @ObservedObject var viewModel: BudgetViewModel
    
    var body: some View {
        VStack(spacing: Constants.Spacing.md) {
            HStack {
                Text("Budget Overview")
                    .font(Constants.Fonts.headline)
                    .foregroundColor(Constants.Colors.white)
                
                Spacer()
                
                Text("\(viewModel.activeBudgets.count) Active")
                    .font(Constants.Fonts.caption)
                    .foregroundColor(Constants.Colors.gray)
            }
            
            HStack(spacing: Constants.Spacing.lg) {
                VStack(alignment: .leading, spacing: Constants.Spacing.sm) {
                    Text("Total Budget")
                        .font(Constants.Fonts.caption)
                        .foregroundColor(Constants.Colors.gray)
                    
                    Text("$\(viewModel.totalBudgetLimit, specifier: "%.2f")")
                        .font(Constants.Fonts.title)
                        .foregroundColor(Constants.Colors.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: Constants.Spacing.sm) {
                    Text("Spent")
                        .font(Constants.Fonts.caption)
                        .foregroundColor(Constants.Colors.gray)
                    
                    Text("$\(viewModel.totalBudgetSpent, specifier: "%.2f")")
                        .font(Constants.Fonts.headline)
                        .foregroundColor(Constants.Colors.primaryButton)
                }
                
                VStack(alignment: .trailing, spacing: Constants.Spacing.sm) {
                    Text("Remaining")
                        .font(Constants.Fonts.caption)
                        .foregroundColor(Constants.Colors.gray)
                    
                    Text("$\(viewModel.totalBudgetRemaining, specifier: "%.2f")")
                        .font(Constants.Fonts.headline)
                        .foregroundColor(Constants.Colors.secondaryButton)
                }
            }
            
            // Progress Bar
            ProgressView(value: viewModel.totalBudgetSpent, total: viewModel.totalBudgetLimit)
                .tint(Constants.Colors.primaryButton)
                .scaleEffect(y: 2)
        }
        .padding()
        .background(Constants.Colors.white.opacity(0.05))
        .cornerRadius(Constants.CornerRadius.large)
    }
}

// MARK: - Budget Status Overview
struct BudgetStatusOverview: View {
    @ObservedObject var viewModel: BudgetViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.md) {
            Text("Budget Status")
                .font(Constants.Fonts.headline)
                .foregroundColor(Constants.Colors.white)
            
            HStack(spacing: Constants.Spacing.md) {
                StatusCard(
                    title: "On Track",
                    count: viewModel.budgetsOnTrack.count,
                    color: Constants.Colors.secondaryButton,
                    icon: "checkmark.circle.fill"
                )
                
                StatusCard(
                    title: "At Risk",
                    count: viewModel.budgetsAtRisk.count,
                    color: Constants.Colors.primaryButton,
                    icon: "exclamationmark.triangle.fill"
                )
                
                StatusCard(
                    title: "Exceeded",
                    count: viewModel.budgetsExceeded.count,
                    color: Color.red,
                    icon: "xmark.circle.fill"
                )
            }
        }
        .padding()
        .background(Constants.Colors.white.opacity(0.05))
        .cornerRadius(Constants.CornerRadius.large)
    }
}

// MARK: - Category Performance View
struct CategoryPerformanceView: View {
    @ObservedObject var viewModel: BudgetViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.md) {
            Text("Category Performance")
                .font(Constants.Fonts.headline)
                .foregroundColor(Constants.Colors.white)
            
            ForEach(viewModel.categoryPerformance.prefix(5), id: \.category) { performance in
                CategoryPerformanceRow(
                    category: performance.category,
                    percentage: performance.performance
                )
            }
        }
        .padding()
        .background(Constants.Colors.white.opacity(0.05))
        .cornerRadius(Constants.CornerRadius.large)
    }
}

// MARK: - Budget Row View
struct BudgetRowView: View {
    let budget: Budget
    @ObservedObject var viewModel: BudgetViewModel
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Constants.Spacing.md) {
                HStack {
                    // Category Icon
                    Image(systemName: budget.category.icon)
                        .font(.title2)
                        .foregroundColor(Constants.Colors.primaryButton)
                        .frame(width: 40, height: 40)
                        .background(Constants.Colors.primaryButton.opacity(0.2))
                        .cornerRadius(Constants.CornerRadius.medium)
                    
                    // Budget Details
                    VStack(alignment: .leading, spacing: Constants.Spacing.xs) {
                        Text(budget.name)
                            .font(Constants.Fonts.body)
                            .foregroundColor(Constants.Colors.white)
                            .lineLimit(1)
                        
                        Text(budget.category.rawValue)
                            .font(Constants.Fonts.small)
                            .foregroundColor(Constants.Colors.gray)
                        
                        Text("\(viewModel.getRemainingDays(budget)) days left")
                            .font(Constants.Fonts.small)
                            .foregroundColor(viewModel.isExpiringSoon(budget) ? Constants.Colors.primaryButton : Constants.Colors.gray)
                    }
                    
                    Spacer()
                    
                    // Budget Status
                    VStack(alignment: .trailing, spacing: Constants.Spacing.xs) {
                        Text("$\(budget.spent, specifier: "%.0f") / $\(budget.limit, specifier: "%.0f")")
                            .font(Constants.Fonts.body)
                            .foregroundColor(Constants.Colors.white)
                        
                        Text("\(budget.percentageUsed, specifier: "%.0f")% used")
                            .font(Constants.Fonts.small)
                            .foregroundColor(Color(hex: budget.status.color))
                        
                        if !budget.isActive {
                            Text("Inactive")
                                .font(Constants.Fonts.small)
                                .foregroundColor(Constants.Colors.gray)
                        }
                    }
                }
                
                // Progress Bar
                ProgressView(value: budget.spent, total: budget.limit)
                    .tint(Color(hex: budget.status.color))
                    .scaleEffect(y: 1.5)
            }
            .padding()
            .background(Constants.Colors.white.opacity(0.05))
            .cornerRadius(Constants.CornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(action: { viewModel.toggleBudgetStatus(budget) }) {
                Label(budget.isActive ? "Deactivate" : "Activate", systemImage: budget.isActive ? "pause.circle" : "play.circle")
            }
            
            Button(action: { viewModel.renewBudget(budget) }) {
                Label("Renew Budget", systemImage: "arrow.clockwise")
            }
            
            Button(role: .destructive, action: { viewModel.deleteBudget(budget) }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Budget Alert Row View
struct BudgetAlertRowView: View {
    let alert: BudgetAlert
    @ObservedObject var viewModel: BudgetViewModel
    
    var body: some View {
        HStack(spacing: Constants.Spacing.md) {
            // Alert Icon
            Image(systemName: alertIcon)
                .font(.title2)
                .foregroundColor(alertColor)
                .frame(width: 40, height: 40)
                .background(alertColor.opacity(0.2))
                .cornerRadius(Constants.CornerRadius.medium)
            
            // Alert Details
            VStack(alignment: .leading, spacing: Constants.Spacing.xs) {
                Text(alert.type.rawValue)
                    .font(Constants.Fonts.body)
                    .foregroundColor(Constants.Colors.white)
                
                Text(alert.message)
                    .font(Constants.Fonts.small)
                    .foregroundColor(Constants.Colors.gray)
                    .lineLimit(2)
                
                Text(alert.date, style: .relative)
                    .font(Constants.Fonts.small)
                    .foregroundColor(Constants.Colors.gray)
            }
            
            Spacer()
            
            // Read Status
            if !alert.isRead {
                Circle()
                    .fill(Constants.Colors.primaryButton)
                    .frame(width: 8, height: 8)
            }
        }
        .padding()
        .background(alert.isRead ? Constants.Colors.white.opacity(0.02) : Constants.Colors.white.opacity(0.08))
        .cornerRadius(Constants.CornerRadius.medium)
        .onTapGesture {
            if !alert.isRead {
                viewModel.markAlertAsRead(alert)
            }
        }
    }
    
    private var alertIcon: String {
        switch alert.type {
        case .approaching: return "exclamationmark.triangle.fill"
        case .exceeded: return "xmark.circle.fill"
        case .renewed: return "arrow.clockwise.circle.fill"
        case .achievement: return "checkmark.circle.fill"
        }
    }
    
    private var alertColor: Color {
        switch alert.type {
        case .approaching: return Constants.Colors.primaryButton
        case .exceeded: return Color.red
        case .renewed: return Constants.Colors.secondaryButton
        case .achievement: return Constants.Colors.secondaryButton
        }
    }
}

// MARK: - Add Budget View
struct AddBudgetView: View {
    @ObservedObject var viewModel: BudgetViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedCategory = ExpenseCategory.other
    @State private var limit = ""
    @State private var selectedPeriod = BudgetPeriod.monthly
    @State private var notifications = true
    
    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.background
                    .ignoresSafeArea()
                
                Form {
                    Section("Budget Details") {
                        TextField("Budget Name", text: $name)
                        
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(ExpenseCategory.allCases, id: \.self) { category in
                                Label(category.rawValue, systemImage: category.icon)
                                    .tag(category)
                            }
                        }
                        
                        HStack {
                            Text("Limit")
                            Spacer()
                            HStack {
                                Text("$")
                                TextField("0.00", text: $limit)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                        
                        Picker("Period", selection: $selectedPeriod) {
                            ForEach(BudgetPeriod.allCases, id: \.self) { period in
                                Text(period.rawValue).tag(period)
                            }
                        }
                    }
                    
                    Section("Settings") {
                        Toggle("Enable Notifications", isOn: $notifications)
                    }
                }

            }
            .navigationTitle("Add Budget")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Constants.Colors.gray)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBudget()
                    }
                    .foregroundColor(Constants.Colors.primaryButton)
                    .disabled(name.isEmpty || limit.isEmpty)
                }
            }
        }
    }
    
    private func saveBudget() {
        guard let limitValue = Double(limit), limitValue > 0 else { return }
        
        viewModel.addBudget(
            name: name,
            category: selectedCategory,
            limit: limitValue,
            period: selectedPeriod,
            notifications: notifications
        )
        
        dismiss()
    }
}

// MARK: - Budget Filters View
struct BudgetFiltersView: View {
    @ObservedObject var viewModel: BudgetViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.background
                    .ignoresSafeArea()
                
                Form {
                    Section("Search") {
                        TextField("Search budgets...", text: $viewModel.searchText)
                    }
                    
                    Section("Category") {
                        Picker("Category", selection: $viewModel.selectedCategory) {
                            Text("All Categories").tag(nil as ExpenseCategory?)
                            ForEach(ExpenseCategory.allCases, id: \.self) { category in
                                Label(category.rawValue, systemImage: category.icon)
                                    .tag(category as ExpenseCategory?)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                    }
                    
                    Section("Period") {
                        Picker("Period", selection: $viewModel.selectedPeriod) {
                            Text("All Periods").tag(nil as BudgetPeriod?)
                            ForEach(BudgetPeriod.allCases, id: \.self) { period in
                                Text(period.rawValue).tag(period as BudgetPeriod?)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                    }
                    
                    Section("Options") {
                        Toggle("Show Only Active", isOn: $viewModel.showOnlyActive)
                    }
                    
                    Section("Sort By") {
                        Picker("Sort Option", selection: $viewModel.sortOption) {
                            ForEach(BudgetSortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                    }
                }

            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Constants.Colors.primaryButton)
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct StatusCard: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: Constants.Spacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text("\(count)")
                .font(Constants.Fonts.headline)
                .foregroundColor(Constants.Colors.white)
            
            Text(title)
                .font(Constants.Fonts.small)
                .foregroundColor(Constants.Colors.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Constants.Colors.white.opacity(0.05))
        .cornerRadius(Constants.CornerRadius.medium)
    }
}

struct CategoryPerformanceRow: View {
    let category: ExpenseCategory
    let percentage: Double
    
    var body: some View {
        HStack {
            Image(systemName: category.icon)
                .foregroundColor(Constants.Colors.primaryButton)
                .frame(width: 20)
            
            Text(category.rawValue)
                .font(Constants.Fonts.body)
                .foregroundColor(Constants.Colors.white)
            
            Spacer()
            
            Text("\(percentage, specifier: "%.0f")%")
                .font(Constants.Fonts.body)
                .foregroundColor(percentage > 100 ? Color.red : percentage > 80 ? Constants.Colors.primaryButton : Constants.Colors.secondaryButton)
        }
        .padding(.vertical, Constants.Spacing.xs)
    }
}

struct ExpiringBudgetsView: View {
    @ObservedObject var viewModel: BudgetViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.md) {
            Text("Expiring Soon")
                .font(Constants.Fonts.headline)
                .foregroundColor(Constants.Colors.white)
            
            ForEach(viewModel.expiringBudgets) { budget in
                HStack {
                    Image(systemName: budget.category.icon)
                        .foregroundColor(Constants.Colors.primaryButton)
                    
                    VStack(alignment: .leading) {
                        Text(budget.name)
                            .font(Constants.Fonts.body)
                            .foregroundColor(Constants.Colors.white)
                        
                        Text("\(viewModel.getRemainingDays(budget)) days left")
                            .font(Constants.Fonts.small)
                            .foregroundColor(Constants.Colors.gray)
                    }
                    
                    Spacer()
                    
                    Button("Renew") {
                        viewModel.renewBudget(budget)
                    }
                    .font(Constants.Fonts.caption)
                    .foregroundColor(Constants.Colors.background)
                    .padding(.horizontal, Constants.Spacing.md)
                    .padding(.vertical, Constants.Spacing.xs)
                    .background(Constants.Colors.primaryButton)
                    .cornerRadius(Constants.CornerRadius.small)
                }
                .padding(.vertical, Constants.Spacing.xs)
            }
        }
        .padding()
        .background(Constants.Colors.white.opacity(0.05))
        .cornerRadius(Constants.CornerRadius.large)
    }
}

// MARK: - Budget Tab Enum
enum BudgetTab: String, CaseIterable {
    case overview = "Overview"
    case budgets = "Budgets"
    case alerts = "Alerts"
    
    var title: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .overview: return "chart.pie.fill"
        case .budgets: return "list.bullet"
        case .alerts: return "bell.fill"
        }
    }
}

#Preview {
    BudgetTrackingView()
}
