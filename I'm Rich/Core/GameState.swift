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
    @Published var highestNetWorth: Double {
        didSet { UserDefaults.standard.set(highestNetWorth, forKey: "highestNetWorth") }
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
    
    // MARK: - Permanently Unlocked Zones
    @Published var unlockedZones: Set<String> {
        didSet { saveUnlockedZones() }
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
    
    // MARK: - Auto-Tappers
    @Published var autoTappers: [AutoTapper] {
        didSet { saveAutoTappers() }
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
    
    // MARK: - Managers (shared references)
    let lifecycleManager = LifeCycleManager.shared
    let prestigeManager = PrestigeManager.shared
    let marketEventManager = MarketEventManager.shared
    let achievementManager = AchievementManager.shared
    let dailySystemManager = DailySystemManager.shared
    
    // MARK: - Life of Wealth Managers
    let wealthManager = WealthManager.shared
    let energyManager = EnergyManager.shared
    let factionManager = FactionManager.shared
    let familyManager = FamilyManager.shared
    let reflectionManager = LifeReflectionManager.shared
    
    // MARK: - Strategic Systems Managers
    let economicCycleManager = EconomicCycleManager.shared
    let researchManager = ResearchManager.shared
    let strategicEventManager = StrategicEventManager.shared
    let competitorManager = CompetitorManager.shared
    let synergyManager = SynergyManager.shared
    
    // MARK: - Game Center
    let gameCenterManager = GameCenterManager.shared
    
    // MARK: - Work Time Tracking
    @Published var workTimeMinutes: Double = 0
    @Published var leisureTimeMinutes: Double = 0
    
    var workTimePercent: Double {
        let total = workTimeMinutes + leisureTimeMinutes
        guard total > 0 else { return 50 }
        return (workTimeMinutes / total) * 100
    }
    
    // MARK: - Daily Sales Limit System
    // Limits how many taps (sales) you can make per game day
    @Published var dailySales: Int = 0 {
        didSet { UserDefaults.standard.set(dailySales, forKey: "dailySales") }
    }
    @Published var lastSalesResetDay: Int = 0 {
        didSet { UserDefaults.standard.set(lastSalesResetDay, forKey: "lastSalesResetDay") }
    }
    
    // Base daily sales limit - increases with upgrades, marketing, etc.
    var baseDailySalesLimit: Int {
        // Starts at 10 sales per day, scales with totalEarned
        switch totalEarned {
        case 0..<1_000: return 10
        case 1_000..<10_000: return 20
        case 10_000..<100_000: return 50
        case 100_000..<1_000_000: return 100
        case 1_000_000..<10_000_000: return 200
        case 10_000_000..<100_000_000: return 500
        case 100_000_000..<1_000_000_000: return 1000
        default: return 2000
        }
    }
    
    var dailySalesLimit: Int {
        var limit = baseDailySalesLimit
        
        // Marketing upgrades add bonus
        let marketingBonus = upgrades.filter { $0.purchased }.reduce(0) { total, upgrade in
            if case .tapMultiplier(_) = upgrade.effect {
                return total + 10  // Each multiplier upgrade adds 10 daily sales
            }
            return total
        }
        limit += marketingBonus
        
        // Employees add sales capacity
        let employees = CompanyManager.shared.state.totalEmployees
        limit += employees * 5  // Each employee adds 5 daily sales capacity
        
        return limit
    }
    
    var canMakeSale: Bool {
        true  // Unlimited tapping allowed
    }
    
    var salesProgress: Double {
        Double(dailySales) / Double(dailySalesLimit)
    }
    
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
        // Cost scales exponentially with role level
        let baseMultiplier = pow(2.0, Double(currentRoleIndex))
        return Double(next.statusPoints) * 150 * baseMultiplier
    }
    
    // MARK: - Promotion Requirements
    
    /// Number of contacts required for next promotion
    var contactsRequiredForPromotion: Int {
        // Each level requires more networking
        // Level 0→1: 1 contact, 1→2: 2 contacts, 2→3: 3 contacts, etc.
        return max(1, currentRoleIndex + 1)
    }
    
    /// How many career-relevant contacts the player has met
    var careerContactsMet: Int {
        contacts.filter { $0.hasMet && ($0.careerPath == nil || $0.careerPath == selectedCareer) }.count
    }
    
    /// Status points required for next promotion
    var statusRequiredForPromotion: Int {
        guard let next = nextRole else { return 0 }
        // Require 50% of the role's status threshold
        return next.statusPoints / 2
    }
    
    /// Check if player meets all promotion requirements
    var canPromote: Bool {
        guard nextRole != nil else { return false }
        guard cash >= promotionCost else { return false }
        guard careerContactsMet >= contactsRequiredForPromotion else { return false }
        guard statusPoints >= statusRequiredForPromotion else { return false }
        return true
    }
    
    /// Get detailed promotion requirements for UI
    var promotionRequirements: [(requirement: String, met: Bool, detail: String)] {
        var reqs: [(requirement: String, met: Bool, detail: String)] = []
        
        // Cash requirement
        let hasCash = cash >= promotionCost
        reqs.append((
            requirement: "💰 Cash",
            met: hasCash,
            detail: "\(formatCompact(cash)) / \(formatCompact(promotionCost))"
        ))
        
        // Contacts requirement
        let hasContacts = careerContactsMet >= contactsRequiredForPromotion
        reqs.append((
            requirement: "🤝 Network",
            met: hasContacts,
            detail: "\(careerContactsMet) / \(contactsRequiredForPromotion) contacts"
        ))
        
        // Status requirement
        let hasStatus = statusPoints >= statusRequiredForPromotion
        reqs.append((
            requirement: "⚡ Status",
            met: hasStatus,
            detail: "\(statusPoints) / \(statusRequiredForPromotion) points"
        ))
        
        return reqs
    }
    
    var passiveIncomePerSecond: Double {
        var income: Double = 0
        
        // Career salary (per second conversion) - realistic pacing
        // Annual salary / seconds-per-game-year = income per second of gameplay
        // If 300 seconds = 1 game year, then divide by 300 to get realistic yearly income
        if let role = currentRole {
            // Convert annual salary to income per game-second
            // This means over a 15-minute game year, you earn your yearly salary
            income += role.salary / LifeCycleConstants.secondsPerGameYear
        }
        
        // Upgrade passive income (scaled down)
        for upgrade in upgrades where upgrade.purchased {
            if case .passiveIncome(let amount) = upgrade.effect {
                income += amount * 0.1  // Reduce upgrade passive income by 90%
            }
            // Luxury items COST money (upkeep) but give status
            if case .luxuryFlex(_, let upkeepPerSecond) = upgrade.effect {
                income -= upkeepPerSecond  // Deduct upkeep cost!
            }
        }
        
        // Product ongoing revenue (scaled down)
        for product in products where product.successful {
            income += product.ongoingRevenue * 0.05  // Reduce product revenue by 95%
        }
        
        // Auto-tapper income - these work in real-time
        income += autoTapperIncomePerSecond
        
        // Apply prestige multiplier
        income *= prestigeManager.legacyMultiplier
        
        // Apply research passive income multiplier
        income *= researchManager.totalPassiveMultiplier
        
        // Apply economic cycle revenue modifier
        income *= economicCycleManager.state.currentPhase.revenueMultiplier
        
        // Apply synergy bonus
        income *= synergyManager.getMultiplier(for: .passiveIncome)
        
        // Apply company understaffing penalty - understaffed companies make less money!
        income *= CompanyManager.shared.understaffingPenalty
        
        // Add venture income (from serial entrepreneur companies)
        let ventureIncome = VentureManager.shared.getTotalVentureIncome() / LifeCycleConstants.secondsPerGameYear
        income += ventureIncome
        
        return income
    }
    
    /// BALANCED: Auto-tappers now use flat income per tier instead of multiplying by tapValue
    /// This prevents them from generating billions/second at late game
    var autoTapperIncomePerSecond: Double {
        var income: Double = 0
        for tapper in autoTappers where tapper.owned {
            // Use flat income based on tapper tier, NOT tap value multipliers
            income += tapper.currentTapsPerSecond * tapper.baseIncomePerTap
        }
        // Only apply prestige multiplier, not all the tap multipliers
        return income * prestigeManager.legacyMultiplier
    }
    
    var totalAutoTapsPerSecond: Double {
        var tapsPerSecond: Double = 0
        for tapper in autoTappers where tapper.owned {
            tapsPerSecond += tapper.currentTapsPerSecond
        }
        return tapsPerSecond
    }
    
    /// Calculate upgrade passive income per second (for tax tracking)
    func calculateUpgradePassiveIncome() -> Double {
        var income: Double = 0
        for upgrade in upgrades where upgrade.purchased {
            if case .passiveIncome(let amount) = upgrade.effect {
                income += amount * 0.1  // Same scaling as passiveIncomePerSecond
            }
        }
        return income * prestigeManager.legacyMultiplier
    }
    
    /// Calculate product revenue per second (for tax tracking)
    func calculateProductIncome() -> Double {
        var income: Double = 0
        for product in products where product.successful {
            income += product.ongoingRevenue * 0.05  // Same scaling as passiveIncomePerSecond
        }
        return income * prestigeManager.legacyMultiplier
    }
    
    /// Total luxury upkeep cost per second (yachts, jets, mansions, etc.)
    var luxuryUpkeepPerSecond: Double {
        var upkeep: Double = 0
        for upgrade in upgrades where upgrade.purchased {
            if case .luxuryFlex(_, let upkeepPerSecond) = upgrade.effect {
                upkeep += upkeepPerSecond
            }
        }
        return upkeep
    }
    
    /// List of owned luxury items for display
    var ownedLuxuryItems: [(name: String, icon: String, upkeep: Double)] {
        upgrades.compactMap { upgrade in
            guard upgrade.purchased else { return nil }
            if case .luxuryFlex(_, let upkeep) = upgrade.effect {
                return (upgrade.name, upgrade.icon, upkeep)
            }
            return nil
        }
    }
    
    var availableAutoTappers: [AutoTapper] {
        autoTappers.filter { $0.phaseUnlock.rawValue <= currentPhase.rawValue }
    }
    
    // Investment gains accumulate throughout the year, compounded at year-end
    var totalInvestmentValue: Double {
        investments.reduce(0) { $0 + $1.totalValue }
    }
    
    /// Total net worth = cash + investments + company valuation
    var netWorth: Double {
        cash + totalInvestmentValue + CompanyManager.shared.state.companyValuation
    }
    
    // MARK: - CEO Identity System
    
    /// Player's CEO title based on net worth and hustle (total taps)
    var ceoTitle: CEOTitle {
        CEOTitle.fromProgress(netWorth: netWorth, totalTaps: totalTaps)
    }
    
    /// Hustle score combines total taps with achievements
    var hustleScore: Int {
        let tapScore = min(1000, totalTaps / 100)  // Cap contribution from taps
        let achievementBonus = achievementManager.unlockedCount * 10
        return Int(tapScore) + achievementBonus
    }
    
    var totalUnrealizedGains: Double {
        investments.reduce(0) { $0 + $1.unrealizedGains }
    }
    
    /// BALANCED: Upgrade tap multiplier capped at 3x to prevent runaway income
    var tapMultiplier: Double {
        var multiplier = 1.0
        
        // Career multiplier (unchanged - ranges from 1.1x to 1.5x)
        if let career = selectedCareer {
            multiplier *= career.incomeMultiplier
        }
        
        // Upgrade multipliers - CAPPED at 3.0x total
        var upgradeBonus = 0.0
        for upgrade in upgrades where upgrade.purchased {
            if case .tapMultiplier(let bonus) = upgrade.effect {
                upgradeBonus += bonus
            }
        }
        multiplier *= min(1 + upgradeBonus, 3.0)  // Cap at 3x from upgrades
        
        // Streak multiplier (already capped at 3x in new system)
        multiplier *= streakMultiplier
        
        return multiplier
    }
    
    /// BALANCED: Streak multiplier capped at 3x (was 20x) to prevent runaway income
    var streakMultiplier: Double {
        switch currentStreak {
        case 0..<50: return 1.0
        case 50..<150: return 1.25
        case 150..<300: return 1.5
        case 300..<500: return 2.0
        case 500..<1000: return 2.5
        default: return 3.0  // Max 3x, not 20x
        }
    }
    
    /// Tap value scales with progress - each tap represents a "deal" or "sale"
    /// Starting at $1-5 feels meaningful, scaling to $1000+ for big deals
    var baseTapValue: Double {
        switch totalEarned {
        case 0..<1_000: return 1.0                      // Selling small items ($1-5 with multipliers)
        case 1_000..<10_000: return 2.0                 // Garage sales, small gigs
        case 10_000..<100_000: return 5.0               // Side hustle deals
        case 100_000..<1_000_000: return 15.0           // Freelance projects
        case 1_000_000..<10_000_000: return 50.0        // Business contracts
        case 10_000_000..<100_000_000: return 150.0     // Major deals
        case 100_000_000..<1_000_000_000: return 500.0  // Corporate contracts
        case 1_000_000_000..<10_000_000_000: return 2_000.0   // Multi-million deals
        case 10_000_000_000..<100_000_000_000: return 10_000.0  // Massive transactions
        default: return 50_000.0  // Billionaire-scale deals
        }
    }
    
    var tapValue: Double {
        var value = baseTapValue * tapMultiplier * prestigeManager.legacyMultiplier
        
        // Apply research bonus
        value *= researchManager.totalTapMultiplier
        
        // Apply economic cycle revenue modifier
        value *= economicCycleManager.state.currentPhase.revenueMultiplier
        
        // Apply synergy bonus
        value *= synergyManager.getMultiplier(for: .tapValue)
        
        return value
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
        
        // Add research bonus
        bonus += researchManager.totalOpportunityBonus
        
        // Add synergy bonus (convert multiplier to additive)
        let synergyMultiplier = synergyManager.getMultiplier(for: .opportunitySuccess)
        if synergyMultiplier > 1.0 {
            bonus += (synergyMultiplier - 1.0)
        }
        
        return bonus
    }
    
    // MARK: - Reward Scaling
    // Scales all rewards (opportunities, daily challenges, etc.) based on net worth
    // This ensures rewards remain meaningful at all wealth levels
    
    /// Get the reward scaling multiplier based on current net worth
    /// BALANCED: Uses logarithmic scaling instead of exponential to prevent runaway growth
    var rewardScaleMultiplier: Double {
        // Logarithmic growth: log10(netWorth) - 2, squared, capped at 1000x
        // This gives much slower scaling than the previous exponential approach
        // At $100 = 0x (min 1), $10K = 1x, $1M = 4x, $100M = 16x, $10B = 49x, $1T = 81x, max = 1000x
        let logScale = max(1.0, log10(max(100, netWorth)) - 2)
        return min(logScale * logScale, 1000.0)
    }
    
    /// Scale a base reward amount to be meaningful at current wealth level
    func scaleReward(_ baseAmount: Double) -> Double {
        return baseAmount * rewardScaleMultiplier
    }
    
    /// Get a meaningful reward based on current wealth (as percentage of net worth)
    /// percentage: 0.001 = 0.1% of net worth, 0.01 = 1%, etc.
    func meaningfulReward(percentage: Double = 0.01) -> Double {
        let reward = netWorth * percentage
        return max(100, min(reward, netWorth * 0.1))  // At least $100, at most 10% of net worth
    }
    
    /// Get a scaled opportunity reward
    func scaledOpportunityReward(_ baseReward: Double) -> Double {
        // Use the higher of: scaled base reward OR percentage of net worth
        let scaled = scaleReward(baseReward)
        let percentBased = meaningfulReward(percentage: 0.005)  // 0.5% of net worth
        return max(scaled, percentBased)
    }
    
    /// BALANCED: Phase-based income cap per tick (0.1 seconds)
    /// Early phases have strict caps, late game allows more but still bounded
    var maxIncomePerTick: Double {
        switch currentPhase {
        case .hustle: return 100               // Max $1K/sec = $86K/day
        case .careerLeverage: return 1_000     // Max $10K/sec = $864K/day
        case .portfolioEngine: return 10_000   // Max $100K/sec = $8.6M/day
        case .legacyScale: return 100_000      // Max $1M/sec = $86M/day
        }
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
        contacts.filter { contact in
            // Basic requirements
            guard contact.phaseRequired.rawValue <= currentPhase.rawValue,
                  statusPoints >= contact.statusRequired,
                  !contact.hasMet else {
                return false
            }
            
            // Career level requirement - must have reached a certain role level
            if contact.careerLevelRequired > 0 {
                guard currentRoleIndex >= contact.careerLevelRequired else {
                    return false  // Player hasn't reached required career level
                }
            }
            
            // Career path filtering - nil means available to all careers
            if let contactCareer = contact.careerPath {
                // Contact is career-specific
                guard let playerCareer = selectedCareer else {
                    return false  // Player hasn't selected career yet
                }
                return contactCareer == playerCareer
            }
            
            // Contact available to all careers
            return true
        }
    }
    
    var availableProducts: [Product] {
        products.filter { !$0.launched }
    }
    
    // MARK: - Initialization
    
    init() {
        // Load saved state with hard caps to prevent overflow bugs
        let loadedCash = UserDefaults.standard.double(forKey: "cash")
        self.cash = min(loadedCash, GameState.maxNetWorth)
        if loadedCash > GameState.maxNetWorth {
            print("⚠️ Loaded cash was \(loadedCash), capped to \(GameState.maxNetWorth)")
        }
        
        let loadedEarned = UserDefaults.standard.double(forKey: "totalEarned")
        self.totalEarned = min(loadedEarned, GameState.maxNetWorth * 10)
        self.highestNetWorth = UserDefaults.standard.double(forKey: "highestNetWorth")
        self.statusPoints = UserDefaults.standard.integer(forKey: "statusPoints")
        self.totalTaps = UserDefaults.standard.integer(forKey: "totalTaps")
        self.highestStreak = UserDefaults.standard.integer(forKey: "highestStreak")
        self.dailySales = UserDefaults.standard.integer(forKey: "dailySales")
        self.lastSalesResetDay = UserDefaults.standard.integer(forKey: "lastSalesResetDay")
        self.currentRoleIndex = UserDefaults.standard.integer(forKey: "currentRoleIndex")
        
        // Load unlocked zones (permanent unlocks)
        if let zoneArray = UserDefaults.standard.stringArray(forKey: "unlockedZones") {
            self.unlockedZones = Set(zoneArray)
        } else {
            self.unlockedZones = ["Hustle"] // Hustle is always unlocked
        }
        
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
        
        // Load auto-tappers
        if let data = UserDefaults.standard.data(forKey: "autoTappers"),
           let decoded = try? JSONDecoder().decode([AutoTapper].self, from: data) {
            self.autoTappers = decoded
        } else {
            self.autoTappers = allAutoTappers
        }
        
        startGameLoop()
    }
    
    // MARK: - Game Loop
    
    func startGameLoop() {
        // Create timer for main game loop (0.1s interval)
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        // Add to .common mode so it continues during scrolling
        RunLoop.main.add(timer, forMode: .common)
        gameTimer = timer
        
        // Create timer for opportunity generation (30s interval)
        let oppTimer = Timer(timeInterval: 30, repeats: true) { [weak self] _ in
            self?.generateOpportunity()
        }
        // Also add to .common mode
        RunLoop.main.add(oppTimer, forMode: .common)
        opportunityTimer = oppTimer
    }
    
    // Track game day for daily sales reset (1 game week = ~5.77 real seconds)
    private var gameDayAccumulator: TimeInterval = 0
    private let secondsPerGameWeek: TimeInterval = 5.77  // 300 seconds per year / 52 weeks
    
    func tick() {
        let deltaTime: TimeInterval = 0.1
        
        // ═══════════════════════════════════════════════════════════
        // HARD CAP SAFEGUARD - Prevent trillion dollar glitch
        // ═══════════════════════════════════════════════════════════
        if cash > GameState.maxNetWorth {
            print("⚠️ CASH OVERFLOW DETECTED: \(cash) - capping to \(GameState.maxNetWorth)")
            cash = GameState.maxNetWorth
        }
        if totalEarned > GameState.maxNetWorth * 10 {
            print("⚠️ TOTAL EARNED OVERFLOW DETECTED: \(totalEarned)")
            totalEarned = GameState.maxNetWorth * 10
        }
        
        // Track game weeks and reset daily sales each week
        gameDayAccumulator += deltaTime
        if gameDayAccumulator >= secondsPerGameWeek {
            gameDayAccumulator = 0
            dailySales = 0  // Reset daily sales limit at start of each game week
        }
        
        // Passive income - track by source for taxes
        let salaryIncome = (currentRole?.salary ?? 0) / LifeCycleConstants.secondsPerGameYear * deltaTime
        let hustleIncome = autoTapperIncomePerSecond * deltaTime
        let passiveUpgradeIncome = calculateUpgradePassiveIncome() * deltaTime
        let productIncome = calculateProductIncome() * deltaTime
        
        let totalIncome = salaryIncome + hustleIncome + passiveUpgradeIncome + productIncome
        
        // BALANCED: Phase-based income cap per tick (0.1 seconds) to prevent runaway values
        let cappedIncome = min(totalIncome, maxIncomePerTick)
        
        if cappedIncome > 0 && cash < GameState.maxNetWorth {
            cash += cappedIncome
            totalEarned += cappedIncome
            
            // Track for taxes
            TaxManager.shared.recordSalaryIncome(salaryIncome)
            TaxManager.shared.recordHustleIncome(hustleIncome)
            TaxManager.shared.recordPassiveIncome(passiveUpgradeIncome + productIncome)
        }
        
        // Accumulate investment gains (these compound at year-end)
        accumulateInvestmentGains(deltaTime: deltaTime)
        
        // Sync financial wealth with net worth
        let netWorth = cash + totalInvestmentValue
        wealthManager.syncFinancialWealth(netWorth: netWorth)
        
        // Track highest net worth achieved
        if netWorth > highestNetWorth {
            highestNetWorth = netWorth
        }
        
        // Lifecycle tick - check for year-end
        if let yearEndEvent = lifecycleManager.tick(deltaTime: deltaTime) {
            processYearEnd(event: yearEndEvent)
        }
        
        // Market events tick
        marketEventManager.tick()
        
        // Check phase unlock
        checkPhaseUnlock()
        
        // Check zone unlocks (permanent)
        checkZoneUnlocks()
        
        // Check achievements
        achievementManager.checkAchievements(game: self)
        
        // Check Game Center achievements (less frequently to avoid spam)
        if totalTaps % 100 == 0 {
            GameCenterManager.shared.checkAchievements(game: self)
        }
        
        // Decay streak if no recent taps
        if Date().timeIntervalSince(lastTapTime) > streakTimeLimit && currentStreak > 0 {
            currentStreak = 0
        }
        
        // Opportunity cooldown
        if opportunityCooldown > 0 {
            opportunityCooldown -= deltaTime
        }
        
        // Check for health-based early death risk
        if wealthManager.isAtRiskOfBurnout && lifecycleManager.currentAge >= 40 {
            // Small chance of early death when burned out and older
            if Double.random(in: 0...1) < wealthManager.earlyDeathRisk * 0.0001 {
                lifecycleManager.showRetirementPrompt = true
            }
        }
    }
    
    // MARK: - Investment Accumulation
    
    // Maximum net worth cap to prevent overflow/runaway bugs
    static let maxNetWorth: Double = 10_000_000_000_000 // $10 trillion cap
    
    func accumulateInvestmentGains(deltaTime: TimeInterval) {
        // Investment gains accumulate based on game time (1 min = 1 year)
        // FIXED: Returns now work as expected - $200M at 10% = ~$20M/year
        let yearFraction = deltaTime / LifeCycleConstants.secondsPerGameYear
        
        // Sanity check: if net worth exceeds cap, don't accumulate more gains
        guard netWorth < GameState.maxNetWorth else { return }
        
        for i in 0..<investments.count where investments[i].amountInvested > 0 {
            let investment = investments[i]
            
            // Get the investment's sentiment (affects returns mildly)
            let sentiment = InvestmentSentimentManager.shared.getSentiment(for: investment.id)
            // Sentiment multiplier is now gentler (0.9 to 1.1 range instead of full range)
            let sentimentMultiplier = 0.9 + (sentiment.level.returnMultiplier * 0.2)
            
            // Base annual return (e.g., 0.10 = 10%)
            let baseReturn = investment.baseReturn
            
            // Apply volatility as a PERCENTAGE of the return, not an absolute offset
            // Volatility of 0.28 now means returns vary ±28% OF the base return
            // e.g., 10% base with 0.28 volatility = 7.2% to 12.8% (not -18% to +38%)
            let volatility = investment.volatility
            let volatilityFactor = Double.random(in: (1.0 - volatility * 0.5)...(1.0 + volatility * 0.5))
            
            // Calculate actual return rate
            var actualReturnRate = baseReturn * sentimentMultiplier * volatilityFactor
            
            // For extreme risk investments (negative base return), keep them risky
            if baseReturn < 0 {
                actualReturnRate = baseReturn * volatilityFactor  // Bad investments stay bad
            }
            
            // Calculate the annual gain amount
            // $200M at 10% = $20M per year
            let annualGainAmount = investment.amountInvested * actualReturnRate
            
            // Apply bonus multipliers (these ADD to gains, not multiply them down)
            let marketMultiplier = marketEventManager.getMultiplier(for: investment.id)
            let networkingMultiplier = getNetworkingInvestmentModifier(for: investment.id)
            let bonusMultiplier = 1.0 + investmentBonusMultiplier
            let prestigeMultiplier = prestigeManager.legacyMultiplier
            
            // Strategic system multipliers
            let economicMultiplier = economicCycleManager.state.currentPhase.investmentMultiplier
            let researchBonus = 1.0 + researchManager.totalInvestmentBonus
            let synergyBonus = synergyManager.getMultiplier(for: .investmentReturns)
            
            // Combine all positive multipliers
            let totalMultiplier = marketMultiplier * networkingMultiplier * bonusMultiplier * prestigeMultiplier * economicMultiplier * researchBonus * synergyBonus
            
            // Calculate gains for this time slice
            var gains = annualGainAmount * yearFraction * totalMultiplier
            
            // During contractions, gains are reduced (not losses amplified)
            if economicCycleManager.state.currentPhase == .contraction || economicCycleManager.state.currentPhase == .trough {
                gains *= 0.7 // 30% reduction in bad economy
            }
            
            // Cap individual investment to prevent overflow
            let newValue = investment.totalValue + gains
            if newValue > 0 && newValue < GameState.maxNetWorth {
                investments[i].unrealizedGains += gains
            } else if newValue <= 0 {
                // Investment lost - but cap the loss to prevent going negative
                investments[i].unrealizedGains = -investment.amountInvested * 0.9 // Lose 90% max
            }
        }
    }
    
    // MARK: - Year End Processing
    
    func processYearEnd(event: YearEndEvent) {
        // ═══════════════════════════════════════════════════════════
        // SAFETY: Track starting cash and limit total deductions to 50%
        // This prevents the "cash reset to zero" bug
        // ═══════════════════════════════════════════════════════════
        let startingCash = cash
        let maxTotalDeduction = startingCash * 0.5  // Never take more than 50% of cash in one year
        var totalDeducted: Double = 0
        
        // Compound all investment gains (with partnership bonuses)
        var totalCompoundedGains: Double = 0
        for i in 0..<investments.count where investments[i].amountInvested > 0 {
            let gains = investments[i].unrealizedGains
            
            // Apply partnership investment bonuses
            let partnershipBonus = PartnershipManager.shared.getInvestmentBonus(for: investments[i].id)
            let adjustedGains = gains * (1 + partnershipBonus)
            
            investments[i].amountInvested += adjustedGains
            totalCompoundedGains += adjustedGains
            investments[i].unrealizedGains = 0
        }
        
        // Add compounded gains to total earned
        if totalCompoundedGains > 0 {
            totalEarned += totalCompoundedGains
            
            // Announce in news feed
            NewsFeedManager.shared.addNews(
                category: .personal,
                headline: "📈 Investment returns: +\(formatCompact(totalCompoundedGains))"
            )
        }
        
        // ═══════════════════════════════════════════════════════════
        // CONSEQUENCE SYSTEM - Monthly Expenses & Lifestyle Costs
        // (Now capped to prevent cash drain)
        // ═══════════════════════════════════════════════════════════
        
        let yearlyExpenses = calculateYearlyExpenses()
        if yearlyExpenses > 0 && totalDeducted < maxTotalDeduction {
            let affordableExpenses = min(yearlyExpenses, maxTotalDeduction - totalDeducted, cash * 0.2)
            if affordableExpenses > 0 {
                cash -= affordableExpenses
                totalDeducted += affordableExpenses
                CreditManager.shared.modifyScore(by: 3, reason: "Living expenses paid")
            }
        }
        
        // Process partnership yearly costs
        // Partnership costs (capped)
        // PartnershipManager.shared.processYearlyPartnershipCosts(game: self) // Temporarily disabled - was causing cash drain
        
        // ═══════════════════════════════════════════════════════════
        // TAX SYSTEM - Year-End Taxes (capped to prevent cash drain)
        // ═══════════════════════════════════════════════════════════
        
        // Record investment gains as income for tax purposes
        if totalCompoundedGains > 0 {
            TaxManager.shared.recordInvestmentIncome(totalCompoundedGains)
        }
        
        // Process taxes (capped to max deduction limit)
        let (taxBill, _) = TaxManager.shared.processYearEnd(game: self)
        if taxBill > 0 && totalDeducted < maxTotalDeduction {
            let affordableTax = min(taxBill, maxTotalDeduction - totalDeducted, cash * 0.15)
            if affordableTax > 0 {
                cash -= affordableTax
                totalDeducted += affordableTax
                NewsFeedManager.shared.addNews(
                    category: .markets,
                    headline: "💰 Taxes: \(formatCompact(affordableTax))"
                )
            }
        }
        
        // Age credit account
        CreditManager.shared.ageAccountByMonth()
        for _ in 0..<11 {
            CreditManager.shared.ageAccountByMonth()
        }
        
        // ═══════════════════════════════════════════════════════════
        // COMPANY HEALTH - Payroll (capped to prevent cash drain)
        // ═══════════════════════════════════════════════════════════
        
        let companyManager = CompanyManager.shared
        let payroll = companyManager.annualPayroll
        
        if payroll > 0 && companyManager.state.totalEmployees > 0 && totalDeducted < maxTotalDeduction {
            let affordablePayroll = min(payroll, maxTotalDeduction - totalDeducted, cash * 0.10)
            if affordablePayroll > 0 {
                cash -= affordablePayroll
                totalDeducted += affordablePayroll
                NewsFeedManager.shared.addNews(
                    category: .personal,
                    headline: "💼 Payroll: \(formatCompact(affordablePayroll)) for \(companyManager.state.totalEmployees) employees"
                )
            }
        }
        
        // Check staffing levels (info only, no additional drain)
        let status = companyManager.staffingStatus
        if companyManager.isUnderstaffed {
            NewsFeedManager.shared.addNews(
                category: .personal,
                headline: "\(status.icon) \(status.message)"
            )
        }
        
        // Process company health (no cash cost, just valuation effects)
        let (_, decay, failed) = companyManager.processYearlyCompanyHealth()
        
        if failed {
            NewsFeedManager.shared.addNews(
                category: .personal,
                headline: "💀 COMPANY CRISIS! Severely understaffed - operations collapsing! Lost \(formatCompact(decay)) in valuation"
            )
        } else if decay > 0 {
            NewsFeedManager.shared.addNews(
                category: .personal,
                headline: "⚠️ Company health declining. Valuation down \(formatCompact(decay)) - hire more staff!"
            )
        }
        
        // Show hiring voucher reminder if they have vouchers
        if companyManager.state.departmentState.totalVouchers > 0 {
            NewsFeedManager.shared.addNews(
                category: .personal,
                headline: "🎫 Reminder: You have \(companyManager.state.departmentState.totalVouchers) hiring vouchers! Use them to hire at 50% off."
            )
        }
        
        // ═══════════════════════════════════════════════════════════
        // STRATEGIC SYSTEMS - Year-End Processing
        // ═══════════════════════════════════════════════════════════
        
        // Process economic cycle
        let cycleChanged = economicCycleManager.processYear()
        if cycleChanged {
            FeedbackCoordinator.shared.opportunityAppear()
        }
        
        // Process research progress
        researchManager.processYear()
        
        // Process competitors
        competitorManager.processYear(playerNetWorth: netWorth)
        
        // Check for strategic events
        strategicEventManager.checkForEvent(
            netWorth: netWorth,
            phase: currentPhase.rawValue,
            currentYear: lifecycleManager.gameYearsPassed
        )
        
        // Check synergies
        synergyManager.checkSynergies(game: self)
        
        // ═══════════════════════════════════════════════════════════
        // VENTURE SYSTEM - Serial Entrepreneur companies
        // ═══════════════════════════════════════════════════════════
        
        let ventureManager = VentureManager.shared
        if ventureManager.state.ventures.count > 0 {
            ventureManager.processYear()
            
            let ventureProfit = ventureManager.state.totalVentureProfit
            if ventureProfit > 0 {
                cash += ventureProfit
                totalEarned += ventureProfit
                NewsFeedManager.shared.addNews(
                    category: .personal,
                    headline: "🏢 Venture profits: +\(formatCompact(ventureProfit)) from \(ventureManager.state.activeVentures.count) companies"
                )
            }
        }
        
        // ═══════════════════════════════════════════════════════════
        
        // Apply wealth dimension yearly decay
        wealthManager.processYearEnd()
        
        // Process family yearly events
        familyManager.processYear(currentYear: lifecycleManager.gameYearsPassed + lifecycleManager.startingAge)
        
        // Child expenses (capped to total deduction limit)
        let childExpenses = familyManager.state.totalChildExpenses
        if childExpenses > 0 && totalDeducted < maxTotalDeduction {
            let affordableChild = min(childExpenses, maxTotalDeduction - totalDeducted, cash * 0.05)
            if affordableChild > 0 {
                cash -= affordableChild
                totalDeducted += affordableChild
                NewsFeedManager.shared.addNews(
                    category: .personal,
                    headline: "👨‍👩‍👧‍👦 Family: \(formatCompact(affordableChild))"
                )
            }
        }
        
        // Partner income contribution (this ADDS money, always good)
        if let partner = familyManager.state.partner, partner.isMarried {
            let partnerIncome = partner.incomeContribution
            if partnerIncome > 0 {
                cash += partnerIncome
                totalEarned += partnerIncome
            }
        }
        
        // Check for forced retirement
        if event.mustRetire {
            lifecycleManager.showRetirementPrompt = true
        }
        
        // ═══════════════════════════════════════════════════════════
        // YEAR-END SUMMARY
        // ═══════════════════════════════════════════════════════════
        let finalCash = cash
        let netChange = finalCash - startingCash + totalCompoundedGains
        
        if netChange >= 0 {
            print("📈 Year-end: Started with \(formatCompact(startingCash)), ended with \(formatCompact(finalCash)) (+\(formatCompact(netChange)))")
        } else {
            print("📉 Year-end: Started with \(formatCompact(startingCash)), ended with \(formatCompact(finalCash)) (\(formatCompact(netChange)))")
        }
        
        // SAFETY: Ensure cash never goes negative
        if cash < 0 {
            cash = 0
        }
    }
    
    // MARK: - Expense Calculation (Consequence System)
    
    /// Calculate yearly expenses based on lifestyle level
    var lifestyleLevel: Int {
        // Lifestyle scales with net worth
        switch netWorth {
        case 0..<10_000: return 1          // Minimal
        case 10_000..<100_000: return 2    // Basic
        case 100_000..<500_000: return 3   // Comfortable
        case 500_000..<1_000_000: return 4 // Upper Middle
        case 1_000_000..<10_000_000: return 5  // Wealthy
        case 10_000_000..<100_000_000: return 6  // Very Wealthy
        case 100_000_000..<1_000_000_000: return 7  // Ultra Wealthy
        default: return 8  // Billionaire lifestyle
        }
    }
    
    func calculateYearlyExpenses() -> Double {
        var expenses: Double = 0
        
        // FIXED: Scale expenses with CASH income, not just net worth
        // This prevents the death spiral where high investments = high expenses = cash drain
        
        // Calculate actual "lifestyle" based on passive income + cash, not total net worth
        let yearlyPassiveIncome = passiveIncomePerSecond * 60 * 5  // 5 min real time = 1 year
        let affordableLifestyle = max(cash, yearlyPassiveIncome * 12)  // What they can actually afford
        
        // Lifestyle expenses are 5-15% of what you can afford (scales with status)
        let lifestyleRate = 0.05 + (Double(statusPoints) * 0.0001)  // 5% base + 0.01% per status point
        let baseExpenses = affordableLifestyle * min(0.15, lifestyleRate)  // Cap at 15%
        expenses += baseExpenses
        
        // Housing costs (fixed, not scaling)
        if housing.status == .ownsHome {
            expenses += housing.monthlyPayment * 12  // Mortgage
            expenses += housing.propertyValue * 0.01  // 1% maintenance (reduced from 1.5%)
        } else {
            // Rent: reasonable scaling, capped
            let rentCost = min(120_000, 12_000 * Double(lifestyleLevel))  // Max $10K/month rent
            expenses += rentCost
        }
        
        // Career-related expenses (modest)
        if selectedCareer != nil {
            expenses += 2000 * Double(currentRoleIndex + 1)  // Professional expenses
        }
        
        // Apply credit score modifier (poor credit = higher costs)
        let creditMultiplier = CreditManager.shared.state.tier.purchaseCostMultiplier
        expenses *= creditMultiplier
        
        // SAFETY: Never charge more than 25% of cash in expenses
        let maxAffordable = cash * 0.25
        return min(expenses, maxAffordable)
    }
    
    // MARK: - Energy-Based Actions
    
    func performAction(_ action: ActionType) -> Bool {
        // Try to consume energy
        guard energyManager.performAction(action) else {
            return false
        }
        
        // Apply wealth impact
        wealthManager.applyImpact(action.wealthImpact)
        
        // Track work vs leisure time
        switch action {
        case .workOvertime, .invest, .network, .opportunity:
            workTimeMinutes += 1
        case .familyTime, .rest, .vacation, .exercise:
            leisureTimeMinutes += 1
        case .tap, .philanthropy:
            break  // Neutral
        }
        
        // Handle specific action effects
        switch action {
        case .workOvertime:
            // Bonus cash for overtime
            let bonus = (currentRole?.salary ?? 50000) * 0.1
            cash += bonus
            totalEarned += bonus
        case .exercise:
            // Health boost already in wealth impact
            break
        case .philanthropy:
            // Give away some money for legacy
            let donation = min(cash * 0.05, 100000)
            cash -= donation
        default:
            break
        }
        
        return true
    }
    
    // MARK: - Actions
    
    func tap() {
        // Check if we can make a sale today
        guard canMakeSale else {
            // At daily limit - provide feedback
            HapticManager.shared.warning()
            return
        }
        
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
        dailySales += 1  // Count against daily limit
        
        // Track for taxes (tapping is hustle/self-employment income)
        TaxManager.shared.recordHustleIncome(tapValue)
        
        // Track for daily challenges
        DailySystemManager.shared.recordTap()
        DailySystemManager.shared.recordEarning(tapValue)
        DailySystemManager.shared.recordStreak(currentStreak)
        
        // Small status point gain from tapping
        if totalTaps % 100 == 0 {
            statusPoints += 1
        }
        
        // ═══════════════════════════════════════════════════════════
        // TAP MILESTONES - Celebrate the hustle!
        // ═══════════════════════════════════════════════════════════
        checkTapMilestone()
    }
    
    // MARK: - Tap Milestones
    
    @Published var currentTapMilestone: TapMilestone? = nil
    
    struct TapMilestone: Identifiable {
        let id = UUID()
        let taps: Int
        let title: String
        let message: String
        let emoji: String
        let bonusCash: Double
    }
    
    static let tapMilestones: [Int: (title: String, message: String, emoji: String, bonusMultiplier: Double)] = [
        // Early milestones - celebrate the beginning!
        50: ("FIRST STEPS!", "50 taps! Every empire starts with a single tap!", "👶", 5),
        100: ("GETTING STARTED!", "100 taps! You're warming up, keep it going!", "🌱", 10),
        250: ("PICKING UP STEAM!", "250 taps! Now you're getting the hang of it!", "💨", 25),
        500: ("NICE HUSTLE!", "500 taps! You little hustler! The grind is paying off!", "🔥", 50),
        750: ("ON A ROLL!", "750 taps! Nothing can slow you down now!", "🎯", 75),
        
        // Core milestones
        1000: ("HUSTLER!", "1,000 taps! You've got that grind mentality. Keep going!", "💪", 100),
        2500: ("DETERMINED!", "2,500 taps! Most people quit by now. Not you!", "🎖️", 250),
        5000: ("GRINDER!", "5,000 taps! Your work ethic is unmatched!", "⚡", 500),
        7500: ("UNSTOPPABLE!", "7,500 taps! You're locked in and focused!", "🔒", 750),
        10000: ("MACHINE!", "10,000 taps! You're built different!", "🤖", 1000),
        
        // Mid-game milestones
        15000: ("CHAMPION!", "15,000 taps! Champions are made, not born!", "🏅", 1500),
        25000: ("RELENTLESS!", "25,000 taps! Nothing can stop you!", "🌪️", 2500),
        50000: ("LEGENDARY!", "50,000 taps! You're in the top 1%!", "👑", 5000),
        75000: ("ELITE!", "75,000 taps! The elite recognize their own!", "⭐", 7500),
        100000: ("IMMORTAL!", "100,000 taps! Your dedication is INSANE!", "🏆", 10000),
        
        // Late-game milestones
        250000: ("TRANSCENDENT!", "250,000 taps! You've achieved the impossible!", "✨", 25000),
        500000: ("GODLIKE!", "500,000 taps! Mere mortals bow before you!", "🌟", 50000),
        750000: ("MYTHICAL!", "750,000 taps! Legends will speak of your hustle!", "🐉", 75000),
        1000000: ("MILLION TAP MASTER!", "1,000,000 TAPS! You are the ultimate hustler!", "💎", 100000)
    ]
    
    private func checkTapMilestone() {
        if let milestone = GameState.tapMilestones[totalTaps] {
            let bonus = milestone.bonusMultiplier * baseTapValue
            cash += bonus
            totalEarned += bonus
            
            currentTapMilestone = TapMilestone(
                taps: totalTaps,
                title: milestone.title,
                message: milestone.message,
                emoji: milestone.emoji,
                bonusCash: bonus
            )
            
            // Haptic feedback
            FeedbackCoordinator.shared.achievement()
            
            // Add to news feed
            NewsFeedManager.shared.addNews(
                category: .personal,
                headline: "\(milestone.emoji) \(milestone.title) You hit \(formatCompact(Double(totalTaps))) taps!"
            )
        }
    }
    
    func selectCareer(_ career: CareerPath) {
        selectedCareer = career
        currentRoleIndex = 0
        if let role = currentRole {
            statusPoints += role.statusPoints
        }
        
        // Apply faction bonus based on career choice
        factionManager.applyCareerBonus(career)
    }
    
    func promote() -> Bool {
        guard let next = nextRole else { return false }
        
        // Check ALL requirements
        guard canPromote else { return false }
        
        // Deduct cost
        cash -= promotionCost
        currentRoleIndex += 1
        statusPoints += next.statusPoints
        
        // Announce the promotion with what was required
        NewsFeedManager.shared.addNews(
            category: .personal,
            headline: "🎉 PROMOTED to \(next.title)! Your network and reputation paid off!"
        )
        
        // Check if max career reached - unlock ventures!
        if let career = selectedCareer {
            VentureManager.shared.checkVentureUnlock(
                careerRoleIndex: currentRoleIndex,
                careerRolesCount: career.roles.count
            )
        }
        
        return true
    }
    
    /// Check if player has reached max career level
    var isMaxCareer: Bool {
        guard let career = selectedCareer else { return false }
        return currentRoleIndex >= career.roles.count - 1
    }
    
    /// Check if ventures are unlocked
    var hasUnlockedVentures: Bool {
        VentureManager.shared.state.hasUnlockedVentures
    }
    
    func invest(in investmentId: String, amount: Double) -> Bool {
        guard let index = investments.firstIndex(where: { $0.id == investmentId }) else { return false }
        guard cash >= amount else { return false }
        guard amount >= investments[index].minInvestment else { return false }
        
        cash -= amount
        investments[index].amountInvested += amount
        
        return true
    }
    
    /// Withdraw from an investment account back to cash
    /// Returns the amount actually withdrawn (may include gains or losses)
    func withdraw(from investmentId: String, amount: Double) -> Double {
        guard let index = investments.firstIndex(where: { $0.id == investmentId }) else { return 0 }
        
        let totalValue = investments[index].totalValue
        let withdrawAmount = min(amount, totalValue)
        
        guard withdrawAmount > 0 else { return 0 }
        
        // Calculate proportional withdrawal from principal and gains
        let proportion = withdrawAmount / totalValue
        let principalWithdrawn = investments[index].amountInvested * proportion
        let gainsWithdrawn = investments[index].unrealizedGains * proportion
        
        // Update investment
        investments[index].amountInvested -= principalWithdrawn
        investments[index].unrealizedGains -= gainsWithdrawn
        
        // Add to cash (gains are now realized)
        cash += withdrawAmount
        if gainsWithdrawn > 0 {
            totalEarned += gainsWithdrawn  // Count realized gains as earnings
        }
        
        return withdrawAmount
    }
    
    /// Withdraw all from an investment
    func withdrawAll(from investmentId: String) -> Double {
        guard let index = investments.firstIndex(where: { $0.id == investmentId }) else { return 0 }
        return withdraw(from: investmentId, amount: investments[index].totalValue)
    }
    
    /// Invest in your own company (adds to company capital)
    func investInCompany(amount: Double) -> Bool {
        guard cash >= amount else { return false }
        guard amount >= 1000 else { return false }  // Minimum $1000 investment
        
        cash -= amount
        CompanyManager.shared.state.totalCapitalRaised += amount
        
        // Update company valuation
        CompanyManager.shared.completeTradeDeal(value: amount)
        
        NewsFeedManager.shared.addNews(
            category: .personal,
            headline: "Invested \(formatCompact(amount)) in \(CompanyManager.shared.state.name)"
        )
        
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
        
        // Luxury items give status but cost money to maintain
        if case .luxuryFlex(let status, let upkeep) = upgrades[index].effect {
            statusPoints += status
            NewsFeedManager.shared.addNews(
                category: .personal,
                headline: "⚠️ Luxury purchase! +\(status) status but costs $\(Int(upkeep))/sec to maintain"
            )
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
    
    /// Result of meeting a contact - includes potential consequences
    struct MeetingResult {
        let success: Bool
        let bonusReceived: Double
        let lawsuitTriggered: Bool
        let lawsuitAmount: Double
        let rivalriesTriggered: [String]  // Names of angry rivals
        let allianceBonus: Double  // Multiplier from alliances
        let message: String
    }
    
    func meetContact(_ contactId: String) -> MeetingResult {
        guard let index = contacts.firstIndex(where: { $0.id == contactId }) else {
            return MeetingResult(success: false, bonusReceived: 0, lawsuitTriggered: false, lawsuitAmount: 0, rivalriesTriggered: [], allianceBonus: 1.0, message: "Contact not found")
        }
        guard !contacts[index].hasMet else {
            return MeetingResult(success: false, bonusReceived: 0, lawsuitTriggered: false, lawsuitAmount: 0, rivalriesTriggered: [], allianceBonus: 1.0, message: "Already met this contact")
        }
        guard statusPoints >= contacts[index].statusRequired else {
            return MeetingResult(success: false, bonusReceived: 0, lawsuitTriggered: false, lawsuitAmount: 0, rivalriesTriggered: [], allianceBonus: 1.0, message: "Not enough status")
        }
        
        let contact = contacts[index]
        let metContactIds = contacts.filter { $0.hasMet }.map { $0.id }
        
        // ═══════════════════════════════════════════════════════════
        // RIVALRY SYSTEM - Check for consequences
        // ═══════════════════════════════════════════════════════════
        
        let rivalries = ContactRivalrySystem.checkRivalries(contactId: contactId, metContacts: metContactIds)
        var lawsuitTriggered = false
        var totalLawsuitDamage: Double = 0
        var angryRivals: [String] = []
        var totalReputationDamage = 0
        
        for rivalry in rivalries {
            // Roll for lawsuit
            if Double.random(in: 0...1) < rivalry.lawsuitChance {
                lawsuitTriggered = true
                let damage = netWorth * rivalry.lawsuitDamage
                totalLawsuitDamage += damage
                angryRivals.append(rivalry.rivalName)
                
                // News announcement
                NewsFeedManager.shared.addNews(
                    category: .breaking,
                    headline: rivalry.newsHeadline
                )
            }
            
            // Reputation damage always happens
            totalReputationDamage += rivalry.reputationDamage
            
            // Apply investment penalty (affects investments for the rest of this game session)
            if let effects = ContactRivalrySystem.investmentEffects[rivalry.rivalId] {
                for investmentId in effects.boost {
                    // The rival's boosted investments now hurt you
                    applyTemporaryInvestmentPenalty(investmentId: investmentId, multiplier: rivalry.investmentPenalty)
                }
            }
        }
        
        // ═══════════════════════════════════════════════════════════
        // ALLIANCE SYSTEM - Check for bonuses
        // ═══════════════════════════════════════════════════════════
        
        let allianceMultiplier = ContactRivalrySystem.getAllianceBonus(contactId: contactId, metContacts: metContactIds)
        
        // ═══════════════════════════════════════════════════════════
        // APPLY EFFECTS
        // ═══════════════════════════════════════════════════════════
        
        contacts[index].hasMet = true
        
        // Calculate final bonus (alliance bonus, minus lawsuit damage)
        var baseBonus = contact.bonusOnMeet * allianceMultiplier
        
        // If rivalries triggered, reduce base bonus significantly
        if !rivalries.isEmpty {
            baseBonus *= 0.5  // Rivalries cut your bonus in half
        }
        
        // Apply lawsuit damage
        if lawsuitTriggered {
            cash -= totalLawsuitDamage
            NewsFeedManager.shared.addNews(
                category: .breaking,
                headline: "⚖️ LAWSUIT FILED! You lose \(formatCompact(totalLawsuitDamage)) in legal fees"
            )
        }
        
        // Apply reputation damage
        if totalReputationDamage > 0 {
            statusPoints = max(0, statusPoints - totalReputationDamage)
        }
        
        // Apply bonus
        cash += baseBonus
        totalEarned += baseBonus
        
        // Standard status gain (reduced if rivalries)
        let statusGain = rivalries.isEmpty ? 10 : 2
        statusPoints += statusGain
        
        // Apply investment boosts for this contact
        if let effects = ContactRivalrySystem.investmentEffects[contactId] {
            for investmentId in effects.boost {
                applyTemporaryInvestmentBoost(investmentId: investmentId, multiplier: 1.15)
            }
        }
        
        // ═══════════════════════════════════════════════════════════
        // COMPANY BENEFITS - Contacts give VOUCHERS (hiring discounts), not free employees!
        // Players must still hire and pay salaries - this just makes it cheaper
        // ═══════════════════════════════════════════════════════════
        
        if let benefit = contact.companyBenefit {
            // Add HIRING VOUCHERS (50% off hiring cost) - NOT free employees!
            if !benefit.hiringVouchers.isEmpty {
                CompanyManager.shared.addHiringVouchers(benefit.hiringVouchers)
                let totalVouchers = benefit.hiringVouchers.values.reduce(0, +)
                let deptNames = benefit.hiringVouchers.keys.joined(separator: ", ")
                NewsFeedManager.shared.addNews(
                    category: .personal,
                    headline: "🎫 \(contact.name) gave you \(totalVouchers) hiring voucher(s) for \(deptNames)! (50% off hiring)"
                )
            }
            
            // Unlock industry
            if let industryRaw = benefit.industryUnlock,
               let industry = Industry(rawValue: industryRaw) {
                CompanyManager.shared.enterIndustry(industry)
                NewsFeedManager.shared.addNews(
                    category: .personal,
                    headline: "🏭 \(contact.name) helped you enter the \(industry.rawValue) industry!"
                )
            }
            
            // Add capital
            if benefit.capitalRaised > 0 {
                CompanyManager.shared.state.totalCapitalRaised += benefit.capitalRaised
                NewsFeedManager.shared.addNews(
                    category: .personal,
                    headline: "💰 \(contact.name) helped raise \(formatCompact(benefit.capitalRaised)) in capital!"
                )
            }
            
            // Trade deal value
            if benefit.tradeDealValue > 0 {
                CompanyManager.shared.completeTradeDeal(value: benefit.tradeDealValue)
                NewsFeedManager.shared.addNews(
                    category: .personal,
                    headline: "📈 \(contact.name) brokered a \(formatCompact(benefit.tradeDealValue)) trade deal!"
                )
            }
        }
        
        // Build result message
        var message = "Met \(contact.name)! +\(formatCompact(baseBonus))"
        if allianceMultiplier > 1.0 {
            message += " (Alliance bonus: \(Int((allianceMultiplier - 1) * 100))%)"
        }
        if lawsuitTriggered {
            message += " ⚠️ SUED for \(formatCompact(totalLawsuitDamage))!"
        }
        if !angryRivals.isEmpty {
            message += " 😡 \(angryRivals.joined(separator: ", ")) not happy!"
        }
        
        return MeetingResult(
            success: true,
            bonusReceived: baseBonus,
            lawsuitTriggered: lawsuitTriggered,
            lawsuitAmount: totalLawsuitDamage,
            rivalriesTriggered: angryRivals,
            allianceBonus: allianceMultiplier,
            message: message
        )
    }
    
    // Legacy support - simple bool return
    func meetContactSimple(_ contactId: String) -> Bool {
        return meetContact(contactId).success
    }
    
    // MARK: - Investment Modifiers from Networking
    
    private var temporaryInvestmentModifiers: [String: Double] = [:]
    
    func applyTemporaryInvestmentBoost(investmentId: String, multiplier: Double) {
        let current = temporaryInvestmentModifiers[investmentId] ?? 1.0
        temporaryInvestmentModifiers[investmentId] = current * multiplier
    }
    
    func applyTemporaryInvestmentPenalty(investmentId: String, multiplier: Double) {
        let current = temporaryInvestmentModifiers[investmentId] ?? 1.0
        temporaryInvestmentModifiers[investmentId] = current * multiplier
    }
    
    func getNetworkingInvestmentModifier(for investmentId: String) -> Double {
        return temporaryInvestmentModifiers[investmentId] ?? 1.0
    }
    
    func takeOpportunity(_ accept: Bool) -> (success: Bool, message: String)? {
        guard let opportunity = currentOpportunity else { return nil }
        
        defer { currentOpportunity = nil }
        
        if !accept {
            return (true, "Passed on \(opportunity.title)")
        }
        
        // Scale cost and reward to current wealth level
        let scaledCost = scaleReward(opportunity.cost)
        let scaledReward = scaledOpportunityReward(opportunity.successReward)
        
        guard cash >= scaledCost else {
            return (false, "Not enough cash! (Need \(formatCompact(scaledCost)))")
        }
        
        cash -= scaledCost
        
        let adjustedChance = min(opportunity.successChance + opportunityBonusChance, 0.95)
        let roll = Double.random(in: 0...1)
        
        if roll <= adjustedChance {
            cash += scaledReward
            totalEarned += scaledReward
            statusPoints += opportunity.statusBonus
            return (true, "Success! \(opportunity.title) paid off! (+\(formatCompact(scaledReward)))")
        } else {
            return (false, "\(opportunity.title) didn't work out... (-\(formatCompact(scaledCost)))")
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
    
    // MARK: - Auto-Tapper Actions
    
    func purchaseAutoTapper(_ tapperId: String) -> Bool {
        guard let index = autoTappers.firstIndex(where: { $0.id == tapperId }) else { return false }
        guard !autoTappers[index].owned else { return false }
        guard cash >= autoTappers[index].baseCost else { return false }
        
        cash -= autoTappers[index].baseCost
        autoTappers[index].owned = true
        
        FeedbackCoordinator.shared.purchase()
        NewsFeedManager.shared.addNews(
            category: .personal,
            headline: "Hired \(autoTappers[index].name)! Passive tapping engaged."
        )
        
        return true
    }
    
    func upgradeAutoTapper(_ tapperId: String) -> Bool {
        guard let index = autoTappers.firstIndex(where: { $0.id == tapperId }) else { return false }
        guard autoTappers[index].owned else { return false }
        guard cash >= autoTappers[index].upgradeCost else { return false }
        
        cash -= autoTappers[index].upgradeCost
        autoTappers[index].level += 1
        
        FeedbackCoordinator.shared.purchase()
        
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
        // Apply hard cap before saving
        let cappedCash = min(cash, GameState.maxNetWorth)
        if cash != cappedCash {
            print("⚠️ Capped cash from \(cash) to \(cappedCash) before saving")
            cash = cappedCash
        }
        UserDefaults.standard.set(cappedCash, forKey: "cash")
    }
    
    private func savePhase() {
        UserDefaults.standard.set(currentPhase.rawValue, forKey: "currentPhase")
    }
    
    private func saveCareer() {
        UserDefaults.standard.set(selectedCareer?.rawValue, forKey: "selectedCareer")
    }
    
    private func saveUnlockedZones() {
        UserDefaults.standard.set(Array(unlockedZones), forKey: "unlockedZones")
    }
    
    /// Check if a zone should be permanently unlocked based on net worth
    func checkZoneUnlocks() {
        // Zone unlock thresholds (must match GameZone.unlockNetWorth)
        let thresholds: [(zone: String, threshold: Double)] = [
            ("Hustle", 0),
            ("Career", 1_000),
            ("Invest", 10_000),
            ("Empire", 1_000_000),
            ("Legacy", 100_000_000)
        ]
        
        for (zone, threshold) in thresholds {
            if netWorth >= threshold && !unlockedZones.contains(zone) {
                unlockedZones.insert(zone)
            }
        }
    }
    
    /// Check if a zone is permanently unlocked
    func isZonePermanentlyUnlocked(_ zoneName: String) -> Bool {
        unlockedZones.contains(zoneName)
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
    
    private func saveAutoTappers() {
        if let data = try? JSONEncoder().encode(autoTappers) {
            UserDefaults.standard.set(data, forKey: "autoTappers")
        }
    }
    
    // MARK: - Helpers
    
    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        // Show cents for small values, hide for large values
        if abs(value) < 100 {
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
        } else {
            formatter.maximumFractionDigits = 0
        }
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
        case 100...:
            return String(format: "$%.0f", value)
        default:
            // Show cents for small values
            return String(format: "$%.2f", value)
        }
    }
    
    func resetGame() {
        cash = 0
        totalEarned = 0
        statusPoints = 0
        totalTaps = 0
        highestStreak = 0
        currentStreak = 0
        dailySales = 0
        lastSalesResetDay = 0
        currentPhase = .hustle
        selectedCareer = nil
        currentRoleIndex = 0
        investments = allInvestments
        upgrades = allUpgrades
        products = productCatalog
        contacts = allContacts
        housing = Housing()
        autoTappers = allAutoTappers
        currentOpportunity = nil
        unlockedZones = ["Hustle"] // Reset zones to just Hustle
    }
    
    /// Complete wipe of ALL game data - use for debugging stuck states
    /// Call on instance: game.nukeAndReset()
    func nukeAndReset() {
        // Stop the game loop first
        gameTimer?.invalidate()
        gameTimer = nil
        opportunityTimer?.invalidate()
        opportunityTimer = nil
        
        // Clear all UserDefaults
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        
        for key in dictionary.keys {
            defaults.removeObject(forKey: key)
        }
        defaults.synchronize()
        
        // Reset all managers
        TaxManager.shared.resetForPrestige()
        CreditManager.shared.reset()
        FamilyManager.shared.reset()
        FactionManager.shared.reset()
        PartnershipManager.shared.reset()
        DailySystemManager.shared.reset()
        WealthManager.shared.reset()
        LifeCycleManager.shared.reset(keepStartingAge: false)
        CompanyManager.shared.reset()
        EnergyManager.shared.reset()
        PrestigeManager.shared.reset()
        MarketEventManager.shared.reset()
        AchievementManager.shared.reset()
        NewsFeedManager.shared.reset()
        InvestmentSentimentManager.shared.reset()
        
        // Reset strategic systems
        EconomicCycleManager.shared.reset()
        ResearchManager.shared.reset()
        StrategicEventManager.shared.reset()
        CompetitorManager.shared.reset()
        SynergyManager.shared.reset()
        VentureManager.shared.reset()
        
        // Reset THIS GameState instance to fresh values
        cash = 0
        totalEarned = 0
        statusPoints = 0
        totalTaps = 0
        highestStreak = 0
        currentStreak = 0
        dailySales = 0
        lastSalesResetDay = 0
        currentPhase = .hustle
        selectedCareer = nil
        currentRoleIndex = 0
        
        // Reset investments to fresh copies (not corrupted ones)
        investments = allInvestments.map { inv in
            var fresh = inv
            fresh.amountInvested = 0
            fresh.unrealizedGains = 0
            return fresh
        }
        
        upgrades = allUpgrades
        products = productCatalog
        contacts = allContacts
        housing = Housing()
        autoTappers = allAutoTappers
        currentOpportunity = nil
        unlockedZones = ["Hustle"]
        
        // Restart game loop
        startGameLoop()
        
        print("🔥 ALL GAME DATA NUKED AND RESET 🔥")
    }
    
    /// Static version for compatibility
    static func nukeAllData() {
        // This only clears storage - caller needs to also call instance reset
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        for key in dictionary.keys {
            defaults.removeObject(forKey: key)
        }
        defaults.synchronize()
        print("🔥 ALL GAME DATA NUKED (storage only) 🔥")
    }
    
    // MARK: - Prestige Reset
    
    func resetForPrestige() {
        // Get starting cash from prestige bonus
        let startingCash = prestigeManager.getStartingCash()
        
        // Reset game state
        cash = startingCash
        totalEarned = startingCash
        statusPoints = 0
        totalTaps = 0
        dailySales = 0
        lastSalesResetDay = 0
        currentStreak = 0
        currentPhase = .hustle
        selectedCareer = nil
        currentRoleIndex = 0
        investments = allInvestments
        upgrades = allUpgrades
        products = productCatalog
        contacts = allContacts
        housing = Housing()
        autoTappers = allAutoTappers
        currentOpportunity = nil
        unlockedZones = ["Hustle"] // Reset zones for new life
        
        // Reset work time tracking
        workTimeMinutes = 0
        leisureTimeMinutes = 0
        
        // Reset lifecycle (keep starting age preference)
        lifecycleManager.reset(keepStartingAge: true)
        
        // Reset tax tracking for new life
        TaxManager.shared.resetForPrestige()
        
        // Reset daily system
        dailySystemManager.resetForPrestige()
        
        // Reset Life of Wealth systems with ending bonuses if available
        if let ending = prestigeManager.state.lastEnding {
            let bonus = ending.prestigeBonus
            wealthManager.resetWithBonus(multiplier: bonus.financialMultiplier)
        } else {
            wealthManager.reset()
        }
        energyManager.reset()
        factionManager.reset()
        familyManager.reset()
        reflectionManager.reset()
        CompanyManager.shared.reset()
        
        // Reset strategic systems for new life
        EconomicCycleManager.shared.reset()
        ResearchManager.shared.reset()
        StrategicEventManager.shared.reset()
        CompetitorManager.shared.reset()
        SynergyManager.shared.reset()
        VentureManager.shared.reset()
        
        // Restore preserved unlocks
        prestigeManager.restoreUnlocks(
            themeManager: ThemeManager.shared,
            educationManager: EducationManager.shared,
            achievementManager: achievementManager
        )
        
        // Announce new life
        NewsFeedManager.shared.addNews(
            category: .breaking,
            headline: "A new life begins! Legacy multiplier: \(prestigeManager.formattedMultiplier)"
        )
        
        FeedbackCoordinator.shared.phaseUnlock()
    }
    
    func performPrestige() {
        // Record current life stats
        prestigeManager.prestige(
            currentEarnings: totalEarned,
            currentAge: lifecycleManager.currentAge,
            yearsPlayed: lifecycleManager.gameYearsPassed,
            themeManager: ThemeManager.shared,
            educationManager: EducationManager.shared,
            achievementManager: achievementManager
        )
        
        // Reset for new life
        resetForPrestige()
    }
}
