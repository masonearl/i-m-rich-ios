//
//  FeedbackManagers.swift
//  I'm Rich
//
//  Haptic feedback and sound effect management
//

import SwiftUI
import Combine
import AVFoundation
import AudioToolbox

// MARK: - Haptic Manager
class HapticManager: ObservableObject {
    static let shared = HapticManager()
    
    @Published var hapticsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(hapticsEnabled, forKey: "hapticsEnabled")
        }
    }
    
    private init() {
        // Default to true if not set
        if UserDefaults.standard.object(forKey: "hapticsEnabled") == nil {
            self.hapticsEnabled = true
        } else {
            self.hapticsEnabled = UserDefaults.standard.bool(forKey: "hapticsEnabled")
        }
    }
    
    // Light tap - for regular taps
    func lightTap() {
        guard hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    // Medium tap - for purchases, investments
    func mediumTap() {
        guard hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    // Heavy tap - for major achievements, phase unlocks
    func heavyTap() {
        guard hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    // Success - for successful actions
    func success() {
        guard hapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // Warning - for risky actions
    func warning() {
        guard hapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    // Error - for failed actions
    func error() {
        guard hapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    // Selection - for UI selections
    func selection() {
        guard hapticsEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    // Streak milestone pattern
    func streakMilestone(_ streak: Int) {
        switch streak {
        case 100:
            mediumTap()
        case 500:
            heavyTap()
        case 1000:
            // Double tap pattern
            heavyTap()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.heavyTap()
            }
        case 5000, 10000:
            // Triple tap pattern
            heavyTap()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.heavyTap()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.heavyTap()
            }
        default:
            break
        }
    }
    
    // Achievement unlock pattern
    func achievementUnlock() {
        success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.heavyTap()
        }
    }
    
    // Phase unlock pattern
    func phaseUnlock() {
        heavyTap()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.success()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.heavyTap()
        }
    }
    
    // Money earned pattern (varies by amount)
    func moneyEarned(_ amount: Double) {
        if amount >= 1_000_000 {
            heavyTap()
        } else if amount >= 10_000 {
            mediumTap()
        } else {
            lightTap()
        }
    }
}

// MARK: - Sound Manager
class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    @Published var isMuted: Bool {
        didSet {
            UserDefaults.standard.set(isMuted, forKey: "soundMuted")
        }
    }
    
    @Published var volume: Float {
        didSet {
            UserDefaults.standard.set(volume, forKey: "soundVolume")
        }
    }
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    
    private init() {
        self.isMuted = UserDefaults.standard.bool(forKey: "soundMuted")
        self.volume = UserDefaults.standard.float(forKey: "soundVolume")
        if volume == 0 { volume = 0.7 } // Default volume
        
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Sound Effects using System Sounds
    
    func playTap() {
        guard !isMuted else { return }
        // Use system sound for reliability
        AudioServicesPlaySystemSound(1104) // Tock sound
    }
    
    func playTapHigh() {
        guard !isMuted else { return }
        AudioServicesPlaySystemSound(1105) // Higher tock
    }
    
    func playCoin() {
        guard !isMuted else { return }
        AudioServicesPlaySystemSound(1057) // Coin-like sound
    }
    
    func playSuccess() {
        guard !isMuted else { return }
        AudioServicesPlaySystemSound(1025) // Success sound
    }
    
    func playFailure() {
        guard !isMuted else { return }
        AudioServicesPlaySystemSound(1073) // Error sound
    }
    
    func playLevelUp() {
        guard !isMuted else { return }
        // Play ascending tones
        AudioServicesPlaySystemSound(1115)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            AudioServicesPlaySystemSound(1116)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            AudioServicesPlaySystemSound(1117)
        }
    }
    
    func playAchievement() {
        guard !isMuted else { return }
        // Fanfare-like sequence
        AudioServicesPlaySystemSound(1001)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            AudioServicesPlaySystemSound(1002)
        }
    }
    
    func playPhaseUnlock() {
        guard !isMuted else { return }
        // Dramatic unlock sound
        AudioServicesPlaySystemSound(1100)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            AudioServicesPlaySystemSound(1101)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AudioServicesPlaySystemSound(1025)
        }
    }
    
    func playPurchase() {
        guard !isMuted else { return }
        AudioServicesPlaySystemSound(1052) // Cash register-like
    }
    
    func playStreakMilestone(_ streak: Int) {
        guard !isMuted else { return }
        switch streak {
        case 100:
            AudioServicesPlaySystemSound(1103)
        case 500:
            playSuccess()
        case 1000, 5000, 10000:
            playLevelUp()
        default:
            break
        }
    }
    
    func playOpportunityAppear() {
        guard !isMuted else { return }
        AudioServicesPlaySystemSound(1033) // Notification-like
    }
    
    func playOpportunityResult(_ success: Bool) {
        if success {
            playSuccess()
        } else {
            playFailure()
        }
    }
    
    func toggleMute() {
        isMuted.toggle()
    }
}

// MARK: - Feedback Coordinator
/// Combines haptic and sound feedback for game events
class FeedbackCoordinator {
    static let shared = FeedbackCoordinator()
    
    private let haptic = HapticManager.shared
    private let sound = SoundManager.shared
    
    private init() {}
    
    func tap(value: Double = 0) {
        haptic.lightTap()
        if value >= 10000 {
            sound.playTapHigh()
        } else {
            sound.playTap()
        }
    }
    
    func achievement() {
        haptic.achievementUnlock()
        sound.playAchievement()
    }
    
    func streakMilestone(_ streak: Int) {
        haptic.streakMilestone(streak)
        sound.playStreakMilestone(streak)
    }
    
    func purchase() {
        haptic.mediumTap()
        sound.playPurchase()
    }
    
    func investment() {
        haptic.mediumTap()
        sound.playCoin()
    }
    
    func achievementUnlock() {
        haptic.achievementUnlock()
        sound.playAchievement()
    }
    
    func phaseUnlock() {
        haptic.phaseUnlock()
        sound.playPhaseUnlock()
    }
    
    func promotion() {
        haptic.success()
        sound.playLevelUp()
    }
    
    func opportunityAppear() {
        haptic.selection()
        sound.playOpportunityAppear()
    }
    
    func opportunityResult(_ success: Bool) {
        if success {
            haptic.success()
        } else {
            haptic.error()
        }
        sound.playOpportunityResult(success)
    }
    
    func warning() {
        haptic.warning()
    }
    
    func contactMet() {
        haptic.success()
        sound.playSuccess()
    }
    
    func error() {
        haptic.error()
        sound.playFailure()
    }
}

// MARK: - Confetti Celebration View
struct ConfettiView: View {
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .cyan]
    @State private var particles: [ConfettiParticle] = []
    @State private var isAnimating = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Text(particle.emoji)
                        .font(.system(size: particle.size))
                        .position(particle.position)
                        .opacity(particle.opacity)
                        .rotationEffect(.degrees(particle.rotation))
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                animateParticles(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }
    
    private func createParticles(in size: CGSize) {
        let emojis = ["🎉", "🎊", "✨", "💰", "💵", "🤑", "⭐", "🔥", "💪", "🏆"]
        particles = (0..<50).map { _ in
            ConfettiParticle(
                emoji: emojis.randomElement()!,
                position: CGPoint(x: CGFloat.random(in: 0...size.width), y: -50),
                size: CGFloat.random(in: 16...32),
                rotation: Double.random(in: 0...360),
                opacity: 1.0,
                velocity: CGFloat.random(in: 100...300)
            )
        }
    }
    
    private func animateParticles(in size: CGSize) {
        for i in particles.indices {
            let delay = Double.random(in: 0...0.5)
            let duration = Double.random(in: 1.5...3.0)
            
            withAnimation(.easeOut(duration: duration).delay(delay)) {
                particles[i].position.y = size.height + 100
                particles[i].position.x += CGFloat.random(in: -100...100)
                particles[i].rotation += Double.random(in: 180...720)
                particles[i].opacity = 0
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var emoji: String
    var position: CGPoint
    var size: CGFloat
    var rotation: Double
    var opacity: Double
    var velocity: CGFloat
}

// MARK: - Tap Milestone Celebration View
struct TapMilestoneCelebration: View {
    let milestone: GameState.TapMilestone
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var emojiScale: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Confetti background
            ConfettiView()
            
            // Celebration card
            VStack(spacing: 16) {
                Text(milestone.emoji)
                    .font(.system(size: 80))
                    .scaleEffect(emojiScale)
                
                Text(milestone.title)
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.yellow)
                    .shadow(color: .orange, radius: 10)
                
                Text(milestone.message)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                HStack(spacing: 4) {
                    Text("+$\(Int(milestone.bonusCash))")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.green)
                    Text("BONUS!")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.yellow)
                }
                
                Button(action: onDismiss) {
                    Text("KEEP HUSTLING!")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.yellow)
                        )
                }
                .padding(.top, 8)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [.yellow, .orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    )
            )
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.2)) {
                emojiScale = 1.0
            }
        }
    }
}
