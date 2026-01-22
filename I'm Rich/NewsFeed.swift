//
//  NewsFeed.swift
//  I'm Rich
//
//  Dynamic news ticker for immersion
//

import SwiftUI
import Combine

// MARK: - News Item
struct NewsItem: Identifiable {
    let id = UUID()
    let category: NewsCategory
    let headline: String
    let timestamp = Date()
    
    enum NewsCategory: String {
        case breaking = "BREAKING"
        case markets = "MARKETS"
        case personal = "YOU"
        case rumor = "RUMOR"
        case weather = "WEATHER"
        case tech = "TECH"
        case economy = "ECONOMY"
        
        var color: Color {
            switch self {
            case .breaking: return .red
            case .markets: return .green
            case .personal: return .yellow
            case .rumor: return .purple
            case .weather: return .cyan
            case .tech: return .blue
            case .economy: return .orange
            }
        }
    }
}

// MARK: - News Templates
struct NewsTemplates {
    
    // Market-related headlines
    static let marketHeadlines = [
        "Tech sector up {percent}% in early trading",
        "Real estate prices hit new highs in major cities",
        "Crypto markets show signs of recovery",
        "Index funds outperform active managers for 15th year",
        "Bond yields rise as Fed hints at rate changes",
        "Small-cap stocks rally on economic optimism",
        "Global markets react to trade news",
        "Dividend aristocrats continue outperformance",
        "Growth stocks lead market rally",
        "Value investing makes a comeback"
    ]
    
    // Weather/atmosphere headlines
    static let atmosphereHeadlines = [
        "Perfect weather for staying in and building wealth",
        "Markets open on a sunny Monday morning",
        "Storm clouds gathering... in the housing market?",
        "Clear skies ahead for savvy investors",
        "Economic forecast: sunny with chance of gains"
    ]
    
    // General economy headlines
    static let economyHeadlines = [
        "Consumer confidence reaches 5-year high",
        "Unemployment hits record low",
        "Inflation data comes in lower than expected",
        "New jobs report beats expectations",
        "GDP growth surprises economists",
        "Housing starts up for third month",
        "Retail sales surge in holiday quarter",
        "Manufacturing sector shows resilience"
    ]
    
    // Tech news headlines
    static let techHeadlines = [
        "New AI breakthrough disrupts tech sector",
        "Major tech company announces record earnings",
        "Startup unicorn valued at $10B",
        "Tech layoffs concern investors",
        "Cloud computing demand accelerates",
        "New smartphone sales break records",
        "E-commerce growth continues post-pandemic",
        "Cybersecurity spending reaches all-time high"
    ]
    
    // Rumor headlines
    static let rumorHeadlines = [
        "Industry sources say big merger coming",
        "Whispers of major acquisition in the works",
        "Insiders hint at earnings surprise",
        "Anonymous tip: tech giant eyeing new market",
        "Sources suggest rate cut on horizon"
    ]
    
    static func randomHeadline() -> (category: NewsItem.NewsCategory, text: String) {
        let categories: [(NewsItem.NewsCategory, [String])] = [
            (.markets, marketHeadlines),
            (.weather, atmosphereHeadlines),
            (.economy, economyHeadlines),
            (.tech, techHeadlines),
            (.rumor, rumorHeadlines)
        ]
        
        let (category, headlines) = categories.randomElement()!
        var headline = headlines.randomElement()!
        
        // Replace any placeholders
        headline = headline.replacingOccurrences(of: "{percent}", with: "\(Int.random(in: 1...15))")
        
        return (category, headline)
    }
}

// MARK: - News Feed Manager
class NewsFeedManager: ObservableObject {
    static let shared = NewsFeedManager()
    
    @Published var currentNews: [NewsItem] = []
    @Published var displayedHeadline: NewsItem?
    @Published var showBanner = false
    
    private var newsTimer: Timer?
    private var rotateTimer: Timer?
    private let maxNewsItems = 20
    
    private init() {
        generateInitialNews()
        startTimers()
    }
    
    private func generateInitialNews() {
        for _ in 0..<5 {
            let (category, text) = NewsTemplates.randomHeadline()
            currentNews.append(NewsItem(category: category, headline: text))
        }
        displayedHeadline = currentNews.first
    }
    
    private func startTimers() {
        // Generate new headlines periodically
        newsTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.addRandomHeadline()
        }
        
        // Rotate displayed headline
        rotateTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { [weak self] _ in
            self?.rotateHeadline()
        }
    }
    
    func addRandomHeadline() {
        let (category, text) = NewsTemplates.randomHeadline()
        addNews(category: category, headline: text)
    }
    
    func addNews(category: NewsItem.NewsCategory, headline: String) {
        let item = NewsItem(category: category, headline: headline)
        currentNews.insert(item, at: 0)
        
        // Trim old news
        if currentNews.count > maxNewsItems {
            currentNews = Array(currentNews.prefix(maxNewsItems))
        }
        
        // Show banner for breaking news
        if category == .breaking || category == .personal {
            displayedHeadline = item
            showBanner = true
        }
    }
    
    private func rotateHeadline() {
        guard !currentNews.isEmpty else { return }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            if let current = displayedHeadline,
               let currentIndex = currentNews.firstIndex(where: { $0.id == current.id }) {
                let nextIndex = (currentIndex + 1) % currentNews.count
                displayedHeadline = currentNews[nextIndex]
            } else {
                displayedHeadline = currentNews.first
            }
        }
    }
    
    // Personal achievement announcements
    func announcePromotion(role: String) {
        addNews(category: .personal, headline: "Promoted to \(role)! Career milestone achieved.")
    }
    
    func announceMilestone(amount: String) {
        addNews(category: .personal, headline: "Net worth hits \(amount)! Another milestone reached.")
    }
    
    func announceProductSuccess(productName: String) {
        addNews(category: .breaking, headline: "\(productName) launch exceeds expectations!")
    }
    
    func announceContact(contactName: String) {
        addNews(category: .rumor, headline: "\(contactName) spotted meeting with rising entrepreneur...")
    }
    
    func announceAchievement(achievementName: String) {
        addNews(category: .personal, headline: "Achievement unlocked: \"\(achievementName)\"")
    }
    
    func announceMarketEvent(eventTitle: String) {
        addNews(category: .breaking, headline: eventTitle)
    }
    
    func reset() {
        currentNews = []
        generateInitialNews()
    }
}

// MARK: - News Ticker View
struct NewsTickerView: View {
    @ObservedObject var newsManager = NewsFeedManager.shared
    
    var body: some View {
        if let headline = newsManager.displayedHeadline {
            HStack(spacing: 8) {
                Text(headline.category.rawValue)
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(headline.category.color)
                    .cornerRadius(4)
                
                Text(headline.headline)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [Color.black, Color.black.opacity(0.9)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                Rectangle()
                    .fill(headline.category.color)
                    .frame(width: 3),
                alignment: .leading
            )
        }
    }
}

// MARK: - News Feed Panel View
struct NewsFeedPanelView: View {
    @ObservedObject var newsManager = NewsFeedManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "newspaper.fill")
                        .foregroundColor(.gray)
                    Text("NEWS FEED")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.gray)
                        .tracking(2)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                
                Divider().background(Color.white.opacity(0.1))
                
                // News list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(newsManager.currentNews) { item in
                            newsRow(item)
                            Divider().background(Color.white.opacity(0.05))
                        }
                    }
                }
            }
        }
    }
    
    func newsRow(_ item: NewsItem) -> some View {
        HStack(spacing: 12) {
            Text(item.category.rawValue)
                .font(.system(size: 8, weight: .black))
                .foregroundColor(.black)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(item.category.color)
                .cornerRadius(3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.headline)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                
                Text(timeAgo(item.timestamp))
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
    
    func timeAgo(_ date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        
        if seconds < 60 {
            return "just now"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes)m ago"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return "\(hours)h ago"
        } else {
            let days = seconds / 86400
            return "\(days)d ago"
        }
    }
}

// MARK: - Breaking News Banner
struct BreakingNewsBanner: View {
    let newsItem: NewsItem
    let onDismiss: () -> Void
    
    @State private var offset: CGFloat = -100
    @State private var opacity: Double = 0
    
    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Text("📰")
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(newsItem.category.rawValue)
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(newsItem.category.color)
                    
                    Text(newsItem.headline)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(newsItem.category.color, lineWidth: 1)
                    )
            )
            .padding()
            .offset(y: offset)
            .opacity(opacity)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                offset = 0
                opacity = 1
            }
            
            // Auto-dismiss after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation {
                    opacity = 0
                    offset = -100
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onDismiss()
                }
            }
        }
    }
}
