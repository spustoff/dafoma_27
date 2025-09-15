import Foundation
import Combine

class ExpenseViewModel: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var analytics: ExpenseAnalytics?
    @Published var selectedCategory: ExpenseCategory?
    @Published var searchText = ""
    @Published var sortOption: ExpenseSortOption = .dateDescending
    @Published var showingAddExpense = false
    @Published var selectedExpense: Expense?
    
    private let dataService = DataService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        loadExpenses()
    }
    
    private func setupBindings() {
        dataService.$expenses
            .receive(on: DispatchQueue.main)
            .sink { [weak self] expenses in
                self?.expenses = expenses
                self?.updateAnalytics()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func loadExpenses() {
        updateAnalytics()
    }
    
    func addExpense(title: String, amount: Double, category: ExpenseCategory, date: Date, description: String? = nil, isRecurring: Bool = false, recurringFrequency: RecurringFrequency? = nil) {
        let expense = Expense(
            title: title,
            amount: amount,
            category: category,
            date: date,
            description: description,
            isRecurring: isRecurring,
            recurringFrequency: recurringFrequency
        )
        dataService.addExpense(expense)
    }
    
    func updateExpense(_ expense: Expense) {
        dataService.updateExpense(expense)
    }
    
    func deleteExpense(_ expense: Expense) {
        dataService.deleteExpense(expense)
    }
    
    func filteredExpenses() -> [Expense] {
        var filtered = expenses
        
        // Filter by category
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { expense in
                expense.title.localizedCaseInsensitiveContains(searchText) ||
                expense.description?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Sort expenses
        return sortExpenses(filtered)
    }
    
    func expensesForCategory(_ category: ExpenseCategory) -> [Expense] {
        return expenses.filter { $0.category == category }
    }
    
    func totalExpensesForMonth(_ date: Date) -> Double {
        let calendar = Calendar.current
        let monthExpenses = expenses.filter { expense in
            calendar.isDate(expense.date, equalTo: date, toGranularity: .month)
        }
        return monthExpenses.reduce(0) { $0 + $1.amount }
    }
    
    func expensesForDateRange(from startDate: Date, to endDate: Date) -> [Expense] {
        return expenses.filter { expense in
            expense.date >= startDate && expense.date <= endDate
        }
    }
    
    // MARK: - Private Methods
    private func sortExpenses(_ expenses: [Expense]) -> [Expense] {
        switch sortOption {
        case .dateAscending:
            return expenses.sorted { $0.date < $1.date }
        case .dateDescending:
            return expenses.sorted { $0.date > $1.date }
        case .amountAscending:
            return expenses.sorted { $0.amount < $1.amount }
        case .amountDescending:
            return expenses.sorted { $0.amount > $1.amount }
        case .titleAscending:
            return expenses.sorted { $0.title < $1.title }
        case .titleDescending:
            return expenses.sorted { $0.title > $1.title }
        case .category:
            return expenses.sorted { $0.category.rawValue < $1.category.rawValue }
        }
    }
    
    private func updateAnalytics() {
        analytics = dataService.getExpenseAnalytics()
    }
    
    // MARK: - Computed Properties
    var totalExpenses: Double {
        return expenses.reduce(0) { $0 + $1.amount }
    }
    
    var averageExpense: Double {
        guard !expenses.isEmpty else { return 0 }
        return totalExpenses / Double(expenses.count)
    }
    
    var expensesByCategory: [ExpenseCategory: [Expense]] {
        return Dictionary(grouping: expenses) { $0.category }
    }
    
    var monthlyExpenses: [String: Double] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        
        let grouped = Dictionary(grouping: expenses) { expense in
            formatter.string(from: expense.date)
        }
        
        return grouped.mapValues { expenses in
            expenses.reduce(0) { $0 + $1.amount }
        }
    }
    
    var topCategories: [(category: ExpenseCategory, amount: Double)] {
        let categoryTotals = expensesByCategory.mapValues { expenses in
            expenses.reduce(0) { $0 + $1.amount }
        }
        
        return categoryTotals.sorted { $0.value > $1.value }
            .map { (category: $0.key, amount: $0.value) }
    }
}

// MARK: - Sort Options
enum ExpenseSortOption: String, CaseIterable {
    case dateDescending = "Date (Newest)"
    case dateAscending = "Date (Oldest)"
    case amountDescending = "Amount (High to Low)"
    case amountAscending = "Amount (Low to High)"
    case titleAscending = "Title (A-Z)"
    case titleDescending = "Title (Z-A)"
    case category = "Category"
}

