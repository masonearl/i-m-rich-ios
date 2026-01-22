//
//  GameState.swift
//  I'm Rich
//
//  Observable game state manager
//

import SwiftUI
import Combine

class GameState: ObservableObject {
    // MARK: - Core Resources
    @Published var cash: Double {
        didSet { saveCash() }
    }
    @Published var totalEarned: Double {
        didSet { UserDefaults.standard.set(totalEarned, forKey: "totalEarned") }
    }
    @Published var statusPoints: Int {
        didSet { UserDefaults.standard.set(statusPoints, forKey: "statusPoints") }
    }
    @Published var totalTaps: Int {
        didSet { UserDefaults.standard.set(totalTaps, forKey: "totalTaps") }
    }
    
    // MARK: - Phase & Career
    @Published var currentPhase: GamePhase {
        didSet { savePhase() }
    }
    @Published var selectedCareer: CareerPath? {
        didSet { saveCareer() }
    }
    @Published var currentRoleIndex: Int {
        didSet { UserDefaults.standard.set(currentRoleIndex, forKey: "currentRoleIndex") }
    }
    
    // MARK: - Investments
    @Published var investments: [Investment] {
        didSet { saveInvestments() }
    }
    
    // MARK: - Upgrades
    @Published var upgrades: [Upgrade] {
        didSet { saveUpgrades() }
    }
    
    // MARK: - Products
    @Published var products: [Product] {
        didSet { saveProducts() }
    }
    
    // MARK: - Contacts
    @Published var contacts: [MeetingContact] {
        didSet { saveContacts() }
    }
    
    // MARK: - Housing
    @Published var housing: Housing {
        didSet { saveHousing() }
    }
    
    // MARK: - Opportunity
    @Published var currentOpportunity: OpportunityCard?
    @Published var opportunityCooldown: Double = 0
    
    // MARK: - Streak
    @Published var currentStreak: Int = 0
    @Published var highestStreak: Int {
        didSet { UserDefaults.standard.set(highestStreak, forKey: "highestStreak") }
    }
    @Published var lastTapTime: Date = Date()
    let streakTimeLimit: TimeInterval = 1.5
    
    // MARK: - Game Timer
    private var gameTimer: Timer?
    private var opportunityTimer: Timer?
    
    // MARK: - Computed Properties
    
    var currentRole: CareerRole? {
        guard let career = selectedCareer else { return nil }
        let roles = career.roles
        guard currentRoleIndex < roles.count else { return roles.last }
        return roles[currentRoleIndex]
    }
    
    var nextRole: CareerRole? {
        guard let career = selectedCareer else { return nil }
        let roles = career.roles
        let nextIndex = currentRoleIndex + 1
        guard nextIndex < roles.count else { return nil }
        return roles[nextIndex]
    }
    
    var promotionCost: Double {
        guard let next = nextRole else { return 0 }
        return Double(next.statusPoints) * 100
    }
    
    var passiveIncomePerSecond: Double {
        var income: Double = 0
        
        // Career salary (per second conversion)
        if let role = currentRole {
            income += role.salary / 31536000 // Convert annual to per-second
        }
        
        // Investment returns (per second)
        for investment in investments where investment.amountInvested > 0 {
            let annualReturn = investment.amountInvested * investment.baseReturn * (1 + investmentBonusMultiplier)
            income += annualReturn / 31536000
        }
        
        // Upgrade passive income
        for upgrade in upgrades where upgrade.purchased {
            if case .passiveIncome(let amount) = upgrade.effect {
                income += amount
            }
        }
        
        // Product ongoing revenue
        for product in products where product.successful {
            income += product.ongoingRevenue
        }
        
        return income
    }
    
    var tapMultiplier: Double {
        var multiplier = 1.0
        
        // Career multiplier
        if let career = selectedCareer {
            multiplier *= career.incomeMultiplier
        }
        
        // Upgrade multipliers
        for upgrade in upgrades where upgrade.purchased {
            if case .tapMultiplier(let bonus) = upgrade.effect {
                multiplier += bonus
            }
        }
        
        // Streak multiplier
        multiplier *= streakMultiplier
        
        return multiplier
    }
    
    var streakMultiplier: Double {
        switch currentStreak {
        case 0..<100: return 1.0
        case 100..<300: return 2.0
        case 300..<500: return 3.0
        case 500..<1000: return 4.0
        case 1000..<2000: return 5.0
        case 2000..<4000: return 7.0
        case 4000..<7000: return 10.0
        case 7000..<10000: return 15.0
        default: return 20.0
        }
    }
    
    var baseTapValue: Double {
        switch totalEarned {
        case 0..<1_000: return 1
        case 1_000..<10_000: return 5
        case 10_000..<100_000: return 25
        case 100_000..<1_000_000: return 100
        case 1_000_000..<10_000_000: return 500
        case 10_000_000..<100_000_000: return 2_500
        case 100_000_000..<1_000_000_000: return 10_000
        default: return 50_000
        }
    }
    
    var tapValue: Double {
        baseTapValue * tapMultiplier
    }
    
    var investmentBonusMultiplier: Double {
        var bonus = 0.0
        for upgrade in upgrades where upgrade.purchased {
            if case .investmentBonus(let amount) = upgrade.effect {
                bonus += amount
            }
        }
        return bonus
    }
    
    var opportunityBonusChance: Double {
        var bonus = 0.0
        for upgrade in upgrades where upgrade.purchased {
            if case .opportunityBonus(let amount) = upgrade.effect {
                bonus += amount
            }
        }
        return bonus
    }
    
    var nextPhase: GamePhase? {
        GamePhase.allCases.first { $0.rawValue == currentPhase.rawValue + 1 }
    }
    
    var phaseProgress: Double {
        guard let next = nextPhase else { return 1.0 }
        let current = currentPhase.unlockRequirement
        let target = next.unlockRequirement
        return min((totalEarned - current) / (target - current), 1.0)
    }
    
    var availableInvestments: [Investment] {
        investments.filter { $0.phaseUnlock.rawValue <= currentPhase.rawValue }
    }
    
    var availableUpgrades: [Upgrade] {
        upgrades.filter { $0.phaseUnlock.rawValue <= currentPhase.rawValue && !$0.purchased }
    }
    
    var availableContacts: [MeetingContact] {
        contacts.filter { 
            $0.phaseRequired.rawValue <= currentPhase.rawValue && 
            statusPoints >= $0.statusRequired && 
            !$0.hasMet 
        }
    }
    
    var availableProducts: [Product] {
        products.filter { !$0.launched }
    }
    
    // MARK: - Initialization
    
    init() {
        // Load saved state
        self.cash = UserDefaults.standard.double(forKey: "cash")
        self.totalEarned = UserDefaults.standard.double(forKey: "totalEarned")
        self.statusPoints = UserDefaults.standard.integer(forKey: "statusPoints")
        self.totalTaps = UserDefaults.standard.integer(forKey: "totalTaps")
        self.highestStreak = UserDefaults.standard.integer(forKey: "highestStreak")
        self.currentRoleIndex = UserDefaults.standard.integer(forKey: "currentRoleIndex")
        
        // Load phase
        let phaseRaw = UserDefaults.standard.integer(forKey: "currentPhase")
        self.currentPhase = GamePhase(rawValue: max(1, phaseRaw)) ?? .hustle
        
        // Load career
        if let careerRaw = UserDefaults.standard.string(forKey: "selectedCareer") {
            self.selectedCareer = CareerPath(rawValue: careerRaw)
        } else {
            self.selectedCareer = nil
        }
        
        // Load investments
        if let data = UserDefaults.standard.data(forKey: "investments"),
           let decoded = try? JSONDecoder().decode([Investment].self, from: data) {
            self.investments = decoded
        } else {
            self.investments = allInvestments
        }
        
        // Load upgrades
        if let data = UserDefaults.standard.data(forKey: "upgrades"),
           let decoded = try? JSONDecoder().decode([Upgrade].self, from: data) {
            self.upgrades = decoded
        } else {
            self.upgrades = allUpgrades
        }
        
        // Load products
        if let data = UserDefaults.standard.data(forKey: "products"),
           let decoded = try? JSONDecoder().decode([Product].self, from: data) {
            self.products = decoded
        } else {
            self.products = productCatalog
        }
        
        // Load contacts
        if let data = UserDefaults.standard.data(forKey: "contacts"),
           let decoded = try? JSONDecoder().decode([MeetingContact].self, from: data) {
            self.contacts = decoded
        } else {
            self.contacts = allContacts
        }
        
        // Load housing
        if let data = UserDefaults.standard.data(forKey: "housing"),
           let decoded = try? JSONDecoder().decode(Housing.self, from: data) {
            self.housing = decoded
        } else {
            self.housing = Housing()
        }
        
        startGameLoop()
    }
    
    // MARK: - Game Loop
    
    func startGameLoop() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        
        opportunityTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.generateOpportunity()
        }
    }
    
    func tick() {
        // Passive income
        let income = passiveIncomePerSecond * 0.1 // 0.1 second tick
        if income > 0 {
            cash += income
            totalEarned += income
        }
        
        // Check phase unlock
        checkPhaseUnlock()
        
        // Decay streak if no recent taps
        if Date().timeIntervalSince(lastTapTime) > streakTimeLimit && currentStreak > 0 {
            currentStreak = 0
        }
        
        // Opportunity cooldown
        if opportunityCooldown > 0 {
            opportunityCooldown -= 0.1
        }
    }
    
    // MARK: - Actions
    
    func tap() {
        let now = Date()
        if now.timeIntervalSince(lastTapTime) < streakTimeLimit {
            currentStreak += 1
            if currentStreak > highestStreak {
                highestStreak = currentStreak
            }
        } else {
            currentStreak = 1
        }
        lastTapTime = now
        
        cash += tapValue
        totalEarned += tapValue
        totalTaps += 1
        
        // Small status point gain from tapping
        if totalTaps % 100 == 0 {
            statusPoints += 1
        }
    }
    
    func selectCareer(_ career: CareerPath) {
        selectedCareer = career
        currentRoleIndex = 0
        if let role = currentRole {
            statusPoints += role.statusPoints
        }
    }
    
    func promote() -> Bool {
        guard let next = nextRole else { return false }
        guard cash >= promotionCost else { return false }
        
        cash -= promotionCost
        currentRoleIndex += 1
        statusPoints += next.statusPoints
        
        return true
    }
    
    func invest(in investmentId: String, amount: Double) -> Bool {
        guard let index = investments.firstIndex(where: { $0.id == investmentId }) else { return false }
        guard cash >= amount else { return false }
        guard amount >= investments[index].minInvestment else { return false }
        
        cash -= amount
        investments[index].amountInvested += amount
        
        return true
    }
    
    func purchaseUpgrade(_ upgradeId: String) -> Bool {
        guard let index = upgrades.firstIndex(where: { $0.id == upgradeId }) else { return false }
        guard !upgrades[index].purchased else { return false }
        guard cash >= upgrades[index].cost else { return false }
        
        cash -= upgrades[index].cost
        upgrades[index].purchased = true
        
        // Apply status bonus immediately
        if case .statusBonus(let points) = upgrades[index].effect {
            statusPoints += points
        }
        
        return true
    }
    
    func launchProduct(_ productId: String) -> (success: Bool, message: String) {
        guard let index = products.firstIndex(where: { $0.id == productId }) else {
            return (false, "Product not found")
        }
        
        let product = products[index]
        let totalCost = product.developmentCost + product.marketingCost
        
        guard cash >= totalCost else {
            return (false, "Not enough cash")
        }
        
        cash -= totalCost
        products[index].launched = true
        
        // Determine success
        let roll = Double.random(in: 0...1)
        if roll <= product.successChance {
            products[index].successful = true
            cash += product.revenueOnSuccess
            totalEarned += product.revenueOnSuccess
            statusPoints += 50
            return (true, "\(product.name) is a hit! +\(formatCurrency(product.revenueOnSuccess))")
        } else {
            return (false, "\(product.name) flopped. Better luck next time!")
        }
    }
    
    func meetContact(_ contactId: String) -> Bool {
        guard let index = contacts.firstIndex(where: { $0.id == contactId }) else { return false }
        guard !contacts[index].hasMet else { return false }
        guard statusPoints >= contacts[index].statusRequired else { return false }
        
        contacts[index].hasMet = true
        cash += contacts[index].bonusOnMeet
        totalEarned += contacts[index].bonusOnMeet
        statusPoints += 10 // Bonus status for networking
        
        return true
    }
    
    func takeOpportunity(_ accept: Bool) -> (success: Bool, message: String)? {
        guard let opportunity = currentOpportunity else { return nil }
        
        defer { currentOpportunity = nil }
        
        if !accept {
            return (true, "Passed on \(opportunity.title)")
        }
        
        guard cash >= opportunity.cost else {
            return (false, "Not enough cash!")
        }
        
        cash -= opportunity.cost
        
        let adjustedChance = min(opportunity.successChance + opportunityBonusChance, 0.95)
        let roll = Double.random(in: 0...1)
        
        if roll <= adjustedChance {
            cash += opportunity.successReward
            totalEarned += opportunity.successReward
            statusPoints += opportunity.statusBonus
            return (true, "Success! \(opportunity.title) paid off!")
        } else {
            return (false, "\(opportunity.title) didn't work out...")
        }
    }
    
    func buyHome(price: Double, downPayment: Double) -> Bool {
        guard cash >= downPayment else { return false }
        guard housing.status == .renting else { return false }
        
        cash -= downPayment
        housing.status = .ownsHome
        housing.propertyValue = price
        housing.equity = downPayment
        housing.mortgageBalance = price - downPayment
        housing.monthlyPayment = (price - downPayment) * 0.005 // ~6% annual rate / 12
        
        statusPoints += 25
        
        return true
    }
    
    // MARK: - Phase Management
    
    func checkPhaseUnlock() {
        for phase in GamePhase.allCases {
            if phase.rawValue > currentPhase.rawValue && totalEarned >= phase.unlockRequirement {
                currentPhase = phase
            }
        }
    }
    
    func generateOpportunity() {
        guard currentOpportunity == nil else { return }
        guard opportunityCooldown <= 0 else { return }
        
        let availableOpportunities = opportunityDeck.filter { 
            $0.phaseAvailable.rawValue <= currentPhase.rawValue 
        }
        
        if let opportunity = availableOpportunities.randomElement() {
            currentOpportunity = opportunity
            opportunityCooldown = 60 // 1 minute cooldown after dismissing
        }
    }
    
    // MARK: - Persistence
    
    private func saveCash() {
        UserDefaults.standard.set(cash, forKey: "cash")
    }
    
    private func savePhase() {
        UserDefaults.standard.set(currentPhase.rawValue, forKey: "currentPhase")
    }
    
    private func saveCareer() {
        UserDefaults.standard.set(selectedCareer?.rawValue, forKey: "selectedCareer")
    }
    
    private func saveInvestments() {
        if let data = try? JSONEncoder().encode(investments) {
            UserDefaults.standard.set(data, forKey: "investments")
        }
    }
    
    private func saveUpgrades() {
        if let data = try? JSONEncoder().encode(upgrades) {
            UserDefaults.standard.set(data, forKey: "upgrades")
        }
    }
    
    private func saveProducts() {
        if let data = try? JSONEncoder().encode(products) {
            UserDefaults.standard.set(data, forKey: "products")
        }
    }
    
    private func saveContacts() {
        if let data = try? JSONEncoder().encode(contacts) {
            UserDefaults.standard.set(data, forKey: "contacts")
        }
    }
    
    private func saveHousing() {
        if let data = try? JSONEncoder().encode(housing) {
            UserDefaults.standard.set(data, forKey: "housing")
        }
    }
    
    // MARK: - Helpers
    
    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
    
    func formatCompact(_ value: Double) -> String {
        switch value {
        case 1_000_000_000_000...:
            return String(format: "$%.1fT", value / 1_000_000_000_000)
        case 1_000_000_000...:
            return String(format: "$%.1fB", value / 1_000_000_000)
        case 1_000_000...:
            return String(format: "$%.1fM", value / 1_000_000)
        case 1_000...:
            return String(format: "$%.1fK", value / 1_000)
        default:
            return formatCurrency(value)
        }
    }
    
    func resetGame() {
        cash = 0
        totalEarned = 0
        statusPoints = 0
        totalTaps = 0
        highestStreak = 0
        currentStreak = 0
        currentPhase = .hustle
        selectedCareer = nil
        currentRoleIndex = 0
        investments = allInvestments
        upgrades = allUpgrades
        products = productCatalog
        contacts = allContacts
        housing = Housing()
        currentOpportunity = nil
    }
}
