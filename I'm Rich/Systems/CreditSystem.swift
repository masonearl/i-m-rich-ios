//
//  CreditSystem.swift
//  Life of Wealth
//
//  Credit Score system - affects banking access, loan rates, and opportunities
//

import SwiftUI
import Combine

// MARK: - Credit Tier
enum CreditTier: String, CaseIterable {
    case poor = "Poor"
    case fair = "Fair"
    case good = "Good"
    case veryGood = "Very Good"
    case excellent = "Excellent"
    
    var range: ClosedRange<Int> {
        switch self {
        case .poor: return 300...579
        case .fair: return 580...669
        case .good: return 670...739
        case .veryGood: return 740...799
        case .excellent: return 800...850
        }
    }
    
    var color: Color {
        switch self {
        case .poor: return .red
        case .fair: return .orange
        case .good: return .yellow
        case .veryGood: return Color(red: 0.4, green: 0.7, blue: 0.4)
        case .excellent: return .green
        }
    }
    
    var icon: String {
        switch self {
        case .poor: return "exclamationmark.triangle.fill"
        case .fair: return "minus.circle.fill"
        case .good: return "checkmark.circle"
        case .veryGood: return "checkmark.circle.fill"
        case .excellent: return "star.circle.fill"
        }
    }
    
    var loanAccessDescription: String {
        switch self {
        case .poor: return "No bank loans available. 25% higher costs on purchases."
        case .fair: return "High-interest loans only (15-25% APR). Limited credit."
        case .good: return "Standard loan rates (8-12% APR). Most options available."
        case .veryGood: return "Preferred rates (5-8% APR). Premium banking access."
        case .excellent: return "Best rates (3-5% APR). VIP banking, exclusive deals."
        }
    }
    
    var interestRateMultiplier: Double {
        switch self {
        case .poor: return 2.5      // 250% of base rate
        case .fair: return 1.75     // 175% of base rate
        case .good: return 1.0      // Base rate
        case .veryGood: return 0.7  // 70% of base rate
        case .excellent: return 0.5 // 50% of base rate
        }
    }
    
    var purchaseCostMultiplier: Double {
        switch self {
        case .poor: return 1.25     // 25% markup
        case .fair: return 1.10     // 10% markup
        case .good: return 1.0      // Normal price
        case .veryGood: return 0.95 // 5% discount
        case .excellent: return 0.90 // 10% discount
        }
    }
    
    var maxLoanAmount: Double {
        switch self {
        case .poor: return 0                    // No loans
        case .fair: return 50_000               // Small personal loans
        case .good: return 500_000              // Home loans
        case .veryGood: return 5_000_000        // Business loans
        case .excellent: return 100_000_000     // Enterprise credit
        }
    }
    
    static func fromScore(_ score: Int) -> CreditTier {
        switch score {
        case 800...850: return .excellent
        case 740...799: return .veryGood
        case 670...739: return .good
        case 580...669: return .fair
        default: return .poor
        }
    }
}

// MARK: - Payment Record
struct PaymentRecord: Codable, Identifiable {
    let id: String
    let type: PaymentType
    let amount: Double
    let dueDate: Date
    var paidDate: Date?
    var wasPaidOnTime: Bool { paidDate != nil && paidDate! <= dueDate }
    var isPaid: Bool { paidDate != nil }
    var isOverdue: Bool { !isPaid && Date() > dueDate }
    
    enum PaymentType: String, Codable {
        case mortgage = "Mortgage"
        case loan = "Loan"
        case expense = "Expense"
        case creditCard = "Credit Card"
        case businessLoan = "Business Loan"
    }
}

// MARK: - Loan
struct Loan: Codable, Identifiable {
    let id: String
    let name: String
    let principal: Double
    let interestRate: Double  // Annual rate
    let termMonths: Int
    let startDate: Date
    var balance: Double
    var monthlyPayment: Double
    var missedPayments: Int = 0
    
    var isActive: Bool { balance > 0 }
    
    var totalInterestPaid: Double {
        let totalPayments = monthlyPayment * Double(termMonths)
        return totalPayments - principal
    }
}

// MARK: - Credit State
struct CreditState: Codable {
    var score: Int = 650  // Start at "Fair"
    var paymentHistory: [PaymentRecord] = []
    var activeLoans: [Loan] = []
    var creditUtilization: Double = 0  // 0-1, percentage of available credit used
    var accountAgeMonths: Int = 0
    var recentInquiries: Int = 0  // Hard inquiries in last 6 months
    var totalDebt: Double = 0
    var availableCredit: Double = 10_000  // Starting credit limit
    
    var tier: CreditTier {
        CreditTier.fromScore(score)
    }
    
    var onTimePaymentRate: Double {
        let completedPayments = paymentHistory.filter { $0.isPaid }
        guard !completedPayments.isEmpty else { return 1.0 }
        let onTime = completedPayments.filter { $0.wasPaidOnTime }.count
        return Double(onTime) / Double(completedPayments.count)
    }
    
    var debtToIncomeRatio: Double {
        // Will be calculated with income from GameState
        totalDebt / max(1, availableCredit)
    }
}

// MARK: - Credit Manager
class CreditManager: ObservableObject {
    static let shared = CreditManager()
    
    @Published var state: CreditState {
        didSet { save() }
    }
    
    @Published var showCreditChange = false
    @Published var recentScoreChange: Int = 0
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: "creditState"),
           let decoded = try? JSONDecoder().decode(CreditState.self, from: data) {
            self.state = decoded
        } else {
            self.state = CreditState()
        }
    }
    
    // MARK: - Score Calculation
    
    /// Recalculate credit score based on all factors
    func recalculateScore() {
        var newScore = 300  // Base score
        
        // Payment History (35% of score - up to 192 points)
        let paymentPoints = Int(state.onTimePaymentRate * 192)
        newScore += paymentPoints
        
        // Credit Utilization (30% of score - up to 165 points)
        // Lower utilization = higher score
        let utilizationScore: Int
        switch state.creditUtilization {
        case 0..<0.10: utilizationScore = 165
        case 0.10..<0.30: utilizationScore = 140
        case 0.30..<0.50: utilizationScore = 100
        case 0.50..<0.75: utilizationScore = 60
        default: utilizationScore = 20
        }
        newScore += utilizationScore
        
        // Length of Credit History (15% of score - up to 82 points)
        let agePoints = min(82, state.accountAgeMonths * 2)
        newScore += agePoints
        
        // Credit Mix & New Credit (20% combined - up to 111 points)
        // Fewer recent inquiries = better
        let inquiryPenalty = min(50, state.recentInquiries * 10)
        let mixPoints = 111 - inquiryPenalty
        newScore += max(0, mixPoints)
        
        // Clamp to valid range
        let oldScore = state.score
        state.score = max(300, min(850, newScore))
        
        // Show change animation
        let change = state.score - oldScore
        if change != 0 {
            recentScoreChange = change
            showCreditChange = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.showCreditChange = false
            }
        }
    }
    
    // MARK: - Payment Actions
    
    /// Record a new payment obligation
    func addPayment(type: PaymentRecord.PaymentType, amount: Double, dueInDays: Int) {
        let record = PaymentRecord(
            id: UUID().uuidString,
            type: type,
            amount: amount,
            dueDate: Date().addingTimeInterval(Double(dueInDays) * 86400)
        )
        state.paymentHistory.append(record)
    }
    
    /// Make a payment on time
    func makePayment(recordId: String) -> Bool {
        guard let index = state.paymentHistory.firstIndex(where: { $0.id == recordId }) else {
            return false
        }
        
        state.paymentHistory[index].paidDate = Date()
        
        // On-time payments improve score
        if state.paymentHistory[index].wasPaidOnTime {
            modifyScore(by: 5, reason: "On-time payment")
        }
        
        recalculateScore()
        return true
    }
    
    /// Miss a payment - damages credit
    func missPayment(recordId: String) {
        modifyScore(by: -30, reason: "Missed payment")
        recalculateScore()
    }
    
    // MARK: - Loan Actions
    
    /// Check if player can get a loan
    func canGetLoan(amount: Double) -> (canGet: Bool, reason: String) {
        let tier = state.tier
        
        if amount > tier.maxLoanAmount {
            return (false, "Credit score too low for this loan amount. Max: $\(Int(tier.maxLoanAmount))")
        }
        
        if state.recentInquiries >= 5 {
            return (false, "Too many recent credit inquiries. Wait before applying.")
        }
        
        if state.debtToIncomeRatio > 0.8 {
            return (false, "Debt-to-income ratio too high. Pay down existing debt first.")
        }
        
        return (true, "Loan approved at \(tier.interestRateMultiplier * 6)% APR")
    }
    
    /// Take out a loan
    func takeLoan(name: String, amount: Double, termMonths: Int) -> Loan? {
        let (canGet, _) = canGetLoan(amount: amount)
        guard canGet else { return nil }
        
        // Add inquiry
        state.recentInquiries += 1
        
        // Calculate interest rate based on credit tier
        let baseRate = 0.06  // 6% base
        let rate = baseRate * state.tier.interestRateMultiplier
        
        // Calculate monthly payment (simplified)
        let monthlyRate = rate / 12
        let monthlyPayment = amount * (monthlyRate * pow(1 + monthlyRate, Double(termMonths))) / (pow(1 + monthlyRate, Double(termMonths)) - 1)
        
        let loan = Loan(
            id: UUID().uuidString,
            name: name,
            principal: amount,
            interestRate: rate,
            termMonths: termMonths,
            startDate: Date(),
            balance: amount,
            monthlyPayment: monthlyPayment
        )
        
        state.activeLoans.append(loan)
        state.totalDebt += amount
        
        // Add monthly payment records
        for month in 1...termMonths {
            addPayment(type: .loan, amount: monthlyPayment, dueInDays: month * 30)
        }
        
        recalculateScore()
        return loan
    }
    
    /// Make a loan payment
    func makeLoanPayment(loanId: String, amount: Double) {
        guard let index = state.activeLoans.firstIndex(where: { $0.id == loanId }) else { return }
        
        state.activeLoans[index].balance -= amount
        state.totalDebt -= amount
        
        if state.activeLoans[index].balance <= 0 {
            state.activeLoans[index].balance = 0
            modifyScore(by: 20, reason: "Loan paid off!")
        }
        
        recalculateScore()
    }
    
    // MARK: - Credit Utilization
    
    func updateCreditUtilization(used: Double, available: Double) {
        state.availableCredit = available
        state.creditUtilization = used / max(1, available)
        recalculateScore()
    }
    
    // MARK: - Age Account
    
    func ageAccountByMonth() {
        state.accountAgeMonths += 1
        
        // Reduce inquiries over time
        if state.recentInquiries > 0 && state.accountAgeMonths % 6 == 0 {
            state.recentInquiries = max(0, state.recentInquiries - 1)
        }
        
        recalculateScore()
    }
    
    // MARK: - Direct Score Modification
    
    func modifyScore(by amount: Int, reason: String) {
        let oldScore = state.score
        state.score = max(300, min(850, state.score + amount))
        
        let actualChange = state.score - oldScore
        if actualChange != 0 {
            recentScoreChange = actualChange
            showCreditChange = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.showCreditChange = false
            }
        }
    }
    
    // MARK: - Persistence
    
    private func save() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: "creditState")
        }
    }
    
    func reset() {
        state = CreditState()
    }
}

// MARK: - Credit Score Display View
struct CreditScoreView: View {
    @ObservedObject var credit = CreditManager.shared
    let compact: Bool
    
    init(compact: Bool = true) {
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
        HStack(spacing: 8) {
            Image(systemName: credit.state.tier.icon)
                .foregroundColor(credit.state.tier.color)
                .font(.system(size: 14))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("CREDIT")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.gray)
                
                Text("\(credit.state.score)")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(credit.state.tier.color)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(credit.state.tier.color.opacity(0.15))
        )
    }
    
    var fullView: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Credit Score")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text(credit.state.tier.rawValue)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(credit.state.tier.color)
            }
            
            // Score display
            HStack(alignment: .bottom, spacing: 4) {
                Text("\(credit.state.score)")
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(credit.state.tier.color)
                
                Text("/ 850")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.bottom, 6)
                
                Spacer()
                
                Image(systemName: credit.state.tier.icon)
                    .font(.system(size: 32))
                    .foregroundColor(credit.state.tier.color)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background with tier zones
                    HStack(spacing: 2) {
                        Rectangle().fill(Color.red.opacity(0.3))
                        Rectangle().fill(Color.orange.opacity(0.3))
                        Rectangle().fill(Color.yellow.opacity(0.3))
                        Rectangle().fill(Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.3))
                        Rectangle().fill(Color.green.opacity(0.3))
                    }
                    .frame(height: 8)
                    .cornerRadius(4)
                    
                    // Current position indicator
                    let progress = CGFloat(credit.state.score - 300) / 550.0
                    Circle()
                        .fill(credit.state.tier.color)
                        .frame(width: 16, height: 16)
                        .offset(x: geometry.size.width * progress - 8)
                }
            }
            .frame(height: 16)
            
            // Tier labels
            HStack {
                Text("300")
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
                Spacer()
                Text("580")
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
                Spacer()
                Text("670")
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
                Spacer()
                Text("740")
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
                Spacer()
                Text("850")
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
            }
            
            // Access description
            Text(credit.state.tier.loanAccessDescription)
                .font(.system(size: 11))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
            
            // Stats
            HStack(spacing: 16) {
                statBadge(label: "On-Time", value: "\(Int(credit.state.onTimePaymentRate * 100))%")
                statBadge(label: "Utilization", value: "\(Int(credit.state.creditUtilization * 100))%")
                statBadge(label: "Age", value: "\(credit.state.accountAgeMonths)mo")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(credit.state.tier.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    func statBadge(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Credit Change Animation
struct CreditChangeView: View {
    let change: Int
    
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: change > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .foregroundColor(change > 0 ? .green : .red)
            Text(change > 0 ? "+\(change)" : "\(change)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(change > 0 ? .green : .red)
            Text("Credit")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.9))
                .overlay(
                    Capsule()
                        .stroke(change > 0 ? Color.green : Color.red, lineWidth: 1)
                )
        )
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
