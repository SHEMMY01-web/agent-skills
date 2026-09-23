---
name: financial-precision-engine
description: >-
  Deterministic financial precision, zero-drift floating-point arithmetic, compound
  interest simulation stability, defensive boundary guards against division-by-zero/NaN,
  and monotonic risk scoring. Use when implementing calculations involving currency,
  penalties, loans, interest, risk scoring, or contractual consequences.
---

# Financial Precision Engine & Numerical Computing

Engineering standards for building zero-drift financial computation engines, compound interest models, and deterministic risk scoring systems in JavaScript and Node.js environments.

---

## 1. When to Use
- Calculating monetary values, interest rates, late penalty accruals, or amortization schedules.
- Simulating long-term compounding consequences (e.g., 30-day, 365-day, or 1000-day horizons).
- Guarding calculations against division-by-zero, `NaN`, `Infinity`, or negative runtime inputs.
- Architecting monotonic risk scores where increased severity or stricter thresholds strictly produce higher or equal scores.
- Converting between major and minor currency units (e.g., Naira to Kobo, Dollars to Cents) without floating-point drift.

---

## 2. Core Guidelines & Best Practices

### 1. Zero Floating-Point Drift (Integer Scaling & Decimal.js)
- Never perform multi-step currency or interest calculations using standard IEEE 754 floats (`0.1 + 0.2 === 0.30000000000000004`).
- **Option A: Integer Minor Units:** Store and compute all values in integer minor units (kobo, cents, satoshis):
  ```javascript
  const amountKobo = Math.round(Number(amountNgn) * 100);
  const penaltyKobo = Math.round(amountKobo * (rateBasisPoints / 10000));
  ```
- **Option B: Arbitrary Precision (Decimal.js / Big.js):** For complex compounding or variable rates, use `Decimal.js`:
  ```javascript
  const Decimal = require('decimal.js');
  Decimal.set({ precision: 28, rounding: Decimal.ROUND_HALF_UP });

  const principal = new Decimal(loanAmount);
  const dailyRate = new Decimal(annualRate).dividedBy(365);
  const compounded = principal.times(new Decimal(1).plus(dailyRate).pow(days));
  ```

### 2. Defensive Boundaries: Division-by-Zero, NaN & Infinity
- Runtime user inputs often supply zero, empty strings, or negative values for denominators (e.g., zero monthly living expenses or negative buyout offers).
- Always establish non-zero minimum baselines and finite sanity assertions:
  ```javascript
  // ❌ FRAGILE: Infinity or NaN on zero expenses
  const monthsCovered = buyoutOffer / monthlyExpenses;

  // ✅ RESILIENT: Bounded fallback ensuring finite non-negative numbers
  const safeExpenses = (!isNaN(expenses) && Number(expenses) > 0) ? Number(expenses) : 250000;
  const safeOffer = Math.max(0, Number(buyoutOffer) || 0);
  const rawMonths = safeOffer / safeExpenses;
  const monthsCovered = isFinite(rawMonths) ? Math.max(0, Number(rawMonths.toFixed(1))) : 0;
  ```

### 3. Compounding Loop Stability & Overflow Caps
- When simulating multi-day compounding (e.g. daily compounded default interest), enforce loop iteration bounds and value caps to prevent runaway overflow:
  ```javascript
  const MAX_DAYS = 1095; // 3 years ceiling
  const boundedDays = Math.min(Math.max(1, parseInt(daysElapsed, 10) || 1), MAX_DAYS);
  ```

### 4. Monotonicity Assertions in Risk Scoring
- A risk scoring algorithm must satisfy mathematical **monotonicity**: adding a contractual penalty or tightening a risk threshold must never decrease the computed risk score.
- Ensure all category and profile weightings are positive, and map outputs to canonical bounded intervals `[0, 100]`:
  ```javascript
  function calculateTotalRiskScore(clauseCards) {
    const SEVERITY_WEIGHTS = { HIGH: 12, MEDIUM: 8, LOW: 4 };
    let score = 0;
    for (const card of clauseCards) {
      const weight = SEVERITY_WEIGHTS[card.severity] || 0;
      score += weight;
    }
    // Strict bounding
    return Math.min(100, Math.max(0, Math.round(score)));
  }
  ```

---

## 3. Recommended Workflow & Procedures

1. **Input Normalization:** Cast all numeric parameters using explicit parsers (`Number()`, `parseInt()`, `parseFloat()`). Validate against `isNaN()`.
2. **Denom Guarding:** Ensure all divisor quantities are strictly positive non-zero floats/integers.
3. **Core Arithmetic:** Execute via integer scaling or `Decimal.js` instances.
4. **Rounding & Currency Formatting:** Apply standard rounding (`ROUND_HALF_UP`) at the final step before returning presentation strings:
   ```javascript
   function formatCurrency(amount, currency = 'NGN') {
     return new Intl.NumberFormat('en-NG', {
       style: 'currency',
       currency,
       minimumFractionDigits: 2
     }).format(amount);
   }
   ```

---

## 4. Verification & Validation
- **Floating-Point Drift Test:** Compute 10,000 sequential additions of `0.01` and verify exact integer match (`100.00`).
- **Extreme Time-Horizon Test:** Run 1000-day compounding simulation; verify result is finite, positive, and matches closed-form formula $P(1 + r)^n$.
- **Boundary Stress Test:** Pass `{ buyoutOffer: 0, monthlyExpenses: 0 }`, `{ buyoutOffer: -5000, monthlyExpenses: "invalid" }`. Assert engine returns valid numeric metrics with 0 crashes.
