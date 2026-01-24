//
//  WealthDimensions.swift
//  Life of Wealth
//
//  Multi-dimensional wealth tracking - Financial, Relationships, Experiences, Health, Legacy
//

import SwiftUI
import Combine

// MARK: - Wealth Dimension Type
enum WealthDimension: String, Codable, CaseIterable {
    case financial = "Financial"
    case relationships = "Relationships"
    case experiences = "Experiences"
    case health = "Health"
    case legacy = "Legacy"
    
    var icon: String {
        switch self {
        case .financial: return "💵"
        case .relationships: return "❤️"
        case .experiences: return "🌟"
        case .health: return "⚖️"
        case .legacy: return "🏛️"
        }
    }
    
    var description: String {
        switch self {
        case .financial: return "Cash, investments, net worth"
        case .relationships: return "Family bonds, friendships, network"
        case .experiences: return "Travel, adventures, memories"
        case .health: return "Stress level, work-life balance"
        case .legacy: return "Philanthropy, mentees, lasting impact"
        }
    }
    
    var color: Color {
        switch self {
        case .financial: return Color.green
        case .relationships: return Color.red
        case .experiences: return Color.yellow
        case .health: return Color.blue
        case .legacy: return Color.purple
        }
    }
    
    // Decay rate per game year (0 = no decay)
    var decayRatePerYear: Double {
        switch self {
        case .financial: return 0 // Financial doesn't decay, managed separately
        case .relationships: return 5.0 // Relationships decay if neglected
        case .experiences: return 2.0 // Memories fade slowly
        case .health: return 3.0 // Health declines without attention
        case .legacy: return 0 // Legacy only grows, never decays
        }
    }
}

// MARK: - Wealth Impact
struct WealthImpact: Codable {
    var financial: Int = 0
    var relationships: Int = 0
    var experiences: Int = 0
    var health: Int = 0
    var legacy: Int = 0
    
    static let zero = WealthImpact()
    
    var isEmpty: Bool {
        financial == 0 && relationships == 0 && experiences == 0 && health == 0 && legacy == 0
    }
    
    var description: String {
        var parts: [String] = []
        if financial != 0 { parts.append("\(WealthDimension.financial.icon)\(financial > 0 ? "+" : "")\(financial)") }
        if relationships != 0 { parts.append("\(WealthDimension.relationships.icon)\(relationships > 0 ? "+" : "")\(relationships)") }
        if experiences != 0 { parts.append("\(WealthDimension.experiences.icon)\(experiences > 0 ? "+" : "")\(experiences)") }
        if health != 0 { parts.append("\(WealthDimension.health.icon)\(health > 0 ? "+" : "")\(health)") }
        if legacy != 0 { parts.append("\(WealthDimension.legacy.icon)\(legacy > 0 ? "+" : "")\(legacy)") }
        return parts.joined(separator: " ")
    }
}

// MARK: - Wealth State
struct WealthState: Codable {
    var financial: Int = 50  // 0-100, starts at 50
    var relationships: Int = 50
    var experiences: Int = 30  // Start lower - haven't lived yet
    var health: Int = 80  // Start healthy
    var legacy: Int = 0  // Start with no legacy
    
    subscript(dimension: WealthDimension) -> Int {
        get {
            switch dimension {
            case .financial: return financial
            case .relationships: return relationships
            case .experiences: return experiences
            case .health: return health
            case .legacy: return legacy
            }
        }
        set {
            let clamped = max(0, min(100, newValue))
            switch dimension {
            case .financial: financial = clamped
            case .relationships: relationships = clamped
            case .experiences: experiences = clamped
            case .health: health = clamped
            case .legacy: legacy = clamped
            }
        }
    }
    
    mutating func apply(_ impact: WealthImpact) {
        financial = max(0, min(100, financial + impact.financial))
        relationships = max(0, min(100, relationships + impact.relationships))
        experiences = max(0, min(100, experiences + impact.experiences))
        health = max(0, min(100, health + impact.health))
        legacy = max(0, min(100, legacy + impact.legacy))
    }
    
    mutating func applyYearlyDecay() {
        for dimension in WealthDimension.allCases {
            let decay = dimension.decayRatePerYear
            if decay > 0 {
                self[dimension] = max(0, self[dimension] - Int(decay))
            }
        }
    }
    
    var averageScore: Double {
        Double(financial + relationships + experiences + health + legacy) / 5.0
    }
    
    var isBalanced: Bool {
        let scores = [financial, relationships, experiences, health, legacy]
        let min = scores.min() ?? 0
        let max = scores.max() ?? 0
        return (max - min) <= 30 // Within 30 points of each other
    }
}

// MARK: - Wealth Manager
class WealthManager: ObservableObject {
    static let shared = WealthManager()
    
    @Published var state: WealthState {
        didSet { save() }
    }
    
    @Published var recentImpact: WealthImpact?
    @Published var showImpactAnimation = false
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: "wealthState"),
           let decoded = try? JSONDecoder().decode(WealthState.self, from: data) {
            self.state = decoded
        } else {
            self.state = WealthState()
        }
    }
    
    // MARK: - Apply Impact
    func applyImpact(_ impact: WealthImpact, animated: Bool = true) {
        state.apply(impact)
        
        if animated && !impact.isEmpty {
            recentImpact = impact
            showImpactAnimation = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.showImpactAnimation = false
            }
        }
    }
    
    // MARK: - Year End Processing
    func processYearEnd() {
        state.applyYearlyDecay()
    }
    
    // MARK: - Financial Wealth Sync
    // Called to sync financial dimension with actual net worth
    func syncFinancialWealth(netWorth: Double) {
        // Map net worth to 0-100 scale
        // $0 = 0, $100K = 25, $1M = 50, $10M = 75, $100M+ = 100
        let score: Int
        switch netWorth {
        case ..<0: score = 0
        case 0..<100_000: score = Int(netWorth / 100_000 * 25)
        case 100_000..<1_000_000: score = 25 + Int((netWorth - 100_000) / 900_000 * 25)
        case 1_000_000..<10_000_000: score = 50 + Int((netWorth - 1_000_000) / 9_000_000 * 25)
        case 10_000_000..<100_000_000: score = 75 + Int((netWorth - 10_000_000) / 90_000_000 * 25)
        default: score = 100
        }
        state.financial = score
    }
    
    // MARK: - Health Effects
    var earlyDeathRisk: Double {
        // Low health increases chance of early death
        if state.health >= 50 { return 0 }
        return Double(50 - state.health) / 100.0 // Up to 50% risk at 0 health
    }
    
    var isAtRiskOfBurnout: Bool {
        state.health < 20
    }
    
    // MARK: - Relationship Effects
    var canAccessNetworkOpportunities: Bool {
        state.relationships >= 30
    }
    
    var familyHappinessLevel: String {
        switch state.relationships {
        case 80...100: return "Thriving"
        case 60..<80: return "Happy"
        case 40..<60: return "Strained"
        case 20..<40: return "Struggling"
        default: return "Broken"
        }
    }
    
    // MARK: - Persistence
    private func save() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: "wealthState")
        }
    }
    
    func reset() {
        state = WealthState()
    }
    
    func resetWithBonus(multiplier: Double) {
        var newState = WealthState()
        newState.financial = min(100, Int(Double(newState.financial) * multiplier))
        newState.relationships = min(100, Int(Double(newState.relationships) * multiplier))
        newState.experiences = min(100, Int(Double(newState.experiences) * multiplier))
        newState.health = min(100, Int(Double(newState.health) * multiplier))
        state = newState
    }
}

// MARK: - Wealth Dimension Bar View
struct WealthDimensionBar: View {
    let dimension: WealthDimension
    let value: Int
    let compact: Bool
    
    init(dimension: WealthDimension, value: Int, compact: Bool = true) {
        self.dimension = dimension
        self.value = value
        self.compact = compact
    }
    
    var body: some View {
        if compact {
            compactView
        } else {
            fullView
        }
    }
    
    var compactView: some View {
        HStack(spacing: 4) {
            Text(dimension.icon)
                .font(.system(size: 12))
            Text("\(value)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(colorForValue)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(dimension.color.opacity(0.15))
        )
    }
    
    var fullView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(dimension.icon)
                    .font(.system(size: 14))
                Text(dimension.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray)
                Spacer()
                Text("\(value)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(colorForValue)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(dimension.color)
                        .frame(width: geometry.size.width * CGFloat(value) / 100, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
    
    var colorForValue: Color {
        switch value {
        case 70...100: return .green
        case 40..<70: return .yellow
        case 20..<40: return .orange
        default: return .red
        }
    }
}

// MARK: - Wealth Overview View
struct WealthOverviewView: View {
    @ObservedObject var wealth = WealthManager.shared
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(WealthDimension.allCases, id: \.self) { dimension in
                WealthDimensionBar(
                    dimension: dimension,
                    value: wealth.state[dimension],
                    compact: true
                )
            }
        }
    }
}

// MARK: - Impact Preview View
struct ImpactPreviewView: View {
    let impact: WealthImpact
    
    var body: some View {
        HStack(spacing: 8) {
            if impact.financial != 0 {
                impactBadge(dimension: .financial, value: impact.financial)
            }
            if impact.relationships != 0 {
                impactBadge(dimension: .relationships, value: impact.relationships)
            }
            if impact.experiences != 0 {
                impactBadge(dimension: .experiences, value: impact.experiences)
            }
            if impact.health != 0 {
                impactBadge(dimension: .health, value: impact.health)
            }
            if impact.legacy != 0 {
                impactBadge(dimension: .legacy, value: impact.legacy)
            }
        }
    }
    
    func impactBadge(dimension: WealthDimension, value: Int) -> some View {
        HStack(spacing: 2) {
            Text(dimension.icon)
                .font(.system(size: 10))
            Text(value > 0 ? "+\(value)" : "\(value)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(value > 0 ? .green : .red)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(value > 0 ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
        )
    }
}

// MARK: - Floating Impact Animation
struct FloatingImpactView: View {
    let impact: WealthImpact
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1
    
    var body: some View {
        ImpactPreviewView(impact: impact)
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 1.5)) {
                    offset = -50
                    opacity = 0
                }
            }
    }
}
