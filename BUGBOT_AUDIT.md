# Bugbot Full App Audit Checklist

## Overview
This file triggers a full app audit by bugbot. Please review the entire "I'm Rich" iOS game for the following issues.

---

## 1. UI Responsiveness - Find Non-Responding Elements

### Buttons & Actions
- [ ] All buttons in each zone tab trigger their expected action
- [ ] Upgrade buttons properly deduct cash and apply upgrades
- [ ] Hire employee buttons work in Empire tab
- [ ] Invest/withdraw buttons work in investment views

### Sheets & Modals
- [ ] NewVentureSheet opens and allows creating ventures
- [ ] ExpandCompanySheet opens and allows building locations
- [ ] IPOSheet opens for ventures over $100M valuation
- [ ] PrestigeSheet opens when tapping prestige button
- [ ] TaxPlanUpgradeSheet opens from career tab
- [ ] SettingsSheet opens from settings gear icon
- [ ] InvestmentDetailSheet opens when tapping investments

### Navigation
- [ ] Zone tabs (Hustle, Career, Empire) switch correctly
- [ ] All ScrollViews scroll properly
- [ ] Game continues running while scrolling (timers in .common mode)

---

## 2. Number Sync - Displayed Values Must Match Game State

### Net Worth Calculation
- [ ] `netWorth = cash + totalInvestmentValue + companyValuation`
- [ ] Net worth ticker updates in real-time
- [ ] Ticker shows cents (2 decimal places)

### Income Rates
- [ ] Auto-tapper displayed rate matches `autoTapperIncomePerSecond`
- [ ] Salary displayed matches `currentRole.salary`
- [ ] Passive income displayed matches actual upgrade income
- [ ] Income cap doesn't silently reduce displayed rates

### Investment Returns
- [ ] Investments compound at their `baseReturn` rate yearly
- [ ] Unrealized gains show correctly before year-end
- [ ] Year-end news shows correct compounded amount
- [ ] `totalInvestmentValue = sum of all investment.totalValue`

### Tax System
- [ ] Tax reduction % matches current plan tier
- [ ] Upgrade cost matches `TaxPlanTier.upgradeCost`
- [ ] Net worth requirement matches `TaxPlanTier.netWorthRequired`
- [ ] Annual cost matches `TaxPlanTier.annualCost`

### Company Valuation
- [ ] `companyValuation` includes employee value
- [ ] `companyValuation` includes department bonuses
- [ ] `companyValuation` includes location asset value (1.5x build cost)
- [ ] Sale price calculation is correct

---

## 3. Progress Sync - Game Mechanics Work Together

### Career Progression
- [ ] `promotionCost` scales correctly with career level
- [ ] `contactsRequiredForPromotion` check works
- [ ] `statusRequiredForPromotion` check works
- [ ] `canPromote` only true when all requirements met

### Tax Planning
- [ ] Can only upgrade to NEXT tier (no skipping)
- [ ] Must meet net worth requirement to upgrade
- [ ] Must have enough cash for upgrade cost
- [ ] `upgradePlan()` validates both requirements

### Prestige System
- [ ] Prestige button shows progress when < $1B
- [ ] Prestige button activates at $1B+ net worth
- [ ] Birthday alert only mentions prestige if $1B+ reached
- [ ] Prestige rewards calculate correctly
- [ ] `resetForPrestige()` properly resets game state

### Death Mechanic
- [ ] `deathAge` generated randomly between 65-100
- [ ] Death triggers at correct age
- [ ] Death alert shows if didn't prestige
- [ ] Full reset works correctly on death

### Venture/IPO System
- [ ] Ventures grow yearly with `processYear()`
- [ ] `totalVentureRevenue` calculated correctly
- [ ] IPO requires $100M+ valuation
- [ ] `takeVenturePublic()` sets correct properties
- [ ] `isPublic` flag persists correctly

---

## 4. Data Persistence

### UserDefaults Saving
- [ ] Cash saves and loads correctly
- [ ] Investments save with unrealized gains
- [ ] Company state persists
- [ ] Tax plan tier persists
- [ ] Venture state persists
- [ ] Settings (haptics, sound) persist

---

## 5. Edge Cases

### Overflow Prevention
- [ ] Cash capped at `maxNetWorth` ($10T)
- [ ] Total earned capped appropriately
- [ ] Investment gains capped to prevent overflow
- [ ] Company valuation capped at `maxValuation`

### Error States
- [ ] Empty company name handled in NewVentureSheet
- [ ] Zero cash doesn't break calculations
- [ ] Missing investments don't crash
- [ ] Invalid upgrade attempts fail gracefully

---

## Files to Review

### Core Logic
- `GameState.swift` - Main game state, tick(), income calculations
- `GameModels.swift` - Investment, Upgrade, Career definitions

### Systems
- `CompanySystem.swift` - Company, Venture, IPO logic
- `TaxSystem.swift` - Tax plans and calculations
- `LifeCycleSystem.swift` - Age, death, birthday logic
- `FamilySystem.swift` - Dating, marriage, kids
- `PrestigeSystem.swift` - Prestige rewards and reset

### Views
- `ZonedGameView.swift` - Main game view, all sheets
- `ContentView.swift` - Root view, overlays
- `GameZones.swift` - Zone-specific views

### Managers
- `ThemeManager.swift` - Colors, themes
- `FeedbackManagers.swift` - Haptics, sounds
