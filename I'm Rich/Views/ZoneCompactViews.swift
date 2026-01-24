//
//  ZoneCompactViews.swift
//  Life of Wealth
//
//  Compact versions of views for zone-based layout
//

import SwiftUI

// MARK: - Family Overview View (Compact)
struct FamilyOverviewView: View {
    @ObservedObject var family = FamilyManager.shared
    @ObservedObject var lifecycle = LifeCycleManager.shared
    let compact: Bool
    
    init(compact: Bool = true) {
        self.compact = compact
    }
    
    var body: some View {
        if compact {
            compactView
        } else {
            FamilyPanelView()
        }
    }
    
    var compactView: some View {
        VStack(spacing: 8) {
            // Family summary row
            HStack(spacing: 12) {
                // Partner status
                if let partner = family.state.partner {
                    HStack(spacing: 6) {
                        Text(partner.personality.icon)
                            .font(.system(size: 16))
                        VStack(alignment: .leading, spacing: 1) {
                            HStack(spacing: 4) {
                                Text(partner.name)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white)
                                if partner.isMarried {
                                    Text("💍")
                                        .font(.system(size: 9))
                                }
                            }
                            Text("❤️ \(partner.relationshipLevel)")
                                .font(.system(size: 9))
                                .foregroundColor(.red)
                        }
                    }
                } else if lifecycle.currentAge >= 25 {
                    HStack(spacing: 6) {
                        Text("💝")
                            .font(.system(size: 16))
                        Text("Ready to date")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                } else {
                    HStack(spacing: 6) {
                        Text("👤")
                            .font(.system(size: 16))
                        Text("Single")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Children count
                if !family.state.children.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(family.state.children.prefix(3)) { child in
                            let stage = child.lifeStage(currentYear: lifecycle.gameYearsPassed + lifecycle.startingAge)
                            Text(stage.icon)
                                .font(.system(size: 12))
                        }
                        if family.state.children.count > 3 {
                            Text("+\(family.state.children.count - 3)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.15))
                    )
                }
            }
            
            // Family size indicator
            if family.state.familySize > 1 {
                HStack {
                    Text("Family of \(family.state.familySize)")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                    Spacer()
                    if family.state.totalChildExpenses > 0 {
                        Text("$\(Int(family.state.totalChildExpenses / 1000))K/yr")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.orange)
                    }
                }
            }
        }
    }
}

// MARK: - Wealth Dimensions View (Compact)
struct WealthDimensionsView: View {
    @ObservedObject var wealth = WealthManager.shared
    let compact: Bool
    
    init(compact: Bool = true) {
        self.compact = compact
    }
    
    var body: some View {
        if compact {
            compactView
        } else {
            fullView
        }
    }
    
    var compactView: some View {
        HStack(spacing: 8) {
            ForEach(WealthDimension.allCases, id: \.self) { dimension in
                CompactDimensionIndicator(
                    dimension: dimension,
                    value: wealth.state[dimension]
                )
            }
        }
    }
    
    var fullView: some View {
        VStack(spacing: 8) {
            ForEach(WealthDimension.allCases, id: \.self) { dimension in
                FullDimensionRow(
                    dimension: dimension,
                    value: wealth.state[dimension]
                )
            }
        }
    }
}

struct CompactDimensionIndicator: View {
    let dimension: WealthDimension
    let value: Int
    
    var body: some View {
        VStack(spacing: 4) {
            Text(dimension.icon)
                .font(.system(size: 14))
            
            // Mini progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 4)
                    
                    Capsule()
                        .fill(dimension.color)
                        .frame(width: geometry.size.width * CGFloat(value) / 100, height: 4)
                }
            }
            .frame(height: 4)
            
            Text("\(value)")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(dimension.color)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FullDimensionRow: View {
    let dimension: WealthDimension
    let value: Int
    
    var body: some View {
        HStack(spacing: 10) {
            Text(dimension.icon)
                .font(.system(size: 14))
            
            Text(dimension.rawValue)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 80, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(dimension.color)
                        .frame(width: geometry.size.width * CGFloat(value) / 100, height: 6)
                }
            }
            .frame(height: 6)
            
            Text("\(value)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(dimension.color)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

// MARK: - Leaderboard View (Compact)
struct LeaderboardView: View {
    let playerNetWorth: Double
    let compact: Bool
    
    @ObservedObject var company = CompanyManager.shared
    
    let accentColor = Color(red: 0.4, green: 0.7, blue: 0.4)
    let goldColor = Color(red: 1, green: 0.84, blue: 0)
    
    init(playerNetWorth: Double, compact: Bool = true) {
        self.playerNetWorth = playerNetWorth
        self.compact = compact
    }
    
    var playerRank: Int {
        company.getPlayerRank(playerNetWorth: playerNetWorth)
    }
    
    var nextToPass: Billionaire? {
        company.getNextBillionaireToPass(playerNetWorth: playerNetWorth)
    }
    
    var body: some View {
        if compact {
            compactView
        } else {
            BillionaireLeaderboardView(playerNetWorth: playerNetWorth)
        }
    }
    
    var compactView: some View {
        VStack(spacing: 10) {
            // Rank badge
            HStack {
                // Your rank
                HStack(spacing: 6) {
                    Text("🏆")
                        .font(.system(size: 14))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("YOUR RANK")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.gray)
                            .tracking(0.5)
                        Text("#\(playerRank)")
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(playerRank <= 10 ? goldColor : accentColor)
                    }
                }
                
                Spacer()
                
                // Total billionaires
                VStack(alignment: .trailing, spacing: 1) {
                    Text("OF")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.gray)
                    Text("\(Billionaire.leaderboard.count)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            // Next to pass
            if let next = nextToPass {
                HStack(spacing: 8) {
                    Text(next.icon)
                        .font(.system(size: 14))
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Next: \(next.name)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                        Text(next.company)
                            .font(.system(size: 8))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("Need")
                            .font(.system(size: 8))
                            .foregroundColor(.gray)
                        Text(formatCompact(next.netWorth - playerNetWorth))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.orange)
                    }
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.03))
                )
            }
            
            // Top 3 preview
            HStack(spacing: 8) {
                ForEach(Array(Billionaire.leaderboard.filter { $0.id != "you" }.prefix(3).enumerated()), id: \.element.id) { index, billionaire in
                    VStack(spacing: 4) {
                        Text(index == 0 ? "🥇" : index == 1 ? "🥈" : "🥉")
                            .font(.system(size: 12))
                        Text(billionaire.icon)
                            .font(.system(size: 14))
                        Text(billionaire.formattedNetWorth)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.02))
            )
        }
    }
    
    func formatCompact(_ value: Double) -> String {
        switch value {
        case 1_000_000_000_000...: return String(format: "$%.1fT", value / 1_000_000_000_000)
        case 1_000_000_000...: return String(format: "$%.1fB", value / 1_000_000_000)
        case 1_000_000...: return String(format: "$%.1fM", value / 1_000_000)
        case 1_000...: return String(format: "$%.1fK", value / 1_000)
        default: return String(format: "$%.0f", value)
        }
    }
}
