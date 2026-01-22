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
class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    // Light tap - for regular taps
    func lightTap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    // Medium tap - for purchases, investments
    func mediumTap() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    // Heavy tap - for major achievements, phase unlocks
    func heavyTap() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    // Success - for successful actions
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // Warning - for risky actions
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    // Error - for failed actions
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    // Selection - for UI selections
    func selection() {
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
    
    func tap(value: Double) {
        haptic.lightTap()
        if value >= 10000 {
            sound.playTapHigh()
        } else {
            sound.playTap()
        }
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
    
    func contactMet() {
        haptic.success()
        sound.playSuccess()
    }
    
    func error() {
        haptic.error()
        sound.playFailure()
    }
}
