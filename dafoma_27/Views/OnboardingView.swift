import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var selectedCategories: Set<NewsCategory> = []
    @State private var monthlyBudget: String = ""
    @State private var investmentExperience: InvestmentExperience = .beginner
    @State private var notificationsEnabled = true
    
    @ObservedObject private var dataService = DataService.shared
    @Environment(\.dismiss) private var dismiss
    
    private let totalPages = 4
    
    var body: some View {
        ZStack {
            Constants.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress Bar
                HStack {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Rectangle()
                            .fill(index <= currentPage ? Constants.Colors.primaryButton : Constants.Colors.gray.opacity(0.3))
                            .frame(height: 4)
                            .animation(Constants.Animation.standard, value: currentPage)
                    }
                }
                .padding(.horizontal, Constants.Spacing.lg)
                .padding(.top, Constants.Spacing.md)
                
                // Content
                TabView(selection: $currentPage) {
                    WelcomePage()
                        .tag(0)
                    
                    NewsPreferencePage(selectedCategories: $selectedCategories)
                        .tag(1)
                    
                    BudgetSetupPage(monthlyBudget: $monthlyBudget)
                        .tag(2)
                    
                    InvestmentExperiencePage(
                        investmentExperience: $investmentExperience,
                        notificationsEnabled: $notificationsEnabled
                    )
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Navigation Buttons
                HStack {
                    if currentPage > 0 {
                        Button("Back") {
                            withAnimation(Constants.Animation.standard) {
                                currentPage -= 1
                            }
                        }
                        .foregroundColor(Constants.Colors.white)
                        .padding(.horizontal, Constants.Spacing.lg)
                        .padding(.vertical, Constants.Spacing.md)
                        .background(Constants.Colors.gray.opacity(0.3))
                        .cornerRadius(Constants.CornerRadius.medium)
                    }
                    
                    Spacer()
                    
                    Button(currentPage == totalPages - 1 ? "Get Started" : "Next") {
                        if currentPage == totalPages - 1 {
                            completeOnboarding()
                        } else {
                            withAnimation(Constants.Animation.standard) {
                                currentPage += 1
                            }
                        }
                    }
                    .foregroundColor(Constants.Colors.background)
                    .font(Constants.Fonts.headline)
                    .padding(.horizontal, Constants.Spacing.lg)
                    .padding(.vertical, Constants.Spacing.md)
                    .background(Constants.Colors.primaryButton)
                    .cornerRadius(Constants.CornerRadius.medium)
                }
                .padding(.horizontal, Constants.Spacing.lg)
                .padding(.bottom, Constants.Spacing.xl)
            }
        }
    }
    
    private func completeOnboarding() {
        // Save preferences
        var preferences = NewsPreferences()
        preferences.preferredCategories = selectedCategories
        preferences.notificationsEnabled = notificationsEnabled
        dataService.updateNewsPreferences(preferences)
        
        // Create initial budget if provided
        if let budget = Double(monthlyBudget), budget > 0 {
            dataService.addBudget(Budget(
                name: "Monthly Budget",
                category: .other,
                limit: budget,
                period: .monthly
            ))
        }
        
        // Mark onboarding as completed
        dataService.hasCompletedOnboarding = true
        
        dismiss()
    }
}

// MARK: - Welcome Page
struct WelcomePage: View {
    var body: some View {
        VStack(spacing: Constants.Spacing.xl) {
            Spacer()
            
            VStack(spacing: Constants.Spacing.lg) {
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Constants.Colors.primaryButton)
                
                Text("Welcome to FinNews Road")
                    .font(Constants.Fonts.title)
                    .foregroundColor(Constants.Colors.white)
                    .multilineTextAlignment(.center)
                
                Text("Your personal finance companion that combines expense tracking, investment monitoring, and curated financial news in one beautiful app.")
                    .font(Constants.Fonts.body)
                    .foregroundColor(Constants.Colors.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Constants.Spacing.lg)
            }
            
            Spacer()
            
            VStack(spacing: Constants.Spacing.md) {
                FeatureRow(icon: "dollarsign.circle.fill", title: "Track Expenses", description: "Monitor your spending with smart categorization")
                FeatureRow(icon: "chart.pie.fill", title: "Investment Insights", description: "Analyze your portfolio performance")
                FeatureRow(icon: "newspaper.fill", title: "Financial News", description: "Stay updated with personalized news feed")
            }
            .padding(.horizontal, Constants.Spacing.lg)
            
            Spacer()
        }
    }
}

// MARK: - News Preferences Page
struct NewsPreferencePage: View {
    @Binding var selectedCategories: Set<NewsCategory>
    
    var body: some View {
        VStack(spacing: Constants.Spacing.xl) {
            VStack(spacing: Constants.Spacing.md) {
                Image(systemName: "newspaper.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Constants.Colors.secondaryButton)
                
                Text("Choose Your Interests")
                    .font(Constants.Fonts.title)
                    .foregroundColor(Constants.Colors.white)
                
                Text("Select the financial topics you're most interested in to personalize your news feed.")
                    .font(Constants.Fonts.body)
                    .foregroundColor(Constants.Colors.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Constants.Spacing.lg)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: Constants.Spacing.md) {
                ForEach(NewsCategory.allCases, id: \.self) { category in
                    CategoryCard(
                        category: category,
                        isSelected: selectedCategories.contains(category)
                    ) {
                        if selectedCategories.contains(category) {
                            selectedCategories.remove(category)
                        } else {
                            selectedCategories.insert(category)
                        }
                    }
                }
            }
            .padding(.horizontal, Constants.Spacing.lg)
            
            Spacer()
        }
    }
}

// MARK: - Budget Setup Page
struct BudgetSetupPage: View {
    @Binding var monthlyBudget: String
    
    var body: some View {
        VStack(spacing: Constants.Spacing.xl) {
            VStack(spacing: Constants.Spacing.md) {
                Image(systemName: "target")
                    .font(.system(size: 60))
                    .foregroundColor(Constants.Colors.primaryButton)
                
                Text("Set Your Budget")
                    .font(Constants.Fonts.title)
                    .foregroundColor(Constants.Colors.white)
                
                Text("Enter your monthly budget to help track your spending and achieve your financial goals.")
                    .font(Constants.Fonts.body)
                    .foregroundColor(Constants.Colors.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Constants.Spacing.lg)
            }
            
            VStack(spacing: Constants.Spacing.lg) {
                VStack(alignment: .leading, spacing: Constants.Spacing.sm) {
                    Text("Monthly Budget")
                        .font(Constants.Fonts.headline)
                        .foregroundColor(Constants.Colors.white)
                    
                    HStack {
                        Text("$")
                            .font(Constants.Fonts.headline)
                            .foregroundColor(Constants.Colors.white)
                        
                        TextField("0", text: $monthlyBudget)
                            .keyboardType(.decimalPad)
                            .font(Constants.Fonts.headline)
                            .foregroundColor(Constants.Colors.white)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding()
                    .background(Constants.Colors.white.opacity(0.1))
                    .cornerRadius(Constants.CornerRadius.medium)
                }
                
                Text("Don't worry, you can always adjust this later or create multiple budgets for different categories.")
                    .font(Constants.Fonts.caption)
                    .foregroundColor(Constants.Colors.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Constants.Spacing.lg)
            
            Spacer()
        }
    }
}

// MARK: - Investment Experience Page
struct InvestmentExperiencePage: View {
    @Binding var investmentExperience: InvestmentExperience
    @Binding var notificationsEnabled: Bool
    
    var body: some View {
        VStack(spacing: Constants.Spacing.xl) {
            VStack(spacing: Constants.Spacing.md) {
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Constants.Colors.secondaryButton)
                
                Text("Almost Done!")
                    .font(Constants.Fonts.title)
                    .foregroundColor(Constants.Colors.white)
                
                Text("Tell us about your investment experience and notification preferences.")
                    .font(Constants.Fonts.body)
                    .foregroundColor(Constants.Colors.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Constants.Spacing.lg)
            }
            
            VStack(spacing: Constants.Spacing.lg) {
                VStack(alignment: .leading, spacing: Constants.Spacing.md) {
                    Text("Investment Experience")
                        .font(Constants.Fonts.headline)
                        .foregroundColor(Constants.Colors.white)
                    
                    ForEach(InvestmentExperience.allCases, id: \.self) { experience in
                        ExperienceRow(
                            experience: experience,
                            isSelected: investmentExperience == experience
                        ) {
                            investmentExperience = experience
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: Constants.Spacing.md) {
                    Text("Notifications")
                        .font(Constants.Fonts.headline)
                        .foregroundColor(Constants.Colors.white)
                    
                    HStack {
                        Toggle("Enable notifications for budget alerts and news updates", isOn: $notificationsEnabled)
                            .font(Constants.Fonts.body)
                            .foregroundColor(Constants.Colors.white)
                            .tint(Constants.Colors.primaryButton)
                    }
                }
            }
            .padding(.horizontal, Constants.Spacing.lg)
            
            Spacer()
        }
    }
}

// MARK: - Supporting Views
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: Constants.Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Constants.Colors.primaryButton)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: Constants.Spacing.xs) {
                Text(title)
                    .font(Constants.Fonts.headline)
                    .foregroundColor(Constants.Colors.white)
                
                Text(description)
                    .font(Constants.Fonts.caption)
                    .foregroundColor(Constants.Colors.white.opacity(0.7))
            }
            
            Spacer()
        }
    }
}

struct CategoryCard: View {
    let category: NewsCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Constants.Spacing.sm) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? Constants.Colors.background : Constants.Colors.primaryButton)
                
                Text(category.rawValue)
                    .font(Constants.Fonts.caption)
                    .foregroundColor(isSelected ? Constants.Colors.background : Constants.Colors.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Constants.Colors.primaryButton : Constants.Colors.white.opacity(0.1))
            .cornerRadius(Constants.CornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ExperienceRow: View {
    let experience: InvestmentExperience
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Constants.Colors.primaryButton : Constants.Colors.gray)
                
                VStack(alignment: .leading, spacing: Constants.Spacing.xs) {
                    Text(experience.title)
                        .font(Constants.Fonts.body)
                        .foregroundColor(Constants.Colors.white)
                    
                    Text(experience.description)
                        .font(Constants.Fonts.small)
                        .foregroundColor(Constants.Colors.white.opacity(0.7))
                }
                
                Spacer()
            }
            .padding()
            .background(isSelected ? Constants.Colors.white.opacity(0.1) : Color.clear)
            .cornerRadius(Constants.CornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Investment Experience Enum
enum InvestmentExperience: String, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    
    var title: String {
        return rawValue
    }
    
    var description: String {
        switch self {
        case .beginner:
            return "New to investing, looking to learn the basics"
        case .intermediate:
            return "Some experience with stocks and basic investments"
        case .advanced:
            return "Experienced investor with diverse portfolio"
        }
    }
}

#Preview {
    OnboardingView()
}

