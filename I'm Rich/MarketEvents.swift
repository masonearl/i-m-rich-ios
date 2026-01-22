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
        case "stocks", "index_fund": return .stocks
        case "rental", "commercial": return .realEstate
        case "crypto": return .crypto
        case "bonds": return .bonds
        case "startup", "venture_fund": return .startups
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
        multiplier: 1.3,
        duration: 60,
        educationalFact: "During market panics, investors often sell risky assets and buy government bonds, driving up bond prices."
    )
]

// MARK: - Market Event Manager
class MarketEventManager: ObservableObject {
    @Published var currentEvent: MarketEvent?
    @Published var eventHistory: [MarketEvent] = []
    @Published var showEventNotification = false
    
    private var eventTimer: Timer?
    private var eventCooldown: TimeInterval = 0
    private let minCooldown: TimeInterval = 120 // 2 minutes between events
    private let maxCooldown: TimeInterval = 300 // 5 minutes max
    
    init() {
        loadHistory()
        startEventLoop()
    }
    
    func startEventLoop() {
        eventTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    private func tick() {
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
        
        // Random chance to trigger new event
        if currentEvent == nil && Double.random(in: 0...1) < 0.01 { // 1% chance per second
            triggerRandomEvent()
        }
    }
    
    func triggerRandomEvent() {
        guard currentEvent == nil else { return }
        
        if let event = historicalMarketEvents.randomElement() {
            var newEvent = event
            newEvent.isActive = true
            newEvent.startTime = Date()
            currentEvent = newEvent
            showEventNotification = true
            
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
        guard let category = InvestmentCategory.forInvestment(investmentId) else { return 1.0 }
        
        if event.affectedCategories.contains(category) {
            return event.multiplier
        }
        return 1.0
    }
    
    // Get affected investment IDs
    var affectedInvestmentIds: [String] {
        guard let event = currentEvent else { return [] }
        var ids: [String] = []
        
        for category in event.affectedCategories {
            switch category {
            case .stocks: ids.append(contentsOf: ["stocks", "index_fund"])
            case .realEstate: ids.append(contentsOf: ["rental", "commercial"])
            case .crypto: ids.append("crypto")
            case .bonds: ids.append("bonds")
            case .startups: ids.append(contentsOf: ["startup", "venture_fund"])
            case .business: ids.append(contentsOf: ["business", "side_gig"])
            }
        }
        return ids
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
            
            // Affected categories
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
