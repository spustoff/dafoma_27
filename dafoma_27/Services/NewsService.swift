import Foundation
import Combine

class NewsService: ObservableObject {
    static let shared = NewsService()
    
    @Published var articles: [NewsArticle] = []
    @Published var trendingTopics: [TrendingTopic] = []
    @Published var isLoading = false
    @Published var error: NewsError?
    
    private var cancellables = Set<AnyCancellable>()
    private let session = URLSession.shared
    
    // Mock news sources for demo purposes
    private let mockSources = [
        NewsSource(name: "Financial Times", url: "https://ft.com", reliability: .high, categories: [.markets, .economy, .business]),
        NewsSource(name: "Bloomberg", url: "https://bloomberg.com", reliability: .high, categories: [.markets, .stocks, .investing]),
        NewsSource(name: "Reuters Finance", url: "https://reuters.com", reliability: .high, categories: [.markets, .economy, .business]),
        NewsSource(name: "MarketWatch", url: "https://marketwatch.com", reliability: .medium, categories: [.stocks, .investing, .markets]),
        NewsSource(name: "CNBC", url: "https://cnbc.com", reliability: .medium, categories: [.business, .markets, .economy])
    ]
    
    private init() {
        generateMockArticles()
        generateMockTrendingTopics()
    }
    
    // MARK: - Public Methods
    func fetchNews(for preferences: NewsPreferences) {
        isLoading = true
        error = nil
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.generateMockArticles(for: preferences)
            self?.isLoading = false
        }
    }
    
    func refreshNews() {
        let preferences = DataService.shared.newsPreferences
        fetchNews(for: preferences)
    }
    
    func bookmarkArticle(_ article: NewsArticle) {
        if let index = articles.firstIndex(where: { $0.id == article.id }) {
            articles[index].isBookmarked.toggle()
        }
    }
    
    func markAsRead(_ article: NewsArticle) {
        if let index = articles.firstIndex(where: { $0.id == article.id }) {
            articles[index].isRead = true
        }
    }
    
    func searchArticles(query: String) -> [NewsArticle] {
        let lowercasedQuery = query.lowercased()
        return articles.filter { article in
            article.title.lowercased().contains(lowercasedQuery) ||
            article.summary.lowercased().contains(lowercasedQuery) ||
            article.tags.contains { $0.lowercased().contains(lowercasedQuery) }
        }
    }
    
    func getArticles(for category: NewsCategory) -> [NewsArticle] {
        return articles.filter { $0.category == category }
    }
    
    func getBookmarkedArticles() -> [NewsArticle] {
        return articles.filter { $0.isBookmarked }
    }
    
    // MARK: - Mock Data Generation
    private func generateMockArticles(for preferences: NewsPreferences? = nil) {
        let categories = preferences?.preferredCategories ?? Set(NewsCategory.allCases.prefix(5))
        
        let mockTitles = [
            "Stock Market Reaches New Heights Amid Economic Recovery",
            "Federal Reserve Announces Interest Rate Decision",
            "Tech Giants Report Strong Q3 Earnings",
            "Cryptocurrency Market Shows Volatility After Regulatory News",
            "Banking Sector Faces New Challenges in Digital Transformation",
            "Investment Strategies for the Modern Portfolio",
            "Personal Finance Tips for Young Professionals",
            "Real Estate Market Trends in Major Cities",
            "Economic Indicators Point to Continued Growth",
            "Startup Funding Reaches Record Levels This Quarter"
        ]
        
        let mockSummaries = [
            "Markets continue to show resilience as investors remain optimistic about economic recovery prospects.",
            "The Federal Reserve's latest decision impacts borrowing costs and market sentiment across sectors.",
            "Technology companies exceed expectations with robust revenue growth and strong user engagement.",
            "Digital currencies face increased scrutiny as governments worldwide consider new regulations.",
            "Traditional banks accelerate digital initiatives to compete with fintech innovations.",
            "Financial advisors recommend diversified approaches for long-term wealth building.",
            "Expert advice on budgeting, saving, and investing for career starters and young families.",
            "Housing prices and rental markets show varied trends across different metropolitan areas.",
            "Key economic metrics suggest sustained growth momentum in the coming quarters.",
            "Venture capital activity reaches new peaks as innovation drives investment opportunities."
        ]
        
        var newArticles: [NewsArticle] = []
        
        for i in 0..<10 {
            let randomCategory = categories.randomElement() ?? .markets
            let publishedDate = Calendar.current.date(byAdding: .hour, value: -Int.random(in: 1...72), to: Date()) ?? Date()
            let source = mockSources.randomElement()?.name ?? "Financial News"
            
            let article = NewsArticle(
                title: mockTitles[i],
                summary: mockSummaries[i],
                content: generateMockContent(for: mockTitles[i]),
                author: generateRandomAuthor(),
                source: source,
                publishedDate: publishedDate,
                imageURL: nil,
                articleURL: "https://edition.cnn.com",
                category: randomCategory,
                tags: generateRandomTags(for: randomCategory),
                isBookmarked: Bool.random(),
                isRead: Bool.random()
            )
            
            newArticles.append(article)
        }
        
        // Sort by publication date (newest first)
        articles = newArticles.sorted { $0.publishedDate > $1.publishedDate }
    }
    
    private func generateMockContent(for title: String) -> String {
        return """
        \(title)
        
        In a significant development for financial markets, recent analysis shows continued momentum across key sectors. Industry experts are closely monitoring various indicators that suggest sustained growth patterns.
        
        Market participants have responded positively to recent economic data, with trading volumes reflecting increased investor confidence. The broader implications of these trends extend beyond immediate market movements.
        
        Financial analysts recommend maintaining a balanced approach to portfolio management while considering both opportunities and potential risks in the current environment.
        
        Key factors influencing market sentiment include regulatory developments, corporate earnings reports, and macroeconomic indicators that continue to shape investment strategies.
        
        Looking ahead, market observers anticipate continued volatility as various economic factors converge to influence trading patterns and investment decisions across different asset classes.
        """
    }
    
    private func generateRandomAuthor() -> String {
        let authors = [
            "Sarah Johnson", "Michael Chen", "Emily Rodriguez", "David Thompson",
            "Jessica Williams", "Robert Kim", "Amanda Davis", "Christopher Lee",
            "Maria Garcia", "James Wilson", "Lisa Anderson", "Kevin Brown"
        ]
        return authors.randomElement() ?? "Staff Writer"
    }
    
    private func generateRandomTags(for category: NewsCategory) -> [String] {
        let tagsByCategory: [NewsCategory: [String]] = [
            .markets: ["trading", "volatility", "indices", "market-analysis"],
            .stocks: ["equity", "earnings", "dividends", "stock-picks"],
            .crypto: ["bitcoin", "ethereum", "blockchain", "defi"],
            .economy: ["gdp", "inflation", "employment", "monetary-policy"],
            .banking: ["interest-rates", "lending", "fintech", "regulation"],
            .investing: ["portfolio", "strategy", "risk-management", "returns"],
            .personalFinance: ["budgeting", "savings", "retirement", "debt"],
            .business: ["corporate", "mergers", "leadership", "innovation"],
            .technology: ["ai", "software", "hardware", "startups"],
            .real_estate: ["housing", "commercial", "reit", "property-values"]
        ]
        
        let availableTags = tagsByCategory[category] ?? ["finance", "news"]
        return Array(availableTags.shuffled().prefix(Int.random(in: 2...4)))
    }
    
    private func generateMockTrendingTopics() {
        let topics = [
            TrendingTopic(keyword: "Interest Rates", count: 156, category: .economy, trend: .up),
            TrendingTopic(keyword: "Tech Earnings", count: 142, category: .stocks, trend: .up),
            TrendingTopic(keyword: "Bitcoin", count: 128, category: .crypto, trend: .down),
            TrendingTopic(keyword: "Housing Market", count: 98, category: .real_estate, trend: .stable),
            TrendingTopic(keyword: "Federal Reserve", count: 87, category: .economy, trend: .up),
            TrendingTopic(keyword: "ESG Investing", count: 76, category: .investing, trend: .up),
            TrendingTopic(keyword: "Inflation", count: 65, category: .economy, trend: .down),
            TrendingTopic(keyword: "Banking Crisis", count: 54, category: .banking, trend: .stable)
        ]
        
        trendingTopics = topics
    }
}

// MARK: - Error Handling
enum NewsError: Error, LocalizedError {
    case networkError
    case invalidURL
    case noData
    case decodingError
    case rateLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network connection error. Please check your internet connection."
        case .invalidURL:
            return "Invalid news source URL."
        case .noData:
            return "No news data available."
        case .decodingError:
            return "Error processing news data."
        case .rateLimitExceeded:
            return "Too many requests. Please try again later."
        }
    }
}
