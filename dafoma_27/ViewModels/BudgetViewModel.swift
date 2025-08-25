import Foundation
import Combine

class BudgetViewModel: ObservableObject {
    @Published var budgets: [Budget] = []
    @Published var analytics: BudgetAnalytics?
    @Published var alerts: [BudgetAlert] = []
    @Published var selectedBudget: Budget?
    @Published var showingAddBudget = false
    @Published var selectedCategory: ExpenseCategory?
    @Published var selectedPeriod: BudgetPeriod?
    @Published var searchText = ""
    @Published var sortOption: BudgetSortOption = .percentageUsed
    @Published var showOnlyActive = true
    
    private let dataService = DataService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        loadBudgets()
    }
    
    private func setupBindings() {
        dataService.$budgets
            .receive(on: DispatchQueue.main)
            .sink { [weak self] budgets in
                self?.budgets = budgets
                self?.updateAnalytics()
            }
            .store(in: &cancellables)
        
        dataService.$budgetAlerts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] alerts in
                self?.alerts = alerts
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func loadBudgets() {
        updateAnalytics()
    }
    
    func addBudget(name: String, category: ExpenseCategory, limit: Double, period: BudgetPeriod, notifications: Bool = true) {
        let budget = Budget(
            name: name,
            category: category,
            limit: limit,
            period: period,
            notifications: notifications
        )
        dataService.addBudget(budget)
    }
    
    func updateBudget(_ budget: Budget) {
        dataService.updateBudget(budget)
    }
    
    func deleteBudget(_ budget: Budget) {
        dataService.deleteBudget(budget)
    }
    
    func toggleBudgetStatus(_ budget: Budget) {
        var updatedBudget = budget
        updatedBudget.isActive.toggle()
        dataService.updateBudget(updatedBudget)
    }
    
    func renewBudget(_ budget: Budget) {
        var renewedBudget = budget
        renewedBudget.startDate = Date()
        renewedBudget.endDate = budget.period.calculateEndDate(from: Date())
        renewedBudget.spent = 0
        renewedBudget.isActive = true
        dataService.updateBudget(renewedBudget)
    }
    
    func markAlertAsRead(_ alert: BudgetAlert) {
        dataService.markAlertAsRead(alert)
    }
    
    func filteredBudgets() -> [Budget] {
        var filtered = budgets
        
        // Filter by active status
        if showOnlyActive {
            filtered = filtered.filter { $0.isActive }
        }
        
        // Filter by category
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Filter by period
        if let period = selectedPeriod {
            filtered = filtered.filter { $0.period == period }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { budget in
                budget.name.localizedCaseInsensitiveContains(searchText) ||
                budget.category.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort budgets
        return sortBudgets(filtered)
    }
    
    func budgetsForCategory(_ category: ExpenseCategory) -> [Budget] {
        return budgets.filter { $0.category == category && $0.isActive }
    }
    
    func budgetsForStatus(_ status: BudgetStatus) -> [Budget] {
        return budgets.filter { $0.status == status && $0.isActive }
    }
    
    func getBudgetProgress(_ budget: Budget) -> Double {
        return min(1.0, budget.spent / budget.limit)
    }
    
    func getRemainingDays(_ budget: Budget) -> Int {
        let calendar = Calendar.current
        let today = Date()
        let components = calendar.dateComponents([.day], from: today, to: budget.endDate)
        return max(0, components.day ?? 0)
    }
    
    func isExpiringSoon(_ budget: Budget) -> Bool {
        return getRemainingDays(budget) <= 3
    }
    
    // MARK: - Private Methods
    private func sortBudgets(_ budgets: [Budget]) -> [Budget] {
        switch sortOption {
        case .name:
            return budgets.sorted { $0.name < $1.name }
        case .category:
            return budgets.sorted { $0.category.rawValue < $1.category.rawValue }
        case .limit:
            return budgets.sorted { $0.limit > $1.limit }
        case .spent:
            return budgets.sorted { $0.spent > $1.spent }
        case .remaining:
            return budgets.sorted { $0.remaining > $1.remaining }
        case .percentageUsed:
            return budgets.sorted { $0.percentageUsed > $1.percentageUsed }
        case .endDate:
            return budgets.sorted { $0.endDate < $1.endDate }
        case .status:
            return budgets.sorted { $0.status.rawValue < $1.status.rawValue }
        }
    }
    
    private func updateAnalytics() {
        analytics = dataService.getBudgetAnalytics()
    }
    
    // MARK: - Computed Properties
    var activeBudgets: [Budget] {
        return budgets.filter { $0.isActive }
    }
    
    var totalBudgetLimit: Double {
        return activeBudgets.reduce(0) { $0 + $1.limit }
    }
    
    var totalBudgetSpent: Double {
        return activeBudgets.reduce(0) { $0 + $1.spent }
    }
    
    var totalBudgetRemaining: Double {
        return activeBudgets.reduce(0) { $0 + $1.remaining }
    }
    
    var averageBudgetUsage: Double {
        guard !activeBudgets.isEmpty else { return 0 }
        let totalUsage = activeBudgets.reduce(0) { $0 + $1.percentageUsed }
        return totalUsage / Double(activeBudgets.count)
    }
    
    var budgetsExceeded: [Budget] {
        return activeBudgets.filter { $0.status == .exceeded }
    }
    
    var budgetsAtRisk: [Budget] {
        return activeBudgets.filter { $0.status == .warning }
    }
    
    var budgetsOnTrack: [Budget] {
        return activeBudgets.filter { $0.status == .good || $0.status == .onTrack }
    }
    
    var unreadAlerts: [BudgetAlert] {
        return alerts.filter { !$0.isRead }
    }
    
    var budgetsByCategory: [ExpenseCategory: [Budget]] {
        return Dictionary(grouping: activeBudgets) { $0.category }
    }
    
    var budgetsByPeriod: [BudgetPeriod: [Budget]] {
        return Dictionary(grouping: activeBudgets) { $0.period }
    }
    
    var expiringBudgets: [Budget] {
        return activeBudgets.filter { isExpiringSoon($0) }
    }
    
    var categoryPerformance: [(category: ExpenseCategory, performance: Double)] {
        let categoryBudgets = budgetsByCategory
        return categoryBudgets.compactMap { (category, budgets) in
            let totalLimit = budgets.reduce(0) { $0 + $1.limit }
            let totalSpent = budgets.reduce(0) { $0 + $1.spent }
            guard totalLimit > 0 else { return nil }
            let performance = (totalSpent / totalLimit) * 100
            return (category: category, performance: performance)
        }.sorted { $0.performance > $1.performance }
    }
    
    var monthlyBudgetTrend: [String: Double] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        
        let monthlyBudgets = Dictionary(grouping: budgets) { budget in
            formatter.string(from: budget.startDate)
        }
        
        return monthlyBudgets.mapValues { budgets in
            budgets.reduce(0) { $0 + $1.limit }
        }
    }
}

// MARK: - Sort Options
enum BudgetSortOption: String, CaseIterable {
    case percentageUsed = "Usage %"
    case remaining = "Remaining"
    case spent = "Spent"
    case limit = "Limit"
    case endDate = "End Date"
    case name = "Name"
    case category = "Category"
    case status = "Status"
}
