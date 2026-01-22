//
//  Achievements.swift
//  I'm Rich
//
//  Achievement system with categories, tracking, and rewards
//

import SwiftUI
import Combine

// MARK: - Achievement Category
enum AchievementCategory: String, Codable, CaseIterable {
    case milestones = "Milestones"
    case career = "Career"
    case investor = "Investor"
    case streak = "Streak"
    case social = "Social"
    case wisdom = "Wisdom"
    
    var icon: String {
        switch self {
        case .milestones: return "🏆"
        case .career: return "💼"
        case .investor: return "📈"
        case .streak: return "🔥"
        case .social: return "🤝"
        case .wisdom: return "🎓"
        }
    }
    
    var color: Color {
        switch self {
        case .milestones: return .yellow
        case .career: return .blue
        case .investor: return .green
        case .streak: return .orange
        case .social: return .purple
        case .wisdom: return .cyan
        }
    }
}

// MARK: - Achievement Reward
enum AchievementReward: Codable {
    case cash(Double)
    case statusPoints(Int)
    case themeUnlock(String)
    case multiplierBoost(Double, duration: TimeInterval)
    
    var description: String {
        switch self {
        case .cash(let amount):
            return "+$\(Int(amount))"
        case .statusPoints(let points):
            return "+\(points) Status"
        case .themeUnlock(let theme):
            return "Unlock \(theme) Theme"
        case .multiplierBoost(let mult, let duration):
            return "\(Int(mult))x boost for \(Int(duration/60))min"
        }
    }
}

// MARK: - Achievement Model
struct Achievement: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let reward: AchievementReward
    let isSecret: Bool
    var unlocked: Bool = false
    var unlockedAt: Date?
    
    // Condition check is done in AchievementManager
}

// MARK: - All Achievements
let allAchievements: [Achievement] = [
    // MILESTONES
    Achievement(id: "first_1k", name: "Getting Started", description: "Earn your first $1,000", icon: "💵", category: .milestones, reward: .cash(500), isSecret: false),
    Achievement(id: "first_10k", name: "Five Figures", description: "Earn $10,000 total", icon: "💰", category: .milestones, reward: .cash(2500), isSecret: false),
    Achievement(id: "first_100k", name: "Six Figures", description: "Earn $100,000 total", icon: "🏦", category: .milestones, reward: .statusPoints(50), isSecret: false),
    Achievement(id: "first_1m", name: "Millionaire", description: "Earn $1,000,000 total", icon: "💎", category: .milestones, reward: .themeUnlock("Gold Rush"), isSecret: false),
    Achievement(id: "first_10m", name: "Multi-Millionaire", description: "Earn $10,000,000 total", icon: "🌟", category: .milestones, reward: .statusPoints(200), isSecret: false),
    Achievement(id: "first_100m", name: "Mega Rich", description: "Earn $100,000,000 total", icon: "👑", category: .milestones, reward: .cash(5_000_000), isSecret: false),
    Achievement(id: "first_1b", name: "Billionaire Club", description: "Earn $1,000,000,000 total", icon: "🌍", category: .milestones, reward: .themeUnlock("Billionaire Black"), isSecret: false),
    
    // CAREER
    Achievement(id: "first_career", name: "Career Starter", description: "Choose your first career path", icon: "🎯", category: .career, reward: .cash(1000), isSecret: false),
    Achievement(id: "first_promotion", name: "Moving Up", description: "Get your first promotion", icon: "📈", category: .career, reward: .statusPoints(25), isSecret: false),
    Achievement(id: "mid_career", name: "Established", description: "Reach role level 4 in any career", icon: "💼", category: .career, reward: .cash(50000), isSecret: false),
    Achievement(id: "max_role", name: "Top of the Game", description: "Reach the highest role in a career", icon: "🏆", category: .career, reward: .statusPoints(500), isSecret: false),
    Achievement(id: "career_switcher", name: "Career Explorer", description: "Try all 4 career paths", icon: "🔄", category: .career, reward: .cash(100000), isSecret: true),
    
    // INVESTOR
    Achievement(id: "first_investment", name: "Baby's First Investment", description: "Make your first investment", icon: "🌱", category: .investor, reward: .cash(500), isSecret: false),
    Achievement(id: "diversified", name: "Diversified", description: "Invest in 5 different assets", icon: "🎨", category: .investor, reward: .statusPoints(50), isSecret: false),
    Achievement(id: "fully_diversified", name: "Portfolio Master", description: "Invest in 10 different assets", icon: "🎯", category: .investor, reward: .cash(500000), isSecret: false),
    Achievement(id: "big_investor", name: "Whale", description: "Have $10,000,000+ invested", icon: "🐋", category: .investor, reward: .statusPoints(200), isSecret: false),
    Achievement(id: "product_success", name: "Entrepreneur", description: "Launch a successful product", icon: "🚀", category: .investor, reward: .cash(250000), isSecret: false),
    Achievement(id: "product_master", name: "Serial Entrepreneur", description: "Launch 3 successful products", icon: "💡", category: .investor, reward: .statusPoints(300), isSecret: false),
    
    // STREAK
    Achievement(id: "streak_100", name: "Warming Up", description: "Reach a 100 tap streak", icon: "🔥", category: .streak, reward: .cash(1000), isSecret: false),
    Achievement(id: "streak_500", name: "On Fire", description: "Reach a 500 tap streak", icon: "🔥", category: .streak, reward: .cash(5000), isSecret: false),
    Achievement(id: "streak_1000", name: "Unstoppable", description: "Reach a 1,000 tap streak", icon: "💥", category: .streak, reward: .statusPoints(100), isSecret: false),
    Achievement(id: "streak_5000", name: "Legendary", description: "Reach a 5,000 tap streak", icon: "⚡", category: .streak, reward: .cash(100000), isSecret: false),
    Achievement(id: "streak_10000", name: "Mythical", description: "Reach a 10,000 tap streak", icon: "🌟", category: .streak, reward: .statusPoints(500), isSecret: true),
    Achievement(id: "tap_master", name: "Tap Master", description: "Reach 100,000 total taps", icon: "👆", category: .streak, reward: .cash(50000), isSecret: false),
    Achievement(id: "tap_legend", name: "Tap Legend", description: "Reach 1,000,000 total taps", icon: "🏅", category: .streak, reward: .statusPoints(1000), isSecret: true),
    
    // SOCIAL
    Achievement(id: "first_contact", name: "Networker", description: "Meet your first contact", icon: "🤝", category: .social, reward: .cash(2500), isSecret: false),
    Achievement(id: "contacts_5", name: "Well Connected", description: "Meet 5 contacts", icon: "📱", category: .social, reward: .statusPoints(50), isSecret: false),
    Achievement(id: "contacts_10", name: "Power Networker", description: "Meet 10 contacts", icon: "🌐", category: .social, reward: .cash(100000), isSecret: false),
    Achievement(id: "met_tim_cook", name: "Apple Insider", description: "Meet Tim Cook", icon: "🍎", category: .social, reward: .statusPoints(500), isSecret: false),
    Achievement(id: "met_elon", name: "To Mars!", description: "Meet Elon Musk", icon: "🚀", category: .social, reward: .cash(10_000_000), isSecret: false),
    Achievement(id: "met_president", name: "World Leader", description: "Meet the President", icon: "🏛️", category: .social, reward: .statusPoints(2000), isSecret: false),
    
    // WISDOM
    Achievement(id: "first_lesson", name: "Student", description: "Complete your first lesson", icon: "📖", category: .wisdom, reward: .cash(1000), isSecret: false),
    Achievement(id: "lessons_5", name: "Learner", description: "Complete 5 lessons", icon: "📚", category: .wisdom, reward: .statusPoints(50), isSecret: false),
    Achievement(id: "lessons_all", name: "Scholar", description: "Complete all lessons", icon: "🎓", category: .wisdom, reward: .cash(500000), isSecret: false),
    Achievement(id: "quiz_perfect", name: "Perfect Score", description: "Get 100% on a quiz", icon: "💯", category: .wisdom, reward: .statusPoints(25), isSecret: false),
    Achievement(id: "quiz_master", name: "Quiz Master", description: "Score 100% on 5 quizzes", icon: "🧠", category: .wisdom, reward: .cash(100000), isSecret: false),
    Achievement(id: "financial_literacy", name: "Financially Literate", description: "Reach 100 Financial Literacy score", icon: "🏆", category: .wisdom, reward: .statusPoints(200), isSecret: false)
]

// MARK: - Achievement Manager
class AchievementManager: ObservableObject {
    @Published var achievements: [Achievement] {
        didSet { save() }
    }
    @Published var recentUnlock: Achievement?
    @Published var showUnlockAnimation = false
    
    var unlockedCount: Int {
        achievements.filter { $0.unlocked }.count
    }
    
    var totalCount: Int {
        achievements.count
    }
    
    var unlockedByCategory: [AchievementCategory: [Achievement]] {
        Dictionary(grouping: achievements.filter { $0.unlocked }) { $0.category }
    }
    
    init() {
        if let data = UserDefaults.standard.data(forKey: "achievements"),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: data) {
            self.achievements = decoded
        } else {
            self.achievements = allAchievements
        }
    }
    
    func checkAchievements(game: GameState) {
        var newUnlocks: [Achievement] = []
        
        for i in 0..<achievements.count where !achievements[i].unlocked {
            if shouldUnlock(achievements[i], game: game) {
                achievements[i].unlocked = true
                achievements[i].unlockedAt = Date()
                newUnlocks.append(achievements[i])
                applyReward(achievements[i].reward, to: game)
            }
        }
        
        // Show the first new unlock (queue others if needed)
        if let first = newUnlocks.first {
            recentUnlock = first
            showUnlockAnimation = true
        }
    }
    
    private func shouldUnlock(_ achievement: Achievement, game: GameState) -> Bool {
        switch achievement.id {
        // Milestones
        case "first_1k": return game.totalEarned >= 1_000
        case "first_10k": return game.totalEarned >= 10_000
        case "first_100k": return game.totalEarned >= 100_000
        case "first_1m": return game.totalEarned >= 1_000_000
        case "first_10m": return game.totalEarned >= 10_000_000
        case "first_100m": return game.totalEarned >= 100_000_000
        case "first_1b": return game.totalEarned >= 1_000_000_000
            
        // Career
        case "first_career": return game.selectedCareer != nil
        case "first_promotion": return game.currentRoleIndex >= 1
        case "mid_career": return game.currentRoleIndex >= 3
        case "max_role": return game.currentRoleIndex >= 7
            
        // Investor
        case "first_investment": return game.investments.contains { $0.amountInvested > 0 }
        case "diversified": return game.investments.filter { $0.amountInvested > 0 }.count >= 5
        case "fully_diversified": return game.investments.filter { $0.amountInvested > 0 }.count >= 10
        case "big_investor": return game.investments.reduce(0) { $0 + $1.amountInvested } >= 10_000_000
        case "product_success": return game.products.contains { $0.successful }
        case "product_master": return game.products.filter { $0.successful }.count >= 3
            
        // Streak
        case "streak_100": return game.highestStreak >= 100
        case "streak_500": return game.highestStreak >= 500
        case "streak_1000": return game.highestStreak >= 1000
        case "streak_5000": return game.highestStreak >= 5000
        case "streak_10000": return game.highestStreak >= 10000
        case "tap_master": return game.totalTaps >= 100_000
        case "tap_legend": return game.totalTaps >= 1_000_000
            
        // Social
        case "first_contact": return game.contacts.contains { $0.hasMet }
        case "contacts_5": return game.contacts.filter { $0.hasMet }.count >= 5
        case "contacts_10": return game.contacts.filter { $0.hasMet }.count >= 10
        case "met_tim_cook": return game.contacts.first { $0.id == "timcook" }?.hasMet ?? false
        case "met_elon": return game.contacts.first { $0.id == "elon" }?.hasMet ?? false
        case "met_president": return game.contacts.first { $0.id == "president" }?.hasMet ?? false
            
        default: return false
        }
    }
    
    private func applyReward(_ reward: AchievementReward, to game: GameState) {
        switch reward {
        case .cash(let amount):
            game.cash += amount
            game.totalEarned += amount
        case .statusPoints(let points):
            game.statusPoints += points
        case .themeUnlock(let theme):
            ThemeManager.shared.unlockTheme(theme)
        case .multiplierBoost:
            // TODO: Implement temporary boost
            break
        }
    }
    
    func dismissUnlock() {
        withAnimation {
            showUnlockAnimation = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.recentUnlock = nil
        }
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(data, forKey: "achievements")
        }
    }
    
    func reset() {
        achievements = allAchievements
    }
}

// MARK: - Achievement Unlock View
struct AchievementUnlockView: View {
    let achievement: Achievement
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // Icon with glow
            ZStack {
                Circle()
                    .fill(achievement.category.color.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)
                
                Text(achievement.icon)
                    .font(.system(size: 60))
            }
            
            Text("ACHIEVEMENT UNLOCKED")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(achievement.category.color)
                .tracking(2)
            
            Text(achievement.name)
                .font(.system(size: 24, weight: .black))
                .foregroundColor(.white)
            
            Text(achievement.description)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            // Reward
            HStack {
                Text("Reward:")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Text(achievement.reward.description)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.4))
            }
            .padding(.top, 8)
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(achievement.category.color, lineWidth: 2)
                )
                .shadow(color: achievement.category.color.opacity(0.5), radius: 30)
        )
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                onDismiss()
            }
        }
        .onTapGesture {
            onDismiss()
        }
    }
}

// MARK: - Achievement Gallery View
struct AchievementGalleryView: View {
    @ObservedObject var manager: AchievementManager
    @Environment(\.dismiss) var dismiss
    
    let accentColor = Color(red: 0.4, green: 0.7, blue: 0.4)
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Achievements")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Text("\(manager.unlockedCount) / \(manager.totalCount) unlocked")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                
                // Categories
                ScrollView {
                    VStack(spacing: 24) {
                        ForEach(AchievementCategory.allCases, id: \.self) { category in
                            categorySection(category)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    func categorySection(_ category: AchievementCategory) -> some View {
        let categoryAchievements = manager.achievements.filter { $0.category == category }
        let unlocked = categoryAchievements.filter { $0.unlocked }.count
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(category.icon)
                    .font(.system(size: 20))
                Text(category.rawValue.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.gray)
                    .tracking(1.5)
                Spacer()
                Text("\(unlocked)/\(categoryAchievements.count)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(category.color)
            }
            
            ForEach(categoryAchievements) { achievement in
                achievementRow(achievement)
            }
        }
    }
    
    func achievementRow(_ achievement: Achievement) -> some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(achievement.unlocked ? achievement.category.color.opacity(0.2) : Color.white.opacity(0.05))
                    .frame(width: 44, height: 44)
                
                if achievement.unlocked {
                    Text(achievement.icon)
                        .font(.system(size: 24))
                } else if achievement.isSecret {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.gray)
                } else {
                    Text(achievement.icon)
                        .font(.system(size: 24))
                        .opacity(0.3)
                }
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.isSecret && !achievement.unlocked ? "???" : achievement.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(achievement.unlocked ? .white : .gray)
                
                Text(achievement.isSecret && !achievement.unlocked ? "Secret achievement" : achievement.description)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Checkmark or reward
            if achievement.unlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(achievement.category.color)
            } else {
                Text(achievement.reward.description)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(accentColor.opacity(0.7))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(achievement.unlocked ? achievement.category.color.opacity(0.1) : Color.white.opacity(0.03))
        )
    }
}
