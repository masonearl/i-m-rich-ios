//
//  ContentView.swift
//  I'm Rich
//
//  Created by Mason Earl on 10/26/25.
//

import SwiftUI
import CoreMotion

struct ContentView: View {
    @State private var moneyItems: [MoneyItem] = []
    @State private var showingShare = false
    @State private var showSplash = true
    @AppStorage("totalMoney") private var totalMoney: Double = 0
    @AppStorage("totalTaps") private var totalTaps: Int = 0
    @AppStorage("highestStreak") private var highestStreak: Int = 0
    @AppStorage("timesShared") private var timesShared: Int = 0
    @AppStorage("currentLevel") private var currentLevel: Int = 1
    @State private var currentStreak: Int = 0
    @State private var motionManager = CMMotionManager()
    @State private var showStats = false
    @State private var showLevelUp = false
    @State private var lastTapTime = Date()
    @State private var newLevelReached: Int = 1
    @State private var showMoneyExplosion = false
    @State private var lastMilestone: Double = 0
    
    let streakTimeLimit: TimeInterval = 1.5
    
    let levels: [Level] = generateLevels()
    
    var currentLevelInfo: Level {
        levels.last(where: { totalMoney >= $0.requirement }) ?? levels[0]
    }
    
    var nextLevelInfo: Level? {
        levels.first(where: { totalMoney < $0.requirement })
    }
    
    var levelProgress: Double {
        guard let next = nextLevelInfo else { return 1.0 }
        let current = currentLevelInfo
        let range = next.requirement - current.requirement
        let progress = totalMoney - current.requirement
        return min(progress / range, 1.0)
    }
    
    var maxMoneyItems: Int {
        // Scale money limit with level: starts at 100, increases by 20 per level
        return 100 + (currentLevel * 20)
    }
    
    var streakMultiplier: Int {
        // Unlock tap multipliers based on current streak
        switch currentStreak {
        case 0..<100:
            return 1 // Single tap
        case 100..<300:
            return 2 // Double tap bonus
        case 300..<500:
            return 3 // Triple tap bonus
        case 500..<1000:
            return 4 // Quad tap bonus
        case 1000..<2000:
            return 5 // 5x tap bonus
        case 2000..<4000:
            return 7 // 7x tap bonus
        case 4000..<7000:
            return 10 // 10x tap bonus
        case 7000..<10000:
            return 15 // 15x tap bonus
        default:
            return 20 // 20x MEGA BONUS at 10000+
        }
    }
    
    var nextStreakMilestone: (taps: Int, multiplier: Int)? {
        let milestones = [(100, 2), (300, 3), (500, 4), (1000, 5), (2000, 7), (4000, 10), (7000, 15), (10000, 20)]
        return milestones.first(where: { $0.0 > currentStreak })
    }
    
    var perTapValue: Double {
        let baseValue: Double
        
        // Progressive tap values based on total money
        switch totalMoney {
        case 0..<100:
            baseValue = 1
        case 100..<1_000:
            baseValue = 5
        case 1_000..<10_000:
            baseValue = 25
        case 10_000..<100_000:
            baseValue = 100
        case 100_000..<1_000_000:
            baseValue = 500
        case 1_000_000..<10_000_000:
            baseValue = 2_500
        case 10_000_000..<100_000_000:
            baseValue = 10_000
        case 100_000_000..<1_000_000_000:
            baseValue = 50_000
        case 1_000_000_000..<10_000_000_000:
            baseValue = 250_000
        case 10_000_000_000..<100_000_000_000:
            baseValue = 1_000_000
        case 100_000_000_000..<1_000_000_000_000:
            baseValue = 5_000_000
        default:
            baseValue = 25_000_000
        }
        
        // Bonus multiplier for shares (10% per share)
        let shareMultiplier = 1.0 + (Double(timesShared) * 0.1)
        
        // Level bonus (higher levels get better multiplier)
        let levelBonus = 1.0 + (Double(currentLevel) * 0.02) // 2% per level
        
        // Streak multiplier bonus
        let streakBonus = Double(streakMultiplier)
        
        return baseValue * shareMultiplier * levelBonus * streakBonus
    }
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashScreen()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                showSplash = false
                            }
                        }
                    }
            } else {
                mainView
            }
        }
        .onAppear {
            startMotionUpdates()
        }
        .onDisappear {
            motionManager.stopDeviceMotionUpdates()
        }
    }
    
    func startMotionUpdates() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.02
            motionManager.startDeviceMotionUpdates(to: .main) { data, error in
                guard let data = data else { return }
                
                let gravityX = data.gravity.x
                let gravityY = data.gravity.y
                
                for i in 0..<moneyItems.count {
                    let velocityX = CGFloat(gravityX * 15)
                    let velocityY = CGFloat(-gravityY * 15)
                    
                    moneyItems[i].x += velocityX
                    moneyItems[i].y += velocityY
                    
                    // Keep within screen bounds
                    let screenWidth = UIScreen.main.bounds.width
                    let screenHeight = UIScreen.main.bounds.height
                    moneyItems[i].x = max(30, min(screenWidth - 30, moneyItems[i].x))
                    moneyItems[i].y = max(30, min(screenHeight - 30, moneyItems[i].y))
                    
                    // Slight rotation based on movement
                    moneyItems[i].rotation += Double(velocityX * 0.5)
                }
            }
        }
    }
    
    var mainView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ForEach(moneyItems) { item in
                Text(item.emoji)
                    .font(.system(size: item.size))
                    .rotationEffect(.degrees(item.rotation))
                    .position(x: item.x, y: item.y)
            }
            
        VStack(spacing: 0) {
                // Top Bar
                HStack {
                    Button(action: { showStats.toggle() }) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.4))
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                Spacer()
                
                // Main Content Container
                VStack(spacing: 16) {
                    // Level Badge Row
                    levelBadge
                        .frame(maxWidth: .infinity)
                    
                    // Net Worth Display Row
                    netWorthCard
                        .frame(maxWidth: .infinity)
                    
                    // Progress Row
                    if let next = nextLevelInfo {
                        nextLevelProgress(next: next)
                            .frame(maxWidth: .infinity)
                    } else {
                        maxLevelBadge
                            .frame(maxWidth: .infinity)
                    }
                    
                    // Tap Value Row
                    tapValueDisplay
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Bottom Right Share Button
                HStack {
                    Spacer()
                    Button(action: { showingShare = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14, weight: .semibold))
                            Text("SHARE")
                                .font(.system(size: 13, weight: .bold))
                                .tracking(0.8)
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.7, blue: 0.4),
                                    Color(red: 0.3, green: 0.6, blue: 0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.4), radius: 8, x: 0, y: 3)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 34)
            }
        }
        .onTapGesture { location in
            createMoneyRain(at: location)
        }
        .sheet(isPresented: $showingShare) {
            ShareSheet(activityItems: ["I'm so rich! I'm a \(currentLevelInfo.name) with \(formattedMoney) created in \(totalTaps) taps on the I'm Rich app 💰🤑"], onDismiss: {
                handleShareCompleted()
            })
        }
        .sheet(isPresented: $showStats) {
            StatsView(totalMoney: totalMoney, totalTaps: totalTaps, highestStreak: highestStreak, perTapValue: perTapValue, timesShared: timesShared, currentLevel: currentLevelInfo, levels: levels)
        }
        .overlay(alignment: .topLeading) {
            if currentStreak > 0 {
                streakOverlay
                    .transition(.move(edge: .leading).combined(with: .opacity))
                    .padding(.top, 70)
                    .padding(.leading, 20)
            }
        }
        .overlay(alignment: .topTrailing) {
            if showLevelUp {
                LevelUpView(level: newLevelReached, levelInfo: levels.first(where: { $0.number == newLevelReached }) ?? levels[0])
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .padding(.top, 70)
                    .padding(.trailing, 20)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation {
                                showLevelUp = false
                            }
                        }
                    }
            }
        }
        .overlay {
            if showMoneyExplosion {
                MoneyExplosionView(milestone: lastMilestone)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    var tapValueDisplay: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("TAP VALUE")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.6))
                    .tracking(1.5)
                
                HStack(spacing: 8) {
                    Text("+$" + String(format: "%.0f", perTapValue))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.4))
                    
                    if streakMultiplier > 1 {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 9))
                            Text("×\(streakMultiplier)")
                                .font(.system(size: 11, weight: .black))
                        }
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(6)
                    }
                    
                    if timesShared > 0 {
                        shareBonusBadge
                    }
                }
            }
            
            Spacer()
            
            Text("💰")
                .font(.system(size: 32))
        }
        .frame(height: 70)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.15), radius: 8, x: 0, y: 2)
        )
    }
    
    var shareBonusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.system(size: 10))
            Text("+\(Int(Double(timesShared) * 10))%")
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.4))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.15))
        .cornerRadius(8)
    }
    
    var levelBadge: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.2),
                                Color(red: 0.3, green: 0.6, blue: 0.3).opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .overlay(
                        Circle()
                            .stroke(Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.4), lineWidth: 2)
                    )
                
                Text(currentLevelInfo.icon)
                    .font(.system(size: 32))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("LEVEL \(currentLevelInfo.number)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.7))
                    .tracking(1.2)
                Text(currentLevelInfo.name.uppercased())
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(0.5)
            }
            
            Spacer()
        }
        .frame(height: 80)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.15), radius: 8, x: 0, y: 2)
        )
    }
    
    var netWorthCard: some View {
        VStack(spacing: 12) {
            Text("NET WORTH")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.gray.opacity(0.6))
                .tracking(2)
            
            Text(formattedMoney)
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.4))
                .shadow(color: Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.3), radius: 8, x: 0, y: 0)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.15), radius: 8, x: 0, y: 2)
        )
    }
    
    var streakOverlay: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 16))
                Text("\(currentStreak)")
                    .font(.system(size: 15, weight: .bold))
                    .tracking(0.5)
                
                if streakMultiplier > 1 {
                    Text("×\(streakMultiplier)")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.yellow)
                }
            }
            .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.4))
            
            if let next = nextStreakMilestone {
                Text("\(next.taps - currentStreak) to ×\(next.multiplier)")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.gray)
            } else {
                Text("MAX BONUS!")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.yellow)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.6), lineWidth: 2)
                )
        )
        .shadow(color: Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.5), radius: 12, x: 0, y: 5)
    }
    
    var maxLevelBadge: some View {
        HStack {
            Text("👑")
                .font(.system(size: 24))
            Text("MAXIMUM WEALTH ACHIEVED")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.4))
                .tracking(1)
            Spacer()
        }
        .frame(height: 70)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    func nextLevelProgress(next: Level) -> some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("NEXT LEVEL")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.gray.opacity(0.6))
                        .tracking(1.5)
                    
                    HStack(spacing: 6) {
                        Text(next.name.uppercased())
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .tracking(0.5)
                        Text(next.icon)
                            .font(.system(size: 14))
                    }
                }
                
                Spacer()
                
                Text("\(Int(levelProgress * 100))%")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.4))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.7, blue: 0.4),
                                    Color(red: 0.3, green: 0.6, blue: 0.3)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(6, geometry.size.width * levelProgress), height: 6)
                        .shadow(color: Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.5), radius: 4, x: 0, y: 0)
                }
            }
            .frame(height: 6)
        }
        .frame(height: 70)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.15), radius: 8, x: 0, y: 2)
        )
    }
    
    var formattedMoney: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: totalMoney)) ?? "$0"
    }
    
    func handleShareCompleted() {
        timesShared += 1
        // Give share bonus that scales with level
        let baseShareBonus = 100.0
        let levelMultiplier = pow(1.5, Double(currentLevel) / 10.0)
        let shareBonus = baseShareBonus * levelMultiplier * Double(timesShared)
        totalMoney += shareBonus
    }
    
    func checkLevelUp() {
        let newLevel = currentLevelInfo.number
        if newLevel > currentLevel {
            currentLevel = newLevel
            newLevelReached = newLevel
            
            // Award level bonus
            if let levelInfo = levels.first(where: { $0.number == newLevel }) {
                totalMoney += levelInfo.bonus
            }
            
            withAnimation {
                showLevelUp = true
            }
        }
    }
    
    func checkMoneyMilestone() {
        let milestones: [Double] = [
            1_000_000,      // 1 million
            5_000_000,      // 5 million
            10_000_000,     // 10 million
            50_000_000,     // 50 million
            100_000_000,    // 100 million
            500_000_000,    // 500 million
            1_000_000_000,  // 1 billion
            10_000_000_000, // 10 billion
            100_000_000_000 // 100 billion
        ]
        
        for milestone in milestones {
            if totalMoney >= milestone && lastMilestone < milestone {
                lastMilestone = milestone
                triggerMoneyExplosion()
                break
            }
        }
    }
    
    func triggerMoneyExplosion() {
        // Don't reset lastTapTime - keep streak alive!
        
        withAnimation {
            showMoneyExplosion = true
        }
        
        // Create explosion of small money emojis across the entire screen
        let explosionCount = 80 // More emojis
        for _ in 0..<explosionCount {
            let randomX = CGFloat.random(in: 20...UIScreen.main.bounds.width - 20)
            let randomY = CGFloat.random(in: 80...UIScreen.main.bounds.height - 80)
            
            let money = MoneyItem(
                emoji: "💰",
                size: CGFloat.random(in: 20...35), // Smaller emojis
                x: randomX,
                y: randomY,
                color: .white,
                rotation: Double.random(in: 0...360)
            )
            
            moneyItems.append(money)
        }
        
        // Auto-dismiss after 2.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                showMoneyExplosion = false
            }
        }
    }
    
    func createMoneyRain(at location: CGPoint) {
        let now = Date()
        let timeSinceLastTap = now.timeIntervalSince(lastTapTime)
        
        if timeSinceLastTap < streakTimeLimit {
            currentStreak += 1
            if currentStreak > highestStreak {
                highestStreak = currentStreak
            }
        } else {
            currentStreak = 1
        }
        lastTapTime = now
        
        totalMoney += perTapValue
        totalTaps += 1
        
        checkLevelUp()
        checkMoneyMilestone()
        
        let isBillTap = moneyItems.count % 2 == 0
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        for _ in 0..<5 {
            let size = CGFloat.random(in: 30...45)
            // Completely random placement across entire screen
            let x = CGFloat.random(in: 40...(screenWidth - 40))
            let y = CGFloat.random(in: 100...(screenHeight - 100))
            let startRotation = Double.random(in: 0...360)
            
            let money = MoneyItem(
                emoji: isBillTap ? "💵" : "🪙",
                size: size,
                x: x,
                y: y,
                color: .white,
                rotation: startRotation
            )
            
            moneyItems.append(money)
        }
        
        // Remove excess items to prevent lag (scales with level)
        if moneyItems.count > maxMoneyItems {
            moneyItems.removeFirst(moneyItems.count - maxMoneyItems)
        }
    }
}

struct SplashScreen: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.52, green: 0.73, blue: 0.55).opacity(0.3),
                                    Color(red: 0.52, green: 0.73, blue: 0.55).opacity(0.1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 180, height: 180)
                        .scaleEffect(scale)
                        .opacity(opacity)
                    
                    Text("$")
                        .font(.system(size: 100, weight: .bold))
                        .foregroundColor(Color(red: 0.52, green: 0.73, blue: 0.55))
                        .scaleEffect(scale)
                        .opacity(opacity)
                }
                
                Text("I'M RICH")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(Color(red: 0.52, green: 0.73, blue: 0.55))
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

struct MoneyItem: Identifiable {
    let id = UUID()
    var emoji: String
    var size: CGFloat
    var x: CGFloat
    var y: CGFloat
    var color: Color
    var rotation: Double = 0
}


struct Level: Identifiable {
    let id = UUID()
    let number: Int
    let name: String
    let requirement: Double
    let bonus: Double
    let icon: String
}

func generateLevels() -> [Level] {
    let levelData: [(range: ClosedRange<Int>, name: String, icon: String, multiplier: Double)] = [
        (1...5, "Broke", "😢", 1.0),
        (6...10, "Hustler", "💪", 1.5),
        (11...15, "Worker", "👷", 2.0),
        (16...20, "Side Gig", "💼", 3.0),
        (21...25, "Entrepreneur", "🚀", 5.0),
        (26...30, "Business Owner", "🏢", 8.0),
        (31...35, "Investor", "📈", 12.0),
        (36...40, "Successful", "⭐", 20.0),
        (41...45, "Well Off", "💵", 35.0),
        (46...50, "Rich", "💰", 60.0),
        (51...55, "Very Rich", "💎", 100.0),
        (56...60, "Wealthy", "👑", 175.0),
        (61...65, "Very Wealthy", "🏰", 300.0),
        (66...70, "Multi-Millionaire", "🏆", 500.0),
        (71...75, "Mega Rich", "🌟", 850.0),
        (76...80, "Ultra Wealthy", "✨", 1400.0),
        (81...85, "Billionaire", "🚁", 2300.0),
        (86...90, "Multi-Billionaire", "🛥️", 4000.0),
        (91...95, "Mega Billionaire", "🏝️", 7000.0),
        (96...100, "Trillionaire", "🌍", 12000.0)
    ]
    
    var levels: [Level] = []
    var baseRequirement = 0.0
    
    for (range, name, icon, multiplier) in levelData {
        for level in range {
            let levelMultiplier = pow(1.35, Double(level - 1))
            let requirement = baseRequirement
            let bonus = requirement * 0.05 // 5% of requirement as bonus
            
            let levelName = level == range.upperBound ? name : "\(name) \(level - range.lowerBound + 1)"
            
            levels.append(Level(
                number: level,
                name: levelName,
                requirement: requirement,
                bonus: max(bonus, 10),
                icon: icon
            ))
            
            // Calculate next requirement with increasing difficulty
            baseRequirement += 100 * multiplier * levelMultiplier
        }
    }
    
    // Ensure level 100 reaches 1 trillion
    if let lastLevel = levels.last {
        let targetRequirement = 1_000_000_000_000.0 // 1 trillion
        if lastLevel.requirement < targetRequirement {
            // Adjust the last level
            levels[99] = Level(
                number: 100,
                name: "Trillionaire",
                requirement: targetRequirement,
                bonus: 100_000_000_000, // 100 billion bonus
                icon: "🌍"
            )
        }
    }
    
    return levels
}

struct LevelUpView: View {
    let level: Int
    let levelInfo: Level
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.85, green: 0.75, blue: 0.5),
                                Color(red: 0.75, green: 0.65, blue: 0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(color: Color(red: 0.85, green: 0.75, blue: 0.5).opacity(0.5), radius: 10, x: 0, y: 0)
                
                Text(levelInfo.icon)
                    .font(.system(size: 28))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("LEVEL \(level) UNLOCKED!")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(0.5)
                
                Text(levelInfo.name.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(red: 0.85, green: 0.75, blue: 0.5))
                    .tracking(1)
                
                if levelInfo.bonus > 0 {
                    Text("+$\(Int(levelInfo.bonus)) bonus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(red: 0.85, green: 0.75, blue: 0.5).opacity(0.8))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.85, green: 0.75, blue: 0.5),
                                    Color(red: 0.75, green: 0.65, blue: 0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: Color(red: 0.85, green: 0.75, blue: 0.5).opacity(0.4), radius: 15, x: 0, y: 5)
        )
    }
}

struct StatsView: View {
    let totalMoney: Double
    let totalTaps: Int
    let highestStreak: Int
    let perTapValue: Double
    let timesShared: Int
    let currentLevel: Level
    let levels: [Level]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                HStack {
                    Text("Stats")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.4))
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.4))
                    }
                }
                .padding()
                
                VStack(spacing: 20) {
                    HStack {
                        Text(currentLevel.icon)
                            .font(.system(size: 40))
                        VStack(alignment: .leading) {
                            Text("Level \(currentLevel.number)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                            Text(currentLevel.name)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.3), lineWidth: 1.5)
                            )
                            .shadow(color: Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.15), radius: 8, x: 0, y: 2)
                    )
                    
                    VStack(spacing: 16) {
                        StatRow(icon: "dollarsign.circle.fill", title: "Total Created", value: formattedMoney, color: Color(red: 0.4, green: 0.7, blue: 0.4))
                        StatRow(icon: "hand.tap.fill", title: "Total Taps", value: "\(totalTaps)", color: Color(red: 0.4, green: 0.7, blue: 0.4))
                        StatRow(icon: "flame.fill", title: "Highest Streak", value: "\(highestStreak)", color: Color(red: 0.4, green: 0.7, blue: 0.4))
                        StatRow(icon: "arrow.up.circle.fill", title: "Per Tap Value", value: formattedPerTap, color: Color(red: 0.4, green: 0.7, blue: 0.4))
                        StatRow(icon: "square.and.arrow.up.fill", title: "Times Shared", value: "\(timesShared)", color: Color(red: 0.4, green: 0.7, blue: 0.4))
                        
                        if totalTaps > 0 {
                            StatRow(icon: "chart.line.uptrend.xyaxis", title: "Average Per Tap", value: formattedAverage, color: Color(red: 0.4, green: 0.7, blue: 0.4))
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .padding()
        }
    }
    
    var formattedMoney: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: totalMoney)) ?? "$0"
    }
    
    var formattedPerTap: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: perTapValue)) ?? "$0"
    }
    
    var formattedAverage: String {
        let avg = totalTaps > 0 ? totalMoney / Double(totalTaps) : 0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: avg)) ?? "$0"
    }
}

struct StatRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.15), radius: 8, x: 0, y: 2)
        )
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in
            if completed {
                onDismiss()
            }
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct MoneyExplosionView: View {
    let milestone: Double
    @State private var animationScale: CGFloat = 0.3
    @State private var animationOpacity: Double = 0
    
    var milestoneText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: milestone)) ?? "$0"
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 12) {
                Text(milestoneText)
                    .font(.system(size: 64, weight: .black))
                    .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.4))
                    .shadow(color: Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.7), radius: 25, x: 0, y: 0)
                
                Text("CONGRATS!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(4)
                    .shadow(color: .black, radius: 6, x: 0, y: 3)
            }
            .scaleEffect(animationScale)
            .opacity(animationOpacity)
            
            Spacer()
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                animationScale = 1.2
                animationOpacity = 1.0
            }
            
            withAnimation(.easeInOut(duration: 0.7).delay(0.2).repeatForever(autoreverses: true)) {
                animationScale = 1.05
            }
        }
    }
}

#Preview {
    ContentView()
}
