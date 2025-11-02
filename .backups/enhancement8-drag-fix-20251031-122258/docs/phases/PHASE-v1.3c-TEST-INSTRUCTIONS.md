# Phase v1.3c Test Instructions
## DSCard Surface Parameter Enhancement - Visual Verification Tests

**Date:** October 21, 2025
**Phase:** v1.3c - DSCard Surface Parameter
**Time Required:** 2-3 minutes
**Test File:** `/Core/DesignSystem/DSCardSurfaceTests.swift`

---

## 🎯 What We're Testing

Verify that DSCard's new `surface` parameter correctly displays light backgrounds (ice/ivory/mint) while preserving default white background behavior.

---

## ✅ Quick Test Steps (2 Tests)

### **Test 1: Surface Parameter Works (Ice Background)**

**How to Run:**
1. Open Xcode
2. Navigate to: `FastingTracker/Core/DesignSystem/DSCardSurfaceTests.swift`
3. Find preview: **"Test 1: Surface Parameter - Ice Background"**
4. Click **▶️ Resume** in preview canvas (or Cmd+Option+P)

**Expected Result:**
- ✅ Card has **LIGHT ICE/BLUE background** (NOT white)
- ✅ Text reads: "If you see a light ice/blue background, surface parameter is working!"
- ✅ Green checkmark (✅ SUCCESS) visible

**Pass/Fail:**
- ✅ **PASS:** Light ice/blue background visible
- ❌ **FAIL:** White background (surface parameter not working)

---

### **Test 2: Default Behavior Unchanged (White Background)**

**How to Run:**
1. In same file: `DSCardSurfaceTests.swift`
2. Find preview: **"Test 2: Default Behavior - White Background"**
3. Click **▶️ Resume** in preview canvas

**Expected Result:**
- ✅ Card has **WHITE background** (default behavior)
- ✅ Text reads: "If you see a WHITE background, default behavior is preserved!"
- ✅ Green checkmark (✅ SUCCESS) visible

**Pass/Fail:**
- ✅ **PASS:** White background visible (no surface parameter = default)
- ❌ **FAIL:** Colored background (default behavior broken)

---

## 🎁 Bonus Test: Visual Comparison (Optional)

**How to Run:**
1. Find preview: **"Bonus: All Surface Colors"**
2. Click **▶️ Resume**

**Expected Result:**
- ✅ 4 cards stacked vertically:
  1. **Ice Surface** - Light ice/blue
  2. **Ivory Surface** - Light ivory/cream
  3. **Mint Surface** - Light mint/green
  4. **Default (White)** - White background

**Pass/Fail:**
- ✅ **PASS:** All 4 cards show distinct backgrounds
- ❌ **FAIL:** Cards all look the same

---

## 📊 Test Results Summary

| Test | Status | Notes |
|------|--------|-------|
| Test 1: Ice Surface | ⬜ Pass / ⬜ Fail | Light ice/blue background |
| Test 2: Default White | ⬜ Pass / ⬜ Fail | White background preserved |
| Bonus: All Colors | ⬜ Pass / ⬜ Fail | All surfaces distinct |

---

## ✅ Success Criteria

**Phase v1.3c is verified if:**
1. ✅ Test 1 shows light ice/blue background
2. ✅ Test 2 shows white background
3. ✅ Build succeeded (0 errors, 0 warnings) ← Already verified
4. ✅ No visual regressions in existing cards

---

## 🚨 If Tests Fail

**Test 1 Fails (Ice background not showing):**
- Check `DSCard.swift` line 128: `.background(surface ?? DSColors.cardBackground)`
- Verify `surface` parameter is being passed correctly

**Test 2 Fails (White background not showing):**
- Check `DSCard.swift` - should use `?? DSColors.cardBackground` fallback
- Verify nil surface defaults to white

---

## 📝 Alternative Test Method (If Previews Don't Work)

If Xcode previews aren't working, you can verify by:

1. **Run the app** in Simulator
2. **Navigate to:** Weight Tracker → Tap "Progress Story" button
3. **Observe:** 7-day and 30-day cards
   - Should have light ice/ivory backgrounds (using LightCard still)
   - This confirms Theme.ColorToken.surfaceIce/surfaceIvory work

4. **Check Weight Tracker main screen:**
   - All cards (Current Weight, Milestone, Chart, Stats) should have WHITE backgrounds
   - This confirms default behavior unchanged

---

## ✅ Test Completion Checklist

- [ ] Test 1 executed and passed
- [ ] Test 2 executed and passed
- [ ] Bonus test executed (optional)
- [ ] No visual regressions observed
- [ ] Build succeeded with 0 errors
- [ ] Ready to proceed to next phase

---

**Status:** 🟡 AWAITING MANUAL VERIFICATION
**Next Step:** Run tests in Xcode preview canvas
**Time Required:** 2-3 minutes

---

**END OF TEST INSTRUCTIONS**
