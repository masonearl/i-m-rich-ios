//
//  MentorsAndLifeEvents.swift
//  I'm Rich
//
//  Mentor system and random life events
//

import SwiftUI
import Combine

// MARK: - Mentor
struct Mentor: Identifiable, Codable {
    let id: String
    let name: String
    let title: String
    let icon: String
    let phaseUnlock: Int
    let bonus: MentorBonus
    let quotes: [String]
    let backstory: String
    var unlocked: Bool = false
    var selected: Bool = false
    
    enum MentorBonus: Codable {
        case savingsBonus(Double)
        case stockBonus(Double)
        case realEstateBonus(Double)
        case startupBonus(Double)
        case tapBonus(Double)
        case opportunityBonus(Double)
        
        var description: String {
            switch self {
            case .savingsBonus(let pct): return "+\(Int(pct * 100))% Savings Returns"
            case .stockBonus(let pct): return "+\(Int(pct * 100))% Stock Returns"
            case .realEstateBonus(let pct): return "+\(Int(pct * 100))% Real Estate Returns"
            case .startupBonus(let pct): return "+\(Int(pct * 100))% Startup Returns"
            case .tapBonus(let pct): return "+\(Int(pct * 100))% Tap Value"
            case .opportunityBonus(let pct): return "+\(Int(pct * 100))% Opportunity Success"
            }
        }
    }
}

let allMentors: [Mentor] = [
    Mentor(
        id: "frugal_uncle",
        name: "The Frugal Uncle",
        title: "Master of Savings",
        icon: "👴",
        phaseUnlock: 1,
        bonus: .savingsBonus(0.05),
        quotes: [
            "A penny saved is a penny earned.",
            "Live below your means. Always.",
            "The best investment you can make is in yourself.",
            "Don't save what's left after spending—spend what's left after saving.",
            "Compound interest is the eighth wonder of the world."
        ],
        backstory: "Your uncle retired at 55 with a modest salary by saving 50% of every paycheck. He never made more than $70K/year but died a millionaire.",
        unlocked: true
    ),
    Mentor(
        id: "day_trader",
        name: "The Day Trader",
        title: "Market Strategist",
        icon: "📈",
        phaseUnlock: 2,
        bonus: .stockBonus(0.10),
        quotes: [
            "Buy the fear, sell the greed.",
            "The trend is your friend—until it isn't.",
            "Cut your losses quickly; let your winners run.",
            "Markets can stay irrational longer than you can stay solvent.",
            "Time in the market beats timing the market."
        ],
        backstory: "Made millions during the 2008 crash by betting against subprime mortgages. Lost it all, rebuilt, and learned humility. Now focuses on long-term value."
    ),
    Mentor(
        id: "real_estate_mogul",
        name: "The Real Estate Mogul",
        title: "Property Empire Builder",
        icon: "🏢",
        phaseUnlock: 3,
        bonus: .realEstateBonus(0.15),
        quotes: [
            "Don't wait to buy real estate. Buy real estate and wait.",
            "Land is the basis of all wealth.",
            "Every month that rent check comes in, rain or shine.",
            "Location, location, location. But also timing.",
            "Use leverage wisely—it amplifies both gains and losses."
        ],
        backstory: "Started with a single duplex, lived in one unit, rented the other. Now owns 500+ units across three states. Never sold a property—only trades up."
    ),
    Mentor(
        id: "venture_capitalist",
        name: "The Venture Capitalist",
        title: "Startup Whisperer",
        icon: "🚀",
        phaseUnlock: 4,
        bonus: .startupBonus(0.20),
        quotes: [
            "Invest in people, not just ideas.",
            "Most startups fail. Plan for the few that 100x.",
            "Power law returns: one winner pays for 20 losers.",
            "The best founders are missionaries, not mercenaries.",
            "Market size matters more than current revenue."
        ],
        backstory: "Early investor in three unicorns. Missed on ten more. Built a $2B fund by trusting her gut on founders while staying disciplined on valuations."
    ),
    Mentor(
        id: "hustler",
        name: "The Side Hustle King",
        title: "Income Stream Creator",
        icon: "💪",
        phaseUnlock: 1,
        bonus: .tapBonus(0.15),
        quotes: [
            "Your 9-5 covers expenses. Your 5-9 builds wealth.",
            "Trade time for money to get started, then trade money for time.",
            "Every skill can be monetized.",
            "The best time to start was yesterday. The next best time is now.",
            "Hustle beats talent when talent doesn't hustle."
        ],
        backstory: "Drove for Uber, sold on eBay, freelanced on Upwork—all while working full-time. Now runs a 7-figure e-commerce business from his laptop."
    ),
    Mentor(
        id: "risk_manager",
        name: "The Risk Manager",
        title: "Probability Expert",
        icon: "🎲",
        phaseUnlock: 2,
        bonus: .opportunityBonus(0.15),
        quotes: [
            "Risk what you can afford to lose.",
            "Diversification is the only free lunch in investing.",
            "Expected value is everything. Emotion is nothing.",
            "The house always wins—unless you ARE the house.",
            "Asymmetric bets: small downside, huge upside."
        ],
        backstory: "Former Wall Street quant who left to manage family money. Turned $500K into $50M over 20 years by rigorously calculating expected value on every decision."
    )
]

// MARK: - Life Event
struct LifeEvent: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let choices: [LifeEventChoice]
    let phaseAvailable: Int
}

struct LifeEventChoice: Identifiable, Codable {
    let id: String
    let label: String
    let cost: Double
    let cashReward: Double
    let statusChange: Int
    let consequence: String
}

let allLifeEvents: [LifeEvent] = [
    LifeEvent(
        id: "wedding",
        title: "Wedding Bells",
        description: "Your partner says it's time to get married. How do you celebrate?",
        icon: "💒",
        choices: [
            LifeEventChoice(id: "big_wedding", label: "Dream Wedding", cost: 50000, cashReward: 0, statusChange: 100, consequence: "Incredible memories and social connections. Your network expands."),
            LifeEventChoice(id: "modest_wedding", label: "Modest Ceremony", cost: 15000, cashReward: 0, statusChange: 30, consequence: "Beautiful day without the debt. Smart choice."),
            LifeEventChoice(id: "elope", label: "Elope to Vegas", cost: 2000, cashReward: 0, statusChange: -10, consequence: "Some family is disappointed, but you saved a fortune.")
        ],
        phaseAvailable: 2
    ),
    LifeEvent(
        id: "health_scare",
        title: "Health Scare",
        description: "An unexpected medical issue requires attention. How do you handle it?",
        icon: "🏥",
        choices: [
            LifeEventChoice(id: "best_treatment", label: "Best Treatment", cost: 25000, cashReward: 0, statusChange: 0, consequence: "Full recovery with the best doctors. Health is wealth."),
            LifeEventChoice(id: "standard_treatment", label: "Standard Care", cost: 10000, cashReward: 0, statusChange: 0, consequence: "Treatment works, but recovery takes longer."),
            LifeEventChoice(id: "ignore", label: "Push Through", cost: 0, cashReward: 0, statusChange: -20, consequence: "You tough it out, but productivity suffers for weeks.")
        ],
        phaseAvailable: 1
    ),
    LifeEvent(
        id: "family_loan",
        title: "Family Needs Help",
        description: "Your sibling needs $20,000 for an emergency. They promise to pay it back.",
        icon: "👨‍👩‍👧",
        choices: [
            LifeEventChoice(id: "full_loan", label: "Give $20,000", cost: 20000, cashReward: 0, statusChange: 50, consequence: "Family comes first. They'll never forget your generosity."),
            LifeEventChoice(id: "partial_loan", label: "Give $10,000", cost: 10000, cashReward: 0, statusChange: 20, consequence: "You help what you can. They understand."),
            LifeEventChoice(id: "decline", label: "Decline", cost: 0, cashReward: 0, statusChange: -30, consequence: "You need the money for your goals. Relationship is strained.")
        ],
        phaseAvailable: 1
    ),
    LifeEvent(
        id: "inheritance",
        title: "Unexpected Windfall",
        description: "A distant relative left you $25,000! What do you do with it?",
        icon: "📬",
        choices: [
            LifeEventChoice(id: "invest_all", label: "Invest It All", cost: 0, cashReward: 30000, statusChange: 10, consequence: "Smart move. Your money will grow exponentially over time."),
            LifeEventChoice(id: "half_and_half", label: "Invest Half, Enjoy Half", cost: 0, cashReward: 25000, statusChange: 25, consequence: "Balance! You treat yourself AND build wealth."),
            LifeEventChoice(id: "splurge", label: "Treat Yourself", cost: 0, cashReward: 10000, statusChange: 50, consequence: "YOLO! Amazing experiences, but the money's gone.")
        ],
        phaseAvailable: 1
    ),
    LifeEvent(
        id: "vacation_dilemma",
        title: "Dream Vacation",
        description: "Your friends are planning an incredible trip. Do you join?",
        icon: "✈️",
        choices: [
            LifeEventChoice(id: "luxury_trip", label: "Go All Out", cost: 15000, cashReward: 0, statusChange: 40, consequence: "Once-in-a-lifetime memories. No regrets."),
            LifeEventChoice(id: "budget_trip", label: "Go Budget", cost: 5000, cashReward: 0, statusChange: 15, consequence: "You join but skip the extras. Still fun!"),
            LifeEventChoice(id: "skip", label: "Stay Home & Grind", cost: 0, cashReward: 5000, statusChange: -15, consequence: "More money earned, but FOMO hits hard.")
        ],
        phaseAvailable: 1
    ),
    LifeEvent(
        id: "car_trouble",
        title: "Car Breakdown",
        description: "Your car needs major repairs. What's the move?",
        icon: "🚗",
        choices: [
            LifeEventChoice(id: "new_car", label: "Buy New Car", cost: 35000, cashReward: 0, statusChange: 30, consequence: "Reliable transport and a nice upgrade. Monthly payments though."),
            LifeEventChoice(id: "used_car", label: "Buy Used", cost: 12000, cashReward: 0, statusChange: 5, consequence: "Gets the job done. Smart financial decision."),
            LifeEventChoice(id: "repair", label: "Repair It", cost: 3000, cashReward: 0, statusChange: -5, consequence: "Fixed for now, but more problems likely coming.")
        ],
        phaseAvailable: 1
    ),
    LifeEvent(
        id: "education_opportunity",
        title: "Education Opportunity",
        description: "A prestigious MBA program accepts you. Tuition is steep.",
        icon: "🎓",
        choices: [
            LifeEventChoice(id: "full_time_mba", label: "Full-Time MBA", cost: 100000, cashReward: 0, statusChange: 200, consequence: "Career accelerated. Network expanded. Doors opened."),
            LifeEventChoice(id: "part_time_mba", label: "Part-Time MBA", cost: 60000, cashReward: 0, statusChange: 100, consequence: "Slower but no income disruption. Balanced approach."),
            LifeEventChoice(id: "decline_mba", label: "Self-Educate", cost: 1000, cashReward: 0, statusChange: 10, consequence: "Books and YouTube. Knowledge without the credential.")
        ],
        phaseAvailable: 2
    ),
    LifeEvent(
        id: "charity_gala",
        title: "Charity Gala Invite",
        description: "A prestigious charity invites you to their gala. Major networking potential.",
        icon: "🎭",
        choices: [
            LifeEventChoice(id: "vip_table", label: "VIP Table ($25K)", cost: 25000, cashReward: 50000, statusChange: 150, consequence: "You meet industry titans. One connection leads to a massive deal."),
            LifeEventChoice(id: "regular_ticket", label: "Regular Ticket ($5K)", cost: 5000, cashReward: 0, statusChange: 40, consequence: "Great event. Some good connections made."),
            LifeEventChoice(id: "skip_gala", label: "Send Regrets", cost: 0, cashReward: 0, statusChange: -20, consequence: "You missed a golden networking opportunity.")
        ],
        phaseAvailable: 3
    )
]

// MARK: - Mentor & Life Event Manager
class MentorLifeEventManager: ObservableObject {
    @Published var mentors: [Mentor] {
        didSet { saveMentors() }
    }
    @Published var currentLifeEvent: LifeEvent?
    @Published var showLifeEvent = false
    @Published var lifeEventHistory: [String] = []
    
    private var eventCooldown: TimeInterval = 0
    private var eventTimer: Timer?
    
    var activeMentor: Mentor? {
        mentors.first { $0.selected }
    }
    
    var unlockedMentors: [Mentor] {
        mentors.filter { $0.unlocked }
    }
    
    init() {
        if let data = UserDefaults.standard.data(forKey: "mentors"),
           let decoded = try? JSONDecoder().decode([Mentor].self, from: data) {
            self.mentors = decoded
        } else {
            self.mentors = allMentors
        }
        
        if let history = UserDefaults.standard.array(forKey: "lifeEventHistory") as? [String] {
            self.lifeEventHistory = history
        }
        
        startEventLoop()
    }
    
    func startEventLoop() {
        eventTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tickEvents()
        }
    }
    
    private func tickEvents() {
        if eventCooldown > 0 {
            eventCooldown -= 1
            return
        }
        
        // Random chance to trigger life event
        if currentLifeEvent == nil && Double.random(in: 0...1) < 0.005 { // 0.5% per second
            triggerRandomLifeEvent(currentPhase: 4) // Max phase for testing
        }
    }
    
    func checkMentorUnlocks(currentPhase: Int) {
        for i in 0..<mentors.count {
            if mentors[i].phaseUnlock <= currentPhase && !mentors[i].unlocked {
                mentors[i].unlocked = true
            }
        }
    }
    
    func selectMentor(_ mentorId: String) {
        for i in 0..<mentors.count {
            mentors[i].selected = (mentors[i].id == mentorId)
        }
    }
    
    func getRandomQuote() -> (mentor: Mentor, quote: String)? {
        guard let mentor = activeMentor ?? unlockedMentors.randomElement() else { return nil }
        guard let quote = mentor.quotes.randomElement() else { return nil }
        return (mentor, quote)
    }
    
    func triggerRandomLifeEvent(currentPhase: Int) {
        let availableEvents = allLifeEvents.filter { 
            $0.phaseAvailable <= currentPhase && !lifeEventHistory.contains($0.id)
        }
        
        if let event = availableEvents.randomElement() {
            currentLifeEvent = event
            showLifeEvent = true
            FeedbackCoordinator.shared.opportunityAppear()
        }
    }
    
    func handleLifeEventChoice(_ choiceId: String, game: GameState) {
        guard let event = currentLifeEvent else { return }
        guard let choice = event.choices.first(where: { $0.id == choiceId }) else { return }
        
        // Apply effects
        if choice.cost > 0 {
            game.cash -= choice.cost
        }
        if choice.cashReward > 0 {
            game.cash += choice.cashReward
            game.totalEarned += choice.cashReward
        }
        game.statusPoints += choice.statusChange
        
        // Record in history
        lifeEventHistory.append(event.id)
        UserDefaults.standard.set(lifeEventHistory, forKey: "lifeEventHistory")
        
        // Clear event
        currentLifeEvent = nil
        showLifeEvent = false
        eventCooldown = 300 // 5 minute cooldown
        
        FeedbackCoordinator.shared.opportunityResult(choice.statusChange >= 0)
    }
    
    func dismissLifeEvent() {
        currentLifeEvent = nil
        showLifeEvent = false
        eventCooldown = 60
    }
    
    // Get bonus for specific investment type
    func getInvestmentBonus(for investmentId: String) -> Double {
        guard let mentor = activeMentor else { return 0 }
        
        switch mentor.bonus {
        case .savingsBonus(let pct):
            return investmentId == "savings" ? pct : 0
        case .stockBonus(let pct):
            return ["stocks", "index_fund"].contains(investmentId) ? pct : 0
        case .realEstateBonus(let pct):
            return ["rental", "commercial"].contains(investmentId) ? pct : 0
        case .startupBonus(let pct):
            return ["startup", "venture_fund"].contains(investmentId) ? pct : 0
        default:
            return 0
        }
    }
    
    func getTapBonus() -> Double {
        guard let mentor = activeMentor else { return 0 }
        if case .tapBonus(let pct) = mentor.bonus {
            return pct
        }
        return 0
    }
    
    func getOpportunityBonus() -> Double {
        guard let mentor = activeMentor else { return 0 }
        if case .opportunityBonus(let pct) = mentor.bonus {
            return pct
        }
        return 0
    }
    
    private func saveMentors() {
        if let data = try? JSONEncoder().encode(mentors) {
            UserDefaults.standard.set(data, forKey: "mentors")
        }
    }
    
    func reset() {
        mentors = allMentors
        currentLifeEvent = nil
        lifeEventHistory = []
        eventCooldown = 0
    }
}

// MARK: - Life Event View
struct LifeEventView: View {
    let event: LifeEvent
    let onChoice: (String) -> Void
    @ObservedObject var game: GameState
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        VStack(spacing: 20) {
            headerSection
            choicesSection
        }
        .padding(24)
        .background(cardBackground)
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(event.icon)
                .font(.system(size: 60))
            
            Text("LIFE EVENT")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.purple)
                .tracking(2)
            
            Text(event.title)
                .font(.system(size: 24, weight: .black))
                .foregroundColor(.white)
            
            Text(event.description)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private var choicesSection: some View {
        VStack(spacing: 12) {
            ForEach(event.choices) { choice in
                choiceButton(choice)
            }
        }
    }
    
    private func choiceButton(_ choice: LifeEventChoice) -> some View {
        let canAfford = game.cash >= choice.cost
        let fillColor: Color = canAfford ? Color.white.opacity(0.1) : Color.red.opacity(0.1)
        let strokeColor: Color = canAfford ? Color.purple.opacity(0.5) : Color.red.opacity(0.3)
        
        return Button(action: { onChoice(choice.id) }) {
            VStack(spacing: 6) {
                HStack {
                    Text(choice.label)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if choice.cost > 0 {
                        Text("-$\(Int(choice.cost))")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.red)
                    }
                    if choice.cashReward > 0 {
                        Text("+$\(Int(choice.cashReward))")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.green)
                    }
                }
                
                Text(choice.consequence)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(fillColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(strokeColor, lineWidth: 1)
                    )
            )
        }
        .disabled(!canAfford)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(Color.black.opacity(0.95))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.purple, lineWidth: 2)
            )
            .shadow(color: Color.purple.opacity(0.5), radius: 30)
    }
}

// MARK: - Mentor Selection View
struct MentorSelectionView: View {
    @ObservedObject var manager: MentorLifeEventManager
    @Environment(\.dismiss) var dismiss
    
    let accentColor = Color(red: 0.4, green: 0.7, blue: 0.4)
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        Text("Choose Your Mentor")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Text("Mentors provide passive bonuses and wisdom")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    ForEach(manager.mentors) { mentor in
                        mentorCard(mentor)
                    }
                }
                .padding()
            }
        }
    }
    
    func mentorCard(_ mentor: Mentor) -> some View {
        Button(action: {
            if mentor.unlocked {
                manager.selectMentor(mentor.id)
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(mentor.icon)
                        .font(.system(size: 40))
                        .opacity(mentor.unlocked ? 1.0 : 0.3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mentor.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(mentor.unlocked ? .white : .gray)
                        Text(mentor.title)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    if mentor.selected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(accentColor)
                    } else if !mentor.unlocked {
                        VStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                            Text("Phase \(mentor.phaseUnlock)")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                if mentor.unlocked {
                    Text(mentor.bonus.description)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(accentColor)
                    
                    Text(mentor.backstory)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(mentor.selected ? accentColor.opacity(0.15) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(mentor.selected ? accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .disabled(!mentor.unlocked)
    }
}
