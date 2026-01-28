import Foundation
import SwiftUI
import Combine

// MARK: - Income Sources
struct IncomeBreakdown {
    var salaryIncome: Double = 0        // W-2 from career
    var hustleIncome: Double = 0        // 1099 from tapping/auto-tappers
    var investmentIncome: Double = 0    // Capital gains, dividends
    var passiveIncome: Double = 0       // Products, upgrades
    
    var totalGrossIncome: Double {
        salaryIncome + hustleIncome + investmentIncome + passiveIncome
    }
}

// MARK: - Tax Brackets (Simplified US-style)
enum TaxBracket: CaseIterable {
    case bracket10   // $0 - $11K: 10%
    case bracket12   // $11K - $44K: 12%
    case bracket22   // $44K - $95K: 22%
    case bracket24   // $95K - $183K: 24%
    case bracket32   // $183K - $365K: 32%
    case bracket35   // $365K - $462K: 35%
    case bracket37   // $462K+: 37%
    
    var rate: Double {
        switch self {
        case .bracket10: return 0.10
        case .bracket12: return 0.12
        case .bracket22: return 0.22
        case .bracket24: return 0.24
        case .bracket32: return 0.32
        case .bracket35: return 0.35
        case .bracket37: return 0.37
        }
    }
    
    var threshold: Double {
        switch self {
        case .bracket10: return 0
        case .bracket12: return 11_000
        case .bracket22: return 44_000
        case .bracket24: return 95_000
        case .bracket32: return 183_000
        case .bracket35: return 365_000
        case .bracket37: return 462_000
        }
    }
    
    var ceiling: Double {
        switch self {
        case .bracket10: return 11_000
        case .bracket12: return 44_000
        case .bracket22: return 95_000
        case .bracket24: return 183_000
        case .bracket32: return 365_000
        case .bracket35: return 462_000
        case .bracket37: return .infinity
        }
    }
}

// MARK: - Tax Plan Tiers
enum TaxPlanTier: Int, Codable, CaseIterable {
    case basic = 0           // Default - no help
    case standard = 1        // Basic accountant
    case professional = 2    // CPA
    case executive = 3       // Tax attorney
    case elite = 4           // Offshore strategies
    case dynasty = 5         // Dynasty planning
    
    var name: String {
        switch self {
        case .basic: return "Basic Filing"
        case .standard: return "Standard"
        case .professional: return "Professional"
        case .executive: return "Executive"
        case .elite: return "Elite"
        case .dynasty: return "Dynasty"
        }
    }
    
    var icon: String {
        switch self {
        case .basic: return "📝"
        case .standard: return "📊"
        case .professional: return "💼"
        case .executive: return "🏛️"
        case .elite: return "💎"
        case .dynasty: return "👑"
        }
    }
    
    var description: String {
        switch self {
        case .basic: return "DIY tax filing"
        case .standard: return "Hire an accountant"
        case .professional: return "CPA with deductions"
        case .executive: return "Tax attorney + shelters"
        case .elite: return "Offshore optimization"
        case .dynasty: return "Generational wealth planning"
        }
    }
    
    var taxReduction: Double {
        switch self {
        case .basic: return 0.0        // 0% reduction
        case .standard: return 0.10    // 10% reduction
        case .professional: return 0.20 // 20% reduction
        case .executive: return 0.30   // 30% reduction
        case .elite: return 0.45       // 45% reduction
        case .dynasty: return 0.60     // 60% reduction
        }
    }
    
    var annualCost: Double {
        switch self {
        case .basic: return 0
        case .standard: return 2_000
        case .professional: return 10_000
        case .executive: return 50_000
        case .elite: return 200_000
        case .dynasty: return 1_000_000
        }
    }
    
    var upgradeCost: Double {
        switch self {
        case .basic: return 0
        case .standard: return 5_000
        case .professional: return 25_000
        case .executive: return 100_000
        case .elite: return 500_000
        case .dynasty: return 5_000_000
        }
    }
    
    var netWorthRequired: Double {
        switch self {
        case .basic: return 0
        case .standard: return 10_000
        case .professional: return 100_000
        case .executive: return 1_000_000
        case .elite: return 10_000_000
        case .dynasty: return 100_000_000
        }
    }
    
    var benefits: [String] {
        switch self {
        case .basic: return ["Standard deductions only"]
        case .standard: return ["10% tax reduction", "Basic deduction tracking"]
        case .professional: return ["20% tax reduction", "Retirement optimization", "Quarterly estimates"]
        case .executive: return ["30% tax reduction", "Tax shelters", "Business expense optimization"]
        case .elite: return ["45% tax reduction", "International structures", "Investment timing"]
        case .dynasty: return ["60% tax reduction", "Trust structures", "Estate planning", "Legacy protection"]
        }
    }
    
    var nextTier: TaxPlanTier? {
        TaxPlanTier(rawValue: self.rawValue + 1)
    }
}

// MARK: - Tax Deductions / Strategies
struct TaxStrategy: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let deductionType: DeductionType
    let maxDeduction: Double
    var isActive: Bool = false
    
    enum DeductionType: String, Codable {
        case retirement401k      // Pre-tax retirement
        case iraContribution     // IRA
        case businessExpenses    // If you have a company
        case charitableGiving    // Donations
        case hireAccountant      // Reduces effective rate
    }
}

// MARK: - Tax State
struct TaxState: Codable {
    var yearToDateIncome: IncomeBreakdownState = IncomeBreakdownState()
    var yearToDateTaxesPaid: Double = 0
    var retirementContributions: Double = 0     // 401k/IRA
    var charitableContributions: Double = 0
    var hasAccountant: Bool = false
    var pendingTaxBill: Double = 0
    var taxesPaidLifetime: Double = 0
    
    // Tax Plan System
    var currentPlanTier: TaxPlanTier = .basic
    var totalTaxSavingsLifetime: Double = 0
    
    struct IncomeBreakdownState: Codable {
        var salary: Double = 0
        var hustle: Double = 0
        var investment: Double = 0
        var passive: Double = 0
        
        var total: Double { salary + hustle + investment + passive }
    }
}

// MARK: - Tax Manager
class TaxManager: ObservableObject {
    static let shared = TaxManager()
    
    @Published var state: TaxState {
        didSet { save() }
    }
    
    // Tax-advantaged account limits
    let max401kContribution: Double = 23_000  // 2024 limit
    let maxIRAContribution: Double = 7_000    // 2024 limit
    
    // Capital gains rates
    let shortTermCapGainsRate: Double = 0.37  // Taxed as ordinary income (top bracket)
    let longTermCapGainsRate: Double = 0.20   // Preferential rate
    
    // Self-employment tax rate (for hustle income)
    let selfEmploymentTaxRate: Double = 0.153 // 15.3% SE tax
    
    init() {
        if let data = UserDefaults.standard.data(forKey: "taxState"),
           let decoded = try? JSONDecoder().decode(TaxState.self, from: data) {
            self.state = decoded
        } else {
            self.state = TaxState()
        }
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: "taxState")
        }
    }
    
    // MARK: - Record Income
    
    func recordSalaryIncome(_ amount: Double) {
        state.yearToDateIncome.salary += amount
    }
    
    func recordHustleIncome(_ amount: Double) {
        state.yearToDateIncome.hustle += amount
    }
    
    func recordInvestmentIncome(_ amount: Double) {
        state.yearToDateIncome.investment += amount
    }
    
    func recordPassiveIncome(_ amount: Double) {
        state.yearToDateIncome.passive += amount
    }
    
    // MARK: - Tax Calculations
    
    /// Calculate progressive income tax on ordinary income (salary + hustle)
    func calculateIncomeTax(on income: Double) -> Double {
        var remainingIncome = income
        var totalTax: Double = 0
        
        for bracket in TaxBracket.allCases {
            guard remainingIncome > 0 else { break }
            
            let taxableInBracket = min(remainingIncome, bracket.ceiling - bracket.threshold)
            if taxableInBracket > 0 {
                totalTax += taxableInBracket * bracket.rate
                remainingIncome -= taxableInBracket
            }
        }
        
        return totalTax
    }
    
    /// Calculate self-employment tax on hustle income
    func calculateSelfEmploymentTax(on hustleIncome: Double) -> Double {
        // SE tax applies to 92.35% of net self-employment income
        let taxableBase = hustleIncome * 0.9235
        return taxableBase * selfEmploymentTaxRate
    }
    
    /// Calculate capital gains tax
    func calculateCapitalGainsTax(gains: Double, isLongTerm: Bool) -> Double {
        let rate = isLongTerm ? longTermCapGainsRate : shortTermCapGainsRate
        return gains * rate
    }
    
    /// Get effective tax rate based on income
    func effectiveTaxRate(for income: Double) -> Double {
        guard income > 0 else { return 0 }
        let tax = calculateIncomeTax(on: income)
        return tax / income
    }
    
    /// Calculate year-end tax bill
    func calculateYearEndTaxes() -> Double {
        let income = state.yearToDateIncome
        
        // Taxable income after deductions
        let retirementDeduction = min(state.retirementContributions, max401kContribution)
        let charitableDeduction = min(state.charitableContributions, income.total * 0.60) // 60% limit
        
        // Ordinary income = salary + hustle - deductions
        let ordinaryIncome = max(0, income.salary + income.hustle - retirementDeduction - charitableDeduction)
        
        // Calculate taxes
        var totalTax: Double = 0
        
        // Income tax on ordinary income
        totalTax += calculateIncomeTax(on: ordinaryIncome)
        
        // Self-employment tax on hustle income
        totalTax += calculateSelfEmploymentTax(on: income.hustle)
        
        // Capital gains tax (assume long-term for simplicity)
        totalTax += calculateCapitalGainsTax(gains: income.investment, isLongTerm: true)
        
        // Apply tax plan reduction (replaces old accountant system)
        let taxReduction = state.currentPlanTier.taxReduction
        let originalTax = totalTax
        totalTax *= (1.0 - taxReduction)
        
        // Track savings
        let savings = originalTax - totalTax
        if savings > 0 {
            state.totalTaxSavingsLifetime += savings
        }
        
        // Subtract taxes already paid
        totalTax -= state.yearToDateTaxesPaid
        
        return max(0, totalTax)
    }
    
    // MARK: - Tax Plan Upgrades
    
    /// Check if player can upgrade to next tax plan tier
    func canUpgradePlan(netWorth: Double, cash: Double) -> Bool {
        guard let nextTier = state.currentPlanTier.nextTier else { return false }
        return netWorth >= nextTier.netWorthRequired && cash >= nextTier.upgradeCost
    }
    
    /// Get the next available tax plan tier
    var nextPlanTier: TaxPlanTier? {
        state.currentPlanTier.nextTier
    }
    
    /// Upgrade to next tax plan tier
    func upgradePlan(cash: inout Double, netWorth: Double) -> Bool {
        guard let nextTier = state.currentPlanTier.nextTier else { return false }
        guard cash >= nextTier.upgradeCost else { return false }
        guard netWorth >= nextTier.netWorthRequired else { return false }
        
        cash -= nextTier.upgradeCost
        state.currentPlanTier = nextTier
        objectWillChange.send() // Force UI update
        
        // Also set hasAccountant for backward compatibility
        if nextTier.rawValue >= TaxPlanTier.standard.rawValue {
            state.hasAccountant = true
        }
        
        return true
    }
    
    /// Get annual cost for current plan
    var annualPlanCost: Double {
        state.currentPlanTier.annualCost
    }
    
    /// Calculate how much the current plan saves per year
    func estimatedAnnualSavings(for income: Double) -> Double {
        let fullTax = calculateIncomeTax(on: income) + calculateSelfEmploymentTax(on: income * 0.3) // Assume 30% hustle
        return fullTax * state.currentPlanTier.taxReduction
    }
    
    /// Process year-end taxes (called at end of game year)
    func processYearEnd(game: GameState) -> (taxBill: Double, paid: Bool) {
        let taxBill = calculateYearEndTaxes()
        
        if game.cash >= taxBill {
            // Can pay taxes
            state.yearToDateTaxesPaid += taxBill
            state.taxesPaidLifetime += taxBill
            resetForNewYear()
            return (taxBill, true)
        } else {
            // Can't afford taxes - this should hurt credit score
            state.pendingTaxBill = taxBill
            CreditManager.shared.modifyScore(by: -75, reason: "Failed to pay taxes")
            resetForNewYear()
            return (taxBill, false)
        }
    }
    
    /// Contribute to retirement (pre-tax)
    func contributeToRetirement(_ amount: Double, game: GameState) -> Bool {
        let maxAdditional = max401kContribution - state.retirementContributions
        let contribution = min(amount, maxAdditional, game.cash)
        
        guard contribution > 0 else { return false }
        
        state.retirementContributions += contribution
        return true
    }
    
    /// Make charitable donation (tax deductible)
    func makeDonation(_ amount: Double) {
        state.charitableContributions += amount
    }
    
    /// Reset for new tax year
    func resetForNewYear() {
        state.yearToDateIncome = TaxState.IncomeBreakdownState()
        state.yearToDateTaxesPaid = 0
        state.retirementContributions = 0
        state.charitableContributions = 0
        state.pendingTaxBill = 0
    }
    
    /// Get marginal tax rate (for display)
    func marginalTaxRate(for income: Double) -> Double {
        for bracket in TaxBracket.allCases.reversed() {
            if income >= bracket.threshold {
                return bracket.rate
            }
        }
        return 0.10
    }
    
    /// Reset for prestige
    func resetForPrestige() {
        state = TaxState()
    }
    
    /// Full reset (death or new game)
    func reset() {
        state = TaxState()
    }
}

// MARK: - Tax Display View
struct TaxOverviewView: View {
    @ObservedObject var taxManager = TaxManager.shared
    @ObservedObject var game: GameState
    
    // Calculate estimated annual income from all sources
    var salaryPerYear: Double {
        game.currentRole?.salary ?? 0
    }
    
    var hustlePerYear: Double {
        game.autoTapperIncomePerSecond * LifeCycleConstants.secondsPerGameYear
    }
    
    var investmentReturnsPerYear: Double {
        // Estimate based on current portfolio and average returns
        var totalReturns: Double = 0
        for investment in game.investments where investment.amountInvested > 0 {
            totalReturns += investment.amountInvested * investment.baseReturn
        }
        return totalReturns
    }
    
    var currentUnrealizedGains: Double {
        game.totalUnrealizedGains
    }
    
    var passivePerYear: Double {
        var income: Double = 0
        for upgrade in game.upgrades where upgrade.purchased {
            if case .passiveIncome(let amount) = upgrade.effect {
                income += amount * LifeCycleConstants.secondsPerGameYear
            }
        }
        for product in game.products where product.successful {
            income += product.ongoingRevenue * LifeCycleConstants.secondsPerGameYear
        }
        return income
    }
    
    var totalAnnualIncome: Double {
        salaryPerYear + hustlePerYear + investmentReturnsPerYear + passivePerYear
    }
    
    var incomeBreakdown: [(String, String, Double, Color)] {
        return [
            ("💼", "Salary", salaryPerYear, .blue),
            ("💪", "Hustle", hustlePerYear, .green),
            ("📈", "Investments", investmentReturnsPerYear, .purple),
            ("🔄", "Passive", passivePerYear, .orange)
        ]
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("💰")
                Text("INCOME & TAXES")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text(game.formatCompact(totalAnnualIncome) + "/yr")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AppColors.mattGreen)
            }
            
            // Income breakdown (estimated annual)
            VStack(spacing: 6) {
                ForEach(incomeBreakdown, id: \.1) { icon, label, amount, color in
                    HStack {
                        Text(icon)
                            .font(.system(size: 12))
                        Text(label)
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        Spacer()
                        Text(game.formatCompact(amount) + "/yr")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(amount > 0 ? color : .gray)
                    }
                }
            }
            
            // Investment details (if any investments)
            if game.totalInvestmentValue > 0 {
                Divider().background(Color.gray.opacity(0.3))
                
                HStack {
                    Text("📊 Portfolio Value")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    Spacer()
                    Text(game.formatCompact(game.totalInvestmentValue))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.purple)
                }
                
                HStack {
                    Text("📈 Unrealized Gains")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    Spacer()
                    Text((currentUnrealizedGains >= 0 ? "+" : "") + game.formatCompact(currentUnrealizedGains))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(currentUnrealizedGains >= 0 ? .green : .red)
                }
            }
            
            Divider().background(Color.gray.opacity(0.3))
            
            // Total and tax estimate
            HStack {
                Text("Est. Taxes")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                Spacer()
                
                let estimatedTax = taxManager.calculateIncomeTax(on: totalAnnualIncome)
                let taxReduction = taxManager.state.currentPlanTier.taxReduction
                let afterReduction = estimatedTax * (1 - taxReduction)
                
                VStack(alignment: .trailing, spacing: 1) {
                    Text(game.formatCompact(afterReduction) + "/yr")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.red)
                    if taxReduction > 0 {
                        Text("-\(Int(taxReduction * 100))% saved")
                            .font(.system(size: 8))
                            .foregroundColor(AppColors.mattGreen)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
        )
    }
}

// MARK: - Compact Income Display
struct IncomeBreakdownCompact: View {
    @ObservedObject var game: GameState
    
    var salaryPerYear: Double {
        game.currentRole?.salary ?? 0
    }
    
    var hustlePerYear: Double {
        game.autoTapperIncomePerSecond * LifeCycleConstants.secondsPerGameYear
    }
    
    var passivePerYear: Double {
        // Upgrades and products passive income
        var income: Double = 0
        for upgrade in game.upgrades where upgrade.purchased {
            if case .passiveIncome(let amount) = upgrade.effect {
                income += amount * LifeCycleConstants.secondsPerGameYear
            }
        }
        for product in game.products where product.successful {
            income += product.ongoingRevenue * LifeCycleConstants.secondsPerGameYear
        }
        return income
    }
    
    var totalPerYear: Double {
        salaryPerYear + hustlePerYear + passivePerYear
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("💰")
                Text("INCOME BREAKDOWN")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text(game.formatCompact(totalPerYear) + "/yr")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.green)
            }
            
            HStack(spacing: 12) {
                IncomeSourceBadge(icon: "💼", label: "Salary", amount: salaryPerYear, color: .blue, game: game)
                IncomeSourceBadge(icon: "💪", label: "Hustle", amount: hustlePerYear, color: .green, game: game)
                IncomeSourceBadge(icon: "🔄", label: "Passive", amount: passivePerYear, color: .orange, game: game)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
        )
    }
}

struct IncomeSourceBadge: View {
    let icon: String
    let label: String
    let amount: Double
    let color: Color
    @ObservedObject var game: GameState
    
    var body: some View {
        VStack(spacing: 2) {
            Text(icon)
                .font(.system(size: 14))
            Text(game.formatCompact(amount))
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 7))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}
