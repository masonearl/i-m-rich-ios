//
//  LifeReflection.swift
//  Life of Wealth
//
//  End-of-life questions and multiple endings based on wealth dimensions
//

import SwiftUI
import Combine

// MARK: - Life Ending Type
enum LifeEnding: String, Codable, CaseIterable {
    case tycoon = "Tycoon"
    case balanced = "Balanced Life"
    case legacyBuilder = "Legacy Builder"
    case emptyVictory = "Empty Victory"
    case familyFirst = "Family First"
    case adventureSeeker = "Adventure Seeker"
    case burnedOut = "Burned Out"
    
    var icon: String {
        switch self {
        case .tycoon: return "💰"
        case .balanced: return "⚖️"
        case .legacyBuilder: return "🏛️"
        case .emptyVictory: return "🏆"
        case .familyFirst: return "👨‍👩‍👧‍👦"
        case .adventureSeeker: return "🌍"
        case .burnedOut: return "🔥"
        }
    }
    
    var title: String {
        switch self {
        case .tycoon: return "The Tycoon"
        case .balanced: return "A Life Well-Lived"
        case .legacyBuilder: return "The Legacy Builder"
        case .emptyVictory: return "Empty Victory"
        case .familyFirst: return "Family First"
        case .adventureSeeker: return "The Adventurer"
        case .burnedOut: return "Burned Out"
        }
    }
    
    var description: String {
        switch self {
        case .tycoon:
            return "Died with billions, but alone. The obituary mentioned your net worth, not your heart. Monuments were built in your name, but no one came to visit."
        case .balanced:
            return "A life well-lived. Not the richest in the cemetery, but surrounded by love and meaning until the very end. Your grandchildren tell stories about you."
        case .legacyBuilder:
            return "Schools bear your name. Lives were changed. Money was just the tool. Generations will benefit from what you built."
        case .emptyVictory:
            return "You won the game everyone else was playing. But was it the right game? All those zeros in the bank account couldn't fill the void."
        case .familyFirst:
            return "Not rich by the world's standards, but your grandchildren fight over who gets to visit next. Every holiday, the house is full of laughter."
        case .adventureSeeker:
            return "The passport was full. The stories were legendary. From Machu Picchu to the Northern Lights, you saw it all. No regrets."
        case .burnedOut:
            return "The body gave out before the ambition did. A cautionary tale about the price of never slowing down."
        }
    }
    
    var prestigeBonus: PrestigeEndingBonus {
        switch self {
        case .tycoon:
            return PrestigeEndingBonus(financialMultiplier: 1.5, relationshipsMultiplier: 0.9, startingCashBonus: 0.02)
        case .balanced:
            return PrestigeEndingBonus(financialMultiplier: 1.15, relationshipsMultiplier: 1.15, experiencesMultiplier: 1.15, healthMultiplier: 1.15, legacyMultiplier: 1.15, startingCashBonus: 0.01)
        case .legacyBuilder:
            return PrestigeEndingBonus(financialMultiplier: 1.0, legacyMultiplier: 1.5, startingCashBonus: 0.015)
        case .emptyVictory:
            return PrestigeEndingBonus(financialMultiplier: 1.3, relationshipsMultiplier: 0.8, startingCashBonus: 0.01)
        case .familyFirst:
            return PrestigeEndingBonus(relationshipsMultiplier: 1.5, healthMultiplier: 1.2, startingCashBonus: 0.005)
        case .adventureSeeker:
            return PrestigeEndingBonus(experiencesMultiplier: 1.5, healthMultiplier: 1.1, startingCashBonus: 0.008)
        case .burnedOut:
            return PrestigeEndingBonus(financialMultiplier: 1.1, healthMultiplier: 0.8, startingCashBonus: 0.005)
        }
    }
}

// MARK: - Prestige Ending Bonus
struct PrestigeEndingBonus: Codable {
    var financialMultiplier: Double = 1.0
    var relationshipsMultiplier: Double = 1.0
    var experiencesMultiplier: Double = 1.0
    var healthMultiplier: Double = 1.0
    var legacyMultiplier: Double = 1.0
    var startingCashBonus: Double = 0.01  // Percentage of lifetime earnings
}

// MARK: - Life Summary
struct LifeSummary {
    let ending: LifeEnding
    let finalAge: Int
    let yearsLived: Int
    let totalEarned: Double
    let finalNetWorth: Double
    let wealthScores: WealthState
    let wasMarried: Bool
    let childrenCount: Int
    let highestFaction: Faction
    let workTimePercent: Double  // Calculated from overtime vs family time
}

// MARK: - Reflection Question
struct ReflectionQuestion: Identifiable {
    let id = UUID()
    let question: String
    let context: String
}

// MARK: - Life Reflection Manager
class LifeReflectionManager: ObservableObject {
    static let shared = LifeReflectionManager()
    
    @Published var currentSummary: LifeSummary?
    @Published var showReflection = false
    @Published var currentQuestionIndex = 0
    @Published var reflectionComplete = false
    
    private init() {}
    
    // MARK: - Determine Ending
    func determineEnding(wealth: WealthState, health: Int) -> LifeEnding {
        // Check for Burned Out first (health-based death)
        if health < 20 {
            return .burnedOut
        }
        
        // Tycoon: Financial 90+, Relationships <30
        if wealth.financial >= 90 && wealth.relationships < 30 {
            return .tycoon
        }
        
        // Empty Victory: Financial 80+, all others <40
        if wealth.financial >= 80 &&
           wealth.relationships < 40 &&
           wealth.experiences < 40 &&
           wealth.health < 40 &&
           wealth.legacy < 40 {
            return .emptyVictory
        }
        
        // Legacy Builder: Legacy 80+
        if wealth.legacy >= 80 {
            return .legacyBuilder
        }
        
        // Family First: Relationships 90+, Financial <50
        if wealth.relationships >= 90 && wealth.financial < 50 {
            return .familyFirst
        }
        
        // Adventure Seeker: Experiences 90+
        if wealth.experiences >= 90 {
            return .adventureSeeker
        }
        
        // Balanced Life: All dimensions 50-70
        if wealth.isBalanced {
            return .balanced
        }
        
        // Default based on highest dimension
        let scores: [(WealthDimension, Int)] = [
            (.financial, wealth.financial),
            (.relationships, wealth.relationships),
            (.experiences, wealth.experiences),
            (.health, wealth.health),
            (.legacy, wealth.legacy)
        ]
        
        let highest = scores.max(by: { $0.1 < $1.1 })?.0 ?? .financial
        
        switch highest {
        case .financial: return .tycoon
        case .relationships: return .familyFirst
        case .experiences: return .adventureSeeker
        case .health: return .balanced
        case .legacy: return .legacyBuilder
        }
    }
    
    // MARK: - Generate Summary
    func generateSummary(
        finalAge: Int,
        yearsLived: Int,
        totalEarned: Double,
        finalNetWorth: Double,
        wealthScores: WealthState,
        family: FamilyState,
        factions: FactionReputationState,
        workTimePercent: Double
    ) -> LifeSummary {
        let ending = determineEnding(wealth: wealthScores, health: wealthScores.health)
        
        return LifeSummary(
            ending: ending,
            finalAge: finalAge,
            yearsLived: yearsLived,
            totalEarned: totalEarned,
            finalNetWorth: finalNetWorth,
            wealthScores: wealthScores,
            wasMarried: family.isMarried,
            childrenCount: family.children.count,
            highestFaction: factions.highestFaction,
            workTimePercent: workTimePercent
        )
    }
    
    // MARK: - Reflection Questions
    func getReflectionQuestions(for summary: LifeSummary) -> [ReflectionQuestion] {
        var questions: [ReflectionQuestion] = []
        
        // Net worth question
        let worthContext: String
        if summary.finalNetWorth >= 1_000_000_000 {
            worthContext = "You amassed a fortune few could dream of."
        } else if summary.finalNetWorth >= 10_000_000 {
            worthContext = "You achieved significant financial success."
        } else if summary.finalNetWorth >= 1_000_000 {
            worthContext = "You reached millionaire status."
        } else {
            worthContext = "Money wasn't your primary focus."
        }
        questions.append(ReflectionQuestion(
            question: "With \(formatCurrency(summary.finalNetWorth)) to your name, what mattered most?",
            context: worthContext
        ))
        
        // Work-life balance question
        let workContext: String
        if summary.workTimePercent > 70 {
            workContext = "You prioritized career above all else."
        } else if summary.workTimePercent > 50 {
            workContext = "Work was important, but you found some balance."
        } else {
            workContext = "You valued time over money."
        }
        questions.append(ReflectionQuestion(
            question: "You spent \(Int(summary.workTimePercent))% of your energy on work. Was it worth it?",
            context: workContext
        ))
        
        // Family question
        let familyContext: String
        if summary.wasMarried && summary.childrenCount > 0 {
            familyContext = "You built a family of \(summary.childrenCount + 2)."
        } else if summary.wasMarried {
            familyContext = "You found a life partner."
        } else {
            familyContext = "You walked your path alone."
        }
        questions.append(ReflectionQuestion(
            question: summary.wasMarried ? "Your family was there in the end. Did you give them enough time?" : "You never started a family. Any regrets?",
            context: familyContext
        ))
        
        // Legacy question
        let legacyContext: String
        if summary.wealthScores.legacy >= 80 {
            legacyContext = "Your impact will outlive you by generations."
        } else if summary.wealthScores.legacy >= 50 {
            legacyContext = "You made a difference in some lives."
        } else {
            legacyContext = "The world will forget quickly."
        }
        questions.append(ReflectionQuestion(
            question: "Your legacy score is \(summary.wealthScores.legacy). How will you be remembered?",
            context: legacyContext
        ))
        
        return questions
    }
    
    private func formatCurrency(_ value: Double) -> String {
        if value >= 1_000_000_000 {
            return String(format: "$%.1fB", value / 1_000_000_000)
        } else if value >= 1_000_000 {
            return String(format: "$%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "$%.0fK", value / 1_000)
        } else {
            return String(format: "$%.0f", value)
        }
    }
    
    // MARK: - Start Reflection
    func startReflection(summary: LifeSummary) {
        currentSummary = summary
        currentQuestionIndex = 0
        reflectionComplete = false
        showReflection = true
    }
    
    func nextQuestion() {
        guard let summary = currentSummary else { return }
        let questions = getReflectionQuestions(for: summary)
        
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
        } else {
            reflectionComplete = true
        }
    }
    
    func reset() {
        currentSummary = nil
        showReflection = false
        currentQuestionIndex = 0
        reflectionComplete = false
    }
}

// MARK: - Life Reflection View
struct LifeReflectionView: View {
    @ObservedObject var reflection = LifeReflectionManager.shared
    let onComplete: (LifeEnding) -> Void
    
    @State private var opacity: Double = 0
    @State private var showEnding = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let summary = reflection.currentSummary {
                if reflection.reflectionComplete || showEnding {
                    endingView(summary)
                } else {
                    questionView(summary)
                }
            }
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 1)) {
                opacity = 1
            }
        }
    }
    
    func questionView(_ summary: LifeSummary) -> some View {
        let questions = reflection.getReflectionQuestions(for: summary)
        let currentQuestion = questions[reflection.currentQuestionIndex]
        
        return VStack(spacing: 30) {
            Spacer()
            
            // Progress
            HStack(spacing: 8) {
                ForEach(0..<questions.count, id: \.self) { index in
                    Circle()
                        .fill(index <= reflection.currentQuestionIndex ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            
            Text("Reflection")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
                .tracking(2)
            
            Text(currentQuestion.question)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            Text(currentQuestion.context)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    reflection.nextQuestion()
                    if reflection.reflectionComplete {
                        showEnding = true
                    }
                }
            }) {
                Text("Continue")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 50)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(Color.white)
                    )
            }
            .padding(.bottom, 50)
        }
    }
    
    func endingView(_ summary: LifeSummary) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text(summary.ending.icon)
                .font(.system(size: 80))
            
            Text(summary.ending.title)
                .font(.system(size: 28, weight: .black))
                .foregroundColor(.white)
                .tracking(2)
            
            Text(summary.ending.description)
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .lineSpacing(6)
            
            // Final stats
            VStack(spacing: 12) {
                statRow("Final Age", "\(summary.finalAge)")
                statRow("Years Played", "\(summary.yearsLived)")
                statRow("Net Worth", formatCompact(summary.finalNetWorth))
                statRow("Family", summary.wasMarried ? "\(summary.childrenCount) children" : "Single")
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
            .padding(.horizontal, 30)
            
            // Wealth dimension summary
            HStack(spacing: 8) {
                wealthBadge(.financial, summary.wealthScores.financial)
                wealthBadge(.relationships, summary.wealthScores.relationships)
                wealthBadge(.experiences, summary.wealthScores.experiences)
                wealthBadge(.health, summary.wealthScores.health)
                wealthBadge(.legacy, summary.wealthScores.legacy)
            }
            
            Spacer()
            
            Button(action: {
                onComplete(summary.ending)
            }) {
                Text("Start New Life")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 50)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(summary.ending.icon == "💰" ? Color.yellow : Color.green)
                    )
            }
            .padding(.bottom, 50)
        }
    }
    
    func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    func wealthBadge(_ dimension: WealthDimension, _ value: Int) -> some View {
        VStack(spacing: 2) {
            Text(dimension.icon)
                .font(.system(size: 14))
            Text("\(value)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(colorForValue(value))
        }
        .frame(width: 45)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(dimension.color.opacity(0.2))
        )
    }
    
    func colorForValue(_ value: Int) -> Color {
        switch value {
        case 70...100: return .green
        case 40..<70: return .yellow
        case 20..<40: return .orange
        default: return .red
        }
    }
    
    func formatCompact(_ value: Double) -> String {
        if value >= 1_000_000_000 {
            return String(format: "$%.1fB", value / 1_000_000_000)
        } else if value >= 1_000_000 {
            return String(format: "$%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "$%.0fK", value / 1_000)
        } else {
            return String(format: "$%.0f", value)
        }
    }
}
