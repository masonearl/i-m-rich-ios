# Code Review: UI, Numbers & Progress Sync

## 🔴 CRITICAL ISSUES FOUND

### 1. Net Worth Calculation Mismatch in `tick()`

**Location**: `GameState.swift` line 764

**Issue**: The `tick()` function calculates net worth without company valuation:
```swift
let netWorth = cash + totalInvestmentValue  // ❌ Missing company valuation
```

But the computed property `netWorth` (line 386) correctly includes it:
```swift
var netWorth: Double {
    cash + totalInvestmentValue + CompanyManager.shared.state.companyValuation  // ✅ Correct
}
```

**Impact**: 
- `highestNetWorth` tracking may be incorrect
- Wealth manager sync uses incomplete value
- Displayed net worth (from computed property) won't match internal calculations

**Fix**: Change line 764 to:
```swift
let netWorth = self.netWorth  // Use the computed property
```

---

## ⚠️ POTENTIAL ISSUES

### 2. Income Cap May Still Be Too Low

**Location**: `GameState.swift` line 542-549

**Current caps**:
- Legacy Scale: $1M/tick = $10M/sec max

**Issue**: If user has multiple high-tier tappers, they could exceed $10M/sec combined. The cap was raised but may need verification.

**Check**: Verify `autoTapperIncomePerSecond` calculation matches displayed rates.

---

### 3. Tax Upgrade Validation

**Location**: `TaxSystem.swift` line 355

**Status**: ✅ Fixed - `upgradePlan()` now validates both cash AND net worth requirements.

---

### 4. Investment Compounding

**Location**: `GameState.swift` line 818-886

**Status**: ✅ Appears correct - gains accumulate in `unrealizedGains` and compound at year-end.

**Verify**: Check that `baseReturn` rates (8-11%) match displayed values.

---

## ✅ VERIFIED WORKING

### Net Worth Display
- Computed property correctly includes: cash + investments + company valuation
- Ticker updates in real-time
- Shows cents (2 decimal places)

### Auto-Tapper Income
- Calculation: `tapper.currentTapsPerSecond * tapper.baseIncomePerTap`
- Prestige multiplier applied correctly
- Income cap raised to $10M/sec for legacy scale

### Company Valuation
- Includes employee value
- Includes department bonuses  
- Includes location asset value (1.5x build cost) ✅
- Includes capital multiplier

### Tax System
- Upgrade validates both cash AND net worth ✅
- Requirements display shows current vs required values ✅

### Prestige System
- Only available at $1B+ net worth ✅
- Birthday alert checks net worth before showing message ✅

---

## 📋 RECOMMENDATIONS

1. **Fix net worth calculation in `tick()`** - Use computed property instead of local variable
2. **Add unit tests** for number sync calculations
3. **Add logging** for income cap hits to verify displayed vs actual rates
4. **Verify all sheet presentations** work correctly (manual testing needed)

---

## 🧪 MANUAL TESTING NEEDED

- [ ] All buttons trigger actions
- [ ] All sheets open/close properly
- [ ] Settings toggles work
- [ ] Investment detail sheets open
- [ ] Prestige sheet appears at $1B+
- [ ] Tax upgrade sheet validates requirements
- [ ] Company expansion sheet works
- [ ] IPO sheet appears for ventures >$100M
