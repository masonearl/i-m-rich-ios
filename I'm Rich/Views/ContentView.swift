//
//  ContentView.swift
//  I'm Rich
//
//  Created by Mason Earl on 10/26/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var game = GameState()
    @ObservedObject private var lifecycle = LifeCycleManager.shared
    @ObservedObject private var prestige = PrestigeManager.shared
    @ObservedObject private var newsFeed = NewsFeedManager.shared
    
    // Life of Wealth managers
    @ObservedObject private var wealth = WealthManager.shared
    @ObservedObject private var energy = EnergyManager.shared
    @ObservedObject private var factions = FactionManager.shared
    @ObservedObject private var family = FamilyManager.shared
    @ObservedObject private var reflection = LifeReflectionManager.shared
    @ObservedObject private var company = CompanyManager.shared
    @ObservedObject private var achievements = AchievementManager.shared
    
    @State private var showSplash = true
    @State private var showOnboarding = false
    @State private var showCareerPicker = false
    @State private var showInvestSheet = false
    @State private var selectedInvestment: Investment?
    @State private var investAmount: String = ""
    @State private var showProductSheet = false
    @State private var showContactSheet = false
    @State private var showOpportunityResult: (success: Bool, message: String)?
    @State private var showPhaseUnlock = false
    @State private var unlockedPhase: GamePhase?
    @State private var lastPhase: GamePhase = .hustle
    
    // Collapsible sections
    @State private var investmentsExpanded = true
    @State private var upgradesExpanded = true
    @State private var productsExpanded = false
    @State private var contactsExpanded = false
    @State private var autoTappersExpanded = true
    @State private var factionsExpanded = false
    @State private var familyExpanded = true
    @State private var actionsExpanded = true
    @State private var companyExpanded = true
    @State private var leaderboardExpanded = true
    
    let accentColor = Color(red: 0.4, green: 0.7, blue: 0.4)
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashScreen()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                showSplash = false
                                // Check if we need onboarding
                                if !lifecycle.hasSetAge {
                                    showOnboarding = true
                                }
                            }
                        }
                    }
            } else if showOnboarding {
                OnboardingView(onComplete: {
                    withAnimation {
                        showOnboarding = false
                        // Apply prestige starting cash if applicable
                        if prestige.hasPrestiged {
                            game.cash = prestige.getStartingCash()
                            game.totalEarned = prestige.getStartingCash()
                        }
                    }
                })
            } else {
                // New zone-based navigation
                ZonedGameView(game: game)
            }
            
            // Birthday alert overlay
            if lifecycle.showBirthdayAlert && !lifecycle.showDeathAlert {
                Color.black.opacity(0.7).ignoresSafeArea()
                BirthdayAlertView(age: lifecycle.currentAge) {
                    lifecycle.dismissBirthdayAlert()
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            // Death alert overlay - player died without prestiging
            if lifecycle.showDeathAlert {
                Color.black.opacity(0.9).ignoresSafeArea()
                DeathAlertView(
                    age: lifecycle.currentAge,
                    yearsPlayed: lifecycle.gameYearsPassed,
                    netWorth: game.netWorth,
                    totalEarned: game.totalEarned
                ) {
                    // Restart the game from scratch (no prestige bonuses carried over)
                    lifecycle.processDeath()
                    lifecycle.fullReset()
                    game.resetGame()
                    // Reset all managers
                    CompanyManager.shared.reset()
                    VentureManager.shared.reset()
                    FamilyManager.shared.reset()
                    TaxManager.shared.reset()
                    showOnboarding = true
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            // Prestige confirmation overlay
            if prestige.showPrestigeConfirmation, let preview = prestige.pendingPrestigePreview {
                Color.black.opacity(0.8).ignoresSafeArea()
                PrestigeConfirmationView(
                    preview: preview,
                    onConfirm: {
                        prestige.showPrestigeConfirmation = false
                        game.performPrestige()
                        showOnboarding = true
                    },
                    onCancel: {
                        prestige.showPrestigeConfirmation = false
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
            
            // Tap milestone celebration overlay
            if let milestone = game.currentTapMilestone {
                Color.black.opacity(0.7).ignoresSafeArea()
                TapMilestoneCelebration(milestone: milestone) {
                    withAnimation {
                        game.currentTapMilestone = nil
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onChange(of: game.currentPhase) { oldPhase, newPhase in
            if newPhase.rawValue > lastPhase.rawValue {
                unlockedPhase = newPhase
                showPhaseUnlock = true
                lastPhase = newPhase
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        showPhaseUnlock = false
                    }
                }
            }
        }
    }
    
    var mainGameView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 12) {
                    // Header: Phase & Resources
                    headerSection
                    
                    // Next Milestone Progress
                    milestoneProgressSection
                    
                    // Wealth Dimensions Overview
                    wealthDimensionsSection
                    
                    // Energy Bar
                    EnergyBarView(compact: false)
                    
                    // News Ticker
                    if let headline = newsFeed.displayedHeadline {
                        newsTickerSection(headline)
                    }
                    
                    // Tap Area (compact)
                    tapSection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Auto-Tappers
                    if !game.availableAutoTappers.isEmpty {
                        autoTapperSection
                    }
                    
                    // Family Panel
                    if lifecycle.currentAge >= 25 || family.state.isMarried {
                        FamilyPanelView()
                    }
                    
                    // Factions (collapsible)
                    factionSection
                    
                    // Company Dashboard (Phase 3+)
                    if game.currentPhase.rawValue >= GamePhase.portfolioEngine.rawValue || company.state.totalEmployees > 0 {
                        companySection
                    }
                    
                    // Billionaire Leaderboard (when net worth > $1M)
                    if game.netWorth >= 1_000_000 {
                        leaderboardSection
                    }
                    
                    // Career (Phase 2+)
                    if game.currentPhase.rawValue >= GamePhase.careerLeverage.rawValue || game.selectedCareer != nil {
                        careerSection
                    }
                    
                    // Opportunity Card
                    if let opportunity = game.currentOpportunity {
                        opportunitySection(opportunity)
                    }
                    
                    // Investments (collapsible)
                    if !game.availableInvestments.isEmpty {
                        investmentSection
                    }
                    
                    // Upgrades (collapsible)
                    if !game.availableUpgrades.isEmpty {
                        upgradeSection
                    }
                    
                    // Products (Phase 3+, collapsible)
                    if game.currentPhase.rawValue >= GamePhase.portfolioEngine.rawValue && !game.availableProducts.isEmpty {
                        productSection
                    }
                    
                    // Contacts / Meetings (collapsible)
                    if !game.availableContacts.isEmpty {
                        contactSection
                    }
                    
                    // Retirement Button
                    if lifecycle.canRetire {
                        retirementSection
                    }
                    
                    // Stats
                    statsSection
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
            }
            
            // Family event overlay
            if family.showEventUI, let event = family.currentEvent {
                Color.black.opacity(0.8).ignoresSafeArea()
                FamilyEventAlertView(event: event) { choice in
                    // Deduct cash cost
                    if choice.cashCost > 0 && game.cash >= choice.cashCost {
                        game.cash -= choice.cashCost
                    }
                    family.handleEventChoice(choice, event: event)
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            // Life reflection overlay
            if reflection.showReflection {
                LifeReflectionView { ending in
                    prestige.state.lastEnding = ending
                    game.performPrestige()
                    reflection.reset()
                    showOnboarding = true
                }
            }
            
            // Insufficient energy alert
            if energy.showInsufficientEnergyAlert {
                Color.black.opacity(0.6).ignoresSafeArea()
                InsufficientEnergyAlert {
                    energy.showInsufficientEnergyAlert = false
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            // Phase unlock overlay
            if showPhaseUnlock, let phase = unlockedPhase {
                phaseUnlockOverlay(phase)
            }
            
            // Opportunity result overlay
            if let result = showOpportunityResult {
                opportunityResultOverlay(result)
            }
        }
        .sheet(isPresented: $showCareerPicker) {
            CareerPickerView(game: game, isPresented: $showCareerPicker)
        }
        .sheet(isPresented: $showInvestSheet) {
            if let investment = selectedInvestment {
                InvestmentSheetView(game: game, investment: investment, isPresented: $showInvestSheet)
            }
        }
    }
    
    // MARK: - Header Section
    
    var headerSection: some View {
        VStack(spacing: 8) {
            // CEO Title & Identity Row
            ceoTitleSection
            
            // Top row: Phase + Age + Lives
            HStack {
                // Phase
                HStack(spacing: 6) {
                    Text(game.currentPhase.icon)
                        .font(.system(size: 18))
                    Text("Phase \(game.currentPhase.rawValue)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Credit Score (compact)
                CreditScoreView(compact: true)
                
                // Age display
                AgeDisplayView()
                
                // Lives counter
                LivesCounterView()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(accentColor.opacity(0.1))
            )
            
            // Phase progress (compact)
            if let nextPhase = game.nextPhase {
                HStack(spacing: 8) {
                    Text("Next:")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 4)
                            
                            Capsule()
                                .fill(accentColor)
                                .frame(width: max(4, geometry.size.width * game.phaseProgress), height: 4)
                        }
                    }
                    .frame(height: 4)
                    
                    Text(game.formatCompact(nextPhase.unlockRequirement))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(accentColor)
                }
                .padding(.horizontal, 8)
            }
            
            // Resources row (compact horizontal)
            HStack(spacing: 8) {
                resourceBadgeCompact(icon: "💵", value: game.formatCompact(game.cash))
                resourceBadgeCompact(icon: "⭐", value: "\(game.statusPoints)")
                resourceBadgeCompact(icon: "📈", value: "\(game.formatCompact(game.passiveIncomePerSecond * LifeCycleConstants.secondsPerGameYear))/yr")
                if game.totalAutoTapsPerSecond > 0 {
                    resourceBadgeCompact(icon: "🤖", value: "\(Int(game.totalAutoTapsPerSecond))/s")
                }
            }
        }
    }
    
    // MARK: - CEO Title Display
    
    var ceoTitleSection: some View {
        HStack(spacing: 12) {
            // CEO Title
            HStack(spacing: 6) {
                Text(game.ceoTitle.icon)
                    .font(.system(size: 20))
                VStack(alignment: .leading, spacing: 2) {
                    Text(game.ceoTitle.rawValue.uppercased())
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(game.ceoTitle.color)
                    Text(game.ceoTitle.description)
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Hustle Score
            VStack(alignment: .trailing, spacing: 2) {
                Text("HUSTLE")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.orange)
                    .tracking(1)
                HStack(spacing: 4) {
                    Text("💪")
                        .font(.system(size: 10))
                    Text("\(game.hustleScore)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            // Net Worth
            VStack(alignment: .trailing, spacing: 2) {
                Text("NET WORTH")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.green)
                    .tracking(1)
                Text(game.formatCompact(game.netWorth))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            game.ceoTitle.color.opacity(0.15),
                            Color.clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(game.ceoTitle.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    func resourceBadgeCompact(icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(icon)
                .font(.system(size: 14))
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Milestone Progress
    
    var milestoneProgressSection: some View {
        Group {
            if let milestone = achievements.nextMilestone(currentNetWorth: game.netWorth) {
                VStack(spacing: 6) {
                    HStack {
                        Text("🎯")
                            .font(.system(size: 12))
                        Text("NEXT MILESTONE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.yellow)
                            .tracking(1)
                        Spacer()
                        Text(milestone.name)
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.white)
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 8)
                            
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.yellow, accentColor]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * milestone.progress, height: 8)
                        }
                    }
                    .frame(height: 8)
                    
                    HStack {
                        Text(game.formatCompact(game.netWorth))
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("\(Int(milestone.progress * 100))%")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(accentColor)
                        
                        Spacer()
                        
                        Text(game.formatCompact(milestone.target))
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.yellow.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
                        )
                )
            } else {
                // All milestones complete!
                HStack {
                    Text("🏆")
                        .font(.system(size: 24))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ALL MILESTONES COMPLETE")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(.yellow)
                        Text("You've conquered the wealth ladder!")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.yellow.opacity(0.1))
                )
            }
        }
    }
    
    // MARK: - News Ticker
    
    func newsTickerSection(_ headline: NewsItem) -> some View {
        HStack(spacing: 6) {
            Text(headline.category.icon)
                .font(.system(size: 10))
            Text(headline.headline)
                .font(.system(size: 11))
                .foregroundColor(.gray)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.03))
        )
    }
    
    // MARK: - Tap Section (Compact)
    
    var tapSection: some View {
        VStack(spacing: 8) {
            // Daily sales indicator
            HStack(spacing: 6) {
                Text("📊")
                    .font(.system(size: 12))
                Text("Sales Today:")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
                Text("\(game.dailySales)/\(game.dailySalesLimit)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(game.canMakeSale ? accentColor : .red)
                
                Spacer()
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                        Capsule()
                            .fill(game.canMakeSale ? accentColor : Color.red)
                            .frame(width: geometry.size.width * CGFloat(game.salesProgress))
                    }
                }
                .frame(width: 60, height: 4)
                
                if !game.canMakeSale {
                    Text("Wait for reset")
                        .font(.system(size: 8))
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.03))
            )
            
            // Tap button - compact
            Button(action: { 
                game.tap()
                if game.canMakeSale {
                    FeedbackCoordinator.shared.tap()
                }
            }) {
                HStack(spacing: 12) {
                    Text(game.canMakeSale ? "💰" : "⏳")
                        .font(.system(size: 40))
                        .opacity(game.canMakeSale ? 1 : 0.5)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(game.canMakeSale ? "TAP TO EARN" : "DAILY LIMIT REACHED")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(game.canMakeSale ? .white : .red)
                            .tracking(1)
                        
                        Text("+\(game.formatCompact(game.tapValue))")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(game.canMakeSale ? accentColor : .gray)
                    }
                    
                    Spacer()
                    
                    // Streak indicator inline
                    if game.currentStreak > 0 {
                        VStack(spacing: 2) {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.orange)
                                Text("\(game.currentStreak)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.orange)
                            }
                            if game.streakMultiplier > 1 {
                                Text("\(Int(game.streakMultiplier))x")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.yellow)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange.opacity(0.15))
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill((game.canMakeSale ? accentColor : Color.gray).opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke((game.canMakeSale ? accentColor : Color.gray).opacity(0.4), lineWidth: 2)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!game.canMakeSale)
        }
    }
    
    // MARK: - Auto-Tapper Section
    
    var autoTapperSection: some View {
        VStack(spacing: 8) {
            collapsibleSectionHeader(
                title: "AUTO-TAPPERS",
                icon: "🤖",
                count: game.autoTappers.filter { $0.owned }.count,
                isExpanded: $autoTappersExpanded
            )
            
            if autoTappersExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(game.availableAutoTappers) { tapper in
                            autoTapperCard(tapper)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
    
    func autoTapperCard(_ tapper: AutoTapper) -> some View {
        VStack(spacing: 6) {
            Text(tapper.icon)
                .font(.system(size: 24))
            
            Text(tapper.name)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
            
            if tapper.owned {
                Text("Lvl \(tapper.level + 1)")
                    .font(.system(size: 9))
                    .foregroundColor(accentColor)
                
                Text("\(Int(tapper.currentTapsPerSecond))/s")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                
                Button(action: { _ = game.upgradeAutoTapper(tapper.id) }) {
                    Text(game.formatCompact(tapper.upgradeCost))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(game.cash >= tapper.upgradeCost ? .black : .gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(game.cash >= tapper.upgradeCost ? accentColor : Color.gray.opacity(0.3))
                        )
                }
            } else {
                Text("\(Int(tapper.baseTapsPerSecond))/s")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                
                Button(action: { _ = game.purchaseAutoTapper(tapper.id) }) {
                    Text(game.formatCompact(tapper.baseCost))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(game.cash >= tapper.baseCost ? .black : .gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(game.cash >= tapper.baseCost ? accentColor : Color.gray.opacity(0.3))
                        )
                }
            }
        }
        .frame(width: 80)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(tapper.owned ? accentColor.opacity(0.1) : Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(tapper.owned ? accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
    
    // MARK: - Career Section
    
    var careerSection: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "CAREER", icon: "💼")
            
            if let career = game.selectedCareer, let role = game.currentRole {
                // Current role
                HStack {
                    Text(career.icon)
                        .font(.system(size: 32))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(role.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Text("Salary: \(game.formatCurrency(role.salary))/yr")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Text("Next meeting: \(role.meetingUnlock)")
                            .font(.system(size: 11))
                            .foregroundColor(accentColor)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                )
                
                // Promotion button
                if let nextRole = game.nextRole {
                    Button(action: {
                        if game.promote() {
                            // Could show promotion animation
                        }
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("PROMOTE TO")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.gray)
                                Text(nextRole.title)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Text(game.formatCompact(game.promotionCost))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(game.cash >= game.promotionCost ? accentColor : .gray)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(accentColor.opacity(game.cash >= game.promotionCost ? 0.15 : 0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(accentColor.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .disabled(game.cash < game.promotionCost)
                }
            } else {
                // Career picker prompt
                Button(action: { showCareerPicker = true }) {
                    HStack {
                        Text("🎯")
                            .font(.system(size: 24))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CHOOSE YOUR PATH")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            Text("Select a career to unlock bonuses")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(accentColor)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(accentColor.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(accentColor.opacity(0.4), lineWidth: 1)
                            )
                    )
                }
            }
        }
    }
    
    // MARK: - Opportunity Section
    
    func opportunitySection(_ opportunity: OpportunityCard) -> some View {
        VStack(spacing: 12) {
            sectionHeader(title: "OPPORTUNITY", icon: "🎲")
            
            VStack(spacing: 12) {
                HStack {
                    Text(opportunity.icon)
                        .font(.system(size: 32))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(opportunity.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Text(opportunity.description)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                
                // Stats - showing SCALED values
                HStack(spacing: 16) {
                    VStack {
                        Text("Cost")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        Text(game.formatCompact(game.scaleReward(opportunity.cost)))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack {
                        Text("Success")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        Text("\(Int((opportunity.successChance + game.opportunityBonusChance) * 100))%")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.yellow)
                    }
                    
                    VStack {
                        Text("Reward")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        Text(game.formatCompact(game.scaledOpportunityReward(opportunity.successReward)))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(accentColor)
                    }
                    
                    VStack {
                        Text("Status")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        Text("+\(opportunity.statusBonus)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.purple)
                    }
                }
                
                // Action buttons
                HStack(spacing: 12) {
                    Button(action: {
                        let result = game.takeOpportunity(false)
                        if let r = result {
                            showOpportunityResult = r
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showOpportunityResult = nil
                            }
                        }
                    }) {
                        Text("Pass")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                    
                    Button(action: {
                        let result = game.takeOpportunity(true)
                        if let r = result {
                            showOpportunityResult = r
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showOpportunityResult = nil
                            }
                        }
                    }) {
                        Text("Take It")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(game.cash >= game.scaleReward(opportunity.cost) ? accentColor : Color.gray)
                            )
                    }
                    .disabled(game.cash < game.scaleReward(opportunity.cost))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.yellow.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Investment Section
    
    var investmentSection: some View {
        VStack(spacing: 8) {
            collapsibleSectionHeader(
                title: "INVESTMENTS",
                icon: "📊",
                count: game.investments.filter { $0.amountInvested > 0 }.count,
                isExpanded: $investmentsExpanded
            )
            
            // Total investment value summary
            if game.totalInvestmentValue > 0 {
                HStack {
                    Text("Total:")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    Text(game.formatCompact(game.totalInvestmentValue))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                    if game.totalUnrealizedGains > 0 {
                        Text("(+\(game.formatCompact(game.totalUnrealizedGains)))")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(accentColor)
                    }
                    Spacer()
                }
                .padding(.horizontal, 8)
            }
            
            if investmentsExpanded {
                ForEach(game.availableInvestments) { investment in
                    Button(action: {
                        selectedInvestment = investment
                        showInvestSheet = true
                    }) {
                        HStack {
                            Text(investment.icon)
                                .font(.system(size: 20))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(investment.name)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                
                                HStack(spacing: 6) {
                                    Text("\(Int(investment.baseReturn * 100))%/yr")
                                        .font(.system(size: 10))
                                        .foregroundColor(accentColor)
                                    
                                    Text(investment.riskLevel.rawValue)
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(investment.riskLevel.color)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(investment.riskLevel.color.opacity(0.2))
                                        .cornerRadius(3)
                                }
                            }
                            
                            Spacer()
                            
                            if investment.amountInvested > 0 {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(game.formatCompact(investment.totalValue))
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                    if investment.unrealizedGains != 0 {
                                        Text(investment.formattedGains)
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(investment.unrealizedGains >= 0 ? accentColor : .red)
                                    }
                                }
                            }
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )
                }
            }
            }
        }
    }
    
    // MARK: - Upgrade Section
    
    var upgradeSection: some View {
        VStack(spacing: 8) {
            collapsibleSectionHeader(
                title: "UPGRADES",
                icon: "⬆️",
                count: game.availableUpgrades.count,
                isExpanded: $upgradesExpanded
            )
            
            if upgradesExpanded {
                ForEach(game.availableUpgrades) { upgrade in
                    Button(action: {
                        _ = game.purchaseUpgrade(upgrade.id)
                        FeedbackCoordinator.shared.purchase()
                    }) {
                        HStack {
                            Text(upgrade.icon)
                                .font(.system(size: 20))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(upgrade.name)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                Text(upgrade.description)
                                    .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Text(game.formatCompact(upgrade.cost))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(game.cash >= upgrade.cost ? accentColor : .gray)
                    }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(game.cash >= upgrade.cost ? accentColor.opacity(0.1) : Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(game.cash >= upgrade.cost ? accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
                                )
                        )
                    }
                    .disabled(game.cash < upgrade.cost)
                }
            }
        }
    }
    
    // MARK: - Product Section
    
    var productSection: some View {
        VStack(spacing: 8) {
            collapsibleSectionHeader(
                title: "PRODUCT LAUNCHES",
                icon: "🚀",
                count: game.availableProducts.count,
                isExpanded: $productsExpanded
            )
            
            if productsExpanded {
                ForEach(game.availableProducts) { product in
                    Button(action: {
                        let result = game.launchProduct(product.id)
                        showOpportunityResult = result
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            showOpportunityResult = nil
                        }
                    }) {
                        HStack {
                            Text(product.icon)
                                .font(.system(size: 20))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(product.name)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                
                                HStack(spacing: 6) {
                                    Text("\(Int(product.successChance * 100))%")
                                        .font(.system(size: 10))
                                        .foregroundColor(.yellow)
                                    Text("+\(game.formatCompact(product.ongoingRevenue))/s")
                                        .font(.system(size: 10))
                                        .foregroundColor(accentColor)
                                }
                            }
                            
                            Spacer()
                            
                            let totalCost = product.developmentCost + product.marketingCost
                            Text(game.formatCompact(totalCost))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(game.cash >= totalCost ? accentColor : .gray)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.purple.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .disabled(game.cash < product.developmentCost + product.marketingCost)
                }
            }
        }
    }
    
    // MARK: - Contact Section
    
    var contactSection: some View {
        VStack(spacing: 8) {
            collapsibleSectionHeader(
                title: "NETWORKING",
                icon: "🤝",
                count: game.availableContacts.count,
                isExpanded: $contactsExpanded
            )
            
            if contactsExpanded {
                ForEach(game.availableContacts) { contact in
                    Button(action: {
                        let result = game.meetContact(contact.id)
                        if result.success {
                            if result.lawsuitTriggered {
                                FeedbackCoordinator.shared.warning()
                            } else {
                                FeedbackCoordinator.shared.purchase()
                            }
                        }
                    }) {
                        HStack {
                            Text(contact.icon)
                                .font(.system(size: 20))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(contact.name)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                Text(contact.title)
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Text("+\(game.formatCompact(contact.bonusOnMeet))")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(accentColor)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Wealth Dimensions Section
    
    var wealthDimensionsSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("💎")
                    .font(.system(size: 12))
                Text("LIFE WEALTH")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
                    .tracking(1.5)
                Spacer()
                if wealth.state.isBalanced {
                    Text("⚖️ Balanced")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.green)
                }
            }
            
            WealthOverviewView()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.03))
        )
    }
    
    // MARK: - Quick Actions Section
    
    var quickActionsSection: some View {
        VStack(spacing: 8) {
            collapsibleSectionHeader(
                title: "LIFE ACTIONS",
                icon: "⚡",
                count: 0,
                isExpanded: $actionsExpanded
            )
            
            if actionsExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ActionButtonView(action: .familyTime) {
                            game.performAction(.familyTime)
                        }
                        ActionButtonView(action: .rest) {
                            game.performAction(.rest)
                        }
                        ActionButtonView(action: .exercise) {
                            game.performAction(.exercise)
                        }
                        ActionButtonView(action: .workOvertime) {
                            game.performAction(.workOvertime)
                        }
                        ActionButtonView(action: .philanthropy) {
                            game.performAction(.philanthropy)
                        }
                        ActionButtonView(action: .vacation) {
                            game.performAction(.vacation)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.03))
        )
    }
    
    // MARK: - Faction Section
    
    var factionSection: some View {
        VStack(spacing: 8) {
            collapsibleSectionHeader(
                title: "FACTIONS",
                icon: "🏛️",
                count: 4,
                isExpanded: $factionsExpanded
            )
            
            if factionsExpanded {
                FactionsOverviewView(compact: false)
            } else {
                FactionsOverviewView(compact: true)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.03))
        )
    }
    
    // MARK: - Company Section
    
    @State private var showCompanyInvestSheet = false
    @State private var companyInvestAmount: String = ""
    
    var companySection: some View {
        VStack(spacing: 8) {
            collapsibleSectionHeader(
                title: "YOUR EMPIRE",
                icon: "🏢",
                count: company.state.totalEmployees,
                isExpanded: $companyExpanded
            )
            
            if companyExpanded {
                CompanyDashboardView(playerNetWorth: game.netWorth)
                
                // Invest in Company Button
                Button(action: { showCompanyInvestSheet = true }) {
                    HStack {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 14))
                        Text("Invest in \(company.state.name)")
                            .font(.system(size: 12, weight: .bold))
                        Spacer()
                        Text("Grow Your Company")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                            )
                    )
                }
                .sheet(isPresented: $showCompanyInvestSheet) {
                    CompanyInvestmentSheet(game: game, isPresented: $showCompanyInvestSheet)
                }
                
                // Hire Employees
                HireEmployeesView(cash: game.cash) { categoryId, cost in
                    if game.cash >= cost {
                        game.cash -= cost
                        return true
                    }
                    return false
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.03))
        )
    }
    
    // MARK: - Leaderboard Section
    
    var leaderboardSection: some View {
        VStack(spacing: 8) {
            collapsibleSectionHeader(
                title: "BILLIONAIRE RANKINGS",
                icon: "🏆",
                count: company.getPlayerRank(playerNetWorth: game.netWorth),
                isExpanded: $leaderboardExpanded
            )
            
            if leaderboardExpanded {
                BillionaireLeaderboardView(playerNetWorth: game.netWorth)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.03))
        )
    }
    
    // MARK: - Stats Section
    
    var statsSection: some View {
        VStack(spacing: 8) {
            sectionHeader(title: "STATISTICS", icon: "📈")
            
            VStack(spacing: 6) {
                // Life stats
                statRow(label: "Age", value: "\(lifecycle.currentAge) years old")
                statRow(label: "Years Played", value: "\(lifecycle.gameYearsPassed)")
                statRow(label: "Work/Life Balance", value: "\(Int(game.workTimePercent))% work")
                
                Divider().background(Color.white.opacity(0.1))
                
                // Wealth dimension stats
                statRow(label: "Financial Score", value: "\(wealth.state.financial)/100", highlight: wealth.state.financial >= 70)
                statRow(label: "Relationships", value: "\(wealth.state.relationships)/100", highlight: wealth.state.relationships >= 70)
                statRow(label: "Experiences", value: "\(wealth.state.experiences)/100", highlight: wealth.state.experiences >= 70)
                statRow(label: "Health", value: "\(wealth.state.health)/100", highlight: wealth.state.health >= 70)
                statRow(label: "Legacy", value: "\(wealth.state.legacy)/100", highlight: wealth.state.legacy >= 70)
                
                Divider().background(Color.white.opacity(0.1))
                
                // Financial stats
                statRow(label: "Total Earned", value: game.formatCompact(game.totalEarned))
                statRow(label: "Investments", value: game.formatCompact(game.totalInvestmentValue))
                statRow(label: "Total Taps", value: "\(game.totalTaps)")
                statRow(label: "Auto-Tap Rate", value: "\(Int(game.totalAutoTapsPerSecond))/sec")
                
                Divider().background(Color.white.opacity(0.1))
                
                // Family stats
                statRow(label: "Family Size", value: "\(family.state.familySize)")
                if family.state.isMarried {
                    statRow(label: "Married", value: "Yes 💍")
                }
                if !family.state.children.isEmpty {
                    statRow(label: "Children", value: "\(family.state.children.count)")
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                // Multipliers
                statRow(label: "Tap Value", value: game.formatCompact(game.tapValue))
                statRow(label: "Streak Mult", value: String(format: "%.1fx", game.streakMultiplier))
                if prestige.hasPrestiged {
                    statRow(label: "Legacy Mult", value: prestige.formattedMultiplier, highlight: true)
                    statRow(label: "Lives Lived", value: "\(prestige.livesLived)", highlight: true)
                }
                
                if game.selectedCareer != nil, let role = game.currentRole {
                    Divider().background(Color.white.opacity(0.1))
                    statRow(label: "Career", value: role.title)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.03))
            )
        }
    }
    
    func statRow(label: String, value: String, highlight: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(highlight ? accentColor : .white)
        }
    }
    
    // MARK: - Retirement Section
    
    var retirementSection: some View {
        VStack(spacing: 8) {
            Button(action: {
                // Calculate prestige preview
                let preview = prestige.calculatePrestigePreview(
                    currentEarnings: game.totalEarned,
                    currentAge: lifecycle.currentAge,
                    yearsPlayed: lifecycle.gameYearsPassed
                )
                prestige.pendingPrestigePreview = preview
                prestige.showPrestigeConfirmation = true
            }) {
                HStack(spacing: 12) {
                    Text("🌟")
                        .font(.system(size: 24))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("RETIRE & START NEW LIFE")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Carry your legacy forward")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Age \(lifecycle.currentAge)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(accentColor)
                        
                        if lifecycle.mustRetire {
                            Text("Required")
                                .font(.system(size: 9))
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [accentColor.opacity(0.2), accentColor.opacity(0.1)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(accentColor.opacity(0.5), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Helpers
    
    func sectionHeader(title: String, icon: String) -> some View {
        HStack {
            Text(icon)
                .font(.system(size: 14))
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.gray)
                .tracking(1.5)
            Spacer()
        }
    }
    
    func collapsibleSectionHeader(title: String, icon: String, count: Int, isExpanded: Binding<Bool>) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.wrappedValue.toggle()
            }
        }) {
            HStack {
                Text(icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.gray)
                    .tracking(1.5)
                
                if count > 0 {
                    Text("(\(count))")
                        .font(.system(size: 10))
                        .foregroundColor(accentColor)
                }
                
                Spacer()
                
                Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Overlays
    
    func phaseUnlockOverlay(_ phase: GamePhase) -> some View {
        VStack(spacing: 16) {
            Text(phase.icon)
                .font(.system(size: 80))
            
            Text("PHASE \(phase.rawValue) UNLOCKED")
                .font(.system(size: 24, weight: .black))
                .foregroundColor(.white)
                .tracking(2)
            
            Text(phase.name)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(accentColor)
            
            Text(phase.description)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(accentColor, lineWidth: 2)
                )
                .shadow(color: accentColor.opacity(0.5), radius: 30)
        )
        .transition(.scale.combined(with: .opacity))
    }
    
    func opportunityResultOverlay(_ result: (success: Bool, message: String)) -> some View {
        VStack(spacing: 12) {
            Text(result.success ? "✅" : "❌")
                .font(.system(size: 48))
            
            Text(result.message)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(result.success ? Color.green.opacity(0.9) : Color.red.opacity(0.9))
        )
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Career Picker View

struct CareerPickerView: View {
    @ObservedObject var game: GameState
    @Binding var isPresented: Bool
    
    let accentColor = Color(red: 0.4, green: 0.7, blue: 0.4)
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Choose Your Path")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Each career offers unique bonuses and progression")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                ForEach(CareerPath.allCases, id: \.self) { career in
                    Button(action: {
                        game.selectCareer(career)
                        isPresented = false
                    }) {
                        HStack {
                            Text(career.icon)
                                .font(.system(size: 32))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(career.rawValue)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                Text(career.description)
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                Text("\(Int((career.incomeMultiplier - 1) * 100))% income bonus")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(accentColor)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(accentColor)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(accentColor.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(accentColor.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Investment Sheet View

struct InvestmentSheetView: View {
    @ObservedObject var game: GameState
    let investment: Investment
    @Binding var isPresented: Bool
    @State private var amount: String = ""
    @State private var selectedTab: Int = 0  // 0 = Deposit, 1 = Withdraw
    
    let accentColor = Color(red: 0.4, green: 0.7, blue: 0.4)
    
    // Get the current investment from game state (for live updates)
    var currentInvestment: Investment {
        game.investments.first { $0.id == investment.id } ?? investment
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text(investment.icon)
                        .font(.system(size: 36))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(investment.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        Text(investment.description)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                }
                
                // Account Value Card
                VStack(spacing: 8) {
                    Text("ACCOUNT VALUE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                        .tracking(1)
                    
                    Text(game.formatCompact(currentInvestment.totalValue))
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 16) {
                        VStack(spacing: 2) {
                            Text("Principal")
                                .font(.system(size: 9))
                                .foregroundColor(.gray)
                            Text(game.formatCompact(currentInvestment.amountInvested))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 2) {
                            Text("Gains/Losses")
                                .font(.system(size: 9))
                                .foregroundColor(.gray)
                            Text(currentInvestment.formattedGains)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(currentInvestment.unrealizedGains >= 0 ? accentColor : .red)
                        }
                        
                        VStack(spacing: 2) {
                            Text("Return")
                                .font(.system(size: 9))
                                .foregroundColor(.gray)
                            Text("\(Int(investment.baseReturn * 100))%/yr")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(accentColor)
                        }
                        
                        VStack(spacing: 2) {
                            Text("Risk")
                                .font(.system(size: 9))
                                .foregroundColor(.gray)
                            Text(investment.riskLevel.rawValue)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(investment.riskLevel.color)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                )
                
                // Deposit / Withdraw Tabs
                HStack(spacing: 0) {
                    tabButton(title: "Deposit", icon: "arrow.down.circle.fill", index: 0)
                    tabButton(title: "Withdraw", icon: "arrow.up.circle.fill", index: 1)
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.05))
                )
                
                // Amount Input
                VStack(spacing: 10) {
                    HStack {
                        Text(selectedTab == 0 ? "Available Cash:" : "Available to Withdraw:")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Spacer()
                        Text(game.formatCompact(selectedTab == 0 ? game.cash : currentInvestment.totalValue))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Text("$")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.gray)
                        TextField("0", text: $amount)
                            .keyboardType(.numberPad)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
                    
                    // Quick buttons
                    HStack(spacing: 8) {
                        if selectedTab == 0 {
                            // Deposit quick buttons
                            quickButton(label: "Min", value: investment.minInvestment)
                            quickButton(label: "25%", value: game.cash * 0.25)
                            quickButton(label: "50%", value: game.cash * 0.5)
                            quickButton(label: "All", value: game.cash)
                        } else {
                            // Withdraw quick buttons
                            quickButton(label: "25%", value: currentInvestment.totalValue * 0.25)
                            quickButton(label: "50%", value: currentInvestment.totalValue * 0.5)
                            quickButton(label: "75%", value: currentInvestment.totalValue * 0.75)
                            quickButton(label: "All", value: currentInvestment.totalValue)
                        }
                    }
                }
                
                Spacer()
                
                // Action Button
                Button(action: performAction) {
                    HStack {
                        Image(systemName: selectedTab == 0 ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                        Text(selectedTab == 0 ? "Deposit Funds" : "Withdraw Funds")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(selectedTab == 0 ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedTab == 0 ? accentColor : Color.orange)
                    )
                }
                .disabled(!canPerformAction)
                .opacity(canPerformAction ? 1 : 0.5)
            }
            .padding()
        }
    }
    
    var canPerformAction: Bool {
        guard let value = Double(amount), value > 0 else { return false }
        if selectedTab == 0 {
            return value >= investment.minInvestment && value <= game.cash
        } else {
            return value <= currentInvestment.totalValue
        }
    }
    
    func performAction() {
        guard let value = Double(amount), value > 0 else { return }
        
        if selectedTab == 0 {
            // Deposit
            if game.invest(in: investment.id, amount: value) {
                HapticManager.shared.success()
                amount = ""
            }
        } else {
            // Withdraw
            let withdrawn = game.withdraw(from: investment.id, amount: value)
            if withdrawn > 0 {
                HapticManager.shared.success()
                amount = ""
            }
        }
    }
    
    func tabButton(title: String, icon: String, index: Int) -> some View {
        Button(action: {
            selectedTab = index
            amount = ""
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundColor(selectedTab == index ? (index == 0 ? accentColor : .orange) : .gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedTab == index ? Color.white.opacity(0.1) : Color.clear)
            )
        }
    }
    
    func quickButton(label: String, value: Double) -> some View {
        Button(action: {
            amount = String(Int(max(0, value)))
        }) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(selectedTab == 0 ? accentColor : .orange)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill((selectedTab == 0 ? accentColor : Color.orange).opacity(0.15))
                )
        }
    }
}

// MARK: - Company Investment Sheet

struct CompanyInvestmentSheet: View {
    @ObservedObject var game: GameState
    @ObservedObject var company = CompanyManager.shared
    @Binding var isPresented: Bool
    @State private var amount: String = ""
    
    let accentColor = Color(red: 0.4, green: 0.7, blue: 0.4)
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("🏢")
                        .font(.system(size: 36))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Invest in \(company.state.name)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text("Grow your company's capital and valuation")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                }
                
                // Company Stats
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        statCard(title: "Capital Raised", value: game.formatCompact(company.state.totalCapitalRaised), icon: "💰")
                        statCard(title: "Valuation", value: game.formatCompact(company.state.companyValuation), icon: "📊")
                    }
                    
                    HStack(spacing: 16) {
                        statCard(title: "Employees", value: "\(company.state.totalEmployees)", icon: "👥")
                        statCard(title: "Industries", value: "\(company.state.industries.count)", icon: "🌍")
                    }
                }
                
                Divider().background(Color.white.opacity(0.2))
                
                // Investment Amount
                VStack(spacing: 10) {
                    HStack {
                        Text("Available Cash:")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Spacer()
                        Text(game.formatCompact(game.cash))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Text("$")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.gray)
                        TextField("0", text: $amount)
                            .keyboardType(.numberPad)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
                    
                    // Quick buttons
                    HStack(spacing: 8) {
                        quickButton(label: "$1K", value: 1000)
                        quickButton(label: "$10K", value: 10000)
                        quickButton(label: "$100K", value: 100000)
                        quickButton(label: "All", value: game.cash)
                    }
                    
                    Text("Minimum investment: $1,000")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // What You Get
                VStack(alignment: .leading, spacing: 6) {
                    Text("INVESTMENT BENEFITS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                        .tracking(1)
                    
                    benefitRow(icon: "📈", text: "Increases company valuation")
                    benefitRow(icon: "💼", text: "Counts as a completed trade deal")
                    benefitRow(icon: "🏆", text: "Helps you climb the billionaire rankings")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue.opacity(0.1))
                )
                
                // Invest Button
                Button(action: investInCompany) {
                    HStack {
                        Image(systemName: "building.2.fill")
                        Text("Invest in Company")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(canInvest ? Color.blue : Color.gray)
                    )
                }
                .disabled(!canInvest)
            }
            .padding()
        }
    }
    
    var canInvest: Bool {
        guard let value = Double(amount), value >= 1000, value <= game.cash else { return false }
        return true
    }
    
    func investInCompany() {
        guard let value = Double(amount), value >= 1000 else { return }
        
        if game.investInCompany(amount: value) {
            HapticManager.shared.success()
            amount = ""
        }
    }
    
    func statCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.system(size: 20))
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            Text(title)
                .font(.system(size: 9))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    func quickButton(label: String, value: Double) -> some View {
        Button(action: {
            amount = String(Int(max(1000, min(value, game.cash))))
        }) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue.opacity(0.15))
                )
        }
    }
    
    func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 12))
            Text(text)
                .font(.system(size: 11))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Splash Screen

struct SplashScreen: View {
    @State private var rotation: Double = -180
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(color: Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.6), radius: 30)
                .rotationEffect(.degrees(rotation))
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .onAppear {
            // Spin in and scale up
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                rotation = 0
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

#Preview {
    ContentView()
}
