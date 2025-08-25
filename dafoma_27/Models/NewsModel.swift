import Foundation

struct NewsArticle: Identifiable, Codable {
    let id = UUID()
    var title: String
    var summary: String
    var content: String?
    var author: String?
    var source: String
    var publishedDate: Date
    var imageURL: String?
    var articleURL: String
    var category: NewsCategory
    var tags: [String]
    var isBookmarked: Bool
    var isRead: Bool
    
    enum CodingKeys: String, CodingKey {
        case title, summary, content, author, source, publishedDate, imageURL, articleURL, category, tags, isBookmarked, isRead
    }
    
    init(title: String, summary: String, content: String? = nil, author: String? = nil, source: String, publishedDate: Date, imageURL: String? = nil, articleURL: String, category: NewsCategory, tags: [String] = [], isBookmarked: Bool = false, isRead: Bool = false) {
        self.title = title
        self.summary = summary
        self.content = content
        self.author = author
        self.source = source
        self.publishedDate = publishedDate
        self.imageURL = imageURL
        self.articleURL = articleURL
        self.category = category
        self.tags = tags
        self.isBookmarked = isBookmarked
        self.isRead = isRead
    }
}

enum NewsCategory: String, CaseIterable, Codable {
    case markets = "Markets"
    case stocks = "Stocks"
    case crypto = "Cryptocurrency"
    case economy = "Economy"
    case banking = "Banking"
    case investing = "Investing"
    case personalFinance = "Personal Finance"
    case business = "Business"
    case technology = "Technology"
    case real_estate = "Real Estate"
    
    var icon: String {
        switch self {
        case .markets: return "chart.line.uptrend.xyaxis"
        case .stocks: return "chart.bar.fill"
        case .crypto: return "bitcoinsign.circle.fill"
        case .economy: return "globe"
        case .banking: return "building.columns.fill"
        case .investing: return "dollarsign.circle.fill"
        case .personalFinance: return "person.crop.circle.fill"
        case .business: return "briefcase.fill"
        case .technology: return "laptopcomputer"
        case .real_estate: return "house.fill"
        }
    }
}

struct NewsPreferences: Codable {
    var preferredCategories: Set<NewsCategory>
    var preferredSources: Set<String>
    var keywords: [String]
    var notificationsEnabled: Bool
    var refreshFrequency: RefreshFrequency
    
    init() {
        self.preferredCategories = [.markets, .stocks, .investing]
        self.preferredSources = []
        self.keywords = []
        self.notificationsEnabled = true
        self.refreshFrequency = .hourly
    }
}

enum RefreshFrequency: String, CaseIterable, Codable {
    case realTime = "Real-time"
    case fifteenMinutes = "15 minutes"
    case thirtyMinutes = "30 minutes"
    case hourly = "Hourly"
    case daily = "Daily"
    
    var interval: TimeInterval {
        switch self {
        case .realTime: return 60 // 1 minute for real-time simulation
        case .fifteenMinutes: return 15 * 60
        case .thirtyMinutes: return 30 * 60
        case .hourly: return 60 * 60
        case .daily: return 24 * 60 * 60
        }
    }
}

struct NewsSource: Identifiable, Codable {
    let id = UUID()
    var name: String
    var url: String
    var isEnabled: Bool
    
    var reliability: SourceReliability
    var categories: [NewsCategory]
    
    enum CodingKeys: String, CodingKey {
        case name, url, isEnabled, reliability, categories
    }
    
    init(name: String, url: String, isEnabled: Bool = true, reliability: SourceReliability = .high, categories: [NewsCategory] = []) {
        self.name = name
        self.url = url
        self.isEnabled = isEnabled
        self.reliability = reliability
        self.categories = categories
    }
}

enum SourceReliability: String, CaseIterable, Codable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    var color: String {
        switch self {
        case .high: return "3cc45b"
        case .medium: return "fcc418"
        case .low: return "ff6b6b"
        }
    }
}

struct TrendingTopic: Identifiable {
    let id = UUID()
    var keyword: String
    var count: Int
    var category: NewsCategory
    var trend: TrendDirection
}

enum TrendDirection: String, CaseIterable {
    case up = "Up"
    case down = "Down"
    case stable = "Stable"
    
    var icon: String {
        switch self {
        case .up: return "arrow.up.circle.fill"
        case .down: return "arrow.down.circle.fill"
        case .stable: return "minus.circle.fill"
        }
    }
}
