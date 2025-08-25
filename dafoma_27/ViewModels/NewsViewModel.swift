import Foundation
import Combine

class NewsViewModel: ObservableObject {
    @Published var articles: [NewsArticle] = []
    @Published var trendingTopics: [TrendingTopic] = []
    @Published var preferences: NewsPreferences = NewsPreferences()
    @Published var selectedCategory: NewsCategory?
    @Published var searchText = ""
    @Published var sortOption: NewsSortOption = .publishedDate
    @Published var showOnlyUnread = false
    @Published var showOnlyBookmarked = false
    @Published var isLoading = false
    @Published var error: NewsError?
    @Published var selectedArticle: NewsArticle?
    
    private let newsService = NewsService.shared
    private let dataService = DataService.shared
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    
    init() {
        setupBindings()
        loadPreferences()
        startAutoRefresh()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    private func setupBindings() {
        newsService.$articles
            .receive(on: DispatchQueue.main)
            .sink { [weak self] articles in
                self?.articles = articles
            }
            .store(in: &cancellables)
        
        newsService.$trendingTopics
            .receive(on: DispatchQueue.main)
            .sink { [weak self] topics in
                self?.trendingTopics = topics
            }
            .store(in: &cancellables)
        
        newsService.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.isLoading = isLoading
            }
            .store(in: &cancellables)
        
        newsService.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.error = error
            }
            .store(in: &cancellables)
        
        dataService.$newsPreferences
            .receive(on: DispatchQueue.main)
            .sink { [weak self] preferences in
                self?.preferences = preferences
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func loadPreferences() {
        preferences = dataService.newsPreferences
    }
    
    func updatePreferences(_ newPreferences: NewsPreferences) {
        dataService.updateNewsPreferences(newPreferences)
        refreshNews()
    }
    
    func refreshNews() {
        newsService.fetchNews(for: preferences)
    }
    
    func bookmarkArticle(_ article: NewsArticle) {
        newsService.bookmarkArticle(article)
    }
    
    func markAsRead(_ article: NewsArticle) {
        newsService.markAsRead(article)
    }
    
    func searchArticles(query: String) -> [NewsArticle] {
        return newsService.searchArticles(query: query)
    }
    
    func filteredArticles() -> [NewsArticle] {
        var filtered = articles
        
        // Filter by category
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Filter by read status
        if showOnlyUnread {
            filtered = filtered.filter { !$0.isRead }
        }
        
        // Filter by bookmark status
        if showOnlyBookmarked {
            filtered = filtered.filter { $0.isBookmarked }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { article in
                article.title.localizedCaseInsensitiveContains(searchText) ||
                article.summary.localizedCaseInsensitiveContains(searchText) ||
                article.source.localizedCaseInsensitiveContains(searchText) ||
                article.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Sort articles
        return sortArticles(filtered)
    }
    
    func articlesForCategory(_ category: NewsCategory) -> [NewsArticle] {
        return articles.filter { $0.category == category }
    }
    
    func getRelatedArticles(for article: NewsArticle) -> [NewsArticle] {
        return articles.filter { otherArticle in
            otherArticle.id != article.id &&
            (otherArticle.category == article.category ||
             !Set(otherArticle.tags).isDisjoint(with: Set(article.tags)))
        }.prefix(5).map { $0 }
    }
    
    func getTrendingArticles() -> [NewsArticle] {
        let trendingKeywords = trendingTopics.map { $0.keyword.lowercased() }
        return articles.filter { article in
            trendingKeywords.contains { keyword in
                article.title.lowercased().contains(keyword) ||
                article.summary.lowercased().contains(keyword) ||
                article.tags.contains { $0.lowercased().contains(keyword) }
            }
        }.prefix(10).map { $0 }
    }
    
    func addToPreferredCategories(_ category: NewsCategory) {
        var newPreferences = preferences
        newPreferences.preferredCategories.insert(category)
        updatePreferences(newPreferences)
    }
    
    func removeFromPreferredCategories(_ category: NewsCategory) {
        var newPreferences = preferences
        newPreferences.preferredCategories.remove(category)
        updatePreferences(newPreferences)
    }
    
    func addKeyword(_ keyword: String) {
        var newPreferences = preferences
        if !newPreferences.keywords.contains(keyword) {
            newPreferences.keywords.append(keyword)
            updatePreferences(newPreferences)
        }
    }
    
    func removeKeyword(_ keyword: String) {
        var newPreferences = preferences
        newPreferences.keywords.removeAll { $0 == keyword }
        updatePreferences(newPreferences)
    }
    
    // MARK: - Private Methods
    private func sortArticles(_ articles: [NewsArticle]) -> [NewsArticle] {
        switch sortOption {
        case .publishedDate:
            return articles.sorted { $0.publishedDate > $1.publishedDate }
        case .title:
            return articles.sorted { $0.title < $1.title }
        case .source:
            return articles.sorted { $0.source < $1.source }
        case .category:
            return articles.sorted { $0.category.rawValue < $1.category.rawValue }
        case .relevance:
            return articles.sorted { article1, article2 in
                let score1 = calculateRelevanceScore(article1)
                let score2 = calculateRelevanceScore(article2)
                return score1 > score2
            }
        }
    }
    
    private func calculateRelevanceScore(_ article: NewsArticle) -> Int {
        var score = 0
        
        // Preferred category bonus
        if preferences.preferredCategories.contains(article.category) {
            score += 10
        }
        
        // Keyword match bonus
        for keyword in preferences.keywords {
            if article.title.localizedCaseInsensitiveContains(keyword) {
                score += 5
            }
            if article.summary.localizedCaseInsensitiveContains(keyword) {
                score += 3
            }
            if article.tags.contains(where: { $0.localizedCaseInsensitiveContains(keyword) }) {
                score += 2
            }
        }
        
        // Recency bonus
        let hoursAgo = Date().timeIntervalSince(article.publishedDate) / 3600
        if hoursAgo < 24 {
            score += Int(24 - hoursAgo)
        }
        
        return score
    }
    
    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: preferences.refreshFrequency.interval, repeats: true) { [weak self] _ in
            self?.refreshNews()
        }
    }
    
    // MARK: - Computed Properties
    var totalArticles: Int {
        return articles.count
    }
    
    var unreadArticles: [NewsArticle] {
        return articles.filter { !$0.isRead }
    }
    
    var bookmarkedArticles: [NewsArticle] {
        return articles.filter { $0.isBookmarked }
    }
    
    var articlesByCategory: [NewsCategory: [NewsArticle]] {
        return Dictionary(grouping: articles) { $0.category }
    }
    
    var articlesBySource: [String: [NewsArticle]] {
        return Dictionary(grouping: articles) { $0.source }
    }
    
    var recentArticles: [NewsArticle] {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return articles.filter { $0.publishedDate >= yesterday }
            .sorted { $0.publishedDate > $1.publishedDate }
    }
    
    var topSources: [(source: String, count: Int)] {
        let sourceCounts = articlesBySource.mapValues { $0.count }
        return sourceCounts.sorted { $0.value > $1.value }
            .map { (source: $0.key, count: $0.value) }
            .prefix(5).map { $0 }
    }
    
    var categoryDistribution: [NewsCategory: Int] {
        return articlesByCategory.mapValues { $0.count }
    }
    
    var readingProgress: Double {
        guard !articles.isEmpty else { return 0 }
        let readCount = articles.filter { $0.isRead }.count
        return Double(readCount) / Double(articles.count)
    }
    
    var personalizedFeed: [NewsArticle] {
        return articles.sorted { article1, article2 in
            let score1 = calculateRelevanceScore(article1)
            let score2 = calculateRelevanceScore(article2)
            return score1 > score2
        }.prefix(20).map { $0 }
    }
}

// MARK: - Sort Options
enum NewsSortOption: String, CaseIterable {
    case publishedDate = "Latest"
    case relevance = "Relevance"
    case title = "Title"
    case source = "Source"
    case category = "Category"
}
