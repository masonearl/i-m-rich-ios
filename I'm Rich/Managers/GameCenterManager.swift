//
//  GameCenterManager.swift
//  I'm Rich
//
//  Game Center integration for leaderboards and achievements
//

import GameKit
import SwiftUI
import Combine

// MARK: - Game Center Manager
class GameCenterManager: NSObject, ObservableObject {
    static let shared = GameCenterManager()
    
    @Published var isAuthenticated = false
    @Published var showGameCenter = false
    @Published var gameCenterError: String? = nil
    
    private var localPlayer: GKLocalPlayer { GKLocalPlayer.local }
    
    // MARK: - Leaderboard IDs (must match App Store Connect)
    struct LeaderboardID {
        static let highestNetWorth = "com.imrich.leaderboard.networth"
        static let fastestBillionaire = "com.imrich.leaderboard.fastbillion"
        static let mostPrestigePoints = "com.imrich.leaderboard.prestige"
        static let highestCompanyValuation = "com.imrich.leaderboard.company"
        static let mostContacts = "com.imrich.leaderboard.contacts"
    }
    
    // MARK: - Achievement IDs (must match App Store Connect)
    struct AchievementID {
        // Wealth Milestones
        static let first100K = "com.imrich.achievement.100k"
        static let firstMillion = "com.imrich.achievement.million"
        static let first10Million = "com.imrich.achievement.10million"
        static let first100Million = "com.imrich.achievement.100million"
        static let firstBillion = "com.imrich.achievement.billion"
        static let first100Billion = "com.imrich.achievement.100billion"
        
        // Career
        static let topOfCareer = "com.imrich.achievement.topcareer"
        static let allCareers = "com.imrich.achievement.allcareers"
        
        // Company
        static let foundCompany = "com.imrich.achievement.foundcompany"
        static let hire50Employees = "com.imrich.achievement.50employees"
        static let companyValuation100M = "com.imrich.achievement.company100m"
        static let allDepartments = "com.imrich.achievement.alldepts"
        
        // Contacts
        static let meet10Contacts = "com.imrich.achievement.10contacts"
        static let meet25Contacts = "com.imrich.achievement.25contacts"
        static let meet50Contacts = "com.imrich.achievement.50contacts"
        static let meet100Contacts = "com.imrich.achievement.100contacts"
        static let meetBillionaire = "com.imrich.achievement.billionairecontact"
        
        // Prestige
        static let firstPrestige = "com.imrich.achievement.prestige1"
        static let fivePrestige = "com.imrich.achievement.prestige5"
        static let tenPrestige = "com.imrich.achievement.prestige10"
        
        // Strategy
        static let firstSynergy = "com.imrich.achievement.synergy"
        static let allFactions50 = "com.imrich.achievement.allfactions"
        static let researchComplete = "com.imrich.achievement.research"
        
        // Fun/Hidden
        static let meetSBF = "com.imrich.achievement.sbf"
        static let billionBefore30 = "com.imrich.achievement.youngbillionaire"
        static let surviveCrash = "com.imrich.achievement.crashsurvivor"
    }
    
    override private init() {
        super.init()
    }
    
    // MARK: - Authentication
    
    func authenticatePlayer() {
        localPlayer.authenticateHandler = { [weak self] viewController, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.gameCenterError = error.localizedDescription
                    self?.isAuthenticated = false
                    print("Game Center auth error: \(error.localizedDescription)")
                    return
                }
                
                if viewController != nil {
                    // Present the authentication view controller if needed
                    // This is handled by the system on iOS
                    return
                }
                
                // Player is authenticated
                self?.isAuthenticated = self?.localPlayer.isAuthenticated ?? false
                if self?.isAuthenticated == true {
                    print("Game Center authenticated: \(self?.localPlayer.displayName ?? "Unknown")")
                    // Load any cached achievements
                    self?.loadAchievements()
                }
            }
        }
    }
    
    // MARK: - Leaderboards
    
    func submitScore(leaderboardID: String, score: Int64) {
        guard isAuthenticated else { return }
        
        GKLeaderboard.submitScore(
            Int(score),
            context: 0,
            player: localPlayer,
            leaderboardIDs: [leaderboardID]
        ) { error in
            if let error = error {
                print("Failed to submit score: \(error.localizedDescription)")
            } else {
                print("Score submitted to \(leaderboardID): \(score)")
            }
        }
    }
    
    func submitNetWorth(_ netWorth: Double) {
        // Submit as cents for precision
        let score = Int64(netWorth * 100)
        submitScore(leaderboardID: LeaderboardID.highestNetWorth, score: score)
    }
    
    func submitFastestBillionaire(years: Int) {
        // Lower is better, so we submit as negative or use inverse
        // Game Center sorts descending by default, so submit as large negative
        let score = Int64(10000 - years)  // Max reasonable years minus actual
        submitScore(leaderboardID: LeaderboardID.fastestBillionaire, score: score)
    }
    
    func submitPrestigePoints(_ points: Int) {
        submitScore(leaderboardID: LeaderboardID.mostPrestigePoints, score: Int64(points))
    }
    
    func submitCompanyValuation(_ valuation: Double) {
        let score = Int64(valuation / 1000)  // In thousands to avoid overflow
        submitScore(leaderboardID: LeaderboardID.highestCompanyValuation, score: score)
    }
    
    func submitContactsMet(_ count: Int) {
        submitScore(leaderboardID: LeaderboardID.mostContacts, score: Int64(count))
    }
    
    // MARK: - Achievements
    
    private var reportedAchievements: Set<String> = []
    
    private func loadAchievements() {
        GKAchievement.loadAchievements { [weak self] achievements, error in
            if let achievements = achievements {
                for achievement in achievements where achievement.isCompleted {
                    self?.reportedAchievements.insert(achievement.identifier)
                }
            }
        }
    }
    
    func reportAchievement(identifier: String, percentComplete: Double = 100.0) {
        guard isAuthenticated else { return }
        guard !reportedAchievements.contains(identifier) else { return }
        
        let achievement = GKAchievement(identifier: identifier)
        achievement.percentComplete = percentComplete
        achievement.showsCompletionBanner = true
        
        GKAchievement.report([achievement]) { [weak self] error in
            if let error = error {
                print("Failed to report achievement: \(error.localizedDescription)")
            } else {
                print("Achievement reported: \(identifier)")
                self?.reportedAchievements.insert(identifier)
            }
        }
    }
    
    // MARK: - Check and Report Achievements
    
    func checkAchievements(game: GameState) {
        guard isAuthenticated else { return }
        
        let netWorth = game.netWorth
        let contactsMet = game.contacts.filter { $0.hasMet }.count
        let prestige = PrestigeManager.shared.state.livesLived
        
        // Wealth Milestones
        if netWorth >= 100_000 {
            reportAchievement(identifier: AchievementID.first100K)
        }
        if netWorth >= 1_000_000 {
            reportAchievement(identifier: AchievementID.firstMillion)
        }
        if netWorth >= 10_000_000 {
            reportAchievement(identifier: AchievementID.first10Million)
        }
        if netWorth >= 100_000_000 {
            reportAchievement(identifier: AchievementID.first100Million)
        }
        if netWorth >= 1_000_000_000 {
            reportAchievement(identifier: AchievementID.firstBillion)
            
            // Check for fast billionaire
            let years = LifeCycleManager.shared.gameYearsPassed
            submitFastestBillionaire(years: years)
            
            // Check for young billionaire
            if LifeCycleManager.shared.currentAge < 30 {
                reportAchievement(identifier: AchievementID.billionBefore30)
            }
        }
        if netWorth >= 100_000_000_000 {
            reportAchievement(identifier: AchievementID.first100Billion)
        }
        
        // Contacts
        if contactsMet >= 10 {
            reportAchievement(identifier: AchievementID.meet10Contacts)
        }
        if contactsMet >= 25 {
            reportAchievement(identifier: AchievementID.meet25Contacts)
        }
        if contactsMet >= 50 {
            reportAchievement(identifier: AchievementID.meet50Contacts)
        }
        if contactsMet >= 100 {
            reportAchievement(identifier: AchievementID.meet100Contacts)
        }
        
        // Check for billionaire contact
        let billionaireContacts = ["buffett", "elon", "bezos", "timcook", "zuck", "gates"]
        for contact in game.contacts where contact.hasMet && billionaireContacts.contains(contact.id) {
            reportAchievement(identifier: AchievementID.meetBillionaire)
            break
        }
        
        // Check for SBF (risky/hidden achievement)
        if game.contacts.first(where: { $0.id == "sbf" })?.hasMet == true {
            reportAchievement(identifier: AchievementID.meetSBF)
        }
        
        // Company
        if CompanyManager.shared.state.founded {
            reportAchievement(identifier: AchievementID.foundCompany)
        }
        if CompanyManager.shared.state.totalEmployees >= 50 {
            reportAchievement(identifier: AchievementID.hire50Employees)
        }
        if CompanyManager.shared.state.companyValuation >= 100_000_000 {
            reportAchievement(identifier: AchievementID.companyValuation100M)
        }
        
        // All departments
        let hasAllDepts = Department.allCases.allSatisfy {
            CompanyManager.shared.getDepartmentCount($0) >= 1
        }
        if hasAllDepts {
            reportAchievement(identifier: AchievementID.allDepartments)
        }
        
        // Prestige
        if prestige >= 1 {
            reportAchievement(identifier: AchievementID.firstPrestige)
        }
        if prestige >= 5 {
            reportAchievement(identifier: AchievementID.fivePrestige)
        }
        if prestige >= 10 {
            reportAchievement(identifier: AchievementID.tenPrestige)
        }
        
        // Synergies
        if !SynergyManager.shared.activeSynergies.isEmpty {
            reportAchievement(identifier: AchievementID.firstSynergy)
        }
        
        // All factions at 50+
        let allFactions50 = Faction.allCases.allSatisfy {
            FactionManager.shared.reputation[$0] >= 50
        }
        if allFactions50 {
            reportAchievement(identifier: AchievementID.allFactions50)
        }
        
        // Submit leaderboard scores
        submitNetWorth(netWorth)
        submitPrestigePoints(prestige)
        submitCompanyValuation(CompanyManager.shared.state.companyValuation)
        submitContactsMet(contactsMet)
    }
    
    // MARK: - Show Game Center
    
    func showLeaderboards() {
        guard isAuthenticated else {
            gameCenterError = "Not signed into Game Center"
            return
        }
        showGameCenter = true
    }
    
    func showAchievements() {
        guard isAuthenticated else {
            gameCenterError = "Not signed into Game Center"
            return
        }
        showGameCenter = true
    }
}

// MARK: - Game Center View Controller Representable
struct GameCenterView: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    let viewState: GKGameCenterViewControllerState
    
    func makeUIViewController(context: Context) -> GKGameCenterViewController {
        let viewController = GKGameCenterViewController(state: viewState)
        viewController.gameCenterDelegate = context.coordinator
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: GKGameCenterViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, GKGameCenterControllerDelegate {
        let parent: GameCenterView
        
        init(_ parent: GameCenterView) {
            self.parent = parent
        }
        
        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            parent.dismiss()
        }
    }
}

// MARK: - Game Center Button View
struct GameCenterButtonView: View {
    @ObservedObject var gameCenter = GameCenterManager.shared
    @State private var showLeaderboards = false
    @State private var showAchievements = false
    
    let accentColor = Color(red: 0.4, green: 0.7, blue: 0.4)
    
    var body: some View {
        HStack(spacing: 12) {
            // Leaderboards button
            Button(action: { showLeaderboards = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 12))
                    Text("Leaderboards")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(gameCenter.isAuthenticated ? .white : .gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(gameCenter.isAuthenticated ? accentColor.opacity(0.3) : Color.gray.opacity(0.2))
                )
            }
            .disabled(!gameCenter.isAuthenticated)
            
            // Achievements button
            Button(action: { showAchievements = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 12))
                    Text("Achievements")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(gameCenter.isAuthenticated ? .white : .gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(gameCenter.isAuthenticated ? Color.yellow.opacity(0.3) : Color.gray.opacity(0.2))
                )
            }
            .disabled(!gameCenter.isAuthenticated)
        }
        .sheet(isPresented: $showLeaderboards) {
            GameCenterView(viewState: .leaderboards)
        }
        .sheet(isPresented: $showAchievements) {
            GameCenterView(viewState: .achievements)
        }
    }
}

// MARK: - Game Center Status Badge
struct GameCenterStatusBadge: View {
    @ObservedObject var gameCenter = GameCenterManager.shared
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: gameCenter.isAuthenticated ? "gamecontroller.fill" : "gamecontroller")
                .font(.system(size: 10))
                .foregroundColor(gameCenter.isAuthenticated ? .green : .gray)
            
            if !gameCenter.isAuthenticated {
                Text("Sign In")
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.1))
        )
        .onTapGesture {
            if !gameCenter.isAuthenticated {
                gameCenter.authenticatePlayer()
            }
        }
    }
}
