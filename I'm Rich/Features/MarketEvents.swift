//
//  MarketEvents.swift
//  I'm Rich
//
//  Historical market events that affect investments dynamically
//

import SwiftUI
import Combine

// MARK: - Market Event
struct MarketEvent: Identifiable, Codable {
    let id: String
    let name: String
    let year: String
    let description: String
    let icon: String
    let affectedCategories: [InvestmentCategory]
    let affectedInvestmentIds: [String] // Company-specific investments (e.g., ["aapl", "msft"])
    let multiplier: Double // 0.5 = 50% crash, 2.0 = 100% gain
    let duration: TimeInterval // How long the event lasts
    let educationalFact: String
    var isActive: Bool = false
    var startTime: Date?
    
    var isPositive: Bool {
        multiplier > 1.0
    }
    
    var percentChange: String {
        let change = (multiplier - 1.0) * 100
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(Int(change))%"
    }
}

// MARK: - Investment Category
enum InvestmentCategory: String, Codable, CaseIterable {
    case stocks = "Stocks"
    case realEstate = "Real Estate"
    case crypto = "Crypto"
    case bonds = "Bonds"
    case startups = "Startups"
    case business = "Business"
    
    var icon: String {
        switch self {
        case .stocks: return "📈"
        case .realEstate: return "🏠"
        case .crypto: return "₿"
        case .bonds: return "📜"
        case .startups: return "🚀"
        case .business: return "💼"
        }
    }
    
    // Map investment IDs to categories
    static func forInvestment(_ id: String) -> InvestmentCategory? {
        switch id {
        case "spy", "voo", "qqq", "vti", "vgt", "schd", "arkk", "aapl", "msft", "googl", "amzn", "nvda", "meta", "tsla", "brk", "jpm", "v": return .stocks
        case "rental", "commercial", "apartment": return .realEstate
        case "btc", "eth", "sol": return .crypto
        case "tbills", "corp_bonds": return .bonds
        case "openai", "spacex", "stripe", "anthropic", "vc_fund": return .startups
        case "business", "side_gig": return .business
        default: return nil
        }
    }
}

// MARK: - Historical Market Events
let historicalMarketEvents: [MarketEvent] = [
    // Crashes / Negative Events
    MarketEvent(
        id: "dotcom_crash",
        name: "Dot-Com Bubble Burst",
        year: "2000",
        description: "The tech bubble bursts! Overvalued tech stocks crash.",
        icon: "💥",
        affectedCategories: [.stocks, .startups],
        affectedInvestmentIds: [],
        multiplier: 0.3,
        duration: 120, // 2 minutes
        educationalFact: "The NASDAQ lost 78% of its value from 2000-2002. Many companies that had never turned a profit went bankrupt."
    ),
    MarketEvent(
        id: "financial_crisis",
        name: "2008 Financial Crisis",
        year: "2008",
        description: "Housing market collapse triggers global recession!",
        icon: "🏚️",
        affectedCategories: [.realEstate, .stocks, .business],
        affectedInvestmentIds: [],
        multiplier: 0.4,
        duration: 120,
        educationalFact: "The crisis was caused by subprime mortgages. Home prices fell 33% on average, and unemployment reached 10%."
    ),
    MarketEvent(
        id: "covid_crash",
        name: "COVID Market Crash",
        year: "2020",
        description: "Pandemic fears cause market panic!",
        icon: "🦠",
        affectedCategories: [.stocks, .business, .realEstate],
        affectedInvestmentIds: [],
        multiplier: 0.65,
        duration: 90,
        educationalFact: "The S&P 500 fell 34% in just 23 trading days. However, it recovered to new highs within 5 months."
    ),
    MarketEvent(
        id: "crypto_winter",
        name: "Crypto Winter",
        year: "2022",
        description: "Major crypto exchanges collapse. Prices plummet!",
        icon: "🥶",
        affectedCategories: [.crypto],
        affectedInvestmentIds: [],
        multiplier: 0.25,
        duration: 120,
        educationalFact: "Bitcoin lost over 75% of its value. The collapse of FTX showed the risks of unregulated exchanges."
    ),
    MarketEvent(
        id: "fed_rate_hike",
        name: "Fed Rate Hike",
        year: "2023",
        description: "Interest rates rise sharply. Growth stocks suffer.",
        icon: "🏛️",
        affectedCategories: [.stocks, .startups],
        affectedInvestmentIds: [],
        multiplier: 0.85,
        duration: 60,
        educationalFact: "Higher interest rates make bonds more attractive and increase borrowing costs, hurting growth companies."
    ),
    
    // Booms / Positive Events
    MarketEvent(
        id: "bitcoin_boom",
        name: "Bitcoin Boom",
        year: "2017",
        description: "Cryptocurrency mania! Bitcoin hits all-time highs!",
        icon: "🚀",
        affectedCategories: [.crypto],
        affectedInvestmentIds: [],
        multiplier: 3.0,
        duration: 90,
        educationalFact: "Bitcoin rose from $1,000 to $20,000 in 2017. Early investors saw life-changing returns."
    ),
    MarketEvent(
        id: "covid_recovery",
        name: "Post-COVID Bull Run",
        year: "2021",
        description: "Markets surge on stimulus and reopening hopes!",
        icon: "📈",
        affectedCategories: [.stocks, .realEstate, .crypto],
        affectedInvestmentIds: [],
        multiplier: 1.5,
        duration: 120,
        educationalFact: "The S&P 500 gained 27% in 2021. Home prices rose 19% as remote work changed housing demand."
    ),
    MarketEvent(
        id: "meme_stock_mania",
        name: "Meme Stock Mania",
        year: "2021",
        description: "Reddit traders take on Wall Street! 🦍💎🙌",
        icon: "🎮",
        affectedCategories: [.stocks],
        affectedInvestmentIds: [],
        multiplier: 2.5,
        duration: 60,
        educationalFact: "GameStop rose 1,500% in January 2021. Retail investors coordinated on social media to create a short squeeze."
    ),
    MarketEvent(
        id: "tech_boom",
        name: "Tech Sector Boom",
        year: "2024",
        description: "AI hype drives tech valuations to new heights!",
        icon: "🤖",
        affectedCategories: [.stocks, .startups],
        affectedInvestmentIds: [],
        multiplier: 1.8,
        duration: 90,
        educationalFact: "AI companies saw massive valuation increases. The 'Magnificent 7' tech stocks drove most of the market's gains."
    ),
    MarketEvent(
        id: "real_estate_boom",
        name: "Housing Boom",
        year: "2021",
        description: "Low rates and high demand send home prices soaring!",
        icon: "🏠",
        affectedCategories: [.realEstate],
        affectedInvestmentIds: [],
        multiplier: 1.4,
        duration: 120,
        educationalFact: "Record-low mortgage rates and pandemic migration patterns created bidding wars and record home prices."
    ),
    MarketEvent(
        id: "startup_frenzy",
        name: "Startup Funding Frenzy",
        year: "2021",
        description: "VCs throw money at every startup with a pulse!",
        icon: "💸",
        affectedCategories: [.startups],
        affectedInvestmentIds: [],
        multiplier: 2.0,
        duration: 90,
        educationalFact: "VC funding hit $330 billion in 2021, more than double the previous year. Valuations reached unprecedented levels."
    ),
    MarketEvent(
        id: "bond_rally",
        name: "Flight to Safety",
        year: "2020",
        description: "Investors flee to bonds. Safe haven assets surge!",
        icon: "🛡️",
        affectedCategories: [.bonds],
        affectedInvestmentIds: [],
        multiplier: 1.3,
        duration: 60,
        educationalFact: "During market panics, investors often sell risky assets and buy government bonds, driving up bond prices."
    ),
    
    // ═══════════════════════════════════════════════════════════════
    // COMPANY-SPECIFIC NEWS EVENTS
    // ═══════════════════════════════════════════════════════════════
    
    // Apple Events
    MarketEvent(
        id: "apple_innovative_phone",
        name: "Apple Releases Revolutionary iPhone",
        year: "2024",
        description: "Apple unveils truly innovative phone with breakthrough features!",
        icon: "🍎",
        affectedCategories: [],
        affectedInvestmentIds: ["aapl", "qqq", "vgt"],
        multiplier: 1.15,
        duration: 180,
        educationalFact: "Major product launches can drive significant stock gains. Apple's iPhone launches historically boost stock 5-15%."
    ),
    MarketEvent(
        id: "apple_ai_fumble",
        name: "Apple Struggles with AI Integration",
        year: "2024",
        description: "Apple fumbles AI integration. Investors lose confidence.",
        icon: "🍎",
        affectedCategories: [],
        affectedInvestmentIds: ["aapl"],
        multiplier: 0.95,
        duration: 120,
        educationalFact: "Tech companies that fall behind in AI face investor skepticism. Stock can drop 5-10% on AI missteps."
    ),
    MarketEvent(
        id: "apple_bad_year",
        name: "Apple Has Disappointing Year",
        year: "2024",
        description: "Weak iPhone sales and supply chain issues hit Apple hard.",
        icon: "🍎",
        affectedCategories: [],
        affectedInvestmentIds: ["aapl"],
        multiplier: 0.90,
        duration: 150,
        educationalFact: "Even blue-chip stocks can have bad years. Apple fell 27% in 2022 due to supply chain and demand concerns."
    ),
    
    // Microsoft Events
    MarketEvent(
        id: "microsoft_ai_breakthrough",
        name: "Microsoft AI Dominance",
        year: "2024",
        description: "Microsoft's AI integration drives record cloud growth!",
        icon: "🪟",
        affectedCategories: [],
        affectedInvestmentIds: ["msft", "qqq", "vgt"],
        multiplier: 1.12,
        duration: 180,
        educationalFact: "Microsoft's Azure and AI investments have driven significant stock gains. Cloud revenue grew 27% in 2023."
    ),
    MarketEvent(
        id: "microsoft_security_breach",
        name: "Microsoft Security Breach",
        year: "2024",
        description: "Major security incident shakes investor confidence.",
        icon: "🪟",
        affectedCategories: [],
        affectedInvestmentIds: ["msft"],
        multiplier: 0.93,
        duration: 120,
        educationalFact: "Security breaches can cause immediate stock drops. Companies must invest heavily in cybersecurity."
    ),
    
    // Tesla Events
    MarketEvent(
        id: "tesla_record_deliveries",
        name: "Tesla Smashes Delivery Records",
        year: "2024",
        description: "Tesla delivers record number of vehicles! Stock surges.",
        icon: "🚗",
        affectedCategories: [],
        affectedInvestmentIds: ["tsla"],
        multiplier: 1.20,
        duration: 150,
        educationalFact: "Tesla's stock is highly sensitive to delivery numbers. Record deliveries often drive 15-25% gains."
    ),
    MarketEvent(
        id: "tesla_autopilot_issues",
        name: "Tesla Autopilot Under Scrutiny",
        year: "2024",
        description: "Regulatory concerns over Autopilot safety hit Tesla stock.",
        icon: "🚗",
        affectedCategories: [],
        affectedInvestmentIds: ["tsla"],
        multiplier: 0.88,
        duration: 180,
        educationalFact: "Regulatory scrutiny can significantly impact Tesla's valuation. Safety concerns caused 30% drops in the past."
    ),
    
    // NVIDIA Events
    MarketEvent(
        id: "nvidia_ai_chip_demand",
        name: "NVIDIA AI Chip Demand Soars",
        year: "2024",
        description: "Unprecedented demand for AI chips drives NVIDIA higher!",
        icon: "🎮",
        affectedCategories: [],
        affectedInvestmentIds: ["nvda", "qqq", "vgt"],
        multiplier: 1.25,
        duration: 180,
        educationalFact: "NVIDIA's data center revenue grew 279% in 2023 due to AI demand. Stock gained 239% that year."
    ),
    MarketEvent(
        id: "nvidia_chip_shortage",
        name: "NVIDIA Faces Supply Constraints",
        year: "2024",
        description: "Chip manufacturing delays limit NVIDIA's growth potential.",
        icon: "🎮",
        affectedCategories: [],
        affectedInvestmentIds: ["nvda"],
        multiplier: 0.92,
        duration: 120,
        educationalFact: "Supply chain issues can limit even the hottest stocks. NVIDIA faced shortages during the crypto mining boom."
    ),
    
    // Meta Events
    MarketEvent(
        id: "meta_vr_breakthrough",
        name: "Meta VR Headset Goes Mainstream",
        year: "2024",
        description: "Meta's VR technology finally gains mass adoption!",
        icon: "👓",
        affectedCategories: [],
        affectedInvestmentIds: ["meta"],
        multiplier: 1.18,
        duration: 150,
        educationalFact: "Meta invested $50B+ in VR/AR. Mainstream adoption could validate this massive bet."
    ),
    MarketEvent(
        id: "meta_privacy_concerns",
        name: "Meta Faces Privacy Backlash",
        year: "2024",
        description: "User privacy concerns and regulatory pressure hit Meta.",
        icon: "👓",
        affectedCategories: [],
        affectedInvestmentIds: ["meta"],
        multiplier: 0.94,
        duration: 120,
        educationalFact: "Privacy concerns have caused Meta stock to drop 20%+ in the past. Regulation is a constant risk."
    ),
    
    // Amazon Events
    MarketEvent(
        id: "amazon_aws_growth",
        name: "Amazon AWS Revenue Explodes",
        year: "2024",
        description: "Cloud computing demand drives Amazon's profits higher!",
        icon: "📦",
        affectedCategories: [],
        affectedInvestmentIds: ["amzn", "qqq", "vgt"],
        multiplier: 1.15,
        duration: 180,
        educationalFact: "AWS accounts for most of Amazon's operating profit. Cloud growth drives the entire company."
    ),
    MarketEvent(
        id: "amazon_logistics_issues",
        name: "Amazon Delivery Problems",
        year: "2024",
        description: "Logistics challenges and rising costs pressure Amazon margins.",
        icon: "📦",
        affectedCategories: [],
        affectedInvestmentIds: ["amzn"],
        multiplier: 0.92,
        duration: 120,
        educationalFact: "Amazon's logistics network is massive and expensive. Delivery issues can hurt profitability."
    ),
    
    // Google/Alphabet Events
    MarketEvent(
        id: "google_search_dominance",
        name: "Google Search AI Integration Success",
        year: "2024",
        description: "Google's AI-powered search maintains dominance!",
        icon: "🔍",
        affectedCategories: [],
        affectedInvestmentIds: ["googl", "qqq", "vgt"],
        multiplier: 1.10,
        duration: 150,
        educationalFact: "Google's search dominance generates most revenue. AI integration is critical to maintaining this."
    ),
    MarketEvent(
        id: "google_antitrust_fine",
        name: "Google Hit with Massive Antitrust Fine",
        year: "2024",
        description: "Regulatory action threatens Google's business model.",
        icon: "🔍",
        affectedCategories: [],
        affectedInvestmentIds: ["googl"],
        multiplier: 0.93,
        duration: 180,
        educationalFact: "Google has faced billions in antitrust fines. Regulatory risk is a constant threat to tech giants."
    ),
    
    // Tech Sector Events (affect ETFs)
    MarketEvent(
        id: "tech_sector_rotation",
        name: "Investors Rotate Out of Tech",
        year: "2024",
        description: "Value stocks outperform. Tech sector faces headwinds.",
        icon: "📉",
        affectedCategories: [],
        affectedInvestmentIds: ["qqq", "vgt", "spy", "voo"],
        multiplier: 0.92,
        duration: 150,
        educationalFact: "Sector rotation happens when investors move money between sectors. Tech can underperform for months."
    ),
    MarketEvent(
        id: "tech_earnings_surprise",
        name: "Tech Earnings Beat Expectations",
        year: "2024",
        description: "Major tech companies report strong earnings across the board!",
        icon: "📈",
        affectedCategories: [],
        affectedInvestmentIds: ["qqq", "vgt", "spy", "voo", "aapl", "msft", "googl", "amzn", "nvda", "meta"],
        multiplier: 1.08,
        duration: 120,
        educationalFact: "Strong earnings seasons can drive tech rallies. The Magnificent 7 often move together."
    )
]

// MARK: - Market Event Manager
class MarketEventManager: ObservableObject {
    static let shared = MarketEventManager()
    
    @Published var currentEvent: MarketEvent?
    @Published var eventHistory: [MarketEvent] = []
    @Published var showEventNotification = false
    
    private var eventTimer: Timer?
    private var eventCooldown: TimeInterval = 0
    private let minCooldown: TimeInterval = 120 // 2 minutes between events
    private let maxCooldown: TimeInterval = 300 // 5 minutes max
    
    private init() {
        loadHistory()
        startEventLoop()
    }
    
    func startEventLoop() {
        eventTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    func tick() {
        // Check if current event has expired
        if let event = currentEvent,
           let startTime = event.startTime,
           Date().timeIntervalSince(startTime) >= event.duration {
            endCurrentEvent()
        }
        
        // Cooldown
        if eventCooldown > 0 {
            eventCooldown -= 1
            return
        }
        
        // Random chance to trigger new event (more frequent for company-specific news)
        if currentEvent == nil {
            // 0.8% chance per second for general events, 0.5% for company-specific
            if Double.random(in: 0...1) < 0.008 {
                triggerRandomEvent()
            } else if Double.random(in: 0...1) < 0.005 {
                triggerCompanyNewsEvent()
            }
        }
    }
    
    func triggerRandomEvent() {
        guard currentEvent == nil else { return }
        
        // Filter to general market events (those without company-specific IDs)
        let generalEvents = historicalMarketEvents.filter { $0.affectedInvestmentIds.isEmpty }
        
        if let event = generalEvents.randomElement() {
            var newEvent = event
            newEvent.isActive = true
            newEvent.startTime = Date()
            currentEvent = newEvent
            showEventNotification = true
            
            // Add to news feed
            NewsFeedManager.shared.addNews(
                category: .markets,
                headline: "\(event.name): \(event.description)"
            )
            
            FeedbackCoordinator.shared.opportunityAppear()
        }
    }
    
    func triggerCompanyNewsEvent() {
        guard currentEvent == nil else { return }
        
        // Filter to company-specific events
        let companyEvents = historicalMarketEvents.filter { !$0.affectedInvestmentIds.isEmpty }
        
        if let event = companyEvents.randomElement() {
            var newEvent = event
            newEvent.isActive = true
            newEvent.startTime = Date()
            currentEvent = newEvent
            showEventNotification = true
            
            // Add to news feed with breaking news tag
            NewsFeedManager.shared.addNews(
                category: .breaking,
                headline: "\(event.name): \(event.description)"
            )
            
            FeedbackCoordinator.shared.opportunityAppear()
        }
    }
    
    private func endCurrentEvent() {
        if var event = currentEvent {
            event.isActive = false
            eventHistory.append(event)
            saveHistory()
        }
        currentEvent = nil
        eventCooldown = Double.random(in: minCooldown...maxCooldown)
    }
    
    func dismissNotification() {
        showEventNotification = false
    }
    
    // Calculate the current multiplier for an investment
    func getMultiplier(for investmentId: String) -> Double {
        guard let event = currentEvent, event.isActive else { return 1.0 }
        
        // Check if this specific investment is affected (company-specific events)
        if event.affectedInvestmentIds.contains(investmentId) {
            return event.multiplier
        }
        
        // Check if investment category is affected (broad market events)
        if let category = InvestmentCategory.forInvestment(investmentId),
           event.affectedCategories.contains(category) {
            return event.multiplier
        }
        
        return 1.0
    }
    
    // Get all affected investment IDs (both company-specific and category-based)
    var allAffectedInvestmentIds: [String] {
        guard let event = currentEvent else { return [] }
        var ids: [String] = []
        
        // Add company-specific investments
        ids.append(contentsOf: event.affectedInvestmentIds)
        
        // Add category-based investments
        for category in event.affectedCategories {
            switch category {
            case .stocks: ids.append(contentsOf: ["spy", "voo", "qqq", "vti", "vgt", "schd", "arkk", "aapl", "msft", "googl", "amzn", "nvda", "meta", "tsla", "brk", "jpm", "v"])
            case .realEstate: ids.append(contentsOf: ["rental", "commercial", "apartment"])
            case .crypto: ids.append(contentsOf: ["btc", "eth", "sol"])
            case .bonds: ids.append(contentsOf: ["tbills", "corp_bonds"])
            case .startups: ids.append(contentsOf: ["openai", "spacex", "stripe", "anthropic", "vc_fund"])
            case .business: ids.append(contentsOf: ["business", "side_gig"])
            }
        }
        
        // Remove duplicates
        return Array(Set(ids))
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "marketEventHistory"),
           let decoded = try? JSONDecoder().decode([MarketEvent].self, from: data) {
            eventHistory = decoded
        }
    }
    
    private func saveHistory() {
        if let data = try? JSONEncoder().encode(eventHistory) {
            UserDefaults.standard.set(data, forKey: "marketEventHistory")
        }
    }
    
    func reset() {
        currentEvent = nil
        eventHistory = []
        eventCooldown = 0
    }
}

// MARK: - Market Event Banner View
struct MarketEventBannerView: View {
    let event: MarketEvent
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(event.icon)
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(event.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("(\(event.year))")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    Text(event.description)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text(event.percentChange)
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(event.isPositive ? .green : .red)
            }
            
            // Affected investments
            VStack(alignment: .leading, spacing: 8) {
                if !event.affectedCategories.isEmpty {
                    HStack(spacing: 8) {
                        Text("Affects:")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                        
                        ForEach(event.affectedCategories, id: \.self) { category in
                            HStack(spacing: 4) {
                                Text(category.icon)
                                    .font(.system(size: 12))
                                Text(category.rawValue)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(event.isPositive ? .green : .red)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background((event.isPositive ? Color.green : Color.red).opacity(0.2))
                            .cornerRadius(6)
                        }
                        
                        Spacer()
                    }
                }
                
                if !event.affectedInvestmentIds.isEmpty {
                    HStack(spacing: 8) {
                        Text("Companies:")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(event.affectedInvestmentIds.prefix(5), id: \.self) { id in
                                    Text(id.uppercased())
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(event.isPositive ? .green : .red)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background((event.isPositive ? Color.green : Color.red).opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
            
            // Educational fact
            Text("💡 \(event.educationalFact)")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.8))
                .padding(10)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill((event.isPositive ? Color.green : Color.red).opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(event.isPositive ? Color.green : Color.red, lineWidth: 2)
                )
        )
        .onTapGesture {
            onDismiss()
        }
    }
}

// MARK: - Market Event Notification View
struct MarketEventNotificationView: View {
    let event: MarketEvent
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Text(event.isPositive ? "📈" : "📉")
                .font(.system(size: 60))
            
            Text("MARKET EVENT")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(event.isPositive ? .green : .red)
                .tracking(2)
            
            Text(event.name)
                .font(.system(size: 24, weight: .black))
                .foregroundColor(.white)
            
            Text(event.description)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            // Impact
            HStack(spacing: 20) {
                ForEach(event.affectedCategories, id: \.self) { category in
                    VStack {
                        Text(category.icon)
                            .font(.system(size: 24))
                        Text(event.percentChange)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(event.isPositive ? .green : .red)
                    }
                }
            }
            .padding(.vertical, 10)
            
            Button(action: onDismiss) {
                Text("GOT IT")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(event.isPositive ? Color.green : Color.red)
                    .cornerRadius(10)
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(event.isPositive ? Color.green : Color.red, lineWidth: 2)
                )
        )
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}
