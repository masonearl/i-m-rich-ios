//
//  ZonedGameView.swift
//  Life of Wealth
//
//  Main game view with zone-based navigation
//  Core Goal: Race to become the world's first trillionaire
//

import SwiftUI

struct ZonedGameView: View {
    @ObservedObject var game: GameState
    @State private var selectedZone: GameZone = .hustle
    
    // Managers
    @ObservedObject private var lifecycle = LifeCycleManager.shared
    @ObservedObject private var credit = CreditManager.shared
    @ObservedObject private var partnerships = PartnershipManager.shared
    
    // Use new color palette
    let accentColor = AppColors.mattGreen
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact Header: Stats + Progress combined
            CompactHeader(game: game, lifecycle: lifecycle)
                .padding(.horizontal, 12)
                .padding(.top, 4)
            
            // Zone Content
            TabView(selection: $selectedZone) {
                ForEach(GameZone.allCases, id: \.self) { zone in
                    zoneContent(for: zone)
                        .tag(zone)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Zone Tab Bar
            ZoneTabBar(selectedZone: $selectedZone, netWorth: game.netWorth, unlockedZones: game.unlockedZones)
                .padding(.horizontal, 8)
                .padding(.bottom, 6)
        }
        .background(AppColors.background.ignoresSafeArea())
        .sheet(isPresented: $showPrestigeSheet) {
            PrestigeSheet(game: game, lifecycle: lifecycle)
        }
    }
    
    @State private var showPrestigeSheet = false
    @ObservedObject private var prestigeManager = PrestigeManager.shared
    
    // MARK: - Top Bar
    
    @State private var showGameInfo = false
    @State private var showSettings = false
    
    var topBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // CEO Identity
                HStack(spacing: 8) {
                    Text(game.ceoTitle.icon)
                        .font(.system(size: 20))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(game.ceoTitle.rawValue)
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(game.ceoTitle.color)
                        Text("Age \(lifecycle.currentAge)")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Settings button
                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .sheet(isPresented: $showSettings) {
                    SettingsSheet(game: game)
                }
                
                // Help/Info button
                Button(action: { showGameInfo = true }) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .sheet(isPresented: $showGameInfo) {
                    GameInfoView(game: game)
                }
                
                // Credit Score
                CreditScoreView(compact: true)
                
                // Lives
                LivesCounterView()
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Quick Stats
            QuickStatsBar(game: game)
                .padding(.horizontal)
        }
    }
    
    // MARK: - Zone Content
    
    func isZoneUnlocked(_ zone: GameZone) -> Bool {
        game.unlockedZones.contains(zone.rawValue) || zone.isUnlocked(netWorth: game.netWorth)
    }
    
    @ViewBuilder
    func zoneContent(for zone: GameZone) -> some View {
        if isZoneUnlocked(zone) {
            ScrollView {
                VStack(spacing: 16) {
                    // Zone header
                    zoneHeader(zone)
                    
                    // Zone-specific content
                    switch zone {
                    case .hustle:
                        hustleZoneContent
                    case .career:
                        careerZoneContent
                    case .invest:
                        investZoneContent
                    case .empire:
                        empireZoneContent
                    case .legacy:
                        legacyZoneContent
                    }
                    
                    // Zone unlock progress (if not last zone)
                    if zone.nextZone != nil {
                        ZoneUnlockProgress(currentZone: zone, netWorth: game.netWorth)
                            .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.top, 8)
            }
        } else {
            ZoneLockedView(zone: zone, currentNetWorth: game.netWorth)
        }
    }
    
    func zoneHeader(_ zone: GameZone) -> some View {
        HStack {
            Text(zone.icon)
                .font(.system(size: 20))
            Text(zone.rawValue.uppercased())
                .font(.system(size: 16, weight: .black))
                .foregroundColor(zone.color)
                .tracking(2)
            Spacer()
            Text(zone.description)
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Hustle Zone Content
    
    var hustleZoneContent: some View {
        VStack(spacing: 16) {
            // Income Breakdown (shows salary vs hustle vs passive)
            IncomeBreakdownCompact(game: game)
                .padding(.horizontal)
            
            // Compact Tap Button
            CompactTapButton(game: game)
                .padding(.horizontal)
            
            // Starter Auto-Tapper unlock (after 100 taps)
            starterAutoTapperSection
            
            // Auto-Tappers (if any owned)
            if game.totalAutoTapsPerSecond > 0 {
                autoTappersSection
            }
            
            // Daily Grind
            DailyGrindSection(game: game)
                .padding(.horizontal)
            
            // Opportunities (if available)
            if game.currentOpportunity != nil {
                opportunityCard
                    .padding(.horizontal)
            }
            
            // Energy Bar
            EnergyBarView(compact: false)
                .padding(.horizontal)
            
            // Upgrades
            upgradesSection
        }
    }
    
    @ViewBuilder
    var starterAutoTapperSection: some View {
        let buddyTapper = game.autoTappers.first { $0.id == "buddy" }
        
        if let buddy = buddyTapper {
            if !buddy.owned && game.totalTaps >= 100 {
                // Show unlock card
                StarterAutoTapperCard(tapper: buddy, game: game)
                    .padding(.horizontal)
            } else if !buddy.owned && game.totalTaps < 100 {
                // Show progress to unlock
                VStack(spacing: 8) {
                    HStack {
                        Text("🔒")
                        Text("UNLOCK AT 100 TAPS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(game.totalTaps)/100")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.cyan)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                            Capsule()
                                .fill(Color.cyan)
                                .frame(width: geo.size.width * CGFloat(min(game.totalTaps, 100)) / 100)
                        }
                    }
                    .frame(height: 6)
                    
                    Text("Recruit a Buddy - Auto-taps every 3 seconds!")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.cyan.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal)
            }
        }
    }
    
    var autoTappersSection: some View {
        VStack(spacing: 10) {
            // Header
            HStack {
                Text("🤖")
                Text("AUTO-INCOME")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.cyan)
                Spacer()
                Text("\(game.formatCompact(game.totalAutoTapsPerSecond * game.tapValue))/sec")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Owned tappers with upgrade option
            ForEach(game.autoTappers.filter { $0.owned }) { tapper in
                AutoTapperRow(tapper: tapper, game: game)
            }
            
            // Available to purchase
            let availableTappers = game.autoTappers.filter { !$0.owned && game.currentPhase.rawValue >= $0.phaseUnlock.rawValue }
            if !availableTappers.isEmpty {
                Divider().background(Color.gray.opacity(0.3))
                
                Text("AVAILABLE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.gray)
                
                ForEach(availableTappers) { tapper in
                    AvailableAutoTapperRow(tapper: tapper, game: game)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
        )
        .padding(.horizontal)
    }
    
    var opportunityCard: some View {
        Group {
            if let opportunity = game.currentOpportunity {
                VStack(spacing: 12) {
                    HStack {
                        Text("⚡")
                        Text("OPPORTUNITY")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.yellow)
                        Spacer()
                    }
                    
                    Text(opportunity.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(opportunity.description)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            _ = game.takeOpportunity(false)
                        }) {
                            Text("Pass")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.1))
                                )
                        }
                        
                        Button(action: {
                            _ = game.takeOpportunity(true)
                        }) {
                            HStack {
                                Text("Take")
                                Text("-\(game.formatCompact(game.scaleReward(opportunity.cost)))")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(game.cash >= game.scaleReward(opportunity.cost) ? accentColor : Color.gray)
                            )
                        }
                        .disabled(game.cash < game.scaleReward(opportunity.cost))
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.yellow.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    var upgradesSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("⬆️")
                Text("UPGRADES")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(game.upgrades.filter { !$0.purchased && game.currentPhase.rawValue >= $0.phaseUnlock.rawValue }) { upgrade in
                        CompactUpgradeCard(upgrade: upgrade, game: game)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Career Zone Content
    
    var careerZoneContent: some View {
        VStack(spacing: 16) {
            // Current Career
            if let career = game.selectedCareer {
                currentCareerSection(career)
            } else {
                careerSelectionPrompt
            }
            
            // Tax Planning Section
            taxPlanningSection
            
            // Skills & Education would go here
            educationSection
            
            // Factions
            factionsSection
        }
        .padding(.horizontal)
    }
    
    // MARK: - Tax Planning Section
    @ObservedObject private var taxManager = TaxManager.shared
    @State private var showTaxUpgradeSheet = false
    
    var taxPlanningSection: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("🏛️")
                Text("TAX PLANNING")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(1.5)
                Spacer()
                Text("\(Int(taxManager.state.currentPlanTier.taxReduction * 100))% savings")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AppColors.mattGreen)
            }
            
            // Current Plan
            HStack(spacing: 12) {
                Text(taxManager.state.currentPlanTier.icon)
                    .font(.system(size: 28))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(taxManager.state.currentPlanTier.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Text(taxManager.state.currentPlanTier.description)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("-\(Int(taxManager.state.currentPlanTier.taxReduction * 100))%")
                        .font(.headline.bold())
                        .foregroundColor(AppColors.mattGreen)
                    if taxManager.state.currentPlanTier.annualCost > 0 {
                        Text("\(game.formatCompact(taxManager.state.currentPlanTier.annualCost))/yr")
                            .font(.caption2)
                            .foregroundColor(AppColors.warning)
                    }
                }
            }
            .padding(12)
            .background(AppColors.surfaceLight)
            .cornerRadius(10)
            
            // Estimated savings this year
            let estimatedIncome = taxManager.state.yearToDateIncome.total
            if estimatedIncome > 0 {
                HStack {
                    Text("Est. savings this year:")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text(game.formatCompact(taxManager.estimatedAnnualSavings(for: estimatedIncome)))
                        .font(.caption.bold())
                        .foregroundColor(AppColors.mattGreen)
                }
            }
            
            // Upgrade button
            if let nextTier = taxManager.nextPlanTier {
                let canAfford = game.cash >= nextTier.upgradeCost
                let meetsNetWorth = game.netWorth >= nextTier.netWorthRequired
                
                Button(action: { showTaxUpgradeSheet = true }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("⬆️ Upgrade to \(nextTier.name)")
                                .font(.system(size: 12, weight: .bold))
                            Text("\(Int(nextTier.taxReduction * 100))% tax reduction")
                                .font(.caption)
                                .foregroundColor(canAfford && meetsNetWorth ? .white.opacity(0.8) : AppColors.textMuted)
                        }
                        Spacer()
                        Text(game.formatCompact(nextTier.upgradeCost))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(canAfford ? .black : .gray)
                    }
                    .foregroundColor(canAfford && meetsNetWorth ? .black : .gray)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(canAfford && meetsNetWorth ? AppColors.mattGreen : AppColors.surfaceLight)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!canAfford || !meetsNetWorth)
                
                if !meetsNetWorth {
                    Text("🔒 Requires \(game.formatCompact(nextTier.netWorthRequired)) net worth")
                        .font(.caption2)
                        .foregroundColor(AppColors.textMuted)
                }
            } else {
                Text("✅ Maximum tax optimization achieved!")
                    .font(.caption)
                    .foregroundColor(AppColors.gold)
            }
            
            // Lifetime savings
            if taxManager.state.totalTaxSavingsLifetime > 0 {
                HStack {
                    Text("💰 Lifetime tax savings:")
                        .font(.caption)
                        .foregroundColor(AppColors.textMuted)
                    Spacer()
                    Text(game.formatCompact(taxManager.state.totalTaxSavingsLifetime))
                        .font(.caption.bold())
                        .foregroundColor(AppColors.mattGreen)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppColors.mattGreen.opacity(0.3), lineWidth: 1)
                )
        )
        .sheet(isPresented: $showTaxUpgradeSheet) {
            TaxPlanUpgradeSheet(game: game)
        }
    }
    
    func currentCareerSection(_ career: CareerPath) -> some View {
        VStack(spacing: 12) {
            careerHeader(career)
            
            // Show promotion progress OR serial entrepreneur options
            if game.isMaxCareer {
                serialEntrepreneurSection
            } else {
                promotionProgress
            }
        }
        .padding(16)
        .background(careerBackground)
    }
    
    // MARK: - Serial Entrepreneur Section (Max Career)
    @State private var showNewVentureSheet = false
    @State private var showSellCompanySheet = false
    @ObservedObject private var ventureManager = VentureManager.shared
    
    private var serialEntrepreneurSection: some View {
        VStack(spacing: 12) {
            // Congrats banner
            HStack {
                Text("👑")
                    .font(.system(size: 24))
                Text("You've reached the top!")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColors.gold)
                Spacer()
            }
            
            Text("As CEO, you can now start new ventures or sell your company.")
                .font(.system(size: 11))
                .foregroundColor(AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Current ventures summary
            if ventureManager.state.ventures.count > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    Text("YOUR VENTURES")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(AppColors.textMuted)
                    
                    ForEach(ventureManager.state.ventures) { venture in
                        HStack {
                            Text(venture.industry.icon)
                                .font(.system(size: 14))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(venture.name)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white)
                                Text(venture.stage.rawValue)
                                    .font(.system(size: 9))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            Spacer()
                            Text(game.formatCompact(venture.valuation))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppColors.mattGreen)
                        }
                        .padding(8)
                        .background(AppColors.surfaceLight)
                        .cornerRadius(8)
                    }
                }
            }
            
            // Action buttons
            HStack(spacing: 10) {
                // Start New Venture
                Button(action: { showNewVentureSheet = true }) {
                    HStack {
                        Text("🚀")
                        Text("New Venture")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.mattGreen)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Sell Company (if has ventures)
                if ventureManager.state.ventures.count > 0 {
                    Button(action: { showSellCompanySheet = true }) {
                        HStack {
                            Text("💰")
                            Text("Sell")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppColors.warning)
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Total empire value
            if ventureManager.state.ventures.count > 0 {
                HStack {
                    Text("Empire Value:")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text(game.formatCompact(ventureManager.state.totalVentureValuation))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.gold)
                }
                .padding(.top, 4)
            }
        }
        .sheet(isPresented: $showNewVentureSheet) {
            NewVentureSheet(game: game)
        }
        .sheet(isPresented: $showSellCompanySheet) {
            SellVentureSheet(game: game)
        }
    }
    
    private func careerHeader(_ career: CareerPath) -> some View {
        HStack {
            Text(career.icon)
                .font(.system(size: 24))
            VStack(alignment: .leading) {
                Text(career.rawValue)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                if let role = game.currentRole {
                    Text(role.title)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            currentSalaryDisplay
        }
    }
    
    @ViewBuilder
    private var currentSalaryDisplay: some View {
        if let role = game.currentRole {
            Text("\(game.formatCompact(role.salary))/yr")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.green)
        }
    }
    
    @ViewBuilder
    private var promotionProgress: some View {
        let rolesCount = game.selectedCareer?.roles.count ?? 0
        if game.currentRoleIndex < rolesCount - 1 {
            let nextRole = game.selectedCareer?.roles[game.currentRoleIndex + 1]
            
            VStack(spacing: 10) {
                // Next role header
                if let next = nextRole {
                    HStack {
                        Text("📈 NEXT: \(next.title)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppColors.mattGreen)
                        Spacer()
                        Text("+\(game.formatCompact(Double(next.salary)))/yr")
                            .font(.system(size: 10))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                // Requirements grid
                VStack(spacing: 6) {
                    ForEach(game.promotionRequirements, id: \.requirement) { req in
                        HStack(spacing: 8) {
                            Image(systemName: req.met ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 12))
                                .foregroundColor(req.met ? AppColors.mattGreen : AppColors.textMuted)
                            
                            Text(req.requirement)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(req.met ? .white : AppColors.textSecondary)
                            
                            Spacer()
                            
                            Text(req.detail)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(req.met ? AppColors.mattGreen : AppColors.warning)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(req.met ? AppColors.mattGreen.opacity(0.1) : AppColors.surfaceLight)
                        )
                    }
                }
                
                // Promote button
                Button(action: {
                    if game.promote() {
                        FeedbackCoordinator.shared.achievement()
                    }
                }) {
                    HStack {
                        Text(game.canPromote ? "🎉 PROMOTE NOW" : "🔒 REQUIREMENTS NOT MET")
                            .font(.system(size: 12, weight: .bold))
                        Spacer()
                        if game.canPromote {
                            Text(game.formatCompact(game.promotionCost))
                                .font(.system(size: 10, weight: .bold))
                        }
                    }
                    .foregroundColor(game.canPromote ? .black : AppColors.textMuted)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(game.canPromote ? AppColors.mattGreen : AppColors.surfaceLight)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!game.canPromote)
                
                // Hint about what to do
                if !game.canPromote {
                    let missingReqs = game.promotionRequirements.filter { !$0.met }
                    if let firstMissing = missingReqs.first {
                        HStack {
                            Text("💡")
                            Text(promotionHint(for: firstMissing.requirement))
                                .font(.system(size: 9))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
            }
        } else {
            // Max level reached
            HStack {
                Text("🏆")
                Text("MAX LEVEL REACHED")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.yellow)
            }
        }
    }
    
    private var careerBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color.blue.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
    }
    
    private func promotionHint(for requirement: String) -> String {
        switch requirement {
        case "💰 Cash":
            return "Tap to hustle, buy auto-tappers, or invest to grow your cash!"
        case "🤝 Network":
            return "Meet more people! Scroll down to find contacts to network with."
        case "⚡ Status":
            return "Earn status by tapping (every 100 taps = +1) and meeting contacts."
        default:
            return "Keep grinding to meet all requirements!"
        }
    }
    
    var careerSelectionPrompt: some View {
        VStack(spacing: 16) {
            Text("🎯 Choose Your Path")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Text("Select a career to unlock salary and promotions")
                .font(.system(size: 11))
                .foregroundColor(.gray)
            
            // Career options grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(CareerPath.allCases, id: \.self) { career in
                    CareerOptionCard(career: career, game: game)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.blue.opacity(0.08))
        )
    }
    
    var educationSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("📚")
                Text("EDUCATION")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("Coming Soon")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
        )
    }
    
    var factionsSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("🏛️")
                Text("FACTIONS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            
            FactionsOverviewView(compact: false)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
        )
    }
    
    // MARK: - Invest Zone Content
    
    var investZoneContent: some View {
        VStack(spacing: 16) {
            // Portfolio Summary
            portfolioSummary
            
            // Investments by category
            investmentCategories
        }
        .padding(.horizontal)
    }
    
    var portfolioSummary: some View {
        VStack(spacing: 12) {
            HStack {
                Text("📊")
                Text("PORTFOLIO")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.green)
                Spacer()
                Text(game.formatCompact(game.totalInvestmentValue))
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(.white)
            }
            
            // Asset allocation could go here
            HStack(spacing: 16) {
                VStack {
                    Text("Invested")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                    Text(game.formatCompact(game.investments.reduce(0) { $0 + $1.amountInvested }))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack {
                    Text("Gains")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                    Text("+\(game.formatCompact(game.totalUnrealizedGains))")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)
                }
                
                VStack {
                    Text("Assets")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                    Text("\(game.investments.filter { $0.amountInvested > 0 }.count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    var investmentCategories: some View {
        VStack(spacing: 6) {
            // Available investments - show more in compact format
            ForEach(game.investments.filter { game.currentPhase.rawValue >= $0.phaseUnlock.rawValue }.prefix(10)) { investment in
                CompactInvestmentRow(investment: investment, game: game)
            }
            
            // Show count of locked investments
            let lockedCount = game.investments.filter { game.currentPhase.rawValue < $0.phaseUnlock.rawValue }.count
            if lockedCount > 0 {
                Text("🔒 \(lockedCount) more investments unlock as you progress")
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
                    .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Empire Zone Content
    
    var empireZoneContent: some View {
        VStack(spacing: 16) {
            // Company status
            companySection
            
            // Department Hiring (only show if company founded)
            if CompanyManager.shared.state.founded {
                departmentHiringSection
            }
            
            // Ventures / Portfolio Companies
            if ventureManager.state.ventures.count > 0 || game.isMaxCareer {
                venturesPortfolioSection
            }
            
            // Products
            productsSection
            
            // Contacts / Networking
            contactsSection
        }
        .padding(.horizontal)
    }
    
    // MARK: - Ventures Portfolio Section
    
    var venturesPortfolioSection: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("🚀")
                Text("YOUR VENTURES")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(1.5)
                Spacer()
                Text("\(ventureManager.state.ventures.count) companies")
                    .font(.system(size: 10))
                    .foregroundColor(AppColors.textSecondary)
            }
            
            // Portfolio value summary
            if ventureManager.state.ventures.count > 0 {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Portfolio Value")
                            .font(.system(size: 9))
                            .foregroundColor(AppColors.textMuted)
                        Text(game.formatCompact(ventureManager.state.totalVentureValuation))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppColors.gold)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Annual Revenue")
                            .font(.system(size: 9))
                            .foregroundColor(AppColors.textMuted)
                        Text(game.formatCompact(ventureManager.totalVentureRevenue))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppColors.mattGreen)
                    }
                }
                .padding(10)
                .background(AppColors.surfaceLight)
                .cornerRadius(8)
            }
            
            // Venture list
            ForEach(ventureManager.state.ventures) { venture in
                VenturePortfolioRow(venture: venture, game: game)
            }
            
            // Add new venture button
            if game.isMaxCareer {
                Button(action: { showNewVentureSheet = true }) {
                    HStack {
                        Text("🚀")
                        Text("Start New Venture")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.mattGreen)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppColors.gold.opacity(0.3), lineWidth: 1)
                )
        )
        .sheet(isPresented: $showNewVentureSheet) {
            NewVentureSheet(game: game)
        }
    }
    
    // MARK: - Department Hiring Section
    
    var departmentHiringSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("👥")
                Text("DEPARTMENTS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(1.5)
                Spacer()
                Text("\(CompanyManager.shared.state.departmentState.totalDepartmentEmployees) total")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
            
            // Warning banners for missing departments
            departmentWarnings
            
            // Department rows
            ForEach(Department.allCases, id: \.self) { dept in
                DepartmentHiringRow(
                    department: dept,
                    count: CompanyManager.shared.getDepartmentCount(dept),
                    maxCount: dept.maxEmployees(companyTier: CompanyManager.shared.getCompanyTier()),
                    hireCost: dept.hireCost,
                    canAfford: game.cash >= dept.hireCost,
                    onHire: { hireDepartmentEmployee(dept) }
                )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
        )
    }
    
    @ViewBuilder
    var departmentWarnings: some View {
        let hasHR = CompanyManager.shared.getDepartmentCount(.hr) > 0
        let hasSales = CompanyManager.shared.getDepartmentCount(.sales) > 0
        let hasEngineering = CompanyManager.shared.getDepartmentCount(.engineering) > 0
        let totalEmployees = CompanyManager.shared.state.totalEmployees
        
        VStack(spacing: 6) {
            if !hasHR && totalEmployees > 10 {
                WarningBanner(
                    text: "No HR! Company valuation will decay 15%/year",
                    color: .red
                )
            }
            
            if !hasSales && totalEmployees > 5 {
                WarningBanner(
                    text: "No Sales team! Product revenue reduced 50%",
                    color: .orange
                )
            }
            
            if !hasEngineering && totalEmployees > 5 {
                WarningBanner(
                    text: "No Engineers! Products fail 50% more often",
                    color: .yellow
                )
            }
        }
    }
    
    func hireDepartmentEmployee(_ department: Department) {
        guard game.cash >= department.hireCost else { return }
        
        if CompanyManager.shared.hireDepartmentEmployee(department) {
            game.cash -= department.hireCost
            FeedbackCoordinator.shared.purchase()
            
            NewsFeedManager.shared.addNews(
                category: .personal,
                headline: "Hired new \(department.rawValue) employee! (\(department.icon))"
            )
        }
    }
    
    @ViewBuilder
    var companySection: some View {
        if CompanyManager.shared.state.founded {
            companyOverview
        } else {
            startCompanyPrompt
        }
    }
    
    var companyOverview: some View {
        let cm = CompanyManager.shared
        
        return VStack(spacing: 12) {
            companyHeaderRow(cm: cm)
            Divider().background(AppColors.border)
            companyStatsGrid(cm: cm)
            companyDepartmentRow(cm: cm)
            companyWarningsAndLocations(cm: cm)
            Divider().background(AppColors.border)
            companyActionButtons
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppColors.purple.opacity(0.3), lineWidth: 1)
                )
        )
        .alert("Sell Company?", isPresented: $showSellCompanyAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sell for \(game.formatCompact(cm.salePrice))", role: .destructive) {
                let proceeds = cm.sellCompany()
                game.cash += proceeds
            }
        } message: {
            Text("Your company is worth \(game.formatCompact(cm.salePrice)). You can start a new company after selling.")
        }
        .sheet(isPresented: $showExpandSheet) {
            ExpandCompanySheet(game: game)
        }
    }
    
    @State private var showExpandSheet = false
    @State private var showSellCompanyAlert = false
    
    private func companyHeaderRow(cm: CompanyManager) -> some View {
        HStack {
            Text("🏢").font(.system(size: 24))
            VStack(alignment: .leading, spacing: 2) {
                Text(cm.state.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                HStack(spacing: 4) {
                    Text(cm.state.companyTierIcon).font(.system(size: 10))
                    Text(cm.state.companyTier)
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Valuation").font(.system(size: 9)).foregroundColor(AppColors.textMuted)
                Text(game.formatCompact(cm.state.companyValuation))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.purple)
            }
        }
    }
    
    private func companyStatsGrid(cm: CompanyManager) -> some View {
        let staffingPercent = Int(cm.staffingLevel * 100)
        let staffColor = cm.isUnderstaffed ? AppColors.warning : AppColors.mattGreen
        let staffIcon = staffingPercent >= 100 ? "✅" : "⚠️"
        
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            companyStatCell(icon: "👥", label: "STAFF", value: "\(cm.state.totalEmployees)/\(cm.requiredEmployees)", color: staffColor)
            companyStatCell(icon: staffIcon, label: "STAFFING", value: "\(min(staffingPercent, 150))%", color: staffColor)
            companyStatCell(icon: "💰", label: "PAYROLL/YR", value: game.formatCompact(cm.annualPayroll), color: AppColors.textSecondary)
        }
    }
    
    private func companyDepartmentRow(cm: CompanyManager) -> some View {
        HStack(spacing: 6) {
            ForEach(Department.allCases, id: \.self) { dept in
                let count = cm.getDepartmentCount(dept)
                HStack(spacing: 2) {
                    Text(dept.icon).font(.system(size: 10))
                    Text("\(count)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(count > 0 ? .white : AppColors.textMuted)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Capsule().fill(count > 0 ? AppColors.surfaceLight : Color.clear))
            }
        }
    }
    
    @ViewBuilder
    private func companyWarningsAndLocations(cm: CompanyManager) -> some View {
        if cm.isUnderstaffed {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(AppColors.warning)
                Text(cm.staffingStatus.message).font(.system(size: 10)).foregroundColor(AppColors.warning)
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(AppColors.warning.opacity(0.15))
            .cornerRadius(8)
        }
        
        if !cm.state.locations.isEmpty {
            VStack(spacing: 6) {
                HStack {
                    Text("📍")
                    Text("LOCATIONS").font(.system(size: 9, weight: .bold)).foregroundColor(AppColors.textMuted)
                    Spacer()
                    Text("\(cm.state.locations.count)").font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                }
                ForEach(cm.state.locations) { location in
                    HStack(spacing: 6) {
                        Text(location.icon).font(.system(size: 10))
                        Text(location.name).font(.system(size: 9)).foregroundColor(.white)
                        Text("• \(location.city)").font(.system(size: 9)).foregroundColor(AppColors.textMuted)
                        Spacer()
                    }
                }
            }
            .padding(10)
            .background(AppColors.surfaceLight)
            .cornerRadius(8)
        }
    }
    
    private var companyActionButtons: some View {
        HStack(spacing: 10) {
            Button(action: { showExpandSheet = true }) {
                HStack(spacing: 4) {
                    Text("🏗️").font(.system(size: 12))
                    Text("EXPAND").font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(AppColors.mattBlue)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: { showSellCompanyAlert = true }) {
                HStack(spacing: 4) {
                    Text("💰").font(.system(size: 12))
                    Text("SELL").font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(AppColors.warning.opacity(0.8))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func companyStatCell(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                Text(icon)
                    .font(.system(size: 8))
                Text(label)
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(AppColors.textMuted)
            }
            Text(value)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(AppColors.surfaceLight)
        .cornerRadius(6)
    }
    
    var startCompanyPrompt: some View {
        VStack(spacing: 12) {
            Text("🏗️")
                .font(.system(size: 24))
            Text("Start Your Empire")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            Text("Choose your company type")
                .font(.system(size: 11))
                .foregroundColor(.gray)
            
            // Company type grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(Industry.allCases.prefix(6)) { industry in
                    CompanyTypeCard(industry: industry, game: game, lifecycle: lifecycle)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.purple.opacity(0.1))
        )
    }
    
    var productsSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("📦")
                Text("PRODUCTS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(game.products.filter { $0.launched }.count) launched")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
            
            // Show launched products
            ForEach(game.products.filter { $0.launched }) { product in
                HStack {
                    Text(product.icon)
                        .font(.system(size: 14))
                    Text(product.name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    if product.successful {
                        Text("+\(game.formatCompact(product.ongoingRevenue * LifeCycleConstants.secondsPerGameYear))/yr")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.green)
                    } else {
                        Text("Failed")
                            .font(.system(size: 9))
                            .foregroundColor(.red)
                    }
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.03)))
            }
            
            // Show products available to launch
            ForEach(game.products.filter { !$0.launched }.prefix(3)) { product in
                ProductLaunchRow(product: product, game: game)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
        )
    }
    
    var contactsSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("🤝")
                Text("NETWORK")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(game.contacts.filter { $0.hasMet }.count) contacts")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
            
            // Active partnerships
            if !partnerships.activePartnerships.isEmpty {
                ForEach(partnerships.activePartnerships) { partnership in
                    HStack {
                        Text(partnership.partnershipType.icon)
                        Text(partnership.contactName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Text(partnership.optionChosen.name)
                            .font(.system(size: 9))
                            .foregroundColor(.gray)
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.purple.opacity(0.1)))
                }
            }
            
            // Available contacts to meet
            // Filter contacts by requirements AND career path
            let availableContacts = game.contacts.filter { contact in
                guard !contact.hasMet,
                      game.statusPoints >= contact.statusRequired,
                      game.currentPhase.rawValue >= contact.phaseRequired.rawValue else {
                    return false
                }
                
                // Career-specific contacts only show for matching career
                if let contactCareer = contact.careerPath {
                    guard let playerCareer = game.selectedCareer else { return false }
                    return contactCareer == playerCareer
                }
                return true
            }.prefix(3)
            
            if !availableContacts.isEmpty {
                Divider().background(Color.gray.opacity(0.3))
                Text("AVAILABLE TO MEET")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.gray)
                
                ForEach(Array(availableContacts)) { contact in
                    ContactMeetRow(contact: contact, game: game)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
        )
    }
    
    // MARK: - Legacy Zone Content
    
    var legacyZoneContent: some View {
        VStack(spacing: 16) {
            // Legacy status
            legacyStatus
            
            // Wealth dimensions
            wealthDimensionsSection
            
            // Leaderboard
            leaderboardSection
            
            // Family / Dynasty
            familySection
        }
        .padding(.horizontal)
    }
    
    var legacyStatus: some View {
        VStack(spacing: 12) {
            HStack {
                Text("👑")
                    .font(.system(size: 24))
                VStack(alignment: .leading) {
                    Text("Your Legacy")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("Building generational wealth")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                Spacer()
                
                // Current net worth
                VStack(alignment: .trailing) {
                    Text("Net Worth")
                        .font(.system(size: 8))
                        .foregroundColor(.gray)
                    Text(game.formatCompact(game.netWorth))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(red: 1, green: 0.84, blue: 0))
                }
            }
            
            // Prestige level if applicable
            if PrestigeManager.shared.hasPrestiged {
                HStack {
                    Text("🔄 Prestige Level: \(PrestigeManager.shared.livesLived)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 1, green: 0.84, blue: 0))
                    Spacer()
                    Text("\(Int(PrestigeManager.shared.legacyMultiplier * 100 - 100))% bonus")
                        .font(.system(size: 11))
                        .foregroundColor(.green)
                }
            }
            
            // Prestige button (available at $1B+)
            prestigeButton
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 1, green: 0.84, blue: 0).opacity(0.15), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(red: 1, green: 0.84, blue: 0).opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Prestige Button
    var prestigeButton: some View {
        VStack(spacing: 12) {
            // Main prestige button - always accessible
            Button(action: { showPrestigeSheet = true }) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("🔄")
                            Text(game.netWorth >= 1_000_000_000 ? "PRESTIGE READY!" : "RETIRE & PRESTIGE")
                                .font(.system(size: 14, weight: .bold))
                        }
                        Text(game.netWorth >= 1_000_000_000 ? "Max bonuses unlocked" : "End this life and start fresh")
                            .font(.system(size: 9))
                            .foregroundColor(game.netWorth >= 1_000_000_000 ? .black.opacity(0.7) : AppColors.textSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        let bonusMultiplier = min(0.1 + (game.netWorth / 10_000_000_000), 0.5)
                        Text("\(String(format: "%.1f", PrestigeManager.shared.legacyMultiplier + bonusMultiplier))x")
                            .font(.system(size: 14, weight: .bold))
                        Text("next life")
                            .font(.system(size: 9))
                            .foregroundColor(game.netWorth >= 1_000_000_000 ? .black.opacity(0.7) : AppColors.textSecondary)
                    }
                }
                .foregroundColor(game.netWorth >= 1_000_000_000 ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            game.netWorth >= 1_000_000_000
                                ? LinearGradient(colors: [AppColors.gold, AppColors.gold.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [AppColors.surfaceLight, AppColors.surfaceLight], startPoint: .leading, endPoint: .trailing)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(game.netWorth >= 1_000_000_000 ? Color.clear : AppColors.gold.opacity(0.5), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Progress indicator
            if game.netWorth < 1_000_000_000 {
                VStack(spacing: 4) {
                    HStack {
                        Text("Bonus Progress")
                            .font(.system(size: 9))
                            .foregroundColor(AppColors.textMuted)
                        Spacer()
                        Text("\(game.formatCompact(game.netWorth)) / $1B")
                            .font(.system(size: 9))
                            .foregroundColor(AppColors.gold)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(AppColors.surfaceLight)
                            Capsule()
                                .fill(AppColors.gold.opacity(0.5))
                                .frame(width: max(2, geo.size.width * min(1.0, game.netWorth / 1_000_000_000)))
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
    }
    
    var wealthDimensionsSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("🎯")
                Text("WEALTH DIMENSIONS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            
            WealthDimensionsView(compact: true)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
        )
    }
    
    var leaderboardSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("🏆")
                Text("BILLIONAIRE LEADERBOARD")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            
            LeaderboardView(playerNetWorth: game.netWorth, compact: true)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
        )
    }
    
    @ObservedObject private var familyManager = FamilyManager.shared
    @State private var showDatingSheet = false
    @State private var showProposeAlert = false
    @State private var showHaveKidAlert = false
    
    var familySection: some View {
        VStack(spacing: 12) {
            familySectionHeader
            familySectionContent
            familySectionChildren
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                )
        )
        .sheet(isPresented: $showDatingSheet) {
            DatingPoolSheet(game: game)
        }
        .alert("Have a Child?", isPresented: $showHaveKidAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Yes! ($50K)") {
                handleHaveChild()
            }
        } message: {
            Text("Children bring joy but also cost money. Are you ready to start a family?")
        }
        .alert("Propose to \(familyManager.state.currentlyDating?.name ?? "Partner")?", isPresented: $showProposeAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Propose! 💍 ($25K)") {
                handleProposal()
            }
        } message: {
            Text("Pop the question and plan the wedding!")
        }
    }
    
    private var familySectionHeader: some View {
        HStack {
            Text("💕")
            Text("RELATIONSHIPS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .tracking(1.5)
            Spacer()
            Text(familyManager.state.relationshipStatus)
                .font(.system(size: 10))
                .foregroundColor(AppColors.textSecondary)
        }
    }
    
    @ViewBuilder
    private var familySectionContent: some View {
        if familyManager.state.isMarried, let partner = familyManager.state.partner {
            marriedPartnerView(partner)
            haveChildButton
        } else if let dating = familyManager.state.currentlyDating {
            datingPartnerView(dating)
        } else if familyManager.state.isReadyToDate {
            datingPoolSection
        } else {
            // Dating available at any age with tradeoffs
            readyToDatePrompt
        }
    }
    
    @ViewBuilder
    private var haveChildButton: some View {
        if lifecycle.currentAge >= 28 && familyManager.state.children.count < 3 {
            let canAffordChild = game.cash >= 50000
            Button(action: { showHaveKidAlert = true }) {
                HStack {
                    Text("👶")
                    Text("Have a Child").font(.system(size: 12, weight: .bold))
                    Spacer()
                    Text("$50K")
                        .font(.system(size: 10))
                        .foregroundColor(canAffordChild ? AppColors.mattGreen : AppColors.warning)
                }
                .foregroundColor(.white)
                .padding(12)
                .background(AppColors.surfaceLight)
                .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!canAffordChild)
        }
    }
    
    @ViewBuilder
    private var familySectionChildren: some View {
        if !familyManager.state.children.isEmpty {
            Divider().background(AppColors.border)
            childrenSection
        }
    }
    
    private func handleHaveChild() {
        if game.cash >= 50000 {
            game.cash -= 50000
            if let child = familyManager.haveChild(currentYear: lifecycle.gameYearsPassed + lifecycle.startingAge) {
                NewsFeedManager.shared.addNews(category: .personal, headline: "👶 NEW BABY! Welcome \(child.name) to the family!")
            }
        }
    }
    
    private func handleProposal() {
        if let partner = familyManager.state.currentlyDating, game.cash >= 25000 {
            game.cash -= 25000
            if familyManager.propose(to: partner, weddingBudget: 25000, currentYear: lifecycle.gameYearsPassed + lifecycle.startingAge) {
                NewsFeedManager.shared.addNews(category: .personal, headline: "💍 ENGAGED! You're getting married to \(partner.name)!")
                let _ = familyManager.applyTiffanyTax(game: game)
            }
        }
    }
    
    var readyToDatePrompt: some View {
        VStack(spacing: 10) {
            Text("Ready to find love?")
                .font(.subheadline.bold())
                .foregroundColor(.white)
            
            Text("Dating costs money but can unlock opportunities. A supportive partner boosts your career, while some partners may drain your finances.")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            
            // Dating cost warning
            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text("💸").font(.caption)
                    Text("Dates cost").font(.system(size: 8)).foregroundColor(AppColors.textMuted)
                    Text("$100-$1K").font(.system(size: 9, weight: .bold)).foregroundColor(AppColors.warning)
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: 2) {
                    Text("💍").font(.caption)
                    Text("Wedding").font(.system(size: 8)).foregroundColor(AppColors.textMuted)
                    Text("$25K").font(.system(size: 9, weight: .bold)).foregroundColor(AppColors.warning)
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: 2) {
                    Text("💰").font(.caption)
                    Text("Partner income").font(.system(size: 8)).foregroundColor(AppColors.textMuted)
                    Text("+30-80%").font(.system(size: 9, weight: .bold)).foregroundColor(AppColors.mattGreen)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(8)
            .background(AppColors.surfaceLight)
            .cornerRadius(8)
            
            Button(action: {
                familyManager.setReadyToDate(true)
            }) {
                HStack {
                    Text("💕")
                    Text("Start Dating")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(colors: [Color.pink, Color.red.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    var datingPoolSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Your Matches")
                    .font(.caption.bold())
                    .foregroundColor(AppColors.textMuted)
                Spacer()
                Button(action: { showDatingSheet = true }) {
                    Text("View All")
                        .font(.caption)
                        .foregroundColor(AppColors.mattBlue)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(familyManager.state.datingPool.prefix(4)) { partner in
                        DatingPoolCard(partner: partner, game: game)
                    }
                }
            }
        }
    }
    
    func marriedPartnerView(_ partner: PotentialPartner) -> some View {
        HStack(spacing: 12) {
            Text(partner.personality.icon)
                .font(.system(size: 28))
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(partner.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Text("💍")
                }
                Text(partner.personality.rawValue)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("❤️ \(partner.relationshipLevel)")
                    .font(.caption.bold())
                    .foregroundColor(.red)
                let income = partner.incomeContribution
                if income > 0 {
                    Text("+\(game.formatCompact(income))/yr")
                        .font(.caption2)
                        .foregroundColor(AppColors.mattGreen)
                }
            }
        }
        .padding(12)
        .background(Color.pink.opacity(0.15))
        .cornerRadius(10)
    }
    
    func datingPartnerView(_ partner: PotentialPartner) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Text(partner.personality.icon)
                    .font(.system(size: 28))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Dating \(partner.name)")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Text(partner.personality.rawValue)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                // Relationship progress
                VStack(alignment: .trailing, spacing: 2) {
                    Text("❤️ \(partner.relationshipLevel)/100")
                        .font(.caption.bold())
                        .foregroundColor(.red)
                    if partner.canPropose {
                        Text("Ready to propose!")
                            .font(.caption2)
                            .foregroundColor(AppColors.gold)
                    }
                }
            }
            
            // Date buttons
            HStack(spacing: 10) {
                Button(action: {
                    _ = familyManager.goOnDate(with: partner, fancy: false, cash: &game.cash)
                }) {
                    VStack(spacing: 2) {
                        Text("☕")
                        Text("Date")
                            .font(.caption2.bold())
                        Text("$100")
                            .font(.system(size: 8))
                            .foregroundColor(AppColors.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(AppColors.surfaceLight)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(game.cash < 100)
                
                Button(action: {
                    _ = familyManager.goOnDate(with: partner, fancy: true, cash: &game.cash)
                }) {
                    VStack(spacing: 2) {
                        Text("🍾")
                        Text("Fancy")
                            .font(.caption2.bold())
                        Text("$500")
                            .font(.system(size: 8))
                            .foregroundColor(AppColors.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(AppColors.surfaceLight)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(game.cash < 500)
                
                if partner.canPropose {
                    Button(action: { showProposeAlert = true }) {
                        VStack(spacing: 2) {
                            Text("💍")
                            Text("Propose")
                                .font(.caption2.bold())
                            Text("$25K")
                                .font(.system(size: 8))
                                .foregroundColor(AppColors.textMuted)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(AppColors.gold)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(game.cash < 25000)
                }
                
                Button(action: {
                    familyManager.breakUp()
                }) {
                    VStack(spacing: 2) {
                        Text("💔")
                        Text("Break Up")
                            .font(.caption2.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(AppColors.warning.opacity(0.3))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(12)
        .background(Color.pink.opacity(0.1))
        .cornerRadius(10)
    }
    
    var childrenSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("👨‍👩‍👧‍👦")
                Text("CHILDREN (\(familyManager.state.children.count))")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AppColors.textMuted)
                Spacer()
                if familyManager.state.totalChildExpenses > 0 {
                    Text("\(game.formatCompact(familyManager.state.totalChildExpenses))/yr")
                        .font(.system(size: 9))
                        .foregroundColor(AppColors.warning)
                }
            }
            
            ForEach(familyManager.state.children) { child in
                childRow(child)
            }
        }
    }
    
    func childRow(_ child: Child) -> some View {
        let stage = child.lifeStage(currentYear: lifecycle.gameYearsPassed + lifecycle.startingAge)
        let age = child.age(currentYear: lifecycle.gameYearsPassed + lifecycle.startingAge)
        
        return HStack(spacing: 10) {
            Text(stage.icon)
                .font(.system(size: 20))
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(child.name)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    Text(child.personality.icon)
                        .font(.system(size: 10))
                }
                Text("\(stage.rawValue), Age \(age)")
                    .font(.system(size: 10))
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("❤️ \(child.relationshipWithParent)")
                    .font(.system(size: 9))
                    .foregroundColor(.red)
                Text("\(game.formatCompact(child.yearlyExpense))/yr")
                    .font(.system(size: 8))
                    .foregroundColor(AppColors.warning)
            }
        }
        .padding(8)
        .background(AppColors.surfaceLight)
        .cornerRadius(8)
    }
}

// MARK: - Compact Cards

struct CompactUpgradeCard: View {
    let upgrade: Upgrade
    @ObservedObject var game: GameState
    @State private var showPurchased = false
    
    var effectText: String {
        switch upgrade.effect {
        case .tapMultiplier(let mult):
            return "+\(Int(mult * 100))% tap"
        case .passiveIncome(let income):
            return "+$\(Int(income))/sec"
        case .opportunityBonus(let bonus):
            return "+\(Int(bonus * 100))% luck"
        case .investmentBonus(let bonus):
            return "+\(Int(bonus * 100))% invest"
        case .statusBonus(let status):
            return "+\(status) status"
        case .luxuryFlex(let status, let upkeep):
            return "+\(status) ⚡ -$\(Int(upkeep))/s"
        }
    }
    
    var effectColor: Color {
        switch upgrade.effect {
        case .tapMultiplier: return .green
        case .passiveIncome: return .cyan
        case .opportunityBonus: return .yellow
        case .investmentBonus: return .purple
        case .statusBonus: return .blue
        case .luxuryFlex: return .orange
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(upgrade.icon)
                .font(.system(size: 20))
            
            Text(upgrade.name)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
            
            // Show what it does!
            Text(effectText)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(effectColor)
            
            Text(game.formatCompact(upgrade.cost))
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(game.cash >= upgrade.cost ? .green : .gray)
        }
        .frame(width: 80, height: 90)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(game.cash >= upgrade.cost ? effectColor.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
        .overlay(
            // Purchase feedback
            Group {
                if showPurchased {
                    Text("✓ \(effectText)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(effectColor)
                        .cornerRadius(6)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        )
        .onTapGesture {
            if game.cash >= upgrade.cost {
                _ = game.purchaseUpgrade(upgrade.id)
                FeedbackCoordinator.shared.tap()
                
                // Show purchase feedback
                withAnimation(.spring()) {
                    showPurchased = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        showPurchased = false
                    }
                }
            }
        }
    }
}

struct CompactInvestmentRow: View {
    let investment: Investment
    @ObservedObject var game: GameState
    @State private var showInvestSheet = false
    @State private var showWithdrawSheet = false
    @State private var showSuccess = false
    @State private var showWithdrawSuccess = false
    @State private var showDetailSheet = false  // NEW: Tap for details
    
    var canAffordMin: Bool {
        game.cash >= investment.minInvestment
    }
    
    var hasInvestment: Bool {
        investment.amountInvested > 0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main row - compact (TAP FOR DETAILS)
            HStack(spacing: 8) {
                Text(investment.icon)
                    .font(.system(size: 14))
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(investment.name)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Text("\(Int(investment.baseReturn * 100))%")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.green)
                        riskBadge
                    }
                }
                
                Spacer()
                
                if investment.amountInvested > 0 {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(game.formatCompact(investment.totalValue))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                        Text(investment.unrealizedGains >= 0 ? "+\(game.formatCompact(investment.unrealizedGains))" : "-\(game.formatCompact(abs(investment.unrealizedGains)))")
                            .font(.system(size: 8))
                            .foregroundColor(investment.unrealizedGains >= 0 ? .green : .red)
                    }
                    
                    // Withdraw button
                    Button(action: { 
                        showWithdrawSheet.toggle()
                        showInvestSheet = false
                    }) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Add more button
                    Button(action: { 
                        showInvestSheet.toggle()
                        showWithdrawSheet = false
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Button(action: { showInvestSheet.toggle() }) {
                        Text("INVEST")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(canAffordMin ? .black : .gray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(canAffordMin ? Color.green : Color.gray.opacity(0.3))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())  // Make entire row tappable
            .onTapGesture {
                showDetailSheet = true
            }
            
            // Expandable invest panel
            if showInvestSheet {
                investPanel
            }
            
            // Expandable withdraw panel
            if showWithdrawSheet {
                withdrawPanel
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity((showInvestSheet || showWithdrawSheet) ? 0.06 : 0.03))
        )
        .overlay(
            Group {
                if showSuccess {
                    Text("✓")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Circle().fill(Color.green))
                        .transition(.scale.combined(with: .opacity))
                }
                if showWithdrawSuccess {
                    Text("💰")
                        .font(.system(size: 14))
                        .padding(6)
                        .background(Circle().fill(Color.orange))
                        .transition(.scale.combined(with: .opacity))
                }
            }
        )
        .sheet(isPresented: $showDetailSheet) {
            InvestmentDetailSheet(investment: investment, game: game)
        }
    }
    
    var withdrawPanel: some View {
        VStack(spacing: 8) {
            Divider().background(Color.gray.opacity(0.3))
            
            HStack {
                Text("Invested: \(game.formatCompact(investment.amountInvested))")
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
                Spacer()
                Text("Total: \(game.formatCompact(investment.totalValue))")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.orange)
            }
            
            HStack(spacing: 4) {
                WithdrawButton(label: "25%", proportion: 0.25, game: game, investment: investment, onSuccess: withdrawSuccess)
                WithdrawButton(label: "50%", proportion: 0.50, game: game, investment: investment, onSuccess: withdrawSuccess)
                WithdrawButton(label: "75%", proportion: 0.75, game: game, investment: investment, onSuccess: withdrawSuccess)
                WithdrawButton(label: "ALL", proportion: 1.0, game: game, investment: investment, onSuccess: withdrawSuccess)
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
    }
    
    func withdrawSuccess() {
        withAnimation(.spring()) {
            showWithdrawSuccess = true
            showWithdrawSheet = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation { showWithdrawSuccess = false }
        }
    }
    
    var riskBadge: some View {
        Text(investment.riskLevel.rawValue.prefix(1))
            .font(.system(size: 7, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(
                Capsule().fill(riskColor)
            )
    }
    
    var riskColor: Color {
        switch investment.riskLevel {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .extreme: return .red
        }
    }
    
    var investPanel: some View {
        VStack(spacing: 8) {
            Divider().background(Color.gray.opacity(0.3))
            
            HStack(spacing: 4) {
                QuickInvestButton(label: "Min", amount: investment.minInvestment, game: game, investment: investment, onSuccess: investSuccess)
                QuickInvestButton(label: "10%", amount: game.cash * 0.1, game: game, investment: investment, onSuccess: investSuccess)
                QuickInvestButton(label: "25%", amount: game.cash * 0.25, game: game, investment: investment, onSuccess: investSuccess)
                QuickInvestButton(label: "MAX", amount: game.cash, game: game, investment: investment, onSuccess: investSuccess)
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
    }
    
    func investSuccess() {
        withAnimation(.spring()) {
            showSuccess = true
            showInvestSheet = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation { showSuccess = false }
        }
    }
}

struct QuickInvestButton: View {
    let label: String
    let amount: Double
    @ObservedObject var game: GameState
    let investment: Investment
    let onSuccess: () -> Void
    
    var validAmount: Double {
        max(investment.minInvestment, min(amount, game.cash))
    }
    
    var canAfford: Bool {
        game.cash >= investment.minInvestment && validAmount >= investment.minInvestment
    }
    
    var body: some View {
        Button(action: {
            if game.invest(in: investment.id, amount: validAmount) {
                DailySystemManager.shared.recordInvestment(validAmount)
                FeedbackCoordinator.shared.tap()
                onSuccess()
            }
        }) {
            VStack(spacing: 1) {
                Text(label)
                    .font(.system(size: 8, weight: .bold))
                Text(game.formatCompact(validAmount))
                    .font(.system(size: 7))
            }
            .foregroundColor(canAfford ? .black : .gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(canAfford ? Color.green : Color.gray.opacity(0.2))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!canAfford)
    }
}

struct WithdrawButton: View {
    let label: String
    let proportion: Double
    @ObservedObject var game: GameState
    let investment: Investment
    let onSuccess: () -> Void
    
    var withdrawAmount: Double {
        investment.totalValue * proportion
    }
    
    var hasEnough: Bool {
        investment.totalValue > 0
    }
    
    var body: some View {
        Button(action: {
            let withdrawn = game.withdraw(from: investment.id, amount: withdrawAmount)
            if withdrawn > 0 {
                FeedbackCoordinator.shared.tap()
                onSuccess()
            }
        }) {
            VStack(spacing: 1) {
                Text(label)
                    .font(.system(size: 8, weight: .bold))
                Text(game.formatCompact(withdrawAmount))
                    .font(.system(size: 7))
            }
            .foregroundColor(hasEnough ? .black : .gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(hasEnough ? Color.orange : Color.gray.opacity(0.2))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!hasEnough)
    }
}

// MARK: - Career Option Card
struct CareerOptionCard: View {
    let career: CareerPath
    @ObservedObject var game: GameState
    
    var body: some View {
        Button(action: {
            game.selectCareer(career)
            FeedbackCoordinator.shared.tap()
        }) {
            VStack(spacing: 8) {
                Text(career.icon)
                    .font(.system(size: 28))
                
                Text(career.rawValue)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                Text(career.description)
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Show starting salary
                if let firstRole = career.roles.first {
                    Text("\(game.formatCompact(firstRole.salary))/yr")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.green)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(careerColor.opacity(0.4), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var careerColor: Color {
        switch career {
        case .tech: return .purple
        case .finance: return .green
        case .creator: return .pink
        case .trades: return .orange
        }
    }
}

// MARK: - Starter Auto-Tapper Card
struct StarterAutoTapperCard: View {
    let tapper: AutoTapper
    @ObservedObject var game: GameState
    @State private var showPurchased = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("🎉")
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("UNLOCKED!")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.cyan)
                    Text(tapper.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(tapper.icon)
                        .font(.system(size: 20))
                    Text("+\(String(format: "%.1f", tapper.baseTapsPerSecond))/sec")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                }
            }
            
            Text(tapper.description)
                .font(.system(size: 11))
                .foregroundColor(.gray)
            
            Button(action: {
                if game.purchaseAutoTapper(tapper.id) {
                    FeedbackCoordinator.shared.tap()
                    withAnimation(.spring()) {
                        showPurchased = true
                    }
                }
            }) {
                HStack {
                    Text("Recruit for \(game.formatCompact(tapper.baseCost))")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(game.cash >= tapper.baseCost ? .black : .gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(game.cash >= tapper.baseCost ? Color.cyan : Color.gray.opacity(0.3))
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(game.cash < tapper.baseCost)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.cyan.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.cyan.opacity(0.4), lineWidth: 2)
                )
        )
        .overlay(
            Group {
                if showPurchased {
                    Text("🤝 Buddy Recruited!")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.cyan)
                        .cornerRadius(10)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        )
    }
}

// MARK: - Game Info View
struct GameInfoView: View {
    @ObservedObject var game: GameState
    @Environment(\.dismiss) var dismiss
    @State private var showNukeConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Goal Section
                    infoSection(title: "🏆 The Goal", content: """
                    Become the world's first TRILLIONAIRE! Start from nothing and build your wealth through:
                    • Tapping to earn
                    • Career progression
                    • Smart investments
                    • Building a company empire
                    """)
                    
                    // Zones Section
                    infoSection(title: "🗺️ Game Zones", content: """
                    • Hustle - Tap to earn, daily challenges, upgrades
                    • Career - Choose a path, get promoted, earn salary
                    • Invest - ETFs, stocks, crypto, real estate
                    • Empire - Start a company, launch products
                    • Legacy - Family, wealth dimensions, leaderboard
                    
                    Zones unlock as your net worth grows!
                    """)
                    
                    // Factions Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🏛️ Factions")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Factions are reputation systems that affect your game:")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        FactionInfoRow(icon: "🏢", name: "Corporate", color: .blue, desc: "Better corporate jobs, traditional investments")
                        FactionInfoRow(icon: "🚀", name: "Startup/Tech", color: .orange, desc: "Tech investments, startup opportunities, meet tech leaders")
                        FactionInfoRow(icon: "💰", name: "Old Money", color: .yellow, desc: "Exclusive investments, old wealth contacts")
                        FactionInfoRow(icon: "🎭", name: "Creator", color: .pink, desc: "Creator economy bonuses, influencer opportunities")
                        
                        Text("""
                        How reputation works:
                        • Unlocks contacts (e.g., Elon needs 60 Startup rep)
                        • Investment bonuses for faction-aligned assets
                        • Strategic partnerships require faction standing
                        • Gaining rep with one faction can hurt rivals
                        """)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
                    
                    // Promotions Section
                    infoSection(title: "📈 Career Promotions", content: """
                    To get promoted:
                    1. Earn enough Status Points (⭐)
                    2. Pay the promotion cost (status × $100)
                    3. Tap the PROMOTE button!
                    
                    How to earn status:
                    • Every 100 taps = +1 status
                    • Completing achievements
                    • Meeting important contacts
                    • Career milestones
                    """)
                    
                    // Daily Challenges Section
                    infoSection(title: "📅 Daily Challenges", content: """
                    Challenges reset each real-world day and track:
                    • Tap Master - Taps made today
                    • Smart Investor - Money invested today
                    • Level Up - Upgrades purchased today
                    
                    Complete them for cash and status rewards!
                    """)
                    
                    // Credit Score Section
                    infoSection(title: "💳 Credit Score", content: """
                    Your credit score (300-850) affects:
                    • Loan interest rates
                    • Purchase costs
                    • Maximum loan amounts
                    
                    Improve it by paying bills on time!
                    """)
                    
                    // Tips Section
                    infoSection(title: "💡 Pro Tips", content: """
                    • Invest early - compound growth is powerful!
                    • Build faction rep strategically
                    • Auto-tappers provide passive income
                    • Higher careers = bigger salaries
                    • Diversify your investments
                    """)
                    
                    // Reset Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🔧 Debug / Reset")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("If you're experiencing bugs (like stuck data), you can reset the game:")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            showNukeConfirmation = true
                        }) {
                            HStack {
                                Text("🔥 WIPE ALL DATA & RESET")
                                    .font(.system(size: 12, weight: .bold))
                                Spacer()
                                Text("Instant reset")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.red.opacity(0.8)))
                        }
                        .alert("Wipe All Data?", isPresented: $showNukeConfirmation) {
                            Button("Cancel", role: .cancel) { }
                            Button("WIPE EVERYTHING", role: .destructive) {
                                game.nukeAndReset()
                                dismiss()
                            }
                        } message: {
                            Text("This will DELETE all progress and reset the game to $0. This cannot be undone.")
                        }
                        
                        Text("⚠️ This will DELETE all progress and instantly reset to a fresh game.")
                            .font(.system(size: 10))
                            .foregroundColor(.red)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.1)))
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("How To Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    func infoSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Text(content)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
    }
}

struct FactionInfoRow: View {
    let icon: String
    let name: String
    let color: Color
    let desc: String
    
    var body: some View {
        HStack(spacing: 10) {
            Text(icon)
                .font(.system(size: 16))
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(color)
                Text(desc)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.1)))
    }
}

// MARK: - Auto Tapper Row (Owned - with upgrade)
struct AutoTapperRow: View {
    let tapper: AutoTapper
    @ObservedObject var game: GameState
    @State private var showUpgraded = false
    
    var canAffordUpgrade: Bool {
        game.cash >= tapper.upgradeCost
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Text(tapper.icon)
                .font(.system(size: 18))
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(tapper.name)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Lv.\(tapper.level + 1)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.cyan.opacity(0.2)))
                }
                Text("+\(String(format: "%.1f", tapper.currentTapsPerSecond)) taps/sec")
                    .font(.system(size: 9))
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            // Upgrade button
            Button(action: {
                if game.upgradeAutoTapper(tapper.id) {
                    FeedbackCoordinator.shared.tap()
                    withAnimation(.spring()) { showUpgraded = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        withAnimation { showUpgraded = false }
                    }
                }
            }) {
                VStack(spacing: 1) {
                    Text("UPGRADE")
                        .font(.system(size: 7, weight: .bold))
                    Text(game.formatCompact(tapper.upgradeCost))
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(canAffordUpgrade ? .black : .gray)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(canAffordUpgrade ? Color.cyan : Color.gray.opacity(0.2))
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!canAffordUpgrade)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.cyan.opacity(0.08))
        )
        .overlay(
            Group {
                if showUpgraded {
                    Text("⬆️ Lv.\(tapper.level + 1)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.cyan)
                        .cornerRadius(6)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        )
    }
}

// MARK: - Available Auto Tapper Row (Not owned - purchase)
struct AvailableAutoTapperRow: View {
    let tapper: AutoTapper
    @ObservedObject var game: GameState
    
    var canAfford: Bool {
        game.cash >= tapper.baseCost
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Text(tapper.icon)
                .font(.system(size: 16))
                .opacity(0.6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(tapper.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
                Text("+\(String(format: "%.1f", tapper.baseTapsPerSecond)) taps/sec")
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {
                if game.purchaseAutoTapper(tapper.id) {
                    FeedbackCoordinator.shared.tap()
                }
            }) {
                Text(game.formatCompact(tapper.baseCost))
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(canAfford ? .black : .gray)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(canAfford ? Color.green : Color.gray.opacity(0.2))
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!canAfford)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.02))
        )
    }
}

// MARK: - Product Launch Row
struct ProductLaunchRow: View {
    let product: Product
    @ObservedObject var game: GameState
    @State private var showLaunched = false
    
    var totalCost: Double {
        product.developmentCost + product.marketingCost
    }
    
    var canAfford: Bool {
        game.cash >= totalCost
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Text(product.icon)
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(product.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                HStack(spacing: 6) {
                    Text("\(Int(product.successChance * 100))% success")
                        .font(.system(size: 8))
                        .foregroundColor(.yellow)
                    Text("•")
                        .foregroundColor(.gray)
                    Text("+\(game.formatCompact(product.revenueOnSuccess))")
                        .font(.system(size: 8))
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            Button(action: {
                let result = game.launchProduct(product.id)
                if result.success {
                    FeedbackCoordinator.shared.tap()
                    withAnimation(.spring()) { showLaunched = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        withAnimation { showLaunched = false }
                    }
                }
            }) {
                VStack(spacing: 1) {
                    Text("LAUNCH")
                        .font(.system(size: 7, weight: .bold))
                    Text(game.formatCompact(totalCost))
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(canAfford ? .black : .gray)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(canAfford ? Color.orange : Color.gray.opacity(0.2))
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!canAfford)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.03)))
        .overlay(
            Group {
                if showLaunched {
                    Text("🚀 Launched!")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.orange)
                        .cornerRadius(6)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        )
    }
}

// MARK: - Contact Meet Row
struct ContactMeetRow: View {
    let contact: MeetingContact
    @ObservedObject var game: GameState
    @State private var showMet = false
    @State private var meetingResult: GameState.MeetingResult?
    
    // Check for potential rivalries before meeting
    var metContactIds: [String] {
        game.contacts.filter { $0.hasMet }.map { $0.id }
    }
    
    var potentialRivalries: [RivalryConsequence] {
        ContactRivalrySystem.checkRivalries(contactId: contact.id, metContacts: metContactIds)
    }
    
    var allianceBonus: Double {
        ContactRivalrySystem.getAllianceBonus(contactId: contact.id, metContacts: metContactIds)
    }
    
    var hasRisk: Bool {
        !potentialRivalries.isEmpty
    }
    
    var hasAllianceBonus: Bool {
        allianceBonus > 1.0
    }
    
    var formattedBonus: String {
        game.formatCompact(contact.bonusOnMeet * allianceBonus)
    }
    
    var rivalNames: String {
        potentialRivalries.map { $0.rivalName }.joined(separator: ", ")
    }
    
    var buttonColor: Color {
        hasRisk ? Color.orange : Color.cyan
    }
    
    var bonusColor: Color {
        hasAllianceBonus ? Color.yellow : Color.green
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            mainRow
            warningsRow
        }
        .padding(8)
        .background(backgroundView)
        .overlay(borderOverlay)
        .overlay(resultOverlay)
    }
    
    var mainRow: some View {
        HStack(spacing: 10) {
            Text(contact.icon)
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(contact.name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                    
                    if hasRisk { Text("⚠️").font(.system(size: 10)) }
                    if hasAllianceBonus { Text("🤝").font(.system(size: 10)) }
                }
                Text(contact.title)
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            meetButton
        }
    }
    
    var meetButton: some View {
        Button(action: handleMeet) {
            VStack(spacing: 1) {
                Text(hasRisk ? "RISKY" : "MEET")
                    .font(.system(size: 8, weight: .bold))
                Text("+\(formattedBonus)")
                    .font(.system(size: 8))
                    .foregroundColor(bonusColor)
            }
            .foregroundColor(.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(buttonColor)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    func handleMeet() {
        let result = game.meetContact(contact.id)
        meetingResult = result
        if result.success {
            if result.lawsuitTriggered {
                FeedbackCoordinator.shared.warning()
            } else {
                FeedbackCoordinator.shared.tap()
            }
            withAnimation(.spring()) { showMet = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation { showMet = false }
                meetingResult = nil
            }
        }
    }
    
    var allianceBonusPercent: Int {
        Int((allianceBonus - 1) * 100)
    }
    
    @ViewBuilder
    var warningsRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            if hasRisk && !showMet {
                HStack(spacing: 4) {
                    Text("⚠️").font(.system(size: 8))
                    Text("May anger: \(rivalNames)")
                        .font(.system(size: 8))
                        .foregroundColor(.orange)
                }
            }
            
            if hasAllianceBonus && !showMet {
                HStack(spacing: 4) {
                    Text("🤝").font(.system(size: 8))
                    Text("Alliance bonus: +\(allianceBonusPercent)%")
                        .font(.system(size: 8))
                        .foregroundColor(.yellow)
                }
            }
        }
    }
    
    var backgroundView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(hasRisk ? Color.orange.opacity(0.05) : Color.white.opacity(0.03))
    }
    
    var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(hasRisk ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
    }
    
    @ViewBuilder
    var resultOverlay: some View {
        if showMet, let result = meetingResult {
            resultView(result: result)
        }
    }
    
    func resultView(result: GameState.MeetingResult) -> some View {
        VStack(spacing: 4) {
            if result.lawsuitTriggered {
                Text("⚖️ SUED!")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(.red)
                Text("-\(game.formatCompact(result.lawsuitAmount))")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.red)
            } else if result.allianceBonus > 1.0 {
                Text("🤝 Alliance!")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.yellow)
                Text("+\(game.formatCompact(result.bonusReceived))")
                    .font(.system(size: 9))
                    .foregroundColor(.green)
            } else {
                Text("🤝 Connected!")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(8)
        .background(result.lawsuitTriggered ? Color.red.opacity(0.9) : Color.cyan)
        .cornerRadius(8)
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Company Type Card
struct CompanyTypeCard: View {
    let industry: Industry
    @ObservedObject var game: GameState
    @ObservedObject var lifecycle: LifeCycleManager
    @State private var showFounded = false
    
    var foundingCost: Double {
        industry.entryThreshold / 10  // Use entry threshold as base for founding cost
    }
    
    var canAfford: Bool {
        game.cash >= foundingCost
    }
    
    var body: some View {
        Button(action: {
            if canAfford {
                game.cash -= foundingCost
                CompanyManager.shared.foundCompany(
                    name: industry.rawValue + " Co.",
                    type: industry,
                    year: lifecycle.gameYearsPassed + lifecycle.startingAge
                )
                FeedbackCoordinator.shared.tap()
                withAnimation(.spring()) { showFounded = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation { showFounded = false }
                }
            }
        }) {
            VStack(spacing: 4) {
                Text(industry.icon)
                    .font(.system(size: 20))
                Text(industry.rawValue)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(game.formatCompact(foundingCost))
                    .font(.system(size: 8))
                    .foregroundColor(canAfford ? .green : .red)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(canAfford ? Color.purple.opacity(0.3) : Color.gray.opacity(0.2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(canAfford ? Color.purple.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!canAfford)
        .overlay(
            Group {
                if showFounded {
                    Text("🎉 Founded!")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.purple)
                        .cornerRadius(6)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        )
    }
}

// MARK: - Department Hiring Row
struct DepartmentHiringRow: View {
    let department: Department
    let count: Int
    let maxCount: Int
    let hireCost: Double
    let canAfford: Bool
    let onHire: () -> Void
    
    @State private var showHired = false
    
    var isMaxed: Bool {
        count >= maxCount
    }
    
    var body: some View {
        HStack(spacing: 10) {
            // Department icon
            Text(department.icon)
                .font(.system(size: 18))
            
            // Department info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(department.rawValue)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                    Text("\(count)/\(maxCount)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.white.opacity(0.1)))
                }
                Text(department.description)
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Hire button
            Button(action: {
                onHire()
                withAnimation(.spring()) { showHired = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation { showHired = false }
                }
            }) {
                VStack(spacing: 1) {
                    Text(isMaxed ? "MAX" : "HIRE")
                        .font(.system(size: 7, weight: .bold))
                    if !isMaxed {
                        Text(formatCompact(hireCost))
                            .font(.system(size: 9, weight: .bold))
                    }
                }
                .foregroundColor(canAfford && !isMaxed ? .black : .gray)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(canAfford && !isMaxed ? Color.green : Color.gray.opacity(0.2))
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!canAfford || isMaxed)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(count > 0 ? Color.green.opacity(0.05) : Color.white.opacity(0.02))
        )
        .overlay(
            Group {
                if showHired {
                    Text("✓ Hired!")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.green)
                        .cornerRadius(6)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        )
    }
    
    func formatCompact(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "$%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "$%.0fK", value / 1_000)
        } else {
            return String(format: "$%.0f", value)
        }
    }
}

// MARK: - Warning Banner
struct WarningBanner: View {
    let text: String
    var color: Color = .orange
    
    var body: some View {
        HStack(spacing: 6) {
            Text("⚠️")
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(color.opacity(0.5), lineWidth: 1)
                )
        )
    }
}

// MARK: - Memento Mori Bar
/// A beautiful life progress bar reminding players of the passage of time
/// "Memento Mori" - Remember that you will die
struct MementoMoriBar: View {
    @ObservedObject var lifecycle: LifeCycleManager
    
    // Life expectancy for progress calculation
    private let lifeExpectancy = 85
    
    /// Progress through current year (0-1)
    private var yearProgress: Double {
        lifecycle.yearProgress
    }
    
    /// Progress through entire life (0-1)
    private var lifeProgress: Double {
        Double(lifecycle.currentAge) / Double(lifeExpectancy)
    }
    
    /// Current month based on year progress
    private var currentMonth: String {
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        let monthIndex = min(11, Int(yearProgress * 12))
        return months[monthIndex]
    }
    
    /// Inspiring/motivating phrase based on life stage
    private var lifePhrase: String {
        switch lifecycle.currentAge {
        case 0..<25: return "CARPE DIEM"       // Seize the day
        case 25..<40: return "TEMPUS FUGIT"    // Time flies
        case 40..<55: return "MEMENTO MORI"    // Remember death
        case 55..<70: return "AMOR FATI"       // Love your fate
        default: return "LEGACY"               // What you leave behind
        }
    }
    
    /// Color gradient based on life progress
    private var progressGradient: LinearGradient {
        let colors: [Color]
        switch lifecycle.currentAge {
        case 0..<30:
            colors = [Color.green, Color.mint]
        case 30..<50:
            colors = [Color.blue, Color.cyan]
        case 50..<70:
            colors = [Color.orange, Color.yellow]
        default:
            colors = [Color.purple, Color.pink]
        }
        return LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Top row: Phrase and Age
            HStack {
                // Memento Mori phrase
                Text(lifePhrase)
                    .font(.system(size: 10, weight: .black, design: .serif))
                    .tracking(2)
                    .foregroundColor(.gray)
                
                Spacer()
                
                // Current month indicator
                Text(currentMonth.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                
                Text("•")
                    .foregroundColor(.gray)
                
                // Age display
                Text("AGE \(lifecycle.currentAge)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                
                // Years remaining
                Text("(\(max(0, lifeExpectancy - lifecycle.currentAge)) yrs left)")
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
            }
            
            // Year progress bar with animated gradient
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)
                    
                    // Progress fill
                    Capsule()
                        .fill(progressGradient)
                        .frame(width: max(4, geometry.size.width * yearProgress), height: 6)
                        .animation(.easeInOut(duration: 0.3), value: yearProgress)
                    
                    // Month markers (subtle dots)
                    HStack(spacing: 0) {
                        ForEach(0..<12, id: \.self) { month in
                            Circle()
                                .fill(month < Int(yearProgress * 12) ? Color.clear : Color.white.opacity(0.2))
                                .frame(width: 2, height: 2)
                            if month < 11 {
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .frame(height: 6)
            
            // Life progress indicator (subtle)
            HStack(spacing: 4) {
                // Skull icon for memento mori
                Text("💀")
                    .font(.system(size: 8))
                    .opacity(0.5)
                
                // Life progress mini bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.05))
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: max(2, geometry.size.width * min(1.0, lifeProgress)))
                    }
                }
                .frame(height: 2)
                
                Text("\(Int(lifeProgress * 100))% lived")
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Compact Header (Combines stats, progress, and goal)
/// Robinhood Gold-inspired header that's clean and information-dense
struct CompactHeader: View {
    @ObservedObject var game: GameState
    @ObservedObject var lifecycle: LifeCycleManager
    
    private let trillionGoal: Double = 1_000_000_000_000
    
    /// Format net worth as a live ticker with cents (fun to watch!)
    private var netWorthTicker: String {
        let value = game.netWorth
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        // Always show full number with commas and cents
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
    
    /// Font size scales down as numbers get bigger
    private var tickerFontSize: CGFloat {
        let value = game.netWorth
        switch value {
        case 0..<1_000: return 22
        case 1_000..<100_000: return 20
        case 100_000..<10_000_000: return 18
        case 10_000_000..<1_000_000_000: return 16
        default: return 14  // Billions+
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Row 1: Net Worth + Age
            HStack(alignment: .center) {
                // Net Worth (main focus) - LIVE TICKER with cents!
                VStack(alignment: .leading, spacing: 2) {
                    Text("NET WORTH")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(AppColors.textMuted)
                    
                    Text(netWorthTicker)
                        .font(.system(size: tickerFontSize, weight: .bold, design: .monospaced))
                        .foregroundColor(AppColors.mattGreen)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.1), value: game.netWorth)
                }
                
                Spacer()
                
                // Status & Age (compact)
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(game.ceoTitle.icon)
                            .font(.system(size: 12))
                        Text(game.ceoTitle.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(game.ceoTitle.color)
                    }
                    
                    Text("Age \(lifecycle.currentAge)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            // Row 2: Progress to $1T goal + Year progress
            HStack(spacing: 12) {
                // Trillion goal progress
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Text("🏆")
                            .font(.system(size: 8))
                        Text("$1T GOAL")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(AppColors.textMuted)
                        Spacer()
                        Text(String(format: "%.2f%%", (game.netWorth / trillionGoal) * 100))
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(AppColors.mattGreen)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(AppColors.surfaceLight)
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [AppColors.mattGreen, AppColors.softGreen],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(2, geo.size.width * min(1.0, game.netWorth / trillionGoal)))
                        }
                    }
                    .frame(height: 4)
                }
                .frame(maxWidth: .infinity)
                
                // Year progress
                VStack(alignment: .trailing, spacing: 3) {
                    HStack(spacing: 4) {
                        Text(yearLabel)
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(AppColors.textMuted)
                        Text("💀")
                            .font(.system(size: 8))
                            .opacity(0.6)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(AppColors.surfaceLight)
                            Capsule()
                                .fill(yearProgressColor)
                                .frame(width: max(2, geo.size.width * lifecycle.yearProgress))
                        }
                    }
                    .frame(height: 4)
                }
                .frame(width: 80)
            }
            
            // Row 3: Quick Stats (compact)
            HStack(spacing: 0) {
                quickStat(icon: "💵", label: "CASH", value: game.formatCompact(game.cash))
                Divider().frame(height: 20).background(AppColors.border)
                quickStat(icon: "📈", label: "INVESTED", value: game.formatCompact(game.totalInvestmentValue))
                Divider().frame(height: 20).background(AppColors.border)
                quickStat(icon: "⚡", label: "STATUS", value: "\(game.statusPoints)")
            }
        }
        .padding(12)
        .background(AppColors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.border, lineWidth: 0.5)
        )
    }
    
    private var yearLabel: String {
        let months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
        let monthIndex = min(11, Int(lifecycle.yearProgress * 12))
        return months[monthIndex]
    }
    
    private var yearProgressColor: LinearGradient {
        LinearGradient(
            colors: [AppColors.mattBlue, AppColors.primaryBlue],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private func quickStat(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                Text(icon)
                    .font(.system(size: 8))
                Text(label)
                    .font(.system(size: 7, weight: .medium))
                    .foregroundColor(AppColors.textMuted)
            }
            Text(value)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Investment Detail Sheet
/// Full investment details with stock info, recommendations, and educational content
struct InvestmentDetailSheet: View {
    let investment: Investment
    @ObservedObject var game: GameState
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var sentimentManager = InvestmentSentimentManager.shared
    
    var sentiment: InvestmentSentiment {
        sentimentManager.getSentiment(for: investment.id)
    }
    
    // Simulated stock data
    var peRatio: Double {
        switch investment.riskLevel {
        case .low: return Double.random(in: 12...18)
        case .medium: return Double.random(in: 18...30)
        case .high: return Double.random(in: 30...50)
        case .extreme: return Double.random(in: 50...200)
        }
    }
    
    var marketCap: String {
        switch investment.id {
        case "aapl": return "$3.0T"
        case "msft": return "$2.9T"
        case "googl": return "$1.8T"
        case "amzn": return "$1.5T"
        case "nvda": return "$1.2T"
        case "meta": return "$900B"
        case "tsla": return "$700B"
        case "btc": return "$850B"
        case "eth": return "$280B"
        default: return "N/A"
        }
    }
    
    var analystRating: (rating: String, color: Color, icon: String) {
        switch sentiment.level {
        case .veryBullish: return ("Strong Buy", AppColors.mattGreen, "hand.thumbsup.fill")
        case .bullish: return ("Buy", AppColors.softGreen, "hand.thumbsup")
        case .neutral: return ("Hold", AppColors.textSecondary, "hand.raised")
        case .bearish: return ("Sell", AppColors.warning, "hand.thumbsdown")
        case .veryBearish: return ("Strong Sell", AppColors.negative, "hand.thumbsdown.fill")
        case .warning: return ("Caution", AppColors.warning, "exclamationmark.triangle")
        case .avoid: return ("Avoid", AppColors.negative, "xmark.octagon")
        }
    }
    
    var earningsDate: String {
        let daysUntil = Int.random(in: 5...90)
        if daysUntil < 14 {
            return "📅 Earnings in \(daysUntil) days!"
        } else if daysUntil < 30 {
            return "📅 Earnings this month"
        } else {
            return "📅 Next earnings: ~\(daysUntil/30) months"
        }
    }
    
    var investmentTip: String {
        switch investment.riskLevel {
        case .low:
            return "💡 Low-risk investments are great for long-term wealth building. Consider dollar-cost averaging."
        case .medium:
            return "💡 Medium-risk investments offer balanced growth. Diversify across sectors to reduce risk."
        case .high:
            return "💡 High-risk investments can deliver big returns but also big losses. Only invest what you can afford to lose."
        case .extreme:
            return "⚠️ Extreme volatility! This is speculative. Never invest more than 5-10% of your portfolio here."
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    headerSection
                    
                    // Your Position
                    if investment.amountInvested > 0 {
                        positionSection
                    }
                    
                    // Key Metrics
                    metricsSection
                    
                    // Analyst Recommendation
                    analystSection
                    
                    // News & Sentiment
                    newsSection
                    
                    // Educational Tips
                    educationSection
                    
                    // Action Buttons
                    actionButtons
                }
                .padding()
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle(investment.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppColors.mattGreen)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    var headerSection: some View {
        VStack(spacing: 8) {
            Text(investment.icon)
                .font(.system(size: 50))
            
            Text(investment.name)
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text(investment.description)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                // Return badge
                HStack(spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.caption)
                    Text("\(Int(investment.baseReturn * 100))% avg return")
                        .font(.caption.bold())
                }
                .foregroundColor(AppColors.mattGreen)
                
                // Risk badge
                HStack(spacing: 4) {
                    Image(systemName: "gauge")
                        .font(.caption)
                    Text(investment.riskLevel.rawValue)
                        .font(.caption.bold())
                }
                .foregroundColor(riskColor)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
    
    var riskColor: Color {
        switch investment.riskLevel {
        case .low: return AppColors.mattGreen
        case .medium: return AppColors.mattBlue
        case .high: return AppColors.warning
        case .extreme: return AppColors.negative
        }
    }
    
    var positionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("YOUR POSITION")
                .font(.caption.bold())
                .foregroundColor(AppColors.textMuted)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Invested")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Text(game.formatCompact(investment.amountInvested))
                        .font(.title3.bold())
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Current Value")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Text(game.formatCompact(investment.totalValue))
                        .font(.title3.bold())
                        .foregroundColor(.white)
                }
            }
            
            // Gain/Loss bar
            HStack {
                Text(investment.unrealizedGains >= 0 ? "Unrealized Gain" : "Unrealized Loss")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                Text(investment.unrealizedGains >= 0 ? "+\(game.formatCompact(investment.unrealizedGains))" : "-\(game.formatCompact(abs(investment.unrealizedGains)))")
                    .font(.headline.bold())
                    .foregroundColor(investment.unrealizedGains >= 0 ? AppColors.mattGreen : AppColors.negative)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(investment.unrealizedGains >= 0 ? AppColors.mattGreen.opacity(0.1) : AppColors.negative.opacity(0.1))
            )
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
    
    var metricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("KEY METRICS")
                .font(.caption.bold())
                .foregroundColor(AppColors.textMuted)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                metricCard(title: "Expected Return", value: "\(Int(investment.baseReturn * 100))%/yr", icon: "chart.line.uptrend.xyaxis")
                metricCard(title: "Volatility", value: "\(Int(investment.volatility * 100))%", icon: "waveform.path.ecg")
                metricCard(title: "Min Investment", value: game.formatCompact(Double(investment.minInvestment)), icon: "dollarsign.circle")
                metricCard(title: "Market Cap", value: marketCap, icon: "building.2")
            }
            
            // Earnings
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(AppColors.mattBlue)
                Text(earningsDate)
                    .font(.caption)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(10)
            .background(AppColors.surfaceLight)
            .cornerRadius(8)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
    
    func metricCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(AppColors.textMuted)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(AppColors.textMuted)
            }
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(AppColors.surfaceLight)
        .cornerRadius(8)
    }
    
    var analystSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ANALYST RECOMMENDATION")
                .font(.caption.bold())
                .foregroundColor(AppColors.textMuted)
            
            HStack(spacing: 16) {
                // Rating badge
                VStack(spacing: 4) {
                    Image(systemName: analystRating.icon)
                        .font(.title)
                        .foregroundColor(analystRating.color)
                    Text(analystRating.rating)
                        .font(.headline.bold())
                        .foregroundColor(analystRating.color)
                }
                .frame(width: 80)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(sentiment.headline)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Text(sentiment.details)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    HStack(spacing: 4) {
                        Text("Trend:")
                            .font(.caption2)
                            .foregroundColor(AppColors.textMuted)
                        Text("\(sentiment.trend.icon) \(sentiment.trend.rawValue)")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
    
    var newsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MARKET SENTIMENT")
                .font(.caption.bold())
                .foregroundColor(AppColors.textMuted)
            
            // Sentiment level indicator
            HStack(spacing: 4) {
                ForEach(["🔴", "🟠", "🟡", "🟢", "🚀"], id: \.self) { emoji in
                    Text(emoji)
                        .font(.title3)
                        .opacity(emojiOpacity(for: emoji))
                }
                Spacer()
                Text(sentiment.level.rawValue)
                    .font(.caption.bold())
                    .foregroundColor(sentiment.level.color)
            }
            .padding(10)
            .background(AppColors.surfaceLight)
            .cornerRadius(8)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
    
    func emojiOpacity(for emoji: String) -> Double {
        switch sentiment.level {
        case .veryBearish, .avoid: return emoji == "🔴" ? 1.0 : 0.3
        case .bearish, .warning: return emoji == "🟠" ? 1.0 : 0.3
        case .neutral: return emoji == "🟡" ? 1.0 : 0.3
        case .bullish: return emoji == "🟢" ? 1.0 : 0.3
        case .veryBullish: return emoji == "🚀" ? 1.0 : 0.3
        }
    }
    
    var educationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("INVESTING TIP")
                .font(.caption.bold())
                .foregroundColor(AppColors.textMuted)
            
            Text(investmentTip)
                .font(.caption)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.mattBlue.opacity(0.2))
                .cornerRadius(8)
            
            // Risk explanation
            VStack(alignment: .leading, spacing: 4) {
                Text("Understanding Volatility")
                    .font(.caption.bold())
                    .foregroundColor(AppColors.textMuted)
                Text("Volatility of \(Int(investment.volatility * 100))% means returns can vary by that much from the average. Higher volatility = more unpredictable but potentially higher returns.")
                    .font(.caption2)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(10)
            .background(AppColors.surfaceLight)
            .cornerRadius(8)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
    
    var actionButtons: some View {
        HStack(spacing: 12) {
            if investment.amountInvested > 0 {
                Button(action: { dismiss() }) {
                    HStack {
                        Image(systemName: "arrow.down.circle")
                        Text("Withdraw")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.warning)
                    .cornerRadius(12)
                }
            }
            
            Button(action: { dismiss() }) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text(investment.amountInvested > 0 ? "Add More" : "Invest Now")
                }
                .font(.subheadline.bold())
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(game.cash >= Double(investment.minInvestment) ? AppColors.mattGreen : AppColors.textMuted)
                .cornerRadius(12)
            }
            .disabled(game.cash < Double(investment.minInvestment))
        }
        .padding(.top, 8)
    }
}

// MARK: - New Venture Sheet
struct NewVentureSheet: View {
    @ObservedObject var game: GameState
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var ventureManager = VentureManager.shared
    @ObservedObject private var lifecycle = LifeCycleManager.shared
    
    @State private var ventureName = ""
    @State private var selectedIndustry: Industry?
    @State private var investmentAmount: Double = 100_000
    
    // Filter to venture-specific industries
    var availableIndustries: [Industry] {
        Industry.allCases.filter { $0.isVentureIndustry && game.cash >= $0.entryThreshold }
    }
    
    var canStart: Bool {
        !ventureName.isEmpty && selectedIndustry != nil && game.cash >= investmentAmount
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("🚀")
                            .font(.system(size: 50))
                        Text("Start a New Venture")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        Text("Build your empire by launching companies in different industries.")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // Company Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("COMPANY NAME")
                            .font(.caption.bold())
                            .foregroundColor(AppColors.textMuted)
                        
                        TextField("Enter company name...", text: $ventureName)
                            .padding(12)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                    }
                    .padding()
                    .cardStyle()
                    
                    // Industry Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SELECT INDUSTRY")
                            .font(.caption.bold())
                            .foregroundColor(AppColors.textMuted)
                        
                        if availableIndustries.isEmpty {
                            Text("You need more cash to enter any industry. Keep hustling!")
                                .font(.caption)
                                .foregroundColor(AppColors.warning)
                                .padding()
                        } else {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(availableIndustries, id: \.self) { industry in
                                    IndustryCard(
                                        industry: industry,
                                        isSelected: selectedIndustry == industry,
                                        canAfford: game.cash >= industry.entryThreshold
                                    ) {
                                        selectedIndustry = industry
                                        investmentAmount = industry.entryThreshold
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .cardStyle()
                    
                    // Investment Amount
                    if let industry = selectedIndustry {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("INITIAL INVESTMENT")
                                .font(.caption.bold())
                                .foregroundColor(AppColors.textMuted)
                            
                            HStack {
                                Text("Min: \(game.formatCompact(industry.entryThreshold))")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                Spacer()
                                Text("Your cash: \(game.formatCompact(game.cash))")
                                    .font(.caption)
                                    .foregroundColor(AppColors.mattGreen)
                            }
                            
                            // Quick amounts
                            HStack(spacing: 8) {
                                ForEach([1.0, 2.0, 5.0, 10.0], id: \.self) { multiplier in
                                    let amount = industry.entryThreshold * multiplier
                                    if game.cash >= amount {
                                        Button(action: { investmentAmount = amount }) {
                                            Text(game.formatCompact(amount))
                                                .font(.caption.bold())
                                                .foregroundColor(investmentAmount == amount ? .black : .white)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(investmentAmount == amount ? AppColors.mattGreen : AppColors.surfaceLight)
                                                .cornerRadius(8)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                        .padding()
                        .cardStyle()
                    }
                    
                    // Start Button
                    Button(action: startVenture) {
                        HStack {
                            Text("🚀")
                            Text("Launch \(ventureName.isEmpty ? "Venture" : ventureName)")
                                .font(.headline.bold())
                        }
                        .foregroundColor(canStart ? .black : AppColors.textMuted)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canStart ? AppColors.mattGreen : AppColors.surfaceLight)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!canStart)
                    .padding(.top)
                }
                .padding()
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("New Venture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func startVenture() {
        guard let industry = selectedIndustry else { return }
        
        // Deduct cash
        game.cash -= investmentAmount
        
        // Create venture
        let _ = ventureManager.startVenture(
            name: ventureName,
            industry: industry,
            initialInvestment: investmentAmount,
            currentYear: lifecycle.gameYearsPassed + lifecycle.startingAge
        )
        
        dismiss()
    }
}

// MARK: - Industry Card
struct IndustryCard: View {
    let industry: Industry
    let isSelected: Bool
    let canAfford: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(industry.icon)
                    .font(.system(size: 28))
                
                Text(industry.rawValue)
                    .font(.caption.bold())
                    .foregroundColor(isSelected ? .black : .white)
                    .lineLimit(1)
                
                Text(formatCompact(industry.entryThreshold))
                    .font(.caption2)
                    .foregroundColor(isSelected ? .black.opacity(0.7) : AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? AppColors.mattGreen : AppColors.surfaceLight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? AppColors.mattGreen : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!canAfford)
        .opacity(canAfford ? 1.0 : 0.5)
    }
    
    private func formatCompact(_ value: Double) -> String {
        switch value {
        case 1_000_000_000...: return String(format: "$%.0fB", value / 1_000_000_000)
        case 1_000_000...: return String(format: "$%.0fM", value / 1_000_000)
        case 1_000...: return String(format: "$%.0fK", value / 1_000)
        default: return "$\(Int(value))"
        }
    }
}

// MARK: - Sell Venture Sheet
struct SellVentureSheet: View {
    @ObservedObject var game: GameState
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var ventureManager = VentureManager.shared
    
    @State private var selectedVenture: Venture?
    @State private var showConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("💰")
                            .font(.system(size: 50))
                        Text("Sell a Venture")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        Text("Cash out on your hard work. Receive the full valuation in cash.")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // Ventures list
                    VStack(alignment: .leading, spacing: 12) {
                        Text("YOUR VENTURES")
                            .font(.caption.bold())
                            .foregroundColor(AppColors.textMuted)
                        
                        ForEach(ventureManager.state.ventures) { venture in
                            VentureRow(
                                venture: venture,
                                isSelected: selectedVenture?.id == venture.id,
                                formatCompact: game.formatCompact
                            ) {
                                selectedVenture = venture
                            }
                        }
                    }
                    .padding()
                    .cardStyle()
                    
                    // Sell button
                    if let venture = selectedVenture {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Sale Price:")
                                    .foregroundColor(AppColors.textSecondary)
                                Spacer()
                                Text(game.formatCompact(venture.valuation))
                                    .font(.title2.bold())
                                    .foregroundColor(AppColors.mattGreen)
                            }
                            
                            Button(action: { showConfirmation = true }) {
                                HStack {
                                    Text("💰")
                                    Text("Sell \(venture.name)")
                                        .font(.headline.bold())
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.warning)
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding()
                        .cardStyle()
                    }
                }
                .padding()
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Sell Venture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .alert("Confirm Sale", isPresented: $showConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Sell", role: .destructive) {
                    if let venture = selectedVenture {
                        if let salePrice = ventureManager.sellVenture(id: venture.id) {
                            game.cash += salePrice
                            game.totalEarned += salePrice
                        }
                        dismiss()
                    }
                }
            } message: {
                if let venture = selectedVenture {
                    Text("Sell \(venture.name) for \(game.formatCompact(venture.valuation))?")
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Venture Row
struct VentureRow: View {
    let venture: Venture
    let isSelected: Bool
    let formatCompact: (Double) -> String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(venture.industry.icon)
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(venture.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Text(venture.stage.rawValue)
                            .font(.caption2)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text("•")
                            .foregroundColor(AppColors.textMuted)
                        
                        Text("\(venture.employees) employees")
                            .font(.caption2)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatCompact(venture.valuation))
                        .font(.subheadline.bold())
                        .foregroundColor(AppColors.mattGreen)
                    
                    Text("+\(Int(venture.growthRate * 100))%/yr")
                        .font(.caption2)
                        .foregroundColor(AppColors.softGreen)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? AppColors.mattGreen.opacity(0.2) : AppColors.surfaceLight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? AppColors.mattGreen : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Prestige Sheet
struct PrestigeSheet: View {
    @ObservedObject var game: GameState
    @ObservedObject var lifecycle: LifeCycleManager
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var prestigeManager = PrestigeManager.shared
    @State private var showConfirmation = false
    
    var preview: PrestigePreview {
        prestigeManager.calculatePrestigePreview(
            currentEarnings: game.totalEarned,
            currentAge: lifecycle.currentAge,
            yearsPlayed: lifecycle.gameYearsPassed
        )
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Text("🌟")
                            .font(.system(size: 60))
                        
                        Text("START A NEW LIFE")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(.white)
                            .tracking(2)
                        
                        Text("Reset your progress and begin again with permanent bonuses")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Current Life Summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("THIS LIFE")
                            .font(.caption.bold())
                            .foregroundColor(AppColors.textMuted)
                        
                        HStack {
                            statBox(icon: "💰", label: "Earned", value: game.formatCompact(game.totalEarned))
                            statBox(icon: "📊", label: "Net Worth", value: game.formatCompact(game.netWorth))
                            statBox(icon: "🎂", label: "Age", value: "\(lifecycle.currentAge)")
                        }
                    }
                    .padding()
                    .cardStyle()
                    
                    // What You'll Get
                    VStack(alignment: .leading, spacing: 12) {
                        Text("REWARDS FOR NEXT LIFE")
                            .font(.caption.bold())
                            .foregroundColor(AppColors.textMuted)
                        
                        prestigeReward(
                            icon: "⚡",
                            label: "Legacy Multiplier",
                            current: String(format: "%.1fx", prestigeManager.legacyMultiplier),
                            new: String(format: "%.1fx", preview.newLegacyMultiplier),
                            color: AppColors.gold
                        )
                        
                        prestigeReward(
                            icon: "💵",
                            label: "Starting Cash",
                            current: game.formatCompact(prestigeManager.state.startingCashBonus),
                            new: game.formatCompact(preview.startingCashBonus),
                            color: AppColors.mattGreen
                        )
                        
                        prestigeReward(
                            icon: "🔄",
                            label: "Lives Lived",
                            current: "\(prestigeManager.livesLived)",
                            new: "\(preview.newLivesCount)",
                            color: AppColors.mattBlue
                        )
                    }
                    .padding()
                    .cardStyle()
                    
                    // What's Preserved
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PRESERVED ACROSS LIVES")
                            .font(.caption.bold())
                            .foregroundColor(AppColors.textMuted)
                        
                        HStack(spacing: 20) {
                            preservedItem(icon: "🎨", label: "Themes")
                            preservedItem(icon: "📚", label: "Lessons")
                            preservedItem(icon: "🏆", label: "Achievements")
                        }
                    }
                    .padding()
                    .cardStyle()
                    
                    // What's Reset
                    VStack(alignment: .leading, spacing: 8) {
                        Text("WILL BE RESET")
                            .font(.caption.bold())
                            .foregroundColor(AppColors.warning)
                        
                        HStack {
                            resetItem(icon: "💰", label: "Cash")
                            resetItem(icon: "📈", label: "Investments")
                            resetItem(icon: "💼", label: "Career")
                            resetItem(icon: "🏢", label: "Company")
                        }
                    }
                    .padding()
                    .background(AppColors.warning.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Prestige Button
                    Button(action: { showConfirmation = true }) {
                        HStack {
                            Text("🌟")
                            Text("PRESTIGE NOW")
                                .font(.headline.bold())
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.gold)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 10)
                }
                .padding()
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Prestige")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .alert("Start New Life?", isPresented: $showConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Prestige", role: .destructive) {
                    executePrestige()
                }
            } message: {
                Text("Your cash, investments, career, and company will reset. Your legacy bonuses will increase.")
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func executePrestige() {
        prestigeManager.prestige(
            currentEarnings: game.totalEarned,
            currentAge: lifecycle.currentAge,
            yearsPlayed: lifecycle.gameYearsPassed,
            themeManager: ThemeManager.shared,
            educationManager: EducationManager.shared,
            achievementManager: AchievementManager.shared
        )
        
        // Reset game state for new life
        game.resetForPrestige()
        
        dismiss()
    }
    
    private func statBox(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.title2)
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.white)
            Text(label)
                .font(.caption2)
                .foregroundColor(AppColors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppColors.surfaceLight)
        .cornerRadius(10)
    }
    
    private func prestigeReward(icon: String, label: String, current: String, new: String, color: Color) -> some View {
        HStack {
            Text(icon)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text("\(current) → \(new)")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            Text("+\(new)")
                .font(.subheadline.bold())
                .foregroundColor(color)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
    
    private func preservedItem(icon: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.title3)
            Text(label)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
    }
    
    private func resetItem(icon: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.caption)
            Text(label)
                .font(.caption2)
                .foregroundColor(AppColors.warning)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Expand Company Sheet
struct ExpandCompanySheet: View {
    @ObservedObject var game: GameState
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var companyManager = CompanyManager.shared
    
    @State private var selectedType: (type: String, name: String, cost: Double, employeesRequired: Int)?
    @State private var selectedCity: String = "San Francisco"
    @State private var showConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    expandSheetHeader
                    expandSheetStats
                    expandLocationTypesList
                    expandCitySelection
                    expandBuildButton
                }
                .padding()
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Expand")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .alert("Confirm Expansion", isPresented: $showConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Build") { handleBuildLocation() }
            } message: {
                if let locType = selectedType {
                    Text("Build \(locType.name) in \(selectedCity) for \(game.formatCompact(locType.cost))?")
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var expandSheetHeader: some View {
        VStack(spacing: 8) {
            Text("🏗️").font(.system(size: 50))
            Text("EXPAND YOUR EMPIRE")
                .font(.system(size: 20, weight: .black))
                .foregroundColor(.white)
                .tracking(2)
            Text("Open new locations to increase revenue and capacity")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    private var expandSheetStats: some View {
        HStack(spacing: 16) {
            expandStatBox(icon: "👥", label: "Employees", value: "\(companyManager.state.totalEmployees)")
            expandStatBox(icon: "📍", label: "Locations", value: "\(companyManager.state.locations.count)")
            expandStatBox(icon: "💰", label: "Cash", value: game.formatCompact(game.cash))
        }
    }
    
    private func expandStatBox(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(icon).font(.title2)
            Text(value).font(.subheadline.bold()).foregroundColor(.white)
            Text(label).font(.caption2).foregroundColor(AppColors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppColors.surfaceLight)
        .cornerRadius(10)
    }
    
    private var expandLocationTypesList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CHOOSE LOCATION TYPE").font(.caption.bold()).foregroundColor(AppColors.textMuted)
            
            if companyManager.availableLocationTypes.isEmpty {
                Text("Found a company first to unlock expansion options")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .padding()
            } else {
                ForEach(companyManager.availableLocationTypes, id: \.type) { locType in
                    LocationTypeRow(
                        type: locType.type,
                        name: locType.name,
                        cost: locType.cost,
                        employeesRequired: locType.employeesRequired,
                        canAfford: game.cash >= locType.cost,
                        hasEmployees: companyManager.canExpandLocation(employeesRequired: locType.employeesRequired),
                        isSelected: selectedType?.type == locType.type,
                        game: game
                    ) {
                        selectedType = locType
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var expandCitySelection: some View {
        if selectedType != nil {
            VStack(alignment: .leading, spacing: 12) {
                Text("CHOOSE CITY").font(.caption.bold()).foregroundColor(AppColors.textMuted)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(CompanyManager.expansionCities, id: \.self) { city in
                        expandCityButton(city: city)
                    }
                }
            }
        }
    }
    
    private func expandCityButton(city: String) -> some View {
        let isSelected = selectedCity == city
        return Button(action: { selectedCity = city }) {
            Text(city)
                .font(.subheadline)
                .foregroundColor(isSelected ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 8).fill(isSelected ? AppColors.mattGreen : AppColors.surfaceLight))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var expandBuildButton: some View {
        if let locType = selectedType {
            let canBuild = game.cash >= locType.cost && companyManager.canExpandLocation(employeesRequired: locType.employeesRequired)
            
            Button(action: { if canBuild { showConfirmation = true } }) {
                VStack(spacing: 4) {
                    Text("BUILD \(locType.name.uppercased())").font(.headline.bold())
                    Text("in \(selectedCity) for \(game.formatCompact(locType.cost))")
                        .font(.caption)
                        .foregroundColor(canBuild ? .black.opacity(0.7) : .gray)
                }
                .foregroundColor(canBuild ? .black : .gray)
                .frame(maxWidth: .infinity)
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(canBuild ? AppColors.mattGreen : AppColors.surfaceLight))
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!canBuild)
            
            if !companyManager.canExpandLocation(employeesRequired: locType.employeesRequired) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Need \(locType.employeesRequired) more employees to staff this location").font(.caption)
                }
                .foregroundColor(AppColors.warning)
            }
        }
    }
    
    private func handleBuildLocation() {
        guard let locType = selectedType else { return }
        game.cash -= locType.cost
        _ = companyManager.addLocation(
            type: locType.type,
            name: locType.name,
            city: selectedCity,
            cost: locType.cost,
            maxEmployees: locType.employeesRequired * 2
        )
        NewsFeedManager.shared.addNews(category: .markets, headline: "🏗️ NEW LOCATION - Opened \(locType.name) in \(selectedCity)!")
        dismiss()
    }
}

// MARK: - Location Type Row
struct LocationTypeRow: View {
    let type: String
    let name: String
    let cost: Double
    let employeesRequired: Int
    let canAfford: Bool
    let hasEmployees: Bool
    let isSelected: Bool
    @ObservedObject var game: GameState
    let onSelect: () -> Void
    
    var icon: String {
        switch type {
        case "datacenter": return "🖥️"
        case "office": return "🏠"
        case "factory": return "🏭"
        case "lab": return "🔬"
        default: return "📍"
        }
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Text(icon)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Text(game.formatCompact(cost))
                            .font(.caption)
                            .foregroundColor(canAfford ? AppColors.mattGreen : AppColors.warning)
                        
                        Text("•")
                            .foregroundColor(AppColors.textMuted)
                        
                        Text("\(employeesRequired) staff needed")
                            .font(.caption)
                            .foregroundColor(hasEmployees ? AppColors.textSecondary : AppColors.warning)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.mattGreen)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? AppColors.mattGreen.opacity(0.2) : AppColors.surfaceLight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? AppColors.mattGreen : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Dating Pool Card
struct DatingPoolCard: View {
    let partner: PotentialPartner
    @ObservedObject var game: GameState
    @ObservedObject private var familyManager = FamilyManager.shared
    
    var body: some View {
        Button(action: {
            _ = familyManager.goOnDate(with: partner, fancy: false, cash: &game.cash)
        }) {
            VStack(spacing: 6) {
                Text(partner.personality.icon)
                    .font(.system(size: 28))
                
                Text(partner.name)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                
                Text(partner.personality.rawValue)
                    .font(.system(size: 8))
                    .foregroundColor(AppColors.textMuted)
                
                if partner.relationshipLevel > 0 {
                    HStack(spacing: 2) {
                        Text("❤️")
                            .font(.system(size: 8))
                        Text("\(partner.relationshipLevel)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.red)
                    }
                } else {
                    Text("Date $100")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(AppColors.mattGreen)
                }
            }
            .frame(width: 75)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.pink.opacity(0.15))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(game.cash < 100)
    }
}

// MARK: - Dating Pool Sheet
struct DatingPoolSheet: View {
    @ObservedObject var game: GameState
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var familyManager = FamilyManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("💕")
                            .font(.system(size: 50))
                        
                        Text("DATING POOL")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(.white)
                            .tracking(2)
                        
                        Text("Find your perfect match")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.top, 20)
                    
                    // Currently dating
                    if let dating = familyManager.state.currentlyDating {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("CURRENTLY DATING")
                                .font(.caption.bold())
                                .foregroundColor(AppColors.textMuted)
                            
                            CurrentDatingCard(partner: dating, game: game)
                        }
                        .padding()
                        .cardStyle()
                    }
                    
                    // Available matches
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("AVAILABLE MATCHES")
                                .font(.caption.bold())
                                .foregroundColor(AppColors.textMuted)
                            Spacer()
                            Button(action: {
                                familyManager.refreshDatingPool()
                            }) {
                                Text("🔄 Refresh")
                                    .font(.caption)
                                    .foregroundColor(AppColors.mattBlue)
                            }
                        }
                        
                        ForEach(familyManager.state.datingPool) { partner in
                            DatingPartnerRow(partner: partner, game: game)
                        }
                    }
                    .padding()
                    .cardStyle()
                }
                .padding()
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Dating")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Current Dating Card
struct CurrentDatingCard: View {
    let partner: PotentialPartner
    @ObservedObject var game: GameState
    @ObservedObject private var familyManager = FamilyManager.shared
    @State private var showProposeAlert = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Text(partner.personality.icon)
                    .font(.system(size: 36))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(partner.name)
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    Text(partner.personality.description)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("❤️ \(partner.relationshipLevel)/100")
                        .font(.subheadline.bold())
                        .foregroundColor(.red)
                    if partner.canPropose {
                        Text("Ready to propose!")
                            .font(.caption2)
                            .foregroundColor(AppColors.gold)
                    }
                }
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColors.surfaceLight)
                    Capsule()
                        .fill(Color.red)
                        .frame(width: geo.size.width * (Double(partner.relationshipLevel) / 100))
                }
            }
            .frame(height: 8)
            
            // Actions
            HStack(spacing: 10) {
                Button(action: {
                    _ = familyManager.goOnDate(with: partner, fancy: false, cash: &game.cash)
                }) {
                    VStack(spacing: 2) {
                        Text("☕ Date")
                            .font(.caption.bold())
                        Text("$100 • +8❤️")
                            .font(.system(size: 9))
                            .foregroundColor(AppColors.textMuted)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppColors.surfaceLight)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    _ = familyManager.goOnDate(with: partner, fancy: true, cash: &game.cash)
                }) {
                    VStack(spacing: 2) {
                        Text("🍾 Fancy")
                            .font(.caption.bold())
                        Text("$500 • +15❤️")
                            .font(.system(size: 9))
                            .foregroundColor(AppColors.textMuted)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppColors.surfaceLight)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                if partner.canPropose {
                    Button(action: { showProposeAlert = true }) {
                        VStack(spacing: 2) {
                            Text("💍 Propose")
                                .font(.caption.bold())
                            Text("$25K")
                                .font(.system(size: 9))
                                .foregroundColor(.black.opacity(0.7))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AppColors.gold)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(Color.pink.opacity(0.15))
        .cornerRadius(12)
        .alert("Propose?", isPresented: $showProposeAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Yes! 💍") {
                if game.cash >= 25000 {
                    game.cash -= 25000
                    if familyManager.propose(to: partner, weddingBudget: 25000, currentYear: LifeCycleManager.shared.gameYearsPassed + LifeCycleManager.shared.startingAge) {
                        // 💎 Easter egg: Tiffany Tax!
                        let _ = familyManager.applyTiffanyTax(game: game)
                    }
                }
            }
        } message: {
            Text("Pop the question to \(partner.name)? This costs $25K for the ring and wedding.")
        }
    }
}

// MARK: - Dating Partner Row
struct DatingPartnerRow: View {
    let partner: PotentialPartner
    @ObservedObject var game: GameState
    @ObservedObject private var familyManager = FamilyManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            Text(partner.personality.icon)
                .font(.system(size: 28))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(partner.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                HStack(spacing: 6) {
                    Text(partner.personality.rawValue)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    if partner.relationshipLevel > 0 {
                        Text("• ❤️\(partner.relationshipLevel)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                _ = familyManager.goOnDate(with: partner, fancy: false, cash: &game.cash)
            }) {
                Text("Date $100")
                    .font(.caption.bold())
                    .foregroundColor(game.cash >= 100 ? .black : .gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(game.cash >= 100 ? AppColors.mattGreen : AppColors.surfaceLight)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(game.cash < 100)
        }
        .padding()
        .background(AppColors.surfaceLight)
        .cornerRadius(10)
    }
}

// MARK: - Tax Plan Upgrade Sheet
struct TaxPlanUpgradeSheet: View {
    @ObservedObject var game: GameState
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var taxManager = TaxManager.shared
    @State private var showConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("🏛️")
                            .font(.system(size: 50))
                        
                        Text("TAX PLANNING")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(.white)
                            .tracking(2)
                        
                        Text("Optimize your tax strategy to keep more of what you earn")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Current plan
                    VStack(alignment: .leading, spacing: 12) {
                        Text("CURRENT PLAN")
                            .font(.caption.bold())
                            .foregroundColor(AppColors.textMuted)
                        
                        currentPlanCard
                    }
                    .padding()
                    .cardStyle()
                    
                    // Available upgrades
                    VStack(alignment: .leading, spacing: 12) {
                        Text("AVAILABLE PLANS")
                            .font(.caption.bold())
                            .foregroundColor(AppColors.textMuted)
                        
                        ForEach(TaxPlanTier.allCases, id: \.rawValue) { tier in
                            if tier.rawValue > taxManager.state.currentPlanTier.rawValue {
                                TaxPlanTierRow(tier: tier, game: game)
                            }
                        }
                    }
                    .padding()
                    .cardStyle()
                    
                    // How it works
                    VStack(alignment: .leading, spacing: 8) {
                        Text("HOW IT WORKS")
                            .font(.caption.bold())
                            .foregroundColor(AppColors.textMuted)
                        
                        taxInfoRow(icon: "💰", text: "Higher tiers reduce your effective tax rate")
                        taxInfoRow(icon: "📅", text: "Plans have annual maintenance fees")
                        taxInfoRow(icon: "📈", text: "Some plans require minimum net worth")
                        taxInfoRow(icon: "💎", text: "Elite plans use legal offshore strategies")
                    }
                    .padding()
                    .background(AppColors.surfaceLight)
                    .cornerRadius(12)
                }
                .padding()
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Tax Planning")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    var currentPlanCard: some View {
        HStack(spacing: 12) {
            Text(taxManager.state.currentPlanTier.icon)
                .font(.system(size: 36))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(taxManager.state.currentPlanTier.name)
                    .font(.headline.bold())
                    .foregroundColor(.white)
                
                ForEach(taxManager.state.currentPlanTier.benefits, id: \.self) { benefit in
                    HStack(spacing: 4) {
                        Text("✓")
                            .font(.caption)
                            .foregroundColor(AppColors.mattGreen)
                        Text(benefit)
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("-\(Int(taxManager.state.currentPlanTier.taxReduction * 100))%")
                    .font(.title2.bold())
                    .foregroundColor(AppColors.mattGreen)
                Text("tax rate")
                    .font(.caption2)
                    .foregroundColor(AppColors.textMuted)
            }
        }
        .padding()
        .background(AppColors.mattGreen.opacity(0.15))
        .cornerRadius(12)
    }
    
    func taxInfoRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Text(icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

// MARK: - Tax Plan Tier Row
struct TaxPlanTierRow: View {
    let tier: TaxPlanTier
    @ObservedObject var game: GameState
    @ObservedObject private var taxManager = TaxManager.shared
    @State private var showConfirmation = false
    
    var canAfford: Bool {
        game.cash >= tier.upgradeCost
    }
    
    var meetsNetWorth: Bool {
        game.netWorth >= tier.netWorthRequired
    }
    
    var isNextTier: Bool {
        tier.rawValue == taxManager.state.currentPlanTier.rawValue + 1
    }
    
    var body: some View {
        VStack(spacing: 10) {
            tierMainRow
            tierRequirementsRow
            tierUpgradeButton
            tierAnnualCostRow
        }
        .padding()
        .background(isNextTier ? AppColors.mattGreen.opacity(0.1) : AppColors.surfaceLight)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isNextTier ? AppColors.mattGreen.opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .alert("Upgrade Tax Plan?", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Upgrade (\(game.formatCompact(tier.upgradeCost)))") {
                handleUpgrade()
            }
        } message: {
            Text("Upgrade to \(tier.name) for \(game.formatCompact(tier.upgradeCost))? This will reduce your taxes by \(Int(tier.taxReduction * 100))%.")
        }
    }
    
    private var tierMainRow: some View {
        HStack(spacing: 12) {
            Text(tier.icon)
                .font(.system(size: 28))
                .opacity(meetsNetWorth ? 1.0 : 0.5)
            
            VStack(alignment: .leading, spacing: 2) {
                tierNameRow
                Text(tier.description).font(.caption).foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            tierStatsColumn
        }
    }
    
    private var tierNameRow: some View {
        HStack {
            Text(tier.name)
                .font(.subheadline.bold())
                .foregroundColor(meetsNetWorth ? .white : AppColors.textMuted)
            if !meetsNetWorth {
                Text("🔒").font(.caption)
            }
        }
    }
    
    private var tierStatsColumn: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("-\(Int(tier.taxReduction * 100))%")
                .font(.headline.bold())
                .foregroundColor(meetsNetWorth ? AppColors.mattGreen : AppColors.textMuted)
            Text(game.formatCompact(tier.upgradeCost))
                .font(.caption)
                .foregroundColor(canAfford ? AppColors.textSecondary : AppColors.warning)
        }
    }
    
    @ViewBuilder
    private var tierRequirementsRow: some View {
        if !meetsNetWorth {
            HStack {
                Text("Requires \(game.formatCompact(tier.netWorthRequired)) net worth")
                    .font(.caption2)
                    .foregroundColor(AppColors.warning)
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private var tierUpgradeButton: some View {
        if isNextTier && meetsNetWorth {
            Button(action: { showConfirmation = true }) {
                Text("Upgrade to \(tier.name)")
                    .font(.caption.bold())
                    .foregroundColor(canAfford ? .black : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(canAfford ? AppColors.mattGreen : AppColors.surfaceLight))
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!canAfford)
        }
    }
    
    @ViewBuilder
    private var tierAnnualCostRow: some View {
        if tier.annualCost > 0 {
            HStack {
                Text("📅").font(.caption2)
                Text("\(game.formatCompact(tier.annualCost))/year maintenance")
                    .font(.caption2)
                    .foregroundColor(AppColors.textMuted)
                Spacer()
            }
        }
    }
    
    private func handleUpgrade() {
        if taxManager.upgradePlan(cash: &game.cash) {
            NewsFeedManager.shared.addNews(category: .economy, headline: "🏛️ TAX PLAN UPGRADED - Now saving \(Int(tier.taxReduction * 100))% on taxes with \(tier.name) plan!")
        }
    }
}

// MARK: - Venture Portfolio Row
struct VenturePortfolioRow: View {
    let venture: Venture
    @ObservedObject var game: GameState
    @State private var showIPOSheet = false
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Text(venture.industry.icon)
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(venture.name)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                        if venture.isPublic {
                            Text("📈 PUBLIC")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(AppColors.mattGreen)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(AppColors.mattGreen.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    Text(venture.stage.rawValue)
                        .font(.system(size: 9))
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(game.formatCompact(venture.valuation))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.gold)
                    Text("\(Int(venture.growthRate * 100))% growth")
                        .font(.system(size: 9))
                        .foregroundColor(AppColors.mattGreen)
                }
            }
            
            // Stats row
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Text("👥").font(.system(size: 10))
                    Text("\(venture.employees)")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.textSecondary)
                }
                HStack(spacing: 4) {
                    Text("💰").font(.system(size: 10))
                    Text(game.formatCompact(venture.yearlyRevenue) + "/yr")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
                
                // IPO button if not public yet
                if !venture.isPublic && venture.valuation >= 100_000_000 {
                    Button(action: { showIPOSheet = true }) {
                        Text("GO PUBLIC")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppColors.mattGreen)
                            .cornerRadius(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(10)
        .background(AppColors.surfaceLight)
        .cornerRadius(10)
        .sheet(isPresented: $showIPOSheet) {
            IPOSheet(venture: venture, game: game)
        }
    }
}

// MARK: - IPO Sheet
struct IPOSheet: View {
    let venture: Venture
    @ObservedObject var game: GameState
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var ventureManager = VentureManager.shared
    @State private var sharesOffered: Double = 0.2  // 20% default
    @State private var showConfirmation = false
    
    var ipoValuation: Double {
        venture.valuation * 1.5  // IPO premium
    }
    
    var proceedsFromIPO: Double {
        ipoValuation * sharesOffered
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("📈").font(.system(size: 50))
                        Text("TAKE \(venture.name.uppercased()) PUBLIC")
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        Text("Sell shares to raise capital and unlock stock trading")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Company stats
                    HStack(spacing: 16) {
                        ipoStatBox(icon: "💰", label: "Current Value", value: game.formatCompact(venture.valuation))
                        ipoStatBox(icon: "📈", label: "IPO Value", value: game.formatCompact(ipoValuation))
                    }
                    
                    // Shares to offer
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SHARES TO OFFER")
                            .font(.caption.bold())
                            .foregroundColor(AppColors.textMuted)
                        
                        Slider(value: $sharesOffered, in: 0.1...0.49, step: 0.05)
                            .accentColor(AppColors.mattGreen)
                        
                        HStack {
                            Text("\(Int(sharesOffered * 100))% of company")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                            Spacer()
                            Text("You receive: \(game.formatCompact(proceedsFromIPO))")
                                .font(.caption)
                                .foregroundColor(AppColors.mattGreen)
                        }
                        
                        Text("You'll retain \(Int((1 - sharesOffered) * 100))% ownership")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding()
                    .cardStyle()
                    
                    // Benefits
                    VStack(alignment: .leading, spacing: 8) {
                        Text("IPO BENEFITS")
                            .font(.caption.bold())
                            .foregroundColor(AppColors.textMuted)
                        
                        benefitRow(icon: "💵", text: "Immediate cash from share sale")
                        benefitRow(icon: "📊", text: "Stock price fluctuates with market")
                        benefitRow(icon: "🔄", text: "Buy/sell your own shares anytime")
                        benefitRow(icon: "🚀", text: "Higher valuation visibility")
                    }
                    .padding()
                    .cardStyle()
                    
                    // Go Public button
                    Button(action: { showConfirmation = true }) {
                        HStack {
                            Text("📈")
                            Text("GO PUBLIC")
                                .font(.headline.bold())
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.mattGreen)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("IPO")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .alert("Confirm IPO", isPresented: $showConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Go Public") {
                    executeIPO()
                }
            } message: {
                Text("Take \(venture.name) public at \(game.formatCompact(ipoValuation)) valuation? You'll receive \(game.formatCompact(proceedsFromIPO)) for \(Int(sharesOffered * 100))% of shares.")
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func executeIPO() {
        ventureManager.takeVenturePublic(id: venture.id, sharesOffered: sharesOffered, ipoValuation: ipoValuation)
        game.cash += proceedsFromIPO
        game.totalEarned += proceedsFromIPO
        NewsFeedManager.shared.addNews(category: .markets, headline: "📈 IPO SUCCESS! \(venture.name) goes public at \(game.formatCompact(ipoValuation)) valuation!")
        dismiss()
    }
    
    private func ipoStatBox(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(icon).font(.title2)
            Text(value).font(.subheadline.bold()).foregroundColor(.white)
            Text(label).font(.caption2).foregroundColor(AppColors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppColors.surfaceLight)
        .cornerRadius(10)
    }
    
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Text(icon).font(.caption)
            Text(text).font(.caption).foregroundColor(AppColors.textSecondary)
        }
    }
}

// MARK: - Settings Manager
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var hapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: "hapticsEnabled") }
    }
    
    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled") }
    }
    
    @Published var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled") }
    }
    
    @Published var autoSaveEnabled: Bool {
        didSet { UserDefaults.standard.set(autoSaveEnabled, forKey: "autoSaveEnabled") }
    }
    
    private init() {
        self.hapticsEnabled = UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
        self.soundEnabled = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
        self.notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
        self.autoSaveEnabled = UserDefaults.standard.object(forKey: "autoSaveEnabled") as? Bool ?? true
    }
}

// MARK: - Settings Sheet
struct SettingsSheet: View {
    @ObservedObject var game: GameState
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var settings = SettingsManager.shared
    @State private var showResetAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("⚙️").font(.system(size: 50))
                        Text("SETTINGS")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(.white)
                            .tracking(2)
                    }
                    .padding(.top, 20)
                    
                    // Gameplay Settings
                    VStack(alignment: .leading, spacing: 12) {
                        Text("GAMEPLAY")
                            .font(.caption.bold())
                            .foregroundColor(AppColors.textMuted)
                        
                        settingsToggle(
                            icon: "📳",
                            title: "Haptic Feedback",
                            subtitle: "Vibration on taps and actions",
                            isOn: $settings.hapticsEnabled
                        )
                        
                        settingsToggle(
                            icon: "🔊",
                            title: "Sound Effects",
                            subtitle: "Play sounds on events",
                            isOn: $settings.soundEnabled
                        )
                        
                        settingsToggle(
                            icon: "💾",
                            title: "Auto Save",
                            subtitle: "Automatically save progress",
                            isOn: $settings.autoSaveEnabled
                        )
                    }
                    .padding()
                    .cardStyle()
                    
                    // Notifications
                    VStack(alignment: .leading, spacing: 12) {
                        Text("NOTIFICATIONS")
                            .font(.caption.bold())
                            .foregroundColor(AppColors.textMuted)
                        
                        settingsToggle(
                            icon: "🔔",
                            title: "Push Notifications",
                            subtitle: "Daily reminders and events",
                            isOn: $settings.notificationsEnabled
                        )
                    }
                    .padding()
                    .cardStyle()
                    
                    // Game Stats
                    VStack(alignment: .leading, spacing: 12) {
                        Text("STATISTICS")
                            .font(.caption.bold())
                            .foregroundColor(AppColors.textMuted)
                        
                        statsRow(label: "Total Taps", value: "\(game.totalTaps)")
                        statsRow(label: "Total Earned", value: game.formatCompact(game.totalEarned))
                        statsRow(label: "Lives Lived", value: "\(PrestigeManager.shared.livesLived)")
                        statsRow(label: "Highest Net Worth", value: game.formatCompact(game.highestNetWorth))
                    }
                    .padding()
                    .cardStyle()
                    
                    // Danger Zone
                    VStack(alignment: .leading, spacing: 12) {
                        Text("DANGER ZONE")
                            .font(.caption.bold())
                            .foregroundColor(AppColors.warning)
                        
                        Button(action: { showResetAlert = true }) {
                            HStack {
                                Text("🗑️")
                                Text("Reset All Progress")
                                    .font(.subheadline.bold())
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                            }
                            .foregroundColor(AppColors.warning)
                            .padding()
                            .background(AppColors.warning.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding()
                    .cardStyle()
                    
                    // Version
                    Text("I'm Rich v1.0")
                        .font(.caption)
                        .foregroundColor(AppColors.textMuted)
                        .padding(.top, 10)
                }
                .padding()
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppColors.mattGreen)
                }
            }
            .alert("Reset Progress?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    game.resetForPrestige()
                    PrestigeManager.shared.fullReset()
                    dismiss()
                }
            } message: {
                Text("This will delete ALL your progress including prestige bonuses. This cannot be undone!")
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func settingsToggle(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Text(icon).font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(AppColors.mattGreen)
        }
    }
    
    private func statsRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.white)
        }
    }
}
