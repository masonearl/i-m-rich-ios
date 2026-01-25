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
    // MILESTONES - Comprehensive wealth progression
    // Thousands
    Achievement(id: "nw_1k", name: "First Thousand", description: "Reach $1,000 net worth", icon: "💵", category: .milestones, reward: .cash(100), isSecret: false),
    Achievement(id: "nw_5k", name: "Getting Serious", description: "Reach $5,000 net worth", icon: "💵", category: .milestones, reward: .cash(500), isSecret: false),
    Achievement(id: "nw_10k", name: "Five Figures", description: "Reach $10,000 net worth", icon: "💰", category: .milestones, reward: .cash(1000), isSecret: false),
    Achievement(id: "nw_20k", name: "Building Momentum", description: "Reach $20,000 net worth", icon: "💰", category: .milestones, reward: .cash(2000), isSecret: false),
    Achievement(id: "nw_50k", name: "Halfway to Six Figures", description: "Reach $50,000 net worth", icon: "💰", category: .milestones, reward: .statusPoints(25), isSecret: false),
    
    // Hundred Thousands
    Achievement(id: "nw_100k", name: "Six Figures", description: "Reach $100,000 net worth", icon: "🏦", category: .milestones, reward: .statusPoints(50), isSecret: false),
    Achievement(id: "nw_200k", name: "Double Six Figures", description: "Reach $200,000 net worth", icon: "🏦", category: .milestones, reward: .cash(10000), isSecret: false),
    Achievement(id: "nw_300k", name: "Comfortable", description: "Reach $300,000 net worth", icon: "🏦", category: .milestones, reward: .statusPoints(75), isSecret: false),
    Achievement(id: "nw_500k", name: "Half Millionaire", description: "Reach $500,000 net worth", icon: "💎", category: .milestones, reward: .cash(25000), isSecret: false),
    
    // Millions
    Achievement(id: "nw_1m", name: "Millionaire", description: "Reach $1,000,000 net worth", icon: "💎", category: .milestones, reward: .themeUnlock("Gold Rush"), isSecret: false),
    Achievement(id: "nw_2m", name: "Double Millionaire", description: "Reach $2,000,000 net worth", icon: "💎", category: .milestones, reward: .cash(100000), isSecret: false),
    Achievement(id: "nw_3m", name: "Triple Millionaire", description: "Reach $3,000,000 net worth", icon: "💎", category: .milestones, reward: .statusPoints(100), isSecret: false),
    Achievement(id: "nw_5m", name: "High Net Worth", description: "Reach $5,000,000 net worth", icon: "🌟", category: .milestones, reward: .cash(250000), isSecret: false),
    Achievement(id: "nw_10m", name: "Multi-Millionaire", description: "Reach $10,000,000 net worth", icon: "🌟", category: .milestones, reward: .statusPoints(200), isSecret: false),
    Achievement(id: "nw_20m", name: "Decamillionaire", description: "Reach $20,000,000 net worth", icon: "🌟", category: .milestones, reward: .cash(1000000), isSecret: false),
    Achievement(id: "nw_50m", name: "Ultra High Net Worth", description: "Reach $50,000,000 net worth", icon: "👑", category: .milestones, reward: .statusPoints(300), isSecret: false),
    
    // Hundred Millions
    Achievement(id: "nw_100m", name: "Centimillionaire", description: "Reach $100,000,000 net worth", icon: "👑", category: .milestones, reward: .cash(5000000), isSecret: false),
    Achievement(id: "nw_200m", name: "Seriously Wealthy", description: "Reach $200,000,000 net worth", icon: "👑", category: .milestones, reward: .statusPoints(400), isSecret: false),
    Achievement(id: "nw_300m", name: "Mogul Status", description: "Reach $300,000,000 net worth", icon: "👑", category: .milestones, reward: .cash(15000000), isSecret: false),
    Achievement(id: "nw_500m", name: "Half Billionaire", description: "Reach $500,000,000 net worth", icon: "🌍", category: .milestones, reward: .statusPoints(500), isSecret: false),
    
    // Billions
    Achievement(id: "nw_1b", name: "Billionaire", description: "Reach $1,000,000,000 net worth", icon: "🌍", category: .milestones, reward: .themeUnlock("Billionaire Black"), isSecret: false),
    Achievement(id: "nw_2b", name: "Double Billionaire", description: "Reach $2,000,000,000 net worth", icon: "🌍", category: .milestones, reward: .cash(100000000), isSecret: false),
    Achievement(id: "nw_5b", name: "Mega Billionaire", description: "Reach $5,000,000,000 net worth", icon: "🌍", category: .milestones, reward: .statusPoints(750), isSecret: false),
    Achievement(id: "nw_10b", name: "Decabillionaire", description: "Reach $10,000,000,000 net worth", icon: "🚀", category: .milestones, reward: .cash(500000000), isSecret: false),
    Achievement(id: "nw_20b", name: "Titan", description: "Reach $20,000,000,000 net worth", icon: "🚀", category: .milestones, reward: .statusPoints(1000), isSecret: false),
    Achievement(id: "nw_50b", name: "Forbes Elite", description: "Reach $50,000,000,000 net worth", icon: "🚀", category: .milestones, reward: .cash(2500000000), isSecret: false),
    
    // Hundred Billions
    Achievement(id: "nw_100b", name: "Centibillionaire", description: "Reach $100,000,000,000 net worth", icon: "⭐", category: .milestones, reward: .themeUnlock("Platinum"), isSecret: false),
    Achievement(id: "nw_200b", name: "World's Richest", description: "Reach $200,000,000,000 net worth", icon: "⭐", category: .milestones, reward: .statusPoints(2000), isSecret: false),
    Achievement(id: "nw_300b", name: "Beyond Bezos", description: "Reach $300,000,000,000 net worth", icon: "⭐", category: .milestones, reward: .cash(15000000000), isSecret: false),
    Achievement(id: "nw_500b", name: "Half Trillionaire", description: "Reach $500,000,000,000 net worth", icon: "💫", category: .milestones, reward: .statusPoints(3000), isSecret: false),
    
    // Trillions
    Achievement(id: "nw_1t", name: "TRILLIONAIRE", description: "Reach $1,000,000,000,000 net worth", icon: "🏆", category: .milestones, reward: .themeUnlock("Trillionaire Diamond"), isSecret: false),
    Achievement(id: "nw_2t", name: "Double Trillionaire", description: "Reach $2,000,000,000,000 net worth", icon: "🏆", category: .milestones, reward: .statusPoints(5000), isSecret: false),
    Achievement(id: "nw_5t", name: "Economy Breaker", description: "Reach $5,000,000,000,000 net worth", icon: "🏆", category: .milestones, reward: .cash(250000000000), isSecret: false),
    Achievement(id: "nw_10t", name: "Nation's GDP", description: "Reach $10,000,000,000,000 net worth", icon: "🌐", category: .milestones, reward: .statusPoints(10000), isSecret: false),
    
    // Legacy milestones (keeping old IDs for backwards compatibility)
    Achievement(id: "first_1k", name: "First Earnings", description: "Earn your first $1,000", icon: "📈", category: .milestones, reward: .cash(100), isSecret: false),
    Achievement(id: "first_1m", name: "Million Earned", description: "Earn $1,000,000 lifetime", icon: "📈", category: .milestones, reward: .statusPoints(50), isSecret: false),
    Achievement(id: "first_1b", name: "Billion Earned", description: "Earn $1,000,000,000 lifetime", icon: "📈", category: .milestones, reward: .statusPoints(500), isSecret: false),
    
    // CAREER
    Achievement(id: "first_career", name: "Career Starter", description: "Choose your first career path", icon: "🎯", category: .career, reward: .cash(1000), isSecret: false),
    Achievement(id: "first_promotion", name: "Moving Up", description: "Get your first promotion", icon: "📈", category: .career, reward: .statusPoints(25), isSecret: false),
    Achievement(id: "mid_career", name: "Established", description: "Reach role level 4 in any career", icon: "💼", category: .career, reward: .statusPoints(75), isSecret: false),
    Achievement(id: "max_role", name: "Top of the Game", description: "Reach the highest role in a career", icon: "🏆", category: .career, reward: .statusPoints(500), isSecret: false),
    Achievement(id: "career_switcher", name: "Career Explorer", description: "Try all 4 career paths", icon: "🔄", category: .career, reward: .statusPoints(200), isSecret: true),
    
    // INVESTOR
    Achievement(id: "first_investment", name: "Baby's First Investment", description: "Make your first investment", icon: "🌱", category: .investor, reward: .cash(500), isSecret: false),
    Achievement(id: "diversified", name: "Diversified", description: "Invest in 5 different assets", icon: "🎨", category: .investor, reward: .statusPoints(50), isSecret: false),
    Achievement(id: "fully_diversified", name: "Portfolio Master", description: "Invest in 10 different assets", icon: "🎯", category: .investor, reward: .statusPoints(100), isSecret: false),
    Achievement(id: "big_investor", name: "Whale", description: "Have $10,000,000+ invested", icon: "🐋", category: .investor, reward: .statusPoints(200), isSecret: false),
    Achievement(id: "product_success", name: "Entrepreneur", description: "Launch a successful product", icon: "🚀", category: .investor, reward: .statusPoints(75), isSecret: false),
    Achievement(id: "product_master", name: "Serial Entrepreneur", description: "Launch 3 successful products", icon: "💡", category: .investor, reward: .statusPoints(300), isSecret: false),
    
    // STREAK (Consecutive Taps)
    Achievement(id: "streak_100", name: "Warming Up", description: "Reach a 100 tap streak", icon: "🔥", category: .streak, reward: .cash(1000), isSecret: false),
    Achievement(id: "streak_500", name: "On Fire", description: "Reach a 500 tap streak", icon: "🔥", category: .streak, reward: .cash(5000), isSecret: false),
    Achievement(id: "streak_1000", name: "Unstoppable", description: "Reach a 1,000 tap streak", icon: "💥", category: .streak, reward: .statusPoints(100), isSecret: false),
    Achievement(id: "streak_5000", name: "Legendary", description: "Reach a 5,000 tap streak", icon: "⚡", category: .streak, reward: .statusPoints(150), isSecret: false),
    Achievement(id: "streak_10000", name: "Mythical", description: "Reach a 10,000 tap streak", icon: "🌟", category: .streak, reward: .statusPoints(500), isSecret: true),
    
    // HUSTLE (Total Taps - CEO Identity)
    Achievement(id: "hustle_100", name: "First Day Grind", description: "100 total taps - The journey begins", icon: "💪", category: .streak, reward: .cash(500), isSecret: false),
    Achievement(id: "hustle_500", name: "Week One Warrior", description: "500 total taps - Building momentum", icon: "💪", category: .streak, reward: .cash(2500), isSecret: false),
    Achievement(id: "hustle_1000", name: "Relentless", description: "1,000 total taps - You don't quit", icon: "🏃", category: .streak, reward: .cash(5000), isSecret: false),
    Achievement(id: "hustle_5000", name: "The Grinder", description: "5,000 total taps - Outworking everyone", icon: "🏃", category: .streak, reward: .statusPoints(50), isSecret: false),
    Achievement(id: "hustle_10000", name: "Obsessed", description: "10,000 total taps - Sleep is optional", icon: "😤", category: .streak, reward: .cash(25000), isSecret: false),
    Achievement(id: "hustle_25000", name: "Built Different", description: "25,000 total taps - They don't understand", icon: "😤", category: .streak, reward: .statusPoints(100), isSecret: false),
    Achievement(id: "hustle_50000", name: "CEO Mentality", description: "50,000 total taps - Whatever it takes", icon: "👔", category: .streak, reward: .statusPoints(200), isSecret: false),
    Achievement(id: "tap_master", name: "Legendary Hustle", description: "100,000 total taps - The grind never stops", icon: "👑", category: .streak, reward: .statusPoints(500), isSecret: false),
    Achievement(id: "hustle_500k", name: "Empire Builder", description: "500,000 total taps - Built from nothing", icon: "🏰", category: .streak, reward: .statusPoints(500), isSecret: false),
    Achievement(id: "tap_legend", name: "Mogul Status", description: "1,000,000 total taps - The stuff of legends", icon: "🏆", category: .streak, reward: .themeUnlock("Mogul Gold"), isSecret: true),
    
    // SOCIAL
    Achievement(id: "first_contact", name: "Networker", description: "Meet your first contact", icon: "🤝", category: .social, reward: .cash(2500), isSecret: false),
    Achievement(id: "contacts_5", name: "Well Connected", description: "Meet 5 contacts", icon: "📱", category: .social, reward: .statusPoints(50), isSecret: false),
    Achievement(id: "contacts_10", name: "Power Networker", description: "Meet 10 contacts", icon: "🌐", category: .social, reward: .statusPoints(100), isSecret: false),
    Achievement(id: "met_tim_cook", name: "Apple Insider", description: "Meet Tim Cook", icon: "🍎", category: .social, reward: .statusPoints(500), isSecret: false),
    Achievement(id: "met_satya", name: "Azure Alliance", description: "Meet Satya Nadella", icon: "🪟", category: .social, reward: .statusPoints(500), isSecret: false),
    Achievement(id: "met_sundar", name: "Search Giant", description: "Meet Sundar Pichai", icon: "🔍", category: .social, reward: .statusPoints(500), isSecret: false),
    Achievement(id: "met_sam_altman", name: "AI Pioneer", description: "Meet Sam Altman", icon: "🤖", category: .social, reward: .statusPoints(500), isSecret: false),
    Achievement(id: "met_demis", name: "Mind Merger", description: "Meet Demis Hassabis", icon: "🧠", category: .social, reward: .statusPoints(500), isSecret: false),
    Achievement(id: "met_jensen", name: "GPU Baron", description: "Meet Jensen Huang", icon: "🎮", category: .social, reward: .statusPoints(600), isSecret: false),
    Achievement(id: "met_elon", name: "To Mars!", description: "Meet Elon Musk", icon: "🚀", category: .social, reward: .statusPoints(1000), isSecret: false),
    Achievement(id: "met_warren", name: "Oracle's Wisdom", description: "Meet Warren Buffett", icon: "📈", category: .social, reward: .statusPoints(1000), isSecret: false),
    Achievement(id: "met_jamie", name: "Banking Titan", description: "Meet Jamie Dimon", icon: "🏦", category: .social, reward: .statusPoints(500), isSecret: false),
    Achievement(id: "met_ray", name: "Principles", description: "Meet Ray Dalio", icon: "🌊", category: .social, reward: .statusPoints(750), isSecret: false),
    Achievement(id: "met_mrbeast", name: "Content King", description: "Meet MrBeast", icon: "📱", category: .social, reward: .statusPoints(400), isSecret: false),
    Achievement(id: "met_president", name: "World Leader", description: "Meet the President", icon: "🏛️", category: .social, reward: .statusPoints(2000), isSecret: false),
    
    // Partnership Achievements
    Achievement(id: "first_partnership", name: "Strategic Partner", description: "Form your first major partnership", icon: "🤝", category: .social, reward: .statusPoints(300), isSecret: false),
    Achievement(id: "ai_alliance", name: "AI Alliance", description: "Partner with an AI company", icon: "🤖", category: .social, reward: .statusPoints(500), isSecret: false),
    Achievement(id: "triple_partnership", name: "Power Broker", description: "Have 3 active partnerships", icon: "⚡", category: .social, reward: .statusPoints(1000), isSecret: true),
    
    // WISDOM
    Achievement(id: "first_lesson", name: "Student", description: "Complete your first lesson", icon: "📖", category: .wisdom, reward: .cash(1000), isSecret: false),
    Achievement(id: "lessons_5", name: "Learner", description: "Complete 5 lessons", icon: "📚", category: .wisdom, reward: .statusPoints(50), isSecret: false),
    Achievement(id: "lessons_all", name: "Scholar", description: "Complete all lessons", icon: "🎓", category: .wisdom, reward: .statusPoints(300), isSecret: false),
    Achievement(id: "quiz_perfect", name: "Perfect Score", description: "Get 100% on a quiz", icon: "💯", category: .wisdom, reward: .statusPoints(25), isSecret: false),
    Achievement(id: "quiz_master", name: "Quiz Master", description: "Score 100% on 5 quizzes", icon: "🧠", category: .wisdom, reward: .statusPoints(100), isSecret: false),
    Achievement(id: "financial_literacy", name: "Financially Literate", description: "Reach 100 Financial Literacy score", icon: "🏆", category: .wisdom, reward: .statusPoints(200), isSecret: false)
]

// MARK: - Achievement Manager
class AchievementManager: ObservableObject {
    static let shared = AchievementManager()
    
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
    
    // MARK: - Next Milestone Tracking
    
    /// All wealth milestone thresholds in order
    static let wealthMilestones: [(id: String, amount: Double, name: String)] = [
        ("nw_1k", 1_000, "$1K"),
        ("nw_5k", 5_000, "$5K"),
        ("nw_10k", 10_000, "$10K"),
        ("nw_20k", 20_000, "$20K"),
        ("nw_50k", 50_000, "$50K"),
        ("nw_100k", 100_000, "$100K"),
        ("nw_200k", 200_000, "$200K"),
        ("nw_300k", 300_000, "$300K"),
        ("nw_500k", 500_000, "$500K"),
        ("nw_1m", 1_000_000, "$1M"),
        ("nw_2m", 2_000_000, "$2M"),
        ("nw_3m", 3_000_000, "$3M"),
        ("nw_5m", 5_000_000, "$5M"),
        ("nw_10m", 10_000_000, "$10M"),
        ("nw_20m", 20_000_000, "$20M"),
        ("nw_50m", 50_000_000, "$50M"),
        ("nw_100m", 100_000_000, "$100M"),
        ("nw_200m", 200_000_000, "$200M"),
        ("nw_300m", 300_000_000, "$300M"),
        ("nw_500m", 500_000_000, "$500M"),
        ("nw_1b", 1_000_000_000, "$1B"),
        ("nw_2b", 2_000_000_000, "$2B"),
        ("nw_5b", 5_000_000_000, "$5B"),
        ("nw_10b", 10_000_000_000, "$10B"),
        ("nw_20b", 20_000_000_000, "$20B"),
        ("nw_50b", 50_000_000_000, "$50B"),
        ("nw_100b", 100_000_000_000, "$100B"),
        ("nw_200b", 200_000_000_000, "$200B"),
        ("nw_300b", 300_000_000_000, "$300B"),
        ("nw_500b", 500_000_000_000, "$500B"),
        ("nw_1t", 1_000_000_000_000, "$1T"),
        ("nw_2t", 2_000_000_000_000, "$2T"),
        ("nw_5t", 5_000_000_000_000, "$5T"),
        ("nw_10t", 10_000_000_000_000, "$10T")
    ]
    
    /// Get the next wealth milestone for the player
    func nextMilestone(currentNetWorth: Double) -> (name: String, target: Double, progress: Double)? {
        for milestone in Self.wealthMilestones {
            if currentNetWorth < milestone.amount {
                // Find the previous milestone to calculate progress
                let previousIndex = Self.wealthMilestones.firstIndex { $0.id == milestone.id }.map { $0 - 1 } ?? -1
                let previousAmount = previousIndex >= 0 ? Self.wealthMilestones[previousIndex].amount : 0
                let progress = (currentNetWorth - previousAmount) / (milestone.amount - previousAmount)
                return (milestone.name, milestone.amount, max(0, min(1, progress)))
            }
        }
        return nil // Already at max milestone
    }
    
    /// Get the achievement for a milestone ID
    func milestoneAchievement(id: String) -> Achievement? {
        achievements.first { $0.id == id }
    }
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: "achievements"),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: data) {
            self.achievements = decoded
        } else {
            self.achievements = allAchievements
        }
    }
    
    func restoreAchievement(_ achievementId: String) {
        guard let index = achievements.firstIndex(where: { $0.id == achievementId }) else { return }
        achievements[index].unlocked = true
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
        // Net Worth Milestones - Thousands
        case "nw_1k": return game.netWorth >= 1_000
        case "nw_5k": return game.netWorth >= 5_000
        case "nw_10k": return game.netWorth >= 10_000
        case "nw_20k": return game.netWorth >= 20_000
        case "nw_50k": return game.netWorth >= 50_000
        
        // Net Worth Milestones - Hundred Thousands
        case "nw_100k": return game.netWorth >= 100_000
        case "nw_200k": return game.netWorth >= 200_000
        case "nw_300k": return game.netWorth >= 300_000
        case "nw_500k": return game.netWorth >= 500_000
        
        // Net Worth Milestones - Millions
        case "nw_1m": return game.netWorth >= 1_000_000
        case "nw_2m": return game.netWorth >= 2_000_000
        case "nw_3m": return game.netWorth >= 3_000_000
        case "nw_5m": return game.netWorth >= 5_000_000
        case "nw_10m": return game.netWorth >= 10_000_000
        case "nw_20m": return game.netWorth >= 20_000_000
        case "nw_50m": return game.netWorth >= 50_000_000
        
        // Net Worth Milestones - Hundred Millions
        case "nw_100m": return game.netWorth >= 100_000_000
        case "nw_200m": return game.netWorth >= 200_000_000
        case "nw_300m": return game.netWorth >= 300_000_000
        case "nw_500m": return game.netWorth >= 500_000_000
        
        // Net Worth Milestones - Billions
        case "nw_1b": return game.netWorth >= 1_000_000_000
        case "nw_2b": return game.netWorth >= 2_000_000_000
        case "nw_5b": return game.netWorth >= 5_000_000_000
        case "nw_10b": return game.netWorth >= 10_000_000_000
        case "nw_20b": return game.netWorth >= 20_000_000_000
        case "nw_50b": return game.netWorth >= 50_000_000_000
        
        // Net Worth Milestones - Hundred Billions
        case "nw_100b": return game.netWorth >= 100_000_000_000
        case "nw_200b": return game.netWorth >= 200_000_000_000
        case "nw_300b": return game.netWorth >= 300_000_000_000
        case "nw_500b": return game.netWorth >= 500_000_000_000
        
        // Net Worth Milestones - Trillions
        case "nw_1t": return game.netWorth >= 1_000_000_000_000
        case "nw_2t": return game.netWorth >= 2_000_000_000_000
        case "nw_5t": return game.netWorth >= 5_000_000_000_000
        case "nw_10t": return game.netWorth >= 10_000_000_000_000
        
        // Legacy earning milestones
        case "first_1k": return game.totalEarned >= 1_000
        case "first_1m": return game.totalEarned >= 1_000_000
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
            
        // Streak (Consecutive)
        case "streak_100": return game.highestStreak >= 100
        case "streak_500": return game.highestStreak >= 500
        case "streak_1000": return game.highestStreak >= 1000
        case "streak_5000": return game.highestStreak >= 5000
        case "streak_10000": return game.highestStreak >= 10000
        
        // Hustle (Total Taps)
        case "hustle_100": return game.totalTaps >= 100
        case "hustle_500": return game.totalTaps >= 500
        case "hustle_1000": return game.totalTaps >= 1_000
        case "hustle_5000": return game.totalTaps >= 5_000
        case "hustle_10000": return game.totalTaps >= 10_000
        case "hustle_25000": return game.totalTaps >= 25_000
        case "hustle_50000": return game.totalTaps >= 50_000
        case "tap_master": return game.totalTaps >= 100_000
        case "hustle_500k": return game.totalTaps >= 500_000
        case "tap_legend": return game.totalTaps >= 1_000_000
            
        // Social
        case "first_contact": return game.contacts.contains { $0.hasMet }
        case "contacts_5": return game.contacts.filter { $0.hasMet }.count >= 5
        case "contacts_10": return game.contacts.filter { $0.hasMet }.count >= 10
        case "met_tim_cook": return game.contacts.first { $0.id == "timcook" }?.hasMet ?? false
        case "met_satya": return game.contacts.first { $0.id == "satya" }?.hasMet ?? false
        case "met_sundar": return game.contacts.first { $0.id == "sundar" }?.hasMet ?? false
        case "met_sam_altman": return game.contacts.first { $0.id == "sam_altman" }?.hasMet ?? false
        case "met_demis": return game.contacts.first { $0.id == "demis_hassabis" }?.hasMet ?? false
        case "met_jensen": return game.contacts.first { $0.id == "jensen_huang" }?.hasMet ?? false
        case "met_elon": return game.contacts.first { $0.id == "elon" }?.hasMet ?? false
        case "met_warren": return game.contacts.first { $0.id == "warren_buffett" }?.hasMet ?? false
        case "met_jamie": return game.contacts.first { $0.id == "jamie_dimon" }?.hasMet ?? false
        case "met_ray": return game.contacts.first { $0.id == "ray_dalio" }?.hasMet ?? false
        case "met_mrbeast": return game.contacts.first { $0.id == "mrBeast" }?.hasMet ?? false
        case "met_president": return game.contacts.first { $0.id == "president" }?.hasMet ?? false
        
        // Partnership achievements - checked via PartnershipManager
        case "first_partnership": return PartnershipManager.shared.activePartnerships.count >= 1
        case "ai_alliance": return PartnershipManager.shared.hasAIPartnership
        case "triple_partnership": return PartnershipManager.shared.activePartnerships.count >= 3
            
        default: return false
        }
    }
    
    private func applyReward(_ reward: AchievementReward, to game: GameState) {
        switch reward {
        case .cash(let amount):
            // Scale cash rewards to current wealth level
            let scaledAmount = game.scaleReward(amount)
            game.cash += scaledAmount
            game.totalEarned += scaledAmount
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
