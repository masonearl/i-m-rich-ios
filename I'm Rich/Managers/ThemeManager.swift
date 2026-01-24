//
//  ThemeManager.swift
//  I'm Rich
//
//  Unlockable color themes and cosmetic progression
//

import SwiftUI
import Combine

// MARK: - App Theme
struct AppTheme: Identifiable, Codable {
    let id: String
    let name: String
    let icon: String
    let primaryColorHex: String
    let secondaryColorHex: String
    let accentColorHex: String
    let unlockCondition: String
    var unlocked: Bool = false
    
    var primaryColor: Color {
        Color(hex: primaryColorHex)
    }
    
    var secondaryColor: Color {
        Color(hex: secondaryColorHex)
    }
    
    var accentColor: Color {
        Color(hex: accentColorHex)
    }
}

// MARK: - All Themes
let allThemes: [AppTheme] = [
    AppTheme(
        id: "default",
        name: "Wealth Green",
        icon: "💚",
        primaryColorHex: "#66B366",
        secondaryColorHex: "#4D994D",
        accentColorHex: "#66B366",
        unlockCondition: "Default theme",
        unlocked: true
    ),
    AppTheme(
        id: "gold_rush",
        name: "Gold Rush",
        icon: "🏆",
        primaryColorHex: "#FFD700",
        secondaryColorHex: "#DAA520",
        accentColorHex: "#FFD700",
        unlockCondition: "Earn $1,000,000 total"
    ),
    AppTheme(
        id: "wall_street",
        name: "Wall Street",
        icon: "📊",
        primaryColorHex: "#4169E1",
        secondaryColorHex: "#1E3A8A",
        accentColorHex: "#4169E1",
        unlockCondition: "Choose Finance career"
    ),
    AppTheme(
        id: "tech_startup",
        name: "Tech Startup",
        icon: "💻",
        primaryColorHex: "#8B5CF6",
        secondaryColorHex: "#6D28D9",
        accentColorHex: "#8B5CF6",
        unlockCondition: "Choose Tech career"
    ),
    AppTheme(
        id: "creator_mode",
        name: "Creator Mode",
        icon: "🎨",
        primaryColorHex: "#EC4899",
        secondaryColorHex: "#BE185D",
        accentColorHex: "#EC4899",
        unlockCondition: "Choose Creator career"
    ),
    AppTheme(
        id: "industrial",
        name: "Industrial",
        icon: "🔧",
        primaryColorHex: "#F97316",
        secondaryColorHex: "#C2410C",
        accentColorHex: "#F97316",
        unlockCondition: "Choose Trades career"
    ),
    AppTheme(
        id: "billionaire_black",
        name: "Billionaire Black",
        icon: "🖤",
        primaryColorHex: "#A1A1AA",
        secondaryColorHex: "#71717A",
        accentColorHex: "#E4E4E7",
        unlockCondition: "Earn $1,000,000,000 total"
    ),
    AppTheme(
        id: "legendary_streak",
        name: "Legendary Streak",
        icon: "🔥",
        primaryColorHex: "#EF4444",
        secondaryColorHex: "#DC2626",
        accentColorHex: "#F97316",
        unlockCondition: "30-day login streak"
    )
]

// MARK: - Money Emoji Options
struct MoneyEmoji: Identifiable, Codable {
    let id: String
    let emoji: String
    let name: String
    let unlockCondition: String
    var unlocked: Bool = false
}

let allMoneyEmojis: [MoneyEmoji] = [
    MoneyEmoji(id: "dollar", emoji: "💵", name: "US Dollar", unlockCondition: "Default", unlocked: true),
    MoneyEmoji(id: "moneybag", emoji: "💰", name: "Money Bag", unlockCondition: "Default", unlocked: true),
    MoneyEmoji(id: "coin", emoji: "🪙", name: "Gold Coin", unlockCondition: "Earn $10,000"),
    MoneyEmoji(id: "euro", emoji: "💶", name: "Euro", unlockCondition: "Earn $100,000"),
    MoneyEmoji(id: "pound", emoji: "💷", name: "British Pound", unlockCondition: "Earn $500,000"),
    MoneyEmoji(id: "yen", emoji: "💴", name: "Japanese Yen", unlockCondition: "Earn $1,000,000"),
    MoneyEmoji(id: "diamond", emoji: "💎", name: "Diamond", unlockCondition: "Earn $10,000,000"),
    MoneyEmoji(id: "crown", emoji: "👑", name: "Crown", unlockCondition: "Earn $100,000,000"),
    MoneyEmoji(id: "gem", emoji: "💍", name: "Ring", unlockCondition: "Earn $1,000,000,000")
]

// MARK: - Office Background
struct OfficeBackground: Identifiable, Codable {
    let id: String
    let name: String
    let icon: String
    let gradientStartHex: String
    let gradientEndHex: String
    let unlockRequirement: Double
    var unlocked: Bool = false
    
    var gradientStart: Color {
        Color(hex: gradientStartHex)
    }
    
    var gradientEnd: Color {
        Color(hex: gradientEndHex)
    }
}

let allOfficeBackgrounds: [OfficeBackground] = [
    OfficeBackground(id: "basement", name: "Basement", icon: "🏚️", gradientStartHex: "#1a1a1a", gradientEndHex: "#0d0d0d", unlockRequirement: 0, unlocked: true),
    OfficeBackground(id: "cubicle", name: "Cubicle", icon: "🏢", gradientStartHex: "#2d2d2d", gradientEndHex: "#1a1a1a", unlockRequirement: 10_000),
    OfficeBackground(id: "office", name: "Private Office", icon: "🚪", gradientStartHex: "#3d3d3d", gradientEndHex: "#2d2d2d", unlockRequirement: 100_000),
    OfficeBackground(id: "corner", name: "Corner Office", icon: "🌆", gradientStartHex: "#1e3a5f", gradientEndHex: "#0d1b2a", unlockRequirement: 1_000_000),
    OfficeBackground(id: "penthouse", name: "Penthouse", icon: "🏙️", gradientStartHex: "#2d1b4e", gradientEndHex: "#1a1033", unlockRequirement: 10_000_000),
    OfficeBackground(id: "yacht", name: "Super Yacht", icon: "🛥️", gradientStartHex: "#0c4a6e", gradientEndHex: "#082f49", unlockRequirement: 100_000_000),
    OfficeBackground(id: "island", name: "Private Island", icon: "🏝️", gradientStartHex: "#14532d", gradientEndHex: "#052e16", unlockRequirement: 1_000_000_000)
]

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var themes: [AppTheme] {
        didSet { save() }
    }
    @Published var currentThemeId: String {
        didSet { 
            UserDefaults.standard.set(currentThemeId, forKey: "currentThemeId")
        }
    }
    @Published var moneyEmojis: [MoneyEmoji] {
        didSet { saveEmojis() }
    }
    @Published var selectedMoneyEmojiId: String {
        didSet {
            UserDefaults.standard.set(selectedMoneyEmojiId, forKey: "selectedMoneyEmojiId")
        }
    }
    @Published var officeBackgrounds: [OfficeBackground] {
        didSet { saveBackgrounds() }
    }
    @Published var currentOfficeId: String {
        didSet {
            UserDefaults.standard.set(currentOfficeId, forKey: "currentOfficeId")
        }
    }
    
    var currentTheme: AppTheme {
        themes.first { $0.id == currentThemeId } ?? themes[0]
    }
    
    var selectedMoneyEmoji: MoneyEmoji {
        moneyEmojis.first { $0.id == selectedMoneyEmojiId } ?? moneyEmojis[0]
    }
    
    var currentOffice: OfficeBackground {
        officeBackgrounds.first { $0.id == currentOfficeId } ?? officeBackgrounds[0]
    }
    
    var unlockedThemes: [AppTheme] {
        themes.filter { $0.unlocked }
    }
    
    private init() {
        // Load themes
        if let data = UserDefaults.standard.data(forKey: "themes"),
           let decoded = try? JSONDecoder().decode([AppTheme].self, from: data) {
            self.themes = decoded
        } else {
            self.themes = allThemes
        }
        
        self.currentThemeId = UserDefaults.standard.string(forKey: "currentThemeId") ?? "default"
        
        // Load emojis
        if let data = UserDefaults.standard.data(forKey: "moneyEmojis"),
           let decoded = try? JSONDecoder().decode([MoneyEmoji].self, from: data) {
            self.moneyEmojis = decoded
        } else {
            self.moneyEmojis = allMoneyEmojis
        }
        
        self.selectedMoneyEmojiId = UserDefaults.standard.string(forKey: "selectedMoneyEmojiId") ?? "dollar"
        
        // Load backgrounds
        if let data = UserDefaults.standard.data(forKey: "officeBackgrounds"),
           let decoded = try? JSONDecoder().decode([OfficeBackground].self, from: data) {
            self.officeBackgrounds = decoded
        } else {
            self.officeBackgrounds = allOfficeBackgrounds
        }
        
        self.currentOfficeId = UserDefaults.standard.string(forKey: "currentOfficeId") ?? "basement"
    }
    
    func unlockTheme(_ name: String) {
        if let index = themes.firstIndex(where: { $0.name == name || $0.id == name }) {
            themes[index].unlocked = true
        }
    }
    
    func unlockThemeForCareer(_ career: CareerPath) {
        switch career {
        case .tech:
            unlockTheme("tech_startup")
        case .finance:
            unlockTheme("wall_street")
        case .creator:
            unlockTheme("creator_mode")
        case .trades:
            unlockTheme("industrial")
        }
    }
    
    func checkUnlocks(totalEarned: Double, loginStreak: Int) {
        // Wealth-based unlocks
        if totalEarned >= 1_000_000 {
            unlockTheme("gold_rush")
        }
        if totalEarned >= 1_000_000_000 {
            unlockTheme("billionaire_black")
        }
        
        // Streak-based unlocks
        if loginStreak >= 30 {
            unlockTheme("legendary_streak")
        }
        
        // Money emoji unlocks
        for i in 0..<moneyEmojis.count {
            switch moneyEmojis[i].id {
            case "coin": if totalEarned >= 10_000 { moneyEmojis[i].unlocked = true }
            case "euro": if totalEarned >= 100_000 { moneyEmojis[i].unlocked = true }
            case "pound": if totalEarned >= 500_000 { moneyEmojis[i].unlocked = true }
            case "yen": if totalEarned >= 1_000_000 { moneyEmojis[i].unlocked = true }
            case "diamond": if totalEarned >= 10_000_000 { moneyEmojis[i].unlocked = true }
            case "crown": if totalEarned >= 100_000_000 { moneyEmojis[i].unlocked = true }
            case "gem": if totalEarned >= 1_000_000_000 { moneyEmojis[i].unlocked = true }
            default: break
            }
        }
        
        // Office background unlocks
        for i in 0..<officeBackgrounds.count {
            if totalEarned >= officeBackgrounds[i].unlockRequirement {
                officeBackgrounds[i].unlocked = true
            }
        }
    }
    
    func selectTheme(_ themeId: String) {
        guard themes.first(where: { $0.id == themeId })?.unlocked == true else { return }
        currentThemeId = themeId
    }
    
    func selectMoneyEmoji(_ emojiId: String) {
        guard moneyEmojis.first(where: { $0.id == emojiId })?.unlocked == true else { return }
        selectedMoneyEmojiId = emojiId
    }
    
    func selectOffice(_ officeId: String) {
        guard officeBackgrounds.first(where: { $0.id == officeId })?.unlocked == true else { return }
        currentOfficeId = officeId
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(themes) {
            UserDefaults.standard.set(data, forKey: "themes")
        }
    }
    
    private func saveEmojis() {
        if let data = try? JSONEncoder().encode(moneyEmojis) {
            UserDefaults.standard.set(data, forKey: "moneyEmojis")
        }
    }
    
    private func saveBackgrounds() {
        if let data = try? JSONEncoder().encode(officeBackgrounds) {
            UserDefaults.standard.set(data, forKey: "officeBackgrounds")
        }
    }
    
    func reset() {
        themes = allThemes
        currentThemeId = "default"
        moneyEmojis = allMoneyEmojis
        selectedMoneyEmojiId = "dollar"
        officeBackgrounds = allOfficeBackgrounds
        currentOfficeId = "basement"
    }
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Theme Settings View
struct ThemeSettingsView: View {
    @ObservedObject var themeManager = ThemeManager.shared
    @ObservedObject var hapticManager = HapticManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Text("Settings")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Feedback Settings Section
                    sectionHeader("FEEDBACK")
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Haptic Feedback")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            Text("Vibrations when tapping and for events")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Toggle("", isOn: $hapticManager.hapticsEnabled)
                            .labelsHidden()
                            .tint(themeManager.currentTheme.accentColor)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )
                    
                    // Themes Section
                    sectionHeader("THEMES")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(themeManager.themes) { theme in
                            themeCard(theme)
                        }
                    }
                    
                    // Money Emoji Section
                    sectionHeader("MONEY STYLE")
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(themeManager.moneyEmojis) { emoji in
                            emojiCard(emoji)
                        }
                    }
                    
                    // Office Section
                    sectionHeader("OFFICE")
                    ForEach(themeManager.officeBackgrounds) { office in
                        officeRow(office)
                    }
                }
                .padding()
            }
        }
    }
    
    func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.gray)
                .tracking(1.5)
            Spacer()
        }
    }
    
    func themeCard(_ theme: AppTheme) -> some View {
        Button(action: { themeManager.selectTheme(theme.id) }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(theme.primaryColor)
                        .frame(width: 50, height: 50)
                    
                    if !theme.unlocked {
                        Circle()
                            .fill(Color.black.opacity(0.7))
                            .frame(width: 50, height: 50)
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                    }
                    
                    if theme.id == themeManager.currentThemeId {
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 54, height: 54)
                    }
                }
                
                Text(theme.name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(theme.unlocked ? .white : .gray)
                
                Text(theme.icon)
                    .font(.system(size: 16))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.id == themeManager.currentThemeId ? theme.primaryColor.opacity(0.2) : Color.white.opacity(0.05))
            )
        }
        .disabled(!theme.unlocked)
    }
    
    func emojiCard(_ emoji: MoneyEmoji) -> some View {
        Button(action: { themeManager.selectMoneyEmoji(emoji.id) }) {
            VStack(spacing: 4) {
                ZStack {
                    Text(emoji.emoji)
                        .font(.system(size: 28))
                        .opacity(emoji.unlocked ? 1.0 : 0.3)
                    
                    if !emoji.unlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    if emoji.id == themeManager.selectedMoneyEmojiId {
                        Circle()
                            .stroke(themeManager.currentTheme.primaryColor, lineWidth: 2)
                            .frame(width: 44, height: 44)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(emoji.id == themeManager.selectedMoneyEmojiId ? themeManager.currentTheme.primaryColor.opacity(0.2) : Color.white.opacity(0.05))
            )
        }
        .disabled(!emoji.unlocked)
    }
    
    func officeRow(_ office: OfficeBackground) -> some View {
        Button(action: { themeManager.selectOffice(office.id) }) {
            HStack(spacing: 12) {
                Text(office.icon)
                    .font(.system(size: 24))
                    .opacity(office.unlocked ? 1.0 : 0.3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(office.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(office.unlocked ? .white : .gray)
                    
                    if !office.unlocked {
                        Text("Requires \(formatCompact(office.unlockRequirement))")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                if office.id == themeManager.currentOfficeId {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(themeManager.currentTheme.primaryColor)
                } else if !office.unlocked {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: office.unlocked ? [office.gradientStart, office.gradientEnd] : [Color.white.opacity(0.05), Color.white.opacity(0.03)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(office.id == themeManager.currentOfficeId ? themeManager.currentTheme.primaryColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .disabled(!office.unlocked)
    }
    
    func formatCompact(_ value: Double) -> String {
        switch value {
        case 1_000_000_000...: return String(format: "$%.0fB", value / 1_000_000_000)
        case 1_000_000...: return String(format: "$%.0fM", value / 1_000_000)
        case 1_000...: return String(format: "$%.0fK", value / 1_000)
        default: return "$\(Int(value))"
        }
    }
}
