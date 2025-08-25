import SwiftUI

struct ExpenseTrackingView: View {
    @StateObject private var viewModel = ExpenseViewModel()
    @State private var showingAddExpense = false
    @State private var showingFilters = false
    @State private var selectedTimeframe: TimeFrame = .month
    
    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with Stats
                    ExpenseHeaderView(viewModel: viewModel, selectedTimeframe: $selectedTimeframe)
                    
                    // Chart Section
                    ExpenseChartView(viewModel: viewModel, timeframe: selectedTimeframe)
                        .padding(.horizontal, Constants.Spacing.md)
                    
                    // Expense List
                    ExpenseListView(viewModel: viewModel)
                }
            }
            .navigationTitle("Expenses")
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
                    Button(action: { showingAddExpense = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Constants.Colors.primaryButton)
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingFilters) {
                ExpenseFiltersView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Header View
struct ExpenseHeaderView: View {
    @ObservedObject var viewModel: ExpenseViewModel
    @Binding var selectedTimeframe: TimeFrame
    
    var body: some View {
        VStack(spacing: Constants.Spacing.md) {
            // Timeframe Selector
            Picker("Timeframe", selection: $selectedTimeframe) {
                ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                    Text(timeframe.rawValue).tag(timeframe)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, Constants.Spacing.md)
            
            // Stats Cards
            HStack(spacing: Constants.Spacing.md) {
                StatCard(
                    title: "Total Spent",
                    value: "$\(String(format: "%.2f", viewModel.totalExpenses))",
                    icon: "dollarsign.circle.fill",
                    color: Constants.Colors.primaryButton
                )
                
                StatCard(
                    title: "Avg. Daily",
                    value: "$\(String(format: "%.2f", viewModel.averageExpense))",
                    icon: "calendar.circle.fill",
                    color: Constants.Colors.secondaryButton
                )
                
                StatCard(
                    title: "Transactions",
                    value: "\(viewModel.expenses.count)",
                    icon: "list.bullet.circle.fill",
                    color: Constants.Colors.primaryButton
                )
            }
            .padding(.horizontal, Constants.Spacing.md)
        }
        .padding(.vertical, Constants.Spacing.md)
    }
}

// MARK: - Chart View
struct ExpenseChartView: View {
    @ObservedObject var viewModel: ExpenseViewModel
    let timeframe: TimeFrame
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.md) {
            Text("Spending Overview")
                .font(Constants.Fonts.headline)
                .foregroundColor(Constants.Colors.white)
            
            // Fallback for iOS 15.6
            CategoryBreakdownView(categories: viewModel.topCategories)
        }
        .padding()
        .background(Constants.Colors.white.opacity(0.05))
        .cornerRadius(Constants.CornerRadius.large)
    }
    
    private var chartData: [(category: ExpenseCategory, amount: Double)] {
        return viewModel.topCategories.prefix(6).map { $0 }
    }
}

// MARK: - Expense List View
struct ExpenseListView: View {
    @ObservedObject var viewModel: ExpenseViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.md) {
            HStack {
                Text("Recent Transactions")
                    .font(Constants.Fonts.headline)
                    .foregroundColor(Constants.Colors.white)
                
                Spacer()
                
                Menu {
                    ForEach(ExpenseSortOption.allCases, id: \.self) { option in
                        Button(option.rawValue) {
                            viewModel.sortOption = option
                        }
                    }
                } label: {
                    HStack {
                        Text("Sort")
                        Image(systemName: "chevron.down")
                    }
                    .font(Constants.Fonts.caption)
                    .foregroundColor(Constants.Colors.primaryButton)
                }
            }
            .padding(.horizontal, Constants.Spacing.md)
            
            if viewModel.filteredExpenses().isEmpty {
                EmptyStateView(
                    icon: "creditcard.circle",
                    title: "No Expenses Yet",
                    message: "Start tracking your expenses by adding your first transaction."
                )
            } else {
                List {
                    ForEach(viewModel.filteredExpenses()) { expense in
                        ExpenseRowView(expense: expense) {
                            viewModel.selectedExpense = expense
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    .onDelete { indexSet in
                        let expenses = viewModel.filteredExpenses()
                        for index in indexSet {
                            viewModel.deleteExpense(expenses[index])
                        }
                    }
                }
                .listStyle(PlainListStyle())

            }
        }
    }
}

// MARK: - Expense Row View
struct ExpenseRowView: View {
    let expense: Expense
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Constants.Spacing.md) {
                // Category Icon
                Image(systemName: expense.category.icon)
                    .font(.title2)
                    .foregroundColor(Constants.Colors.primaryButton)
                    .frame(width: 40, height: 40)
                    .background(Constants.Colors.primaryButton.opacity(0.2))
                    .cornerRadius(Constants.CornerRadius.medium)
                
                // Expense Details
                VStack(alignment: .leading, spacing: Constants.Spacing.xs) {
                    Text(expense.title)
                        .font(Constants.Fonts.body)
                        .foregroundColor(Constants.Colors.white)
                        .lineLimit(1)
                    
                    HStack {
                        Text(expense.category.rawValue)
                            .font(Constants.Fonts.small)
                            .foregroundColor(Constants.Colors.gray)
                        
                        Spacer()
                        
                        Text(expense.date, style: .date)
                            .font(Constants.Fonts.small)
                            .foregroundColor(Constants.Colors.gray)
                    }
                }
                
                Spacer()
                
                // Amount
                VStack(alignment: .trailing) {
                    Text("-$\(String(format: "%.2f", expense.amount))")
                        .font(Constants.Fonts.headline)
                        .foregroundColor(Constants.Colors.white)
                    
                    if expense.isRecurring {
                        Text("Recurring")
                            .font(Constants.Fonts.small)
                            .foregroundColor(Constants.Colors.secondaryButton)
                    }
                }
            }
            .padding()
            .background(Constants.Colors.white.opacity(0.05))
            .cornerRadius(Constants.CornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Add Expense View
struct AddExpenseView: View {
    @ObservedObject var viewModel: ExpenseViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var amount = ""
    @State private var selectedCategory = ExpenseCategory.other
    @State private var date = Date()
    @State private var description = ""
    @State private var isRecurring = false
    @State private var recurringFrequency = RecurringFrequency.monthly
    
    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.background
                    .ignoresSafeArea()
                
                Form {
                    Section {
                        TextField("Expense Title", text: $title)
                        
                        HStack {
                            Text("$")
                            TextField("0.00", text: $amount)
                                .keyboardType(.decimalPad)
                        }
                        
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(ExpenseCategory.allCases, id: \.self) { category in
                                Label(category.rawValue, systemImage: category.icon)
                                    .tag(category)
                            }
                        }
                        
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                    }
                    
                    Section("Additional Details") {
                        TextField("Description (Optional)", text: $description)
                        
                        Toggle("Recurring Expense", isOn: $isRecurring)
                        
                        if isRecurring {
                            Picker("Frequency", selection: $recurringFrequency) {
                                ForEach(RecurringFrequency.allCases, id: \.self) { frequency in
                                    Text(frequency.rawValue).tag(frequency)
                                }
                            }
                        }
                    }
                }

            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(Constants.Colors.gray),
                trailing: Button("Save") {
                    saveExpense()
                }
                .foregroundColor(Constants.Colors.primaryButton)
                .disabled(title.isEmpty || amount.isEmpty)
            )
        }
    }
    
    private func saveExpense() {
        guard let amountValue = Double(amount), amountValue > 0 else { return }
        
        viewModel.addExpense(
            title: title,
            amount: amountValue,
            category: selectedCategory,
            date: date,
            description: description.isEmpty ? nil : description,
            isRecurring: isRecurring,
            recurringFrequency: isRecurring ? recurringFrequency : nil
        )
        
        dismiss()
    }
}

// MARK: - Filters View
struct ExpenseFiltersView: View {
    @ObservedObject var viewModel: ExpenseViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.background
                    .ignoresSafeArea()
                
                Form {
                    Section("Search") {
                        TextField("Search expenses...", text: $viewModel.searchText)
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
                    
                    Section("Sort By") {
                        Picker("Sort Option", selection: $viewModel.sortOption) {
                            ForEach(ExpenseSortOption.allCases, id: \.self) { option in
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
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Constants.Spacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
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

struct CategoryBreakdownView: View {
    let categories: [(category: ExpenseCategory, amount: Double)]
    
    var body: some View {
        VStack(spacing: Constants.Spacing.sm) {
            ForEach(categories.prefix(5), id: \.category) { item in
                HStack {
                    Image(systemName: item.category.icon)
                        .foregroundColor(Constants.Colors.primaryButton)
                    
                    Text(item.category.rawValue)
                        .font(Constants.Fonts.body)
                        .foregroundColor(Constants.Colors.white)
                    
                    Spacer()
                    
                                            Text("$\(String(format: "%.2f", item.amount))")
                        .font(Constants.Fonts.body)
                        .foregroundColor(Constants.Colors.white)
                }
            }
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: Constants.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(Constants.Colors.gray)
            
            VStack(spacing: Constants.Spacing.sm) {
                Text(title)
                    .font(Constants.Fonts.headline)
                    .foregroundColor(Constants.Colors.white)
                
                Text(message)
                    .font(Constants.Fonts.body)
                    .foregroundColor(Constants.Colors.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Constants.Spacing.xl)
    }
}

// MARK: - TimeFrame Enum
enum TimeFrame: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case quarter = "Quarter"
    case year = "Year"
}

#Preview {
    ExpenseTrackingView()
}
