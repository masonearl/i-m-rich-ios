//
//  CompanySystem.swift
//  I'm Rich
//
//  Company building, employee tracking, and billionaire leaderboard
//

import SwiftUI
import Combine

// MARK: - Department Types
enum Department: String, Codable, CaseIterable, Identifiable {
    case engineering = "Engineering"
    case sales = "Sales"
    case marketing = "Marketing"
    case hr = "HR"
    case finance = "Finance"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .engineering: return "👨‍💻"
        case .sales: return "📈"
        case .marketing: return "📣"
        case .hr: return "👥"
        case .finance: return "💰"
        }
    }
    
    var baseSalary: Double {
        switch self {
        case .engineering: return 120_000
        case .sales: return 80_000
        case .marketing: return 75_000
        case .hr: return 70_000
        case .finance: return 100_000
        }
    }
    
    var hireCost: Double {
        baseSalary * 2  // 2x salary to hire
    }
    
    var description: String {
        switch self {
        case .engineering: return "Product success rate +10% per engineer"
        case .sales: return "Revenue multiplier +5% per salesperson"
        case .marketing: return "Contact bonuses +10%, daily sales +20"
        case .hr: return "Prevents 15%/year valuation decay"
        case .finance: return "Investment returns +2% per analyst"
        }
    }
    
    /// Maximum employees per department, scales with company size tier
    /// INCREASED: Now supports much larger companies (10,000+ total employees possible)
    func maxEmployees(companyTier: Int) -> Int {
        // Tier 0 = Solo, 1 = Startup, 2 = Small, etc.
        // Base values significantly increased for bigger companies
        let base: Int
        switch self {
        case .engineering: base = 100   // Was 10 - now supports 600 engineers at max tier
        case .sales: base = 80          // Was 8 - now supports 480 salespeople at max tier
        case .marketing: base = 50      // Was 5 - now supports 300 marketers at max tier
        case .hr: base = 30             // Was 3 - now supports 180 HR at max tier
        case .finance: base = 50        // Was 5 - now supports 300 analysts at max tier
        }
        return base * max(1, companyTier)
    }
    
    /// Get the current max for display purposes
    func maxForDisplay(companyTier: Int) -> String {
        "\(maxEmployees(companyTier: companyTier))"
    }
}

// MARK: - Department State
struct DepartmentState: Codable {
    var employees: [String: Int] = [:]       // Department rawValue -> count
    var hiringVouchers: [String: Int] = [:]  // Department rawValue -> voucher count (50% off)
    var lastHRCheck: Int = 0                 // Game year of last HR check
    
    func getCount(for department: Department) -> Int {
        employees[department.rawValue] ?? 0
    }
    
    func getVouchers(for department: Department) -> Int {
        hiringVouchers[department.rawValue] ?? 0
    }
    
    mutating func addEmployee(to department: Department, count: Int = 1) {
        let current = employees[department.rawValue] ?? 0
        employees[department.rawValue] = current + count
    }
    
    mutating func addVouchers(to department: Department, count: Int) {
        let current = hiringVouchers[department.rawValue] ?? 0
        hiringVouchers[department.rawValue] = current + count
    }
    
    mutating func useVoucher(for department: Department) -> Bool {
        let current = hiringVouchers[department.rawValue] ?? 0
        guard current > 0 else { return false }
        hiringVouchers[department.rawValue] = current - 1
        return true
    }
    
    var totalDepartmentEmployees: Int {
        employees.values.reduce(0, +)
    }
    
    var totalVouchers: Int {
        hiringVouchers.values.reduce(0, +)
    }
}

// MARK: - Industry Types (Expanded with cool company ideas)
enum Industry: String, Codable, CaseIterable, Identifiable {
    // Original industries
    case software = "Software"
    case space = "Space"
    case robotics = "Robotics"
    case automotive = "Automotive"
    case dataCenters = "Data Centers"
    case solar = "Solar Energy"
    case nuclear = "Nuclear Energy"
    case ai = "Artificial Intelligence"
    case biotech = "Biotechnology"
    case fintech = "Fintech"
    
    // NEW: Cool venture industries (unlocked after max career)
    case ecommerce = "E-Commerce"           // Amazon competitor
    case socialMedia = "Social Media"        // Meta competitor
    case streaming = "Streaming"             // Netflix competitor
    case gaming = "Gaming"                   // Epic/Valve competitor
    case crypto = "Crypto & Web3"            // Coinbase competitor
    case defenseTech = "Defense Tech"        // Anduril competitor
    case healthcare = "Healthcare"           // Oscar/One Medical competitor
    case foodTech = "Food Tech"              // DoorDash competitor
    case realEstateTech = "Real Estate Tech" // Zillow competitor
    case logistics = "Logistics"             // FedEx competitor
    case media = "Media Empire"              // Disney competitor
    case fashion = "Fashion Tech"            // LVMH competitor
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .software: return "💻"
        case .space: return "🚀"
        case .robotics: return "🤖"
        case .automotive: return "🚗"
        case .dataCenters: return "🖥️"
        case .solar: return "☀️"
        case .nuclear: return "⚛️"
        case .ai: return "🧠"
        case .biotech: return "🧬"
        case .fintech: return "💰"
        // New industries
        case .ecommerce: return "📦"
        case .socialMedia: return "👥"
        case .streaming: return "🎬"
        case .gaming: return "🎮"
        case .crypto: return "₿"
        case .defenseTech: return "🛡️"
        case .healthcare: return "🏥"
        case .foodTech: return "🍔"
        case .realEstateTech: return "🏠"
        case .logistics: return "🚚"
        case .media: return "🎭"
        case .fashion: return "👗"
        }
    }
    
    var entryThreshold: Double {
        switch self {
        case .software: return 100_000
        case .fintech: return 500_000
        case .automotive: return 1_000_000
        case .dataCenters: return 2_000_000
        case .solar: return 5_000_000
        case .biotech: return 10_000_000
        case .robotics: return 20_000_000
        case .ai: return 50_000_000
        case .nuclear: return 100_000_000
        case .space: return 200_000_000
        // New industries - require max career (these unlock via ventures)
        case .ecommerce: return 1_000_000
        case .socialMedia: return 2_000_000
        case .streaming: return 5_000_000
        case .gaming: return 3_000_000
        case .crypto: return 2_000_000
        case .defenseTech: return 50_000_000
        case .healthcare: return 10_000_000
        case .foodTech: return 1_000_000
        case .realEstateTech: return 5_000_000
        case .logistics: return 10_000_000
        case .media: return 100_000_000
        case .fashion: return 20_000_000
        }
    }
    
    var description: String {
        switch self {
        case .software: return "Enterprise software, SaaS, and cloud platforms"
        case .space: return "Space exploration, satellites, and interplanetary travel"
        case .robotics: return "Industrial automation and advanced robotics"
        case .automotive: return "Electric vehicles and autonomous driving"
        case .dataCenters: return "Cloud infrastructure and data processing"
        case .solar: return "Solar panels and renewable energy systems"
        case .nuclear: return "Nuclear power and advanced reactor technology"
        case .ai: return "Machine learning and AI systems"
        case .biotech: return "Genetic engineering and medical breakthroughs"
        case .fintech: return "Digital banking and financial technology"
        // New venture industries
        case .ecommerce: return "Build the next Amazon - marketplace & fulfillment"
        case .socialMedia: return "Create a social network to rival Meta"
        case .streaming: return "Launch a streaming service like Netflix"
        case .gaming: return "Build a gaming empire like Epic or Valve"
        case .crypto: return "Web3, blockchain, and digital assets"
        case .defenseTech: return "Military tech and national security"
        case .healthcare: return "Disrupt healthcare with technology"
        case .foodTech: return "Food delivery and restaurant tech"
        case .realEstateTech: return "PropTech and real estate innovation"
        case .logistics: return "Shipping, fulfillment, and supply chain"
        case .media: return "Entertainment conglomerate like Disney"
        case .fashion: return "Luxury fashion and retail empire"
        }
    }
    
    /// Famous company comparison for this industry
    var famousExample: String {
        switch self {
        case .software: return "Build the next Salesforce"
        case .space: return "Compete with SpaceX"
        case .robotics: return "Challenge Boston Dynamics"
        case .automotive: return "Rival Tesla"
        case .dataCenters: return "Compete with AWS"
        case .solar: return "Scale like First Solar"
        case .nuclear: return "Next-gen like Oklo"
        case .ai: return "Challenge OpenAI"
        case .biotech: return "Disrupt like Moderna"
        case .fintech: return "Scale like Stripe"
        case .ecommerce: return "Build the next Amazon"
        case .socialMedia: return "Create the next Meta"
        case .streaming: return "Launch the next Netflix"
        case .gaming: return "Build the next Epic Games"
        case .crypto: return "Scale like Coinbase"
        case .defenseTech: return "Grow like Anduril"
        case .healthcare: return "Disrupt like One Medical"
        case .foodTech: return "Scale like DoorDash"
        case .realEstateTech: return "Build the next Zillow"
        case .logistics: return "Rival FedEx or Amazon Logistics"
        case .media: return "Build the next Disney"
        case .fashion: return "Create the next LVMH"
        }
    }
    
    /// Whether this industry requires max career to unlock (venture industries)
    var isVentureIndustry: Bool {
        switch self {
        case .ecommerce, .socialMedia, .streaming, .gaming, .crypto, 
             .defenseTech, .healthcare, .foodTech, .realEstateTech, 
             .logistics, .media, .fashion:
            return true
        default:
            return false
        }
    }
}

// MARK: - Venture System (Serial Entrepreneur)
// Once you max out your career, you can start new companies in different industries!

struct Venture: Identifiable, Codable {
    let id: String
    var name: String
    var industry: Industry
    var foundedYear: Int
    var valuation: Double
    var employees: Int
    var revenue: Double
    var growthRate: Double  // Annual growth rate
    var isActive: Bool
    
    /// Calculate yearly revenue based on valuation and industry
    var yearlyRevenue: Double {
        valuation * 0.15  // ~15% of valuation as revenue
    }
    
    /// Calculate how much profit this venture generates
    var yearlyProfit: Double {
        yearlyRevenue * 0.2  // 20% profit margin
    }
    
    /// Get the venture stage based on valuation
    var stage: VentureStage {
        switch valuation {
        case 0..<1_000_000: return .startup
        case 1_000_000..<10_000_000: return .growth
        case 10_000_000..<100_000_000: return .scaleup
        case 100_000_000..<1_000_000_000: return .unicorn
        case 1_000_000_000..<10_000_000_000: return .decacorn
        default: return .empire
        }
    }
}

enum VentureStage: String, Codable {
    case startup = "Startup"
    case growth = "Growth Stage"
    case scaleup = "Scale-Up"
    case unicorn = "Unicorn 🦄"
    case decacorn = "Decacorn"
    case empire = "Global Empire"
    
    var icon: String {
        switch self {
        case .startup: return "🌱"
        case .growth: return "📈"
        case .scaleup: return "🚀"
        case .unicorn: return "🦄"
        case .decacorn: return "💎"
        case .empire: return "👑"
        }
    }
    
    var description: String {
        switch self {
        case .startup: return "Early stage, building product"
        case .growth: return "Product-market fit achieved"
        case .scaleup: return "Rapid expansion phase"
        case .unicorn: return "$1B+ valuation"
        case .decacorn: return "$10B+ valuation"
        case .empire: return "Global domination"
        }
    }
}

struct VentureState: Codable {
    var ventures: [Venture] = []
    var totalVenturesStarted: Int = 0
    var hasUnlockedVentures: Bool = false
    
    var totalVentureValuation: Double {
        ventures.reduce(0) { $0 + $1.valuation }
    }
    
    var totalVentureProfit: Double {
        ventures.filter { $0.isActive }.reduce(0) { $0 + $1.yearlyProfit }
    }
    
    var activeVentures: [Venture] {
        ventures.filter { $0.isActive }
    }
}

class VentureManager: ObservableObject {
    static let shared = VentureManager()
    
    @Published var state: VentureState
    @Published var showVentureUnlockedAlert = false
    @Published var showNewVentureSheet = false
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: "ventureState"),
           let decoded = try? JSONDecoder().decode(VentureState.self, from: data) {
            self.state = decoded
        } else {
            self.state = VentureState()
        }
    }
    
    func save() {
        if let encoded = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(encoded, forKey: "ventureState")
        }
    }
    
    /// Format currency compactly
    private func formatCompact(_ value: Double) -> String {
        switch value {
        case 1_000_000_000_000...: return String(format: "$%.1fT", value / 1_000_000_000_000)
        case 1_000_000_000...: return String(format: "$%.1fB", value / 1_000_000_000)
        case 1_000_000...: return String(format: "$%.1fM", value / 1_000_000)
        case 1_000...: return String(format: "$%.1fK", value / 1_000)
        default: return "$\(Int(value))"
        }
    }
    
    /// Check if player has reached max career (unlocks ventures)
    func checkVentureUnlock(careerRoleIndex: Int, careerRolesCount: Int) {
        // Max career = last role (index == count - 1)
        if careerRoleIndex >= careerRolesCount - 1 && !state.hasUnlockedVentures {
            state.hasUnlockedVentures = true
            showVentureUnlockedAlert = true
            save()
            
            NewsFeedManager.shared.addNews(
                category: .personal,
                headline: "🎉 CAREER MAXED! You've unlocked Serial Entrepreneur mode - start new ventures!"
            )
        }
    }
    
    /// Get available industries for new ventures
    func availableIndustries() -> [Industry] {
        let startedIndustries = Set(state.ventures.map { $0.industry })
        return Industry.allCases.filter { industry in
            industry.isVentureIndustry && !startedIndustries.contains(industry)
        }
    }
    
    /// Start a new venture in an industry
    func startVenture(name: String, industry: Industry, initialInvestment: Double, currentYear: Int) -> Venture? {
        guard state.hasUnlockedVentures else { return nil }
        guard initialInvestment >= industry.entryThreshold else { return nil }
        
        let venture = Venture(
            id: UUID().uuidString,
            name: name,
            industry: industry,
            foundedYear: currentYear,
            valuation: initialInvestment * 2,  // 2x initial investment as starting valuation
            employees: 5,  // Start with small team
            revenue: 0,
            growthRate: 0.25,  // 25% annual growth to start
            isActive: true
        )
        
        state.ventures.append(venture)
        state.totalVenturesStarted += 1
        save()
        
        NewsFeedManager.shared.addNews(
            category: .personal,
            headline: "\(industry.icon) New venture launched! \(name) enters the \(industry.rawValue) industry!"
        )
        
        return venture
    }
    
    /// Process yearly growth for all ventures
    func processYear() {
        for i in 0..<state.ventures.count where state.ventures[i].isActive {
            var venture = state.ventures[i]
            
            // Apply growth rate to valuation
            let growth = venture.valuation * venture.growthRate
            venture.valuation += growth
            
            // Employees grow with valuation
            let newEmployees = Int(growth / 100_000)  // 1 employee per $100k growth
            venture.employees += max(0, newEmployees)
            
            // Revenue based on valuation
            venture.revenue = venture.yearlyRevenue
            
            // Growth rate decreases as company gets bigger
            if venture.valuation > 1_000_000_000 {
                venture.growthRate = max(0.05, venture.growthRate * 0.9)  // Slow down at $1B+
            }
            
            state.ventures[i] = venture
        }
        save()
    }
    
    /// Get total passive income from all ventures
    func getTotalVentureIncome() -> Double {
        state.totalVentureProfit
    }
    
    /// Invest more money in an existing venture
    func investInVenture(id: String, amount: Double) -> Bool {
        guard let index = state.ventures.firstIndex(where: { $0.id == id }) else { return false }
        
        state.ventures[index].valuation += amount * 1.5  // Investment increases valuation 1.5x
        save()
        return true
    }
    
    /// Sell a venture (exit)
    func sellVenture(id: String) -> Double? {
        guard let index = state.ventures.firstIndex(where: { $0.id == id }) else { return nil }
        
        let venture = state.ventures[index]
        let salePrice = venture.valuation * 0.8  // Sell at 80% of valuation
        
        state.ventures[index].isActive = false
        save()
        
        NewsFeedManager.shared.addNews(
            category: .personal,
            headline: "💰 EXIT! Sold \(venture.name) for \(formatCompact(salePrice))!"
        )
        
        return salePrice
    }
    
    func reset() {
        state = VentureState()
        save()
    }
}

// MARK: - Employee Types
struct EmployeeCategory: Identifiable, Codable {
    let id: String
    let name: String
    let icon: String
    let baseSalary: Double
    var count: Int
    var maxLevel: Int
    
    var totalSalary: Double {
        Double(count) * baseSalary
    }
    
    // INCREASED: maxLevel now supports much larger companies
    // Max employees = maxLevel * 10 (e.g., maxLevel 100 = 1000 employees per category)
    static let categories: [EmployeeCategory] = [
        EmployeeCategory(id: "intern", name: "Interns", icon: "👶", baseSalary: 30_000, count: 0, maxLevel: 100),        // Max 1000
        EmployeeCategory(id: "associate", name: "Associates", icon: "👤", baseSalary: 60_000, count: 0, maxLevel: 100),  // Max 1000
        EmployeeCategory(id: "manager", name: "Managers", icon: "👔", baseSalary: 120_000, count: 0, maxLevel: 50),      // Max 500
        EmployeeCategory(id: "director", name: "Directors", icon: "📊", baseSalary: 250_000, count: 0, maxLevel: 25),    // Max 250
        EmployeeCategory(id: "vp", name: "VPs", icon: "🎯", baseSalary: 500_000, count: 0, maxLevel: 15),                // Max 150
        EmployeeCategory(id: "executive", name: "Executives", icon: "👑", baseSalary: 1_000_000, count: 0, maxLevel: 10), // Max 100
    ]
}

// MARK: - Billionaire Data
struct Billionaire: Identifiable {
    let id: String
    let name: String
    let netWorth: Double  // in dollars
    let company: String
    let icon: String
    
    var formattedNetWorth: String {
        if netWorth >= 1_000_000_000_000 {
            return String(format: "$%.1fT", netWorth / 1_000_000_000_000)
        } else {
            return String(format: "$%.0fB", netWorth / 1_000_000_000)
        }
    }
    
    // Real billionaires (approximate net worth as of 2024)
    static let leaderboard: [Billionaire] = [
        Billionaire(id: "you", name: "You", netWorth: 0, company: "Your Empire", icon: "🌟"),
        Billionaire(id: "musk", name: "Elon Musk", netWorth: 250_000_000_000, company: "Tesla, SpaceX, X", icon: "🚀"),
        Billionaire(id: "bezos", name: "Jeff Bezos", netWorth: 200_000_000_000, company: "Amazon, Blue Origin", icon: "📦"),
        Billionaire(id: "arnault", name: "Bernard Arnault", netWorth: 180_000_000_000, company: "LVMH", icon: "👜"),
        Billionaire(id: "zuckerberg", name: "Mark Zuckerberg", netWorth: 170_000_000_000, company: "Meta", icon: "👤"),
        Billionaire(id: "ellison", name: "Larry Ellison", netWorth: 150_000_000_000, company: "Oracle", icon: "🔮"),
        Billionaire(id: "buffett", name: "Warren Buffett", netWorth: 130_000_000_000, company: "Berkshire Hathaway", icon: "📈"),
        Billionaire(id: "gates", name: "Bill Gates", netWorth: 120_000_000_000, company: "Microsoft", icon: "🪟"),
        Billionaire(id: "page", name: "Larry Page", netWorth: 115_000_000_000, company: "Google/Alphabet", icon: "🔍"),
        Billionaire(id: "brin", name: "Sergey Brin", netWorth: 110_000_000_000, company: "Google/Alphabet", icon: "🔍"),
        Billionaire(id: "ballmer", name: "Steve Ballmer", netWorth: 100_000_000_000, company: "Microsoft, LA Clippers", icon: "🏀"),
    ]
    
    static let trillionGoal: Double = 1_000_000_000_000  // $1 Trillion
}

// MARK: - Company Location (for expansion)
struct CompanyLocation: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var type: String  // "headquarters", "datacenter", "office", "factory", "lab"
    var city: String
    var employees: Int = 0
    var maxEmployees: Int = 100
    var operatingCost: Double = 50_000  // Monthly cost
    var revenueMultiplier: Double = 1.0  // How much this location boosts revenue
    
    var icon: String {
        switch type {
        case "headquarters": return "🏢"
        case "datacenter": return "🖥️"
        case "office": return "🏠"
        case "factory": return "🏭"
        case "lab": return "🔬"
        default: return "📍"
        }
    }
    
    var monthlyCost: Double {
        operatingCost + (Double(employees) * 5000)  // Base + per employee
    }
}

// MARK: - Company State
struct CompanyState: Codable {
    var name: String = "My Company"
    var companyType: Industry? = nil  // The primary industry/type of the company
    var founded: Bool = false
    var foundedYear: Int = 0
    var employees: [EmployeeCategory] = EmployeeCategory.categories
    var industries: [Industry] = []
    var companyValuation: Double = 0
    var totalCapitalRaised: Double = 0
    var tradeDealsCompleted: Int = 0
    var acquisitions: Int = 0
    
    // Locations / Expansion
    var locations: [CompanyLocation] = []
    
    // Department System
    var departmentState: DepartmentState = DepartmentState()
    
    var totalLocations: Int {
        locations.count
    }
    
    var datacenterCount: Int {
        locations.filter { $0.type == "datacenter" }.count
    }
    
    // Maximum valuation cap to prevent overflow bugs
    static let maxValuation: Double = 5_000_000_000_000 // $5 trillion cap
    
    var totalEmployees: Int {
        // Include both legacy employees and department employees
        let legacyCount = employees.reduce(0) { $0 + $1.count }
        return legacyCount + departmentState.totalDepartmentEmployees
    }
    
    var totalPayroll: Double {
        employees.reduce(0) { $0 + $1.totalSalary }
    }
    
    var companyTier: String {
        switch totalEmployees {
        case 0: return "Solo Founder"
        case 1...10: return "Startup"
        case 11...50: return "Small Business"
        case 51...200: return "Growing Company"
        case 201...1000: return "Mid-Size Enterprise"
        case 1001...10000: return "Large Corporation"
        case 10001...100000: return "Multinational"
        default: return "Global Empire"
        }
    }
    
    var companyTierIcon: String {
        switch totalEmployees {
        case 0: return "🌱"
        case 1...10: return "🚀"
        case 11...50: return "🏠"
        case 51...200: return "🏢"
        case 201...1000: return "🏛️"
        case 1001...10000: return "🌆"
        case 10001...100000: return "🌍"
        default: return "👑"
        }
    }
}

// MARK: - Company Manager
class CompanyManager: ObservableObject {
    static let shared = CompanyManager()
    
    @Published var state: CompanyState {
        didSet { save() }
    }
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: "companyState"),
           let decoded = try? JSONDecoder().decode(CompanyState.self, from: data) {
            self.state = decoded
        } else {
            self.state = CompanyState()
        }
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(encoded, forKey: "companyState")
        }
    }
    
    // MARK: - Company Actions
    
    func foundCompany(name: String, type: Industry, year: Int) {
        state.name = name
        state.companyType = type
        state.founded = true
        state.foundedYear = year
        state.industries = [type]  // Start with the founding industry
        updateValuation()
    }
    
    // Legacy support for old code
    func foundCompany(name: String, year: Int) {
        foundCompany(name: name, type: .software, year: year)
    }
    
    func hireEmployee(categoryId: String) -> Bool {
        guard let index = state.employees.firstIndex(where: { $0.id == categoryId }) else { return false }
        if state.employees[index].count < state.employees[index].maxLevel * 10 {
            state.employees[index].count += 1
            updateValuation()
            return true
        }
        return false
    }
    
    func enterIndustry(_ industry: Industry) {
        if !state.industries.contains(industry) {
            state.industries.append(industry)
            updateValuation()
        }
    }
    
    func completeTradeDeal(value: Double) {
        state.tradeDealsCompleted += 1
        state.totalCapitalRaised += value
        updateValuation()
    }
    
    func makeAcquisition(value: Double) {
        state.acquisitions += 1
        state.totalCapitalRaised += value * 0.1  // 10% of acquisition adds to capital
        updateValuation()
    }
    
    // MARK: - Sell Company
    
    /// Calculate sale price based on valuation and multipliers
    var salePrice: Double {
        var price = state.companyValuation
        
        // Premium for more employees (larger companies are worth more)
        let employeeMultiplier = 1.0 + min(Double(state.totalEmployees) / 1000, 0.5)  // Up to 50% bonus
        price *= employeeMultiplier
        
        // Premium for multiple locations
        let locationMultiplier = 1.0 + (Double(state.locations.count) * 0.1)  // 10% per location
        price *= locationMultiplier
        
        // Premium for industries
        let industryMultiplier = 1.0 + (Double(state.industries.count) * 0.05)  // 5% per industry
        price *= industryMultiplier
        
        return price
    }
    
    /// Sell the company and return cash to player
    /// Returns the sale price
    func sellCompany() -> Double {
        let price = salePrice
        
        // Reset company state
        state = CompanyState()
        
        return price
    }
    
    // MARK: - Expansion / Locations
    
    /// Available location types based on company industry
    var availableLocationTypes: [(type: String, name: String, cost: Double, employeesRequired: Int)] {
        guard let industry = state.companyType else { return [] }
        
        switch industry {
        case .dataCenters:
            return [
                ("datacenter", "Data Center", 5_000_000, 50),
                ("office", "Regional Office", 500_000, 10)
            ]
        case .software, .ai:
            return [
                ("office", "Dev Office", 1_000_000, 20),
                ("datacenter", "Cloud Infrastructure", 10_000_000, 75),
                ("lab", "R&D Lab", 3_000_000, 30)
            ]
        case .space:
            return [
                ("factory", "Manufacturing Facility", 50_000_000, 200),
                ("lab", "Launch Facility", 100_000_000, 150),
                ("office", "Mission Control", 10_000_000, 50)
            ]
        case .biotech:
            return [
                ("lab", "Research Lab", 5_000_000, 40),
                ("factory", "Production Facility", 20_000_000, 100)
            ]
        case .automotive:
            return [
                ("factory", "Gigafactory", 30_000_000, 500),
                ("office", "Design Studio", 5_000_000, 30)
            ]
        default:
            return [
                ("office", "Office", 500_000, 10),
                ("factory", "Facility", 5_000_000, 50)
            ]
        }
    }
    
    /// Cities available for expansion
    static let expansionCities = [
        "San Francisco", "Austin", "Seattle", "New York", "Boston",
        "London", "Berlin", "Singapore", "Tokyo", "Dublin"
    ]
    
    /// Check if we have enough employees to support a new location
    func canExpandLocation(employeesRequired: Int) -> Bool {
        // Need at least the required employees, plus 20% buffer for existing operations
        let available = state.totalEmployees
        let needed = state.locations.reduce(0) { $0 + $1.employees } + employeesRequired
        return available >= needed
    }
    
    /// Add a new location
    func addLocation(type: String, name: String, city: String, cost: Double, maxEmployees: Int) -> Bool {
        let location = CompanyLocation(
            name: name,
            type: type,
            city: city,
            employees: 0,
            maxEmployees: maxEmployees,
            operatingCost: cost / 100,  // Monthly operating cost is 1% of build cost
            revenueMultiplier: type == "datacenter" ? 1.5 : (type == "factory" ? 1.3 : 1.1)
        )
        
        state.locations.append(location)
        updateValuation()
        return true
    }
    
    /// Get total revenue multiplier from all locations
    var locationRevenueMultiplier: Double {
        guard !state.locations.isEmpty else { return 1.0 }
        return state.locations.reduce(1.0) { $0 * $1.revenueMultiplier }
    }
    
    /// Get monthly operating costs for all locations
    var totalLocationCosts: Double {
        state.locations.reduce(0) { $0 + $1.monthlyCost }
    }
    
    // MARK: - Department Actions
    
    /// Get the count of employees in a specific department
    func getDepartmentCount(_ department: Department) -> Int {
        state.departmentState.getCount(for: department)
    }
    
    /// Hire an employee to a specific department
    func hireDepartmentEmployee(_ department: Department) -> Bool {
        let tier = getCompanyTier()
        let max = department.maxEmployees(companyTier: tier)
        let current = getDepartmentCount(department)
        
        guard current < max else { return false }
        
        state.departmentState.addEmployee(to: department)
        updateValuation()
        return true
    }
    
    /// Add employees to a department (e.g., from contact benefits)
    func addEmployees(department: Department, count: Int) {
        state.departmentState.addEmployee(to: department, count: count)
        updateValuation()
    }
    
    /// Get the company tier based on total employees (for department max calculations)
    func getCompanyTier() -> Int {
        switch state.totalEmployees {
        case 0: return 0          // Solo
        case 1...10: return 1     // Startup
        case 11...50: return 2    // Small
        case 51...200: return 3   // Growing
        case 201...1000: return 4 // Mid-Size
        case 1001...10000: return 5 // Large
        default: return 6         // Global
        }
    }
    
    // MARK: - Department Effect Calculations
    
    /// Engineering: +10% product success rate per engineer
    func getEngineeringBonus() -> Double {
        let engineers = getDepartmentCount(.engineering)
        return Double(engineers) * 0.10  // 10% per engineer
    }
    
    /// Sales: +5% revenue multiplier per salesperson
    func getSalesMultiplier() -> Double {
        let salespeople = getDepartmentCount(.sales)
        return 1.0 + (Double(salespeople) * 0.05)  // 5% per salesperson
    }
    
    /// Marketing: +10% contact bonus per marketer, +20 daily sales per marketer
    func getMarketingContactBonus() -> Double {
        let marketers = getDepartmentCount(.marketing)
        return Double(marketers) * 0.10  // 10% per marketer
    }
    
    func getMarketingDailySalesBonus() -> Int {
        let marketers = getDepartmentCount(.marketing)
        return marketers * 20  // +20 daily sales per marketer
    }
    
    /// Finance: +2% investment returns per analyst
    func getFinanceInvestmentBonus() -> Double {
        let analysts = getDepartmentCount(.finance)
        return Double(analysts) * 0.02  // 2% per analyst
    }
    
    /// Check if company has HR protection (prevents 15% yearly decay)
    func hasHRProtection() -> Bool {
        return getDepartmentCount(.hr) > 0
    }
    
    /// Apply HR decay penalty (15% valuation loss)
    func applyHRDecay() -> Double {
        guard state.totalEmployees > 10 && !hasHRProtection() else { return 0 }
        let decay = state.companyValuation * 0.15
        state.companyValuation = max(0, state.companyValuation - decay)
        return decay
    }
    
    /// Get penalty multiplier when missing a department
    func getMissingDepartmentPenalty(_ department: Department) -> Double {
        let hasEmployees = getDepartmentCount(department) > 0
        if hasEmployees { return 1.0 }
        
        switch department {
        case .engineering: return 0.5   // Products fail 50% more
        case .sales: return 0.5         // Revenue reduced 50%
        case .marketing: return 0.5     // Contacts give 50% less
        case .hr: return 1.0            // Handled separately via decay
        case .finance: return 1.2       // Pay 20% more taxes
        }
    }
    
    // MARK: - Staffing Requirements & Payroll
    
    /// Calculate required employees based on company valuation
    /// Higher valuation = more staff needed to maintain it
    var requiredEmployees: Int {
        switch state.companyValuation {
        case 0: return 0
        case 0..<100_000: return 1
        case 100_000..<500_000: return 3
        case 500_000..<1_000_000: return 5
        case 1_000_000..<5_000_000: return 10
        case 5_000_000..<10_000_000: return 20
        case 10_000_000..<50_000_000: return 40
        case 50_000_000..<100_000_000: return 75
        case 100_000_000..<500_000_000: return 150
        case 500_000_000..<1_000_000_000: return 300
        case 1_000_000_000..<10_000_000_000: return 500
        default: return 1000
        }
    }
    
    /// Current staffing level as a percentage (100% = fully staffed)
    var staffingLevel: Double {
        guard requiredEmployees > 0 else { return 1.0 }
        return min(1.5, Double(state.totalEmployees) / Double(requiredEmployees))
    }
    
    /// Is the company understaffed?
    var isUnderstaffed: Bool {
        staffingLevel < 0.75
    }
    
    /// Is the company critically understaffed? (company will fail)
    var isCriticallyUnderstaffed: Bool {
        staffingLevel < 0.25 && requiredEmployees >= 5
    }
    
    /// Get staffing status message
    var staffingStatus: (message: String, color: String, icon: String) {
        switch staffingLevel {
        case 1.0...:
            return ("Fully Staffed", "green", "✅")
        case 0.75..<1.0:
            return ("Slightly Understaffed", "yellow", "⚠️")
        case 0.5..<0.75:
            return ("Understaffed - Revenue Impacted", "orange", "🔶")
        case 0.25..<0.5:
            return ("Severely Understaffed - Company Failing", "red", "🚨")
        default:
            return ("CRITICAL - Company Collapsing!", "red", "💀")
        }
    }
    
    /// Calculate annual payroll cost (employees cost money!)
    var annualPayroll: Double {
        var total: Double = 0
        for dept in Department.allCases {
            let count = getDepartmentCount(dept)
            total += Double(count) * dept.baseSalary
        }
        // Add legacy employee costs
        total += state.totalPayroll
        return total
    }
    
    /// Get the understaffing revenue penalty multiplier
    var understaffingPenalty: Double {
        switch staffingLevel {
        case 1.0...: return 1.0      // No penalty
        case 0.75..<1.0: return 0.9  // 10% revenue loss
        case 0.5..<0.75: return 0.6  // 40% revenue loss
        case 0.25..<0.5: return 0.3  // 70% revenue loss
        default: return 0.1          // 90% revenue loss - company failing
        }
    }
    
    /// Process yearly company health - call at end of each game year
    /// Returns: (payrollCost, valuationLoss, isCompanyFailed)
    func processYearlyCompanyHealth() -> (payroll: Double, decay: Double, failed: Bool) {
        var totalDecay: Double = 0
        
        // 1. Apply HR decay if no HR
        let hrDecay = applyHRDecay()
        totalDecay += hrDecay
        
        // 2. Apply understaffing decay
        if isUnderstaffed {
            let staffingDecay = state.companyValuation * (1.0 - staffingLevel) * 0.25
            state.companyValuation = max(0, state.companyValuation - staffingDecay)
            totalDecay += staffingDecay
        }
        
        // 3. Check for company failure
        let failed = isCriticallyUnderstaffed && state.companyValuation > 0
        if failed {
            // Company fails - massive valuation loss
            let failureLoss = state.companyValuation * 0.5
            state.companyValuation = max(0, state.companyValuation - failureLoss)
            totalDecay += failureLoss
        }
        
        return (annualPayroll, totalDecay, failed)
    }
    
    // MARK: - Hiring with Vouchers
    
    /// Add hiring vouchers from a contact
    func addHiringVouchers(_ vouchers: [String: Int]) {
        for (deptName, count) in vouchers {
            if let dept = Department(rawValue: deptName) {
                state.departmentState.addVouchers(to: dept, count: count)
            }
        }
    }
    
    /// Get voucher count for a department
    func getVoucherCount(_ department: Department) -> Int {
        state.departmentState.getVouchers(for: department)
    }
    
    /// Get hiring cost for a department (50% off with voucher)
    func getHiringCost(_ department: Department) -> Double {
        let hasVoucher = getVoucherCount(department) > 0
        return hasVoucher ? department.hireCost * 0.5 : department.hireCost
    }
    
    /// Hire an employee with cost (uses voucher if available)
    func hireDepartmentEmployeeWithCost(_ department: Department, cash: inout Double) -> Bool {
        let cost = getHiringCost(department)
        guard cash >= cost else { return false }
        
        let tier = getCompanyTier()
        let max = department.maxEmployees(companyTier: tier)
        let current = getDepartmentCount(department)
        guard current < max else { return false }
        
        // Use voucher if available
        _ = state.departmentState.useVoucher(for: department)
        
        // Deduct cost and hire
        cash -= cost
        state.departmentState.addEmployee(to: department)
        updateValuation()
        return true
    }
    
    private func updateValuation() {
        // Company valuation formula
        let employeeValue = Double(state.totalEmployees) * 100_000
        let industryValue = Double(state.industries.count) * 10_000_000
        let dealValue = Double(state.tradeDealsCompleted) * 5_000_000
        let acquisitionValue = Double(state.acquisitions) * 50_000_000
        
        // Department bonus: specialized employees are worth more
        let deptBonus = Double(state.departmentState.totalDepartmentEmployees) * 50_000
        
        // Cap capital raised to prevent overflow
        let cappedCapital = min(state.totalCapitalRaised, 10_000_000_000) // $10B cap
        let capitalMultiplier = 1 + (cappedCapital / 100_000_000)
        
        let rawValuation = (employeeValue + industryValue + dealValue + acquisitionValue + deptBonus) * capitalMultiplier
        
        // Apply hard cap to prevent overflow bugs
        state.companyValuation = min(rawValuation, CompanyState.maxValuation)
    }
    
    // MARK: - Leaderboard
    
    func getLeaderboardWithPlayer(playerNetWorth: Double) -> [Billionaire] {
        var leaderboard = Billionaire.leaderboard.filter { $0.id != "you" }
        let player = Billionaire(id: "you", name: "You", netWorth: playerNetWorth, company: state.name, icon: "🌟")
        leaderboard.append(player)
        return leaderboard.sorted { $0.netWorth > $1.netWorth }
    }
    
    func getPlayerRank(playerNetWorth: Double) -> Int {
        let sorted = getLeaderboardWithPlayer(playerNetWorth: playerNetWorth)
        return (sorted.firstIndex { $0.id == "you" } ?? sorted.count) + 1
    }
    
    func getNextBillionaireToPass(playerNetWorth: Double) -> Billionaire? {
        let sorted = getLeaderboardWithPlayer(playerNetWorth: playerNetWorth)
        guard let playerIndex = sorted.firstIndex(where: { $0.id == "you" }) else { return nil }
        if playerIndex > 0 {
            return sorted[playerIndex - 1]
        }
        return nil
    }
    
    func progressToTrillionaire(playerNetWorth: Double) -> Double {
        return min(1.0, playerNetWorth / Billionaire.trillionGoal)
    }
    
    // MARK: - Reset
    
    func reset() {
        state = CompanyState()
        state.departmentState = DepartmentState()
    }
}

// MARK: - Company Dashboard View
struct CompanyDashboardView: View {
    @ObservedObject var company = CompanyManager.shared
    let playerNetWorth: Double
    let accentColor = Color(red: 0.4, green: 0.7, blue: 0.4)
    
    var body: some View {
        VStack(spacing: 12) {
            // Company Header
            HStack {
                Text(company.state.companyTierIcon)
                    .font(.system(size: 24))
                VStack(alignment: .leading, spacing: 2) {
                    Text(company.state.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text(company.state.companyTier)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(company.state.totalEmployees)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(accentColor)
                    Text("employees")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                }
            }
            
            // Industries
            if !company.state.industries.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(company.state.industries) { industry in
                            HStack(spacing: 4) {
                                Text(industry.icon)
                                    .font(.system(size: 12))
                                Text(industry.rawValue)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(accentColor.opacity(0.2))
                            )
                        }
                    }
                }
            }
            
            // Stats Row
            HStack(spacing: 16) {
                statBadge(icon: "💼", value: "\(company.state.tradeDealsCompleted)", label: "Deals")
                statBadge(icon: "🏢", value: "\(company.state.acquisitions)", label: "Acquisitions")
                statBadge(icon: "🌍", value: "\(company.state.industries.count)", label: "Industries")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
        )
    }
    
    func statBadge(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.system(size: 16))
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Billionaire Leaderboard View
struct BillionaireLeaderboardView: View {
    @ObservedObject var company = CompanyManager.shared
    let playerNetWorth: Double
    let accentColor = Color(red: 0.4, green: 0.7, blue: 0.4)
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with trillion goal
            HStack {
                Text("🏆")
                    .font(.system(size: 18))
                Text("BILLIONAIRE RANKINGS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.gray)
                    .tracking(1.5)
                Spacer()
                Text("#\(company.getPlayerRank(playerNetWorth: playerNetWorth))")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(accentColor)
            }
            
            // Trillion Goal Progress
            VStack(spacing: 6) {
                HStack {
                    Text("Goal: First Trillionaire")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Text(String(format: "%.4f%%", company.progressToTrillionaire(playerNetWorth: playerNetWorth) * 100))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(accentColor)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 6)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [accentColor, Color.yellow],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(4, geometry.size.width * CGFloat(company.progressToTrillionaire(playerNetWorth: playerNetWorth))), height: 6)
                    }
                }
                .frame(height: 6)
                
                Text("$1,000,000,000,000")
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
            
            // Leaderboard
            ForEach(Array(company.getLeaderboardWithPlayer(playerNetWorth: playerNetWorth).prefix(5).enumerated()), id: \.element.id) { index, billionaire in
                leaderboardRow(rank: index + 1, billionaire: billionaire, isPlayer: billionaire.id == "you")
            }
            
            // Next target
            if let nextTarget = company.getNextBillionaireToPass(playerNetWorth: playerNetWorth) {
                HStack {
                    Text("Next target:")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    Text("\(nextTarget.name)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                    Text("(\(nextTarget.formattedNetWorth))")
                        .font(.system(size: 10))
                        .foregroundColor(accentColor)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
        )
    }
    
    func leaderboardRow(rank: Int, billionaire: Billionaire, isPlayer: Bool) -> some View {
        HStack(spacing: 12) {
            // Rank
            Text("\(rank)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(rank <= 3 ? .yellow : .gray)
                .frame(width: 20)
            
            // Icon
            Text(billionaire.icon)
                .font(.system(size: 16))
            
            // Name & Company
            VStack(alignment: .leading, spacing: 2) {
                Text(billionaire.name)
                    .font(.system(size: 12, weight: isPlayer ? .bold : .medium))
                    .foregroundColor(isPlayer ? accentColor : .white)
                Text(billionaire.company)
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Net Worth
            Text(billionaire.formattedNetWorth)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(isPlayer ? accentColor : .white)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isPlayer ? accentColor.opacity(0.1) : Color.clear)
        )
    }
}

// MARK: - Hire Employees View
struct HireEmployeesView: View {
    @ObservedObject var company = CompanyManager.shared
    let cash: Double
    let onHire: (String, Double) -> Bool  // Returns true if hire successful
    let accentColor = Color(red: 0.4, green: 0.7, blue: 0.4)
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("👥")
                    .font(.system(size: 14))
                Text("HIRE EMPLOYEES")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.gray)
                    .tracking(1.5)
                Spacer()
                Text("\(company.state.totalEmployees) total")
                    .font(.system(size: 11))
                    .foregroundColor(.white)
            }
            
            ForEach(company.state.employees) { category in
                employeeRow(category: category)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
        )
    }
    
    func employeeRow(category: EmployeeCategory) -> some View {
        let hireCost = category.baseSalary * 2  // 2x salary to hire
        let canHire = cash >= hireCost && category.count < category.maxLevel * 10
        
        return HStack(spacing: 12) {
            Text(category.icon)
                .font(.system(size: 20))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                Text("\(category.count)/\(category.maxLevel * 10)")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {
                if onHire(category.id, hireCost) {
                    _ = company.hireEmployee(categoryId: category.id)
                }
            }) {
                Text(formatCompact(hireCost))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(canHire ? .black : .gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(canHire ? accentColor : Color.gray.opacity(0.3))
                    )
            }
            .disabled(!canHire)
        }
        .padding(.vertical, 4)
    }
    
    func formatCompact(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "$%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "$%.0fK", value / 1_000)
        } else {
            return String(format: "$%.0f", value)
        }
    }
}
