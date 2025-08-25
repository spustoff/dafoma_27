import Foundation

struct Expense: Identifiable, Codable {
    let id = UUID()
    var title: String
    var amount: Double
    var category: ExpenseCategory
    var date: Date
    var description: String?
    var isRecurring: Bool
    var recurringFrequency: RecurringFrequency?
    
    enum CodingKeys: String, CodingKey {
        case title, amount, category, date, description, isRecurring, recurringFrequency
    }
    
    init(title: String, amount: Double, category: ExpenseCategory, date: Date = Date(), description: String? = nil, isRecurring: Bool = false, recurringFrequency: RecurringFrequency? = nil) {
        self.title = title
        self.amount = amount
        self.category = category
        self.date = date
        self.description = description
        self.isRecurring = isRecurring
        self.recurringFrequency = recurringFrequency
    }
}

enum ExpenseCategory: String, CaseIterable, Codable {
    case food = "Food & Dining"
    case transportation = "Transportation"
    case shopping = "Shopping"
    case entertainment = "Entertainment"
    case bills = "Bills & Utilities"
    case healthcare = "Healthcare"
    case education = "Education"
    case travel = "Travel"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transportation: return "car.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "tv.fill"
        case .bills: return "doc.text.fill"
        case .healthcare: return "cross.fill"
        case .education: return "book.fill"
        case .travel: return "airplane"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

enum RecurringFrequency: String, CaseIterable, Codable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
}

struct ExpenseAnalytics {
    var totalSpent: Double
    var categoryBreakdown: [ExpenseCategory: Double]
    var monthlyTrend: [MonthlyExpense]
    var averageDaily: Double
    var topCategories: [(category: ExpenseCategory, amount: Double)]
}

struct MonthlyExpense {
    let month: String
    let amount: Double
    let date: Date
}
