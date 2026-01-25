//
//  InvestmentSentiment.swift
//  I'm Rich
//
//  Dynamic investment sentiment system - shows news and whether investments are good or bad
//

import SwiftUI
import Combine

// MARK: - Investment Sentiment

enum SentimentLevel: String, Codable, CaseIterable {
    case veryBullish = "Very Bullish"
    case bullish = "Bullish"
    case neutral = "Neutral"
    case bearish = "Bearish"
    case veryBearish = "Very Bearish"
    case warning = "Warning"  // For risky/bad investments
    case avoid = "Avoid"      // For clearly bad investments
    
    var icon: String {
        switch self {
        case .veryBullish: return "🚀"
        case .bullish: return "📈"
        case .neutral: return "➡️"
        case .bearish: return "📉"
        case .veryBearish: return "💥"
        case .warning: return "⚠️"
        case .avoid: return "🚫"
        }
    }
    
    var color: Color {
        switch self {
        case .veryBullish: return .green
        case .bullish: return .green.opacity(0.7)
        case .neutral: return .gray
        case .bearish: return .orange
        case .veryBearish: return .red
        case .warning: return .yellow
        case .avoid: return .red
        }
    }
    
    var returnMultiplier: Double {
        switch self {
        case .veryBullish: return 1.5   // +50% returns
        case .bullish: return 1.2       // +20% returns
        case .neutral: return 1.0       // Normal returns
        case .bearish: return 0.5       // -50% returns
        case .veryBearish: return -0.5  // Losing money!
        case .warning: return 0.3       // Risky
        case .avoid: return -1.0        // Definitely losing
        }
    }
    
    var recommendation: String {
        switch self {
        case .veryBullish: return "Strong Buy"
        case .bullish: return "Buy"
        case .neutral: return "Hold"
        case .bearish: return "Sell"
        case .veryBearish: return "Strong Sell"
        case .warning: return "Caution"
        case .avoid: return "Stay Away"
        }
    }
}

struct InvestmentSentiment: Identifiable, Codable {
    let id: String  // Investment ID
    var level: SentimentLevel
    var headline: String
    var details: String
    var lastUpdated: Date
    var trend: SentimentTrend
    
    enum SentimentTrend: String, Codable {
        case improving = "Improving"
        case stable = "Stable"
        case declining = "Declining"
        
        var icon: String {
            switch self {
            case .improving: return "↗️"
            case .stable: return "→"
            case .declining: return "↘️"
            }
        }
    }
}

// MARK: - Investment News Templates

struct InvestmentNewsTemplate {
    let investmentId: String
    let bullishNews: [String]
    let bearishNews: [String]
    let bullishDetails: [String]
    let bearishDetails: [String]
}

// News templates for each investment
let investmentNewsTemplates: [String: InvestmentNewsTemplate] = [
    // Tech Giants
    "aapl": InvestmentNewsTemplate(
        investmentId: "aapl",
        bullishNews: [
            "Apple announces record iPhone sales",
            "Apple Vision Pro sales exceed expectations",
            "Services revenue hits all-time high",
            "Apple AI features drive upgrade cycle",
            "Warren Buffett increases Apple stake"
        ],
        bearishNews: [
            "iPhone sales decline in China",
            "Apple faces antitrust lawsuit",
            "Supply chain issues hurt production",
            "Competition heats up in smartphone market",
            "Services growth slowing concerns analysts"
        ],
        bullishDetails: [
            "Strong demand for premium devices continues. Analysts raising price targets.",
            "The tech giant's ecosystem lock-in creates recurring revenue. Long-term bullish.",
            "New product categories show promise. Innovation pipeline looks healthy."
        ],
        bearishDetails: [
            "Market saturation concerns mount. Growth may be limited.",
            "Regulatory pressure increasing globally. Legal costs rising.",
            "Valuation stretched compared to peers. May underperform."
        ]
    ),
    
    "msft": InvestmentNewsTemplate(
        investmentId: "msft",
        bullishNews: [
            "Azure cloud revenue surges 40%",
            "Microsoft Copilot adoption accelerating",
            "Enterprise AI deals worth billions",
            "Gaming division shows strong growth",
            "Microsoft 365 price increases accepted"
        ],
        bearishNews: [
            "Cloud growth slowing vs competitors",
            "OpenAI partnership costs scrutinized",
            "Antitrust regulators eye Activision deal",
            "Enterprise spending cuts impact sales",
            "LinkedIn growth disappoints"
        ],
        bullishDetails: [
            "AI integration across products driving upsell. Enterprise moat widening.",
            "Cloud infrastructure investments paying off. Market share gains continue.",
            "Diversified revenue streams reduce risk. Dividend growth attractive."
        ],
        bearishDetails: [
            "Heavy AI investments may not pay off short-term. Margins under pressure.",
            "Competition from Amazon and Google intensifying in cloud.",
            "Stock trades at premium valuation. Limited upside near-term."
        ]
    ),
    
    "googl": InvestmentNewsTemplate(
        investmentId: "googl",
        bullishNews: [
            "Google Search AI upgrades drive engagement",
            "YouTube Premium subscribers soar",
            "Cloud business turns profitable",
            "Waymo robotaxi expansion accelerates",
            "Ad revenue rebounds strongly"
        ],
        bearishNews: [
            "DOJ antitrust case threatens breakup",
            "AI search competition from ChatGPT",
            "Ad revenue market share declining",
            "Cloud losses continue to mount",
            "Privacy regulations hurt targeting"
        ],
        bullishDetails: [
            "AI capabilities keep Google competitive in search. Moat remains strong.",
            "YouTube monetization improving. Creator economy benefits platform.",
            "Massive cash position enables innovation and buybacks."
        ],
        bearishDetails: [
            "Antitrust risks are real and growing. Regulatory overhang persists.",
            "AI disruption could fundamentally change search economics.",
            "Other Bets continue to burn cash with unclear path to profitability."
        ]
    ),
    
    "nvda": InvestmentNewsTemplate(
        investmentId: "nvda",
        bullishNews: [
            "AI chip demand exceeds all forecasts",
            "Data center revenue up 200%+",
            "New GPU architecture dominates",
            "Every major tech company buying NVIDIA",
            "Blackwell chips sold out for 2 years"
        ],
        bearishNews: [
            "China export restrictions hurt sales",
            "AMD and Intel catching up in AI chips",
            "Valuation concerns as stock soars",
            "Customer concentration risk highlighted",
            "Crypto mining demand collapse"
        ],
        bullishDetails: [
            "AI infrastructure buildout just beginning. Years of growth ahead.",
            "Competitive moat through CUDA ecosystem very strong.",
            "Pricing power unprecedented in semiconductor industry."
        ],
        bearishDetails: [
            "Stock has run up massively. May need to grow into valuation.",
            "Competitors developing alternatives. Moat may narrow over time.",
            "Cyclical risk as AI investment may slow after initial buildout."
        ]
    ),
    
    "tsla": InvestmentNewsTemplate(
        investmentId: "tsla",
        bullishNews: [
            "Cybertruck production ramping successfully",
            "FSD achieving human-level safety",
            "Energy storage business exploding",
            "Robotaxi service launching soon",
            "Optimus robot enters production"
        ],
        bearishNews: [
            "EV competition intensifying globally",
            "Price cuts hurt profit margins",
            "Elon Musk distracted by other ventures",
            "Quality issues persist in new models",
            "Market share losses in key regions"
        ],
        bullishDetails: [
            "Energy and AI optionality not priced in. Multiple expansion possible.",
            "Manufacturing innovation creates cost advantages over competitors.",
            "Brand loyalty and charging network are underappreciated moats."
        ],
        bearishDetails: [
            "Automotive margins compressing rapidly. Competition fierce.",
            "CEO distraction creates execution risk. Governance concerns.",
            "Valuation assumes perfection. Any miss could crater stock."
        ]
    ),
    
    // Crypto
    "btc": InvestmentNewsTemplate(
        investmentId: "btc",
        bullishNews: [
            "Bitcoin ETF sees record inflows",
            "Institutional adoption accelerating",
            "Halving cycle historically bullish",
            "El Salvador strategy vindicated",
            "MicroStrategy continues accumulation"
        ],
        bearishNews: [
            "Regulatory crackdown intensifies",
            "Environmental concerns resurface",
            "Mt. Gox distribution creates selling pressure",
            "Whale wallets show distribution",
            "Mining difficulty at all-time high"
        ],
        bullishDetails: [
            "Digital gold thesis gaining mainstream acceptance.",
            "Fixed supply + increasing demand = bullish long-term.",
            "Network security and decentralization continue to strengthen."
        ],
        bearishDetails: [
            "Regulatory risk remains high. Government bans possible.",
            "No intrinsic value makes bottom difficult to predict.",
            "Energy consumption criticism may limit institutional adoption."
        ]
    ),
    
    "eth": InvestmentNewsTemplate(
        investmentId: "eth",
        bullishNews: [
            "Ethereum staking yields attractive",
            "Layer 2 scaling solutions thriving",
            "DeFi total value locked surging",
            "NFT market showing recovery",
            "Enterprise blockchain adoption growing"
        ],
        bearishNews: [
            "SEC may classify ETH as security",
            "Solana competition intensifying",
            "Gas fees spike during congestion",
            "Vitalik selling concerns market",
            "Smart contract hacks continue"
        ],
        bullishDetails: [
            "Network effects make Ethereum the default smart contract platform.",
            "Staking creates sustainable yield and reduces selling pressure.",
            "Developer ecosystem unmatched in crypto space."
        ],
        bearishDetails: [
            "Security classification would be catastrophic for price.",
            "Scaling remains a challenge despite Layer 2 solutions.",
            "Competition from faster, cheaper chains is real."
        ]
    ),
    
    "sol": InvestmentNewsTemplate(
        investmentId: "sol",
        bullishNews: [
            "Solana transaction volume hits record",
            "Meme coin activity drives adoption",
            "Network uptime improving significantly",
            "Developer activity surging",
            "Institutional interest growing"
        ],
        bearishNews: [
            "Another network outage frustrates users",
            "FTX estate selling large position",
            "Centralization concerns persist",
            "Token unlock schedule creates pressure",
            "Competition from new L1s emerging"
        ],
        bullishDetails: [
            "Fast, cheap transactions attract real usage beyond speculation.",
            "Firedancer upgrade will improve reliability significantly.",
            "Mobile-first strategy with Saga phone is innovative."
        ],
        bearishDetails: [
            "Network outages undermine reliability claims.",
            "Still recovering from FTX association damage.",
            "Venture capital unlock schedule creates selling pressure."
        ]
    ),
    
    // Index Funds
    "spy": InvestmentNewsTemplate(
        investmentId: "spy",
        bullishNews: [
            "S&P 500 hits all-time high",
            "Corporate earnings beat expectations",
            "Fed signals rate cuts ahead",
            "Economic soft landing achieved",
            "Consumer spending remains strong"
        ],
        bearishNews: [
            "Recession fears mount",
            "Inflation proving sticky",
            "Fed raises rates unexpectedly",
            "Earnings growth slowing",
            "Geopolitical tensions escalate"
        ],
        bullishDetails: [
            "Broad market exposure provides diversification. Lower risk.",
            "Historically returns 10%+ annually over long periods.",
            "Passive investing beats most active managers."
        ],
        bearishDetails: [
            "Market pullback overdue after extended rally.",
            "Concentration in tech names creates risk.",
            "Valuations stretched compared to historical averages."
        ]
    ),
    
    "arkk": InvestmentNewsTemplate(
        investmentId: "arkk",
        bullishNews: [
            "Innovation themes rebounding",
            "Cathie Wood's calls proving right",
            "Genomics and AI stocks surging",
            "Disruptive companies gaining traction",
            "Ark funds seeing inflows again"
        ],
        bearishNews: [
            "ARK continues underperformance streak",
            "High-growth stocks punished by rates",
            "Key holdings see massive declines",
            "Outflows accelerating from fund",
            "Concentration risk in few names"
        ],
        bullishDetails: [
            "High-conviction bets on innovation could pay off big.",
            "5-year time horizon aligns with disruption timeline.",
            "Contrarian opportunity after massive drawdown."
        ],
        bearishDetails: [
            "Track record since 2021 is poor. Expensive underperformance.",
            "High volatility makes position sizing difficult.",
            "Many holdings are unprofitable companies burning cash."
        ]
    )
]

// Default templates for investments without specific news
let defaultBullishNews = [
    "Strong quarterly results reported",
    "Analyst upgrades to Buy rating",
    "Sector showing positive momentum",
    "Institutional buyers accumulating",
    "Technical breakout confirmed"
]

let defaultBearishNews = [
    "Disappointing earnings miss expectations",
    "Analyst downgrades to Sell rating",
    "Sector facing headwinds",
    "Insider selling detected",
    "Technical breakdown signals weakness"
]

let defaultBullishDetails = [
    "Fundamentals remain strong. Growth trajectory intact.",
    "Valuation attractive relative to peers.",
    "Management executing well on strategy."
]

let defaultBearishDetails = [
    "Fundamentals deteriorating. Growth concerns rising.",
    "Valuation appears stretched. Limited upside.",
    "Competitive pressures mounting."
]

// MARK: - Investment Sentiment Manager

class InvestmentSentimentManager: ObservableObject {
    static let shared = InvestmentSentimentManager()
    
    @Published var sentiments: [String: InvestmentSentiment] = [:]
    @Published var lastUpdate: Date = Date()
    
    private var updateTimer: Timer?
    
    private init() {
        loadSentiments()
        startAutoUpdate()
    }
    
    // MARK: - Public Methods
    
    func getSentiment(for investmentId: String) -> InvestmentSentiment {
        if let sentiment = sentiments[investmentId] {
            return sentiment
        }
        // Generate new sentiment for unknown investment
        let newSentiment = generateSentiment(for: investmentId)
        sentiments[investmentId] = newSentiment
        save()
        return newSentiment
    }
    
    func refreshSentiment(for investmentId: String) {
        sentiments[investmentId] = generateSentiment(for: investmentId)
        save()
    }
    
    func refreshAllSentiments() {
        for id in sentiments.keys {
            sentiments[id] = generateSentiment(for: id)
        }
        lastUpdate = Date()
        save()
    }
    
    // MARK: - Sentiment Generation
    
    private func generateSentiment(for investmentId: String) -> InvestmentSentiment {
        // Some investments are always bad (scams, failed companies)
        if let badInvestment = badInvestments[investmentId] {
            return badInvestment
        }
        
        // Generate random sentiment weighted by investment quality
        let level = generateSentimentLevel(for: investmentId)
        let (headline, details) = generateNews(for: investmentId, level: level)
        let trend = generateTrend(currentLevel: level)
        
        return InvestmentSentiment(
            id: investmentId,
            level: level,
            headline: headline,
            details: details,
            lastUpdated: Date(),
            trend: trend
        )
    }
    
    private func generateSentimentLevel(for investmentId: String) -> SentimentLevel {
        // Stable investments (savings, bonds) are mostly neutral/bullish
        let stableInvestments = ["savings", "tbills", "corp_bonds"]
        if stableInvestments.contains(investmentId) {
            let roll = Double.random(in: 0...1)
            if roll < 0.6 { return .neutral }
            if roll < 0.9 { return .bullish }
            return .bearish
        }
        
        // Index funds are mostly stable with occasional swings
        let indexFunds = ["spy", "voo", "vti", "qqq", "vgt", "schd"]
        if indexFunds.contains(investmentId) {
            let roll = Double.random(in: 0...1)
            if roll < 0.15 { return .veryBullish }
            if roll < 0.45 { return .bullish }
            if roll < 0.70 { return .neutral }
            if roll < 0.90 { return .bearish }
            return .veryBearish
        }
        
        // High volatility investments have more extreme swings
        let highVolatility = ["tsla", "nvda", "arkk", "btc", "eth", "sol", "openai", "spacex", "anthropic"]
        if highVolatility.contains(investmentId) {
            let roll = Double.random(in: 0...1)
            if roll < 0.20 { return .veryBullish }
            if roll < 0.40 { return .bullish }
            if roll < 0.55 { return .neutral }
            if roll < 0.75 { return .bearish }
            return .veryBearish
        }
        
        // Default distribution
        let roll = Double.random(in: 0...1)
        if roll < 0.10 { return .veryBullish }
        if roll < 0.35 { return .bullish }
        if roll < 0.60 { return .neutral }
        if roll < 0.85 { return .bearish }
        return .veryBearish
    }
    
    private func generateNews(for investmentId: String, level: SentimentLevel) -> (String, String) {
        let template = investmentNewsTemplates[investmentId]
        
        let isBullish = level == .veryBullish || level == .bullish
        
        let headlines = isBullish 
            ? (template?.bullishNews ?? defaultBullishNews)
            : (template?.bearishNews ?? defaultBearishNews)
        
        let detailsList = isBullish
            ? (template?.bullishDetails ?? defaultBullishDetails)
            : (template?.bearishDetails ?? defaultBearishDetails)
        
        let headline = headlines.randomElement() ?? "Market conditions changing"
        let details = detailsList.randomElement() ?? "Monitor closely for developments."
        
        return (headline, details)
    }
    
    private func generateTrend(currentLevel: SentimentLevel) -> InvestmentSentiment.SentimentTrend {
        // Trends are random but weighted by current level
        let roll = Double.random(in: 0...1)
        
        switch currentLevel {
        case .veryBullish:
            return roll < 0.6 ? .stable : .declining
        case .bullish:
            if roll < 0.3 { return .improving }
            if roll < 0.7 { return .stable }
            return .declining
        case .neutral:
            if roll < 0.35 { return .improving }
            if roll < 0.65 { return .stable }
            return .declining
        case .bearish:
            if roll < 0.3 { return .declining }
            if roll < 0.7 { return .stable }
            return .improving
        case .veryBearish:
            return roll < 0.6 ? .stable : .improving
        case .warning, .avoid:
            return roll < 0.7 ? .declining : .stable
        }
    }
    
    // MARK: - Auto Update
    
    private func startAutoUpdate() {
        // Update sentiments every game year (5 minutes real time)
        // But we'll do it more frequently for gameplay - every 30 seconds
        updateTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.randomlyUpdateSentiments()
        }
    }
    
    private func randomlyUpdateSentiments() {
        // Each tick, ~10% of investments get updated sentiment
        for id in sentiments.keys {
            if Double.random(in: 0...1) < 0.1 {
                sentiments[id] = generateSentiment(for: id)
            }
        }
        lastUpdate = Date()
        save()
    }
    
    // MARK: - Persistence
    
    private func save() {
        if let data = try? JSONEncoder().encode(sentiments) {
            UserDefaults.standard.set(data, forKey: "investmentSentiments")
        }
    }
    
    private func loadSentiments() {
        if let data = UserDefaults.standard.data(forKey: "investmentSentiments"),
           let decoded = try? JSONDecoder().decode([String: InvestmentSentiment].self, from: data) {
            sentiments = decoded
        }
    }
    
    func reset() {
        sentiments = [:]
        lastUpdate = Date()
        UserDefaults.standard.removeObject(forKey: "investmentSentiments")
    }
}

// MARK: - Bad Investments (Always Avoid)

let badInvestments: [String: InvestmentSentiment] = [
    "penny_stock_1": InvestmentSentiment(
        id: "penny_stock_1",
        level: .avoid,
        headline: "SEC investigation ongoing",
        details: "This company has been flagged for potential fraud. Massive losses likely.",
        lastUpdated: Date(),
        trend: .declining
    ),
    "penny_stock_2": InvestmentSentiment(
        id: "penny_stock_2",
        level: .avoid,
        headline: "Company files for bankruptcy",
        details: "All shareholder equity will be wiped out. Do not invest.",
        lastUpdated: Date(),
        trend: .declining
    ),
    "scam_coin": InvestmentSentiment(
        id: "scam_coin",
        level: .avoid,
        headline: "Developers abandon project",
        details: "Classic rug pull. Token has lost 99% of value and will go to zero.",
        lastUpdated: Date(),
        trend: .declining
    ),
    "failed_startup": InvestmentSentiment(
        id: "failed_startup",
        level: .avoid,
        headline: "Startup burns through funding",
        details: "No path to profitability. Shutdown imminent.",
        lastUpdated: Date(),
        trend: .declining
    ),
    "meme_stock": InvestmentSentiment(
        id: "meme_stock",
        level: .warning,
        headline: "Reddit hype fading",
        details: "Momentum has shifted. Bag holders emerging as price collapses.",
        lastUpdated: Date(),
        trend: .declining
    )
]

// MARK: - UI Components

struct InvestmentSentimentBadge: View {
    let sentiment: InvestmentSentiment
    
    var body: some View {
        HStack(spacing: 4) {
            Text(sentiment.level.icon)
                .font(.caption)
            Text(sentiment.level.recommendation)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(sentiment.level.color.opacity(0.2))
        .foregroundColor(sentiment.level.color)
        .cornerRadius(8)
    }
}

struct InvestmentNewsCard: View {
    let sentiment: InvestmentSentiment
    let investmentName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(sentiment.level.icon)
                    .font(.title2)
                Text(investmentName)
                    .font(.headline)
                Spacer()
                InvestmentSentimentBadge(sentiment: sentiment)
            }
            
            Text(sentiment.headline)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text(sentiment.details)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text("Trend: \(sentiment.trend.icon) \(sentiment.trend.rawValue)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Updated \(timeAgo(sentiment.lastUpdated))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        return "\(seconds / 3600)h ago"
    }
}
