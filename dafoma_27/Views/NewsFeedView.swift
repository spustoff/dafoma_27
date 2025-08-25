import SwiftUI

struct NewsFeedView: View {
    @StateObject private var viewModel = NewsViewModel()
    @State private var showingPreferences = false
    @State private var selectedTab: NewsTab = .feed
    
    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab Selector
                    NewsTabSelector(selectedTab: $selectedTab)
                    
                    // Content based on selected tab
                    switch selectedTab {
                    case .feed:
                        NewsFeedContentView(viewModel: viewModel)
                    case .trending:
                        TrendingNewsView(viewModel: viewModel)
                    case .bookmarks:
                        BookmarkedNewsView(viewModel: viewModel)
                    }
                }
            }
            .navigationTitle("Financial News")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingPreferences = true }) {
                        Image(systemName: "gearshape.circle")
                            .foregroundColor(Constants.Colors.primaryButton)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.refreshNews() }) {
                        Image(systemName: "arrow.clockwise.circle")
                            .foregroundColor(Constants.Colors.primaryButton)
                    }
                }
            }
            .sheet(isPresented: $showingPreferences) {
                NewsPreferencesView(viewModel: viewModel)
            }
            .refreshable {
                viewModel.refreshNews()
            }
        }
    }
}

// MARK: - Tab Selector
struct NewsTabSelector: View {
    @Binding var selectedTab: NewsTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(NewsTab.allCases, id: \.self) { tab in
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

// MARK: - News Feed Content View
struct NewsFeedContentView: View {
    @ObservedObject var viewModel: NewsViewModel
    
    var body: some View {
        VStack(spacing: Constants.Spacing.md) {
            // Search Bar
            HStack {
                TextField("Search news...", text: $viewModel.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Menu {
                    ForEach(NewsSortOption.allCases, id: \.self) { option in
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
            
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Constants.Spacing.sm) {
                    CategoryFilterChip(
                        title: "All",
                        isSelected: viewModel.selectedCategory == nil
                    ) {
                        viewModel.selectedCategory = nil
                    }
                    
                    ForEach(NewsCategory.allCases, id: \.self) { category in
                        CategoryFilterChip(
                            title: category.rawValue,
                            isSelected: viewModel.selectedCategory == category
                        ) {
                            viewModel.selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal, Constants.Spacing.md)
            }
            
            // News List
            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.filteredArticles().isEmpty {
                EmptyStateView(
                    icon: "newspaper.circle",
                    title: "No News Available",
                    message: "Check your internet connection or adjust your news preferences."
                )
            } else {
                List {
                    ForEach(viewModel.filteredArticles()) { article in
                        NewsArticleRowView(article: article, viewModel: viewModel)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(PlainListStyle())

            }
        }
    }
}

// MARK: - Trending News View
struct TrendingNewsView: View {
    @ObservedObject var viewModel: NewsViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.Spacing.lg) {
                // Trending Topics
                TrendingTopicsView(viewModel: viewModel)
                
                // Trending Articles
                TrendingArticlesView(viewModel: viewModel)
            }
            .padding(.horizontal, Constants.Spacing.md)
        }
    }
}

// MARK: - Bookmarked News View
struct BookmarkedNewsView: View {
    @ObservedObject var viewModel: NewsViewModel
    
    var body: some View {
        VStack {
            if viewModel.bookmarkedArticles.isEmpty {
                EmptyStateView(
                    icon: "bookmark.circle",
                    title: "No Bookmarks Yet",
                    message: "Bookmark articles you want to read later by tapping the bookmark icon."
                )
            } else {
                List {
                    ForEach(viewModel.bookmarkedArticles) { article in
                        NewsArticleRowView(article: article, viewModel: viewModel)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(PlainListStyle())

            }
        }
        .padding(.horizontal, Constants.Spacing.md)
    }
}

// MARK: - News Article Row View
struct NewsArticleRowView: View {
    let article: NewsArticle
    @ObservedObject var viewModel: NewsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.md) {
            // Article Header
            HStack {
                VStack(alignment: .leading, spacing: Constants.Spacing.xs) {
                    // Category and Source
                    HStack {
                        Image(systemName: article.category.icon)
                            .font(.caption)
                            .foregroundColor(Constants.Colors.primaryButton)
                        
                        Text(article.category.rawValue)
                            .font(Constants.Fonts.small)
                            .foregroundColor(Constants.Colors.primaryButton)
                        
                        Text("•")
                            .font(Constants.Fonts.small)
                            .foregroundColor(Constants.Colors.gray)
                        
                        Text(article.source)
                            .font(Constants.Fonts.small)
                            .foregroundColor(Constants.Colors.gray)
                        
                        Spacer()
                        
                        Text(article.publishedDate, style: .relative)
                            .font(Constants.Fonts.small)
                            .foregroundColor(Constants.Colors.gray)
                    }
                    
                    // Title
                    Text(article.title)
                        .font(Constants.Fonts.headline)
                        .foregroundColor(Constants.Colors.white)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Bookmark Button
                Button(action: {
                    viewModel.bookmarkArticle(article)
                }) {
                    Image(systemName: article.isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.title3)
                        .foregroundColor(article.isBookmarked ? Constants.Colors.primaryButton : Constants.Colors.gray)
                }
            }
            
            // Summary
            Text(article.summary)
                .font(Constants.Fonts.body)
                .foregroundColor(Constants.Colors.white.opacity(0.8))
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            // Tags
            if !article.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Constants.Spacing.xs) {
                        ForEach(article.tags.prefix(3), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(Constants.Fonts.small)
                                .foregroundColor(Constants.Colors.secondaryButton)
                                .padding(.horizontal, Constants.Spacing.sm)
                                .padding(.vertical, Constants.Spacing.xs)
                                .background(Constants.Colors.secondaryButton.opacity(0.2))
                                .cornerRadius(Constants.CornerRadius.small)
                        }
                    }
                }
            }
            
            // Action Buttons
            HStack {
                Button(action: {
                    viewModel.markAsRead(article)
                    // Open article URL in Safari
                    if let url = URL(string: article.articleURL) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "safari")
                        Text("Read More")
                    }
                    .font(Constants.Fonts.caption)
                    .foregroundColor(Constants.Colors.background)
                    .padding(.horizontal, Constants.Spacing.md)
                    .padding(.vertical, Constants.Spacing.sm)
                    .background(Constants.Colors.primaryButton)
                    .cornerRadius(Constants.CornerRadius.medium)
                }
                
                Spacer()
                
                if !article.isRead {
                    Circle()
                        .fill(Constants.Colors.secondaryButton)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding()
        .background(article.isRead ? Constants.Colors.white.opacity(0.02) : Constants.Colors.white.opacity(0.08))
        .cornerRadius(Constants.CornerRadius.large)
        .onTapGesture {
            if !article.isRead {
                viewModel.markAsRead(article)
            }
        }
    }
}

// MARK: - Trending Topics View
struct TrendingTopicsView: View {
    @ObservedObject var viewModel: NewsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.md) {
            Text("Trending Topics")
                .font(Constants.Fonts.headline)
                .foregroundColor(Constants.Colors.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: Constants.Spacing.md) {
                ForEach(viewModel.trendingTopics.prefix(6)) { topic in
                    TrendingTopicCard(topic: topic)
                }
            }
        }
        .padding()
        .background(Constants.Colors.white.opacity(0.05))
        .cornerRadius(Constants.CornerRadius.large)
    }
}

// MARK: - Trending Articles View
struct TrendingArticlesView: View {
    @ObservedObject var viewModel: NewsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.md) {
            Text("Trending Articles")
                .font(Constants.Fonts.headline)
                .foregroundColor(Constants.Colors.white)
            
            ForEach(viewModel.getTrendingArticles().prefix(5)) { article in
                CompactNewsRowView(article: article, viewModel: viewModel)
            }
        }
        .padding()
        .background(Constants.Colors.white.opacity(0.05))
        .cornerRadius(Constants.CornerRadius.large)
    }
}

// MARK: - News Preferences View
struct NewsPreferencesView: View {
    @ObservedObject var viewModel: NewsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var tempPreferences: NewsPreferences
    
    init(viewModel: NewsViewModel) {
        self.viewModel = viewModel
        self._tempPreferences = State(initialValue: viewModel.preferences)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.background
                    .ignoresSafeArea()
                
                Form {
                    Section("Preferred Categories") {
                        ForEach(NewsCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(Constants.Colors.primaryButton)
                                
                                Text(category.rawValue)
                                    .font(Constants.Fonts.body)
                                
                                Spacer()
                                
                                Toggle("", isOn: Binding(
                                    get: { tempPreferences.preferredCategories.contains(category) },
                                    set: { isOn in
                                        if isOn {
                                            tempPreferences.preferredCategories.insert(category)
                                        } else {
                                            tempPreferences.preferredCategories.remove(category)
                                        }
                                    }
                                ))
                                .tint(Constants.Colors.primaryButton)
                            }
                        }
                    }
                    
                    Section("Keywords") {
                        ForEach(tempPreferences.keywords, id: \.self) { keyword in
                            HStack {
                                Text(keyword)
                                Spacer()
                                Button("Remove") {
                                    tempPreferences.keywords.removeAll { $0 == keyword }
                                }
                                .foregroundColor(.red)
                            }
                        }
                        
                        Button("Add Keyword") {
                            // In a real app, this would show a text input dialog
                            tempPreferences.keywords.append("New Keyword")
                        }
                        .foregroundColor(Constants.Colors.primaryButton)
                    }
                    
                    Section("Settings") {
                        Toggle("Enable Notifications", isOn: $tempPreferences.notificationsEnabled)
                            .tint(Constants.Colors.primaryButton)
                        
                        Picker("Refresh Frequency", selection: $tempPreferences.refreshFrequency) {
                            ForEach(RefreshFrequency.allCases, id: \.self) { frequency in
                                Text(frequency.rawValue).tag(frequency)
                            }
                        }
                    }
                }

            }
            .navigationTitle("News Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Constants.Colors.gray)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.updatePreferences(tempPreferences)
                        dismiss()
                    }
                    .foregroundColor(Constants.Colors.primaryButton)
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct CategoryFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Constants.Fonts.caption)
                .foregroundColor(isSelected ? Constants.Colors.background : Constants.Colors.white)
                .padding(.horizontal, Constants.Spacing.md)
                .padding(.vertical, Constants.Spacing.sm)
                .background(isSelected ? Constants.Colors.primaryButton : Constants.Colors.white.opacity(0.1))
                .cornerRadius(Constants.CornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TrendingTopicCard: View {
    let topic: TrendingTopic
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.sm) {
            HStack {
                Image(systemName: topic.category.icon)
                    .font(.caption)
                    .foregroundColor(Constants.Colors.primaryButton)
                
                Spacer()
                
                Image(systemName: topic.trend.icon)
                    .font(.caption)
                    .foregroundColor(trendColor)
            }
            
            Text(topic.keyword)
                .font(Constants.Fonts.body)
                .foregroundColor(Constants.Colors.white)
                .lineLimit(2)
            
            Text("\(topic.count) mentions")
                .font(Constants.Fonts.small)
                .foregroundColor(Constants.Colors.gray)
        }
        .padding()
        .background(Constants.Colors.white.opacity(0.05))
        .cornerRadius(Constants.CornerRadius.medium)
    }
    
    private var trendColor: Color {
        switch topic.trend {
        case .up: return Constants.Colors.secondaryButton
        case .down: return Color.red
        case .stable: return Constants.Colors.gray
        }
    }
}

struct CompactNewsRowView: View {
    let article: NewsArticle
    @ObservedObject var viewModel: NewsViewModel
    
    var body: some View {
        HStack(spacing: Constants.Spacing.md) {
            VStack(alignment: .leading, spacing: Constants.Spacing.xs) {
                Text(article.title)
                    .font(Constants.Fonts.body)
                    .foregroundColor(Constants.Colors.white)
                    .lineLimit(2)
                
                HStack {
                    Text(article.source)
                        .font(Constants.Fonts.small)
                        .foregroundColor(Constants.Colors.gray)
                    
                    Text("•")
                        .font(Constants.Fonts.small)
                        .foregroundColor(Constants.Colors.gray)
                    
                    Text(article.publishedDate, style: .relative)
                        .font(Constants.Fonts.small)
                        .foregroundColor(Constants.Colors.gray)
                }
            }
            
            Spacer()
            
            Button(action: {
                viewModel.bookmarkArticle(article)
            }) {
                Image(systemName: article.isBookmarked ? "bookmark.fill" : "bookmark")
                    .foregroundColor(article.isBookmarked ? Constants.Colors.primaryButton : Constants.Colors.gray)
            }
        }
        .padding(.vertical, Constants.Spacing.sm)
        .onTapGesture {
            viewModel.markAsRead(article)
            if let url = URL(string: article.articleURL) {
                UIApplication.shared.open(url)
            }
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: Constants.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Constants.Colors.primaryButton)
            
            Text("Loading news...")
                .font(Constants.Fonts.body)
                .foregroundColor(Constants.Colors.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - News Tab Enum
enum NewsTab: String, CaseIterable {
    case feed = "Feed"
    case trending = "Trending"
    case bookmarks = "Bookmarks"
    
    var title: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .feed: return "newspaper.fill"
        case .trending: return "flame.fill"
        case .bookmarks: return "bookmark.fill"
        }
    }
}

#Preview {
    NewsFeedView()
}
