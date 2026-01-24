//
//  OnboardingView.swift
//  I'm Rich
//
//  Starting age selection and game introduction
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var lifecycle = LifeCycleManager.shared
    @ObservedObject var prestige = PrestigeManager.shared
    let onComplete: () -> Void
    
    @State private var selectedAge: Double = 27
    @State private var currentStep = 0
    @State private var opacity: Double = 0
    
    let accentColor = Color(red: 0.4, green: 0.7, blue: 0.4)
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                if currentStep == 0 {
                    welcomeStep
                } else if currentStep == 1 {
                    ageSelectionStep
                } else {
                    readyStep
                }
                
                Spacer()
                
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(index == currentStep ? accentColor : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 40)
            }
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 0.5)) {
                    opacity = 1
                }
            }
        }
    }
    
    var welcomeStep: some View {
        VStack(spacing: 24) {
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(color: accentColor.opacity(0.4), radius: 15)
            
            if prestige.hasPrestiged {
                Text("WELCOME BACK")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.white)
                    .tracking(3)
                
                Text("Life #\(prestige.livesLived + 1)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(accentColor)
                
                Text("Legacy Multiplier: \(prestige.formattedMultiplier)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            } else {
                Text("LIFE OF WEALTH")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.white)
                    .tracking(3)
                
                Text("Money is just the beginning")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
            
            VStack(spacing: 8) {
                featureRow(icon: "💪", text: "Tap to earn your first dollars")
                featureRow(icon: "📈", text: "Invest and grow your wealth")
                featureRow(icon: "👔", text: "Build a career and climb the ladder")
                featureRow(icon: "🌟", text: "Live multiple lives, each stronger")
            }
            .padding(.top, 20)
            
            Button(action: { 
                withAnimation { currentStep = 1 }
            }) {
                Text("Begin Your Journey")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(accentColor)
                    )
            }
            .padding(.top, 20)
        }
        .padding()
    }
    
    var ageSelectionStep: some View {
        VStack(spacing: 24) {
            Text("🎂")
                .font(.system(size: 60))
            
            Text("CHOOSE YOUR AGE")
                .font(.system(size: 20, weight: .black))
                .foregroundColor(.white)
                .tracking(2)
            
            Text("This is your simulated starting age - it doesn't have to be your real age. Try picking 27.")
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            // Age display
            Text("\(Int(selectedAge))")
                .font(.system(size: 72, weight: .black))
                .foregroundColor(accentColor)
            
            // Age slider
            VStack(spacing: 8) {
                Slider(
                    value: $selectedAge,
                    in: Double(LifeCycleConstants.minStartingAge)...Double(LifeCycleConstants.maxStartingAge),
                    step: 1
                )
                .accentColor(accentColor)
                .padding(.horizontal, 40)
                
                HStack {
                    Text("\(LifeCycleConstants.minStartingAge)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(LifeCycleConstants.maxStartingAge)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 40)
            }
            
            // Special message for 100
            if Int(selectedAge) >= 100 {
                VStack(spacing: 8) {
                    Text("🙏")
                        .font(.system(size: 32))
                    Text("Put down your phone.")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text("Go spend time with the people you love. Enjoy these final moments of your journey. The time you have left is precious - don't spend it on a screen.")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                .padding(.vertical, 15)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                )
            } else {
                // Life expectancy note
                Text("You can retire anytime from age 50-100")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .padding(.top, 10)
            }
            
            Button(action: {
                lifecycle.setStartingAge(Int(selectedAge))
                withAnimation { currentStep = 2 }
            }) {
                Text(Int(selectedAge) >= 100 ? "I understand" : "Confirm Age")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(accentColor)
                    )
            }
            .padding(.top, 20)
        }
        .padding()
    }
    
    var readyStep: some View {
        VStack(spacing: 24) {
            Text("🚀")
                .font(.system(size: 60))
            
            Text("YOU'RE READY!")
                .font(.system(size: 20, weight: .black))
                .foregroundColor(.white)
                .tracking(2)
            
            VStack(spacing: 12) {
                readyStatRow(label: "Starting Age", value: "\(Int(selectedAge))")
                
                if prestige.hasPrestiged {
                    readyStatRow(label: "Starting Cash", value: formatCompact(prestige.getStartingCash()))
                    readyStatRow(label: "Legacy Bonus", value: prestige.formattedMultiplier)
                }
                
                readyStatRow(label: "Game Speed", value: "10 min = 1 year")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
            
            Text("Tap fast, invest smart, retire rich!")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Button(action: onComplete) {
                Text("Start Playing")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(accentColor)
                    )
            }
            .padding(.top, 20)
        }
        .padding()
    }
    
    func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.system(size: 20))
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    func readyStatRow(label: String, value: String) -> some View {
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
    
    func formatCompact(_ value: Double) -> String {
        switch value {
        case 1_000_000_000...: return String(format: "$%.1fB", value / 1_000_000_000)
        case 1_000_000...: return String(format: "$%.1fM", value / 1_000_000)
        case 1_000...: return String(format: "$%.1fK", value / 1_000)
        default: return "$\(Int(value))"
        }
    }
}
