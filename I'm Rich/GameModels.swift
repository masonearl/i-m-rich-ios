//
//  GameModels.swift
//  I'm Rich
//
//  Multi-phase wealth strategy game models
//

import SwiftUI

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
        switch self {
        case .hustle: return 0
        case .careerLeverage: return 10_000
        case .portfolioEngine: return 1_000_000
        case .legacyScale: return 100_000_000
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
    
    var expectedReturn: Double {
        amountInvested * baseReturn
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
    // Phase 1 - Hustle
    Investment(id: "savings", name: "Savings Account", icon: "🏦", description: "Safe but slow", minInvestment: 100, riskLevel: .low, baseReturn: 0.02, volatility: 0.0, phaseUnlock: .hustle),
    Investment(id: "index_fund", name: "Index Fund", icon: "📊", description: "Steady market returns", minInvestment: 500, riskLevel: .low, baseReturn: 0.08, volatility: 0.15, phaseUnlock: .hustle),
    Investment(id: "side_gig", name: "Side Gig Equipment", icon: "🛠️", description: "Invest in tools for extra income", minInvestment: 1000, riskLevel: .medium, baseReturn: 0.25, volatility: 0.3, phaseUnlock: .hustle),
    
    // Phase 2 - Career & Leverage
    Investment(id: "stocks", name: "Individual Stocks", icon: "📈", description: "Pick winners, risk losers", minInvestment: 1000, riskLevel: .medium, baseReturn: 0.12, volatility: 0.35, phaseUnlock: .careerLeverage),
    Investment(id: "crypto", name: "Cryptocurrency", icon: "₿", description: "High risk, high reward", minInvestment: 500, riskLevel: .extreme, baseReturn: 0.40, volatility: 0.80, phaseUnlock: .careerLeverage),
    Investment(id: "rental", name: "Rental Property", icon: "🏠", description: "Steady cash flow", minInvestment: 50_000, riskLevel: .medium, baseReturn: 0.10, volatility: 0.15, phaseUnlock: .careerLeverage),
    
    // Phase 3 - Portfolio Engine
    Investment(id: "startup", name: "Startup Investment", icon: "🚀", description: "Fund the next unicorn", minInvestment: 25_000, riskLevel: .extreme, baseReturn: 0.50, volatility: 0.90, phaseUnlock: .portfolioEngine),
    Investment(id: "commercial", name: "Commercial Real Estate", icon: "🏢", description: "Office and retail properties", minInvestment: 500_000, riskLevel: .medium, baseReturn: 0.12, volatility: 0.20, phaseUnlock: .portfolioEngine),
    Investment(id: "bonds", name: "Corporate Bonds", icon: "📜", description: "Stable fixed income", minInvestment: 10_000, riskLevel: .low, baseReturn: 0.05, volatility: 0.05, phaseUnlock: .portfolioEngine),
    Investment(id: "business", name: "Own a Business", icon: "💼", description: "Build something real", minInvestment: 100_000, riskLevel: .high, baseReturn: 0.30, volatility: 0.50, phaseUnlock: .portfolioEngine),
    
    // Phase 4 - Legacy & Scale
    Investment(id: "hedge_fund", name: "Hedge Fund", icon: "🎯", description: "Sophisticated strategies", minInvestment: 1_000_000, riskLevel: .high, baseReturn: 0.18, volatility: 0.40, phaseUnlock: .legacyScale),
    Investment(id: "private_equity", name: "Private Equity", icon: "🦈", description: "Buy and optimize companies", minInvestment: 5_000_000, riskLevel: .high, baseReturn: 0.22, volatility: 0.35, phaseUnlock: .legacyScale),
    Investment(id: "venture_fund", name: "Venture Capital Fund", icon: "💡", description: "Fund many startups", minInvestment: 10_000_000, riskLevel: .extreme, baseReturn: 0.35, volatility: 0.70, phaseUnlock: .legacyScale),
    Investment(id: "global_brand", name: "Global Brand", icon: "🌐", description: "Build a worldwide empire", minInvestment: 50_000_000, riskLevel: .high, baseReturn: 0.25, volatility: 0.40, phaseUnlock: .legacyScale)
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
}

let allContacts: [MeetingContact] = [
    // Phase 1
    MeetingContact(id: "pm1", name: "Sarah Chen", title: "Project Manager", icon: "👩‍💼", statusRequired: 10, phaseRequired: .hustle, bonusOnMeet: 1000),
    MeetingContact(id: "lead1", name: "Mike Johnson", title: "Team Lead", icon: "👨‍💼", statusRequired: 25, phaseRequired: .hustle, bonusOnMeet: 2500),
    MeetingContact(id: "manager1", name: "Lisa Park", title: "Department Manager", icon: "👩‍💻", statusRequired: 50, phaseRequired: .hustle, bonusOnMeet: 5000),
    
    // Phase 2
    MeetingContact(id: "director1", name: "James Williams", title: "Director", icon: "🧑‍💼", statusRequired: 100, phaseRequired: .careerLeverage, bonusOnMeet: 15000),
    MeetingContact(id: "vp1", name: "Amanda Foster", title: "VP of Operations", icon: "👔", statusRequired: 200, phaseRequired: .careerLeverage, bonusOnMeet: 50000),
    MeetingContact(id: "cfo1", name: "Robert Kim", title: "CFO", icon: "💼", statusRequired: 400, phaseRequired: .careerLeverage, bonusOnMeet: 100000),
    
    // Phase 3
    MeetingContact(id: "ceo1", name: "Victoria Hayes", title: "Fortune 500 CEO", icon: "👑", statusRequired: 800, phaseRequired: .portfolioEngine, bonusOnMeet: 500000),
    MeetingContact(id: "investor1", name: "Marcus Reid", title: "Venture Capitalist", icon: "💰", statusRequired: 1500, phaseRequired: .portfolioEngine, bonusOnMeet: 1000000),
    MeetingContact(id: "celebrity1", name: "Celebrity Connection", title: "A-List Celebrity", icon: "⭐", statusRequired: 3000, phaseRequired: .portfolioEngine, bonusOnMeet: 2500000),
    
    // Phase 4
    MeetingContact(id: "timcook", name: "Tim Cook", title: "Apple CEO", icon: "🍎", statusRequired: 5000, phaseRequired: .legacyScale, bonusOnMeet: 10000000),
    MeetingContact(id: "elon", name: "Elon Musk", title: "Tech Visionary", icon: "🚀", statusRequired: 10000, phaseRequired: .legacyScale, bonusOnMeet: 25000000),
    MeetingContact(id: "president", name: "The President", title: "Leader of the Free World", icon: "🏛️", statusRequired: 25000, phaseRequired: .legacyScale, bonusOnMeet: 100000000)
]
