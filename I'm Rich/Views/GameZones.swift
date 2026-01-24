//
//  GameZones.swift
//  Life of Wealth
//
//  Zone-based navigation system with progressive unlocking
//  Core concept: Race to become the world's first trillionaire
//

import SwiftUI

// MARK: - Game Zone Definition
enum GameZone: String, CaseIterable {
    case hustle = "Hustle"
    case career = "Career"
    case invest = "Invest"
    case empire = "Empire"
    case legacy = "Legacy"
    
    var icon: String {
        switch self {
        case .hustle: return "💪"
        case .career: return "📈"
        case .invest: return "💰"
        case .empire: return "🏢"
        case .legacy: return "👑"
        }
    }
    
    var systemIcon: String {
        switch self {
        case .hustle: return "hand.tap.fill"
        case .career: return "briefcase.fill"
        case .invest: return "chart.line.uptrend.xyaxis"
        case .empire: return "building.2.fill"
        case .legacy: return "crown.fill"
        }
    }
    
    var description: String {
        switch self {
        case .hustle: return "Tap, grind, daily challenges"
        case .career: return "Jobs, skills, education"
        case .invest: return "Stocks, real estate, assets"
        case .empire: return "Build companies, hire teams"
        case .legacy: return "Influence, philanthropy, dynasty"
        }
    }
    
    var unlockNetWorth: Double {
        switch self {
        case .hustle: return 0
        case .career: return 1_000
        case .invest: return 10_000
        case .empire: return 1_000_000
        case .legacy: return 100_000_000
        }
    }
    
    var color: Color {
        switch self {
        case .hustle: return .orange
        case .career: return .blue
        case .invest: return .green
        case .empire: return .purple
        case .legacy: return Color(red: 1, green: 0.84, blue: 0) // Gold
        }
    }
    
    func isUnlocked(netWorth: Double) -> Bool {
        netWorth >= unlockNetWorth
    }
    
    var nextZone: GameZone? {
        guard let index = GameZone.allCases.firstIndex(of: self),
              index < GameZone.allCases.count - 1 else { return nil }
        return GameZone.allCases[index + 1]
    }
}

// MARK: - Zone Tab Bar
struct ZoneTabBar: View {
    @Binding var selectedZone: GameZone
    let netWorth: Double
    let unlockedZones: Set<String>
    
    func isZoneUnlocked(_ zone: GameZone) -> Bool {
        // Check permanent unlock OR current net worth qualifies
        unlockedZones.contains(zone.rawValue) || zone.isUnlocked(netWorth: netWorth)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(GameZone.allCases, id: \.self) { zone in
                ZoneTab(
                    zone: zone,
                    isSelected: selectedZone == zone,
                    isUnlocked: isZoneUnlocked(zone),
                    netWorth: netWorth
                ) {
                    if isZoneUnlocked(zone) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedZone = zone
                        }
                        FeedbackCoordinator.shared.tap()
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct ZoneTab: View {
    let zone: GameZone
    let isSelected: Bool
    let isUnlocked: Bool
    let netWorth: Double
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    if isUnlocked {
                        Image(systemName: zone.systemIcon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(isSelected ? zone.color : .gray)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
                .frame(height: 22)
                
                Text(zone.rawValue)
                    .font(.system(size: 9, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isUnlocked ? (isSelected ? zone.color : .gray) : .gray.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? zone.color.opacity(0.15) : Color.clear)
            )
        }
        .disabled(!isUnlocked)
    }
}

// MARK: - Zone Progress Bar (Shows unlock progress)
struct ZoneUnlockProgress: View {
    let currentZone: GameZone
    let netWorth: Double
    
    var nextZone: GameZone? { currentZone.nextZone }
    
    var progress: CGFloat {
        guard let next = nextZone else { return 1.0 }
        let current = currentZone.unlockNetWorth
        let target = next.unlockNetWorth
        return CGFloat((netWorth - current) / (target - current))
    }
    
    var body: some View {
        if let next = nextZone {
            VStack(spacing: 6) {
                HStack {
                    Text("🔓")
                        .font(.system(size: 12))
                    Text("NEXT ZONE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.gray)
                        .tracking(1)
                    Spacer()
                    HStack(spacing: 4) {
                        Text(next.icon)
                            .font(.system(size: 12))
                        Text(next.rawValue)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(next.color)
                    }
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [currentZone.color, next.color],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(6, geometry.size.width * progress), height: 6)
                    }
                }
                .frame(height: 6)
                
                HStack {
                    Text(formatCompact(netWorth))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text(formatCompact(next.unlockNetWorth))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(next.color)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(next.color.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    func formatCompact(_ value: Double) -> String {
        switch value {
        case 1_000_000_000_000...: return String(format: "%.1fT", value / 1_000_000_000_000)
        case 1_000_000_000...: return String(format: "%.1fB", value / 1_000_000_000)
        case 1_000_000...: return String(format: "%.1fM", value / 1_000_000)
        case 1_000...: return String(format: "%.1fK", value / 1_000)
        default: return String(format: "%.0f", value)
        }
    }
}

// MARK: - Trillionaire Goal Display
struct TrillionaireGoalView: View {
    let netWorth: Double
    let accentColor = Color(red: 1, green: 0.84, blue: 0)  // Gold
    
    var progress: CGFloat {
        CGFloat(netWorth / 1_000_000_000_000)
    }
    
    var percentComplete: Double {
        (netWorth / 1_000_000_000_000) * 100
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("🏆")
                    .font(.system(size: 16))
                Text("RACE TO TRILLIONAIRE")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(accentColor)
                    .tracking(2)
                Spacer()
                if progress >= 1.0 {
                    Text("ACHIEVED!")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.green)
                } else {
                    Text(String(format: "%.6f%%", percentComplete))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                }
            }
            
            // Progress bar with milestones
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 12)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [.orange, accentColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(12, geometry.size.width * min(1, progress)), height: 12)
                    
                    // Milestone markers (log scale visualization would be better but this is simple)
                    ForEach([0.001, 0.01, 0.1, 0.5], id: \.self) { milestone in
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 1, height: 16)
                            .offset(x: geometry.size.width * CGFloat(milestone))
                    }
                }
            }
            .frame(height: 16)
            
            // Labels
            HStack {
                Text("$0")
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
                Spacer()
                Text("$1B")
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
                Spacer()
                Text("$100B")
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
                Spacer()
                Text("$1T")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(accentColor)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [accentColor.opacity(0.1), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(accentColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Compact Tap Button (For Hustle Zone)
struct CompactTapButton: View {
    @ObservedObject var game: GameState
    @State private var isPressed = false
    @State private var showReward = false
    @State private var rewardAmount: Double = 0
    
    let accentColor = Color(red: 0.4, green: 0.7, blue: 0.4)
    
    var body: some View {
        HStack(spacing: 16) {
            tapButton
            streakDisplay
        }
        .overlay(rewardOverlay)
    }
    
    private var tapButton: some View {
        Button(action: performTap) {
            tapButtonContent
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
    
    private var tapButtonContent: some View {
        HStack(spacing: 10) {
            Text("💵")
                .font(.system(size: 24))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("TAP TO EARN")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
                Text("+\(game.formatCompact(game.tapValue))")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(accentColor)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("TAPS")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.gray)
                Text("\(game.totalTaps)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(tapButtonBackground)
        .scaleEffect(isPressed ? 0.97 : 1.0)
    }
    
    private var tapButtonBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(accentColor.opacity(isPressed ? 0.3 : 0.15))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(accentColor.opacity(0.5), lineWidth: 2)
            )
    }
    
    @ViewBuilder
    private var streakDisplay: some View {
        if game.currentStreak > 0 {
            VStack(spacing: 2) {
                Text("🔥")
                    .font(.system(size: 16))
                Text("\(game.currentStreak)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.orange)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.orange.opacity(0.15))
            )
        }
    }
    
    @ViewBuilder
    private var rewardOverlay: some View {
        if showReward {
            Text("+\(game.formatCompact(rewardAmount))")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(accentColor)
                .offset(y: -30)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    func performTap() {
        rewardAmount = game.tapValue
        game.tap()
        
        withAnimation(.easeOut(duration: 0.3)) {
            showReward = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                showReward = false
            }
        }
        
        FeedbackCoordinator.shared.tap()
    }
}

// MARK: - Daily Grind Section (For Hustle Zone)
struct DailyGrindSection: View {
    @ObservedObject var game: GameState
    @ObservedObject var dailySystem = DailySystemManager.shared
    
    var body: some View {
        VStack(spacing: 12) {
            // Section Header
            HStack {
                Text("📅")
                    .font(.system(size: 14))
                Text("DAILY GRIND")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("Day \(dailySystem.loginStreak)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.orange)
            }
            
            // Compact challenge list
            ForEach(Array(dailySystem.todaysChallenges.prefix(3).enumerated()), id: \.element.id) { index, challenge in
                CompactChallengeRow(challenge: challenge, challengeIndex: index, game: game)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
        )
    }
}

struct CompactChallengeRow: View {
    let challenge: DailyChallenge
    let challengeIndex: Int
    @ObservedObject var game: GameState
    @ObservedObject var dailySystem = DailySystemManager.shared
    
    var progress: CGFloat {
        CGFloat(min(challenge.currentValue, challenge.targetValue)) / CGFloat(challenge.targetValue)
    }
    
    var body: some View {
        HStack(spacing: 10) {
            // Progress circle
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 3)
                    .frame(width: 32, height: 32)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(challenge.isComplete ? Color.green : Color.orange, lineWidth: 3)
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(-90))
                
                if challenge.isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)
                }
            }
            
            // Challenge info
            VStack(alignment: .leading, spacing: 2) {
                Text(challenge.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                Text("\(challenge.currentValue)/\(challenge.targetValue)")
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Reward
            if challenge.isComplete && !challenge.claimed {
                Button(action: {
                    dailySystem.claimChallengeReward(index: challengeIndex, game: game)
                }) {
                    Text("+\(game.formatCompact(game.scaleReward(challenge.rewardCash)))")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.green)
                        )
                }
            } else if challenge.claimed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 16))
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.02))
        )
    }
}

// MARK: - Quick Stats Bar
struct QuickStatsBar: View {
    @ObservedObject var game: GameState
    
    // Convert per-second income to per-year (300 seconds = 1 game year)
    var incomePerYear: Double {
        game.passiveIncomePerSecond * LifeCycleConstants.secondsPerGameYear
    }
    
    var body: some View {
        HStack(spacing: 8) {
            QuickStatItem(icon: "💵", label: "Cash", value: game.formatCompact(game.cash), color: .green)
            QuickStatItem(icon: "📊", label: "Net Worth", value: game.formatCompact(game.netWorth), color: .blue)
            QuickStatItem(icon: "📈", label: "Income/yr", value: game.formatCompact(incomePerYear), color: .purple)
            QuickStatItem(icon: "⭐", label: "Status", value: "\(game.statusPoints)", color: .orange)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
        )
    }
}

struct QuickStatItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.system(size: 14))
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Zone Locked View
struct ZoneLockedView: View {
    let zone: GameZone
    let currentNetWorth: Double
    
    var remaining: Double {
        zone.unlockNetWorth - currentNetWorth
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("🔒")
                .font(.system(size: 60))
            
            Text("\(zone.rawValue) Zone")
                .font(.system(size: 24, weight: .black))
                .foregroundColor(.white)
            
            Text("LOCKED")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.gray)
                .tracking(3)
            
            VStack(spacing: 8) {
                Text("Requires")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Text(formatCompact(zone.unlockNetWorth))
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(zone.color)
                
                Text("Net Worth")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(zone.color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(zone.color.opacity(0.3), lineWidth: 1)
                    )
            )
            
            Text("You need \(formatCompact(remaining)) more")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Spacer()
        }
        .padding()
    }
    
    func formatCompact(_ value: Double) -> String {
        switch value {
        case 1_000_000_000_000...: return String(format: "$%.1fT", value / 1_000_000_000_000)
        case 1_000_000_000...: return String(format: "$%.1fB", value / 1_000_000_000)
        case 1_000_000...: return String(format: "$%.1fM", value / 1_000_000)
        case 1_000...: return String(format: "$%.1fK", value / 1_000)
        default: return String(format: "$%.0f", value)
        }
    }
}
