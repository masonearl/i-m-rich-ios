//
//  EducationContent.swift
//  I'm Rich
//
//  Financial education: lessons, tips, and quizzes
//

import SwiftUI
import Combine

// MARK: - Wealth Wisdom Tip
struct WealthWisdom: Identifiable {
    let id = UUID()
    let quote: String
    let author: String
    let icon: String
}

let wealthWisdomTips: [WealthWisdom] = [
    // Warren Buffett
    WealthWisdom(quote: "Rule No. 1: Never lose money. Rule No. 2: Never forget Rule No. 1.", author: "Warren Buffett", icon: "🎯"),
    WealthWisdom(quote: "The stock market is designed to transfer money from the Active to the Patient.", author: "Warren Buffett", icon: "⏳"),
    WealthWisdom(quote: "Be fearful when others are greedy and greedy when others are fearful.", author: "Warren Buffett", icon: "💡"),
    WealthWisdom(quote: "Price is what you pay. Value is what you get.", author: "Warren Buffett", icon: "💎"),
    WealthWisdom(quote: "Someone's sitting in the shade today because someone planted a tree a long time ago.", author: "Warren Buffett", icon: "🌳"),
    
    // Charlie Munger
    WealthWisdom(quote: "The big money is not in the buying and selling, but in the waiting.", author: "Charlie Munger", icon: "⏰"),
    WealthWisdom(quote: "Spend each day trying to be a little wiser than you were when you woke up.", author: "Charlie Munger", icon: "📚"),
    WealthWisdom(quote: "Knowing what you don't know is more useful than being brilliant.", author: "Charlie Munger", icon: "🧠"),
    
    // Benjamin Graham
    WealthWisdom(quote: "In the short run, the market is a voting machine. In the long run, it is a weighing machine.", author: "Benjamin Graham", icon: "⚖️"),
    WealthWisdom(quote: "The investor's chief problem—and even his worst enemy—is likely to be himself.", author: "Benjamin Graham", icon: "🪞"),
    
    // John Bogle
    WealthWisdom(quote: "Don't look for the needle in the haystack. Just buy the haystack.", author: "John Bogle", icon: "🎪"),
    WealthWisdom(quote: "Time is your friend; impulse is your enemy.", author: "John Bogle", icon: "🐢"),
    
    // Other Legends
    WealthWisdom(quote: "Compound interest is the eighth wonder of the world.", author: "Albert Einstein", icon: "✨"),
    WealthWisdom(quote: "It's not about timing the market, but time in the market.", author: "Ken Fisher", icon: "📅"),
    WealthWisdom(quote: "The four most dangerous words in investing are: 'This time it's different.'", author: "Sir John Templeton", icon: "⚠️"),
    WealthWisdom(quote: "An investment in knowledge pays the best interest.", author: "Benjamin Franklin", icon: "📖"),
    WealthWisdom(quote: "Do not save what is left after spending, but spend what is left after saving.", author: "Warren Buffett", icon: "🏦"),
    WealthWisdom(quote: "The individual investor should act consistently as an investor and not as a speculator.", author: "Benjamin Graham", icon: "🎭"),
    WealthWisdom(quote: "Risk comes from not knowing what you are doing.", author: "Warren Buffett", icon: "🎲"),
    WealthWisdom(quote: "Wide diversification is only required when investors do not understand what they are doing.", author: "Warren Buffett", icon: "🎨")
]

// MARK: - Mini Lesson
struct MiniLesson: Identifiable, Codable {
    let id: String
    let title: String
    let icon: String
    let phaseUnlock: Int
    let content: [LessonSection]
    let quiz: [QuizQuestion]
    var completed: Bool = false
    var quizScore: Int = 0
}

struct LessonSection: Codable {
    let heading: String
    let body: String
}

struct QuizQuestion: Identifiable, Codable {
    let id: String
    let question: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
}

// MARK: - All Lessons
let allLessons: [MiniLesson] = [
    // Phase 1 Lessons
    MiniLesson(
        id: "compound_interest",
        title: "The Power of Compound Interest",
        icon: "📈",
        phaseUnlock: 1,
        content: [
            LessonSection(heading: "What is Compound Interest?", body: "Compound interest is when you earn interest on your interest. Your money grows exponentially over time, not linearly."),
            LessonSection(heading: "The Rule of 72", body: "Divide 72 by your interest rate to find how many years it takes to double your money. At 8% returns, your money doubles every 9 years."),
            LessonSection(heading: "Start Early", body: "Someone who invests $5,000/year from age 25-35 (10 years) will have MORE money at 65 than someone who invests $5,000/year from 35-65 (30 years). Time beats amount.")
        ],
        quiz: [
            QuizQuestion(id: "q1", question: "At 10% annual returns, how long does it take to double your money?", options: ["5 years", "7.2 years", "10 years", "12 years"], correctIndex: 1, explanation: "Using the Rule of 72: 72 ÷ 10 = 7.2 years"),
            QuizQuestion(id: "q2", question: "Why does starting early matter so much?", options: ["You have more time to work", "Compound interest needs time to grow exponentially", "Stocks are cheaper when you're young", "Banks give better rates to young people"], correctIndex: 1, explanation: "Compound interest accelerates over time. The earlier you start, the more doubling periods you get.")
        ]
    ),
    
    MiniLesson(
        id: "pay_yourself_first",
        title: "Pay Yourself First",
        icon: "💰",
        phaseUnlock: 1,
        content: [
            LessonSection(heading: "The Concept", body: "Before you pay bills or spend on wants, automatically transfer money to savings/investments. Treat it like a non-negotiable bill to yourself."),
            LessonSection(heading: "Automate It", body: "Set up automatic transfers on payday. If you never see the money in your checking account, you won't miss it."),
            LessonSection(heading: "The 50/30/20 Rule", body: "A popular budget: 50% to needs, 30% to wants, 20% to savings. Adjust based on your goals.")
        ],
        quiz: [
            QuizQuestion(id: "q1", question: "When should you transfer money to savings?", options: ["After paying all bills", "Before spending on anything else", "At the end of the month", "When you remember"], correctIndex: 1, explanation: "Pay yourself FIRST means savings comes before other spending."),
            QuizQuestion(id: "q2", question: "In the 50/30/20 rule, what does the 20% represent?", options: ["Rent", "Entertainment", "Savings and investments", "Food"], correctIndex: 2, explanation: "The 20% is dedicated to building your financial future.")
        ]
    ),
    
    MiniLesson(
        id: "emergency_fund",
        title: "Emergency Funds 101",
        icon: "🛡️",
        phaseUnlock: 1,
        content: [
            LessonSection(heading: "Why You Need One", body: "An emergency fund protects you from going into debt when unexpected expenses hit—car repairs, medical bills, job loss."),
            LessonSection(heading: "How Much?", body: "Start with $1,000, then build to 3-6 months of expenses. If your income is unstable, aim for 6-12 months."),
            LessonSection(heading: "Where to Keep It", body: "Keep it in a high-yield savings account—liquid and accessible, but not so easy to spend on non-emergencies.")
        ],
        quiz: [
            QuizQuestion(id: "q1", question: "How much should a starter emergency fund be?", options: ["$100", "$500", "$1,000", "$10,000"], correctIndex: 2, explanation: "$1,000 covers most small emergencies and is an achievable first goal."),
            QuizQuestion(id: "q2", question: "Why shouldn't you invest your emergency fund in stocks?", options: ["Stocks are too risky", "You need immediate access without potential losses", "It's illegal", "Banks pay more"], correctIndex: 1, explanation: "Emergency funds need to be liquid and stable. Stock values fluctuate.")
        ]
    ),
    
    // Phase 2 Lessons
    MiniLesson(
        id: "good_vs_bad_debt",
        title: "Good Debt vs Bad Debt",
        icon: "💳",
        phaseUnlock: 2,
        content: [
            LessonSection(heading: "Not All Debt is Equal", body: "Good debt helps you build wealth or increase earning potential. Bad debt costs you money on depreciating assets or consumption."),
            LessonSection(heading: "Good Debt Examples", body: "Mortgage on a home that appreciates. Student loans for a degree that increases income. Business loans for profitable ventures."),
            LessonSection(heading: "Bad Debt Examples", body: "Credit card debt for shopping. Car loans for expensive vehicles you can't afford. Payday loans with predatory rates.")
        ],
        quiz: [
            QuizQuestion(id: "q1", question: "Which is an example of good debt?", options: ["Credit card for a vacation", "Car loan for a luxury car", "Mortgage on a rental property", "Payday loan for bills"], correctIndex: 2, explanation: "A rental property can generate income and appreciate, making the debt productive."),
            QuizQuestion(id: "q2", question: "What makes debt 'bad'?", options: ["High interest rate", "Used for depreciating assets or consumption", "Both A and B", "Any amount over $1,000"], correctIndex: 2, explanation: "Bad debt typically has high rates AND doesn't help you build wealth.")
        ]
    ),
    
    MiniLesson(
        id: "tax_advantaged",
        title: "Tax-Advantaged Accounts",
        icon: "🏛️",
        phaseUnlock: 2,
        content: [
            LessonSection(heading: "Free Money from the Government", body: "401(k)s, IRAs, and HSAs let your money grow tax-free or tax-deferred. This can mean tens of thousands extra over your lifetime."),
            LessonSection(heading: "401(k) Basics", body: "Employer-sponsored. Often includes matching—that's free money! 2024 limit: $23,000. Contributions reduce taxable income."),
            LessonSection(heading: "Roth vs Traditional", body: "Traditional: Tax break now, pay taxes later. Roth: Pay taxes now, withdrawals are tax-free. If you expect higher income later, Roth is often better.")
        ],
        quiz: [
            QuizQuestion(id: "q1", question: "If your employer matches 50% up to 6%, and you earn $100,000, how much free money do you get?", options: ["$3,000", "$6,000", "$9,000", "$12,000"], correctIndex: 0, explanation: "6% of $100,000 = $6,000. 50% match = $3,000 free."),
            QuizQuestion(id: "q2", question: "When are Roth account withdrawals taxed?", options: ["When you contribute", "When you withdraw", "Both times", "Never (contributions were already taxed)"], correctIndex: 3, explanation: "Roth contributions are made with after-tax money, so qualified withdrawals are tax-free.")
        ]
    ),
    
    MiniLesson(
        id: "salary_negotiation",
        title: "Salary Negotiation Basics",
        icon: "💬",
        phaseUnlock: 2,
        content: [
            LessonSection(heading: "Why Negotiate?", body: "Not negotiating your salary can cost you $500,000+ over your career. Most employers expect negotiation."),
            LessonSection(heading: "Know Your Worth", body: "Research salary ranges on Glassdoor, Levels.fyi, LinkedIn. Know the market rate for your role, location, and experience."),
            LessonSection(heading: "The Ask", body: "Let them make the first offer. Counter 10-20% higher. Negotiate total compensation: base, bonus, equity, PTO, remote work.")
        ],
        quiz: [
            QuizQuestion(id: "q1", question: "Who should state a number first in salary negotiation?", options: ["You, to anchor high", "The employer", "Doesn't matter", "Neither—avoid numbers"], correctIndex: 1, explanation: "Let them anchor first. Their offer gives you information and room to counter."),
            QuizQuestion(id: "q2", question: "What should you negotiate besides base salary?", options: ["Signing bonus", "Equity/stock options", "Remote work flexibility", "All of the above"], correctIndex: 3, explanation: "Total compensation includes many elements. Be creative!")
        ]
    ),
    
    // Phase 3 Lessons
    MiniLesson(
        id: "diversification",
        title: "Diversification",
        icon: "🎨",
        phaseUnlock: 3,
        content: [
            LessonSection(heading: "Don't Put All Eggs in One Basket", body: "Diversification reduces risk by spreading investments across different assets, sectors, and geographies."),
            LessonSection(heading: "Asset Classes", body: "Stocks, bonds, real estate, commodities, cash. Each behaves differently in various market conditions."),
            LessonSection(heading: "The Free Lunch", body: "Diversification is called 'the only free lunch in investing.' It can reduce risk without reducing expected returns.")
        ],
        quiz: [
            QuizQuestion(id: "q1", question: "What is diversification?", options: ["Buying many stocks in one sector", "Spreading investments across different asset types", "Only investing in safe assets", "Timing the market"], correctIndex: 1, explanation: "True diversification means different asset classes, not just many stocks."),
            QuizQuestion(id: "q2", question: "Why is diversification called 'a free lunch'?", options: ["It's cheap to implement", "It can reduce risk without reducing expected returns", "Financial advisors don't charge for it", "Index funds are free"], correctIndex: 1, explanation: "You get lower volatility without sacrificing expected returns.")
        ]
    ),
    
    MiniLesson(
        id: "risk_reward",
        title: "Risk vs Reward",
        icon: "⚖️",
        phaseUnlock: 3,
        content: [
            LessonSection(heading: "The Fundamental Tradeoff", body: "Higher potential returns come with higher risk. There's no way to earn high returns with zero risk."),
            LessonSection(heading: "Know Your Risk Tolerance", body: "Can you stomach a 30% drop without panic selling? Your risk tolerance depends on your time horizon, income stability, and personality."),
            LessonSection(heading: "Risk Capacity vs Tolerance", body: "Capacity: How much risk you CAN take (financial situation). Tolerance: How much risk you're comfortable with (emotional). Both matter.")
        ],
        quiz: [
            QuizQuestion(id: "q1", question: "What's the relationship between risk and return?", options: ["No relationship", "Higher risk = higher potential return", "Lower risk = higher return", "Risk doesn't affect returns"], correctIndex: 1, explanation: "The risk-return tradeoff is fundamental to investing."),
            QuizQuestion(id: "q2", question: "A young investor with stable income should generally take:", options: ["No risk at all", "Only bonds", "More risk than a retiree", "Same risk as everyone"], correctIndex: 2, explanation: "Longer time horizons allow more risk because you can recover from downturns.")
        ]
    ),
    
    MiniLesson(
        id: "passive_income",
        title: "Building Passive Income",
        icon: "💤",
        phaseUnlock: 3,
        content: [
            LessonSection(heading: "Money Working for You", body: "Passive income is earnings that require minimal ongoing effort—dividends, rental income, royalties, business systems."),
            LessonSection(heading: "Building It Takes Work", body: "Nothing is truly 'passive' at first. It takes capital, time, or effort upfront to create income streams that run themselves."),
            LessonSection(heading: "The FIRE Movement", body: "Financial Independence, Retire Early. When passive income covers expenses, you're financially independent. The 4% rule: You need 25x your annual expenses.")
        ],
        quiz: [
            QuizQuestion(id: "q1", question: "To cover $50,000/year in expenses passively at 4% withdrawal, you need:", options: ["$500,000", "$1,000,000", "$1,250,000", "$2,000,000"], correctIndex: 2, explanation: "$50,000 × 25 = $1,250,000"),
            QuizQuestion(id: "q2", question: "Which is an example of passive income?", options: ["Salary from a job", "Dividend payments from stocks", "Freelance consulting", "Hourly wages"], correctIndex: 1, explanation: "Dividends pay you whether you work or not.")
        ]
    ),
    
    // Phase 4 Lessons
    MiniLesson(
        id: "legacy_planning",
        title: "Legacy Planning",
        icon: "🏰",
        phaseUnlock: 4,
        content: [
            LessonSection(heading: "Beyond Your Lifetime", body: "Legacy planning ensures your wealth benefits future generations and causes you care about."),
            LessonSection(heading: "Estate Planning Basics", body: "Will, trust, power of attorney, beneficiary designations. Without these, the state decides what happens to your assets."),
            LessonSection(heading: "Generational Wealth", body: "70% of wealthy families lose their wealth by the second generation, 90% by the third. Financial education for heirs is crucial.")
        ],
        quiz: [
            QuizQuestion(id: "q1", question: "What happens to your assets if you die without a will?", options: ["They go to charity", "The state decides distribution", "They go to the government", "Nothing—they stay in your accounts"], correctIndex: 1, explanation: "Intestate succession laws determine distribution, which may not match your wishes."),
            QuizQuestion(id: "q2", question: "What percentage of wealthy families lose their wealth by the third generation?", options: ["50%", "70%", "90%", "100%"], correctIndex: 2, explanation: "The 'shirtsleeves to shirtsleeves' phenomenon is very real.")
        ]
    ),
    
    MiniLesson(
        id: "impact_investing",
        title: "Philanthropy & Impact Investing",
        icon: "❤️",
        phaseUnlock: 4,
        content: [
            LessonSection(heading: "Giving While Living", body: "Many wealthy individuals find more meaning in strategic giving than pure accumulation. You can see your impact."),
            LessonSection(heading: "Impact Investing", body: "Investments that generate both financial returns AND positive social/environmental impact. ESG, green bonds, community development."),
            LessonSection(heading: "Donor-Advised Funds", body: "Tax-advantaged giving accounts. Contribute now for the tax deduction, grant to charities over time.")
        ],
        quiz: [
            QuizQuestion(id: "q1", question: "What is impact investing?", options: ["Investing only for returns", "Investing for both returns and social impact", "Donating to charity", "Government bonds"], correctIndex: 1, explanation: "Impact investing aims for the double bottom line: profit and purpose."),
            QuizQuestion(id: "q2", question: "What's a benefit of donor-advised funds?", options: ["Higher investment returns", "Immediate tax deduction, flexible granting", "No fees ever", "Government matching"], correctIndex: 1, explanation: "You get the tax benefit now but can decide which charities receive grants later.")
        ]
    ),
    
    MiniLesson(
        id: "psychology_wealth",
        title: "The Psychology of Wealth",
        icon: "🧠",
        phaseUnlock: 4,
        content: [
            LessonSection(heading: "Money and Happiness", body: "Research shows money increases happiness up to about $75-100K/year for basic needs. After that, experiences and relationships matter more."),
            LessonSection(heading: "Lifestyle Inflation", body: "As income rises, spending often rises to match. The wealthy who stay wealthy are those who don't let lifestyle inflate with every raise."),
            LessonSection(heading: "Purpose Beyond Money", body: "Many who achieve financial freedom struggle without purpose. Have goals beyond the number—what will you DO with your freedom?")
        ],
        quiz: [
            QuizQuestion(id: "q1", question: "What is lifestyle inflation?", options: ["Rising prices due to economy", "Spending more as you earn more", "Investing in luxury goods", "Moving to expensive cities"], correctIndex: 1, explanation: "Lifestyle inflation is when your spending rises to match your income, preventing wealth building."),
            QuizQuestion(id: "q2", question: "After what income level does more money have diminishing returns on happiness?", options: ["$30,000", "$75,000-$100,000", "$500,000", "$1,000,000"], correctIndex: 1, explanation: "Research suggests basic needs are met around this level; beyond that, other factors matter more.")
        ]
    )
]

// MARK: - Education Manager
class EducationManager: ObservableObject {
    static let shared = EducationManager()
    
    @Published var lessons: [MiniLesson] {
        didSet { save() }
    }
    @Published var financialLiteracyScore: Int {
        didSet { UserDefaults.standard.set(financialLiteracyScore, forKey: "financialLiteracyScore") }
    }
    @Published var currentLesson: MiniLesson?
    @Published var showingQuiz = false
    
    var completedLessonIds: [String] {
        lessons.filter { $0.completed }.map { $0.id }
    }
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: "lessons"),
           let decoded = try? JSONDecoder().decode([MiniLesson].self, from: data) {
            self.lessons = decoded
        } else {
            self.lessons = allLessons
        }
        
        self.financialLiteracyScore = UserDefaults.standard.integer(forKey: "financialLiteracyScore")
    }
    
    func getRandomTip() -> WealthWisdom {
        wealthWisdomTips.randomElement()!
    }
    
    func availableLessons(for phase: Int) -> [MiniLesson] {
        lessons.filter { $0.phaseUnlock <= phase }
    }
    
    func completeLesson(_ lessonId: String, score: Int) {
        guard let index = lessons.firstIndex(where: { $0.id == lessonId }) else { return }
        
        lessons[index].completed = true
        lessons[index].quizScore = score
        
        // Award literacy points based on score
        let pointsEarned = score * 5
        financialLiteracyScore += pointsEarned
    }
    
    func markLessonCompleted(_ lessonId: String) {
        guard let index = lessons.firstIndex(where: { $0.id == lessonId }) else { return }
        lessons[index].completed = true
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(lessons) {
            UserDefaults.standard.set(data, forKey: "lessons")
        }
    }
    
    func reset() {
        lessons = allLessons
        financialLiteracyScore = 0
    }
}

// MARK: - Lesson View
struct LessonView: View {
    let lesson: MiniLesson
    @ObservedObject var educationManager: EducationManager
    @ObservedObject var game: GameState
    @Environment(\.dismiss) var dismiss
    
    @State private var currentSection = 0
    @State private var showQuiz = false
    @State private var quizAnswers: [Int] = []
    @State private var quizComplete = false
    @State private var quizScore = 0
    
    let accentColor = Color(red: 0.4, green: 0.7, blue: 0.4)
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if !showQuiz {
                lessonContent
            } else if !quizComplete {
                quizContent
            } else {
                quizResults
            }
        }
    }
    
    var lessonContent: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text(lesson.icon)
                    .font(.system(size: 32))
                Text(lesson.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(Array(lesson.content.enumerated()), id: \.offset) { index, section in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(section.heading)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(accentColor)
                            
                            Text(section.body)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9))
                                .lineSpacing(4)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                        )
                    }
                }
                .padding()
            }
            
            // Take Quiz button
            Button(action: { showQuiz = true }) {
                Text("TAKE QUIZ")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(accentColor)
                    .cornerRadius(12)
            }
            .padding()
        }
    }
    
    var quizContent: some View {
        VStack(spacing: 20) {
            Text("QUIZ")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.gray)
                .tracking(2)
            
            let currentQ = lesson.quiz[min(quizAnswers.count, lesson.quiz.count - 1)]
            
            Text(currentQ.question)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
            
            VStack(spacing: 12) {
                ForEach(Array(currentQ.options.enumerated()), id: \.offset) { index, option in
                    Button(action: {
                        quizAnswers.append(index)
                        if quizAnswers.count >= lesson.quiz.count {
                            calculateScore()
                        }
                    }) {
                        Text(option)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                }
            }
            .padding()
            
            // Progress
            Text("Question \(quizAnswers.count + 1) of \(lesson.quiz.count)")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .padding()
    }
    
    var quizResults: some View {
        VStack(spacing: 24) {
            Text(quizScore == lesson.quiz.count ? "🎉" : "📚")
                .font(.system(size: 60))
            
            Text(quizScore == lesson.quiz.count ? "PERFECT!" : "QUIZ COMPLETE")
                .font(.system(size: 24, weight: .black))
                .foregroundColor(quizScore == lesson.quiz.count ? .yellow : .white)
            
            Text("\(quizScore) / \(lesson.quiz.count) correct")
                .font(.system(size: 18))
                .foregroundColor(.gray)
            
            Text("+\(quizScore * 5) Financial Literacy")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(accentColor)
            
            Button(action: { dismiss() }) {
                Text("DONE")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 60)
                    .padding(.vertical, 14)
                    .background(accentColor)
                    .cornerRadius(12)
            }
            .padding(.top, 20)
        }
    }
    
    func calculateScore() {
        quizScore = 0
        for (index, answer) in quizAnswers.enumerated() {
            if answer == lesson.quiz[index].correctIndex {
                quizScore += 1
            }
        }
        educationManager.completeLesson(lesson.id, score: quizScore)
        quizComplete = true
        
        // Award cash bonus
        let bonus = Double(quizScore * 1000)
        game.cash += bonus
        game.totalEarned += bonus
        
        FeedbackCoordinator.shared.achievementUnlock()
    }
}

// MARK: - Wisdom Tip View
struct WisdomTipView: View {
    let wisdom: WealthWisdom
    
    var body: some View {
        VStack(spacing: 12) {
            Text(wisdom.icon)
                .font(.system(size: 24))
            
            Text("\"\(wisdom.quote)\"")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .italic()
            
            Text("— \(wisdom.author)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.4))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 0.4, green: 0.7, blue: 0.4).opacity(0.3), lineWidth: 1)
                )
        )
    }
}
