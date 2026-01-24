//
//  PrestigeSystem.swift
//  I'm Rich
//
//  Prestige mechanics: legacy bonuses, life resets, and progression across lives
//

import SwiftUI
import Combine

// MARK: - Prestige State
struct PrestigeState: Codable {
    var livesLived: Int = 0
    var totalLifetimeEarnings: Double = 0
    var legacyMultiplier: Double = 1.0
    var unlockedThemeIds: [String] = []
    var completedLessonIds: [String] = []
    var unlockedAchievementIds: [String] = []
    var startingCashBonus: Double = 0
    var bestLifeEarnings: Double = 0
    var fastestToMillion: Int? = nil // Years
    var fastestToBillion: Int? = nil
    
    // Life of Wealth additions
    var lastEnding: LifeEnding? = nil
    var endingHistory: [LifeEnding] = []
    var endingBonusMultipliers: [String: Double] = [:] // Dimension multipliers from endings
}

// MARK: - Prestige Manager
class PrestigeManager: ObservableObject {
    static let shared = PrestigeManager()
    
    @Published var state: PrestigeState {
        didSet { save() }
    }
    @Published var showPrestigeConfirmation = false
    @Published var pendingPrestigePreview: PrestigePreview?
    
    var legacyMultiplier: Double {
        state.legacyMultiplier
    }
    
    var livesLived: Int {
        state.livesLived
    }
    
    var hasPrestiged: Bool {
        state.livesLived > 0
    }
    
    var formattedMultiplier: String {
        String(format: "%.1fx", state.legacyMultiplier)
    }
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: "prestigeState"),
           let decoded = try? JSONDecoder().decode(PrestigeState.self, from: data) {
            self.state = decoded
        } else {
            self.state = PrestigeState()
        }
    }
    
    /// Reset all prestige state to fresh values
    func reset() {
        state = PrestigeState()
        showPrestigeConfirmation = false
        pendingPrestigePreview = nil
        UserDefaults.standard.removeObject(forKey: "prestigeState")
    }
    
    // MARK: - Preview what you'll get from prestiging
    func calculatePrestigePreview(currentEarnings: Double, currentAge: Int, yearsPlayed: Int) -> PrestigePreview {
        let multiplierGain = calculateMultiplierGain(earnings: currentEarnings)
        let startingCash = calculateStartingCash(earnings: currentEarnings)
        
        return PrestigePreview(
            currentEarnings: currentEarnings,
            currentAge: currentAge,
            yearsPlayed: yearsPlayed,
            newLegacyMultiplier: state.legacyMultiplier + multiplierGain,
            multiplierGain: multiplierGain,
            startingCashBonus: startingCash,
            newLivesCount: state.livesLived + 1
        )
    }
    
    private func calculateMultiplierGain(earnings: Double) -> Double {
        // +10% per billion earned, minimum +5%
        let billionsEarned = earnings / 1_000_000_000
        return max(0.05, billionsEarned * 0.10)
    }
    
    private func calculateStartingCash(earnings: Double) -> Double {
        // 1% of lifetime earnings, capped at $10M
        return min(earnings * 0.01, 10_000_000)
    }
    
    // MARK: - Execute Prestige
    func prestige(
        currentEarnings: Double,
        currentAge: Int,
        yearsPlayed: Int,
        themeManager: ThemeManager,
        educationManager: EducationManager,
        achievementManager: AchievementManager,
        ending: LifeEnding? = nil
    ) {
        // Calculate bonuses
        let multiplierGain = calculateMultiplierGain(earnings: currentEarnings)
        var startingCash = calculateStartingCash(earnings: currentEarnings)
        
        // Apply ending-based bonuses
        if let ending = ending {
            state.lastEnding = ending
            state.endingHistory.append(ending)
            
            let endingBonus = ending.prestigeBonus
            
            // Apply starting cash bonus from ending
            startingCash += currentEarnings * endingBonus.startingCashBonus
            
            // Store ending multipliers for wealth dimensions
            state.endingBonusMultipliers["financial"] = endingBonus.financialMultiplier
            state.endingBonusMultipliers["relationships"] = endingBonus.relationshipsMultiplier
            state.endingBonusMultipliers["experiences"] = endingBonus.experiencesMultiplier
            state.endingBonusMultipliers["health"] = endingBonus.healthMultiplier
            state.endingBonusMultipliers["legacy"] = endingBonus.legacyMultiplier
        }
        
        // Update prestige state
        state.livesLived += 1
        state.totalLifetimeEarnings += currentEarnings
        state.legacyMultiplier += multiplierGain
        state.startingCashBonus = startingCash
        
        // Track records
        if currentEarnings > state.bestLifeEarnings {
            state.bestLifeEarnings = currentEarnings
        }
        
        // Preserve unlocks
        state.unlockedThemeIds = themeManager.themes.filter { $0.unlocked }.map { $0.id }
        state.completedLessonIds = educationManager.completedLessonIds
        state.unlockedAchievementIds = achievementManager.achievements.filter { $0.unlocked }.map { $0.id }
        
        save()
        
        // Haptic feedback
        FeedbackCoordinator.shared.phaseUnlock()
    }
    
    // MARK: - Get ending bonus for a wealth dimension
    func getEndingBonus(for dimension: WealthDimension) -> Double {
        let key = dimension.rawValue.lowercased()
        return state.endingBonusMultipliers[key] ?? 1.0
    }
    
    // MARK: - Get starting cash for new life
    func getStartingCash() -> Double {
        return state.startingCashBonus
    }
    
    // MARK: - Restore unlocks after prestige
    func restoreUnlocks(
        themeManager: ThemeManager,
        educationManager: EducationManager,
        achievementManager: AchievementManager
    ) {
        // Restore themes
        for themeId in state.unlockedThemeIds {
            themeManager.unlockTheme(themeId)
        }
        
        // Restore lessons
        for lessonId in state.completedLessonIds {
            educationManager.markLessonCompleted(lessonId)
        }
        
        // Restore achievements
        for achievementId in state.unlockedAchievementIds {
            achievementManager.restoreAchievement(achievementId)
        }
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: "prestigeState")
        }
    }
    
    func fullReset() {
        state = PrestigeState()
        save()
    }
}

// MARK: - Prestige Preview
struct PrestigePreview {
    let currentEarnings: Double
    let currentAge: Int
    let yearsPlayed: Int
    let newLegacyMultiplier: Double
    let multiplierGain: Double
    let startingCashBonus: Double
    let newLivesCount: Int
}

// MARK: - Prestige Confirmation View
struct PrestigeConfirmationView: View {
    let preview: PrestigePreview
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    let accentColor = Color(red: 0.4, green: 0.7, blue: 0.4)
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🌟")
                .font(.system(size: 50))
            
            Text("START A NEW LIFE?")
                .font(.system(size: 20, weight: .black))
                .foregroundColor(.white)
                .tracking(2)
            
            Text("Your legacy will carry forward")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            // Stats
            VStack(spacing: 12) {
                prestigeStatRow(label: "Lives Lived", value: "\(preview.newLivesCount)")
                prestigeStatRow(label: "Legacy Multiplier", value: String(format: "%.1fx → %.1fx", preview.newLegacyMultiplier - preview.multiplierGain, preview.newLegacyMultiplier), highlight: true)
                prestigeStatRow(label: "Starting Cash", value: formatCompact(preview.startingCashBonus))
                prestigeStatRow(label: "Themes & Lessons", value: "Preserved", highlight: true)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
            
            // Warning
            Text("Cash, investments, career, and age will reset")
                .font(.system(size: 11))
                .foregroundColor(.orange)
                .multilineTextAlignment(.center)
            
            // Buttons
            HStack(spacing: 16) {
                Button(action: onCancel) {
                    Text("Keep Playing")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                        )
                }
                
                Button(action: onConfirm) {
                    Text("New Life")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(accentColor)
                        )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(accentColor, lineWidth: 2)
                )
                .shadow(color: accentColor.opacity(0.3), radius: 20)
        )
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
    
    func prestigeStatRow(label: String, value: String, highlight: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(highlight ? accentColor : .white)
        }
    }
    
    func formatCompact(_ value: Double) -> String {
        switch value {
        case 1_000_000_000...: return String(format: "$%.1fB", value / 1_000_000_000)
        case 1_000_000...: return String(format: "$%.1fM", value / 1_000_000)
        case 1_000...: return String(format: "$%.1fK", value / 1_000)
        default: return "$\(Int(value))"
        }
    }
}

// MARK: - Retirement Button View
struct RetirementButtonView: View {
    let canRetire: Bool
    let age: Int
    let onTap: () -> Void
    
    let accentColor = Color(red: 0.4, green: 0.7, blue: 0.4)
    
    var body: some View {
        if canRetire {
            Button(action: onTap) {
                HStack(spacing: 8) {
                    Text("🌟")
                        .font(.system(size: 16))
                    Text("Retire & Start New Life")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
        }
    }
}

// MARK: - Lives Counter View
struct LivesCounterView: View {
    @ObservedObject var prestige = PrestigeManager.shared
    
    var body: some View {
        if prestige.hasPrestiged {
            HStack(spacing: 4) {
                Text("🌟")
                    .font(.system(size: 10))
                Text("Life \(prestige.livesLived + 1)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                Text("(\(prestige.formattedMultiplier))")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.4))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.1))
            )
        }
    }
}
