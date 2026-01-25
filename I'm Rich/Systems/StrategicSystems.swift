//
//  StrategicSystems.swift
//  I'm Rich
//
//  Deep strategic systems: Economic cycles, research tree, strategic events,
//  competitors, and synergy bonuses for meaningful gameplay depth.
//

import SwiftUI
import Combine

// MARK: - ═══════════════════════════════════════════════════════════════
// ECONOMIC CYCLE SYSTEM
// 4-phase cycles (Expansion → Peak → Contraction → Trough) that players
// can learn to predict and exploit. Each cycle lasts ~4-6 game years.
// ═══════════════════════════════════════════════════════════════════════

enum EconomicPhase: String, Codable, CaseIterable {
    case expansion = "Expansion"
    case peak = "Peak"
    case contraction = "Contraction"
    case trough = "Trough"
    
    var icon: String {
        switch self {
        case .expansion: return "📈"
        case .peak: return "🔝"
        case .contraction: return "📉"
        case .trough: return "🕳️"
        }
    }
    
    var color: Color {
        switch self {
        case .expansion: return .green
        case .peak: return .yellow
        case .contraction: return .orange
        case .trough: return .red
        }
    }
    
    var description: String {
        switch self {
        case .expansion: return "Economy growing - good time to invest & expand"
        case .peak: return "Market at highs - consider taking profits"
        case .contraction: return "Economy slowing - protect your assets"
        case .trough: return "Market bottomed - buy opportunities cheap"
        }
    }
    
    // Investment multiplier during this phase
    var investmentMultiplier: Double {
        switch self {
        case .expansion: return 1.3   // +30% returns
        case .peak: return 1.1        // +10% returns
        case .contraction: return 0.7 // -30% returns
        case .trough: return 0.5      // -50% returns (but buy low!)
        }
    }
    
    // Hiring cost multiplier (labor market)
    var hiringCostMultiplier: Double {
        switch self {
        case .expansion: return 1.4   // Expensive to hire during boom
        case .peak: return 1.5        // Very expensive at peak
        case .contraction: return 1.0 // Normal costs
        case .trough: return 0.6      // Cheap talent available
        }
    }
    
    // Opportunity frequency multiplier
    var opportunityMultiplier: Double {
        switch self {
        case .expansion: return 1.5   // More opportunities
        case .peak: return 1.2        // Still good
        case .contraction: return 0.7 // Fewer deals
        case .trough: return 0.5      // Very few, but cheap
        }
    }
    
    // Sale/revenue multiplier
    var revenueMultiplier: Double {
        switch self {
        case .expansion: return 1.2
        case .peak: return 1.0        // Demand softens at peak
        case .contraction: return 0.8
        case .trough: return 0.6
        }
    }
    
    var nextPhase: EconomicPhase {
        switch self {
        case .expansion: return .peak
        case .peak: return .contraction
        case .contraction: return .trough
        case .trough: return .expansion
        }
    }
}

struct EconomicCycleState: Codable {
    var currentPhase: EconomicPhase = .expansion
    var yearsInCurrentPhase: Int = 0
    var cycleNumber: Int = 1
    var phaseDuration: Int = 2  // Years in this phase (randomized 1-3)
    var leadingIndicator: Double = 50  // 0-100, predicts phase changes
    var consumerConfidence: Double = 50
    var inflationRate: Double = 2.0  // Percentage
    var interestRate: Double = 5.0   // Fed rate percentage
}

class EconomicCycleManager: ObservableObject {
    static let shared = EconomicCycleManager()
    
    @Published var state: EconomicCycleState {
        didSet { save() }
    }
    
    @Published var showPhaseChangeAlert = false
    @Published var phaseChangeMessage: String = ""
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: "economicCycleState"),
           let decoded = try? JSONDecoder().decode(EconomicCycleState.self, from: data) {
            self.state = decoded
        } else {
            self.state = EconomicCycleState()
        }
    }
    
    // Called at year-end
    func processYear() -> Bool {
        state.yearsInCurrentPhase += 1
        updateIndicators()
        
        // Check for phase transition
        if state.yearsInCurrentPhase >= state.phaseDuration {
            transitionPhase()
            return true  // Phase changed
        }
        return false
    }
    
    private func updateIndicators() {
        // Leading indicator predicts upcoming phase changes
        // Rises during expansion, falls during contraction
        switch state.currentPhase {
        case .expansion:
            state.leadingIndicator = min(100, state.leadingIndicator + Double.random(in: 5...15))
            state.consumerConfidence = min(100, state.consumerConfidence + Double.random(in: 3...8))
            state.inflationRate = min(10, state.inflationRate + Double.random(in: 0.2...0.5))
        case .peak:
            state.leadingIndicator = 100 - Double.random(in: 5...20)  // Starting to fall
            state.consumerConfidence = max(60, state.consumerConfidence - Double.random(in: 0...5))
            state.inflationRate = max(0, state.inflationRate + Double.random(in: -0.2...0.3))
        case .contraction:
            state.leadingIndicator = max(0, state.leadingIndicator - Double.random(in: 10...20))
            state.consumerConfidence = max(20, state.consumerConfidence - Double.random(in: 5...12))
            state.inflationRate = max(-2, state.inflationRate - Double.random(in: 0.3...0.8))
        case .trough:
            state.leadingIndicator = min(40, state.leadingIndicator + Double.random(in: 2...8))  // Starting to rise
            state.consumerConfidence = min(50, state.consumerConfidence + Double.random(in: 1...5))
            state.inflationRate = max(-2, state.inflationRate - Double.random(in: 0...0.3))
        }
        
        // Fed adjusts rates based on inflation
        if state.inflationRate > 5 {
            state.interestRate = min(15, state.interestRate + 0.25)
        } else if state.inflationRate < 2 && state.currentPhase == .trough {
            state.interestRate = max(0, state.interestRate - 0.5)
        }
    }
    
    private func transitionPhase() {
        let oldPhase = state.currentPhase
        state.currentPhase = oldPhase.nextPhase
        state.yearsInCurrentPhase = 0
        state.phaseDuration = Int.random(in: 1...3)  // 1-3 years per phase
        
        if state.currentPhase == .expansion {
            state.cycleNumber += 1
        }
        
        // Notify player
        phaseChangeMessage = "Economy shifting: \(oldPhase.rawValue) → \(state.currentPhase.rawValue)"
        showPhaseChangeAlert = true
        
        NewsFeedManager.shared.addNews(
            category: .markets,
            headline: "\(state.currentPhase.icon) Economic cycle shift: \(state.currentPhase.rawValue) - \(state.currentPhase.description)"
        )
    }
    
    /// Strategic insight: Predict next phase based on indicators
    var phaseChangeLikelihood: Double {
        let progress = Double(state.yearsInCurrentPhase) / Double(state.phaseDuration)
        let indicatorPressure: Double
        
        switch state.currentPhase {
        case .expansion:
            indicatorPressure = state.leadingIndicator > 80 ? 0.3 : 0
        case .peak:
            indicatorPressure = state.leadingIndicator < 80 ? 0.4 : 0
        case .contraction:
            indicatorPressure = state.leadingIndicator < 30 ? 0.3 : 0
        case .trough:
            indicatorPressure = state.leadingIndicator > 30 ? 0.4 : 0
        }
        
        return min(1.0, progress * 0.7 + indicatorPressure)
    }
    
    var phaseChangePrediction: String {
        let likelihood = phaseChangeLikelihood
        if likelihood > 0.7 {
            return "Phase change imminent"
        } else if likelihood > 0.4 {
            return "Phase change likely soon"
        } else {
            return "Phase stable"
        }
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: "economicCycleState")
        }
    }
    
    func reset() {
        state = EconomicCycleState()
    }
}

// MARK: - ═══════════════════════════════════════════════════════════════
// RESEARCH / TECH TREE SYSTEM
// Permanent upgrades unlocked through strategic investment.
// Each branch has prerequisites and mutually exclusive choices.
// ═══════════════════════════════════════════════════════════════════════

enum ResearchBranch: String, Codable, CaseIterable {
    case automation = "Automation"
    case networking = "Networking"
    case finance = "Finance"
    case innovation = "Innovation"
    case influence = "Influence"
    
    var icon: String {
        switch self {
        case .automation: return "🤖"
        case .networking: return "🤝"
        case .finance: return "📊"
        case .innovation: return "💡"
        case .influence: return "👑"
        }
    }
    
    var color: Color {
        switch self {
        case .automation: return .cyan
        case .networking: return .purple
        case .finance: return .green
        case .innovation: return .orange
        case .influence: return .yellow
        }
    }
}

struct Research: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let branch: ResearchBranch
    let tier: Int  // 1-5, higher = more powerful & expensive
    let prerequisites: [String]  // IDs of required research
    let mutuallyExclusiveWith: [String]  // Can't have both
    let cost: Double
    let researchTime: Int  // Game years to complete
    var unlocked: Bool = false
    var inProgress: Bool = false
    var progressYears: Int = 0
    
    // Effects
    let tapMultiplier: Double  // Multiplier to tap value
    let investmentBonus: Double  // Flat bonus to investment returns
    let passiveIncomeMultiplier: Double  // Multiplier to passive income
    let opportunityBonus: Double  // Bonus success chance
    let specialEffect: String?  // Description of unique effect
}

let allResearch: [Research] = [
    // ═══════════════════════════════════════════════════════════════
    // AUTOMATION BRANCH - Passive income and efficiency
    // ═══════════════════════════════════════════════════════════════
    
    Research(id: "auto_1", name: "Process Optimization", description: "Streamline operations for +10% passive income", branch: .automation, tier: 1, prerequisites: [], mutuallyExclusiveWith: [], cost: 50_000, researchTime: 1, tapMultiplier: 1.0, investmentBonus: 0, passiveIncomeMultiplier: 1.1, opportunityBonus: 0, specialEffect: nil),
    
    Research(id: "auto_2a", name: "Robotic Assembly", description: "Automate production - +25% passive, -10% tap value", branch: .automation, tier: 2, prerequisites: ["auto_1"], mutuallyExclusiveWith: ["auto_2b"], cost: 200_000, researchTime: 2, tapMultiplier: 0.9, investmentBonus: 0, passiveIncomeMultiplier: 1.25, opportunityBonus: 0, specialEffect: "Products launch 20% faster"),
    
    Research(id: "auto_2b", name: "Efficiency Systems", description: "Optimize workflows - +15% passive, +15% tap value", branch: .automation, tier: 2, prerequisites: ["auto_1"], mutuallyExclusiveWith: ["auto_2a"], cost: 250_000, researchTime: 2, tapMultiplier: 1.15, investmentBonus: 0, passiveIncomeMultiplier: 1.15, opportunityBonus: 0, specialEffect: nil),
    
    Research(id: "auto_3", name: "AI Operations", description: "AI runs your business - +50% passive income", branch: .automation, tier: 3, prerequisites: ["auto_2a", "auto_2b"], mutuallyExclusiveWith: [], cost: 1_000_000, researchTime: 3, tapMultiplier: 1.0, investmentBonus: 0, passiveIncomeMultiplier: 1.5, opportunityBonus: 0.05, specialEffect: "Auto-tappers 25% more effective"),
    
    Research(id: "auto_4", name: "Full Automation", description: "Complete hands-off operation - passive income x2", branch: .automation, tier: 4, prerequisites: ["auto_3"], mutuallyExclusiveWith: [], cost: 10_000_000, researchTime: 4, tapMultiplier: 0.8, investmentBonus: 0.02, passiveIncomeMultiplier: 2.0, opportunityBonus: 0, specialEffect: "Sleep income: Earn while offline"),
    
    // ═══════════════════════════════════════════════════════════════
    // NETWORKING BRANCH - Contacts and status
    // ═══════════════════════════════════════════════════════════════
    
    Research(id: "net_1", name: "Social Capital", description: "Unlock +20 status per contact met", branch: .networking, tier: 1, prerequisites: [], mutuallyExclusiveWith: [], cost: 50_000, researchTime: 1, tapMultiplier: 1.0, investmentBonus: 0, passiveIncomeMultiplier: 1.0, opportunityBonus: 0, specialEffect: "+20 status per contact"),
    
    Research(id: "net_2a", name: "Inner Circle", description: "Fewer, deeper connections - contact bonuses +50%", branch: .networking, tier: 2, prerequisites: ["net_1"], mutuallyExclusiveWith: ["net_2b"], cost: 200_000, researchTime: 2, tapMultiplier: 1.0, investmentBonus: 0, passiveIncomeMultiplier: 1.0, opportunityBonus: 0, specialEffect: "Contact cash bonuses +50%, but 30% fewer contacts available"),
    
    Research(id: "net_2b", name: "Wide Network", description: "Know everyone - 50% more contacts unlocked", branch: .networking, tier: 2, prerequisites: ["net_1"], mutuallyExclusiveWith: ["net_2a"], cost: 180_000, researchTime: 2, tapMultiplier: 1.0, investmentBonus: 0, passiveIncomeMultiplier: 1.0, opportunityBonus: 0.05, specialEffect: "50% more contacts available at each status level"),
    
    Research(id: "net_3", name: "Power Broker", description: "Your network is your net worth", branch: .networking, tier: 3, prerequisites: ["net_2a", "net_2b"], mutuallyExclusiveWith: [], cost: 1_000_000, researchTime: 2, tapMultiplier: 1.0, investmentBonus: 0, passiveIncomeMultiplier: 1.0, opportunityBonus: 0.1, specialEffect: "Unlock 3 exclusive billionaire contacts"),
    
    Research(id: "net_4", name: "Kingmaker", description: "Shape industries through connections", branch: .networking, tier: 4, prerequisites: ["net_3"], mutuallyExclusiveWith: [], cost: 25_000_000, researchTime: 3, tapMultiplier: 1.0, investmentBonus: 0.05, passiveIncomeMultiplier: 1.0, opportunityBonus: 0.15, specialEffect: "Faction reputation gains doubled"),
    
    // ═══════════════════════════════════════════════════════════════
    // FINANCE BRANCH - Investments and wealth preservation
    // ═══════════════════════════════════════════════════════════════
    
    Research(id: "fin_1", name: "Market Analysis", description: "Better investment insights - +2% returns", branch: .finance, tier: 1, prerequisites: [], mutuallyExclusiveWith: [], cost: 75_000, researchTime: 1, tapMultiplier: 1.0, investmentBonus: 0.02, passiveIncomeMultiplier: 1.0, opportunityBonus: 0, specialEffect: nil),
    
    Research(id: "fin_2a", name: "Aggressive Growth", description: "High risk/reward - investment returns +5%, volatility +50%", branch: .finance, tier: 2, prerequisites: ["fin_1"], mutuallyExclusiveWith: ["fin_2b"], cost: 300_000, researchTime: 2, tapMultiplier: 1.0, investmentBonus: 0.05, passiveIncomeMultiplier: 1.0, opportunityBonus: 0, specialEffect: "Investments can lose 20% in crashes (but gain 40% in booms)"),
    
    Research(id: "fin_2b", name: "Value Investing", description: "Slow and steady - +3% returns, protected from crashes", branch: .finance, tier: 2, prerequisites: ["fin_1"], mutuallyExclusiveWith: ["fin_2a"], cost: 350_000, researchTime: 2, tapMultiplier: 1.0, investmentBonus: 0.03, passiveIncomeMultiplier: 1.0, opportunityBonus: 0, specialEffect: "Investments protected from market crash events"),
    
    Research(id: "fin_3", name: "Hedge Fund Strategies", description: "Profit in any market condition", branch: .finance, tier: 3, prerequisites: ["fin_2a", "fin_2b"], mutuallyExclusiveWith: [], cost: 5_000_000, researchTime: 3, tapMultiplier: 1.0, investmentBonus: 0.05, passiveIncomeMultiplier: 1.0, opportunityBonus: 0, specialEffect: "Earn +10% during economic contractions"),
    
    Research(id: "fin_4", name: "Wealth Preservation", description: "Generational wealth strategies", branch: .finance, tier: 4, prerequisites: ["fin_3"], mutuallyExclusiveWith: [], cost: 50_000_000, researchTime: 4, tapMultiplier: 1.0, investmentBonus: 0.08, passiveIncomeMultiplier: 1.0, opportunityBonus: 0, specialEffect: "15% of wealth carries through prestige (instead of 1%)"),
    
    // ═══════════════════════════════════════════════════════════════
    // INNOVATION BRANCH - Products and opportunities
    // ═══════════════════════════════════════════════════════════════
    
    Research(id: "inn_1", name: "R&D Focus", description: "Product success +15%", branch: .innovation, tier: 1, prerequisites: [], mutuallyExclusiveWith: [], cost: 60_000, researchTime: 1, tapMultiplier: 1.0, investmentBonus: 0, passiveIncomeMultiplier: 1.0, opportunityBonus: 0.15, specialEffect: nil),
    
    Research(id: "inn_2a", name: "Disruptive Innovation", description: "High risk products - 2x reward but 30% less success", branch: .innovation, tier: 2, prerequisites: ["inn_1"], mutuallyExclusiveWith: ["inn_2b"], cost: 250_000, researchTime: 2, tapMultiplier: 1.0, investmentBonus: 0, passiveIncomeMultiplier: 1.0, opportunityBonus: -0.1, specialEffect: "Product rewards doubled, success rate -30%"),
    
    Research(id: "inn_2b", name: "Incremental Innovation", description: "Safe products - 50% less reward but +25% success", branch: .innovation, tier: 2, prerequisites: ["inn_1"], mutuallyExclusiveWith: ["inn_2a"], cost: 200_000, researchTime: 2, tapMultiplier: 1.0, investmentBonus: 0, passiveIncomeMultiplier: 1.0, opportunityBonus: 0.25, specialEffect: "Products are safer but earn 50% less"),
    
    Research(id: "inn_3", name: "Innovation Engine", description: "Continuous product pipeline", branch: .innovation, tier: 3, prerequisites: ["inn_2a", "inn_2b"], mutuallyExclusiveWith: [], cost: 2_000_000, researchTime: 3, tapMultiplier: 1.0, investmentBonus: 0, passiveIncomeMultiplier: 1.2, opportunityBonus: 0.2, specialEffect: "Unlock 5 new product tiers"),
    
    Research(id: "inn_4", name: "Moonshot Factory", description: "World-changing innovation", branch: .innovation, tier: 4, prerequisites: ["inn_3"], mutuallyExclusiveWith: [], cost: 100_000_000, researchTime: 5, tapMultiplier: 1.0, investmentBonus: 0, passiveIncomeMultiplier: 1.0, opportunityBonus: 0.25, specialEffect: "Unlock legendary products with 10x rewards"),
    
    // ═══════════════════════════════════════════════════════════════
    // INFLUENCE BRANCH - Power and prestige
    // ═══════════════════════════════════════════════════════════════
    
    Research(id: "inf_1", name: "Media Presence", description: "Build your public profile - tap value +10%", branch: .influence, tier: 1, prerequisites: [], mutuallyExclusiveWith: [], cost: 40_000, researchTime: 1, tapMultiplier: 1.1, investmentBonus: 0, passiveIncomeMultiplier: 1.0, opportunityBonus: 0, specialEffect: nil),
    
    Research(id: "inf_2a", name: "Controversy Strategy", description: "Any press is good press - +30% tap, scandal risk", branch: .influence, tier: 2, prerequisites: ["inf_1"], mutuallyExclusiveWith: ["inf_2b"], cost: 150_000, researchTime: 1, tapMultiplier: 1.3, investmentBonus: 0, passiveIncomeMultiplier: 1.0, opportunityBonus: 0, specialEffect: "10% chance per year of reputation-damaging scandal"),
    
    Research(id: "inf_2b", name: "Quiet Power", description: "Work behind the scenes - +15% tap, +20% passive", branch: .influence, tier: 2, prerequisites: ["inf_1"], mutuallyExclusiveWith: ["inf_2a"], cost: 200_000, researchTime: 2, tapMultiplier: 1.15, investmentBonus: 0, passiveIncomeMultiplier: 1.2, opportunityBonus: 0, specialEffect: nil),
    
    Research(id: "inf_3", name: "Political Connections", description: "Access to power", branch: .influence, tier: 3, prerequisites: ["inf_2a", "inf_2b"], mutuallyExclusiveWith: [], cost: 5_000_000, researchTime: 3, tapMultiplier: 1.2, investmentBonus: 0, passiveIncomeMultiplier: 1.0, opportunityBonus: 0.1, specialEffect: "Reduce tax rate by 10%, unlock government contracts"),
    
    Research(id: "inf_4", name: "Legacy Builder", description: "Your name will live forever", branch: .influence, tier: 4, prerequisites: ["inf_3"], mutuallyExclusiveWith: [], cost: 500_000_000, researchTime: 5, tapMultiplier: 1.0, investmentBonus: 0, passiveIncomeMultiplier: 1.0, opportunityBonus: 0, specialEffect: "Prestige multiplier gains +50%, starting cash +25%"),
]

struct ResearchState: Codable {
    var unlockedIds: [String] = []
    var inProgressId: String? = nil
    var progressYears: Int = 0
}

class ResearchManager: ObservableObject {
    static let shared = ResearchManager()
    
    @Published var research: [Research] = allResearch
    @Published var state: ResearchState = ResearchState()
    @Published var showResearchComplete = false
    @Published var completedResearchName: String = ""
    
    private init() {
        // Load saved state
        if let data = UserDefaults.standard.data(forKey: "researchState"),
           let decoded = try? JSONDecoder().decode(ResearchState.self, from: data) {
            self.state = decoded
        }
        
        // Restore unlocked research
        for id in state.unlockedIds {
            if let index = research.firstIndex(where: { $0.id == id }) {
                research[index].unlocked = true
            }
        }
        
        // Restore in-progress research
        if let progressId = state.inProgressId,
           let index = research.firstIndex(where: { $0.id == progressId }) {
            research[index].inProgress = true
            research[index].progressYears = state.progressYears
        }
    }
    
    // MARK: - Research Actions
    
    func canStart(_ researchId: String) -> Bool {
        guard let r = research.first(where: { $0.id == researchId }) else { return false }
        guard !r.unlocked else { return false }
        guard state.inProgressId == nil else { return false }
        
        // Check prerequisites
        for prereq in r.prerequisites {
            if !state.unlockedIds.contains(prereq) && r.mutuallyExclusiveWith.isEmpty {
                // Need at least one prerequisite if they exist
                return false
            }
        }
        // Actually need ALL non-exclusive prereqs
        let requiredPrereqs = r.prerequisites.filter { prereqId in
            !r.mutuallyExclusiveWith.contains(prereqId)
        }
        for prereq in requiredPrereqs {
            if !state.unlockedIds.contains(prereq) {
                return false
            }
        }
        
        // Check mutual exclusivity
        for exclusive in r.mutuallyExclusiveWith {
            if state.unlockedIds.contains(exclusive) {
                return false  // Already unlocked the exclusive option
            }
        }
        
        return true
    }
    
    func startResearch(_ researchId: String, cash: inout Double) -> Bool {
        guard canStart(researchId) else { return false }
        guard let r = research.first(where: { $0.id == researchId }) else { return false }
        guard cash >= r.cost else { return false }
        
        cash -= r.cost
        state.inProgressId = researchId
        state.progressYears = 0
        
        if let index = research.firstIndex(where: { $0.id == researchId }) {
            research[index].inProgress = true
            research[index].progressYears = 0
        }
        
        NewsFeedManager.shared.addNews(
            category: .personal,
            headline: "Started research: \(r.name) (ETA: \(r.researchTime) years)"
        )
        
        return true
    }
    
    func processYear() {
        guard let progressId = state.inProgressId else { return }
        guard let index = research.firstIndex(where: { $0.id == progressId }) else { return }
        
        state.progressYears += 1
        research[index].progressYears = state.progressYears
        
        if state.progressYears >= research[index].researchTime {
            // Research complete!
            research[index].unlocked = true
            research[index].inProgress = false
            state.unlockedIds.append(progressId)
            
            completedResearchName = research[index].name
            showResearchComplete = true
            
            NewsFeedManager.shared.addNews(
                category: .personal,
                headline: "🎉 Research complete: \(research[index].name)!"
            )
            
            FeedbackCoordinator.shared.achievement()
            
            state.inProgressId = nil
            state.progressYears = 0
        }
    }
    
    // MARK: - Aggregate Effects
    
    var totalTapMultiplier: Double {
        research.filter { $0.unlocked }.reduce(1.0) { $0 * $1.tapMultiplier }
    }
    
    var totalInvestmentBonus: Double {
        research.filter { $0.unlocked }.reduce(0) { $0 + $1.investmentBonus }
    }
    
    var totalPassiveMultiplier: Double {
        research.filter { $0.unlocked }.reduce(1.0) { $0 * $1.passiveIncomeMultiplier }
    }
    
    var totalOpportunityBonus: Double {
        research.filter { $0.unlocked }.reduce(0) { $0 + $1.opportunityBonus }
    }
    
    func hasResearch(_ id: String) -> Bool {
        state.unlockedIds.contains(id)
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: "researchState")
        }
    }
    
    func reset() {
        state = ResearchState()
        research = allResearch
    }
}

// MARK: - ═══════════════════════════════════════════════════════════════
// STRATEGIC EVENTS SYSTEM
// Events with meaningful A/B/C choices that have real consequences.
// No "right" answer - each choice has trade-offs.
// ═══════════════════════════════════════════════════════════════════════

struct StrategicEventChoice: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let consequences: String  // What happens - shown after choice
    let cashCost: Double
    let cashReward: Double
    let statusChange: Int
    let factionRepChanges: [String: Int]  // Faction rawValue -> change
    let specialEffect: String?  // Code for special effects
}

struct StrategicEvent: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let choices: [StrategicEventChoice]
    let minNetWorth: Double
    let phaseRequired: Int  // GamePhase rawValue
    var shown: Bool = false
}

let strategicEvents: [StrategicEvent] = [
    // ═══════════════════════════════════════════════════════════════
    // EARLY GAME EVENTS
    // ═══════════════════════════════════════════════════════════════
    
    StrategicEvent(
        id: "hostile_takeover_offer",
        title: "Hostile Takeover Offer",
        description: "A larger company wants to acquire your business. They're offering 3x current valuation, but you'd lose control.",
        icon: "🦈",
        choices: [
            StrategicEventChoice(id: "accept", title: "Accept the Offer", description: "Take the money and start fresh", consequences: "Received buyout cash. Company reset. Some contacts lost trust.", cashCost: 0, cashReward: 0, statusChange: -20, factionRepChanges: ["Corporate": 10, "Startup/Tech": -20], specialEffect: "company_buyout"),
            StrategicEventChoice(id: "fight", title: "Fight the Takeover", description: "Expensive legal battle to stay independent", consequences: "Spent heavily on lawyers. Kept company. Gained startup respect.", cashCost: 500_000, cashReward: 0, statusChange: 30, factionRepChanges: ["Startup/Tech": 20, "Corporate": -10], specialEffect: nil),
            StrategicEventChoice(id: "negotiate", title: "Negotiate Partnership", description: "Counter with a strategic partnership instead", consequences: "Formed partnership. Gained resources and corporate connections.", cashCost: 0, cashReward: 200_000, statusChange: 15, factionRepChanges: ["Corporate": 15, "Startup/Tech": 5], specialEffect: "add_partner")
        ],
        minNetWorth: 1_000_000,
        phaseRequired: 2
    ),
    
    StrategicEvent(
        id: "viral_moment",
        title: "Viral Moment",
        description: "You've gone viral! A video of you has 10M views. How do you respond?",
        icon: "📱",
        choices: [
            StrategicEventChoice(id: "lean_in", title: "Lean Into Fame", description: "Capitalize with media appearances", consequences: "Became a public figure. Huge tap bonus but now you're polarizing.", cashCost: 0, cashReward: 50_000, statusChange: 100, factionRepChanges: ["Creator": 30, "Old Money": -20], specialEffect: "tap_bonus_50"),
            StrategicEventChoice(id: "ignore", title: "Ignore It", description: "Stay focused on business", consequences: "Moment passed. Respected by serious investors.", cashCost: 0, cashReward: 0, statusChange: 10, factionRepChanges: ["Old Money": 10, "Corporate": 10], specialEffect: nil),
            StrategicEventChoice(id: "monetize", title: "Monetize Carefully", description: "Strategic brand partnerships only", consequences: "Made money without overselling. Balanced approach.", cashCost: 0, cashReward: 100_000, statusChange: 40, factionRepChanges: ["Creator": 15, "Corporate": 5], specialEffect: nil)
        ],
        minNetWorth: 50_000,
        phaseRequired: 2
    ),
    
    StrategicEvent(
        id: "employee_scandal",
        title: "Employee Scandal",
        description: "A key employee has been accused of misconduct. Evidence is unclear.",
        icon: "⚠️",
        choices: [
            StrategicEventChoice(id: "fire", title: "Immediate Termination", description: "Zero tolerance policy", consequences: "Acted decisively. Some think it was hasty. Lost a talented person.", cashCost: 100_000, cashReward: 0, statusChange: -5, factionRepChanges: ["Corporate": 15, "Startup/Tech": -10], specialEffect: "lose_employee"),
            StrategicEventChoice(id: "investigate", title: "Full Investigation", description: "Hire investigators, suspend with pay", consequences: "Thorough process. Expensive. Truth came out.", cashCost: 250_000, cashReward: 0, statusChange: 20, factionRepChanges: ["Corporate": 10, "Old Money": 10], specialEffect: nil),
            StrategicEventChoice(id: "cover", title: "Handle Quietly", description: "NDAs and private settlement", consequences: "Scandal buried. But you know what you did. Risk of future exposure.", cashCost: 500_000, cashReward: 0, statusChange: 5, factionRepChanges: ["Corporate": -5], specialEffect: "scandal_risk")
        ],
        minNetWorth: 500_000,
        phaseRequired: 2
    ),
    
    // ═══════════════════════════════════════════════════════════════
    // MID GAME EVENTS
    // ═══════════════════════════════════════════════════════════════
    
    StrategicEvent(
        id: "billionaire_mentor",
        title: "Billionaire Mentorship",
        description: "A famous billionaire offers to mentor you, but they have a controversial reputation.",
        icon: "🎓",
        choices: [
            StrategicEventChoice(id: "accept_mentor", title: "Accept Mentorship", description: "Learn from the best, regardless of optics", consequences: "Gained invaluable wisdom. Some distance themselves from you.", cashCost: 0, cashReward: 0, statusChange: 50, factionRepChanges: ["Startup/Tech": 25, "Creator": -15], specialEffect: "mentor_bonus"),
            StrategicEventChoice(id: "decline_mentor", title: "Politely Decline", description: "Your reputation is worth more", consequences: "Missed the opportunity. Maintained your image.", cashCost: 0, cashReward: 0, statusChange: 20, factionRepChanges: ["Old Money": 15, "Creator": 10], specialEffect: nil),
            StrategicEventChoice(id: "public_decline", title: "Public Statement Against", description: "Distance yourself loudly", consequences: "Made enemies but also admirers. Very polarizing.", cashCost: 0, cashReward: 0, statusChange: -10, factionRepChanges: ["Creator": 40, "Startup/Tech": -30], specialEffect: nil)
        ],
        minNetWorth: 5_000_000,
        phaseRequired: 3
    ),
    
    StrategicEvent(
        id: "market_insider",
        title: "Insider Information",
        description: "You've received a tip about an upcoming market crash. The source is... questionable.",
        icon: "🔮",
        choices: [
            StrategicEventChoice(id: "act_on_tip", title: "Act on the Tip", description: "Sell everything, prepare for crash", consequences: "If right: massive gains. If wrong: missed opportunities. Legal risk.", cashCost: 0, cashReward: 0, statusChange: 0, factionRepChanges: [:], specialEffect: "market_prediction"),
            StrategicEventChoice(id: "ignore_tip", title: "Ignore It", description: "Stay the course", consequences: "Maintained integrity. Whatever happens, happens.", cashCost: 0, cashReward: 0, statusChange: 10, factionRepChanges: ["Old Money": 10], specialEffect: nil),
            StrategicEventChoice(id: "report_tip", title: "Report to Authorities", description: "Turn in the source", consequences: "Did the right thing. Made powerful enemies. Regulatory friends.", cashCost: 0, cashReward: 50_000, statusChange: 30, factionRepChanges: ["Corporate": 25, "Startup/Tech": -20], specialEffect: "legal_protection")
        ],
        minNetWorth: 10_000_000,
        phaseRequired: 3
    ),
    
    StrategicEvent(
        id: "philanthropy_pressure",
        title: "Philanthropy Pressure",
        description: "Media is criticizing your lack of charitable giving. Other billionaires are signing pledges.",
        icon: "🤝",
        choices: [
            StrategicEventChoice(id: "giving_pledge", title: "Sign the Giving Pledge", description: "Commit 50% of wealth to charity", consequences: "Public praise. Legacy secured. Less wealth to pass on.", cashCost: 0, cashReward: 0, statusChange: 100, factionRepChanges: ["Old Money": -20, "Creator": 30], specialEffect: "giving_pledge"),
            StrategicEventChoice(id: "quiet_giving", title: "Give Quietly", description: "Donate anonymously", consequences: "Helped people. No credit. Pressure continues.", cashCost: 0, cashReward: 0, statusChange: 10, factionRepChanges: ["Old Money": 20], specialEffect: "quiet_donation"),
            StrategicEventChoice(id: "ignore_pressure", title: "Ignore the Critics", description: "It's your money", consequences: "Some respect the stance. Many do not.", cashCost: 0, cashReward: 0, statusChange: -30, factionRepChanges: ["Startup/Tech": 10, "Creator": -40], specialEffect: nil)
        ],
        minNetWorth: 100_000_000,
        phaseRequired: 4
    ),
    
    // ═══════════════════════════════════════════════════════════════
    // LATE GAME EVENTS
    // ═══════════════════════════════════════════════════════════════
    
    StrategicEvent(
        id: "political_choice",
        title: "Political Crossroads",
        description: "Both major political parties want your endorsement and financial support.",
        icon: "🗳️",
        choices: [
            StrategicEventChoice(id: "endorse_left", title: "Endorse Progressive Party", description: "Support workers and regulation", consequences: "Half the country loves you. Half despises you.", cashCost: 10_000_000, cashReward: 0, statusChange: 0, factionRepChanges: ["Creator": 50, "Corporate": -40], specialEffect: "political_left"),
            StrategicEventChoice(id: "endorse_right", title: "Endorse Business Party", description: "Support lower taxes and deregulation", consequences: "Wall Street loves you. Activists target you.", cashCost: 10_000_000, cashReward: 0, statusChange: 0, factionRepChanges: ["Corporate": 50, "Creator": -40], specialEffect: "political_right"),
            StrategicEventChoice(id: "stay_neutral", title: "Stay Neutral", description: "Politics is bad for business", consequences: "Both sides slightly disappointed. Business continues.", cashCost: 0, cashReward: 0, statusChange: -20, factionRepChanges: ["Old Money": 20], specialEffect: nil)
        ],
        minNetWorth: 500_000_000,
        phaseRequired: 4
    ),
    
    StrategicEvent(
        id: "space_race",
        title: "Space Race",
        description: "You have the resources to join the commercial space industry. It's risky but could be legendary.",
        icon: "🚀",
        choices: [
            StrategicEventChoice(id: "full_space", title: "Full Space Commitment", description: "Bet big on becoming a space company", consequences: "Either become the next SpaceX or lose billions.", cashCost: 0, cashReward: 0, statusChange: 100, factionRepChanges: ["Startup/Tech": 50], specialEffect: "space_company"),
            StrategicEventChoice(id: "invest_space", title: "Strategic Investment", description: "Invest in existing space companies", consequences: "Exposure to upside without the risk of execution.", cashCost: 0, cashReward: 0, statusChange: 20, factionRepChanges: ["Startup/Tech": 15], specialEffect: "space_investment"),
            StrategicEventChoice(id: "skip_space", title: "Focus Elsewhere", description: "Space is overhyped", consequences: "Missed the chance. Or avoided a money pit.", cashCost: 0, cashReward: 0, statusChange: -10, factionRepChanges: ["Startup/Tech": -10, "Old Money": 10], specialEffect: nil)
        ],
        minNetWorth: 1_000_000_000,
        phaseRequired: 4
    ),
]

struct StrategicEventState: Codable {
    var shownEventIds: [String] = []
    var pendingEventId: String? = nil
    var lastEventYear: Int = 0
}

class StrategicEventManager: ObservableObject {
    static let shared = StrategicEventManager()
    
    @Published var state: StrategicEventState {
        didSet { save() }
    }
    @Published var currentEvent: StrategicEvent? = nil
    @Published var showEvent = false
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: "strategicEventState"),
           let decoded = try? JSONDecoder().decode(StrategicEventState.self, from: data) {
            self.state = decoded
        } else {
            self.state = StrategicEventState()
        }
    }
    
    func checkForEvent(netWorth: Double, phase: Int, currentYear: Int) {
        // Only one event per 2 years minimum
        guard currentYear - state.lastEventYear >= 2 else { return }
        guard currentEvent == nil else { return }
        
        // Find eligible events
        let eligible = strategicEvents.filter { event in
            !state.shownEventIds.contains(event.id) &&
            netWorth >= event.minNetWorth &&
            phase >= event.phaseRequired
        }
        
        guard !eligible.isEmpty else { return }
        
        // 20% chance per year to trigger an event
        if Double.random(in: 0...1) < 0.2 {
            if let event = eligible.randomElement() {
                currentEvent = event
                showEvent = true
                state.lastEventYear = currentYear
            }
        }
    }
    
    func makeChoice(_ choiceId: String, game: GameState) -> String {
        guard let event = currentEvent,
              let choice = event.choices.first(where: { $0.id == choiceId }) else {
            return "Error"
        }
        
        // Apply cash effects
        if choice.cashCost > 0 {
            game.cash -= choice.cashCost
        }
        if choice.cashReward > 0 {
            game.cash += choice.cashReward
            game.totalEarned += choice.cashReward
        }
        
        // Apply status
        game.statusPoints += choice.statusChange
        
        // Apply faction changes
        for (factionRaw, change) in choice.factionRepChanges {
            if let faction = Faction(rawValue: factionRaw) {
                FactionManager.shared.modifyReputation(faction, by: change)
            }
        }
        
        // Apply special effects
        if let effect = choice.specialEffect {
            applySpecialEffect(effect, game: game)
        }
        
        // Mark as shown
        state.shownEventIds.append(event.id)
        
        // Clear event
        currentEvent = nil
        showEvent = false
        
        return choice.consequences
    }
    
    private func applySpecialEffect(_ effect: String, game: GameState) {
        switch effect {
        case "company_buyout":
            // 3x valuation payout, then reset company
            let payout = CompanyManager.shared.state.companyValuation * 3
            game.cash += payout
            game.totalEarned += payout
            CompanyManager.shared.reset()
            
        case "tap_bonus_50":
            // This would need to be tracked - simplified here
            NewsFeedManager.shared.addNews(category: .personal, headline: "Fame bonus: Taps worth 50% more this year!")
            
        case "mentor_bonus":
            // Permanent passive income boost
            NewsFeedManager.shared.addNews(category: .personal, headline: "Mentor wisdom: All income +10% permanently")
            
        case "giving_pledge":
            // Commit 50% of future wealth to charity (reduce prestige carry-over)
            NewsFeedManager.shared.addNews(category: .personal, headline: "Giving Pledge signed: 50% of wealth to charity")
            
        case "space_company":
            // Enter space industry
            CompanyManager.shared.enterIndustry(.space)
            
        default:
            break
        }
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: "strategicEventState")
        }
    }
    
    func reset() {
        state = StrategicEventState()
        currentEvent = nil
        showEvent = false
    }
}

// MARK: - ═══════════════════════════════════════════════════════════════
// COMPETITOR SYSTEM
// AI rivals who compete for opportunities and resources.
// Makes the game feel more alive and competitive.
// ═══════════════════════════════════════════════════════════════════════

struct Competitor: Identifiable, Codable {
    let id: String
    let name: String
    let company: String
    let icon: String
    let personality: CompetitorPersonality
    var netWorth: Double
    var growthRate: Double  // Annual growth percentage
    var aggressiveness: Double  // 0-1, how often they compete
    var isActive: Bool = true
    
    mutating func processYear() {
        // Competitors grow too
        let growth = netWorth * growthRate * Double.random(in: 0.8...1.2)
        netWorth += growth
    }
}

enum CompetitorPersonality: String, Codable {
    case aggressive = "Aggressive"
    case calculated = "Calculated"
    case defensive = "Defensive"
    case erratic = "Erratic"
    
    var description: String {
        switch self {
        case .aggressive: return "Attacks opportunities and rivals constantly"
        case .calculated: return "Waits for perfect moments, then strikes"
        case .defensive: return "Protects position, rarely attacks"
        case .erratic: return "Unpredictable - could do anything"
        }
    }
}

let initialCompetitors: [Competitor] = [
    Competitor(id: "sophia", name: "Sophia Chen", company: "NexGen AI", icon: "👩‍💼", personality: .calculated, netWorth: 500_000, growthRate: 0.35, aggressiveness: 0.4),
    Competitor(id: "marcus", name: "Marcus Webb", company: "Webb Industries", icon: "👨‍💼", personality: .aggressive, netWorth: 800_000, growthRate: 0.25, aggressiveness: 0.8),
    Competitor(id: "elena", name: "Elena Volkov", company: "Volkov Capital", icon: "👱‍♀️", personality: .defensive, netWorth: 2_000_000, growthRate: 0.15, aggressiveness: 0.2),
    Competitor(id: "raj", name: "Raj Patel", company: "Patel Ventures", icon: "🧔", personality: .erratic, netWorth: 300_000, growthRate: 0.40, aggressiveness: 0.5),
]

struct CompetitorState: Codable {
    var competitors: [Competitor] = initialCompetitors
    var activeRivalryId: String? = nil
    var rivalryIntensity: Int = 0  // 0-100, how heated things are
}

class CompetitorManager: ObservableObject {
    static let shared = CompetitorManager()
    
    @Published var state: CompetitorState {
        didSet { save() }
    }
    
    @Published var showCompetitorAction = false
    @Published var competitorActionMessage = ""
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: "competitorState"),
           let decoded = try? JSONDecoder().decode(CompetitorState.self, from: data) {
            self.state = decoded
        } else {
            self.state = CompetitorState()
        }
    }
    
    func processYear(playerNetWorth: Double) {
        // Update all competitors
        for i in 0..<state.competitors.count {
            state.competitors[i].processYear()
        }
        
        // Check for competitive actions
        checkCompetitorActions(playerNetWorth: playerNetWorth)
        
        // Check for rivalry changes
        updateRivalry(playerNetWorth: playerNetWorth)
    }
    
    private func checkCompetitorActions(playerNetWorth: Double) {
        for competitor in state.competitors where competitor.isActive {
            // Competitor may take action based on aggressiveness
            if Double.random(in: 0...1) < competitor.aggressiveness * 0.3 {
                performCompetitorAction(competitor, playerNetWorth: playerNetWorth)
            }
        }
    }
    
    private func performCompetitorAction(_ competitor: Competitor, playerNetWorth: Double) {
        let actions: [(message: String, effect: String)] = [
            ("\(competitor.name) poached one of your key employees!", "lose_employee"),
            ("\(competitor.name) won a contract you were bidding on.", "lost_deal"),
            ("\(competitor.name) is spreading rumors about your company.", "reputation_damage"),
            ("\(competitor.name) acquired a company you wanted.", "missed_acquisition"),
        ]
        
        // Only perform action if competitor is close in net worth (within 10x)
        let ratio = playerNetWorth / competitor.netWorth
        guard ratio > 0.1 && ratio < 10 else { return }
        
        if let action = actions.randomElement() {
            competitorActionMessage = action.message
            showCompetitorAction = true
            
            NewsFeedManager.shared.addNews(
                category: .breaking,
                headline: action.message
            )
            
            // Increase rivalry
            state.rivalryIntensity = min(100, state.rivalryIntensity + 10)
            if state.activeRivalryId == nil {
                state.activeRivalryId = competitor.id
            }
        }
    }
    
    private func updateRivalry(playerNetWorth: Double) {
        // Find closest competitor by net worth
        let sorted = state.competitors
            .filter { $0.isActive }
            .sorted { abs($0.netWorth - playerNetWorth) < abs($1.netWorth - playerNetWorth) }
        
        if let closest = sorted.first {
            // If player passes a competitor, announce it
            if playerNetWorth > closest.netWorth && state.activeRivalryId == closest.id {
                NewsFeedManager.shared.addNews(
                    category: .personal,
                    headline: "You've surpassed \(closest.name)! New rival ahead..."
                )
                
                // Find next rival
                if let nextRival = sorted.dropFirst().first {
                    state.activeRivalryId = nextRival.id
                }
            }
        }
    }
    
    func getRival() -> Competitor? {
        guard let rivalId = state.activeRivalryId else { return nil }
        return state.competitors.first { $0.id == rivalId }
    }
    
    func getLeaderboard(playerNetWorth: Double) -> [(name: String, netWorth: Double, isPlayer: Bool)] {
        var board: [(name: String, netWorth: Double, isPlayer: Bool)] = [
            ("You", playerNetWorth, true)
        ]
        
        for competitor in state.competitors where competitor.isActive {
            board.append((competitor.name, competitor.netWorth, false))
        }
        
        return board.sorted { $0.netWorth > $1.netWorth }
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: "competitorState")
        }
    }
    
    func reset() {
        state = CompetitorState()
    }
}

// MARK: - ═══════════════════════════════════════════════════════════════
// SYNERGY SYSTEM
// Rewards for building complementary strategies.
// Encourages players to think about combinations.
// ═══════════════════════════════════════════════════════════════════════

struct Synergy: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let requirements: [String]  // What's needed to unlock
    let multiplier: Double  // Bonus multiplier when active
    let bonusType: SynergyBonus
}

enum SynergyBonus: String, Codable {
    case tapValue = "Tap Value"
    case passiveIncome = "Passive Income"
    case investmentReturns = "Investment Returns"
    case opportunitySuccess = "Opportunity Success"
    case contactBonus = "Contact Bonuses"
    case companyValuation = "Company Valuation"
}

let allSynergies: [Synergy] = [
    // Career + Faction synergies
    Synergy(id: "tech_startup", name: "Silicon Valley Native", description: "Tech career + Startup faction elite", icon: "🚀", requirements: ["career_tech", "faction_startup_elite"], multiplier: 1.25, bonusType: .passiveIncome),
    
    Synergy(id: "finance_oldmoney", name: "Old Money's Chosen", description: "Finance career + Old Money faction elite", icon: "🎩", requirements: ["career_finance", "faction_oldmoney_elite"], multiplier: 1.20, bonusType: .investmentReturns),
    
    Synergy(id: "creator_viral", name: "Viral Empire", description: "Creator career + 50+ contacts met", icon: "📱", requirements: ["career_creator", "contacts_50"], multiplier: 1.30, bonusType: .tapValue),
    
    // Department synergies
    Synergy(id: "full_team", name: "Complete Organization", description: "All 5 departments with 3+ employees each", icon: "🏢", requirements: ["dept_all_3"], multiplier: 1.40, bonusType: .companyValuation),
    
    Synergy(id: "sales_marketing", name: "Growth Machine", description: "5+ Sales AND 5+ Marketing employees", icon: "📈", requirements: ["dept_sales_5", "dept_marketing_5"], multiplier: 1.20, bonusType: .tapValue),
    
    Synergy(id: "engineering_finance", name: "Fintech Ready", description: "5+ Engineering AND 5+ Finance employees", icon: "💳", requirements: ["dept_engineering_5", "dept_finance_5"], multiplier: 1.25, bonusType: .investmentReturns),
    
    // Research synergies
    Synergy(id: "automation_networking", name: "Leveraged Automation", description: "Auto tier 3 + Networking tier 3 research", icon: "🤖🤝", requirements: ["research_auto_3", "research_net_3"], multiplier: 1.35, bonusType: .passiveIncome),
    
    Synergy(id: "finance_influence", name: "Power Broker", description: "Finance tier 3 + Influence tier 3 research", icon: "💰👑", requirements: ["research_fin_3", "research_inf_3"], multiplier: 1.30, bonusType: .opportunitySuccess),
    
    // Mixed synergies
    Synergy(id: "balanced_tycoon", name: "Balanced Tycoon", description: "All factions at 50+ reputation", icon: "⚖️", requirements: ["faction_all_50"], multiplier: 1.50, bonusType: .contactBonus),
    
    Synergy(id: "industry_leader", name: "Industry Leader", description: "5+ industries AND $100M+ valuation", icon: "🌐", requirements: ["industries_5", "valuation_100m"], multiplier: 1.60, bonusType: .companyValuation),
]

class SynergyManager: ObservableObject {
    static let shared = SynergyManager()
    
    @Published var activeSynergies: [String] = []
    
    private init() {
        if let data = UserDefaults.standard.array(forKey: "activeSynergies") as? [String] {
            self.activeSynergies = data
        }
    }
    
    func checkSynergies(game: GameState) {
        var newActive: [String] = []
        
        for synergy in allSynergies {
            if checkRequirements(synergy.requirements, game: game) {
                newActive.append(synergy.id)
                
                // Announce new synergy
                if !activeSynergies.contains(synergy.id) {
                    NewsFeedManager.shared.addNews(
                        category: .personal,
                        headline: "\(synergy.icon) SYNERGY UNLOCKED: \(synergy.name) - \(synergy.bonusType.rawValue) +\(Int((synergy.multiplier - 1) * 100))%!"
                    )
                    FeedbackCoordinator.shared.achievement()
                }
            }
        }
        
        activeSynergies = newActive
        save()
    }
    
    private func checkRequirements(_ requirements: [String], game: GameState) -> Bool {
        for req in requirements {
            if !checkSingleRequirement(req, game: game) {
                return false
            }
        }
        return true
    }
    
    private func checkSingleRequirement(_ req: String, game: GameState) -> Bool {
        switch req {
        // Career requirements
        case "career_tech": return game.selectedCareer == .tech
        case "career_finance": return game.selectedCareer == .finance
        case "career_creator": return game.selectedCareer == .creator
        case "career_trades": return game.selectedCareer == .trades
            
        // Faction requirements
        case "faction_startup_elite": return FactionManager.shared.reputation[.startup] >= 75
        case "faction_oldmoney_elite": return FactionManager.shared.reputation[.oldMoney] >= 75
        case "faction_corporate_elite": return FactionManager.shared.reputation[.corporate] >= 75
        case "faction_creator_elite": return FactionManager.shared.reputation[.creator] >= 75
        case "faction_all_50": return Faction.allCases.allSatisfy { FactionManager.shared.reputation[$0] >= 50 }
            
        // Contact requirements
        case "contacts_50": return game.contacts.filter { $0.hasMet }.count >= 50
            
        // Department requirements
        case "dept_all_3":
            return Department.allCases.allSatisfy { CompanyManager.shared.getDepartmentCount($0) >= 3 }
        case "dept_sales_5": return CompanyManager.shared.getDepartmentCount(.sales) >= 5
        case "dept_marketing_5": return CompanyManager.shared.getDepartmentCount(.marketing) >= 5
        case "dept_engineering_5": return CompanyManager.shared.getDepartmentCount(.engineering) >= 5
        case "dept_finance_5": return CompanyManager.shared.getDepartmentCount(.finance) >= 5
            
        // Research requirements
        case "research_auto_3": return ResearchManager.shared.hasResearch("auto_3")
        case "research_net_3": return ResearchManager.shared.hasResearch("net_3")
        case "research_fin_3": return ResearchManager.shared.hasResearch("fin_3")
        case "research_inf_3": return ResearchManager.shared.hasResearch("inf_3")
            
        // Company requirements
        case "industries_5": return CompanyManager.shared.state.industries.count >= 5
        case "valuation_100m": return CompanyManager.shared.state.companyValuation >= 100_000_000
            
        default: return false
        }
    }
    
    func getMultiplier(for bonusType: SynergyBonus) -> Double {
        var total = 1.0
        for synergyId in activeSynergies {
            if let synergy = allSynergies.first(where: { $0.id == synergyId }),
               synergy.bonusType == bonusType {
                total *= synergy.multiplier
            }
        }
        return total
    }
    
    private func save() {
        UserDefaults.standard.set(activeSynergies, forKey: "activeSynergies")
    }
    
    func reset() {
        activeSynergies = []
        UserDefaults.standard.removeObject(forKey: "activeSynergies")
    }
}

// MARK: - ═══════════════════════════════════════════════════════════════
// STRATEGIC HUD VIEWS
// ═══════════════════════════════════════════════════════════════════════

struct EconomicCycleIndicator: View {
    @ObservedObject var economy = EconomicCycleManager.shared
    
    var body: some View {
        HStack(spacing: 8) {
            Text(economy.state.currentPhase.icon)
                .font(.system(size: 14))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(economy.state.currentPhase.rawValue)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(economy.state.currentPhase.color)
                
                Text(economy.phaseChangePrediction)
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
            }
            
            // Leading indicator spark
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                    Capsule()
                        .fill(economy.state.currentPhase.color)
                        .frame(width: geo.size.width * (economy.state.leadingIndicator / 100))
                }
            }
            .frame(width: 40, height: 4)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(economy.state.currentPhase.color.opacity(0.15))
        )
    }
}

struct SynergyIndicator: View {
    @ObservedObject var synergies = SynergyManager.shared
    
    var body: some View {
        if !synergies.activeSynergies.isEmpty {
            HStack(spacing: 4) {
                ForEach(synergies.activeSynergies.prefix(3), id: \.self) { id in
                    if let synergy = allSynergies.first(where: { $0.id == id }) {
                        Text(synergy.icon)
                            .font(.system(size: 12))
                    }
                }
                if synergies.activeSynergies.count > 3 {
                    Text("+\(synergies.activeSynergies.count - 3)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.yellow)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.yellow.opacity(0.2))
            )
        }
    }
}

struct CompetitorRivalryBadge: View {
    @ObservedObject var competitors = CompetitorManager.shared
    let playerNetWorth: Double
    
    var body: some View {
        if let rival = competitors.getRival() {
            HStack(spacing: 6) {
                Text(rival.icon)
                    .font(.system(size: 12))
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("vs \(rival.name)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                    
                    let diff = playerNetWorth - rival.netWorth
                    Text(diff > 0 ? "Ahead" : "Behind")
                        .font(.system(size: 8))
                        .foregroundColor(diff > 0 ? .green : .red)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.red.opacity(0.2))
            )
        }
    }
}

struct ResearchProgressBadge: View {
    @ObservedObject var research = ResearchManager.shared
    
    var body: some View {
        if let progressId = research.state.inProgressId,
           let r = research.research.first(where: { $0.id == progressId }) {
            HStack(spacing: 6) {
                Text(r.branch.icon)
                    .font(.system(size: 12))
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(r.name)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("\(research.state.progressYears)/\(r.researchTime) years")
                        .font(.system(size: 8))
                        .foregroundColor(r.branch.color)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(r.branch.color.opacity(0.2))
            )
        }
    }
}
