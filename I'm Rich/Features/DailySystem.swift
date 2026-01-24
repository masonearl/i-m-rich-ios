//
//  DailySystem.swift
//  I'm Rich
//
//  Daily login streaks, challenges, and weekly goals
//

import SwiftUI
import Combine

// MARK: - Daily Challenge
struct DailyChallenge: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let targetValue: Int
    var currentValue: Int = 0
    let rewardCash: Double
    let rewardStatus: Int
    var completed: Bool = false
    var claimed: Bool = false
    
    var progress: Double {
        min(Double(currentValue) / Double(targetValue), 1.0)
    }
    
    var isComplete: Bool {
        currentValue >= targetValue
    }
}

// MARK: - Challenge Templates
enum ChallengeType: CaseIterable {
    case tapCount
    case investAmount
    case earnAmount
    case completeOpportunity
    case purchaseUpgrade
    case meetContact
    case reachStreak
    
    func generate(difficulty: Int) -> DailyChallenge {
        let multiplier = Double(difficulty)
        
        switch self {
        case .tapCount:
            let target = [500, 1000, 2500, 5000, 10000][min(difficulty - 1, 4)]
            return DailyChallenge(
                id: UUID().uuidString,
                title: "Tap Master",
                description: "Tap \(target) times today",
                icon: "👆",
                targetValue: target,
                rewardCash: 500 * multiplier,
                rewardStatus: 5 * difficulty
            )
            
        case .investAmount:
            let target = [1000, 5000, 25000, 100000, 500000][min(difficulty - 1, 4)]
            return DailyChallenge(
                id: UUID().uuidString,
                title: "Smart Investor",
                description: "Invest $\(target) today",
                icon: "📊",
                targetValue: target,
                rewardCash: Double(target) * 0.1,
                rewardStatus: 10 * difficulty
            )
            
        case .earnAmount:
            let target = [5000, 25000, 100000, 500000, 2000000][min(difficulty - 1, 4)]
            return DailyChallenge(
                id: UUID().uuidString,
                title: "Money Maker",
                description: "Earn $\(target) today",
                icon: "💰",
                targetValue: target,
                rewardCash: Double(target) * 0.05,
                rewardStatus: 15 * difficulty
            )
            
        case .completeOpportunity:
            return DailyChallenge(
                id: UUID().uuidString,
                title: "Opportunity Seeker",
                description: "Complete \(difficulty) opportunit\(difficulty == 1 ? "y" : "ies")",
                icon: "🎲",
                targetValue: difficulty,
                rewardCash: 2000 * multiplier,
                rewardStatus: 20 * difficulty
            )
            
        case .purchaseUpgrade:
            return DailyChallenge(
                id: UUID().uuidString,
                title: "Level Up",
                description: "Purchase \(difficulty) upgrade\(difficulty == 1 ? "" : "s")",
                icon: "⬆️",
                targetValue: difficulty,
                rewardCash: 1000 * multiplier,
                rewardStatus: 10 * difficulty
            )
            
        case .meetContact:
            return DailyChallenge(
                id: UUID().uuidString,
                title: "Networker",
                description: "Meet \(difficulty) new contact\(difficulty == 1 ? "" : "s")",
                icon: "🤝",
                targetValue: difficulty,
                rewardCash: 5000 * multiplier,
                rewardStatus: 25 * difficulty
            )
            
        case .reachStreak:
            let target = [100, 250, 500, 1000, 2500][min(difficulty - 1, 4)]
            return DailyChallenge(
                id: UUID().uuidString,
                title: "Streak Hunter",
                description: "Reach a \(target) tap streak",
                icon: "🔥",
                targetValue: target,
                rewardCash: 1000 * multiplier,
                rewardStatus: 15 * difficulty
            )
        }
    }
}

// MARK: - Weekly Goal
struct WeeklyGoal: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let targetValue: Double
    var currentValue: Double = 0
    let rewardCash: Double
    let rewardStatus: Int
    var completed: Bool = false
    var claimed: Bool = false
    
    var progress: Double {
        min(currentValue / targetValue, 1.0)
    }
}

// MARK: - Login Streak Reward
struct LoginReward: Codable {
    let day: Int
    let cashReward: Double
    let statusReward: Int
    let specialReward: String? // Theme unlock, etc.
    
    var description: String {
        var parts: [String] = []
        if cashReward > 0 { parts.append("$\(Int(cashReward))") }
        if statusReward > 0 { parts.append("+\(statusReward) Status") }
        if let special = specialReward { parts.append(special) }
        return parts.joined(separator: " + ")
    }
}

let loginRewards: [LoginReward] = [
    LoginReward(day: 1, cashReward: 500, statusReward: 5, specialReward: nil),
    LoginReward(day: 2, cashReward: 1000, statusReward: 10, specialReward: nil),
    LoginReward(day: 3, cashReward: 2500, statusReward: 15, specialReward: nil),
    LoginReward(day: 4, cashReward: 5000, statusReward: 20, specialReward: nil),
    LoginReward(day: 5, cashReward: 7500, statusReward: 25, specialReward: nil),
    LoginReward(day: 6, cashReward: 10000, statusReward: 30, specialReward: nil),
    LoginReward(day: 7, cashReward: 25000, statusReward: 50, specialReward: "2x Tap Boost (1hr)"),
    LoginReward(day: 14, cashReward: 50000, statusReward: 100, specialReward: nil),
    LoginReward(day: 21, cashReward: 100000, statusReward: 150, specialReward: nil),
    LoginReward(day: 30, cashReward: 500000, statusReward: 300, specialReward: "Legendary Streak Theme")
]

// MARK: - Daily System Manager
class DailySystemManager: ObservableObject {
    static let shared = DailySystemManager()
    
    @Published var loginStreak: Int {
        didSet { save() }
    }
    @Published var lastLoginDate: Date? {
        didSet { save() }
    }
    @Published var todaysChallenges: [DailyChallenge] {
        didSet { save() }
    }
    @Published var weeklyGoal: WeeklyGoal? {
        didSet { save() }
    }
    @Published var showLoginReward = false
    @Published var currentLoginReward: LoginReward?
    @Published var dailyTapsToday: Int = 0
    @Published var dailyEarnedToday: Double = 0
    @Published var dailyInvestedToday: Double = 0
    
    private var lastChallengeDate: Date?
    
    init() {
        // Load saved state
        self.loginStreak = UserDefaults.standard.integer(forKey: "loginStreak")
        
        if let lastLoginData = UserDefaults.standard.object(forKey: "lastLoginDate") as? Date {
            self.lastLoginDate = lastLoginData
        } else {
            self.lastLoginDate = nil
        }
        
        if let data = UserDefaults.standard.data(forKey: "todaysChallenges"),
           let decoded = try? JSONDecoder().decode([DailyChallenge].self, from: data) {
            self.todaysChallenges = decoded
        } else {
            self.todaysChallenges = []
        }
        
        if let data = UserDefaults.standard.data(forKey: "weeklyGoal"),
           let decoded = try? JSONDecoder().decode(WeeklyGoal.self, from: data) {
            self.weeklyGoal = decoded
        } else {
            self.weeklyGoal = nil
        }
        
        if let lastChallengeData = UserDefaults.standard.object(forKey: "lastChallengeDate") as? Date {
            self.lastChallengeDate = lastChallengeData
        }
        
        // Check and refresh on init
        checkDailyReset()
    }
    
    // MARK: - Login Streak
    
    func checkLogin() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastLogin = lastLoginDate {
            let lastLoginDay = calendar.startOfDay(for: lastLogin)
            let daysDiff = calendar.dateComponents([.day], from: lastLoginDay, to: today).day ?? 0
            
            if daysDiff == 0 {
                // Already logged in today
                return
            } else if daysDiff == 1 {
                // Consecutive day - increment streak
                loginStreak += 1
            } else {
                // Streak broken - reset
                loginStreak = 1
            }
        } else {
            // First login ever
            loginStreak = 1
        }
        
        lastLoginDate = Date()
        
        // Find applicable reward
        if let reward = loginRewards.last(where: { $0.day <= loginStreak }) {
            currentLoginReward = reward
            showLoginReward = true
        }
    }
    
    func claimLoginReward(game: GameState) {
        guard let reward = currentLoginReward else { return }
        
        // Scale login rewards to current wealth level
        let scaledReward = game.scaleReward(reward.cashReward)
        game.cash += scaledReward
        game.totalEarned += scaledReward
        game.statusPoints += reward.statusReward
        
        // Handle special rewards
        if let special = reward.specialReward {
            if special.contains("Theme") {
                ThemeManager.shared.unlockTheme(special)
            }
            // TODO: Handle boost rewards
        }
        
        showLoginReward = false
        currentLoginReward = nil
        
        FeedbackCoordinator.shared.achievementUnlock()
    }
    
    // MARK: - Daily Challenges
    
    func checkDailyReset() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let shouldRefresh: Bool
        if let lastChallenge = lastChallengeDate {
            let lastChallengeDay = calendar.startOfDay(for: lastChallenge)
            shouldRefresh = lastChallengeDay < today
        } else {
            shouldRefresh = true
        }
        
        if shouldRefresh {
            generateDailyChallenges()
            generateWeeklyGoal()
            dailyTapsToday = 0
            dailyEarnedToday = 0
            dailyInvestedToday = 0
            lastChallengeDate = Date()
            UserDefaults.standard.set(lastChallengeDate, forKey: "lastChallengeDate")
        }
    }
    
    private func generateDailyChallenges() {
        // Generate 3 random challenges of varying difficulty
        var challenges: [DailyChallenge] = []
        var usedTypes: Set<Int> = []
        
        for difficulty in 1...3 {
            var typeIndex: Int
            repeat {
                typeIndex = Int.random(in: 0..<ChallengeType.allCases.count)
            } while usedTypes.contains(typeIndex)
            usedTypes.insert(typeIndex)
            
            let type = ChallengeType.allCases[typeIndex]
            challenges.append(type.generate(difficulty: difficulty))
        }
        
        todaysChallenges = challenges
    }
    
    private func generateWeeklyGoal() {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        
        // Only generate on Sunday (1) or if no goal exists
        guard weekday == 1 || weeklyGoal == nil else { return }
        
        let goals = [
            WeeklyGoal(id: UUID().uuidString, title: "Weekly Earner", description: "Earn $1,000,000 this week", icon: "💵", targetValue: 1_000_000, rewardCash: 100_000, rewardStatus: 100),
            WeeklyGoal(id: UUID().uuidString, title: "Phase Climber", description: "Reach Phase 2", icon: "📈", targetValue: 10_000, rewardCash: 50_000, rewardStatus: 50),
            WeeklyGoal(id: UUID().uuidString, title: "Investment King", description: "Invest $500,000 total", icon: "🏦", targetValue: 500_000, rewardCash: 75_000, rewardStatus: 75),
            WeeklyGoal(id: UUID().uuidString, title: "Tap Marathon", description: "Reach 50,000 taps", icon: "👆", targetValue: 50_000, rewardCash: 25_000, rewardStatus: 50)
        ]
        
        weeklyGoal = goals.randomElement()
    }
    
    // MARK: - Progress Tracking
    
    func recordTap() {
        dailyTapsToday += 1
        updateChallengeProgress(type: .tapCount, value: 1)
    }
    
    func recordEarning(_ amount: Double) {
        dailyEarnedToday += amount
        updateChallengeProgress(type: .earnAmount, value: Int(amount))
        
        // Update weekly goal if it's earning-based
        if let goal = weeklyGoal, goal.title.contains("Earn") {
            weeklyGoal?.currentValue += amount
            checkWeeklyGoalCompletion()
        }
    }
    
    func recordInvestment(_ amount: Double) {
        dailyInvestedToday += amount
        updateChallengeProgress(type: .investAmount, value: Int(amount))
        
        if let goal = weeklyGoal, goal.title.contains("Invest") {
            weeklyGoal?.currentValue += amount
            checkWeeklyGoalCompletion()
        }
    }
    
    func recordOpportunity() {
        updateChallengeProgress(type: .completeOpportunity, value: 1)
    }
    
    func recordUpgrade() {
        updateChallengeProgress(type: .purchaseUpgrade, value: 1)
    }
    
    func recordContact() {
        updateChallengeProgress(type: .meetContact, value: 1)
    }
    
    func recordStreak(_ streak: Int) {
        // Check if any streak challenge target is met
        for i in 0..<todaysChallenges.count {
            if todaysChallenges[i].icon == "🔥" && streak >= todaysChallenges[i].targetValue {
                todaysChallenges[i].currentValue = todaysChallenges[i].targetValue
                todaysChallenges[i].completed = true
            }
        }
    }
    
    private func updateChallengeProgress(type: ChallengeType, value: Int) {
        for i in 0..<todaysChallenges.count {
            // Match by icon (simple heuristic)
            let challenge = todaysChallenges[i]
            let matches: Bool
            switch type {
            case .tapCount: matches = challenge.icon == "👆"
            case .investAmount: matches = challenge.icon == "📊"
            case .earnAmount: matches = challenge.icon == "💰"
            case .completeOpportunity: matches = challenge.icon == "🎲"
            case .purchaseUpgrade: matches = challenge.icon == "⬆️"
            case .meetContact: matches = challenge.icon == "🤝"
            case .reachStreak: matches = challenge.icon == "🔥"
            }
            
            if matches && !todaysChallenges[i].completed {
                todaysChallenges[i].currentValue += value
                if todaysChallenges[i].isComplete {
                    todaysChallenges[i].completed = true
                }
            }
        }
    }
    
    private func checkWeeklyGoalCompletion() {
        guard var goal = weeklyGoal else { return }
        if goal.currentValue >= goal.targetValue && !goal.completed {
            goal.completed = true
            weeklyGoal = goal
        }
    }
    
    // MARK: - Claim Rewards
    
    func claimChallengeReward(index: Int, game: GameState) {
        guard index < todaysChallenges.count else { return }
        guard todaysChallenges[index].completed && !todaysChallenges[index].claimed else { return }
        
        let challenge = todaysChallenges[index]
        // Scale rewards to current wealth level
        let scaledReward = game.scaleReward(challenge.rewardCash)
        game.cash += scaledReward
        game.totalEarned += scaledReward
        game.statusPoints += challenge.rewardStatus
        
        todaysChallenges[index].claimed = true
        
        FeedbackCoordinator.shared.achievementUnlock()
    }
    
    func claimWeeklyReward(game: GameState) {
        guard var goal = weeklyGoal else { return }
        guard goal.completed && !goal.claimed else { return }
        
        // Scale rewards to current wealth level
        let scaledReward = game.scaleReward(goal.rewardCash)
        game.cash += scaledReward
        game.totalEarned += scaledReward
        game.statusPoints += goal.rewardStatus
        
        goal.claimed = true
        weeklyGoal = goal
        
        FeedbackCoordinator.shared.phaseUnlock()
    }
    
    // MARK: - Persistence
    
    private func save() {
        UserDefaults.standard.set(loginStreak, forKey: "loginStreak")
        UserDefaults.standard.set(lastLoginDate, forKey: "lastLoginDate")
        
        if let data = try? JSONEncoder().encode(todaysChallenges) {
            UserDefaults.standard.set(data, forKey: "todaysChallenges")
        }
        
        if let goal = weeklyGoal, let data = try? JSONEncoder().encode(goal) {
            UserDefaults.standard.set(data, forKey: "weeklyGoal")
        }
    }
    
    func reset() {
        loginStreak = 0
        lastLoginDate = nil
        todaysChallenges = []
        weeklyGoal = nil
        dailyTapsToday = 0
        dailyEarnedToday = 0
        dailyInvestedToday = 0
        lastChallengeDate = nil
    }
    
    func resetForPrestige() {
        // Keep login streak (it's real-world based)
        // Reset daily progress
        dailyTapsToday = 0
        dailyEarnedToday = 0
        dailyInvestedToday = 0
        // Regenerate challenges
        generateDailyChallenges()
    }
}

// MARK: - Daily Challenges View
struct DailyChallengesView: View {
    @ObservedObject var dailySystem: DailySystemManager
    @ObservedObject var game: GameState
    
    let accentColor = Color(red: 0.4, green: 0.7, blue: 0.4)
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with streak
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DAILY CHALLENGES")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.gray)
                        .tracking(1.5)
                    
                    HStack(spacing: 6) {
                        Text("🔥")
                        Text("\(dailySystem.loginStreak) Day Streak")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.orange)
                    }
                }
                Spacer()
            }
            
            // Challenges
            ForEach(Array(dailySystem.todaysChallenges.enumerated()), id: \.element.id) { index, challenge in
                challengeRow(challenge, index: index)
            }
            
            // Weekly goal
            if let goal = dailySystem.weeklyGoal {
                weeklyGoalRow(goal)
            }
        }
    }
    
    func challengeRow(_ challenge: DailyChallenge, index: Int) -> some View {
        HStack(spacing: 12) {
            Text(challenge.icon)
                .font(.system(size: 24))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(challenge.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(challenge.completed ? accentColor : Color.yellow)
                            .frame(width: geometry.size.width * challenge.progress, height: 6)
                    }
                }
                .frame(height: 6)
                
                Text("\(challenge.currentValue)/\(challenge.targetValue)")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                // Show scaled reward
                Text("+\(game.formatCompact(game.scaleReward(challenge.rewardCash)))")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(accentColor)
                
                if challenge.completed && !challenge.claimed {
                    Button(action: {
                        dailySystem.claimChallengeReward(index: index, game: game)
                    }) {
                        Text("Claim")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(accentColor)
                            .cornerRadius(8)
                    }
                } else if challenge.claimed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(accentColor)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(challenge.completed ? accentColor.opacity(0.1) : Color.white.opacity(0.05))
        )
    }
    
    func weeklyGoalRow(_ goal: WeeklyGoal) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(goal.icon)
                    .font(.system(size: 20))
                Text("WEEKLY GOAL")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.purple)
                    .tracking(1)
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(goal.description)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    // Show scaled reward
                    Text("+\(game.formatCompact(game.scaleReward(goal.rewardCash)))")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.purple)
                    
                    if goal.completed && !goal.claimed {
                        Button(action: {
                            dailySystem.claimWeeklyReward(game: game)
                        }) {
                            Text("Claim")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.purple)
                                .cornerRadius(8)
                        }
                    } else {
                        Text("\(Int(goal.progress * 100))%")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.purple)
                    }
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(Color.purple)
                        .frame(width: geometry.size.width * goal.progress, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Login Reward View
struct LoginRewardView: View {
    @ObservedObject var game: GameState
    let reward: LoginReward
    let streak: Int
    let onClaim: () -> Void
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🔥")
                .font(.system(size: 60))
            
            Text("DAY \(streak)")
                .font(.system(size: 36, weight: .black))
                .foregroundColor(.orange)
            
            Text("LOGIN STREAK")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.gray)
                .tracking(2)
            
            VStack(spacing: 8) {
                if reward.cashReward > 0 {
                    Text("+\(game.formatCompact(game.scaleReward(reward.cashReward)))")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.4))
                }
                
                if reward.statusReward > 0 {
                    Text("+\(reward.statusReward) Status")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.purple)
                }
                
                if let special = reward.specialReward {
                    Text(special)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.yellow)
                        .padding(.top, 4)
                }
            }
            
            Button(action: onClaim) {
                Text("CLAIM REWARD")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(Color.orange)
                    .cornerRadius(12)
            }
            .padding(.top, 10)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.orange, lineWidth: 2)
                )
                .shadow(color: Color.orange.opacity(0.5), radius: 30)
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
}
