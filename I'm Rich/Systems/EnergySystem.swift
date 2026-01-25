//
//  EnergySystem.swift
//  Life of Wealth
//
//  Energy pool and action costs - adds strategic resource management
//

import SwiftUI
import Combine

// MARK: - Action Type
enum ActionType: String, Codable, CaseIterable {
    case tap = "Tap to Earn"
    case network = "Network"
    case invest = "Manage Investments"
    case opportunity = "Take Opportunity"
    case familyTime = "Family Time"
    case workOvertime = "Work Overtime"
    case rest = "Rest & Recover"
    case vacation = "Take Vacation"
    case exercise = "Exercise"
    case philanthropy = "Philanthropy"
    
    var energyCost: Int {
        switch self {
        case .tap: return 0  // Always available
        case .network: return 15
        case .invest: return 10
        case .opportunity: return 20
        case .familyTime: return 10
        case .workOvertime: return 25
        case .rest: return 0  // Recovers energy
        case .vacation: return 30
        case .exercise: return 15
        case .philanthropy: return 20
        }
    }
    
    var icon: String {
        switch self {
        case .tap: return "👆"
        case .network: return "🤝"
        case .invest: return "📊"
        case .opportunity: return "🎯"
        case .familyTime: return "👨‍👩‍👧‍👦"
        case .workOvertime: return "💼"
        case .rest: return "😴"
        case .vacation: return "🏖️"
        case .exercise: return "🏃"
        case .philanthropy: return "🎁"
        }
    }
    
    var wealthImpact: WealthImpact {
        switch self {
        case .tap: return WealthImpact()
        case .network: return WealthImpact(relationships: 3)
        case .invest: return WealthImpact(financial: 2)
        case .opportunity: return WealthImpact() // Varies by opportunity
        case .familyTime: return WealthImpact(relationships: 8, health: 3)
        case .workOvertime: return WealthImpact(financial: 10, relationships: -5, health: -8)
        case .rest: return WealthImpact(health: 10)
        case .vacation: return WealthImpact(relationships: 10, experiences: 15, health: 5, legacy: -2)
        case .exercise: return WealthImpact(health: 12)
        case .philanthropy: return WealthImpact(financial: -5, relationships: 5, legacy: 15)
        }
    }
    
    var description: String {
        switch self {
        case .tap: return "Quick cash, no energy needed"
        case .network: return "Build connections and relationships"
        case .invest: return "Review and adjust investments"
        case .opportunity: return "Pursue a time-sensitive opportunity"
        case .familyTime: return "Quality time with loved ones"
        case .workOvertime: return "Extra hours for extra pay"
        case .rest: return "Recharge your energy"
        case .vacation: return "Create lasting memories"
        case .exercise: return "Invest in your health"
        case .philanthropy: return "Give back and build legacy"
        }
    }
}

// MARK: - Energy State
struct EnergyState: Codable {
    var currentEnergy: Int = 100
    var maxEnergy: Int = 100
    var energyRegenRate: Double = 1.0  // Energy per real second
    var lastRegenTime: Date = Date()
    
    var energyPercent: Double {
        Double(currentEnergy) / Double(maxEnergy)
    }
    
    var isFull: Bool {
        currentEnergy >= maxEnergy
    }
    
    var isEmpty: Bool {
        currentEnergy <= 0
    }
}

// MARK: - Energy Manager
class EnergyManager: ObservableObject {
    static let shared = EnergyManager()
    
    @Published var state: EnergyState {
        didSet { save() }
    }
    
    @Published var showInsufficientEnergyAlert = false
    @Published var lastActionType: ActionType?
    
    private var regenTimer: Timer?
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: "energyState"),
           let decoded = try? JSONDecoder().decode(EnergyState.self, from: data) {
            self.state = decoded
            // Apply offline regen
            applyOfflineRegen()
        } else {
            self.state = EnergyState()
        }
        
        startRegenTimer()
    }
    
    // MARK: - Regen Timer
    private func startRegenTimer() {
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.regenerateEnergy()
        }
        // Add to .common mode so it continues during scrolling
        RunLoop.main.add(timer, forMode: .common)
        regenTimer = timer
    }
    
    private func regenerateEnergy() {
        guard state.currentEnergy < state.maxEnergy else { return }
        
        let regenAmount = Int(state.energyRegenRate)
        state.currentEnergy = min(state.maxEnergy, state.currentEnergy + regenAmount)
        state.lastRegenTime = Date()
    }
    
    private func applyOfflineRegen() {
        let now = Date()
        let timeSinceLastRegen = now.timeIntervalSince(state.lastRegenTime)
        let energyToAdd = Int(timeSinceLastRegen * state.energyRegenRate)
        
        if energyToAdd > 0 {
            state.currentEnergy = min(state.maxEnergy, state.currentEnergy + energyToAdd)
            state.lastRegenTime = now
        }
    }
    
    // MARK: - Actions
    func canPerformAction(_ action: ActionType) -> Bool {
        return state.currentEnergy >= action.energyCost
    }
    
    func performAction(_ action: ActionType) -> Bool {
        guard canPerformAction(action) else {
            showInsufficientEnergyAlert = true
            FeedbackCoordinator.shared.error()
            return false
        }
        
        state.currentEnergy -= action.energyCost
        lastActionType = action
        
        // Handle rest specially
        if action == .rest {
            state.currentEnergy = min(state.maxEnergy, state.currentEnergy + 50)
        }
        
        FeedbackCoordinator.shared.tap()
        return true
    }
    
    func consumeEnergy(_ amount: Int) -> Bool {
        guard state.currentEnergy >= amount else {
            showInsufficientEnergyAlert = true
            return false
        }
        state.currentEnergy -= amount
        return true
    }
    
    func restoreEnergy(_ amount: Int) {
        state.currentEnergy = min(state.maxEnergy, state.currentEnergy + amount)
    }
    
    // MARK: - Upgrades
    func upgradeMaxEnergy(by amount: Int) {
        state.maxEnergy += amount
        state.currentEnergy = min(state.maxEnergy, state.currentEnergy + amount)
    }
    
    func upgradeRegenRate(by amount: Double) {
        state.energyRegenRate += amount
    }
    
    // MARK: - Time Display
    var timeToFullEnergy: String {
        guard !state.isFull else { return "Full" }
        
        let energyNeeded = state.maxEnergy - state.currentEnergy
        let secondsNeeded = Double(energyNeeded) / state.energyRegenRate
        
        if secondsNeeded < 60 {
            return "\(Int(secondsNeeded))s"
        } else {
            return "\(Int(secondsNeeded / 60))m"
        }
    }
    
    // MARK: - Persistence
    private func save() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: "energyState")
        }
    }
    
    func reset() {
        state = EnergyState()
    }
}

// MARK: - Energy Bar View
struct EnergyBarView: View {
    @ObservedObject var energy = EnergyManager.shared
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
        HStack(spacing: 6) {
            Text("⚡")
                .font(.system(size: 12))
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(energyColor)
                        .frame(width: geometry.size.width * energy.state.energyPercent, height: 8)
                }
            }
            .frame(width: 50, height: 8)
            
            Text("\(energy.state.currentEnergy)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(energyColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.05))
        )
    }
    
    var fullView: some View {
        VStack(spacing: 6) {
            HStack {
                Text("⚡ Energy")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                Spacer()
                Text("\(energy.state.currentEnergy)/\(energy.state.maxEnergy)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(energyColor)
                if !energy.state.isFull {
                    Text("(\(energy.timeToFullEnergy))")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 10)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [energyColor.opacity(0.8), energyColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * energy.state.energyPercent, height: 10)
                }
            }
            .frame(height: 10)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.03))
        )
    }
    
    var energyColor: Color {
        switch energy.state.currentEnergy {
        case 70...100: return .green
        case 40..<70: return .yellow
        case 20..<40: return .orange
        default: return .red
        }
    }
}

// MARK: - Action Button View
struct ActionButtonView: View {
    let action: ActionType
    let onPerform: () -> Void
    
    @ObservedObject var energy = EnergyManager.shared
    
    var canPerform: Bool {
        energy.canPerformAction(action)
    }
    
    var body: some View {
        Button(action: {
            if energy.performAction(action) {
                onPerform()
            }
        }) {
            VStack(spacing: 4) {
                Text(action.icon)
                    .font(.system(size: 20))
                
                Text(action.rawValue)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                if action.energyCost > 0 {
                    HStack(spacing: 2) {
                        Text("⚡")
                            .font(.system(size: 8))
                        Text("\(action.energyCost)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(canPerform ? .yellow : .gray)
                    }
                }
            }
            .frame(width: 70, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(canPerform ? Color.white.opacity(0.08) : Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(canPerform ? Color.yellow.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .disabled(!canPerform)
        .opacity(canPerform ? 1 : 0.5)
    }
}

// MARK: - Quick Actions Bar
struct QuickActionsBar: View {
    let onFamilyTime: () -> Void
    let onRest: () -> Void
    let onExercise: () -> Void
    let onOvertime: () -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ActionButtonView(action: .familyTime, onPerform: onFamilyTime)
                ActionButtonView(action: .rest, onPerform: onRest)
                ActionButtonView(action: .exercise, onPerform: onExercise)
                ActionButtonView(action: .workOvertime, onPerform: onOvertime)
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Insufficient Energy Alert
struct InsufficientEnergyAlert: View {
    @ObservedObject var energy = EnergyManager.shared
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("⚡")
                .font(.system(size: 40))
            
            Text("NOT ENOUGH ENERGY")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Text("Rest or wait for energy to regenerate")
                .font(.system(size: 12))
                .foregroundColor(.gray)
            
            EnergyBarView(compact: false)
            
            Button(action: onDismiss) {
                Text("OK")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.yellow)
                    )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
