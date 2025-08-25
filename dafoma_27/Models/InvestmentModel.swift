import Foundation

struct Investment: Identifiable, Codable {
    let id = UUID()
    var symbol: String
    var name: String
    var shares: Double
    var purchasePrice: Double
    var currentPrice: Double
    var purchaseDate: Date
    var type: InvestmentType
    var notes: String?
    
    enum CodingKeys: String, CodingKey {
        case symbol, name, shares, purchasePrice, currentPrice, purchaseDate, type, notes
    }
    
    var totalValue: Double {
        return shares * currentPrice
    }
    
    var totalCost: Double {
        return shares * purchasePrice
    }
    
    var gainLoss: Double {
        return totalValue - totalCost
    }
    
    var gainLossPercentage: Double {
        guard totalCost > 0 else { return 0 }
        return (gainLoss / totalCost) * 100
    }
    
    init(symbol: String, name: String, shares: Double, purchasePrice: Double, currentPrice: Double, purchaseDate: Date = Date(), type: InvestmentType, notes: String? = nil) {
        self.symbol = symbol
        self.name = name
        self.shares = shares
        self.purchasePrice = purchasePrice
        self.currentPrice = currentPrice
        self.purchaseDate = purchaseDate
        self.type = type
        self.notes = notes
    }
}

enum InvestmentType: String, CaseIterable, Codable {
    case stock = "Stock"
    case etf = "ETF"
    case bond = "Bond"
    case crypto = "Cryptocurrency"
    case mutualFund = "Mutual Fund"
    case reit = "REIT"
    case commodity = "Commodity"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .stock: return "chart.line.uptrend.xyaxis"
        case .etf: return "chart.pie.fill"
        case .bond: return "doc.fill"
        case .crypto: return "bitcoinsign.circle.fill"
        case .mutualFund: return "building.columns.fill"
        case .reit: return "house.fill"
        case .commodity: return "leaf.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

struct Portfolio {
    var investments: [Investment]
    var totalValue: Double {
        return investments.reduce(0) { $0 + $1.totalValue }
    }
    var totalCost: Double {
        return investments.reduce(0) { $0 + $1.totalCost }
    }
    var totalGainLoss: Double {
        return totalValue - totalCost
    }
    var totalGainLossPercentage: Double {
        guard totalCost > 0 else { return 0 }
        return (totalGainLoss / totalCost) * 100
    }
}

struct InvestmentAnalytics {
    var portfolioValue: Double
    var totalGainLoss: Double
    var gainLossPercentage: Double
    var bestPerformer: Investment?
    var worstPerformer: Investment?
    var typeBreakdown: [InvestmentType: Double]
    var monthlyPerformance: [MonthlyPerformance]
}

struct MonthlyPerformance {
    let month: String
    let value: Double
    let gainLoss: Double
    let date: Date
}

struct MarketData {
    let symbol: String
    let currentPrice: Double
    let change: Double
    let changePercentage: Double
    let volume: Int64
    let marketCap: Double?
    let lastUpdated: Date
}
