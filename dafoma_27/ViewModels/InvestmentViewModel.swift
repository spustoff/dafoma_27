import Foundation
import Combine

class InvestmentViewModel: ObservableObject {
    @Published var investments: [Investment] = []
    @Published var portfolio: Portfolio = Portfolio(investments: [])
    @Published var analytics: InvestmentAnalytics?
    @Published var marketData: [String: MarketData] = [:]
    @Published var selectedInvestment: Investment?
    @Published var showingAddInvestment = false
    @Published var isLoadingMarketData = false
    @Published var searchText = ""
    @Published var sortOption: InvestmentSortOption = .gainLossPercentage
    @Published var selectedType: InvestmentType?
    
    private let dataService = DataService.shared
    private var cancellables = Set<AnyCancellable>()
    private var marketDataTimer: Timer?
    
    init() {
        setupBindings()
        loadInvestments()
        startMarketDataUpdates()
    }
    
    deinit {
        marketDataTimer?.invalidate()
    }
    
    private func setupBindings() {
        dataService.$investments
            .receive(on: DispatchQueue.main)
            .sink { [weak self] investments in
                self?.investments = investments
                self?.updatePortfolio()
                self?.updateAnalytics()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func loadInvestments() {
        updatePortfolio()
        updateAnalytics()
    }
    
    func addInvestment(symbol: String, name: String, shares: Double, purchasePrice: Double, currentPrice: Double, type: InvestmentType, notes: String? = nil) {
        let investment = Investment(
            symbol: symbol.uppercased(),
            name: name,
            shares: shares,
            purchasePrice: purchasePrice,
            currentPrice: currentPrice,
            type: type,
            notes: notes
        )
        dataService.addInvestment(investment)
    }
    
    func updateInvestment(_ investment: Investment) {
        dataService.updateInvestment(investment)
    }
    
    func deleteInvestment(_ investment: Investment) {
        dataService.deleteInvestment(investment)
    }
    
    func refreshMarketData() {
        isLoadingMarketData = true
        
        // Simulate market data fetch with realistic price movements
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.generateMockMarketData()
            self?.isLoadingMarketData = false
        }
    }
    
    func filteredInvestments() -> [Investment] {
        var filtered = investments
        
        // Filter by type
        if let type = selectedType {
            filtered = filtered.filter { $0.type == type }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { investment in
                investment.symbol.localizedCaseInsensitiveContains(searchText) ||
                investment.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort investments
        return sortInvestments(filtered)
    }
    
    func investmentsForType(_ type: InvestmentType) -> [Investment] {
        return investments.filter { $0.type == type }
    }
    
    func totalValueForType(_ type: InvestmentType) -> Double {
        return investmentsForType(type).reduce(0) { $0 + $1.totalValue }
    }
    
    // MARK: - Private Methods
    private func updatePortfolio() {
        portfolio = Portfolio(investments: investments)
    }
    
    private func updateAnalytics() {
        analytics = dataService.getInvestmentAnalytics()
    }
    
    private func sortInvestments(_ investments: [Investment]) -> [Investment] {
        switch sortOption {
        case .symbol:
            return investments.sorted { $0.symbol < $1.symbol }
        case .name:
            return investments.sorted { $0.name < $1.name }
        case .totalValue:
            return investments.sorted { $0.totalValue > $1.totalValue }
        case .gainLossAmount:
            return investments.sorted { $0.gainLoss > $1.gainLoss }
        case .gainLossPercentage:
            return investments.sorted { $0.gainLossPercentage > $1.gainLossPercentage }
        case .purchaseDate:
            return investments.sorted { $0.purchaseDate > $1.purchaseDate }
        case .type:
            return investments.sorted { $0.type.rawValue < $1.type.rawValue }
        }
    }
    
    private func startMarketDataUpdates() {
        // Update market data every 30 seconds for demo purposes
        marketDataTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.updateMarketPrices()
        }
    }
    
    private func updateMarketPrices() {
        generateMockMarketData()
    }
    
    private func generateMockMarketData() {
        var newMarketData: [String: MarketData] = [:]
        
        for investment in investments {
            // Generate realistic price movement (±5%)
            let changePercentage = Double.random(in: -5.0...5.0)
            let newPrice = investment.currentPrice * (1 + changePercentage / 100)
            let change = newPrice - investment.currentPrice
            
            let data = MarketData(
                symbol: investment.symbol,
                currentPrice: newPrice,
                change: change,
                changePercentage: changePercentage,
                volume: Int64.random(in: 100000...10000000),
                marketCap: Double.random(in: 1000000000...1000000000000),
                lastUpdated: Date()
            )
            
            newMarketData[investment.symbol] = data
        }
        
        marketData = newMarketData
        dataService.updateInvestmentPrices(newMarketData)
    }
    
    // MARK: - Computed Properties
    var totalPortfolioValue: Double {
        return portfolio.totalValue
    }
    
    var totalGainLoss: Double {
        return portfolio.totalGainLoss
    }
    
    var totalGainLossPercentage: Double {
        return portfolio.totalGainLossPercentage
    }
    
    var bestPerformer: Investment? {
        return investments.max { $0.gainLossPercentage < $1.gainLossPercentage }
    }
    
    var worstPerformer: Investment? {
        return investments.min { $0.gainLossPercentage < $1.gainLossPercentage }
    }
    
    var investmentsByType: [InvestmentType: [Investment]] {
        return Dictionary(grouping: investments) { $0.type }
    }
    
    var typeBreakdown: [InvestmentType: Double] {
        return investmentsByType.mapValues { investments in
            investments.reduce(0) { $0 + $1.totalValue }
        }
    }
    
    var diversificationScore: Double {
        let types = Set(investments.map { $0.type })
        let maxTypes = InvestmentType.allCases.count
        return Double(types.count) / Double(maxTypes) * 100
    }
    
    var topPerformers: [Investment] {
        return investments.sorted { $0.gainLossPercentage > $1.gainLossPercentage }.prefix(3).map { $0 }
    }
    
    var recentActivity: [Investment] {
        return investments.sorted { $0.purchaseDate > $1.purchaseDate }.prefix(5).map { $0 }
    }
}

// MARK: - Sort Options
enum InvestmentSortOption: String, CaseIterable {
    case gainLossPercentage = "Performance (%)"
    case gainLossAmount = "Gain/Loss ($)"
    case totalValue = "Total Value"
    case symbol = "Symbol"
    case name = "Name"
    case purchaseDate = "Purchase Date"
    case type = "Type"
}

