//
//  GameModels.swift
//  I'm Rich
//
//  Multi-phase wealth strategy game models
//

import SwiftUI

// MARK: - CEO Title (Identity System)
enum CEOTitle: String, CaseIterable {
    case aspirant = "Aspirant"
    case freelancer = "Freelancer"
    case entrepreneur = "Entrepreneur"
    case founder = "Founder"
    case ceo = "CEO"
    case executive = "Executive"
    case mogul = "Mogul"
    case titan = "Titan"
    case legend = "Legend"
    
    var icon: String {
        switch self {
        case .aspirant: return "🌱"
        case .freelancer: return "💼"
        case .entrepreneur: return "🚀"
        case .founder: return "🏗️"
        case .ceo: return "👔"
        case .executive: return "🎯"
        case .mogul: return "👑"
        case .titan: return "⚡"
        case .legend: return "🏆"
        }
    }
    
    var description: String {
        switch self {
        case .aspirant: return "Just starting out"
        case .freelancer: return "Working for yourself"
        case .entrepreneur: return "Building something"
        case .founder: return "Leading a company"
        case .ceo: return "Running an empire"
        case .executive: return "Multi-company influence"
        case .mogul: return "Industry dominance"
        case .titan: return "Economic powerhouse"
        case .legend: return "Generational wealth"
        }
    }
    
    var color: Color {
        switch self {
        case .aspirant: return .gray
        case .freelancer: return .blue
        case .entrepreneur: return .cyan
        case .founder: return .green
        case .ceo: return .yellow
        case .executive: return .orange
        case .mogul: return .purple
        case .titan: return .red
        case .legend: return Color(red: 1, green: 0.84, blue: 0)  // Gold
        }
    }
    
    /// Determine CEO title from net worth and total taps
    static func fromProgress(netWorth: Double, totalTaps: Int) -> CEOTitle {
        // Net worth thresholds (primary factor)
        let wealthTitle: CEOTitle
        switch netWorth {
        case 0..<1_000: wealthTitle = .aspirant
        case 1_000..<10_000: wealthTitle = .freelancer
        case 10_000..<100_000: wealthTitle = .entrepreneur
        case 100_000..<1_000_000: wealthTitle = .founder
        case 1_000_000..<10_000_000: wealthTitle = .ceo
        case 10_000_000..<100_000_000: wealthTitle = .executive
        case 100_000_000..<1_000_000_000: wealthTitle = .mogul
        case 1_000_000_000..<100_000_000_000: wealthTitle = .titan
        default: wealthTitle = .legend
        }
        
        // Hustle bonus: High tap counts can boost your title by 1 level
        let hustleBonus = totalTaps >= 100_000
        if hustleBonus && wealthTitle != .legend {
            if let currentIndex = CEOTitle.allCases.firstIndex(of: wealthTitle),
               currentIndex < CEOTitle.allCases.count - 1 {
                // Don't actually boost, just acknowledge hustle separately
                // The title is primarily wealth-based
            }
        }
        
        return wealthTitle
    }
    
    /// Get the next title
    var next: CEOTitle? {
        guard let index = CEOTitle.allCases.firstIndex(of: self),
              index < CEOTitle.allCases.count - 1 else { return nil }
        return CEOTitle.allCases[index + 1]
    }
    
    /// Net worth required for this title
    var requiredNetWorth: Double {
        switch self {
        case .aspirant: return 0
        case .freelancer: return 1_000
        case .entrepreneur: return 10_000
        case .founder: return 100_000
        case .ceo: return 1_000_000
        case .executive: return 10_000_000
        case .mogul: return 100_000_000
        case .titan: return 1_000_000_000
        case .legend: return 100_000_000_000
        }
    }
}

// MARK: - Game Phase
enum GamePhase: Int, Codable, CaseIterable {
    case hustle = 1
    case careerLeverage = 2
    case portfolioEngine = 3
    case legacyScale = 4
    
    var name: String {
        switch self {
        case .hustle: return "Hustle"
        case .careerLeverage: return "Career & Leverage"
        case .portfolioEngine: return "Portfolio Engine"
        case .legacyScale: return "Legacy & Scale"
        }
    }
    
    var icon: String {
        switch self {
        case .hustle: return "💪"
        case .careerLeverage: return "📈"
        case .portfolioEngine: return "🏦"
        case .legacyScale: return "🌍"
        }
    }
    
    var unlockRequirement: Double {
        // Slower progression for 5-hour gameplay
        switch self {
        case .hustle: return 0
        case .careerLeverage: return 25_000           // Was 10K - need more hustling
        case .portfolioEngine: return 2_500_000       // Was 1M - need more career building
        case .legacyScale: return 250_000_000         // Was 100M - need more portfolio growth
        }
    }
    
    var description: String {
        switch self {
        case .hustle: return "Build your foundation through hard work and smart choices."
        case .careerLeverage: return "Choose your path and leverage debt strategically."
        case .portfolioEngine: return "Diversify investments and launch products."
        case .legacyScale: return "Build your empire and influence the world."
        }
    }
}

// MARK: - Career Path
enum CareerPath: String, Codable, CaseIterable {
    case tech = "Tech"
    case finance = "Finance"
    case creator = "Creator"
    case trades = "Trades"
    
    var icon: String {
        switch self {
        case .tech: return "💻"
        case .finance: return "📊"
        case .creator: return "🎨"
        case .trades: return "🔧"
        }
    }
    
    var description: String {
        switch self {
        case .tech: return "Build software and scale with technology"
        case .finance: return "Master markets and compound capital"
        case .creator: return "Build audiences and monetize influence"
        case .trades: return "Skilled work with high income potential"
        }
    }
    
    var incomeMultiplier: Double {
        switch self {
        case .tech: return 1.3
        case .finance: return 1.2
        case .creator: return 1.5
        case .trades: return 1.1
        }
    }
    
    var roles: [CareerRole] {
        switch self {
        case .tech:
            return [
                CareerRole(title: "Junior Developer", salary: 75_000, statusPoints: 10, meetingUnlock: "Team Lead"),
                CareerRole(title: "Software Engineer", salary: 120_000, statusPoints: 25, meetingUnlock: "Engineering Manager"),
                CareerRole(title: "Senior Engineer", salary: 180_000, statusPoints: 50, meetingUnlock: "Director of Engineering"),
                CareerRole(title: "Staff Engineer", salary: 280_000, statusPoints: 100, meetingUnlock: "VP of Engineering"),
                CareerRole(title: "Principal Engineer", salary: 400_000, statusPoints: 200, meetingUnlock: "CTO"),
                CareerRole(title: "VP of Engineering", salary: 600_000, statusPoints: 400, meetingUnlock: "CEO"),
                CareerRole(title: "CTO", salary: 1_000_000, statusPoints: 800, meetingUnlock: "Tim Cook"),
                CareerRole(title: "CEO", salary: 5_000_000, statusPoints: 2000, meetingUnlock: "World Leaders")
            ]
        case .finance:
            return [
                CareerRole(title: "Analyst", salary: 85_000, statusPoints: 10, meetingUnlock: "Associate"),
                CareerRole(title: "Associate", salary: 150_000, statusPoints: 30, meetingUnlock: "Vice President"),
                CareerRole(title: "Vice President", salary: 250_000, statusPoints: 60, meetingUnlock: "Director"),
                CareerRole(title: "Director", salary: 400_000, statusPoints: 120, meetingUnlock: "Managing Director"),
                CareerRole(title: "Managing Director", salary: 700_000, statusPoints: 250, meetingUnlock: "Partner"),
                CareerRole(title: "Partner", salary: 2_000_000, statusPoints: 500, meetingUnlock: "Warren Buffett"),
                CareerRole(title: "Fund Manager", salary: 10_000_000, statusPoints: 1500, meetingUnlock: "Central Bankers"),
                CareerRole(title: "Hedge Fund Legend", salary: 50_000_000, statusPoints: 5000, meetingUnlock: "World Leaders")
            ]
        case .creator:
            return [
                CareerRole(title: "Content Creator", salary: 30_000, statusPoints: 15, meetingUnlock: "Other Creators"),
                CareerRole(title: "Influencer", salary: 100_000, statusPoints: 40, meetingUnlock: "Brand Managers"),
                CareerRole(title: "Verified Creator", salary: 250_000, statusPoints: 80, meetingUnlock: "Celebrity Agents"),
                CareerRole(title: "Brand Ambassador", salary: 500_000, statusPoints: 150, meetingUnlock: "Celebrities"),
                CareerRole(title: "Media Personality", salary: 1_000_000, statusPoints: 300, meetingUnlock: "A-List Celebrities"),
                CareerRole(title: "Celebrity", salary: 5_000_000, statusPoints: 700, meetingUnlock: "Elon Musk"),
                CareerRole(title: "Mega Influencer", salary: 20_000_000, statusPoints: 2000, meetingUnlock: "Global Icons"),
                CareerRole(title: "Global Icon", salary: 100_000_000, statusPoints: 10000, meetingUnlock: "World Leaders")
            ]
        case .trades:
            return [
                CareerRole(title: "Apprentice", salary: 45_000, statusPoints: 5, meetingUnlock: "Journeyman"),
                CareerRole(title: "Journeyman", salary: 75_000, statusPoints: 15, meetingUnlock: "Foreman"),
                CareerRole(title: "Foreman", salary: 100_000, statusPoints: 30, meetingUnlock: "Contractor"),
                CareerRole(title: "Contractor", salary: 150_000, statusPoints: 60, meetingUnlock: "Business Owner"),
                CareerRole(title: "Business Owner", salary: 300_000, statusPoints: 120, meetingUnlock: "Regional Executives"),
                CareerRole(title: "Regional Owner", salary: 750_000, statusPoints: 250, meetingUnlock: "Industry Leaders"),
                CareerRole(title: "Franchise King", salary: 3_000_000, statusPoints: 600, meetingUnlock: "Billionaires"),
                CareerRole(title: "Industry Titan", salary: 20_000_000, statusPoints: 2000, meetingUnlock: "World Leaders")
            ]
        }
    }
}

struct CareerRole: Codable, Identifiable {
    var id: String { title }
    let title: String
    let salary: Double
    let statusPoints: Int
    let meetingUnlock: String
}

// MARK: - Investment Types
struct Investment: Identifiable, Codable {
    let id: String
    let name: String
    let icon: String
    let description: String
    let minInvestment: Double
    let riskLevel: RiskLevel
    let baseReturn: Double // Annual return rate
    let volatility: Double // How much return can vary
    let phaseUnlock: GamePhase
    var amountInvested: Double = 0
    var unrealizedGains: Double = 0 // Accumulates throughout the year
    
    var expectedReturn: Double {
        amountInvested * baseReturn
    }
    
    var totalValue: Double {
        amountInvested + unrealizedGains
    }
    
    var formattedGains: String {
        if unrealizedGains >= 0 {
            return "+$\(Int(unrealizedGains))"
        } else {
            return "-$\(Int(abs(unrealizedGains)))"
        }
    }
    
    enum RiskLevel: String, Codable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case extreme = "Extreme"
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .extreme: return .red
            }
        }
    }
}

let allInvestments: [Investment] = [
    // ═══════════════════════════════════════════════════════════════
    // PHASE 1 - HUSTLE (Starting out, low minimums)
    // Returns REDUCED for 5-hour gameplay
    // ═══════════════════════════════════════════════════════════════
    
    // Safe Options (very low returns - realistic)
    Investment(id: "savings", name: "High-Yield Savings", icon: "🏦", description: "FDIC insured, 4.5% APY", minInvestment: 100, riskLevel: .low, baseReturn: 0.045, volatility: 0.0, phaseUnlock: .hustle),
    Investment(id: "tbills", name: "Treasury Bills", icon: "🇺🇸", description: "US Government bonds", minInvestment: 100, riskLevel: .low, baseReturn: 0.05, volatility: 0.02, phaseUnlock: .hustle),
    
    // ETFs & Index Funds (realistic returns)
    Investment(id: "spy", name: "S&P 500 (SPY)", icon: "📊", description: "Top 500 US companies", minInvestment: 500, riskLevel: .low, baseReturn: 0.08, volatility: 0.18, phaseUnlock: .hustle),
    Investment(id: "voo", name: "Vanguard S&P (VOO)", icon: "📈", description: "Low-cost S&P 500", minInvestment: 400, riskLevel: .low, baseReturn: 0.08, volatility: 0.17, phaseUnlock: .hustle),
    Investment(id: "qqq", name: "Nasdaq 100 (QQQ)", icon: "💻", description: "Top tech companies", minInvestment: 500, riskLevel: .medium, baseReturn: 0.10, volatility: 0.25, phaseUnlock: .hustle),
    Investment(id: "vti", name: "Total Market (VTI)", icon: "🌎", description: "Entire US stock market", minInvestment: 250, riskLevel: .low, baseReturn: 0.07, volatility: 0.16, phaseUnlock: .hustle),
    Investment(id: "vgt", name: "Tech Sector (VGT)", icon: "🖥️", description: "Pure tech exposure", minInvestment: 500, riskLevel: .medium, baseReturn: 0.11, volatility: 0.28, phaseUnlock: .hustle),
    Investment(id: "schd", name: "Dividend (SCHD)", icon: "💰", description: "High dividend stocks", minInvestment: 300, riskLevel: .low, baseReturn: 0.06, volatility: 0.14, phaseUnlock: .hustle),
    Investment(id: "arkk", name: "ARK Innovation", icon: "🚀", description: "Disruptive innovation", minInvestment: 500, riskLevel: .high, baseReturn: 0.15, volatility: 0.50, phaseUnlock: .hustle),
    
    // ═══════════════════════════════════════════════════════════════
    // PHASE 2 - CAREER & LEVERAGE (Individual stocks unlocked)
    // ═══════════════════════════════════════════════════════════════
    
    // Magnificent 7 Tech Giants (realistic returns)
    Investment(id: "aapl", name: "Apple (AAPL)", icon: "🍎", description: "iPhone, Mac, Services", minInvestment: 1000, riskLevel: .medium, baseReturn: 0.10, volatility: 0.28, phaseUnlock: .careerLeverage),
    Investment(id: "msft", name: "Microsoft (MSFT)", icon: "🪟", description: "Windows, Azure, AI", minInvestment: 1000, riskLevel: .medium, baseReturn: 0.11, volatility: 0.25, phaseUnlock: .careerLeverage),
    Investment(id: "googl", name: "Alphabet (GOOGL)", icon: "🔍", description: "Google, YouTube, Cloud", minInvestment: 1000, riskLevel: .medium, baseReturn: 0.10, volatility: 0.30, phaseUnlock: .careerLeverage),
    Investment(id: "amzn", name: "Amazon (AMZN)", icon: "📦", description: "E-commerce, AWS, AI", minInvestment: 1000, riskLevel: .medium, baseReturn: 0.12, volatility: 0.35, phaseUnlock: .careerLeverage),
    Investment(id: "nvda", name: "NVIDIA (NVDA)", icon: "🎮", description: "AI chips, GPUs, Data Centers", minInvestment: 1000, riskLevel: .high, baseReturn: 0.20, volatility: 0.55, phaseUnlock: .careerLeverage),
    Investment(id: "meta", name: "Meta (META)", icon: "👓", description: "Facebook, Instagram, VR", minInvestment: 1000, riskLevel: .medium, baseReturn: 0.12, volatility: 0.40, phaseUnlock: .careerLeverage),
    Investment(id: "tsla", name: "Tesla (TSLA)", icon: "🚗", description: "EVs, Energy, Robotics", minInvestment: 1000, riskLevel: .extreme, baseReturn: 0.18, volatility: 0.65, phaseUnlock: .careerLeverage),
    
    // Other Major Stocks
    Investment(id: "brk", name: "Berkshire Hathaway", icon: "🏛️", description: "Warren Buffett's empire", minInvestment: 5000, riskLevel: .low, baseReturn: 0.09, volatility: 0.18, phaseUnlock: .careerLeverage),
    Investment(id: "jpm", name: "JPMorgan Chase", icon: "🏦", description: "Largest US bank", minInvestment: 1000, riskLevel: .medium, baseReturn: 0.08, volatility: 0.25, phaseUnlock: .careerLeverage),
    Investment(id: "v", name: "Visa (V)", icon: "💳", description: "Global payments network", minInvestment: 1000, riskLevel: .low, baseReturn: 0.09, volatility: 0.20, phaseUnlock: .careerLeverage),
    
    // Crypto (HIGH risk, HIGH volatility, moderate expected returns)
    Investment(id: "btc", name: "Bitcoin (BTC)", icon: "₿", description: "Digital gold, store of value", minInvestment: 500, riskLevel: .extreme, baseReturn: 0.25, volatility: 0.75, phaseUnlock: .careerLeverage),
    Investment(id: "eth", name: "Ethereum (ETH)", icon: "⟠", description: "Smart contracts, DeFi", minInvestment: 500, riskLevel: .extreme, baseReturn: 0.22, volatility: 0.80, phaseUnlock: .careerLeverage),
    Investment(id: "sol", name: "Solana (SOL)", icon: "◎", description: "Fast blockchain, NFTs", minInvestment: 250, riskLevel: .extreme, baseReturn: 0.28, volatility: 0.90, phaseUnlock: .careerLeverage),
    
    // Real Estate
    Investment(id: "rental", name: "Rental Property", icon: "🏠", description: "Monthly cash flow", minInvestment: 50_000, riskLevel: .medium, baseReturn: 0.08, volatility: 0.12, phaseUnlock: .careerLeverage),
    
    // ═══════════════════════════════════════════════════════════════
    // PHASE 3 - PORTFOLIO ENGINE (Larger investments)
    // ═══════════════════════════════════════════════════════════════
    
    // Private Tech Companies (Pre-IPO) - risky but higher potential
    Investment(id: "openai", name: "OpenAI (Private)", icon: "🤖", description: "ChatGPT, AGI research", minInvestment: 100_000, riskLevel: .extreme, baseReturn: 0.35, volatility: 0.90, phaseUnlock: .portfolioEngine),
    Investment(id: "spacex", name: "SpaceX (Private)", icon: "🚀", description: "Rockets, Starlink, Mars", minInvestment: 250_000, riskLevel: .high, baseReturn: 0.20, volatility: 0.50, phaseUnlock: .portfolioEngine),
    Investment(id: "stripe", name: "Stripe (Private)", icon: "💵", description: "Online payments platform", minInvestment: 100_000, riskLevel: .medium, baseReturn: 0.14, volatility: 0.35, phaseUnlock: .portfolioEngine),
    Investment(id: "anthropic", name: "Anthropic (Private)", icon: "🧠", description: "Claude AI, AI safety", minInvestment: 100_000, riskLevel: .extreme, baseReturn: 0.30, volatility: 0.85, phaseUnlock: .portfolioEngine),
    
    // Commercial Real Estate
    Investment(id: "commercial", name: "Commercial Building", icon: "🏢", description: "Office/retail property", minInvestment: 500_000, riskLevel: .medium, baseReturn: 0.09, volatility: 0.18, phaseUnlock: .portfolioEngine),
    Investment(id: "apartment", name: "Apartment Complex", icon: "🏗️", description: "Multi-family housing", minInvestment: 1_000_000, riskLevel: .medium, baseReturn: 0.10, volatility: 0.15, phaseUnlock: .portfolioEngine),
    
    // Fixed Income
    Investment(id: "corp_bonds", name: "Corporate Bonds", icon: "📜", description: "Investment grade debt", minInvestment: 25_000, riskLevel: .low, baseReturn: 0.055, volatility: 0.08, phaseUnlock: .portfolioEngine),
    
    // Alternative
    Investment(id: "art", name: "Fine Art Collection", icon: "🎨", description: "Masterpiece investments", minInvestment: 100_000, riskLevel: .medium, baseReturn: 0.06, volatility: 0.25, phaseUnlock: .portfolioEngine),
    Investment(id: "wine", name: "Wine Collection", icon: "🍷", description: "Rare vintage wines", minInvestment: 50_000, riskLevel: .medium, baseReturn: 0.07, volatility: 0.20, phaseUnlock: .portfolioEngine),
    
    // ═══════════════════════════════════════════════════════════════
    // PHASE 4 - LEGACY & SCALE (Institutional level)
    // ═══════════════════════════════════════════════════════════════
    
    // Funds
    Investment(id: "hedge_fund", name: "Hedge Fund", icon: "🎯", description: "Sophisticated strategies", minInvestment: 1_000_000, riskLevel: .high, baseReturn: 0.12, volatility: 0.35, phaseUnlock: .legacyScale),
    Investment(id: "pe_fund", name: "Private Equity Fund", icon: "🦈", description: "Buy and optimize companies", minInvestment: 5_000_000, riskLevel: .high, baseReturn: 0.15, volatility: 0.30, phaseUnlock: .legacyScale),
    Investment(id: "vc_fund", name: "Venture Capital Fund", icon: "💡", description: "Fund early-stage startups", minInvestment: 10_000_000, riskLevel: .extreme, baseReturn: 0.20, volatility: 0.70, phaseUnlock: .legacyScale),
    
    // Trophy Assets
    Investment(id: "sports_team", name: "Sports Team Stake", icon: "🏈", description: "Pro sports franchise", minInvestment: 50_000_000, riskLevel: .medium, baseReturn: 0.10, volatility: 0.20, phaseUnlock: .legacyScale),
    Investment(id: "media_company", name: "Media Company", icon: "📺", description: "Entertainment empire", minInvestment: 100_000_000, riskLevel: .high, baseReturn: 0.12, volatility: 0.40, phaseUnlock: .legacyScale),
    Investment(id: "island", name: "Private Island", icon: "🏝️", description: "Exclusive real estate", minInvestment: 25_000_000, riskLevel: .medium, baseReturn: 0.04, volatility: 0.15, phaseUnlock: .legacyScale),
    
    // Mega Investments
    Investment(id: "infrastructure", name: "Infrastructure Project", icon: "🌉", description: "Bridges, roads, utilities", minInvestment: 500_000_000, riskLevel: .low, baseReturn: 0.065, volatility: 0.10, phaseUnlock: .legacyScale),
    Investment(id: "space_venture", name: "Space Venture", icon: "🛸", description: "Asteroid mining, colonies", minInvestment: 1_000_000_000, riskLevel: .extreme, baseReturn: 0.25, volatility: 0.90, phaseUnlock: .legacyScale)
]

// MARK: - Opportunity Cards
struct OpportunityCard: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let cost: Double
    let successChance: Double // 0.0 to 1.0
    let successReward: Double
    let failurePenalty: Double
    let statusBonus: Int
    let phaseAvailable: GamePhase
    
    // Life of Wealth additions
    var factionRequired: Faction? = nil
    var factionReputationRequired: Int = 0
    var wealthImpact: WealthImpact = WealthImpact()
    var energyCost: Int = 20  // Default energy cost for opportunities
}

let opportunityDeck: [OpportunityCard] = [
    // Phase 1
    OpportunityCard(id: "freelance_gig", title: "Freelance Opportunity", description: "A client needs quick work done", icon: "💻", cost: 0, successChance: 0.8, successReward: 500, failurePenalty: 0, statusBonus: 2, phaseAvailable: .hustle),
    OpportunityCard(id: "garage_sale", title: "Garage Sale Flip", description: "Found vintage items to resell", icon: "🏷️", cost: 200, successChance: 0.7, successReward: 800, failurePenalty: 200, statusBonus: 1, phaseAvailable: .hustle),
    OpportunityCard(id: "skill_course", title: "Online Course", description: "Learn a valuable skill", icon: "📚", cost: 500, successChance: 0.9, successReward: 2000, failurePenalty: 500, statusBonus: 5, phaseAvailable: .hustle),
    
    // Phase 2
    OpportunityCard(id: "job_offer", title: "Job Offer", description: "A recruiter reached out", icon: "📧", cost: 0, successChance: 0.6, successReward: 15000, failurePenalty: 0, statusBonus: 20, phaseAvailable: .careerLeverage),
    OpportunityCard(id: "networking_event", title: "Networking Event", description: "Meet industry leaders", icon: "🤝", cost: 1000, successChance: 0.75, successReward: 10000, failurePenalty: 1000, statusBonus: 30, phaseAvailable: .careerLeverage),
    OpportunityCard(id: "stock_tip", title: "Hot Stock Tip", description: "Insider info? Or a scam?", icon: "🎰", cost: 5000, successChance: 0.4, successReward: 25000, failurePenalty: 5000, statusBonus: 10, phaseAvailable: .careerLeverage),
    
    // Phase 3
    OpportunityCard(id: "acquisition", title: "Acquisition Target", description: "A competitor is for sale", icon: "🏢", cost: 500000, successChance: 0.65, successReward: 2000000, failurePenalty: 500000, statusBonus: 100, phaseAvailable: .portfolioEngine),
    OpportunityCard(id: "patent", title: "Patent Opportunity", description: "License a breakthrough technology", icon: "💡", cost: 100000, successChance: 0.5, successReward: 1000000, failurePenalty: 100000, statusBonus: 75, phaseAvailable: .portfolioEngine),
    OpportunityCard(id: "media_feature", title: "Media Feature", description: "Forbes wants to profile you", icon: "📰", cost: 50000, successChance: 0.8, successReward: 500000, failurePenalty: 50000, statusBonus: 150, phaseAvailable: .portfolioEngine),
    
    // Phase 4
    OpportunityCard(id: "ipo", title: "IPO Opportunity", description: "Take a company public", icon: "🔔", cost: 10000000, successChance: 0.55, successReward: 100000000, failurePenalty: 10000000, statusBonus: 500, phaseAvailable: .legacyScale),
    OpportunityCard(id: "global_expansion", title: "Global Expansion", description: "Enter new markets worldwide", icon: "🌍", cost: 50000000, successChance: 0.6, successReward: 300000000, failurePenalty: 50000000, statusBonus: 1000, phaseAvailable: .legacyScale),
    OpportunityCard(id: "presidential_meeting", title: "Presidential Meeting", description: "The President wants your advice", icon: "🏛️", cost: 0, successChance: 0.9, successReward: 10000000, failurePenalty: 0, statusBonus: 5000, phaseAvailable: .legacyScale)
]

// MARK: - Upgrades
struct Upgrade: Identifiable, Codable {
    let id: String
    let name: String
    let icon: String
    let description: String
    let cost: Double
    let effect: UpgradeEffect
    let category: UpgradeCategory
    let phaseUnlock: GamePhase
    var purchased: Bool = false
    
    enum UpgradeCategory: String, Codable, CaseIterable {
        case skills = "Skills"
        case tools = "Tools"
        case network = "Network"
        case lifestyle = "Lifestyle"
    }
    
    enum UpgradeEffect: Codable {
        case tapMultiplier(Double)
        case passiveIncome(Double)
        case investmentBonus(Double)
        case statusBonus(Int)
        case opportunityBonus(Double)
    }
}

let allUpgrades: [Upgrade] = [
    // Phase 1 Skills
    Upgrade(id: "typing", name: "Speed Typing", icon: "⌨️", description: "+10% tap value", cost: 500, effect: .tapMultiplier(0.1), category: .skills, phaseUnlock: .hustle),
    Upgrade(id: "excel", name: "Excel Mastery", icon: "📊", description: "+$5/sec passive income", cost: 2000, effect: .passiveIncome(5), category: .skills, phaseUnlock: .hustle),
    Upgrade(id: "networking_101", name: "Networking 101", icon: "🤝", description: "+5% opportunity success", cost: 3000, effect: .opportunityBonus(0.05), category: .skills, phaseUnlock: .hustle),
    
    // Phase 1 Tools
    Upgrade(id: "laptop", name: "Better Laptop", icon: "💻", description: "+15% tap value", cost: 1500, effect: .tapMultiplier(0.15), category: .tools, phaseUnlock: .hustle),
    Upgrade(id: "desk_setup", name: "Pro Desk Setup", icon: "🖥️", description: "+$10/sec passive", cost: 5000, effect: .passiveIncome(10), category: .tools, phaseUnlock: .hustle),
    
    // Phase 2 Skills
    Upgrade(id: "negotiation", name: "Negotiation Skills", icon: "💬", description: "+20% tap value", cost: 15000, effect: .tapMultiplier(0.2), category: .skills, phaseUnlock: .careerLeverage),
    Upgrade(id: "investing_101", name: "Investment Course", icon: "📈", description: "+5% investment returns", cost: 25000, effect: .investmentBonus(0.05), category: .skills, phaseUnlock: .careerLeverage),
    Upgrade(id: "leadership", name: "Leadership Training", icon: "👔", description: "+50 status points", cost: 50000, effect: .statusBonus(50), category: .skills, phaseUnlock: .careerLeverage),
    
    // Phase 2 Network
    Upgrade(id: "mentor", name: "Find a Mentor", icon: "🧑‍🏫", description: "+10% opportunity success", cost: 20000, effect: .opportunityBonus(0.10), category: .network, phaseUnlock: .careerLeverage),
    Upgrade(id: "mastermind", name: "Mastermind Group", icon: "🧠", description: "+$100/sec passive", cost: 75000, effect: .passiveIncome(100), category: .network, phaseUnlock: .careerLeverage),
    
    // Phase 3 Tools
    Upgrade(id: "team", name: "Hire a Team", icon: "👥", description: "+$500/sec passive", cost: 500000, effect: .passiveIncome(500), category: .tools, phaseUnlock: .portfolioEngine),
    Upgrade(id: "automation", name: "Business Automation", icon: "🤖", description: "+50% tap value", cost: 750000, effect: .tapMultiplier(0.5), category: .tools, phaseUnlock: .portfolioEngine),
    Upgrade(id: "advisors", name: "Financial Advisors", icon: "📋", description: "+10% investment returns", cost: 1000000, effect: .investmentBonus(0.10), category: .tools, phaseUnlock: .portfolioEngine),
    
    // Phase 3 Lifestyle
    Upgrade(id: "luxury_car", name: "Luxury Car", icon: "🏎️", description: "+100 status points", cost: 200000, effect: .statusBonus(100), category: .lifestyle, phaseUnlock: .portfolioEngine),
    Upgrade(id: "penthouse", name: "Penthouse", icon: "🏙️", description: "+$1000/sec passive", cost: 5000000, effect: .passiveIncome(1000), category: .lifestyle, phaseUnlock: .portfolioEngine),
    
    // Phase 4
    Upgrade(id: "private_jet", name: "Private Jet", icon: "✈️", description: "+500 status points", cost: 25000000, effect: .statusBonus(500), category: .lifestyle, phaseUnlock: .legacyScale),
    Upgrade(id: "yacht", name: "Super Yacht", icon: "🛥️", description: "+$10,000/sec passive", cost: 100000000, effect: .passiveIncome(10000), category: .lifestyle, phaseUnlock: .legacyScale),
    Upgrade(id: "foundation", name: "Charitable Foundation", icon: "❤️", description: "+2000 status, +20% opportunity", cost: 50000000, effect: .statusBonus(2000), category: .network, phaseUnlock: .legacyScale),
    Upgrade(id: "world_tour", name: "World Influence Tour", icon: "🌐", description: "+100% tap value", cost: 500000000, effect: .tapMultiplier(1.0), category: .network, phaseUnlock: .legacyScale)
]

// MARK: - Product Launch
struct Product: Identifiable, Codable {
    let id: String
    let name: String
    let icon: String
    let description: String
    let developmentCost: Double
    let marketingCost: Double
    let successChance: Double
    let revenueOnSuccess: Double
    let ongoingRevenue: Double // Per second if successful
    var launched: Bool = false
    var successful: Bool = false
}

let productCatalog: [Product] = [
    Product(id: "app", name: "Mobile App", icon: "📱", description: "Build and launch an app", developmentCost: 50000, marketingCost: 25000, successChance: 0.4, revenueOnSuccess: 500000, ongoingRevenue: 100),
    Product(id: "saas", name: "SaaS Platform", icon: "☁️", description: "Software as a service", developmentCost: 200000, marketingCost: 100000, successChance: 0.35, revenueOnSuccess: 2000000, ongoingRevenue: 500),
    Product(id: "ecommerce", name: "E-Commerce Brand", icon: "🛒", description: "Direct-to-consumer products", developmentCost: 100000, marketingCost: 200000, successChance: 0.45, revenueOnSuccess: 1000000, ongoingRevenue: 300),
    Product(id: "course", name: "Online Course Empire", icon: "🎓", description: "Teach what you know", developmentCost: 25000, marketingCost: 50000, successChance: 0.5, revenueOnSuccess: 300000, ongoingRevenue: 150),
    Product(id: "hardware", name: "Hardware Startup", icon: "🔌", description: "Physical tech product", developmentCost: 1000000, marketingCost: 500000, successChance: 0.25, revenueOnSuccess: 10000000, ongoingRevenue: 2000),
    Product(id: "media", name: "Media Company", icon: "🎬", description: "Content and entertainment", developmentCost: 500000, marketingCost: 1000000, successChance: 0.3, revenueOnSuccess: 5000000, ongoingRevenue: 1500)
]

// MARK: - Housing
enum HousingStatus: String, Codable {
    case renting = "Renting"
    case ownsHome = "Homeowner"
    case ownsMultiple = "Real Estate Investor"
    case estateLiving = "Estate Living"
}

struct Housing: Codable {
    var status: HousingStatus = .renting
    var monthlyPayment: Double = 1500 // Rent or mortgage
    var propertyValue: Double = 0
    var equity: Double = 0
    var mortgageBalance: Double = 0
}

// MARK: - Meeting Contacts
struct MeetingContact: Identifiable, Codable {
    let id: String
    let name: String
    let title: String
    let icon: String
    let statusRequired: Int
    let phaseRequired: GamePhase
    let bonusOnMeet: Double
    var hasMet: Bool = false
    
    // Career-specific contacts - nil means available to all careers
    var careerPath: CareerPath? = nil
    
    // Life of Wealth additions
    var factionRequired: Faction? = nil
    var factionReputationRequired: Int = 0
    var wealthImpact: WealthImpact = WealthImpact(relationships: 5)  // Default relationship boost
    var energyCost: Int = 15  // Default energy cost for meetings
    
    // Risk level for investments - some contacts are risky (can lose you money!)
    var isRiskyInvestment: Bool = false
    var riskDescription: String? = nil
    
    // Rivalry System - contacts who become hostile if you meet this person first
    var rivals: [String] = []  // IDs of contacts who will be angry if you meet this person
    var allies: [String] = []  // IDs of contacts who give bonus if you already met this person
    var investmentBoost: [String] = []  // Investment IDs that get boosted after meeting
    var investmentPenalty: [String] = []  // Investment IDs that get penalized if rivalry triggered
}

// MARK: - Rivalry Consequence
struct RivalryConsequence {
    let rivalId: String
    let rivalName: String
    let lawsuitChance: Double  // 0.0 to 1.0
    let lawsuitDamage: Double  // Percentage of net worth
    let reputationDamage: Int  // Status points lost
    let investmentPenalty: Double  // Multiplier for affected investments (e.g., 0.8 = -20%)
    let newsHeadline: String
}

// MARK: - Contact Rivalry Map
struct ContactRivalrySystem {
    
    // Define rivalries between major tech/business figures
    // Key = contact being met, Value = consequences based on who you've already met
    static let rivalries: [String: [RivalryConsequence]] = [
        // Sam Altman has multiple rivals (Elon AND Demis)
        "sam_altman": [
            RivalryConsequence(
                rivalId: "elon",
                rivalName: "Elon Musk",
                lawsuitChance: 0.6,
                lawsuitDamage: 0.05,
                reputationDamage: 500,
                investmentPenalty: 0.85,
                newsHeadline: "Musk FURIOUS over your OpenAI alliance! Lawsuit incoming..."
            ),
            RivalryConsequence(
                rivalId: "demis_hassabis",
                rivalName: "Demis Hassabis",
                lawsuitChance: 0.25,
                lawsuitDamage: 0.02,
                reputationDamage: 150,
                investmentPenalty: 0.93,
                newsHeadline: "Google suspicious of your OpenAI ties"
            )
        ],
        // Elon has rivals with Sam and also with Tim Cook
        "elon": [
            RivalryConsequence(
                rivalId: "sam_altman",
                rivalName: "Sam Altman",
                lawsuitChance: 0.5,
                lawsuitDamage: 0.03,
                reputationDamage: 300,
                investmentPenalty: 0.90,
                newsHeadline: "OpenAI distances itself after your Musk meeting"
            ),
            RivalryConsequence(
                rivalId: "timcook",
                rivalName: "Tim Cook",
                lawsuitChance: 0.15,
                lawsuitDamage: 0.01,
                reputationDamage: 75,
                investmentPenalty: 0.96,
                newsHeadline: "Apple executives side-eye your Tesla connection"
            )
        ],
        // Demis Hassabis (DeepMind/Google) vs Sam Altman (OpenAI)
        "demis_hassabis": [
            RivalryConsequence(
                rivalId: "sam_altman",
                rivalName: "Sam Altman",
                lawsuitChance: 0.3,
                lawsuitDamage: 0.02,
                reputationDamage: 200,
                investmentPenalty: 0.92,
                newsHeadline: "OpenAI questions your loyalty after DeepMind meeting"
            ),
            RivalryConsequence(
                rivalId: "elon",
                rivalName: "Elon Musk",
                lawsuitChance: 0.2,
                lawsuitDamage: 0.015,
                reputationDamage: 100,
                investmentPenalty: 0.94,
                newsHeadline: "xAI concerned about your Google AI alliance"
            )
        ],
        // Tim Cook vs Elon (Apple vs Tesla rivalry)
        "timcook": [
            RivalryConsequence(
                rivalId: "elon",
                rivalName: "Elon Musk",
                lawsuitChance: 0.2,
                lawsuitDamage: 0.01,
                reputationDamage: 100,
                investmentPenalty: 0.95,
                newsHeadline: "Tesla insiders unhappy about your Apple connection"
            )
        ],
        // Warren Buffett hates crypto/speculation - penalizes your crypto holdings!
        "warren_buffett": [
            RivalryConsequence(
                rivalId: "elon",
                rivalName: "Elon Musk",
                lawsuitChance: 0.1,
                lawsuitDamage: 0.005,
                reputationDamage: 50,
                investmentPenalty: 0.97,
                newsHeadline: "Buffett disapproves of your 'speculative' connections"
            )
        ],
        // Jensen Huang (NVIDIA) competes with everyone in AI
        "jensen_huang": [
            RivalryConsequence(
                rivalId: "sam_altman",
                rivalName: "Sam Altman",
                lawsuitChance: 0.15,
                lawsuitDamage: 0.01,
                reputationDamage: 75,
                investmentPenalty: 0.95,
                newsHeadline: "OpenAI considering alternative chip suppliers after your NVIDIA meeting"
            ),
            RivalryConsequence(
                rivalId: "demis_hassabis",
                rivalName: "Demis Hassabis",
                lawsuitChance: 0.1,
                lawsuitDamage: 0.008,
                reputationDamage: 50,
                investmentPenalty: 0.96,
                newsHeadline: "Google TPU team not thrilled about your NVIDIA deal"
            )
        ],
        
        // ═══════════════════════════════════════════════════════════════
        // CREATOR/MEDIA RIVALRIES
        // ═══════════════════════════════════════════════════════════════
        
        // KANYE VS TAYLOR - The legendary feud
        "kanye": [
            RivalryConsequence(
                rivalId: "taylor_swift",
                rivalName: "Taylor Swift",
                lawsuitChance: 0.7,
                lawsuitDamage: 0.08,
                reputationDamage: 1000,
                investmentPenalty: 0.70,
                newsHeadline: "Swifties DESTROY your reputation after Kanye alliance"
            ),
            RivalryConsequence(
                rivalId: "kid_cudi",
                rivalName: "Kid Cudi",
                lawsuitChance: 0.3,
                lawsuitDamage: 0.02,
                reputationDamage: 200,
                investmentPenalty: 0.90,
                newsHeadline: "Kid Cudi distances himself after your Kanye connection"
            )
        ],
        "taylor_swift": [
            RivalryConsequence(
                rivalId: "kanye",
                rivalName: "Kanye West",
                lawsuitChance: 0.5,
                lawsuitDamage: 0.05,
                reputationDamage: 500,
                investmentPenalty: 0.80,
                newsHeadline: "Ye goes on X rant about your Taylor Swift meeting"
            ),
            RivalryConsequence(
                rivalId: "kim_k",
                rivalName: "Kim Kardashian",
                lawsuitChance: 0.2,
                lawsuitDamage: 0.02,
                reputationDamage: 150,
                investmentPenalty: 0.92,
                newsHeadline: "Kardashian camp not happy about your Taylor alliance"
            )
        ],
        
        // Drake vs Kanye (ongoing beef)
        "drake": [
            RivalryConsequence(
                rivalId: "kanye",
                rivalName: "Kanye West",
                lawsuitChance: 0.35,
                lawsuitDamage: 0.03,
                reputationDamage: 300,
                investmentPenalty: 0.88,
                newsHeadline: "Kanye drops diss track mentioning your Drake connection"
            )
        ],
        
        // David Dobrik controversy risk
        "david_dobrik": [
            RivalryConsequence(
                rivalId: "emma_chamberlain",
                rivalName: "Emma Chamberlain",
                lawsuitChance: 0.15,
                lawsuitDamage: 0.01,
                reputationDamage: 100,
                investmentPenalty: 0.95,
                newsHeadline: "Clean creator community questions your Dobrik association"
            )
        ],
        
        // ═══════════════════════════════════════════════════════════════
        // FINANCE RIVALRIES
        // ═══════════════════════════════════════════════════════════════
        
        // SBF is radioactive
        "sbf": [
            RivalryConsequence(
                rivalId: "cz",
                rivalName: "CZ",
                lawsuitChance: 0.9,
                lawsuitDamage: 0.15,
                reputationDamage: 2000,
                investmentPenalty: 0.50,
                newsHeadline: "SEC investigating your FTX connections"
            ),
            RivalryConsequence(
                rivalId: "vitalik",
                rivalName: "Vitalik Buterin",
                lawsuitChance: 0.6,
                lawsuitDamage: 0.10,
                reputationDamage: 1500,
                investmentPenalty: 0.60,
                newsHeadline: "Crypto community shuns you after SBF meeting"
            )
        ],
        
        // Cathie Wood vs traditional finance
        "cathie_wood": [
            RivalryConsequence(
                rivalId: "warren_buffett",
                rivalName: "Warren Buffett",
                lawsuitChance: 0.1,
                lawsuitDamage: 0.01,
                reputationDamage: 100,
                investmentPenalty: 0.95,
                newsHeadline: "Value investors question your ARK alliance"
            )
        ],
        
        // ═══════════════════════════════════════════════════════════════
        // TRADES RIVALRIES
        // ═══════════════════════════════════════════════════════════════
        
        // Grant Cardone polarizes
        "grant_cardone": [
            RivalryConsequence(
                rivalId: "barbara_corcoran",
                rivalName: "Barbara Corcoran",
                lawsuitChance: 0.2,
                lawsuitDamage: 0.02,
                reputationDamage: 150,
                investmentPenalty: 0.93,
                newsHeadline: "Shark Tank investors skeptical of your 10X associations"
            )
        ]
    ]
    
    // Define alliances (meeting person A first gives bonus when meeting person B)
    static let alliances: [String: [String: Double]] = [
        // If you meet Satya first, meeting Tim Cook gives extra bonus (corporate alliance)
        "satya": ["timcook": 1.5, "sundar": 1.3],
        "timcook": ["satya": 1.5, "jamie_dimon": 1.2],
        // If you meet Warren Buffett first, meeting Jamie Dimon is better (old money network)
        "warren_buffett": ["jamie_dimon": 2.0, "ray_dalio": 1.8],
        "ray_dalio": ["warren_buffett": 1.8, "jamie_dimon": 1.5],
        // AI alliance (if you're in the AI crowd, they help each other... sometimes)
        "jensen_huang": ["demis_hassabis": 1.3],
        
        // ═══════════════════════════════════════════════════════════════
        // PODCAST PROGRESSION - Build your media presence strategically
        // ═══════════════════════════════════════════════════════════════
        
        // Local podcasts unlock industry podcasts
        "podcast_local": ["podcast_industry": 1.3, "podcast_tbpn": 1.2],
        "podcast_industry": ["podcast_tbpn": 1.3, "podcast_starter": 1.2],
        
        // Mid-tier builds to major
        "podcast_tbpn": ["podcast_mfm": 1.4, "podcast_doac": 1.3],
        "podcast_starter": ["podcast_mfm": 1.5, "podcast_indie": 1.3],
        "podcast_indie": ["podcast_mfm": 1.4, "podcast_allIn": 1.3],
        
        // Major podcasts unlock top-tier
        "podcast_mfm": ["podcast_allIn": 1.5, "podcast_lex": 1.4, "podcast_huberman": 1.3],
        "podcast_allIn": ["podcast_lex": 1.6, "podcast_rogan": 1.3],
        "podcast_doac": ["podcast_huberman": 1.5, "podcast_rogan": 1.2],
        
        // Top-tier podcasts boost tech titans
        "podcast_lex": ["elon": 1.5, "sam_altman": 1.4, "jensen_huang": 1.3],
        "podcast_huberman": ["timcook": 1.3, "satya": 1.2],
        "podcast_rogan": ["elon": 2.0, "mrBeast": 1.5, "president": 1.3],  // Rogan = Elon access
        
        // ═══════════════════════════════════════════════════════════════
        // CREATOR/MEDIA ALLIANCES
        // ═══════════════════════════════════════════════════════════════
        
        // YouTube/Social Media progression
        "logan_paul": ["the_rock": 1.4, "mrBeast": 1.3, "kim_k": 1.2],
        "mrBeast": ["logan_paul": 1.3, "emma_chamberlain": 1.2],
        "emma_chamberlain": ["charli_damelio": 1.3, "zendaya": 1.2],
        
        // Hollywood connections
        "talent_agent": ["margot_robbie": 1.5, "brad_pitt": 1.4, "timothee_chalamet": 1.4],
        "margot_robbie": ["brad_pitt": 1.4, "timothee_chalamet": 1.3],
        "timothee_chalamet": ["zendaya": 1.5, "kid_cudi": 1.3],  // Dune connection
        "zendaya": ["timothee_chalamet": 1.5, "taylor_swift": 1.2],
        
        // Music industry
        "kid_cudi": ["kanye": 1.5, "drake": 1.2, "timothee_chalamet": 1.3],
        "drake": ["rihanna": 1.4, "kid_cudi": 1.2],
        "rihanna": ["drake": 1.3, "oprah": 1.4, "kim_k": 1.3],
        "taylor_swift": ["oprah": 1.5, "zendaya": 1.3],
        
        // Media moguls
        "kim_k": ["oprah": 1.3, "rihanna": 1.3],
        "oprah": ["taylor_swift": 1.4, "brad_pitt": 1.3, "the_rock": 1.3],
        
        // ═══════════════════════════════════════════════════════════════
        // FINANCE ALLIANCES
        // ═══════════════════════════════════════════════════════════════
        
        "analyst": ["trader": 1.3, "quant": 1.2],
        "trader": ["fund_manager": 1.4],
        "fund_manager": ["pe_partner": 1.3, "bill_ackman": 1.2],
        "vitalik": ["cz": 1.3],
        "bill_ackman": ["carl_icahn": 1.4, "warren_buffett": 1.3],
        "cathie_wood": ["vitalik": 1.3, "elon": 1.2],
        "larry_fink": ["jamie_dimon": 1.5, "ray_dalio": 1.4, "warren_buffett": 1.3],
        
        // ═══════════════════════════════════════════════════════════════
        // TECH ALLIANCES
        // ═══════════════════════════════════════════════════════════════
        
        "senior_eng": ["pm_tech": 1.2, "startup_cto": 1.3],
        "startup_cto": ["yc_partner": 1.4],
        "yc_partner": ["pg": 1.6, "a16z_partner": 1.3],
        "a16z_partner": ["marc_andreessen": 1.5, "sequoia_partner": 1.3],
        "pg": ["reid_hoffman": 1.4, "peter_thiel": 1.3],
        "marc_andreessen": ["peter_thiel": 1.4, "reid_hoffman": 1.3, "elon": 1.2],
        "peter_thiel": ["elon": 1.5, "marc_andreessen": 1.3],  // PayPal Mafia
        "reid_hoffman": ["satya": 1.3, "pg": 1.3],  // LinkedIn -> Microsoft
        
        // ═══════════════════════════════════════════════════════════════
        // TRADES ALLIANCES
        // ═══════════════════════════════════════════════════════════════
        
        "foreman": ["contractor": 1.3],
        "contractor": ["union_rep": 1.2, "developer": 1.4],
        "developer": ["barbara_corcoran": 1.4, "grant_cardone": 1.3],
        "franchise_owner": ["marcus_lemonis": 1.5],
        "barbara_corcoran": ["marcus_lemonis": 1.3, "grant_cardone": 1.2],
    ]
    
    // Investment effects - meeting certain people boosts specific investments
    static let investmentEffects: [String: (boost: [String], penalty: [String])] = [
        "timcook": (boost: ["aapl"], penalty: []),
        "satya": (boost: ["msft"], penalty: []),
        "sundar": (boost: ["googl"], penalty: []),
        "elon": (boost: ["tsla", "spacex"], penalty: ["openai"]),
        "sam_altman": (boost: ["openai"], penalty: ["tsla", "spacex"]),
        "jensen_huang": (boost: ["nvda"], penalty: []),
        "warren_buffett": (boost: ["brk"], penalty: ["btc", "eth", "sol"]),  // Buffett hates crypto
        "demis_hassabis": (boost: ["googl", "anthropic"], penalty: []),
    ]
    
    /// Check if meeting this contact will trigger any rivalries
    static func checkRivalries(contactId: String, metContacts: [String]) -> [RivalryConsequence] {
        var consequences: [RivalryConsequence] = []
        
        // Check if any contacts the player has already met are rivals of this new contact
        for metId in metContacts {
            if let rivalries = rivalries[contactId] {
                for rivalry in rivalries {
                    if rivalry.rivalId == metId {
                        consequences.append(rivalry)
                    }
                }
            }
        }
        
        // Also check reverse - does this contact have rivals among met contacts?
        for metId in metContacts {
            if let theirRivalries = rivalries[metId] {
                for rivalry in theirRivalries {
                    if rivalry.rivalId == contactId {
                        // The person you already met is now angry
                        let reverseConsequence = RivalryConsequence(
                            rivalId: metId,
                            rivalName: "", // Will be filled in by caller
                            lawsuitChance: rivalry.lawsuitChance * 0.5,  // Lower chance for reverse
                            lawsuitDamage: rivalry.lawsuitDamage * 0.5,
                            reputationDamage: rivalry.reputationDamage / 2,
                            investmentPenalty: rivalry.investmentPenalty,
                            newsHeadline: "Your old ally feels betrayed by new connection..."
                        )
                        consequences.append(reverseConsequence)
                    }
                }
            }
        }
        
        return consequences
    }
    
    /// Get alliance bonus multiplier for meeting this contact
    static func getAllianceBonus(contactId: String, metContacts: [String]) -> Double {
        var totalBonus = 1.0
        
        for metId in metContacts {
            if let theirAlliances = alliances[metId], let bonus = theirAlliances[contactId] {
                totalBonus *= bonus
            }
        }
        
        return totalBonus
    }
}

let allContacts: [MeetingContact] = [
    // Phase 1 - Early Career (modest bonuses)
    MeetingContact(id: "pm1", name: "Sarah Chen", title: "Project Manager", icon: "👩‍💼", statusRequired: 10, phaseRequired: .hustle, bonusOnMeet: 500),
    MeetingContact(id: "lead1", name: "Mike Johnson", title: "Team Lead", icon: "👨‍💼", statusRequired: 25, phaseRequired: .hustle, bonusOnMeet: 1000),
    MeetingContact(id: "manager1", name: "Lisa Park", title: "Department Manager", icon: "👩‍💻", statusRequired: 50, phaseRequired: .hustle, bonusOnMeet: 2500),
    
    // Phase 2 - Corporate Ladder
    MeetingContact(id: "director1", name: "James Williams", title: "Director", icon: "🧑‍💼", statusRequired: 100, phaseRequired: .careerLeverage, bonusOnMeet: 5000),
    MeetingContact(id: "vp1", name: "Amanda Foster", title: "VP of Operations", icon: "👔", statusRequired: 200, phaseRequired: .careerLeverage, bonusOnMeet: 15000),
    MeetingContact(id: "cfo1", name: "Robert Kim", title: "CFO", icon: "💼", statusRequired: 400, phaseRequired: .careerLeverage, bonusOnMeet: 50000),
    
    // ═══════════════════════════════════════════════════════════════
    // PODCAST APPEARANCES - Build your way up!
    // ═══════════════════════════════════════════════════════════════
    
    // Local/Niche Podcasts (Phase 2)
    MeetingContact(id: "podcast_local", name: "Local Business Podcast", title: "Regional exposure", icon: "🎙️", statusRequired: 150, phaseRequired: .careerLeverage, bonusOnMeet: 3000),
    MeetingContact(id: "podcast_industry", name: "Industry Newsletter", title: "Niche credibility", icon: "📰", statusRequired: 300, phaseRequired: .careerLeverage, bonusOnMeet: 8000),
    
    // Mid-Tier Podcasts (Phase 3)
    MeetingContact(id: "podcast_tbpn", name: "The Business Podcast Network", title: "Growing audience", icon: "🎧", statusRequired: 600, phaseRequired: .portfolioEngine, bonusOnMeet: 25000),
    MeetingContact(id: "podcast_starter", name: "Starter Story", title: "Entrepreneur community", icon: "🚀", statusRequired: 900, phaseRequired: .portfolioEngine, bonusOnMeet: 40000),
    MeetingContact(id: "podcast_indie", name: "Indie Hackers", title: "Bootstrapper cred", icon: "💻", statusRequired: 1200, phaseRequired: .portfolioEngine, bonusOnMeet: 60000),
    
    // Major Podcasts (Phase 3-4)
    MeetingContact(id: "podcast_mfm", name: "My First Million", title: "Sam & Shaan's show", icon: "💰", statusRequired: 2000, phaseRequired: .portfolioEngine, bonusOnMeet: 150000, factionRequired: .startup, factionReputationRequired: 30),
    MeetingContact(id: "podcast_allIn", name: "All-In Podcast", title: "The Besties", icon: "🎲", statusRequired: 4000, phaseRequired: .portfolioEngine, bonusOnMeet: 300000, factionRequired: .startup, factionReputationRequired: 45),
    MeetingContact(id: "podcast_doac", name: "Diary of a CEO", title: "Steven Bartlett", icon: "📖", statusRequired: 3500, phaseRequired: .portfolioEngine, bonusOnMeet: 250000, factionRequired: .creator, factionReputationRequired: 40),
    
    // Top-Tier Podcasts (Phase 4)
    MeetingContact(id: "podcast_lex", name: "Lex Fridman Podcast", title: "3-hour deep dive", icon: "🤖", statusRequired: 6000, phaseRequired: .legacyScale, bonusOnMeet: 500000, factionRequired: .startup, factionReputationRequired: 55),
    MeetingContact(id: "podcast_huberman", name: "Huberman Lab", title: "Science credibility", icon: "🧠", statusRequired: 5500, phaseRequired: .legacyScale, bonusOnMeet: 400000, factionRequired: .corporate, factionReputationRequired: 50),
    MeetingContact(id: "podcast_rogan", name: "Joe Rogan Experience", title: "The biggest platform", icon: "🎤", statusRequired: 10000, phaseRequired: .legacyScale, bonusOnMeet: 1000000, factionRequired: .creator, factionReputationRequired: 70),
    
    // ═══════════════════════════════════════════════════════════════
    // INDUSTRY PLAYERS (Phase 3)
    // ═══════════════════════════════════════════════════════════════
    
    MeetingContact(id: "ceo1", name: "Victoria Hayes", title: "Fortune 500 CEO", icon: "👑", statusRequired: 800, phaseRequired: .portfolioEngine, bonusOnMeet: 75000),
    MeetingContact(id: "investor1", name: "Marcus Reid", title: "Venture Capitalist", icon: "💰", statusRequired: 1500, phaseRequired: .portfolioEngine, bonusOnMeet: 150000),
    MeetingContact(id: "celebrity1", name: "Celebrity Connection", title: "A-List Celebrity", icon: "⭐", statusRequired: 3000, phaseRequired: .portfolioEngine, bonusOnMeet: 300000),
    
    // ═══════════════════════════════════════════════════════════════
    // TECH TITANS (Phase 4) - REDUCED bonuses, strategic value
    // ═══════════════════════════════════════════════════════════════
    
    MeetingContact(id: "timcook", name: "Tim Cook", title: "Apple CEO", icon: "🍎", statusRequired: 7000, phaseRequired: .legacyScale, bonusOnMeet: 500000, factionRequired: .corporate, factionReputationRequired: 55),
    MeetingContact(id: "satya", name: "Satya Nadella", title: "Microsoft CEO", icon: "🪟", statusRequired: 7500, phaseRequired: .legacyScale, bonusOnMeet: 600000, factionRequired: .corporate, factionReputationRequired: 55),
    MeetingContact(id: "sundar", name: "Sundar Pichai", title: "Google CEO", icon: "🔍", statusRequired: 8000, phaseRequired: .legacyScale, bonusOnMeet: 700000, factionRequired: .startup, factionReputationRequired: 55),
    
    // AI Visionaries (Strategic value, but rivalries!)
    MeetingContact(id: "sam_altman", name: "Sam Altman", title: "OpenAI CEO", icon: "🤖", statusRequired: 12000, phaseRequired: .legacyScale, bonusOnMeet: 800000, factionRequired: .startup, factionReputationRequired: 65),
    MeetingContact(id: "demis_hassabis", name: "Demis Hassabis", title: "DeepMind CEO", icon: "🧠", statusRequired: 13000, phaseRequired: .legacyScale, bonusOnMeet: 900000, factionRequired: .startup, factionReputationRequired: 70),
    MeetingContact(id: "jensen_huang", name: "Jensen Huang", title: "NVIDIA CEO", icon: "🎮", statusRequired: 14000, phaseRequired: .legacyScale, bonusOnMeet: 1000000, factionRequired: .startup, factionReputationRequired: 65),
    
    // Elon & Mars (High value but HIGH RISK - many rivalries)
    MeetingContact(id: "elon", name: "Elon Musk", title: "Tesla/SpaceX/xAI", icon: "🚀", statusRequired: 20000, phaseRequired: .legacyScale, bonusOnMeet: 2000000, factionRequired: .startup, factionReputationRequired: 80),
    
    // Finance Titans (Old money network - safer, alliances)
    MeetingContact(id: "warren_buffett", name: "Warren Buffett", title: "Berkshire Hathaway", icon: "📈", statusRequired: 15000, phaseRequired: .legacyScale, bonusOnMeet: 1500000, factionRequired: .oldMoney, factionReputationRequired: 75),
    MeetingContact(id: "jamie_dimon", name: "Jamie Dimon", title: "JPMorgan Chase CEO", icon: "🏦", statusRequired: 12000, phaseRequired: .legacyScale, bonusOnMeet: 1000000, factionRequired: .corporate, factionReputationRequired: 70),
    MeetingContact(id: "ray_dalio", name: "Ray Dalio", title: "Bridgewater Founder", icon: "🌊", statusRequired: 16000, phaseRequired: .legacyScale, bonusOnMeet: 1200000, factionRequired: .oldMoney, factionReputationRequired: 75),
    
    // Creator Economy (General)
    MeetingContact(id: "mrBeast", name: "MrBeast", title: "YouTube Mogul", icon: "📱", statusRequired: 10000, phaseRequired: .legacyScale, bonusOnMeet: 800000, factionRequired: .creator, factionReputationRequired: 65),
    
    // Political Power (Very high risk - everyone has an opinion)
    MeetingContact(id: "president", name: "The President", title: "Leader of the Free World", icon: "🏛️", statusRequired: 50000, phaseRequired: .legacyScale, bonusOnMeet: 5000000),
    
    // ═══════════════════════════════════════════════════════════════
    // CREATOR/MEDIA CAREER PATH - YouTubers, Influencers, Hollywood
    // ═══════════════════════════════════════════════════════════════
    
    // Phase 2 - Starting Out in Media
    MeetingContact(id: "local_influencer", name: "Local Influencer", title: "10K followers", icon: "📸", statusRequired: 100, phaseRequired: .careerLeverage, bonusOnMeet: 3000, careerPath: .creator),
    MeetingContact(id: "podcast_host", name: "Podcast Host", title: "Growing show", icon: "🎙️", statusRequired: 200, phaseRequired: .careerLeverage, bonusOnMeet: 8000, careerPath: .creator),
    MeetingContact(id: "talent_agent", name: "Talent Agent", title: "Hollywood connections", icon: "🎬", statusRequired: 350, phaseRequired: .careerLeverage, bonusOnMeet: 20000, careerPath: .creator),
    
    // Phase 3 - Mid-Tier Creators (Mixed bag - some risky!)
    MeetingContact(id: "david_dobrik", name: "David Dobrik", title: "Vlog Squad", icon: "📹", statusRequired: 800, phaseRequired: .portfolioEngine, bonusOnMeet: 50000, careerPath: .creator, isRiskyInvestment: true, riskDescription: "Controversy history - could damage your brand"),
    MeetingContact(id: "emma_chamberlain", name: "Emma Chamberlain", title: "Coffee & Content", icon: "☕", statusRequired: 900, phaseRequired: .portfolioEngine, bonusOnMeet: 80000, careerPath: .creator),
    MeetingContact(id: "charli_damelio", name: "Charli D'Amelio", title: "TikTok Star", icon: "💃", statusRequired: 1000, phaseRequired: .portfolioEngine, bonusOnMeet: 70000, careerPath: .creator),
    MeetingContact(id: "khaby_lame", name: "Khaby Lame", title: "Silent Comedy King", icon: "🤷", statusRequired: 1200, phaseRequired: .portfolioEngine, bonusOnMeet: 100000, careerPath: .creator),
    
    // Phase 3-4 - Wrestling/Sports Entertainment
    MeetingContact(id: "logan_paul", name: "Logan Paul", title: "PRIME & WWE", icon: "🥊", statusRequired: 2000, phaseRequired: .portfolioEngine, bonusOnMeet: 200000, careerPath: .creator),
    MeetingContact(id: "the_rock", name: "Dwayne Johnson", title: "The Rock", icon: "💪", statusRequired: 5000, phaseRequired: .legacyScale, bonusOnMeet: 600000, careerPath: .creator, factionRequired: .creator, factionReputationRequired: 50),
    
    // Phase 4 - A-List Hollywood
    MeetingContact(id: "margot_robbie", name: "Margot Robbie", title: "Hollywood A-List", icon: "🌟", statusRequired: 8000, phaseRequired: .legacyScale, bonusOnMeet: 500000, careerPath: .creator, factionRequired: .creator, factionReputationRequired: 55),
    MeetingContact(id: "brad_pitt", name: "Brad Pitt", title: "Hollywood Legend", icon: "🎭", statusRequired: 10000, phaseRequired: .legacyScale, bonusOnMeet: 700000, careerPath: .creator, factionRequired: .creator, factionReputationRequired: 60),
    MeetingContact(id: "timothee_chalamet", name: "Timothée Chalamet", title: "Gen Z Icon", icon: "🎬", statusRequired: 7000, phaseRequired: .legacyScale, bonusOnMeet: 450000, careerPath: .creator, factionRequired: .creator, factionReputationRequired: 50),
    MeetingContact(id: "zendaya", name: "Zendaya", title: "Multi-Hyphenate Star", icon: "✨", statusRequired: 7500, phaseRequired: .legacyScale, bonusOnMeet: 500000, careerPath: .creator, factionRequired: .creator, factionReputationRequired: 52),
    
    // Phase 4 - Music Industry
    MeetingContact(id: "kid_cudi", name: "Kid Cudi", title: "Artist & Visionary", icon: "🌙", statusRequired: 6000, phaseRequired: .legacyScale, bonusOnMeet: 400000, careerPath: .creator, factionRequired: .creator, factionReputationRequired: 45),
    MeetingContact(id: "kanye", name: "Kanye West", title: "Ye", icon: "🐻", statusRequired: 9000, phaseRequired: .legacyScale, bonusOnMeet: 300000, careerPath: .creator, factionRequired: .creator, factionReputationRequired: 60, isRiskyInvestment: true, riskDescription: "EXTREMELY unpredictable - could 10x or destroy you"),
    MeetingContact(id: "taylor_swift", name: "Taylor Swift", title: "Music Industry Titan", icon: "🎤", statusRequired: 15000, phaseRequired: .legacyScale, bonusOnMeet: 1500000, careerPath: .creator, factionRequired: .creator, factionReputationRequired: 75),
    MeetingContact(id: "drake", name: "Drake", title: "OVO Sound", icon: "🦉", statusRequired: 11000, phaseRequired: .legacyScale, bonusOnMeet: 900000, careerPath: .creator, factionRequired: .creator, factionReputationRequired: 65),
    MeetingContact(id: "rihanna", name: "Rihanna", title: "Fenty Empire", icon: "💎", statusRequired: 12000, phaseRequired: .legacyScale, bonusOnMeet: 1000000, careerPath: .creator, factionRequired: .creator, factionReputationRequired: 70),
    
    // Phase 4 - Media Moguls
    MeetingContact(id: "oprah", name: "Oprah Winfrey", title: "Media Mogul", icon: "👑", statusRequired: 18000, phaseRequired: .legacyScale, bonusOnMeet: 1200000, careerPath: .creator, factionRequired: .creator, factionReputationRequired: 80),
    MeetingContact(id: "kim_k", name: "Kim Kardashian", title: "Reality & Business", icon: "💄", statusRequired: 8000, phaseRequired: .legacyScale, bonusOnMeet: 600000, careerPath: .creator, factionRequired: .creator, factionReputationRequired: 55),
    
    // ═══════════════════════════════════════════════════════════════
    // FINANCE CAREER PATH - Wall Street, Hedge Funds, Crypto
    // ═══════════════════════════════════════════════════════════════
    
    // Phase 2 - Starting in Finance
    MeetingContact(id: "analyst", name: "Senior Analyst", title: "Goldman Sachs", icon: "📊", statusRequired: 100, phaseRequired: .careerLeverage, bonusOnMeet: 5000, careerPath: .finance),
    MeetingContact(id: "trader", name: "Floor Trader", title: "NYSE Veteran", icon: "📈", statusRequired: 250, phaseRequired: .careerLeverage, bonusOnMeet: 12000, careerPath: .finance),
    MeetingContact(id: "quant", name: "Quant Developer", title: "Algorithmic Trading", icon: "🔢", statusRequired: 400, phaseRequired: .careerLeverage, bonusOnMeet: 25000, careerPath: .finance),
    
    // Phase 3 - Finance Mid-Career
    MeetingContact(id: "fund_manager", name: "Fund Manager", title: "Manages $500M", icon: "💹", statusRequired: 800, phaseRequired: .portfolioEngine, bonusOnMeet: 80000, careerPath: .finance),
    MeetingContact(id: "pe_partner", name: "PE Partner", title: "Private Equity", icon: "🦈", statusRequired: 1500, phaseRequired: .portfolioEngine, bonusOnMeet: 150000, careerPath: .finance),
    
    // Phase 3-4 - Crypto/DeFi
    MeetingContact(id: "sbf", name: "Sam Bankman-Fried", title: "Former FTX", icon: "💀", statusRequired: 500, phaseRequired: .portfolioEngine, bonusOnMeet: -100000, careerPath: .finance, isRiskyInvestment: true, riskDescription: "AVOID - Convicted fraud"),
    MeetingContact(id: "cz", name: "CZ (Changpeng Zhao)", title: "Binance Founder", icon: "🔶", statusRequired: 3000, phaseRequired: .portfolioEngine, bonusOnMeet: 200000, careerPath: .finance, isRiskyInvestment: true, riskDescription: "Regulatory risk - proceed with caution"),
    MeetingContact(id: "vitalik", name: "Vitalik Buterin", title: "Ethereum Creator", icon: "⟠", statusRequired: 4000, phaseRequired: .legacyScale, bonusOnMeet: 400000, careerPath: .finance, factionRequired: .startup, factionReputationRequired: 50),
    
    // Phase 4 - Finance Legends
    MeetingContact(id: "carl_icahn", name: "Carl Icahn", title: "Activist Investor", icon: "🦅", statusRequired: 12000, phaseRequired: .legacyScale, bonusOnMeet: 800000, careerPath: .finance, factionRequired: .oldMoney, factionReputationRequired: 65),
    MeetingContact(id: "bill_ackman", name: "Bill Ackman", title: "Pershing Square", icon: "🎯", statusRequired: 10000, phaseRequired: .legacyScale, bonusOnMeet: 700000, careerPath: .finance, factionRequired: .oldMoney, factionReputationRequired: 60),
    MeetingContact(id: "cathie_wood", name: "Cathie Wood", title: "ARK Invest", icon: "🚀", statusRequired: 6000, phaseRequired: .legacyScale, bonusOnMeet: 350000, careerPath: .finance, factionRequired: .startup, factionReputationRequired: 45),
    MeetingContact(id: "larry_fink", name: "Larry Fink", title: "BlackRock CEO", icon: "⬛", statusRequired: 15000, phaseRequired: .legacyScale, bonusOnMeet: 1000000, careerPath: .finance, factionRequired: .corporate, factionReputationRequired: 75),
    
    // ═══════════════════════════════════════════════════════════════
    // TECH CAREER PATH - Startups, Engineers, VCs
    // ═══════════════════════════════════════════════════════════════
    
    // Phase 2 - Starting in Tech
    MeetingContact(id: "senior_eng", name: "Senior Engineer", title: "FAANG Veteran", icon: "👨‍💻", statusRequired: 100, phaseRequired: .careerLeverage, bonusOnMeet: 4000, careerPath: .tech),
    MeetingContact(id: "pm_tech", name: "Product Manager", title: "Shipped 10M+ users", icon: "📋", statusRequired: 200, phaseRequired: .careerLeverage, bonusOnMeet: 8000, careerPath: .tech),
    MeetingContact(id: "startup_cto", name: "Startup CTO", title: "Series A Company", icon: "🛠️", statusRequired: 350, phaseRequired: .careerLeverage, bonusOnMeet: 15000, careerPath: .tech),
    
    // Phase 3 - Tech Mid-Career
    MeetingContact(id: "yc_partner", name: "YC Partner", title: "Y Combinator", icon: "🟠", statusRequired: 800, phaseRequired: .portfolioEngine, bonusOnMeet: 100000, careerPath: .tech, factionRequired: .startup, factionReputationRequired: 35),
    MeetingContact(id: "a16z_partner", name: "a16z Partner", title: "Andreessen Horowitz", icon: "🅰️", statusRequired: 1200, phaseRequired: .portfolioEngine, bonusOnMeet: 180000, careerPath: .tech, factionRequired: .startup, factionReputationRequired: 45),
    MeetingContact(id: "sequoia_partner", name: "Sequoia Partner", title: "Legendary VC", icon: "🌲", statusRequired: 1500, phaseRequired: .portfolioEngine, bonusOnMeet: 220000, careerPath: .tech, factionRequired: .startup, factionReputationRequired: 50),
    
    // Phase 4 - Tech Legends
    MeetingContact(id: "pg", name: "Paul Graham", title: "YC Founder", icon: "📝", statusRequired: 6000, phaseRequired: .legacyScale, bonusOnMeet: 450000, careerPath: .tech, factionRequired: .startup, factionReputationRequired: 55),
    MeetingContact(id: "marc_andreessen", name: "Marc Andreessen", title: "a16z Co-Founder", icon: "🥚", statusRequired: 8000, phaseRequired: .legacyScale, bonusOnMeet: 600000, careerPath: .tech, factionRequired: .startup, factionReputationRequired: 60),
    MeetingContact(id: "peter_thiel", name: "Peter Thiel", title: "PayPal Mafia", icon: "♟️", statusRequired: 10000, phaseRequired: .legacyScale, bonusOnMeet: 750000, careerPath: .tech, factionRequired: .startup, factionReputationRequired: 65),
    MeetingContact(id: "reid_hoffman", name: "Reid Hoffman", title: "LinkedIn Founder", icon: "🔗", statusRequired: 7000, phaseRequired: .legacyScale, bonusOnMeet: 500000, careerPath: .tech, factionRequired: .startup, factionReputationRequired: 55),
    
    // ═══════════════════════════════════════════════════════════════
    // TRADES CAREER PATH - Construction, Real Estate, Skilled Labor
    // ═══════════════════════════════════════════════════════════════
    
    // Phase 2 - Starting in Trades
    MeetingContact(id: "foreman", name: "Site Foreman", title: "25 years experience", icon: "👷", statusRequired: 100, phaseRequired: .careerLeverage, bonusOnMeet: 3000, careerPath: .trades),
    MeetingContact(id: "contractor", name: "General Contractor", title: "Licensed & Bonded", icon: "🏗️", statusRequired: 200, phaseRequired: .careerLeverage, bonusOnMeet: 8000, careerPath: .trades),
    MeetingContact(id: "union_rep", name: "Union Representative", title: "Labor connections", icon: "✊", statusRequired: 350, phaseRequired: .careerLeverage, bonusOnMeet: 12000, careerPath: .trades),
    
    // Phase 3 - Trades Mid-Career
    MeetingContact(id: "developer", name: "Real Estate Developer", title: "Builds neighborhoods", icon: "🏘️", statusRequired: 800, phaseRequired: .portfolioEngine, bonusOnMeet: 80000, careerPath: .trades),
    MeetingContact(id: "fleet_owner", name: "Fleet Owner", title: "50+ trucks", icon: "🚛", statusRequired: 600, phaseRequired: .portfolioEngine, bonusOnMeet: 50000, careerPath: .trades),
    MeetingContact(id: "franchise_owner", name: "Franchise Owner", title: "Multi-unit operator", icon: "🍔", statusRequired: 1000, phaseRequired: .portfolioEngine, bonusOnMeet: 100000, careerPath: .trades),
    
    // Phase 4 - Trades Moguls
    MeetingContact(id: "barbara_corcoran", name: "Barbara Corcoran", title: "Real Estate Shark", icon: "🦈", statusRequired: 5000, phaseRequired: .legacyScale, bonusOnMeet: 350000, careerPath: .trades, factionRequired: .oldMoney, factionReputationRequired: 45),
    MeetingContact(id: "marcus_lemonis", name: "Marcus Lemonis", title: "The Profit", icon: "💼", statusRequired: 6000, phaseRequired: .legacyScale, bonusOnMeet: 400000, careerPath: .trades, factionRequired: .corporate, factionReputationRequired: 50),
    MeetingContact(id: "grant_cardone", name: "Grant Cardone", title: "Real Estate Empire", icon: "🏢", statusRequired: 4000, phaseRequired: .portfolioEngine, bonusOnMeet: 250000, careerPath: .trades, isRiskyInvestment: true, riskDescription: "Aggressive tactics - polarizing")
]

// MARK: - Auto-Tapper System
struct AutoTapper: Identifiable, Codable {
    let id: String
    let name: String
    let icon: String
    let description: String
    let baseTapsPerSecond: Double
    let baseCost: Double
    let phaseUnlock: GamePhase
    var level: Int = 0
    var owned: Bool = false
    
    var currentTapsPerSecond: Double {
        owned ? baseTapsPerSecond * Double(1 + level) : 0
    }
    
    var upgradeCost: Double {
        baseCost * pow(1.5, Double(level))
    }
    
    var nextLevelTapsPerSecond: Double {
        baseTapsPerSecond * Double(2 + level)
    }
}

let allAutoTappers: [AutoTapper] = [
    AutoTapper(
        id: "buddy",
        name: "Recruit a Buddy",
        icon: "🤝",
        description: "Your friend helps out - taps every 3 sec",
        baseTapsPerSecond: 0.33,
        baseCost: 100,
        phaseUnlock: .hustle
    ),
    AutoTapper(
        id: "intern",
        name: "Hire an Intern",
        icon: "👨‍💼",
        description: "Eager college student taps for you",
        baseTapsPerSecond: 1,
        baseCost: 1000,
        phaseUnlock: .hustle
    ),
    AutoTapper(
        id: "va",
        name: "Virtual Assistant",
        icon: "💻",
        description: "Remote worker handles your tapping",
        baseTapsPerSecond: 5,
        baseCost: 10000,
        phaseUnlock: .hustle
    ),
    AutoTapper(
        id: "ai_bot",
        name: "AI Bot",
        icon: "🤖",
        description: "Machine learning optimizes your taps",
        baseTapsPerSecond: 25,
        baseCost: 100000,
        phaseUnlock: .careerLeverage
    ),
    AutoTapper(
        id: "tap_army",
        name: "Tap Army",
        icon: "👥",
        description: "An entire team dedicated to tapping",
        baseTapsPerSecond: 100,
        baseCost: 1000000,
        phaseUnlock: .portfolioEngine
    ),
    AutoTapper(
        id: "tap_factory",
        name: "Tap Factory",
        icon: "🏭",
        description: "Industrial-scale automated tapping",
        baseTapsPerSecond: 500,
        baseCost: 10000000,
        phaseUnlock: .portfolioEngine
    ),
    AutoTapper(
        id: "quantum_tapper",
        name: "Quantum Tapper",
        icon: "⚛️",
        description: "Taps in multiple dimensions simultaneously",
        baseTapsPerSecond: 2500,
        baseCost: 100000000,
        phaseUnlock: .legacyScale
    )
]
