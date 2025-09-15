import Foundation
import Combine

class DataService: ObservableObject {
    static let shared = DataService()
    
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // MARK: - Published Properties
    @Published var expenses: [Expense] = []
    @Published var investments: [Investment] = []
    @Published var budgets: [Budget] = []
    @Published var newsPreferences = NewsPreferences()
    @Published var budgetAlerts: [BudgetAlert] = []
    
    // MARK: - Keys
    private enum Keys {
        static let expenses = "expenses"
        static let investments = "investments"
        static let budgets = "budgets"
        static let newsPreferences = "newsPreferences"
        static let budgetAlerts = "budgetAlerts"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }
    
    private init() {
        loadData()
    }
    
    // MARK: - Data Loading
    private func loadData() {
        loadExpenses()
        loadInvestments()
        loadBudgets()
        loadNewsPreferences()
        loadBudgetAlerts()
    }
    
    // MARK: - Expense Management
    func addExpense(_ expense: Expense) {
        expenses.append(expense)
        updateBudgetSpending(for: expense)
        saveExpenses()
        checkBudgetAlerts()
    }
    
    func updateExpense(_ expense: Expense) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
            saveExpenses()
            recalculateBudgets()
        }
    }
    
    func deleteExpense(_ expense: Expense) {
        expenses.removeAll { $0.id == expense.id }
        saveExpenses()
        recalculateBudgets()
    }
    
    private func loadExpenses() {
        if let data = userDefaults.data(forKey: Keys.expenses),
           let decodedExpenses = try? decoder.decode([Expense].self, from: data) {
            expenses = decodedExpenses
        }
    }
    
    private func saveExpenses() {
        if let encoded = try? encoder.encode(expenses) {
            userDefaults.set(encoded, forKey: Keys.expenses)
        }
    }
    
    // MARK: - Investment Management
    func addInvestment(_ investment: Investment) {
        investments.append(investment)
        saveInvestments()
    }
    
    func updateInvestment(_ investment: Investment) {
        if let index = investments.firstIndex(where: { $0.id == investment.id }) {
            investments[index] = investment
            saveInvestments()
        }
    }
    
    func deleteInvestment(_ investment: Investment) {
        investments.removeAll { $0.id == investment.id }
        saveInvestments()
    }
    
    func updateInvestmentPrices(_ marketData: [String: MarketData]) {
        for i in 0..<investments.count {
            if let data = marketData[investments[i].symbol] {
                investments[i].currentPrice = data.currentPrice
            }
        }
        saveInvestments()
    }
    
    private func loadInvestments() {
        if let data = userDefaults.data(forKey: Keys.investments),
           let decodedInvestments = try? decoder.decode([Investment].self, from: data) {
            investments = decodedInvestments
        }
    }
    
    private func saveInvestments() {
        if let encoded = try? encoder.encode(investments) {
            userDefaults.set(encoded, forKey: Keys.investments)
        }
    }
    
    // MARK: - Budget Management
    func addBudget(_ budget: Budget) {
        budgets.append(budget)
        saveBudgets()
        recalculateBudgets()
    }
    
    func updateBudget(_ budget: Budget) {
        if let index = budgets.firstIndex(where: { $0.id == budget.id }) {
            budgets[index] = budget
            saveBudgets()
        }
    }
    
    func deleteBudget(_ budget: Budget) {
        budgets.removeAll { $0.id == budget.id }
        saveBudgets()
    }
    
    private func updateBudgetSpending(for expense: Expense) {
        for i in 0..<budgets.count {
            if budgets[i].category == expense.category && budgets[i].isActive {
                let expenseDate = expense.date
                if expenseDate >= budgets[i].startDate && expenseDate <= budgets[i].endDate {
                    budgets[i].spent += expense.amount
                }
            }
        }
        saveBudgets()
    }
    
    private func recalculateBudgets() {
        for i in 0..<budgets.count {
            budgets[i].spent = 0
            let categoryExpenses = expenses.filter { expense in
                expense.category == budgets[i].category &&
                expense.date >= budgets[i].startDate &&
                expense.date <= budgets[i].endDate
            }
            budgets[i].spent = categoryExpenses.reduce(0) { $0 + $1.amount }
        }
        saveBudgets()
    }
    
    private func loadBudgets() {
        if let data = userDefaults.data(forKey: Keys.budgets),
           let decodedBudgets = try? decoder.decode([Budget].self, from: data) {
            budgets = decodedBudgets
        }
    }
    
    private func saveBudgets() {
        if let encoded = try? encoder.encode(budgets) {
            userDefaults.set(encoded, forKey: Keys.budgets)
        }
    }
    
    // MARK: - News Preferences
    func updateNewsPreferences(_ preferences: NewsPreferences) {
        newsPreferences = preferences
        saveNewsPreferences()
    }
    
    private func loadNewsPreferences() {
        if let data = userDefaults.data(forKey: Keys.newsPreferences),
           let decodedPreferences = try? decoder.decode(NewsPreferences.self, from: data) {
            newsPreferences = decodedPreferences
        }
    }
    
    private func saveNewsPreferences() {
        if let encoded = try? encoder.encode(newsPreferences) {
            userDefaults.set(encoded, forKey: Keys.newsPreferences)
        }
    }
    
    // MARK: - Budget Alerts
    private func checkBudgetAlerts() {
        let calendar = Calendar.current
        let today = Date()
        
        for budget in budgets where budget.isActive && budget.notifications {
            let percentage = budget.percentageUsed
            
            // Check for 80% warning
            if percentage >= 80 && percentage < 100 {
                let existingAlert = budgetAlerts.first { alert in
                    alert.budgetId == budget.id && 
                    alert.type == .approaching &&
                    calendar.isDate(alert.date, inSameDayAs: today)
                }
                
                if existingAlert == nil {
                    let alert = BudgetAlert(
                        budgetId: budget.id,
                        type: .approaching,
                        message: "You've used \(Int(percentage))% of your \(budget.name) budget",
                        date: today,
                        isRead: false
                    )
                    budgetAlerts.append(alert)
                }
            }
            
            // Check for exceeded budget
            if percentage >= 100 {
                let existingAlert = budgetAlerts.first { alert in
                    alert.budgetId == budget.id && 
                    alert.type == .exceeded &&
                    calendar.isDate(alert.date, inSameDayAs: today)
                }
                
                if existingAlert == nil {
                    let alert = BudgetAlert(
                        budgetId: budget.id,
                        type: .exceeded,
                        message: "You've exceeded your \(budget.name) budget by $\(String(format: "%.2f", budget.spent - budget.limit))",
                        date: today,
                        isRead: false
                    )
                    budgetAlerts.append(alert)
                }
            }
        }
        
        saveBudgetAlerts()
    }
    
    func markAlertAsRead(_ alert: BudgetAlert) {
        if let index = budgetAlerts.firstIndex(where: { $0.id == alert.id }) {
            budgetAlerts[index] = BudgetAlert(
                budgetId: alert.budgetId,
                type: alert.type,
                message: alert.message,
                date: alert.date,
                isRead: true
            )
            saveBudgetAlerts()
        }
    }
    
    private func loadBudgetAlerts() {
        if let data = userDefaults.data(forKey: Keys.budgetAlerts),
           let decodedAlerts = try? decoder.decode([BudgetAlert].self, from: data) {
            budgetAlerts = decodedAlerts
        }
    }
    
    private func saveBudgetAlerts() {
        if let encoded = try? encoder.encode(budgetAlerts) {
            userDefaults.set(encoded, forKey: Keys.budgetAlerts)
        }
    }
    
    // MARK: - Onboarding
    var hasCompletedOnboarding: Bool {
        get { userDefaults.bool(forKey: Keys.hasCompletedOnboarding) }
        set { userDefaults.set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }
    
    // MARK: - Analytics
    func getExpenseAnalytics() -> ExpenseAnalytics {
        let totalSpent = expenses.reduce(0) { $0 + $1.amount }
        
        var categoryBreakdown: [ExpenseCategory: Double] = [:]
        for expense in expenses {
            categoryBreakdown[expense.category, default: 0] += expense.amount
        }
        
        let sortedCategories = categoryBreakdown.sorted { $0.value > $1.value }
        let topCategories = Array(sortedCategories.prefix(5)).map { (category: $0.key, amount: $0.value) }
        
        // Calculate monthly trend
        let calendar = Calendar.current
        let monthlyExpenses = Dictionary(grouping: expenses) { expense in
            calendar.dateInterval(of: .month, for: expense.date)?.start ?? expense.date
        }
        
        let monthlyTrend = monthlyExpenses.map { (date, expenses) in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"
            return MonthlyExpense(
                month: formatter.string(from: date),
                amount: expenses.reduce(0) { $0 + $1.amount },
                date: date
            )
        }.sorted { $0.date < $1.date }
        
        let averageDaily = expenses.isEmpty ? 0 : totalSpent / Double(expenses.count)
        
        return ExpenseAnalytics(
            totalSpent: totalSpent,
            categoryBreakdown: categoryBreakdown,
            monthlyTrend: monthlyTrend,
            averageDaily: averageDaily,
            topCategories: topCategories
        )
    }
    
    func getInvestmentAnalytics() -> InvestmentAnalytics {
        let portfolio = Portfolio(investments: investments)
        
        let bestPerformer = investments.max { $0.gainLossPercentage < $1.gainLossPercentage }
        let worstPerformer = investments.min { $0.gainLossPercentage < $1.gainLossPercentage }
        
        var typeBreakdown: [InvestmentType: Double] = [:]
        for investment in investments {
            typeBreakdown[investment.type, default: 0] += investment.totalValue
        }
        
        return InvestmentAnalytics(
            portfolioValue: portfolio.totalValue,
            totalGainLoss: portfolio.totalGainLoss,
            gainLossPercentage: portfolio.totalGainLossPercentage,
            bestPerformer: bestPerformer,
            worstPerformer: worstPerformer,
            typeBreakdown: typeBreakdown,
            monthlyPerformance: []
        )
    }
    
    func getBudgetAnalytics() -> BudgetAnalytics {
        let activeBudgets = budgets.filter { $0.isActive }
        let totalLimit = activeBudgets.reduce(0) { $0 + $1.limit }
        let totalSpent = activeBudgets.reduce(0) { $0 + $1.spent }
        let averageUsage = activeBudgets.isEmpty ? 0 : activeBudgets.reduce(0) { $0 + $1.percentageUsed } / Double(activeBudgets.count)
        
        let budgetsExceeded = activeBudgets.filter { $0.status == .exceeded }.count
        let budgetsOnTrack = activeBudgets.filter { $0.status == .good || $0.status == .onTrack }.count
        
        var categoryPerformance: [ExpenseCategory: BudgetPerformance] = [:]
        for budget in activeBudgets {
            categoryPerformance[budget.category] = BudgetPerformance(
                category: budget.category,
                budgeted: budget.limit,
                spent: budget.spent,
                remaining: budget.remaining,
                percentageUsed: budget.percentageUsed,
                status: budget.status
            )
        }
        
        return BudgetAnalytics(
            totalBudgets: budgets.count,
            activeBudgets: activeBudgets.count,
            totalLimit: totalLimit,
            totalSpent: totalSpent,
            averageUsage: averageUsage,
            budgetsExceeded: budgetsExceeded,
            budgetsOnTrack: budgetsOnTrack,
            categoryPerformance: categoryPerformance
        )
    }
}

