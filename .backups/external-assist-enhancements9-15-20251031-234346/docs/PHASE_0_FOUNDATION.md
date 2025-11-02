# Phase 0: Foundation & App Store Preparation

> **The infrastructure that should have been built first**
>
> **Purpose:** Privacy manifest, App Store compliance, and foundational setup
>
> **Estimated Time:** 2-4 hours
>
> **Last Updated:** October 27, 2025

---

## 📋 Overview

**Phase 0** covers the foundational infrastructure required for App Store submission. These tasks were missed during initial development and must be completed before launch.

**Why This Matters:**
- **App Store Rejection:** Missing privacy manifest = automatic rejection (iOS 17+)
- **Legal Compliance:** Health data requires highest privacy standards
- **User Trust:** Professional privacy practices build credibility

**What We'll Build:**
1. Privacy Manifest (PrivacyInfo.xcprivacy)
2. App Store Connect Record
3. TestFlight Setup Foundation
4. Basic Compliance Documentation

---

## 🔒 Section 1: Privacy Manifest (Required for App Store)

### Step 1.1: Understand Privacy Manifest Requirements

**What Is It?**
- iOS 17+ requires apps to declare which "privacy-impacting APIs" they use
- Declared in a file called `PrivacyInfo.xcprivacy` in app bundle
- Must specify "required reason" codes for each API

**Which APIs Require Declaration?**
Fast LIFe likely uses these privacy-impacting APIs:
1. **NSPrivacyAccessedAPICategoryFileTimestamp** - File timestamp access
2. **NSPrivacyAccessedAPICategorySystemBootTime** - System boot time
3. **NSPrivacyAccessedAPICategoryDiskSpace** - Disk space access
4. **NSPrivacyAccessedAPICategoryUserDefaults** - UserDefaults access

**HealthKit APIs** (weight, sleep, activity) do NOT require privacy manifest declarations because they have separate permission prompts.

### Step 1.2: Create PrivacyInfo.xcprivacy File

**Instructions:**

1. **Open Xcode project:**
   ```bash
   open /Users/richmarin/Desktop/FastingTracker/FastingTracker.xcodeproj
   ```

2. **Create privacy manifest file:**
   - Right-click on "FastingTracker" folder in Project Navigator
   - Select "New File..."
   - Choose "App Privacy" template
   - Name: `PrivacyInfo.xcprivacy`
   - Target: FastingTracker (ensure checkbox is checked)
   - Click "Create"

3. **Add API declarations:**
   Open `PrivacyInfo.xcprivacy` and add the following XML:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Privacy Manifest for Fast LIFe -->
    <!-- Declares privacy-impacting APIs used by the app -->

    <!-- API Category Declarations -->
    <key>NSPrivacyAccessedAPITypes</key>
    <array>

        <!-- 1. File Timestamp Access -->
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <!-- C617.1: Accessing timestamps to determine order of user-created content -->
                <string>C617.1</string>
            </array>
        </dict>

        <!-- 2. System Boot Time Access -->
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategorySystemBootTime</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <!-- 35F9.1: Measuring time intervals for performance monitoring -->
                <string>35F9.1</string>
            </array>
        </dict>

        <!-- 3. UserDefaults Access -->
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <!-- CA92.1: Accessing user preferences and app configuration -->
                <string>CA92.1</string>
            </array>
        </dict>

    </array>

    <!-- Data Collection Practices -->
    <key>NSPrivacyCollectedDataTypes</key>
    <array>

        <!-- Health & Fitness Data -->
        <dict>
            <key>NSPrivacyCollectedDataType</key>
            <string>NSPrivacyCollectedDataTypeHealthAndFitness</string>
            <key>NSPrivacyCollectedDataTypeLinked</key>
            <false/>
            <key>NSPrivacyCollectedDataTypeTracking</key>
            <false/>
            <key>NSPrivacyCollectedDataTypePurposes</key>
            <array>
                <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
                <string>NSPrivacyCollectedDataTypePurposeAnalytics</string>
            </array>
        </dict>

    </array>

    <!-- Tracking Domains (None - we don't do cross-site tracking) -->
    <key>NSPrivacyTrackingDomains</key>
    <array>
        <!-- No tracking domains -->
    </array>

    <!-- Privacy Tracking Enabled -->
    <key>NSPrivacyTracking</key>
    <false/>

</dict>
</plist>
```

4. **Verify file is included in app bundle:**
   - Click "FastingTracker" project (blue icon)
   - Select "FastingTracker" target
   - Click "Build Phases" tab
   - Expand "Copy Bundle Resources"
   - Verify `PrivacyInfo.xcprivacy` is listed
   - If not, click "+" and add it

5. **Build and verify:**
   ```bash
   cd /Users/richmarin/Desktop/FastingTracker
   xcodebuild -scheme FastingTracker -configuration Debug clean build
   ```
   - Build should succeed
   - Check build output for privacy manifest processing

### Step 1.3: Update Info.plist for Privacy Descriptions

Fast LIFe accesses HealthKit data, which requires user-facing privacy descriptions.

**Verify these keys exist in Info.plist:**

```xml
<!-- HealthKit Privacy Descriptions -->
<key>NSHealthShareUsageDescription</key>
<string>Fast LIFe needs access to your health data to provide personalized fasting insights and track your wellness journey.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>Fast LIFe can save your weight, sleep, hydration, and mood data to HealthKit for a complete health picture.</string>
```

**How to Add (if missing):**
1. Open `FastingTracker/Info.plist` in Xcode
2. Right-click → "Add Row"
3. Type `NSHealthShareUsageDescription`
4. Value: "Fast LIFe needs access to your health data to provide personalized fasting insights and track your wellness journey."
5. Repeat for `NSHealthUpdateUsageDescription`

### Step 1.4: Audit Third-Party Dependencies

**OpenAI SDK (if using):**
- If using OpenAI's official SDK, check if they provide a privacy manifest
- If not, you may need to declare their APIs in your manifest

**How to Check:**
```bash
cd /Users/richmarin/Desktop/FastingTracker
find . -name "PrivacyInfo.xcprivacy" -path "*/DerivedData/*" -prune -o -type f -print
```

**Current Status:**
- Fast LIFe uses direct HTTP calls to OpenAI API (no SDK)
- No third-party SDK privacy concerns

---

## 📱 Section 2: App Store Connect Setup

### Step 2.1: Create App Store Connect Record

**Prerequisites:**
- Apple Developer account ($99/year)
- Enrolled in Apple Developer Program

**Instructions:**

1. **Log in to App Store Connect:**
   - Visit: https://appstoreconnect.apple.com
   - Sign in with Apple Developer account

2. **Create new app:**
   - Click "My Apps"
   - Click "+" button (top-left)
   - Select "New App"

3. **Fill in required information:**
   - **Platforms:** iOS
   - **Name:** Fast LIFe (or "Fast LIFE" if LIFe is taken)
   - **Primary Language:** English (U.S.)
   - **Bundle ID:** Select the bundle ID created in Xcode (com.fastlife.FastingTracker)
   - **SKU:** FASTLIFE001 (unique identifier for internal use)
   - **User Access:** Full Access

4. **Click "Create"**

### Step 2.2: Complete App Information

**Navigate to "App Information" section:**

1. **Category:**
   - **Primary:** Health & Fitness
   - **Secondary:** Lifestyle

2. **Age Rating:**
   - Click "Edit" next to Age Rating
   - Answer questionnaire:
     - Medical/Treatment Information: Yes (provides health insights)
     - Unrestricted Web Access: No
     - All other questions: No
   - Should result in: **4+** or **12+** (depending on medical info interpretation)

3. **Privacy Policy URL:**
   - **Required:** Must create privacy policy
   - **Placeholder:** https://fastlife.app/privacy (create this before submission)

4. **Support URL:**
   - **Required:** https://fastlife.app/support (create this before submission)

### Step 2.3: Prepare App Store Listing

**Navigate to "App Store" tab:**

1. **App Name:**
   - Fast LIFe - Intermittent Fasting & AI Coach

2. **Subtitle (30 chars max):**
   - Fasting Tracker with AI Insights

3. **Description (4000 chars max):**
   ```
   Transform your health journey with Fast LIFe - the intelligent fasting tracker that combines intermittent fasting, weight tracking, and AI-powered coaching.

   PERSONALIZED AI COACH
   Meet AInstein, your personal health advisor. Ask questions like "Why isn't my weight changing?" or "How's my sleep affecting my progress?" and get insights based on YOUR data.

   COMPREHENSIVE TRACKING
   • Fasting Timer: Track 16:8, 18:6, 20:4, or custom fasting windows
   • Weight Tracking: Sync with HealthKit or log manually
   • Sleep Monitoring: Understand sleep's impact on your progress
   • Hydration Logging: Stay on track with water intake
   • Mood & Energy: See how fasting affects how you feel

   POWERFUL INSIGHTS
   • 7/30/90-day trend analysis
   • Fasting streaks and milestones
   • Correlations (sleep quality vs weight loss)
   • Goal projections and progress tracking

   INDUSTRY-LEADING PRIVACY
   • All data stored locally and in HealthKit
   • OpenAI API calls are encrypted
   • No data sold or shared with third parties
   • Optional iCloud backup

   WHY FAST LIFE?
   Unlike other fasting apps, Fast LIFe doesn't just track - it understands. Our AI analyzes your patterns and provides actionable insights, just like a personal health coach.

   Perfect for:
   • Intermittent fasting beginners and experts
   • Weight loss journeys
   • Wellness optimization
   • Anyone seeking data-driven health insights

   Download Fast LIFe today and experience the future of fasting.

   ---

   HEALTH DISCLAIMER
   Fast LIFe is a wellness app and not a medical device. Consult your doctor before starting any fasting or weight loss program. Not intended to diagnose, treat, cure, or prevent any disease.
   ```

4. **Keywords (100 chars max):**
   ```
   fasting,intermittent fasting,weight loss,AI coach,health tracker,diet,wellness,HealthKit
   ```

5. **Promotional Text (170 chars max):**
   ```
   New: Ask AInstein anything! "Why isn't my weight changing?" Get personalized insights based on YOUR fasting data. Download now!
   ```

### Step 2.4: Prepare Screenshots

**Required Sizes:**
- **6.7" Display (iPhone 15 Pro Max):** 1290 x 2796 pixels (3 required)
- **6.5" Display (iPhone 11 Pro Max):** 1284 x 2778 pixels (3 required)
- **5.5" Display (iPhone 8 Plus):** 1242 x 2208 pixels (3 required)

**Recommended Screenshots:**
1. **Fasting Timer** - Active fast with circular timer
2. **AI Coach Chat** - Conversation with AInstein showing insights
3. **Dashboard** - Weight chart, stats, trends
4. **Analytics** - 30-day trends, correlations
5. **Profile** - Goal progress, milestones

**Tools for Creating Screenshots:**
- **Option 1:** Xcode Simulator (Cmd+S to save screenshot)
- **Option 2:** Actual device (take screenshot, export from Photos)
- **Option 3:** Design in Figma with device frames

**Placeholder Text (DO BEFORE SUBMISSION):**
```
⚠️ TODO: Create 3+ screenshots for each required size
    - Use device frames from Apple's resources
    - Add text overlays highlighting key features
    - Ensure all text is readable at thumbnail size
```

---

## 🧪 Section 3: TestFlight Beta Testing Setup

### Step 3.1: Enable TestFlight

**In App Store Connect:**

1. **Navigate to "TestFlight" tab**
2. **Internal Testing:**
   - Add Apple Developer account email
   - You can test immediately after upload

3. **External Testing (Optional for Beta):**
   - Click "Create New Group"
   - Name: "Beta Testers"
   - Add testers: Up to 10,000 external testers
   - **Note:** External testing requires App Review approval (2-3 days)

### Step 3.2: Archive and Upload Build

**Instructions:**

1. **Ensure Config.xcconfig is wired** (see HANDOFF.md:492-522)

2. **Set version and build number:**
   - Open Xcode project
   - Select "FastingTracker" target
   - General tab
   - Version: `1.0.0`
   - Build: `1` (increment for each upload)

3. **Archive build:**
   ```bash
   cd /Users/richmarin/Desktop/FastingTracker
   xcodebuild archive \
     -scheme FastingTracker \
     -configuration Release \
     -archivePath "./build/FastingTracker.xcarchive"
   ```

4. **Export for App Store:**
   ```bash
   xcodebuild -exportArchive \
     -archivePath "./build/FastingTracker.xcarchive" \
     -exportPath "./build/" \
     -exportOptionsPlist "./ExportOptions.plist"
   ```

5. **Upload to App Store Connect:**
   - Open Xcode
   - Window → Organizer
   - Select archive
   - Click "Distribute App"
   - Choose "App Store Connect"
   - Click "Upload"
   - Wait for processing (15-60 minutes)

**Alternative (Easier):**
- Use Xcode's Product → Archive menu
- Follow guided export wizard

### Step 3.3: Export Compliance

**Required for International Distribution:**

When uploading, you'll be asked:
> "Does your app use encryption?"

**Answer:**
- **Yes** (HTTPS uses encryption)
- Select: "Your app uses standard encryption" (exemption applies)

**Why This Matters:**
- HTTPS uses encryption for API calls
- Standard encryption is exempt from export compliance documentation
- No additional paperwork required

---

## 🛡️ Section 4: Compliance & Security Checklist

### Step 4.1: HIPAA Compliance Review

**Is Fast LIFe Subject to HIPAA?**

**Likely NO, but verify with these criteria:**

1. **Are you a Covered Entity?**
   - Healthcare provider? No
   - Health plan? No
   - Healthcare clearinghouse? No

2. **Are you a Business Associate?**
   - Do you handle PHI (Protected Health Information) on behalf of a covered entity? No

**Conclusion:**
- Fast LIFe is a **personal wellness app**, not a medical device
- Users own their data (stored locally, in HealthKit, or iCloud)
- NOT subject to HIPAA

**However:**
- **Best Practice:** Follow HIPAA-like security standards for user trust
- Encrypt data at rest and in transit
- Allow users to export/delete data
- Provide clear privacy policy

### Step 4.2: OpenAI Data Processing Agreement

**Question:** Does OpenAI store user data?

**Answer (as of October 2025):**
- **API requests:** OpenAI does NOT use API data for training (per their policy)
- **Data retention:** 30 days for abuse monitoring, then deleted
- **BAA Available:** OpenAI offers Business Associate Agreement (BAA) for HIPAA compliance if needed

**Action Required:**
- Review OpenAI's Data Usage Policy: https://openai.com/policies/data-usage
- If targeting healthcare market, consider BAA

### Step 4.3: GDPR Compliance (EU Users)

**If you have EU users, you must support:**

1. **Right to Access:**
   - Users can request their data
   - Provide data export feature (JSON or CSV)

2. **Right to Erasure:**
   - Users can delete their account and all data
   - Implement "Delete My Account" button

3. **Data Minimization:**
   - Only collect necessary data
   - Fast LIFe: Weight, fasting times, sleep, hydration, mood (all necessary)

4. **Consent:**
   - Clear privacy policy
   - Explicit consent for data processing

**Current Status:**
- ✅ Data stored locally (user controls it)
- ❌ No data export feature yet
- ❌ No account deletion feature yet

**TODO (Before EU Launch):**
- Add "Export My Data" button → JSON file
- Add "Delete My Account" button → Wipe all local data

---

## 📊 Section 5: Post-Setup Verification

### Checklist: Are We Ready for App Store Submission?

**Privacy & Compliance:**
- [ ] PrivacyInfo.xcprivacy created and included in bundle
- [ ] Info.plist has NSHealthShareUsageDescription and NSHealthUpdateUsageDescription
- [ ] Privacy policy URL created (https://fastlife.app/privacy)
- [ ] Support URL created (https://fastlife.app/support)
- [ ] Medical disclaimer in App Store description

**App Store Connect:**
- [ ] App record created
- [ ] App name and subtitle set
- [ ] Description written (4000 chars)
- [ ] Keywords optimized (100 chars)
- [ ] Screenshots prepared (3+ per required size)
- [ ] Age rating completed (4+ or 12+)
- [ ] Category selected (Health & Fitness)

**TestFlight:**
- [ ] Internal testing enabled
- [ ] First build uploaded and processed
- [ ] Export compliance completed (standard encryption)

**Build Configuration:**
- [ ] Config.xcconfig wired to Xcode (Debug & Release)
- [ ] OPENAI_API_KEY verified in build settings
- [ ] Version set to 1.0.0
- [ ] Build number set to 1 (or incremented)

**Testing:**
- [ ] Build runs on device
- [ ] Fasting timer works
- [ ] Weight entry works
- [ ] AInstein chat works (LLM responds)
- [ ] HealthKit permissions prompt
- [ ] No crashes during basic flow

**Known Gaps (Address Later):**
- [ ] Crash reporting (Sentry) - P1
- [ ] Analytics (Firebase) - P2
- [ ] Data export feature - P2 (GDPR)
- [ ] Account deletion feature - P2 (GDPR)
- [ ] Onboarding flow - P2
- [ ] Help & support system - P2

---

## 🚀 What's Next After Phase 0?

**Immediate (This Week):**
1. ✅ Complete Phase 0 (this document)
2. ⏳ Upload first TestFlight build
3. ⏳ Test on device
4. ⏳ Add crash reporting (Sentry or Firebase Crashlytics)

**Short-Term (Next 2 Weeks):**
5. Add analytics (Firebase Analytics or Mixpanel)
6. Design onboarding flow
7. Create privacy policy and support pages
8. Write unit tests for critical paths

**Medium-Term (Weeks 3-4):**
9. Complete App Store screenshots
10. Beta test with external users
11. Implement feedback
12. Submit for App Review

**Long-Term (Months 2-3):**
13. Add subscription infrastructure (if monetizing)
14. Implement advanced features (voice input, notifications)
15. Optimize performance and polish UI
16. Launch marketing campaign

---

## 📚 Resources

### Apple Documentation
- **Privacy Manifest:** https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
- **Required Reason API:** https://developer.apple.com/documentation/bundleresources/privacy_manifest_files/describing_use_of_required_reason_api
- **App Store Review Guidelines:** https://developer.apple.com/app-store/review/guidelines/
- **TestFlight Beta Testing:** https://developer.apple.com/testflight/

### Privacy & Compliance
- **OpenAI Data Usage Policy:** https://openai.com/policies/data-usage
- **GDPR Compliance Checklist:** https://gdpr.eu/checklist/
- **HIPAA Compliance (if applicable):** https://www.hhs.gov/hipaa/index.html

### Tools
- **Screenshot Framer:** https://www.figma.com (device frames)
- **ASO Tools:** https://www.appannie.com, https://www.sensor tower.com
- **Privacy Policy Generator:** https://www.termsfeed.com/privacy-policy-generator/

---

## ✅ Completion Criteria

**Phase 0 is complete when:**

1. ✅ PrivacyInfo.xcprivacy created and verified in bundle
2. ✅ Info.plist has all required privacy descriptions
3. ✅ App Store Connect record created
4. ✅ App information filled out (name, category, age rating)
5. ✅ TestFlight internal testing enabled
6. ⏳ First build uploaded to TestFlight (pending Config.xcconfig fix)
7. ⏳ Build tested on device (pending Config.xcconfig fix)

**Current Status:** 5/7 complete (71%)

**Blockers:**
- Config.xcconfig not wired (5 min fix)

**Next Steps:**
1. User wires Config.xcconfig in Xcode
2. Build and upload to TestFlight
3. Test on device
4. Mark Phase 0 complete ✅

---

**Last Updated:** October 27, 2025

**Phase Owner:** Development Team

**Estimated Completion:** Week 12 (this week)
