import SwiftUI
import Charts

struct InvestmentTrackingView: View {
    @StateObject private var viewModel = InvestmentViewModel()
    @State private var showingAddInvestment = false
    @State private var showingFilters = false
    @State private var selectedTab: InvestmentTab = .portfolio
    
    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab Selector
                    InvestmentTabSelector(selectedTab: $selectedTab)
                    
                    // Content based on selected tab
                    switch selectedTab {
                    case .portfolio:
                        PortfolioView(viewModel: viewModel)
                    case .performance:
                        PerformanceView(viewModel: viewModel)
                    case .holdings:
                        HoldingsView(viewModel: viewModel)
                    }
                }
            }
            .navigationTitle("Investments")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { viewModel.refreshMarketData() }) {
                        Image(systemName: "arrow.clockwise.circle")
                            .foregroundColor(Constants.Colors.primaryButton)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddInvestment = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Constants.Colors.primaryButton)
                    }
                }
            }
            .sheet(isPresented: $showingAddInvestment) {
                AddInvestmentView(viewModel: viewModel)
            }
            .refreshable {
                viewModel.refreshMarketData()
            }
        }
    }
}

// MARK: - Tab Selector
struct InvestmentTabSelector: View {
    @Binding var selectedTab: InvestmentTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(InvestmentTab.allCases, id: \.self) { tab in
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

// MARK: - Portfolio View
struct PortfolioView: View {
    @ObservedObject var viewModel: InvestmentViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.Spacing.lg) {
                // Portfolio Summary
                PortfolioSummaryCard(viewModel: viewModel)
                
                // Performance Chart
                PortfolioPerformanceChart(viewModel: viewModel)
                
                // Asset Allocation
                AssetAllocationView(viewModel: viewModel)
                
                // Top Performers
                TopPerformersView(viewModel: viewModel)
            }
            .padding(.horizontal, Constants.Spacing.md)
        }
    }
}

// MARK: - Performance View
struct PerformanceView: View {
    @ObservedObject var viewModel: InvestmentViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.Spacing.lg) {
                // Performance Metrics
                PerformanceMetricsView(viewModel: viewModel)
                
                // Performance Chart
                if #available(iOS 16.0, *) {
                    PerformanceChartView(viewModel: viewModel)
                } else {
                    PerformanceListView(viewModel: viewModel)
                }
                
                // Best/Worst Performers
                BestWorstPerformersView(viewModel: viewModel)
            }
            .padding(.horizontal, Constants.Spacing.md)
        }
    }
}

// MARK: - Holdings View
struct HoldingsView: View {
    @ObservedObject var viewModel: InvestmentViewModel
    
    var body: some View {
        VStack(spacing: Constants.Spacing.md) {
            // Search and Filter
            HStack {
                TextField("Search investments...", text: $viewModel.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Menu {
                    ForEach(InvestmentSortOption.allCases, id: \.self) { option in
                        Button(option.rawValue) {
                            viewModel.sortOption = option
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(Constants.Colors.primaryButton)
                }
            }
            .padding(.horizontal, Constants.Spacing.md)
            
            // Holdings List
            if viewModel.filteredInvestments().isEmpty {
                EmptyStateView(
                    icon: "chart.line.uptrend.xyaxis.circle",
                    title: "No Investments Yet",
                    message: "Start building your portfolio by adding your first investment."
                )
            } else {
                List {
                    ForEach(viewModel.filteredInvestments()) { investment in
                        InvestmentRowView(investment: investment, marketData: viewModel.marketData[investment.symbol]) {
                            viewModel.selectedInvestment = investment
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    .onDelete { indexSet in
                        let investments = viewModel.filteredInvestments()
                        for index in indexSet {
                            viewModel.deleteInvestment(investments[index])
                        }
                    }
                }
                .listStyle(PlainListStyle())

            }
        }
    }
}

// MARK: - Portfolio Summary Card
struct PortfolioSummaryCard: View {
    @ObservedObject var viewModel: InvestmentViewModel
    
    var body: some View {
        VStack(spacing: Constants.Spacing.md) {
            HStack {
                Text("Portfolio Value")
                    .font(Constants.Fonts.headline)
                    .foregroundColor(Constants.Colors.white)
                
                Spacer()
                
                if viewModel.isLoadingMarketData {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(Constants.Colors.primaryButton)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: Constants.Spacing.sm) {
                    Text("$\(String(format: "%.2f", viewModel.totalPortfolioValue))")
                        .font(Constants.Fonts.title)
                        .foregroundColor(Constants.Colors.white)
                    
                    HStack {
                        Image(systemName: viewModel.totalGainLoss >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .foregroundColor(viewModel.totalGainLoss >= 0 ? Constants.Colors.secondaryButton : Color.red)
                        
                        Text("\(viewModel.totalGainLoss >= 0 ? "+" : "")$\(String(format: "%.2f", viewModel.totalGainLoss))")
                            .font(Constants.Fonts.body)
                            .foregroundColor(viewModel.totalGainLoss >= 0 ? Constants.Colors.secondaryButton : Color.red)
                        
                        Text("(\(String(format: "%.2f", viewModel.totalGainLossPercentage))%)")
                            .font(Constants.Fonts.body)
                            .foregroundColor(Constants.Colors.gray)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: Constants.Spacing.sm) {
                    Text("Diversification")
                        .font(Constants.Fonts.caption)
                        .foregroundColor(Constants.Colors.gray)
                    
                    Text("\(String(format: "%.0f", viewModel.diversificationScore))%")
                        .font(Constants.Fonts.headline)
                        .foregroundColor(Constants.Colors.primaryButton)
                }
            }
        }
        .padding()
        .background(Constants.Colors.white.opacity(0.05))
        .cornerRadius(Constants.CornerRadius.large)
    }
}

// MARK: - Asset Allocation View
struct AssetAllocationView: View {
    @ObservedObject var viewModel: InvestmentViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.md) {
            Text("Asset Allocation")
                .font(Constants.Fonts.headline)
                .foregroundColor(Constants.Colors.white)
            
            // Portfolio breakdown for iOS 15.6 compatibility
            VStack(spacing: Constants.Spacing.sm) {
                ForEach(Array(viewModel.typeBreakdown.keys), id: \.self) { type in
                    HStack {
                        Image(systemName: type.icon)
                            .foregroundColor(Constants.Colors.primaryButton)
                        
                        Text(type.rawValue)
                            .font(Constants.Fonts.body)
                            .foregroundColor(Constants.Colors.white)
                        
                        Spacer()
                        
                        Text("$\(String(format: "%.2f", viewModel.typeBreakdown[type] ?? 0))")
                            .font(Constants.Fonts.body)
                            .foregroundColor(Constants.Colors.white)
                    }
                }
            }
        }
        .padding()
        .background(Constants.Colors.white.opacity(0.05))
        .cornerRadius(Constants.CornerRadius.large)
    }
}

// MARK: - Investment Row View
struct InvestmentRowView: View {
    let investment: Investment
    let marketData: MarketData?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Constants.Spacing.md) {
                // Investment Icon
                Image(systemName: investment.type.icon)
                    .font(.title2)
                    .foregroundColor(Constants.Colors.primaryButton)
                    .frame(width: 40, height: 40)
                    .background(Constants.Colors.primaryButton.opacity(0.2))
                    .cornerRadius(Constants.CornerRadius.medium)
                
                // Investment Details
                VStack(alignment: .leading, spacing: Constants.Spacing.xs) {
                    Text(investment.symbol)
                        .font(Constants.Fonts.headline)
                        .foregroundColor(Constants.Colors.white)
                    
                    Text(investment.name)
                        .font(Constants.Fonts.caption)
                        .foregroundColor(Constants.Colors.gray)
                        .lineLimit(1)
                    
                    Text("\(String(format: "%.2f", investment.shares)) shares")
                        .font(Constants.Fonts.small)
                        .foregroundColor(Constants.Colors.gray)
                }
                
                Spacer()
                
                // Performance
                VStack(alignment: .trailing, spacing: Constants.Spacing.xs) {
                    Text("$\(String(format: "%.2f", investment.totalValue))")
                        .font(Constants.Fonts.headline)
                        .foregroundColor(Constants.Colors.white)
                    
                    HStack {
                        Image(systemName: investment.gainLoss >= 0 ? "arrow.up" : "arrow.down")
                            .font(.caption)
                        
                        Text("\(String(format: "%.2f", investment.gainLossPercentage))%")
                            .font(Constants.Fonts.caption)
                    }
                    .foregroundColor(investment.gainLoss >= 0 ? Constants.Colors.secondaryButton : Color.red)
                    
                    if let data = marketData {
                        Text("$\(String(format: "%.2f", data.currentPrice))")
                            .font(Constants.Fonts.small)
                            .foregroundColor(Constants.Colors.gray)
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

// MARK: - Add Investment View
struct AddInvestmentView: View {
    @ObservedObject var viewModel: InvestmentViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var symbol = ""
    @State private var name = ""
    @State private var shares = ""
    @State private var purchasePrice = ""
    @State private var currentPrice = ""
    @State private var selectedType = InvestmentType.stock
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.background
                    .ignoresSafeArea()
                
                Form {
                    Section("Investment Details") {
                        TextField("Symbol (e.g., AAPL)", text: $symbol)
                            .textInputAutocapitalization(.characters)
                        
                        TextField("Company Name", text: $name)
                        
                        Picker("Type", selection: $selectedType) {
                            ForEach(InvestmentType.allCases, id: \.self) { type in
                                Label(type.rawValue, systemImage: type.icon)
                                    .tag(type)
                            }
                        }
                    }
                    
                    Section("Purchase Information") {
                        HStack {
                            Text("Shares")
                            Spacer()
                            TextField("0", text: $shares)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        HStack {
                            Text("Purchase Price")
                            Spacer()
                            HStack {
                                Text("$")
                                TextField("0.00", text: $purchasePrice)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                        
                        HStack {
                            Text("Current Price")
                            Spacer()
                            HStack {
                                Text("$")
                                TextField("0.00", text: $currentPrice)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    }
                    
                    Section("Notes") {
                        TextField("Additional notes (Optional)", text: $notes)
                    }
                }

            }
            .navigationTitle("Add Investment")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(Constants.Colors.gray),
                trailing: Button("Save") {
                    saveInvestment()
                }
                .foregroundColor(Constants.Colors.primaryButton)
                .disabled(!isFormValid)
            )
        }
    }
    
    private var isFormValid: Bool {
        return !symbol.isEmpty && !name.isEmpty && 
               !shares.isEmpty && !purchasePrice.isEmpty && !currentPrice.isEmpty &&
               Double(shares) != nil && Double(purchasePrice) != nil && Double(currentPrice) != nil
    }
    
    private func saveInvestment() {
        guard let sharesValue = Double(shares),
              let purchasePriceValue = Double(purchasePrice),
              let currentPriceValue = Double(currentPrice) else { return }
        
        viewModel.addInvestment(
            symbol: symbol.uppercased(),
            name: name,
            shares: sharesValue,
            purchasePrice: purchasePriceValue,
            currentPrice: currentPriceValue,
            type: selectedType,
            notes: notes.isEmpty ? nil : notes
        )
        
        dismiss()
    }
}

// MARK: - Supporting Views
struct TopPerformersView: View {
    @ObservedObject var viewModel: InvestmentViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.md) {
            Text("Top Performers")
                .font(Constants.Fonts.headline)
                .foregroundColor(Constants.Colors.white)
            
            ForEach(viewModel.topPerformers) { investment in
                HStack {
                    VStack(alignment: .leading) {
                        Text(investment.symbol)
                            .font(Constants.Fonts.body)
                            .foregroundColor(Constants.Colors.white)
                        
                        Text(investment.name)
                            .font(Constants.Fonts.small)
                            .foregroundColor(Constants.Colors.gray)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("\(String(format: "%.2f", investment.gainLossPercentage))%")
                            .font(Constants.Fonts.body)
                            .foregroundColor(investment.gainLoss >= 0 ? Constants.Colors.secondaryButton : Color.red)
                        
                        Text("$\(String(format: "%.2f", investment.totalValue))")
                            .font(Constants.Fonts.small)
                            .foregroundColor(Constants.Colors.gray)
                    }
                }
                .padding(.vertical, Constants.Spacing.xs)
            }
        }
        .padding()
        .background(Constants.Colors.white.opacity(0.05))
        .cornerRadius(Constants.CornerRadius.large)
    }
}

struct PerformanceMetricsView: View {
    @ObservedObject var viewModel: InvestmentViewModel
    
    var body: some View {
        HStack(spacing: Constants.Spacing.md) {
            StatCard(
                title: "Total Return",
                value: "$\(String(format: "%.2f", viewModel.totalGainLoss))",
                icon: "chart.line.uptrend.xyaxis",
                color: viewModel.totalGainLoss >= 0 ? Constants.Colors.secondaryButton : Color.red
            )
            
            StatCard(
                title: "Return %",
                value: "\(String(format: "%.2f", viewModel.totalGainLossPercentage))%",
                icon: "percent",
                color: viewModel.totalGainLossPercentage >= 0 ? Constants.Colors.secondaryButton : Color.red
            )
        }
    }
}

struct PerformanceListView: View {
    @ObservedObject var viewModel: InvestmentViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.md) {
            Text("Performance Breakdown")
                .font(Constants.Fonts.headline)
                .foregroundColor(Constants.Colors.white)
            
            ForEach(viewModel.investments.sorted { $0.gainLossPercentage > $1.gainLossPercentage }) { investment in
                HStack {
                    Text(investment.symbol)
                        .font(Constants.Fonts.body)
                        .foregroundColor(Constants.Colors.white)
                    
                    Spacer()
                    
                    Text("\(String(format: "%.2f", investment.gainLossPercentage))%")
                        .font(Constants.Fonts.body)
                        .foregroundColor(investment.gainLoss >= 0 ? Constants.Colors.secondaryButton : Color.red)
                }
            }
        }
        .padding()
        .background(Constants.Colors.white.opacity(0.05))
        .cornerRadius(Constants.CornerRadius.large)
    }
}

struct BestWorstPerformersView: View {
    @ObservedObject var viewModel: InvestmentViewModel
    
    var body: some View {
        HStack(spacing: Constants.Spacing.md) {
            if let best = viewModel.bestPerformer {
                PerformerCard(title: "Best Performer", investment: best, isPositive: true)
            }
            
            if let worst = viewModel.worstPerformer {
                PerformerCard(title: "Worst Performer", investment: worst, isPositive: false)
            }
        }
    }
}

struct PerformerCard: View {
    let title: String
    let investment: Investment
    let isPositive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.sm) {
            Text(title)
                .font(Constants.Fonts.caption)
                .foregroundColor(Constants.Colors.gray)
            
            Text(investment.symbol)
                .font(Constants.Fonts.headline)
                .foregroundColor(Constants.Colors.white)
            
            Text("\(String(format: "%.2f", investment.gainLossPercentage))%")
                .font(Constants.Fonts.body)
                .foregroundColor(isPositive ? Constants.Colors.secondaryButton : Color.red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Constants.Colors.white.opacity(0.05))
        .cornerRadius(Constants.CornerRadius.medium)
    }
}

@available(iOS 16.0, *)
struct PerformanceChartView: View {
    @ObservedObject var viewModel: InvestmentViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.md) {
            Text("Performance Chart")
                .font(Constants.Fonts.headline)
                .foregroundColor(Constants.Colors.white)
            
            Chart {
                ForEach(viewModel.investments) { investment in
                    BarMark(
                        x: .value("Symbol", investment.symbol),
                        y: .value("Return %", investment.gainLossPercentage)
                    )
                    .foregroundStyle(investment.gainLoss >= 0 ? Constants.Colors.secondaryButton : Color.red)
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(Constants.Colors.white.opacity(0.05))
        .cornerRadius(Constants.CornerRadius.large)
    }
}

struct PortfolioPerformanceChart: View {
    @ObservedObject var viewModel: InvestmentViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.md) {
            Text("Portfolio Performance")
                .font(Constants.Fonts.headline)
                .foregroundColor(Constants.Colors.white)
            
            // Placeholder for performance chart - would show historical data in real app
            HStack {
                VStack(alignment: .leading) {
                    Text("1D")
                        .font(Constants.Fonts.small)
                        .foregroundColor(Constants.Colors.gray)
                    Text("+2.3%")
                        .font(Constants.Fonts.body)
                        .foregroundColor(Constants.Colors.secondaryButton)
                }
                
                Spacer()
                
                VStack(alignment: .center) {
                    Text("1W")
                        .font(Constants.Fonts.small)
                        .foregroundColor(Constants.Colors.gray)
                    Text("+5.7%")
                        .font(Constants.Fonts.body)
                        .foregroundColor(Constants.Colors.secondaryButton)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("1M")
                        .font(Constants.Fonts.small)
                        .foregroundColor(Constants.Colors.gray)
                    Text("-1.2%")
                        .font(Constants.Fonts.body)
                        .foregroundColor(Color.red)
                }
            }
        }
        .padding()
        .background(Constants.Colors.white.opacity(0.05))
        .cornerRadius(Constants.CornerRadius.large)
    }
}

// MARK: - Investment Tab Enum
enum InvestmentTab: String, CaseIterable {
    case portfolio = "Portfolio"
    case performance = "Performance"
    case holdings = "Holdings"
    
    var title: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .portfolio: return "chart.pie.fill"
        case .performance: return "chart.line.uptrend.xyaxis"
        case .holdings: return "list.bullet"
        }
    }
}

#Preview {
    InvestmentTrackingView()
}
