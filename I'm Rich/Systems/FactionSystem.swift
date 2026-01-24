//
//  FactionSystem.swift
//  Life of Wealth
//
//  Four factions with distinct philosophies and reputation-gated opportunities
//

import SwiftUI
import Combine

// MARK: - Faction Type
enum Faction: String, Codable, CaseIterable {
    case corporate = "Corporate"
    case startup = "Startup/Tech"
    case oldMoney = "Old Money"
    case creator = "Creator"
    
    var icon: String {
        switch self {
        case .corporate: return "🏢"
        case .startup: return "🚀"
        case .oldMoney: return "🎩"
        case .creator: return "📱"
        }
    }
    
    var philosophy: String {
        switch self {
        case .corporate: return "Stability, hierarchy, benefits"
        case .startup: return "Risk-taking, disruption, equity"
        case .oldMoney: return "Connections, tradition, status"
        case .creator: return "Audience, authenticity, viral"
        }
    }
    
    var color: Color {
        switch self {
        case .corporate: return .blue
        case .startup: return .orange
        case .oldMoney: return .purple
        case .creator: return .pink
        }
    }
    
    var alignedCareer: CareerPath {
        switch self {
        case .corporate: return .finance
        case .startup: return .tech
        case .oldMoney: return .finance
        case .creator: return .creator
        }
    }
    
    var opportunityTypes: [String] {
        switch self {
        case .corporate: return ["Safe promotions", "Stock options", "Networking events", "401k matching"]
        case .startup: return ["Equity offers", "IPO opportunities", "Tech conferences", "Moonshot ventures"]
        case .oldMoney: return ["Exclusive clubs", "Inheritance", "Charity galas", "Private banking"]
        case .creator: return ["Brand deals", "Viral moments", "Fan meetups", "Merch launches"]
        }
    }
}

// MARK: - Reputation Tier
enum ReputationTier: Int, CaseIterable {
    case unknown = 0
    case known = 25
    case respected = 50
    case elite = 75
    case legendary = 90
    
    var name: String {
        switch self {
        case .unknown: return "Unknown"
        case .known: return "Known"
        case .respected: return "Respected"
        case .elite: return "Elite"
        case .legendary: return "Legendary"
        }
    }
    
    var unlockDescription: String {
        switch self {
        case .unknown: return "No access to faction opportunities"
        case .known: return "Basic opportunities unlocked"
        case .respected: return "Advanced opportunities unlocked"
        case .elite: return "Elite opportunities unlocked"
        case .legendary: return "Legendary contacts and opportunities"
        }
    }
    
    static func fromReputation(_ rep: Int) -> ReputationTier {
        switch rep {
        case 90...100: return .legendary
        case 75..<90: return .elite
        case 50..<75: return .respected
        case 25..<50: return .known
        default: return .unknown
        }
    }
}

// MARK: - Faction Reputation State
struct FactionReputationState: Codable {
    var corporate: Int = 10
    var startup: Int = 10
    var oldMoney: Int = 0
    var creator: Int = 10
    
    subscript(faction: Faction) -> Int {
        get {
            switch faction {
            case .corporate: return corporate
            case .startup: return startup
            case .oldMoney: return oldMoney
            case .creator: return creator
            }
        }
        set {
            let clamped = max(0, min(100, newValue))
            switch faction {
            case .corporate: corporate = clamped
            case .startup: startup = clamped
            case .oldMoney: oldMoney = clamped
            case .creator: creator = clamped
            }
        }
    }
    
    func tier(for faction: Faction) -> ReputationTier {
        ReputationTier.fromReputation(self[faction])
    }
    
    var highestFaction: Faction {
        let all = [
            (Faction.corporate, corporate),
            (Faction.startup, startup),
            (Faction.oldMoney, oldMoney),
            (Faction.creator, creator)
        ]
        return all.max(by: { $0.1 < $1.1 })?.0 ?? .corporate
    }
}

// MARK: - Faction Manager
class FactionManager: ObservableObject {
    static let shared = FactionManager()
    
    @Published var reputation: FactionReputationState {
        didSet { save() }
    }
    
    @Published var showReputationChange = false
    @Published var recentReputationChange: (faction: Faction, amount: Int)?
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: "factionReputation"),
           let decoded = try? JSONDecoder().decode(FactionReputationState.self, from: data) {
            self.reputation = decoded
        } else {
            self.reputation = FactionReputationState()
        }
    }
    
    // MARK: - Career Selection Bonus
    func applyCareerBonus(_ career: CareerPath) {
        switch career {
        case .tech:
            modifyReputation(.startup, by: 20)
            modifyReputation(.corporate, by: 10)
        case .finance:
            modifyReputation(.corporate, by: 20)
            modifyReputation(.oldMoney, by: 10)
        case .creator:
            modifyReputation(.creator, by: 25)
        case .trades:
            modifyReputation(.corporate, by: 5)
            modifyReputation(.startup, by: 5)
        }
    }
    
    // MARK: - Modify Reputation
    
    /// Modify reputation with optional rival penalty
    /// - Parameters:
    ///   - faction: The faction to modify
    ///   - amount: Points to add (or subtract if negative)
    ///   - applyRivalry: If true, gaining reputation with one faction hurts rivals
    func modifyReputation(_ faction: Faction, by amount: Int, applyRivalry: Bool = false) {
        reputation[faction] += amount
        
        if applyRivalry && amount > 0 {
            // ENHANCED RIVALRY - Gaining rep with one faction significantly hurts rivals
            let rivals = getRivals(of: faction)
            let rivalPenalty = calculateRivalPenalty(baseGain: amount, currentRep: reputation[faction])
            for rival in rivals {
                reputation[rival] -= rivalPenalty
            }
        }
        
        recentReputationChange = (faction, amount)
        showReputationChange = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.showReputationChange = false
        }
    }
    
    /// Calculate rival penalty - gets more severe at higher reputation levels
    private func calculateRivalPenalty(baseGain: Int, currentRep: Int) -> Int {
        // Rivalry intensifies as you become more prominent
        let rivalryMultiplier: Double
        switch currentRep {
        case 0..<25: rivalryMultiplier = 0.25     // Minor rivalry
        case 25..<50: rivalryMultiplier = 0.40   // Growing tension
        case 50..<75: rivalryMultiplier = 0.50   // Serious rivalry
        case 75..<90: rivalryMultiplier = 0.60   // Fierce competition
        default: rivalryMultiplier = 0.75        // At the top, enemies hate you
        }
        return max(1, Int(Double(baseGain) * rivalryMultiplier))
    }
    
    /// Get rival factions
    func getRivals(of faction: Faction) -> [Faction] {
        switch faction {
        case .corporate: return [.startup, .creator]
        case .startup: return [.corporate, .oldMoney]
        case .oldMoney: return [.startup, .creator]
        case .creator: return [.corporate, .oldMoney]
        }
    }
    
    /// Get allied factions
    func getAllies(of faction: Faction) -> [Faction] {
        switch faction {
        case .corporate: return [.oldMoney]
        case .startup: return [.creator]
        case .oldMoney: return [.corporate]
        case .creator: return [.startup]
        }
    }
    
    // MARK: - Public Scandal (Consequence Event)
    
    /// Trigger a public scandal that damages all faction reputations
    func triggerScandal(severity: ScandalSeverity) {
        for faction in Faction.allCases {
            reputation[faction] -= severity.reputationDamage
        }
        
        NewsFeedManager.shared.addNews(
            category: .personal,
            headline: severity.headline
        )
    }
    
    enum ScandalSeverity {
        case minor      // Bad press
        case moderate   // Controversy
        case major      // Full scandal
        case catastrophic  // Career-ending
        
        var reputationDamage: Int {
            switch self {
            case .minor: return 5
            case .moderate: return 15
            case .major: return 30
            case .catastrophic: return 50
            }
        }
        
        var headline: String {
            switch self {
            case .minor: return "Minor controversy creates bad optics"
            case .moderate: return "Growing controversy affects your reputation"
            case .major: return "Major scandal rocks your empire!"
            case .catastrophic: return "CATASTROPHIC: Your reputation is in ruins"
            }
        }
    }
    
    // MARK: - Faction Lock-in Check
    
    /// Check if player is "locked in" to a faction (reputation too high to switch)
    func isLockedIn(to faction: Faction) -> Bool {
        reputation[faction] >= 75
    }
    
    /// Get factions that are now hostile due to rivalry
    func getHostileFactions() -> [Faction] {
        Faction.allCases.filter { reputation[$0] < 10 }
    }
    
    /// Check if a faction is hostile (reputation too damaged)
    func isHostile(_ faction: Faction) -> Bool {
        reputation[faction] < 10
    }
    
    // MARK: - Access Checks
    func canAccessOpportunity(requiringFaction faction: Faction, tier: ReputationTier) -> Bool {
        reputation[faction] >= tier.rawValue
    }
    
    func canMeetContact(requiringFaction faction: Faction, minReputation: Int) -> Bool {
        reputation[faction] >= minReputation
    }
    
    // MARK: - Tier Access
    func tier(for faction: Faction) -> ReputationTier {
        reputation.tier(for: faction)
    }
    
    func allTiers() -> [(Faction, ReputationTier)] {
        Faction.allCases.map { ($0, tier(for: $0)) }
    }
    
    // MARK: - Persistence
    private func save() {
        if let data = try? JSONEncoder().encode(reputation) {
            UserDefaults.standard.set(data, forKey: "factionReputation")
        }
    }
    
    func reset() {
        reputation = FactionReputationState()
    }
}

// MARK: - Faction Bar View
struct FactionBarView: View {
    let faction: Faction
    let reputation: Int
    let compact: Bool
    
    init(faction: Faction, reputation: Int, compact: Bool = true) {
        self.faction = faction
        self.reputation = reputation
        self.compact = compact
    }
    
    var tier: ReputationTier {
        ReputationTier.fromReputation(reputation)
    }
    
    var body: some View {
        if compact {
            compactView
        } else {
            fullView
        }
    }
    
    var compactView: some View {
        VStack(spacing: 4) {
            Text(faction.icon)
                .font(.system(size: 16))
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 4)
                    
                    Capsule()
                        .fill(faction.color)
                        .frame(width: geometry.size.width * CGFloat(reputation) / 100, height: 4)
                }
            }
            .frame(height: 4)
            
            Text("\(reputation)")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: 50)
    }
    
    var fullView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(faction.icon)
                    .font(.system(size: 14))
                Text(faction.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                Spacer()
                Text(tier.name)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(faction.color)
                Text("(\(reputation))")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 3)
                        .fill(faction.color)
                        .frame(width: geometry.size.width * CGFloat(reputation) / 100, height: 6)
                    
                    // Tier markers
                    ForEach(ReputationTier.allCases.dropFirst(), id: \.rawValue) { tierMark in
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 1, height: 10)
                            .offset(x: geometry.size.width * CGFloat(tierMark.rawValue) / 100)
                    }
                }
            }
            .frame(height: 10)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(faction.color.opacity(0.1))
        )
    }
}

// MARK: - All Factions Overview
struct FactionsOverviewView: View {
    @ObservedObject var factions = FactionManager.shared
    let compact: Bool
    
    init(compact: Bool = true) {
        self.compact = compact
    }
    
    var body: some View {
        if compact {
            HStack(spacing: 8) {
                ForEach(Faction.allCases, id: \.self) { faction in
                    FactionBarView(
                        faction: faction,
                        reputation: factions.reputation[faction],
                        compact: true
                    )
                }
            }
        } else {
            VStack(spacing: 8) {
                ForEach(Faction.allCases, id: \.self) { faction in
                    FactionBarView(
                        faction: faction,
                        reputation: factions.reputation[faction],
                        compact: false
                    )
                }
            }
        }
    }
}

// MARK: - Reputation Change Animation
struct ReputationChangeView: View {
    let faction: Faction
    let amount: Int
    
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1
    
    var body: some View {
        HStack(spacing: 4) {
            Text(faction.icon)
                .font(.system(size: 14))
            Text(amount > 0 ? "+\(amount)" : "\(amount)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(amount > 0 ? .green : .red)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(faction.color.opacity(0.3))
        )
        .offset(y: offset)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                offset = -40
                opacity = 0
            }
        }
    }
}

// MARK: - Faction Required Badge
struct FactionRequiredBadge: View {
    let faction: Faction
    let requiredTier: ReputationTier
    let currentReputation: Int
    
    var hasAccess: Bool {
        currentReputation >= requiredTier.rawValue
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text(faction.icon)
                .font(.system(size: 10))
            Text(requiredTier.name)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(hasAccess ? faction.color : .gray)
            if !hasAccess {
                Image(systemName: "lock.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(hasAccess ? faction.color.opacity(0.2) : Color.gray.opacity(0.2))
        )
    }
}
