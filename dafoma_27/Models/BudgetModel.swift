import Foundation

struct Budget: Identifiable, Codable {
    let id = UUID()
    var name: String
    var category: ExpenseCategory
    var limit: Double
    var spent: Double
    var period: BudgetPeriod
    var startDate: Date
    var endDate: Date
    var isActive: Bool
    var notifications: Bool
    
    enum CodingKeys: String, CodingKey {
        case name, category, limit, spent, period, startDate, endDate, isActive, notifications
    }
    
    var remaining: Double {
        return max(0, limit - spent)
    }
    
    var percentageUsed: Double {
        guard limit > 0 else { return 0 }
        return min(100, (spent / limit) * 100)
    }
    
    var status: BudgetStatus {
        let percentage = percentageUsed
        if percentage >= 100 {
            return .exceeded
        } else if percentage >= 80 {
            return .warning
        } else if percentage >= 50 {
            return .onTrack
        } else {
            return .good
        }
    }
    
    init(name: String, category: ExpenseCategory, limit: Double, period: BudgetPeriod, startDate: Date = Date(), notifications: Bool = true) {
        self.name = name
        self.category = category
        self.limit = limit
        self.spent = 0
        self.period = period
        self.startDate = startDate
        self.endDate = period.calculateEndDate(from: startDate)
        self.isActive = true
        self.notifications = notifications
    }
}

enum BudgetPeriod: String, CaseIterable, Codable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"
    
    func calculateEndDate(from startDate: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: startDate) ?? startDate
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: startDate) ?? startDate
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: startDate) ?? startDate
        }
    }
}

enum BudgetStatus: String, CaseIterable {
    case good = "Good"
    case onTrack = "On Track"
    case warning = "Warning"
    case exceeded = "Exceeded"
    
    var color: String {
        switch self {
        case .good: return "3cc45b"
        case .onTrack: return "3cc45b"
        case .warning: return "fcc418"
        case .exceeded: return "ff6b6b"
        }
    }
}

struct BudgetAnalytics {
    var totalBudgets: Int
    var activeBudgets: Int
    var totalLimit: Double
    var totalSpent: Double
    var averageUsage: Double
    var budgetsExceeded: Int
    var budgetsOnTrack: Int
    var categoryPerformance: [ExpenseCategory: BudgetPerformance]
}

struct BudgetPerformance {
    let category: ExpenseCategory
    let budgeted: Double
    let spent: Double
    let remaining: Double
    let percentageUsed: Double
    let status: BudgetStatus
}

struct BudgetAlert: Identifiable, Codable {
    let id = UUID()
    let budgetId: UUID
    let type: AlertType
    let message: String
    let date: Date
    let isRead: Bool
    
    enum CodingKeys: String, CodingKey {
        case budgetId, type, message, date, isRead
    }
}

enum AlertType: String, CaseIterable, Codable {
    case approaching = "Approaching Limit"
    case exceeded = "Budget Exceeded"
    case renewed = "Budget Renewed"
    case achievement = "Budget Goal Achieved"
}
