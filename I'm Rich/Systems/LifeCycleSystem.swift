//
//  LifeCycleSystem.swift
//  I'm Rich
//
//  Time compression (1 min = 1 year) and age tracking
//

import SwiftUI
import Combine

// MARK: - Life Cycle Constants
struct LifeCycleConstants {
    static let secondsPerGameYear: TimeInterval = 60 // 1 minute = 1 year
    static let minStartingAge = 1
    static let maxStartingAge = 100
    static let retirementEligibleAge = 50
    static let maxAge = 100
    static let minDeathAge = 65  // Earliest possible death
    static let maxDeathAge = 100 // Latest possible death
}

// MARK: - Year End Event
struct YearEndEvent {
    let newAge: Int
    let investmentGains: Double
    let yearsPlayed: Int
    let canRetire: Bool
    let mustRetire: Bool
}

// MARK: - Life Cycle Manager
class LifeCycleManager: ObservableObject {
    static let shared = LifeCycleManager()
    
    @Published var currentAge: Int {
        didSet { UserDefaults.standard.set(currentAge, forKey: "currentAge") }
    }
    @Published var startingAge: Int {
        didSet { UserDefaults.standard.set(startingAge, forKey: "startingAge") }
    }
    @Published var gameYearsPassed: Int {
        didSet { UserDefaults.standard.set(gameYearsPassed, forKey: "gameYearsPassed") }
    }
    @Published var hasSetAge: Bool {
        didSet { UserDefaults.standard.set(hasSetAge, forKey: "hasSetAge") }
    }
    @Published var deathAge: Int {
        didSet { UserDefaults.standard.set(deathAge, forKey: "deathAge") }
    }
    @Published var showBirthdayAlert = false
    @Published var showRetirementPrompt = false
    @Published var showDeathAlert = false
    @Published var lastYearEndEvent: YearEndEvent?
    @Published var isDead = false
    
    private var yearAccumulator: TimeInterval = 0
    private var lastTickTime: Date
    
    var canRetire: Bool {
        currentAge >= LifeCycleConstants.retirementEligibleAge
    }
    
    var mustRetire: Bool {
        currentAge >= LifeCycleConstants.maxAge
    }
    
    var isDying: Bool {
        currentAge >= deathAge
    }
    
    var yearsUntilDeath: Int {
        max(0, deathAge - currentAge)
    }
    
    var yearsUntilRetirementEligible: Int {
        max(0, LifeCycleConstants.retirementEligibleAge - currentAge)
    }
    
    var yearProgress: Double {
        yearAccumulator / LifeCycleConstants.secondsPerGameYear
    }
    
    var formattedAge: String {
        "Age \(currentAge)"
    }
    
    var formattedYearsPlayed: String {
        "Year \(gameYearsPassed)"
    }
    
    /// Estimated lifespan message
    var lifespanHint: String {
        if currentAge >= 60 {
            return "Time is precious..."
        } else if currentAge >= 45 {
            return "Make every year count"
        } else {
            return ""
        }
    }
    
    private init() {
        self.hasSetAge = UserDefaults.standard.bool(forKey: "hasSetAge")
        
        var savedStartingAge = UserDefaults.standard.integer(forKey: "startingAge")
        if savedStartingAge == 0 { savedStartingAge = 27 } // Default
        self.startingAge = savedStartingAge
        
        var savedCurrentAge = UserDefaults.standard.integer(forKey: "currentAge")
        if savedCurrentAge == 0 { savedCurrentAge = savedStartingAge }
        self.currentAge = savedCurrentAge
        
        self.gameYearsPassed = UserDefaults.standard.integer(forKey: "gameYearsPassed")
        self.lastTickTime = Date()
        
        // Load or generate death age
        var savedDeathAge = UserDefaults.standard.integer(forKey: "deathAge")
        if savedDeathAge == 0 {
            // Generate random death age between 65-100
            savedDeathAge = Int.random(in: LifeCycleConstants.minDeathAge...LifeCycleConstants.maxDeathAge)
            UserDefaults.standard.set(savedDeathAge, forKey: "deathAge")
        }
        self.deathAge = savedDeathAge
        
        // Load accumulated time
        self.yearAccumulator = UserDefaults.standard.double(forKey: "yearAccumulator")
    }
    
    /// Generate a new random death age for a new life
    func generateNewDeathAge() {
        deathAge = Int.random(in: LifeCycleConstants.minDeathAge...LifeCycleConstants.maxDeathAge)
    }
    
    func setStartingAge(_ age: Int) {
        startingAge = max(LifeCycleConstants.minStartingAge, 
                          min(LifeCycleConstants.maxStartingAge, age))
        currentAge = startingAge
        gameYearsPassed = 0
        yearAccumulator = 0
        hasSetAge = true
        saveAccumulator()
    }
    
    /// Call this every game tick (0.1 seconds)
    /// Returns a YearEndEvent if a new year has passed
    func tick(deltaTime: TimeInterval = 0.1) -> YearEndEvent? {
        yearAccumulator += deltaTime
        
        if yearAccumulator >= LifeCycleConstants.secondsPerGameYear {
            yearAccumulator -= LifeCycleConstants.secondsPerGameYear
            saveAccumulator()
            return processYearEnd()
        }
        
        // Save accumulator periodically (every ~10 seconds of real time)
        if Int(yearAccumulator) % 10 == 0 {
            saveAccumulator()
        }
        
        return nil
    }
    
    private func processYearEnd() -> YearEndEvent {
        currentAge += 1
        gameYearsPassed += 1
        
        let event = YearEndEvent(
            newAge: currentAge,
            investmentGains: 0, // Will be calculated by GameState
            yearsPlayed: gameYearsPassed,
            canRetire: canRetire,
            mustRetire: mustRetire
        )
        
        lastYearEndEvent = event
        
        // Check for death
        if currentAge >= deathAge {
            isDead = true
            showDeathAlert = true
            // Haptic feedback for death
            FeedbackCoordinator.shared.achievement()
            return event
        }
        
        showBirthdayAlert = true
        
        if mustRetire {
            showRetirementPrompt = true
        }
        
        // Haptic feedback for birthday
        FeedbackCoordinator.shared.achievement()
        
        return event
    }
    
    /// Handle death - called when user acknowledges death alert
    func processDeath() {
        isDead = false
        showDeathAlert = false
    }
    
    func dismissBirthdayAlert() {
        showBirthdayAlert = false
    }
    
    func triggerRetirementPrompt() {
        showRetirementPrompt = true
    }
    
    private func saveAccumulator() {
        UserDefaults.standard.set(yearAccumulator, forKey: "yearAccumulator")
    }
    
    func reset(keepStartingAge: Bool = false) {
        if !keepStartingAge {
            hasSetAge = false
        }
        currentAge = startingAge
        gameYearsPassed = 0
        yearAccumulator = 0
        showBirthdayAlert = false
        showRetirementPrompt = false
        showDeathAlert = false
        isDead = false
        lastYearEndEvent = nil
        generateNewDeathAge()
        saveAccumulator()
    }
    
    func fullReset() {
        hasSetAge = false
        startingAge = 27
        currentAge = 27
        gameYearsPassed = 0
        yearAccumulator = 0
        showBirthdayAlert = false
        showRetirementPrompt = false
        showDeathAlert = false
        isDead = false
        lastYearEndEvent = nil
        generateNewDeathAge()
        saveAccumulator()
    }
}

// MARK: - Birthday Alert View
struct BirthdayAlertView: View {
    let age: Int
    let netWorth: Double
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    private let prestigeThreshold: Double = 1_000_000_000
    
    var canPrestige: Bool {
        netWorth >= prestigeThreshold
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("🎂")
                .font(.system(size: 60))
            
            Text("HAPPY BIRTHDAY!")
                .font(.system(size: 20, weight: .black))
                .foregroundColor(.white)
                .tracking(2)
            
            Text("You are now \(age) years old")
                .font(.system(size: 16))
                .foregroundColor(.gray)
            
            // Only show retirement message if they can actually prestige ($1B+)
            if canPrestige {
                Text("You can now retire and start a new life!")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow)
                    .multilineTextAlignment(.center)
            } else if age >= LifeCycleConstants.retirementEligibleAge {
                // They're old enough but don't have the money
                Text("Reach $1B to unlock prestige")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onDismiss) {
                Text("Continue")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.yellow)
                    )
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.yellow, lineWidth: 2)
                )
                .shadow(color: Color.yellow.opacity(0.3), radius: 20)
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

// MARK: - Age Display View
struct AgeDisplayView: View {
    @ObservedObject var lifecycle = LifeCycleManager.shared
    
    let accentColor = Color(red: 0.4, green: 0.7, blue: 0.4)
    
    var body: some View {
        HStack(spacing: 8) {
            // Age
            HStack(spacing: 4) {
                Text("🎂")
                    .font(.system(size: 12))
                Text("\(lifecycle.currentAge)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text("|")
                .foregroundColor(.gray.opacity(0.5))
            
            // Year
            HStack(spacing: 4) {
                Text("📅")
                    .font(.system(size: 12))
                Text("Yr \(lifecycle.gameYearsPassed)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Year progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 4)
                    
                    Capsule()
                        .fill(accentColor)
                        .frame(width: geometry.size.width * lifecycle.yearProgress, height: 4)
                }
            }
            .frame(width: 40, height: 4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Year Progress Ring
struct YearProgressRing: View {
    @ObservedObject var lifecycle = LifeCycleManager.shared
    
    let size: CGFloat
    let lineWidth: CGFloat
    let accentColor = Color(red: 0.4, green: 0.7, blue: 0.4)
    
    init(size: CGFloat = 40, lineWidth: CGFloat = 3) {
        self.size = size
        self.lineWidth = lineWidth
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: lineWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: lifecycle.yearProgress)
                .stroke(accentColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            // Age text
            Text("\(lifecycle.currentAge)")
                .font(.system(size: size * 0.35, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Death Alert View
struct DeathAlertView: View {
    let age: Int
    let yearsPlayed: Int
    let netWorth: Double
    let totalEarned: Double
    let onRestart: () -> Void
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    private func formatCompact(_ value: Double) -> String {
        switch value {
        case 1_000_000_000_000...: return String(format: "$%.1fT", value / 1_000_000_000_000)
        case 1_000_000_000...: return String(format: "$%.1fB", value / 1_000_000_000)
        case 1_000_000...: return String(format: "$%.1fM", value / 1_000_000)
        case 1_000...: return String(format: "$%.1fK", value / 1_000)
        default: return "$\(Int(value))"
        }
    }
    
    var epitaph: String {
        if netWorth >= 1_000_000_000 {
            return "A legendary titan of industry"
        } else if netWorth >= 100_000_000 {
            return "A true mogul and visionary"
        } else if netWorth >= 10_000_000 {
            return "A successful entrepreneur"
        } else if netWorth >= 1_000_000 {
            return "A millionaire who lived well"
        } else if netWorth >= 100_000 {
            return "A comfortable life, well lived"
        } else {
            return "Died with dreams unfulfilled"
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("⚰️")
                .font(.system(size: 60))
            
            Text("REST IN PEACE")
                .font(.system(size: 22, weight: .black))
                .foregroundColor(.white)
                .tracking(3)
            
            Text("You passed away at age \(age)")
                .font(.system(size: 16))
                .foregroundColor(.gray)
            
            Text("\"\(epitaph)\"")
                .font(.system(size: 14, weight: .medium).italic())
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Divider()
                .background(Color.white.opacity(0.3))
                .padding(.horizontal, 40)
            
            // Life stats
            VStack(spacing: 12) {
                HStack {
                    Text("Years Lived")
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(yearsPlayed)")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text("Final Net Worth")
                        .foregroundColor(.gray)
                    Spacer()
                    Text(formatCompact(netWorth))
                        .foregroundColor(netWorth >= 1_000_000 ? .green : .white)
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text("Lifetime Earnings")
                        .foregroundColor(.gray)
                    Spacer()
                    Text(formatCompact(totalEarned))
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                }
            }
            .font(.system(size: 14))
            .padding(.horizontal, 30)
            
            Divider()
                .background(Color.white.opacity(0.3))
                .padding(.horizontal, 40)
            
            Text("Your legacy fades without prestige...")
                .font(.system(size: 12))
                .foregroundColor(.orange)
            
            Button(action: onRestart) {
                Text("Start New Life")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color.white)
                    )
            }
            .padding(.top, 10)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.98))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.5), radius: 20)
        )
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}
