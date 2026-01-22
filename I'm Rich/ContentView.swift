//
//  ContentView.swift
//  I'm Rich
//
//  Created by Mason Earl on 10/26/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var game = GameState()
    @State private var showSplash = true
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
    
    let accentColor = Color(red: 0.4, green: 0.7, blue: 0.4)
    
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
                mainGameView
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
                VStack(spacing: 16) {
                    // Header: Phase & Resources
                    headerSection
                    
                    // Tap Area
                    tapSection
                    
                    // Career (Phase 2+)
                    if game.currentPhase.rawValue >= GamePhase.careerLeverage.rawValue || game.selectedCareer != nil {
                        careerSection
                    }
                    
                    // Opportunity Card
                    if let opportunity = game.currentOpportunity {
                        opportunitySection(opportunity)
                    }
                    
                    // Investments
                    if !game.availableInvestments.isEmpty {
                        investmentSection
                    }
                    
                    // Upgrades
                    if !game.availableUpgrades.isEmpty {
                        upgradeSection
                    }
                    
                    // Products (Phase 3+)
                    if game.currentPhase.rawValue >= GamePhase.portfolioEngine.rawValue && !game.availableProducts.isEmpty {
                        productSection
                    }
                    
                    // Contacts / Meetings
                    if !game.availableContacts.isEmpty {
                        contactSection
                    }
                    
                    // Stats
                    statsSection
                    
                    Spacer(minLength: 50)
                }
                .padding()
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
        VStack(spacing: 12) {
            // Phase indicator
            HStack {
                Text(game.currentPhase.icon)
                    .font(.system(size: 24))
                Text("Phase \(game.currentPhase.rawValue): \(game.currentPhase.name)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(accentColor.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(accentColor.opacity(0.3), lineWidth: 1)
                    )
            )
            
            // Phase progress
            if let nextPhase = game.nextPhase {
                VStack(spacing: 6) {
                    HStack {
                        Text("Next: \(nextPhase.name)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                        Spacer()
                        Text(game.formatCompact(nextPhase.unlockRequirement))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(accentColor)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 6)
                            
                            Capsule()
                                .fill(accentColor)
                                .frame(width: max(6, geometry.size.width * game.phaseProgress), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
            
            // Resources row
            HStack(spacing: 20) {
                resourceBadge(icon: "💵", label: "Cash", value: game.formatCompact(game.cash))
                resourceBadge(icon: "⭐", label: "Status", value: "\(game.statusPoints)")
                resourceBadge(icon: "📈", label: "/sec", value: game.formatCompact(game.passiveIncomePerSecond))
            }
        }
    }
    
    func resourceBadge(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.system(size: 20))
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Tap Section
    
    var tapSection: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "HUSTLE", icon: "💪")
            
            // Tap button
            Button(action: { game.tap() }) {
                VStack(spacing: 8) {
                    Text("💰")
                        .font(.system(size: 60))
                    
                    Text("TAP TO EARN")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(2)
                    
                    Text("+\(game.formatCompact(game.tapValue))")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(accentColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(accentColor.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(accentColor.opacity(0.4), lineWidth: 2)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Streak indicator
            if game.currentStreak > 0 {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("Streak: \(game.currentStreak)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.orange)
                    
                    if game.streakMultiplier > 1 {
                        Text("(\(Int(game.streakMultiplier))x)")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.yellow)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.1))
                )
            }
        }
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
                
                // Stats
                HStack(spacing: 16) {
                    VStack {
                        Text("Cost")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        Text(game.formatCompact(opportunity.cost))
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
                        Text(game.formatCompact(opportunity.successReward))
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
                                    .fill(game.cash >= opportunity.cost ? accentColor : Color.gray)
                            )
                    }
                    .disabled(game.cash < opportunity.cost)
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
        VStack(spacing: 12) {
            sectionHeader(title: "INVESTMENTS", icon: "📊")
            
            ForEach(game.availableInvestments) { investment in
                Button(action: {
                    selectedInvestment = investment
                    showInvestSheet = true
                }) {
                    HStack {
                        Text(investment.icon)
                            .font(.system(size: 24))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(investment.name)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 8) {
                                Text("\(Int(investment.baseReturn * 100))% return")
                                    .font(.system(size: 11))
                                    .foregroundColor(accentColor)
                                
                                Text(investment.riskLevel.rawValue)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(investment.riskLevel.color)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(investment.riskLevel.color.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                        
                        Spacer()
                        
                        if investment.amountInvested > 0 {
                            VStack(alignment: .trailing) {
                                Text(game.formatCompact(investment.amountInvested))
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                Text("invested")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )
                }
            }
        }
    }
    
    // MARK: - Upgrade Section
    
    var upgradeSection: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "UPGRADES", icon: "⬆️")
            
            ForEach(game.availableUpgrades) { upgrade in
                Button(action: {
                    _ = game.purchaseUpgrade(upgrade.id)
                }) {
                    HStack {
                        Text(upgrade.icon)
                            .font(.system(size: 24))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(upgrade.name)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            Text(upgrade.description)
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Text(game.formatCompact(upgrade.cost))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(game.cash >= upgrade.cost ? accentColor : .gray)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(game.cash >= upgrade.cost ? accentColor.opacity(0.1) : Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(game.cash >= upgrade.cost ? accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
                            )
                    )
                }
                .disabled(game.cash < upgrade.cost)
            }
        }
    }
    
    // MARK: - Product Section
    
    var productSection: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "PRODUCT LAUNCHES", icon: "🚀")
            
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
                            .font(.system(size: 24))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(product.name)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 8) {
                                Text("\(Int(product.successChance * 100))% success")
                                    .font(.system(size: 11))
                                    .foregroundColor(.yellow)
                                Text("+\(game.formatCompact(product.ongoingRevenue))/sec")
                                    .font(.system(size: 11))
                                    .foregroundColor(accentColor)
                            }
                        }
                        
                        Spacer()
                        
                        let totalCost = product.developmentCost + product.marketingCost
                        Text(game.formatCompact(totalCost))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(game.cash >= totalCost ? accentColor : .gray)
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
                .disabled(game.cash < product.developmentCost + product.marketingCost)
            }
        }
    }
    
    // MARK: - Contact Section
    
    var contactSection: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "NETWORKING", icon: "🤝")
            
            ForEach(game.availableContacts) { contact in
                Button(action: {
                    _ = game.meetContact(contact.id)
                }) {
                    HStack {
                        Text(contact.icon)
                            .font(.system(size: 24))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(contact.name)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            Text(contact.title)
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("+\(game.formatCompact(contact.bonusOnMeet))")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(accentColor)
                            Text("bonus")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }
        }
    }
    
    // MARK: - Stats Section
    
    var statsSection: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "STATISTICS", icon: "📈")
            
            VStack(spacing: 8) {
                statRow(label: "Total Earned", value: game.formatCompact(game.totalEarned))
                statRow(label: "Total Taps", value: "\(game.totalTaps)")
                statRow(label: "Highest Streak", value: "\(game.highestStreak)")
                statRow(label: "Tap Value", value: game.formatCompact(game.tapValue))
                statRow(label: "Tap Multiplier", value: String(format: "%.1fx", game.tapMultiplier))
                
                if game.selectedCareer != nil, let role = game.currentRole {
                    statRow(label: "Current Role", value: role.title)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
        }
    }
    
    func statRow(label: String, value: String) -> some View {
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
    
    // MARK: - Helpers
    
    func sectionHeader(title: String, icon: String) -> some View {
        HStack {
            Text(icon)
                .font(.system(size: 16))
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.gray)
                .tracking(1.5)
            Spacer()
        }
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
    @State private var investAmount: String = ""
    
    let accentColor = Color(red: 0.4, green: 0.7, blue: 0.4)
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text(investment.icon)
                        .font(.system(size: 40))
                    
                    VStack(alignment: .leading) {
                        Text(investment.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        Text(investment.description)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                
                // Stats
                HStack(spacing: 20) {
                    VStack {
                        Text("Return")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Text("\(Int(investment.baseReturn * 100))%")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(accentColor)
                    }
                    
                    VStack {
                        Text("Risk")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Text(investment.riskLevel.rawValue)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(investment.riskLevel.color)
                    }
                    
                    VStack {
                        Text("Min")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Text(game.formatCompact(investment.minInvestment))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack {
                        Text("Invested")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Text(game.formatCompact(investment.amountInvested))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                )
                
                // Investment input
                VStack(spacing: 12) {
                    Text("Available: \(game.formatCompact(game.cash))")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    TextField("Amount to invest", text: $investAmount)
                        .keyboardType(.numberPad)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                        )
                    
                    // Quick buttons
                    HStack(spacing: 12) {
                        quickInvestButton(label: "Min", amount: investment.minInvestment)
                        quickInvestButton(label: "25%", amount: game.cash * 0.25)
                        quickInvestButton(label: "50%", amount: game.cash * 0.5)
                        quickInvestButton(label: "Max", amount: game.cash)
                    }
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 16) {
                    Button(action: { isPresented = false }) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                    
                    Button(action: {
                        if let amount = Double(investAmount) {
                            if game.invest(in: investment.id, amount: amount) {
                                isPresented = false
                            }
                        }
                    }) {
                        Text("Invest")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(accentColor)
                            )
                    }
                }
            }
            .padding()
        }
    }
    
    func quickInvestButton(label: String, amount: Double) -> some View {
        Button(action: {
            investAmount = String(Int(max(amount, investment.minInvestment)))
        }) {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(accentColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accentColor.opacity(0.15))
                )
        }
    }
}

// MARK: - Splash Screen

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
                                    Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.3),
                                    Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 180, height: 180)
                        .scaleEffect(scale)
                        .opacity(opacity)
                    
                    Text("💰")
                        .font(.system(size: 80))
                        .scaleEffect(scale)
                        .opacity(opacity)
                }
                
                VStack(spacing: 8) {
                    Text("WEALTH FORGE")
                        .font(.system(size: 36, weight: .black))
                        .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.4))
                        .tracking(3)
                        .opacity(opacity)
                    
                    Text("From Hustle to Empire")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .opacity(opacity)
                }
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

#Preview {
    ContentView()
}
