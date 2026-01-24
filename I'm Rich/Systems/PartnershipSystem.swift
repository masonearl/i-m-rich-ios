//
//  PartnershipSystem.swift
//  Life of Wealth
//
//  Strategic partnerships with tech leaders that shape your future
//

import SwiftUI
import Combine

// MARK: - Partnership Type
enum PartnershipType: String, Codable, CaseIterable {
    case ai = "AI/Tech"
    case finance = "Finance"
    case manufacturing = "Manufacturing"
    case media = "Media"
    case space = "Space"
    case crypto = "Crypto"
    
    var icon: String {
        switch self {
        case .ai: return "🤖"
        case .finance: return "🏦"
        case .manufacturing: return "🏭"
        case .media: return "📺"
        case .space: return "🚀"
        case .crypto: return "₿"
        }
    }
}

// MARK: - Partnership Option
struct PartnershipOption: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let upfrontCost: Double
    let equityGiven: Double  // Percentage 0-1
    let ongoingCost: Double  // Per year
    let benefits: [PartnershipBenefit]
    let risks: [PartnershipRisk]
    let exclusiveWith: [String]  // Partnership IDs this conflicts with
}

struct PartnershipBenefit: Codable {
    let description: String
    let investmentBonus: Double  // Multiplier for specific investments
    let investmentCategory: String  // Which investments benefit
    let statusBonus: Int
    let factionBonus: (faction: String, amount: Int)?
    
    enum CodingKeys: String, CodingKey {
        case description, investmentBonus, investmentCategory, statusBonus, factionBonusFaction, factionBonusAmount
    }
    
    init(description: String, investmentBonus: Double = 0, investmentCategory: String = "", statusBonus: Int = 0, factionBonus: (faction: String, amount: Int)? = nil) {
        self.description = description
        self.investmentBonus = investmentBonus
        self.investmentCategory = investmentCategory
        self.statusBonus = statusBonus
        self.factionBonus = factionBonus
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        description = try container.decode(String.self, forKey: .description)
        investmentBonus = try container.decode(Double.self, forKey: .investmentBonus)
        investmentCategory = try container.decode(String.self, forKey: .investmentCategory)
        statusBonus = try container.decode(Int.self, forKey: .statusBonus)
        if let faction = try container.decodeIfPresent(String.self, forKey: .factionBonusFaction),
           let amount = try container.decodeIfPresent(Int.self, forKey: .factionBonusAmount) {
            factionBonus = (faction, amount)
        } else {
            factionBonus = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(description, forKey: .description)
        try container.encode(investmentBonus, forKey: .investmentBonus)
        try container.encode(investmentCategory, forKey: .investmentCategory)
        try container.encode(statusBonus, forKey: .statusBonus)
        try container.encodeIfPresent(factionBonus?.faction, forKey: .factionBonusFaction)
        try container.encodeIfPresent(factionBonus?.amount, forKey: .factionBonusAmount)
    }
}

struct PartnershipRisk: Codable {
    let description: String
    let investmentPenalty: Double  // Negative multiplier
    let investmentCategory: String
    let factionPenalty: (faction: String, amount: Int)?
    
    enum CodingKeys: String, CodingKey {
        case description, investmentPenalty, investmentCategory, factionPenaltyFaction, factionPenaltyAmount
    }
    
    init(description: String, investmentPenalty: Double = 0, investmentCategory: String = "", factionPenalty: (faction: String, amount: Int)? = nil) {
        self.description = description
        self.investmentPenalty = investmentPenalty
        self.investmentCategory = investmentCategory
        self.factionPenalty = factionPenalty
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        description = try container.decode(String.self, forKey: .description)
        investmentPenalty = try container.decode(Double.self, forKey: .investmentPenalty)
        investmentCategory = try container.decode(String.self, forKey: .investmentCategory)
        if let faction = try container.decodeIfPresent(String.self, forKey: .factionPenaltyFaction),
           let amount = try container.decodeIfPresent(Int.self, forKey: .factionPenaltyAmount) {
            factionPenalty = (faction, amount)
        } else {
            factionPenalty = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(description, forKey: .description)
        try container.encode(investmentPenalty, forKey: .investmentPenalty)
        try container.encode(investmentCategory, forKey: .investmentCategory)
        try container.encodeIfPresent(factionPenalty?.faction, forKey: .factionPenaltyFaction)
        try container.encodeIfPresent(factionPenalty?.amount, forKey: .factionPenaltyAmount)
    }
}

// MARK: - Active Partnership
struct ActivePartnership: Identifiable, Codable {
    let id: String
    let contactId: String
    let contactName: String
    let partnershipType: PartnershipType
    let optionChosen: PartnershipOption
    let startDate: Date
    var yearsActive: Int = 0
    
    var totalCostPaid: Double {
        optionChosen.upfrontCost + (optionChosen.ongoingCost * Double(yearsActive))
    }
}

// MARK: - Partnership Offer (When meeting a contact)
struct PartnershipOffer: Identifiable {
    let id: String
    let contactId: String
    let contactName: String
    let contactIcon: String
    let partnershipType: PartnershipType
    let options: [PartnershipOption]
    let declineConsequence: String
    let factionPenaltyOnDecline: (faction: String, amount: Int)?
}

// MARK: - All Partnership Offers
let allPartnershipOffers: [PartnershipOffer] = [
    // Sam Altman - OpenAI
    PartnershipOffer(
        id: "openai_partnership",
        contactId: "sam_altman",
        contactName: "Sam Altman",
        contactIcon: "🤖",
        partnershipType: .ai,
        options: [
            PartnershipOption(
                id: "openai_full",
                name: "AI Infrastructure Deal",
                description: "Full integration with OpenAI's API and early access to GPT models",
                upfrontCost: 50_000_000,
                equityGiven: 0.10,
                ongoingCost: 10_000_000,
                benefits: [
                    PartnershipBenefit(description: "+80% returns on AI investments", investmentBonus: 0.80, investmentCategory: "ai"),
                    PartnershipBenefit(description: "+50 Startup reputation", factionBonus: ("startup", 50))
                ],
                risks: [
                    PartnershipRisk(description: "-20% non-tech investment returns", investmentPenalty: -0.20, investmentCategory: "traditional"),
                    PartnershipRisk(description: "Locked into AI focus", factionPenalty: ("oldMoney", -25))
                ],
                exclusiveWith: ["anthropic_full", "deepmind_full"]
            ),
            PartnershipOption(
                id: "openai_advisory",
                name: "Advisory Relationship",
                description: "Sam joins your advisory board with occasional guidance",
                upfrontCost: 5_000_000,
                equityGiven: 0.01,
                ongoingCost: 1_000_000,
                benefits: [
                    PartnershipBenefit(description: "+15% returns on tech investments", investmentBonus: 0.15, investmentCategory: "tech"),
                    PartnershipBenefit(description: "+20 Startup reputation", factionBonus: ("startup", 20))
                ],
                risks: [],
                exclusiveWith: []
            )
        ],
        declineConsequence: "Declining may close AI partnership doors",
        factionPenaltyOnDecline: ("startup", -25)
    ),
    
    // Demis Hassabis - DeepMind
    PartnershipOffer(
        id: "deepmind_partnership",
        contactId: "demis_hassabis",
        contactName: "Demis Hassabis",
        contactIcon: "🧠",
        partnershipType: .ai,
        options: [
            PartnershipOption(
                id: "deepmind_full",
                name: "Robotics & AGI Venture",
                description: "Joint venture in robotics and artificial general intelligence",
                upfrontCost: 100_000_000,
                equityGiven: 0.15,
                ongoingCost: 25_000_000,
                benefits: [
                    PartnershipBenefit(description: "+100% returns on AI & robotics", investmentBonus: 1.0, investmentCategory: "ai"),
                    PartnershipBenefit(description: "Access to breakthrough tech", statusBonus: 500)
                ],
                risks: [
                    PartnershipRisk(description: "High capital requirements", investmentPenalty: 0, investmentCategory: ""),
                    PartnershipRisk(description: "Regulatory scrutiny", factionPenalty: ("corporate", -30))
                ],
                exclusiveWith: ["openai_full"]
            ),
            PartnershipOption(
                id: "deepmind_research",
                name: "Research Sponsorship",
                description: "Fund DeepMind research in exchange for IP rights",
                upfrontCost: 25_000_000,
                equityGiven: 0.0,
                ongoingCost: 5_000_000,
                benefits: [
                    PartnershipBenefit(description: "+30% AI investment returns", investmentBonus: 0.30, investmentCategory: "ai"),
                    PartnershipBenefit(description: "First access to patents", statusBonus: 200)
                ],
                risks: [],
                exclusiveWith: []
            )
        ],
        declineConsequence: "Miss the AGI revolution",
        factionPenaltyOnDecline: ("startup", -20)
    ),
    
    // Jensen Huang - NVIDIA
    PartnershipOffer(
        id: "nvidia_partnership",
        contactId: "jensen_huang",
        contactName: "Jensen Huang",
        contactIcon: "🎮",
        partnershipType: .manufacturing,
        options: [
            PartnershipOption(
                id: "nvidia_supply",
                name: "GPU Supply Agreement",
                description: "Priority access to NVIDIA's latest chips for your ventures",
                upfrontCost: 75_000_000,
                equityGiven: 0.05,
                ongoingCost: 15_000_000,
                benefits: [
                    PartnershipBenefit(description: "+50% data center investment returns", investmentBonus: 0.50, investmentCategory: "tech"),
                    PartnershipBenefit(description: "Critical supply chain advantage", statusBonus: 300)
                ],
                risks: [
                    PartnershipRisk(description: "Tied to NVIDIA's roadmap")
                ],
                exclusiveWith: []
            )
        ],
        declineConsequence: "GPU allocation goes to competitors",
        factionPenaltyOnDecline: ("startup", -15)
    ),
    
    // Elon Musk
    PartnershipOffer(
        id: "elon_partnership",
        contactId: "elon",
        contactName: "Elon Musk",
        contactIcon: "🚀",
        partnershipType: .space,
        options: [
            PartnershipOption(
                id: "spacex_investor",
                name: "SpaceX Strategic Investment",
                description: "Major investment position in SpaceX with board observer seat",
                upfrontCost: 500_000_000,
                equityGiven: 0.02,
                ongoingCost: 0,
                benefits: [
                    PartnershipBenefit(description: "+200% space venture returns", investmentBonus: 2.0, investmentCategory: "aerospace"),
                    PartnershipBenefit(description: "Starlink revenue share", statusBonus: 1000),
                    PartnershipBenefit(description: "+75 Startup reputation", factionBonus: ("startup", 75))
                ],
                risks: [
                    PartnershipRisk(description: "Elon's tweets may cause volatility", investmentPenalty: -0.10, investmentCategory: "all"),
                    PartnershipRisk(description: "Extreme capital lockup")
                ],
                exclusiveWith: []
            ),
            PartnershipOption(
                id: "tesla_partnership",
                name: "Tesla Manufacturing Deal",
                description: "Partnership for EV battery technology",
                upfrontCost: 200_000_000,
                equityGiven: 0.0,
                ongoingCost: 20_000_000,
                benefits: [
                    PartnershipBenefit(description: "+60% energy investment returns", investmentBonus: 0.60, investmentCategory: "energy"),
                    PartnershipBenefit(description: "EV market access", statusBonus: 400)
                ],
                risks: [],
                exclusiveWith: []
            )
        ],
        declineConsequence: "Elon moves on - opportunity gone forever",
        factionPenaltyOnDecline: ("startup", -50)
    ),
    
    // Warren Buffett
    PartnershipOffer(
        id: "buffett_partnership",
        contactId: "warren_buffett",
        contactName: "Warren Buffett",
        contactIcon: "📈",
        partnershipType: .finance,
        options: [
            PartnershipOption(
                id: "berkshire_mentorship",
                name: "Value Investing Mentorship",
                description: "Warren personally mentors you in value investing",
                upfrontCost: 10_000_000,
                equityGiven: 0.0,
                ongoingCost: 0,
                benefits: [
                    PartnershipBenefit(description: "+40% all investment returns", investmentBonus: 0.40, investmentCategory: "all"),
                    PartnershipBenefit(description: "+100 Old Money reputation", factionBonus: ("oldMoney", 100)),
                    PartnershipBenefit(description: "Access to Berkshire deal flow", statusBonus: 750)
                ],
                risks: [
                    PartnershipRisk(description: "Must avoid 'speculative' investments", investmentPenalty: -0.50, investmentCategory: "crypto"),
                    PartnershipRisk(description: "-30 Startup reputation", factionPenalty: ("startup", -30))
                ],
                exclusiveWith: []
            )
        ],
        declineConsequence: "The Oracle rarely offers twice",
        factionPenaltyOnDecline: ("oldMoney", -40)
    ),
    
    // Jamie Dimon
    PartnershipOffer(
        id: "jpmorgan_partnership",
        contactId: "jamie_dimon",
        contactName: "Jamie Dimon",
        contactIcon: "🏦",
        partnershipType: .finance,
        options: [
            PartnershipOption(
                id: "jpmorgan_banking",
                name: "Private Banking Relationship",
                description: "JPMorgan becomes your exclusive private bank",
                upfrontCost: 0,
                equityGiven: 0.0,
                ongoingCost: 5_000_000,
                benefits: [
                    PartnershipBenefit(description: "0.5% lower interest on all loans", investmentBonus: 0.0, investmentCategory: ""),
                    PartnershipBenefit(description: "Unlimited credit line", statusBonus: 500),
                    PartnershipBenefit(description: "+50 Corporate reputation", factionBonus: ("corporate", 50))
                ],
                risks: [],
                exclusiveWith: []
            ),
            PartnershipOption(
                id: "jpmorgan_ipo",
                name: "IPO Partnership",
                description: "JPMorgan leads your company's IPO when ready",
                upfrontCost: 25_000_000,
                equityGiven: 0.03,
                ongoingCost: 0,
                benefits: [
                    PartnershipBenefit(description: "Premium IPO valuation", statusBonus: 1000),
                    PartnershipBenefit(description: "Wall Street credibility", factionBonus: ("corporate", 75))
                ],
                risks: [
                    PartnershipRisk(description: "Must maintain profitability metrics")
                ],
                exclusiveWith: []
            )
        ],
        declineConsequence: "Banking options become limited",
        factionPenaltyOnDecline: ("corporate", -30)
    )
]

// MARK: - Partnership Manager
class PartnershipManager: ObservableObject {
    static let shared = PartnershipManager()
    
    @Published var activePartnerships: [ActivePartnership] = [] {
        didSet { save() }
    }
    @Published var declinedOffers: [String] = [] {
        didSet { save() }
    }
    @Published var currentOffer: PartnershipOffer?
    @Published var showPartnershipOffer = false
    
    var hasAIPartnership: Bool {
        activePartnerships.contains { $0.partnershipType == .ai }
    }
    
    var totalEquityGiven: Double {
        activePartnerships.reduce(0) { $0 + $1.optionChosen.equityGiven }
    }
    
    var annualPartnershipCosts: Double {
        activePartnerships.reduce(0) { $0 + $1.optionChosen.ongoingCost }
    }
    
    private init() {
        load()
    }
    
    // MARK: - Check for Partnership Offer
    func checkForPartnershipOffer(contactId: String) -> PartnershipOffer? {
        // Don't offer if already declined or have partnership
        if declinedOffers.contains(contactId) { return nil }
        if activePartnerships.contains(where: { $0.contactId == contactId }) { return nil }
        
        return allPartnershipOffers.first { $0.contactId == contactId }
    }
    
    // MARK: - Present Offer
    func presentOffer(_ offer: PartnershipOffer) {
        currentOffer = offer
        showPartnershipOffer = true
    }
    
    // MARK: - Accept Partnership
    func acceptPartnership(option: PartnershipOption, from offer: PartnershipOffer, game: GameState) -> Bool {
        // Check if can afford
        guard game.cash >= option.upfrontCost else { return false }
        
        // Check exclusivity
        for excludedId in option.exclusiveWith {
            if activePartnerships.contains(where: { $0.optionChosen.id == excludedId }) {
                return false
            }
        }
        
        // Pay upfront cost
        game.cash -= option.upfrontCost
        
        // Create partnership
        let partnership = ActivePartnership(
            id: UUID().uuidString,
            contactId: offer.contactId,
            contactName: offer.contactName,
            partnershipType: offer.partnershipType,
            optionChosen: option,
            startDate: Date()
        )
        
        activePartnerships.append(partnership)
        
        // Apply immediate benefits
        for benefit in option.benefits {
            game.statusPoints += benefit.statusBonus
            if let factionBonus = benefit.factionBonus {
                FactionManager.shared.modifyReputation(
                    Faction(rawValue: factionBonus.faction.capitalized) ?? .startup,
                    by: factionBonus.amount
                )
            }
        }
        
        // Apply immediate risks
        for risk in option.risks {
            if let factionPenalty = risk.factionPenalty {
                FactionManager.shared.modifyReputation(
                    Faction(rawValue: factionPenalty.faction.capitalized) ?? .startup,
                    by: factionPenalty.amount
                )
            }
        }
        
        currentOffer = nil
        showPartnershipOffer = false
        
        FeedbackCoordinator.shared.achievementUnlock()
        return true
    }
    
    // MARK: - Decline Partnership
    func declinePartnership(offer: PartnershipOffer) {
        declinedOffers.append(offer.contactId)
        
        // Apply decline penalty
        if let penalty = offer.factionPenaltyOnDecline {
            FactionManager.shared.modifyReputation(
                Faction(rawValue: penalty.faction.capitalized) ?? .startup,
                by: penalty.amount
            )
        }
        
        currentOffer = nil
        showPartnershipOffer = false
    }
    
    // MARK: - Get Investment Bonus
    func getInvestmentBonus(for category: String) -> Double {
        var bonus = 0.0
        for partnership in activePartnerships {
            for benefit in partnership.optionChosen.benefits {
                if benefit.investmentCategory == category || benefit.investmentCategory == "all" {
                    bonus += benefit.investmentBonus
                }
            }
            for risk in partnership.optionChosen.risks {
                if risk.investmentCategory == category || risk.investmentCategory == "all" {
                    bonus += risk.investmentPenalty  // This is negative
                }
            }
        }
        return bonus
    }
    
    // MARK: - Yearly Update
    func processYearlyPartnershipCosts(game: GameState) {
        for i in 0..<activePartnerships.count {
            activePartnerships[i].yearsActive += 1
            let cost = activePartnerships[i].optionChosen.ongoingCost
            if cost > 0 {
                game.cash -= cost
            }
        }
    }
    
    // MARK: - Persistence
    private func save() {
        if let data = try? JSONEncoder().encode(activePartnerships) {
            UserDefaults.standard.set(data, forKey: "activePartnerships")
        }
        UserDefaults.standard.set(declinedOffers, forKey: "declinedPartnershipOffers")
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: "activePartnerships"),
           let decoded = try? JSONDecoder().decode([ActivePartnership].self, from: data) {
            self.activePartnerships = decoded
        }
        if let declined = UserDefaults.standard.array(forKey: "declinedPartnershipOffers") as? [String] {
            self.declinedOffers = declined
        }
    }
    
    func reset() {
        activePartnerships = []
        declinedOffers = []
        currentOffer = nil
    }
}

// MARK: - Partnership Offer View
struct PartnershipOfferView: View {
    let offer: PartnershipOffer
    @ObservedObject var game: GameState
    @ObservedObject var partnerships = PartnershipManager.shared
    
    @State private var selectedOption: PartnershipOption?
    
    let accentColor = Color(red: 0.4, green: 0.7, blue: 0.4)
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Text(offer.contactIcon)
                            .font(.system(size: 60))
                        
                        Text("PARTNERSHIP OPPORTUNITY")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.purple)
                            .tracking(2)
                        
                        Text(offer.contactName)
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.white)
                        
                        Text(offer.partnershipType.rawValue)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 40)
                    
                    // Options
                    VStack(spacing: 16) {
                        ForEach(offer.options) { option in
                            optionCard(option)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        if let selected = selectedOption {
                            Button(action: {
                                _ = partnerships.acceptPartnership(option: selected, from: offer, game: game)
                            }) {
                                HStack {
                                    Text("Accept: \(selected.name)")
                                        .font(.system(size: 16, weight: .bold))
                                    Spacer()
                                    Text("-\(game.formatCompact(selected.upfrontCost))")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .foregroundColor(.black)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(game.cash >= selected.upfrontCost ? accentColor : Color.gray)
                                )
                            }
                            .disabled(game.cash < selected.upfrontCost)
                        }
                        
                        Button(action: {
                            partnerships.declinePartnership(offer: offer)
                        }) {
                            VStack(spacing: 4) {
                                Text("Decline")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.red)
                                Text(offer.declineConsequence)
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red.opacity(0.1))
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    func optionCard(_ option: PartnershipOption) -> some View {
        let isSelected = selectedOption?.id == option.id
        let canAfford = game.cash >= option.upfrontCost
        
        return Button(action: {
            selectedOption = option
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(option.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(accentColor)
                    }
                }
                
                Text(option.description)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
                
                // Costs
                HStack(spacing: 16) {
                    if option.upfrontCost > 0 {
                        VStack(alignment: .leading) {
                            Text("Upfront")
                                .font(.system(size: 9))
                                .foregroundColor(.gray)
                            Text(game.formatCompact(option.upfrontCost))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(canAfford ? .white : .red)
                        }
                    }
                    if option.equityGiven > 0 {
                        VStack(alignment: .leading) {
                            Text("Equity")
                                .font(.system(size: 9))
                                .foregroundColor(.gray)
                            Text("\(Int(option.equityGiven * 100))%")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.orange)
                        }
                    }
                    if option.ongoingCost > 0 {
                        VStack(alignment: .leading) {
                            Text("Yearly")
                                .font(.system(size: 9))
                                .foregroundColor(.gray)
                            Text(game.formatCompact(option.ongoingCost))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.yellow)
                        }
                    }
                }
                
                // Benefits
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(option.benefits.indices, id: \.self) { i in
                        HStack(spacing: 4) {
                            Text("+")
                                .foregroundColor(.green)
                            Text(option.benefits[i].description)
                                .font(.system(size: 11))
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // Risks
                if !option.risks.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(option.risks.indices, id: \.self) { i in
                            HStack(spacing: 4) {
                                Text("-")
                                    .foregroundColor(.red)
                                Text(option.risks[i].description)
                                    .font(.system(size: 11))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? accentColor.opacity(0.15) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? accentColor : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
    }
}
