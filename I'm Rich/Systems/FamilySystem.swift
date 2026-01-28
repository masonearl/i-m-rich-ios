//
//  FamilySystem.swift
//  Life of Wealth
//
//  Dating, marriage, children with personalities, and family events
//

import SwiftUI
import Combine

// MARK: - Partner Personality
enum PartnerPersonality: String, Codable, CaseIterable {
    case supportive = "Supportive"
    case ambitious = "Ambitious"
    case freeSpirit = "Free Spirit"
    case traditional = "Traditional"
    
    var icon: String {
        switch self {
        case .supportive: return "🤗"
        case .ambitious: return "💪"
        case .freeSpirit: return "🦋"
        case .traditional: return "🏠"
        }
    }
    
    var description: String {
        switch self {
        case .supportive: return "Always there for you, boosts relationships"
        case .ambitious: return "Driven, dual income, less family time"
        case .freeSpirit: return "Spontaneous, loves experiences"
        case .traditional: return "Values stability and family above all"
        }
    }
    
    var wealthModifiers: WealthImpact {
        switch self {
        case .supportive: return WealthImpact(relationships: 5, health: 3)
        case .ambitious: return WealthImpact(financial: 8, relationships: -2)
        case .freeSpirit: return WealthImpact(financial: -3, experiences: 8)
        case .traditional: return WealthImpact(relationships: 8, legacy: 3)
        }
    }
}

// MARK: - Child Personality
enum ChildPersonality: String, Codable, CaseIterable {
    case overachiever = "Overachiever"
    case creative = "Creative"
    case rebellious = "Rebellious"
    case easygoing = "Easygoing"
    case athletic = "Athletic"
    
    var icon: String {
        switch self {
        case .overachiever: return "📚"
        case .creative: return "🎨"
        case .rebellious: return "🎸"
        case .easygoing: return "😊"
        case .athletic: return "⚽"
        }
    }
    
    var eventTypes: [String] {
        switch self {
        case .overachiever: return ["Science fair", "Honor roll", "College prep", "Scholarship"]
        case .creative: return ["Art show", "School play", "Music recital", "Portfolio review"]
        case .rebellious: return ["Principal's office", "Skipped class", "Bad grades", "Sneaking out"]
        case .easygoing: return ["Birthday party", "Field trip", "Sleepover", "Family dinner"]
        case .athletic: return ["Championship game", "Team tryouts", "Sports injury", "College scouts"]
        }
    }
}

// MARK: - Potential Partner
struct PotentialPartner: Identifiable, Codable {
    let id: String
    let name: String
    let personality: PartnerPersonality
    let careerFocus: CareerPath?
    let wealthPreference: WealthDimension
    let attractivenessBonus: Int  // Adds to relationship score appearance
    var relationshipLevel: Int = 0  // 0-100
    var isMarried: Bool = false
    var meetingAge: Int = 0  // Age when first met
    
    var canPropose: Bool {
        relationshipLevel >= 70
    }
    
    var incomeContribution: Double {
        guard isMarried, let career = careerFocus else { return 0 }
        // Partner contributes 50-80% of base salary depending on personality
        let baseMultiplier: Double
        switch personality {
        case .ambitious: baseMultiplier = 0.8
        case .supportive: baseMultiplier = 0.5
        case .freeSpirit: baseMultiplier = 0.4
        case .traditional: baseMultiplier = 0.3
        }
        return career.roles.first?.salary ?? 50000 * baseMultiplier
    }
}

// MARK: - Child
struct Child: Identifiable, Codable {
    let id: String
    let name: String
    let birthYear: Int
    var personality: ChildPersonality
    var relationshipWithParent: Int = 50  // 0-100
    var academicScore: Int = 50  // 0-100
    var happiness: Int = 70  // 0-100
    
    func age(currentYear: Int) -> Int {
        max(0, currentYear - birthYear)
    }
    
    func lifeStage(currentYear: Int) -> ChildLifeStage {
        let childAge = age(currentYear: currentYear)
        switch childAge {
        case 0..<5: return .toddler
        case 5..<13: return .child
        case 13..<18: return .teen
        case 18..<22: return .college
        default: return .adult
        }
    }
    
    var yearlyExpense: Double {
        // Children cost money!
        switch personality {
        case .overachiever: return 15000  // Tutors, prep courses
        case .creative: return 12000  // Art supplies, lessons
        case .athletic: return 14000  // Equipment, travel teams
        case .rebellious: return 10000  // Therapy, repairs
        case .easygoing: return 8000  // Basic needs
        }
    }
}

enum ChildLifeStage: String {
    case toddler = "Toddler"
    case child = "Child"
    case teen = "Teen"
    case college = "College"
    case adult = "Adult"
    
    var icon: String {
        switch self {
        case .toddler: return "👶"
        case .child: return "🧒"
        case .teen: return "🧑"
        case .college: return "🎓"
        case .adult: return "👨"
        }
    }
}

// MARK: - Family Event
struct FamilyEvent: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let choices: [FamilyEventChoice]
    let relatedMemberId: String?  // Child or partner ID
}

struct FamilyEventChoice: Identifiable, Codable {
    let id: String
    let text: String
    let wealthImpact: WealthImpact
    let energyCost: Int
    let relationshipImpact: Int  // On the related family member
    let cashCost: Double
}

// MARK: - Family State
struct FamilyState: Codable {
    var partner: PotentialPartner?
    var children: [Child] = []
    var datingPool: [PotentialPartner] = []
    var weddingYear: Int?
    var totalChildExpenses: Double = 0
    
    // NEW: Ready to Date system - player chooses when to start dating
    var isReadyToDate: Bool = false
    var hasSeenDatingIntro: Bool = false
    var currentlyDating: PotentialPartner? = nil  // Active dating partner
    var datesCompleted: Int = 0
    
    // 💎 Easter egg: Tiffany Tax
    var tiffanyTaxApplied: Bool = false
    
    var isMarried: Bool {
        partner?.isMarried == true
    }
    
    var hasChildren: Bool {
        !children.isEmpty
    }
    
    var familySize: Int {
        1 + (isMarried ? 1 : 0) + children.count
    }
    
    var canStartDating: Bool {
        !isMarried && isReadyToDate
    }
    
    var relationshipStatus: String {
        if isMarried {
            return "Married to \(partner?.name ?? "Partner")"
        } else if let dating = currentlyDating {
            return "Dating \(dating.name)"
        } else if isReadyToDate {
            return "Single & Ready to Mingle"
        } else {
            return "Focused on Career"
        }
    }
}

// MARK: - Family Manager
class FamilyManager: ObservableObject {
    static let shared = FamilyManager()
    
    @Published var state: FamilyState {
        didSet { save() }
    }
    
    @Published var currentEvent: FamilyEvent?
    @Published var showEventUI = false
    @Published var showDatingUI = false        // Show dating pool sheet
    @Published var showReadyToDatePrompt = false  // Initial "Ready to Date?" prompt
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: "familyState"),
           let decoded = try? JSONDecoder().decode(FamilyState.self, from: data) {
            self.state = decoded
        } else {
            self.state = FamilyState()
            generateDatingPool()
        }
    }
    
    // MARK: - Ready to Date System
    
    /// Player decides to start dating
    func setReadyToDate(_ ready: Bool) {
        state.isReadyToDate = ready
        if ready && state.datingPool.isEmpty {
            generateDatingPool()
        }
        if ready && !state.hasSeenDatingIntro {
            state.hasSeenDatingIntro = true
            NewsFeedManager.shared.addNews(
                category: .personal,
                headline: "💕 You're ready to date! Check out potential matches in your dating pool."
            )
        }
        save()
    }
    
    // MARK: - Dating Pool (Improved with interesting characters)
    func generateDatingPool() {
        // Create diverse, interesting potential partners
        let potentialPartners: [PotentialPartner] = [
            // Ambitious types
            PotentialPartner(id: "partner_startup", name: "Sam", personality: .ambitious, careerFocus: .tech, wealthPreference: .financial, attractivenessBonus: 15),
            PotentialPartner(id: "partner_lawyer", name: "Jordan", personality: .ambitious, careerFocus: .finance, wealthPreference: .legacy, attractivenessBonus: 12),
            PotentialPartner(id: "partner_doctor", name: "Morgan", personality: .supportive, careerFocus: nil, wealthPreference: .health, attractivenessBonus: 18),
            
            // Creative types
            PotentialPartner(id: "partner_artist", name: "Riley", personality: .freeSpirit, careerFocus: .creator, wealthPreference: .experiences, attractivenessBonus: 20),
            PotentialPartner(id: "partner_musician", name: "Avery", personality: .freeSpirit, careerFocus: .creator, wealthPreference: .relationships, attractivenessBonus: 16),
            
            // Supportive types
            PotentialPartner(id: "partner_teacher", name: "Taylor", personality: .supportive, careerFocus: nil, wealthPreference: .relationships, attractivenessBonus: 14),
            PotentialPartner(id: "partner_nurse", name: "Casey", personality: .supportive, careerFocus: nil, wealthPreference: .health, attractivenessBonus: 13),
            
            // Traditional types
            PotentialPartner(id: "partner_business", name: "Alex", personality: .traditional, careerFocus: .trades, wealthPreference: .legacy, attractivenessBonus: 11),
            PotentialPartner(id: "partner_family", name: "Quinn", personality: .traditional, careerFocus: nil, wealthPreference: .relationships, attractivenessBonus: 17),
            
            // Wild cards
            PotentialPartner(id: "partner_traveler", name: "Sage", personality: .freeSpirit, careerFocus: nil, wealthPreference: .experiences, attractivenessBonus: 19),
            PotentialPartner(id: "partner_entrepreneur", name: "Blake", personality: .ambitious, careerFocus: .tech, wealthPreference: .financial, attractivenessBonus: 14),
            PotentialPartner(id: "partner_athlete", name: "Drew", personality: .ambitious, careerFocus: nil, wealthPreference: .health, attractivenessBonus: 22),
            
            // 💎 Special easter egg partner - WARNING: Expensive taste!
            PotentialPartner(id: "partner_tiffany", name: "Tiffany", personality: .freeSpirit, careerFocus: nil, wealthPreference: .financial, attractivenessBonus: 25),
        ]
        
        // Shuffle and take 6 random partners
        state.datingPool = Array(potentialPartners.shuffled().prefix(6))
    }
    
    /// Refresh dating pool with new matches
    func refreshDatingPool() {
        generateDatingPool()
        NewsFeedManager.shared.addNews(
            category: .personal,
            headline: "💫 New matches available! Check out your dating pool."
        )
    }
    
    // MARK: - Dating Actions
    
    /// Get dating cost based on date type
    func getDateCost(fancy: Bool) -> Double {
        fancy ? 500 : 100
    }
    
    /// Convenience method to start dating a partner (uses current age from LifeCycleManager)
    func startDating(_ partner: PotentialPartner) {
        let currentAge = LifeCycleManager.shared.currentAge
        date(partner: partner, currentAge: currentAge)
    }
    
    /// Go on a date with a partner (costs money, builds relationship)
    func goOnDate(with partner: PotentialPartner, fancy: Bool, cash: inout Double) -> Bool {
        let cost = getDateCost(fancy: fancy)
        guard cash >= cost else { return false }
        guard state.isReadyToDate else { return false }
        
        cash -= cost
        
        // Update partner in pool
        if var updatedPartner = state.datingPool.first(where: { $0.id == partner.id }) {
            let relationshipGain = fancy ? 15 : 8
            updatedPartner.relationshipLevel = min(100, updatedPartner.relationshipLevel + relationshipGain)
            
            if updatedPartner.meetingAge == 0 {
                updatedPartner.meetingAge = LifeCycleManager.shared.currentAge
            }
            
            if let index = state.datingPool.firstIndex(where: { $0.id == partner.id }) {
                state.datingPool[index] = updatedPartner
            }
            
            // Set as currently dating if relationship high enough
            if updatedPartner.relationshipLevel >= 30 {
                state.currentlyDating = updatedPartner
            }
        }
        
        state.datesCompleted += 1
        
        // Apply wealth impact
        let experienceBonus = fancy ? 8 : 3
        WealthManager.shared.applyImpact(WealthImpact(relationships: 5, experiences: experienceBonus))
        
        save()
        return true
    }
    
    func date(partner: PotentialPartner, currentAge: Int) {
        guard var updatedPartner = state.datingPool.first(where: { $0.id == partner.id }) else { return }
        
        updatedPartner.relationshipLevel = min(100, updatedPartner.relationshipLevel + 10)
        if updatedPartner.meetingAge == 0 {
            updatedPartner.meetingAge = currentAge
        }
        
        if let index = state.datingPool.firstIndex(where: { $0.id == partner.id }) {
            state.datingPool[index] = updatedPartner
        }
        
        // Apply wealth impact
        WealthManager.shared.applyImpact(WealthImpact(relationships: 5, experiences: 3))
    }
    
    /// Break up with current dating partner
    func breakUp() {
        if let partner = state.currentlyDating {
            NewsFeedManager.shared.addNews(
                category: .personal,
                headline: "💔 You and \(partner.name) have gone separate ways."
            )
            state.currentlyDating = nil
            // Remove from dating pool too
            state.datingPool.removeAll { $0.id == partner.id }
            save()
        }
    }
    
    func propose(to partner: PotentialPartner, weddingBudget: Double, currentYear: Int) -> Bool {
        guard partner.canPropose else { return false }
        
        var married = partner
        married.isMarried = true
        state.partner = married
        state.weddingYear = currentYear
        
        // Remove from dating pool
        state.datingPool.removeAll { $0.id == partner.id }
        
        // Wedding affects wealth
        let impact = WealthImpact(
            relationships: 20,
            experiences: 15,
            legacy: 5
        )
        WealthManager.shared.applyImpact(impact)
        
        FeedbackCoordinator.shared.achievement()
        return true
    }
    
    /// 💎 EASTER EGG: Apply Tiffany Tax - called from GameState after proposal
    /// Returns the amount "lost" to Tiffany's expensive taste
    func applyTiffanyTax(game: GameState) -> Double {
        guard let partner = state.partner, partner.name.lowercased() == "tiffany" else {
            return 0
        }
        
        guard !state.tiffanyTaxApplied else { return 0 }  // Only apply once
        
        state.tiffanyTaxApplied = true
        
        // Calculate half of current wealth
        let cashLost = game.cash * 0.5
        
        // Reduce cash by half
        game.cash -= cashLost
        
        // Also reduce investments by half (she gets half in the prenup... wait, there was no prenup!)
        for i in 0..<game.investments.count {
            game.investments[i].amountInvested *= 0.5
            game.investments[i].unrealizedGains *= 0.5
        }
        
        // Calculate total loss
        let investmentLoss = game.totalInvestmentValue  // Already halved
        let totalLoss = cashLost + investmentLoss
        
        // Breaking news!
        NewsFeedManager.shared.addNews(
            category: .personal,
            headline: "💎 TIFFANY'S TASTE IS EXPENSIVE - Half your assets are now funding shopping sprees. Should've gotten a prenup!"
        )
        
        return totalLoss
    }
    
    /// Check if player married Tiffany
    var marriedTiffany: Bool {
        state.tiffanyTaxApplied
    }
    
    // MARK: - Children
    func haveChild(currentYear: Int) -> Child? {
        guard state.isMarried else { return nil }
        
        let childNames = ["Emma", "Liam", "Olivia", "Noah", "Ava", "Ethan", "Sophia", "Mason"]
        let child = Child(
            id: "child_\(state.children.count)",
            name: childNames.randomElement() ?? "Child",
            birthYear: currentYear,
            personality: ChildPersonality.allCases.randomElement() ?? .easygoing
        )
        
        state.children.append(child)
        
        // Having a child affects wealth
        let impact = WealthImpact(
            relationships: 15,
            experiences: 5,
            health: -10,
            legacy: 10
        )
        WealthManager.shared.applyImpact(impact)
        
        FeedbackCoordinator.shared.achievement()
        return child
    }
    
    // MARK: - Family Events
    func generateFamilyEvent(currentYear: Int) -> FamilyEvent? {
        guard state.isMarried || state.hasChildren else { return nil }
        
        // Partner events
        if let partner = state.partner, Double.random(in: 0...1) < 0.4 {
            return generatePartnerEvent(partner)
        }
        
        // Child events
        if let child = state.children.randomElement() {
            return generateChildEvent(child, currentYear: currentYear)
        }
        
        return nil
    }
    
    private func generatePartnerEvent(_ partner: PotentialPartner) -> FamilyEvent {
        let events: [(String, String, String, [FamilyEventChoice])] = [
            (
                "Partner's Job Offer",
                "\(partner.name) got a job offer in another city. It pays well but means less time together.",
                "💼",
                [
                    FamilyEventChoice(id: "support", text: "Support their career", wealthImpact: WealthImpact(financial: 10, relationships: -5), energyCost: 0, relationshipImpact: 15, cashCost: 0),
                    FamilyEventChoice(id: "stay", text: "Ask them to stay", wealthImpact: WealthImpact(relationships: 5), energyCost: 0, relationshipImpact: -10, cashCost: 0)
                ]
            ),
            (
                "Anniversary Planning",
                "Your anniversary is coming up. How do you want to celebrate?",
                "💝",
                [
                    FamilyEventChoice(id: "lavish", text: "Lavish vacation ($10K)", wealthImpact: WealthImpact(relationships: 15, experiences: 20), energyCost: 30, relationshipImpact: 20, cashCost: 10000),
                    FamilyEventChoice(id: "simple", text: "Quiet dinner at home", wealthImpact: WealthImpact(relationships: 8, health: 5), energyCost: 10, relationshipImpact: 5, cashCost: 200),
                    FamilyEventChoice(id: "forget", text: "Too busy with work", wealthImpact: WealthImpact(financial: 5, relationships: -15), energyCost: 0, relationshipImpact: -25, cashCost: 0)
                ]
            )
        ]
        
        let event = events.randomElement()!
        return FamilyEvent(
            id: UUID().uuidString,
            title: event.0,
            description: event.1,
            icon: event.2,
            choices: event.3,
            relatedMemberId: partner.id
        )
    }
    
    private func generateChildEvent(_ child: Child, currentYear: Int) -> FamilyEvent {
        let stage = child.lifeStage(currentYear: currentYear)
        
        switch stage {
        case .toddler, .child:
            return FamilyEvent(
                id: UUID().uuidString,
                title: "\(child.name)'s School Event",
                description: "\(child.name) has a \(child.personality.eventTypes.randomElement() ?? "school event"). Will you attend?",
                icon: "🏫",
                choices: [
                    FamilyEventChoice(id: "attend", text: "Attend and participate", wealthImpact: WealthImpact(relationships: 10), energyCost: 15, relationshipImpact: 15, cashCost: 0),
                    FamilyEventChoice(id: "skip", text: "Send a gift instead", wealthImpact: WealthImpact(financial: -2), energyCost: 0, relationshipImpact: -10, cashCost: 100),
                    FamilyEventChoice(id: "work", text: "Can't make it - work", wealthImpact: WealthImpact(financial: 5, relationships: -8), energyCost: 0, relationshipImpact: -20, cashCost: 0)
                ],
                relatedMemberId: child.id
            )
        case .teen:
            return FamilyEvent(
                id: UUID().uuidString,
                title: "\(child.name) Needs Help",
                description: "Your teen is struggling with \(child.personality == .rebellious ? "behavior issues" : "big decisions").",
                icon: "🧑",
                choices: [
                    FamilyEventChoice(id: "time", text: "Take time to talk", wealthImpact: WealthImpact(relationships: 12, health: 3), energyCost: 20, relationshipImpact: 20, cashCost: 0),
                    FamilyEventChoice(id: "therapy", text: "Get professional help", wealthImpact: WealthImpact(relationships: 5, health: 5), energyCost: 5, relationshipImpact: 10, cashCost: 5000),
                    FamilyEventChoice(id: "ignore", text: "They'll figure it out", wealthImpact: WealthImpact(health: 2), energyCost: 0, relationshipImpact: -15, cashCost: 0)
                ],
                relatedMemberId: child.id
            )
        case .college:
            return FamilyEvent(
                id: UUID().uuidString,
                title: "\(child.name)'s College",
                description: "\(child.name) got into their dream school! But it's expensive.",
                icon: "🎓",
                choices: [
                    FamilyEventChoice(id: "full", text: "Pay full tuition ($80K)", wealthImpact: WealthImpact(relationships: 15, legacy: 10), energyCost: 0, relationshipImpact: 25, cashCost: 80000),
                    FamilyEventChoice(id: "partial", text: "Help with half", wealthImpact: WealthImpact(relationships: 8, legacy: 5), energyCost: 0, relationshipImpact: 10, cashCost: 40000),
                    FamilyEventChoice(id: "loans", text: "They can take loans", wealthImpact: WealthImpact(relationships: -5), energyCost: 0, relationshipImpact: -15, cashCost: 0)
                ],
                relatedMemberId: child.id
            )
        case .adult:
            return FamilyEvent(
                id: UUID().uuidString,
                title: "\(child.name)'s Wedding",
                description: "Your child is getting married! They're asking for help.",
                icon: "💒",
                choices: [
                    FamilyEventChoice(id: "dream", text: "Dream wedding ($50K)", wealthImpact: WealthImpact(relationships: 20, experiences: 10, legacy: 5), energyCost: 25, relationshipImpact: 30, cashCost: 50000),
                    FamilyEventChoice(id: "modest", text: "Contribute $10K", wealthImpact: WealthImpact(relationships: 10, experiences: 5), energyCost: 15, relationshipImpact: 10, cashCost: 10000),
                    FamilyEventChoice(id: "none", text: "They're adults now", wealthImpact: WealthImpact(relationships: -10), energyCost: 0, relationshipImpact: -20, cashCost: 0)
                ],
                relatedMemberId: child.id
            )
        }
    }
    
    func handleEventChoice(_ choice: FamilyEventChoice, event: FamilyEvent) {
        // Apply wealth impact
        WealthManager.shared.applyImpact(choice.wealthImpact)
        
        // Apply relationship impact to family member
        if let memberId = event.relatedMemberId {
            if state.partner?.id == memberId {
                state.partner?.relationshipLevel = max(0, min(100, (state.partner?.relationshipLevel ?? 50) + choice.relationshipImpact))
            } else if let childIndex = state.children.firstIndex(where: { $0.id == memberId }) {
                state.children[childIndex].relationshipWithParent = max(0, min(100, state.children[childIndex].relationshipWithParent + choice.relationshipImpact))
            }
        }
        
        // Consume energy
        if choice.energyCost > 0 {
            _ = EnergyManager.shared.consumeEnergy(choice.energyCost)
        }
        
        currentEvent = nil
        showEventUI = false
    }
    
    // MARK: - Yearly Processing
    func processYear(currentYear: Int) {
        // Calculate child expenses
        var totalExpenses: Double = 0
        for child in state.children {
            let stage = child.lifeStage(currentYear: currentYear)
            if stage != .adult {
                totalExpenses += child.yearlyExpense
            }
        }
        state.totalChildExpenses = totalExpenses
        
        // Partner income contribution
        if let partner = state.partner, partner.isMarried {
            // Partner's personality affects yearly wealth
            WealthManager.shared.applyImpact(partner.personality.wealthModifiers)
        }
        
        // Random family event
        if Double.random(in: 0...1) < 0.3 {
            if let event = generateFamilyEvent(currentYear: currentYear) {
                currentEvent = event
                showEventUI = true
            }
        }
    }
    
    // MARK: - Persistence
    private func save() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: "familyState")
        }
    }
    
    func reset() {
        state = FamilyState()
        generateDatingPool()
    }
}

// MARK: - Family Panel View
struct FamilyPanelView: View {
    @ObservedObject var family = FamilyManager.shared
    @ObservedObject var lifecycle = LifeCycleManager.shared
    
    let accentColor = Color(red: 0.4, green: 0.7, blue: 0.4)
    
    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("👨‍👩‍👧‍👦")
                    .font(.system(size: 14))
                Text("FAMILY")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.gray)
                    .tracking(1.5)
                Spacer()
                Text("Size: \(family.state.familySize)")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
            
            if let partner = family.state.partner {
                partnerView(partner)
            } else if lifecycle.currentAge >= 25 {
                datingView
            }
            
            if !family.state.children.isEmpty {
                childrenView
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.03))
        )
    }
    
    func partnerView(_ partner: PotentialPartner) -> some View {
        HStack(spacing: 10) {
            Text(partner.personality.icon)
                .font(.system(size: 20))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(partner.name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                Text(partner.personality.rawValue)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if partner.isMarried {
                Text("💍")
                    .font(.system(size: 14))
            }
            
            // Relationship bar
            VStack(spacing: 2) {
                Text("❤️ \(partner.relationshipLevel)")
                    .font(.system(size: 9))
                    .foregroundColor(.red)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.1))
        )
    }
    
    var datingView: some View {
        VStack(spacing: 6) {
            Text("Ready to date?")
                .font(.system(size: 11))
                .foregroundColor(.gray)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(family.state.datingPool) { partner in
                        datingCard(partner)
                    }
                }
            }
        }
    }
    
    func datingCard(_ partner: PotentialPartner) -> some View {
        Button(action: {
            family.startDating(partner)
            HapticManager.shared.mediumTap()
        }) {
            VStack(spacing: 4) {
                Text(partner.personality.icon)
                    .font(.system(size: 20))
                Text(partner.name)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                
                if partner.relationshipLevel > 0 {
                    Text("❤️\(partner.relationshipLevel)")
                        .font(.system(size: 8))
                        .foregroundColor(.red)
                } else {
                    Text("Date")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(accentColor)
                }
            }
            .frame(width: 70)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.pink.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(accentColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var childrenView: some View {
        VStack(spacing: 6) {
            ForEach(family.state.children) { child in
                childRow(child)
            }
        }
    }
    
    func childRow(_ child: Child) -> some View {
        let stage = child.lifeStage(currentYear: lifecycle.gameYearsPassed + lifecycle.startingAge)
        
        return HStack(spacing: 8) {
            Text(stage.icon)
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(child.name)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                HStack(spacing: 4) {
                    Text("Age \(child.age(currentYear: lifecycle.gameYearsPassed + lifecycle.startingAge))")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                    Text(child.personality.icon)
                        .font(.system(size: 8))
                }
            }
            
            Spacer()
            
            Text("❤️\(child.relationshipWithParent)")
                .font(.system(size: 9))
                .foregroundColor(.red)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.blue.opacity(0.1))
        )
    }
}

// MARK: - Family Event View
struct FamilyEventAlertView: View {
    let event: FamilyEvent
    let onChoice: (FamilyEventChoice) -> Void
    
    @ObservedObject var energy = EnergyManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            Text(event.icon)
                .font(.system(size: 50))
            
            Text(event.title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text(event.description)
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 10) {
                ForEach(event.choices) { choice in
                    choiceButton(choice)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    func choiceButton(_ choice: FamilyEventChoice) -> some View {
        let canAffordEnergy = energy.state.currentEnergy >= choice.energyCost
        
        return Button(action: { onChoice(choice) }) {
            VStack(spacing: 4) {
                Text(choice.text)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(canAffordEnergy ? .white : .gray)
                
                HStack(spacing: 8) {
                    if !choice.wealthImpact.isEmpty {
                        ImpactPreviewView(impact: choice.wealthImpact)
                    }
                    if choice.energyCost > 0 {
                        HStack(spacing: 2) {
                            Text("⚡")
                                .font(.system(size: 9))
                            Text("\(choice.energyCost)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(canAffordEnergy ? .yellow : .red)
                        }
                    }
                    if choice.cashCost > 0 {
                        Text("-$\(Int(choice.cashCost / 1000))K")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.orange)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(canAffordEnergy ? Color.white.opacity(0.1) : Color.gray.opacity(0.1))
            )
        }
        .disabled(!canAffordEnergy)
    }
}
