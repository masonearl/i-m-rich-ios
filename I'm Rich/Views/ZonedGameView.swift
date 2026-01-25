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
    }
    
    // MARK: - Top Bar
    
    @State private var showGameInfo = false
    
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
                
                // Help/Info button
                Button(action: { showGameInfo = true }) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 18))
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
            
            // Tax Overview
            TaxOverviewView(game: game)
            
            // Skills & Education would go here
            educationSection
            
            // Factions
            factionsSection
        }
        .padding(.horizontal)
    }
    
    func currentCareerSection(_ career: CareerPath) -> some View {
        VStack(spacing: 12) {
            careerHeader(career)
            promotionProgress
        }
        .padding(16)
        .background(careerBackground)
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
            let nextStatusRequired = nextRole?.statusPoints ?? 0
            let canPromote = game.statusPoints >= nextStatusRequired && game.cash >= game.promotionCost
            
            VStack(spacing: 10) {
                // Status progress
                HStack {
                    Text("⭐ Status:")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    Text("\(game.statusPoints)/\(nextStatusRequired)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(game.statusPoints >= nextStatusRequired ? .green : .blue)
                    
                    Spacer()
                    
                    if let next = nextRole {
                        Text("Next: \(next.title)")
                            .font(.system(size: 9))
                            .foregroundColor(.gray)
                    }
                }
                
                // Promote button
                if game.statusPoints >= nextStatusRequired {
                    Button(action: {
                        if game.promote() {
                            FeedbackCoordinator.shared.tap()
                        }
                    }) {
                        HStack {
                            Text("🎉 PROMOTE")
                                .font(.system(size: 12, weight: .bold))
                            Spacer()
                            Text("Cost: \(game.formatCompact(game.promotionCost))")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(canPromote ? .black : .gray)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(canPromote ? Color.green : Color.gray.opacity(0.3))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!canPromote)
                    
                    if !canPromote && game.cash < game.promotionCost {
                        Text("Need \(game.formatCompact(game.promotionCost - game.cash)) more cash")
                            .font(.system(size: 9))
                            .foregroundColor(.orange)
                    }
                } else {
                    // Progress bar to next promotion
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                            Capsule()
                                .fill(Color.blue)
                                .frame(width: geo.size.width * CGFloat(min(game.statusPoints, nextStatusRequired)) / CGFloat(nextStatusRequired))
                        }
                    }
                    .frame(height: 6)
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
            
            // Products
            productsSection
            
            // Contacts / Networking
            contactsSection
        }
        .padding(.horizontal)
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
        VStack(spacing: 12) {
            HStack {
                Text("🏢")
                    .font(.system(size: 24))
                VStack(alignment: .leading) {
                    Text(CompanyManager.shared.state.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("\(CompanyManager.shared.state.totalEmployees) employees")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Valuation")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                    Text(game.formatCompact(CompanyManager.shared.state.companyValuation))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.purple)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.purple.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
        )
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
            if game.netWorth >= 1_000_000_000 {
                Button(action: {
                    // Calculate prestige preview first
                    let preview = PrestigeManager.shared.calculatePrestigePreview(
                        currentEarnings: game.totalEarned,
                        currentAge: lifecycle.currentAge,
                        yearsPlayed: lifecycle.gameYearsPassed
                    )
                    PrestigeManager.shared.pendingPrestigePreview = preview
                    PrestigeManager.shared.showPrestigeConfirmation = true
                }) {
                    HStack {
                        Text("🔄 PRESTIGE")
                            .font(.system(size: 12, weight: .bold))
                        Spacer()
                        Text("Reset with \(Int((PrestigeManager.shared.legacyMultiplier + 0.1) * 100))% bonus")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 1, green: 0.84, blue: 0))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                HStack {
                    Text("🔒 Prestige at $1B")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(game.formatCompact(1_000_000_000 - game.netWorth)) to go")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                }
            }
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
    
    var familySection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("👨‍👩‍👧‍👦")
                Text("DYNASTY")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            
            FamilyOverviewView(compact: true)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
        )
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
    
    var canAffordMin: Bool {
        game.cash >= investment.minInvestment
    }
    
    var hasInvestment: Bool {
        investment.amountInvested > 0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main row - compact
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
    
    var body: some View {
        VStack(spacing: 8) {
            // Row 1: Net Worth + Age
            HStack(alignment: .center) {
                // Net Worth (main focus)
                VStack(alignment: .leading, spacing: 2) {
                    Text("NET WORTH")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(AppColors.textMuted)
                    
                    Text(game.formatCompact(game.netWorth))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.mattGreen)
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
