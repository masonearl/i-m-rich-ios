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
    func maxEmployees(companyTier: Int) -> Int {
        // Tier 0 = Solo, 1 = Startup, 2 = Small, etc.
        let base: Int
        switch self {
        case .engineering: base = 10
        case .sales: base = 8
        case .marketing: base = 5
        case .hr: base = 3
        case .finance: base = 5
        }
        return base * max(1, companyTier)
    }
}

// MARK: - Department State
struct DepartmentState: Codable {
    var employees: [String: Int] = [:]  // Department rawValue -> count
    var lastHRCheck: Int = 0  // Game year of last HR check
    
    func getCount(for department: Department) -> Int {
        employees[department.rawValue] ?? 0
    }
    
    mutating func addEmployee(to department: Department, count: Int = 1) {
        let current = employees[department.rawValue] ?? 0
        employees[department.rawValue] = current + count
    }
    
    var totalDepartmentEmployees: Int {
        employees.values.reduce(0, +)
    }
}

// MARK: - Industry Types
enum Industry: String, Codable, CaseIterable, Identifiable {
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
        }
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
    
    static let categories: [EmployeeCategory] = [
        EmployeeCategory(id: "intern", name: "Interns", icon: "👶", baseSalary: 30_000, count: 0, maxLevel: 10),
        EmployeeCategory(id: "associate", name: "Associates", icon: "👤", baseSalary: 60_000, count: 0, maxLevel: 10),
        EmployeeCategory(id: "manager", name: "Managers", icon: "👔", baseSalary: 120_000, count: 0, maxLevel: 10),
        EmployeeCategory(id: "director", name: "Directors", icon: "📊", baseSalary: 250_000, count: 0, maxLevel: 10),
        EmployeeCategory(id: "vp", name: "VPs", icon: "🎯", baseSalary: 500_000, count: 0, maxLevel: 10),
        EmployeeCategory(id: "executive", name: "Executives", icon: "👑", baseSalary: 1_000_000, count: 0, maxLevel: 5),
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
    
    // Department System
    var departmentState: DepartmentState = DepartmentState()
    
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
