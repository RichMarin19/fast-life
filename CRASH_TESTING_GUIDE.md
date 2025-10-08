# Crash Reporting Testing Guide

## 🧪 Debug Mode Testing (Current)

### What You'll See Now:
When running in DEBUG mode, crash reports are logged locally:

```
🚨 CrashReport[healthkit]: The operation couldn't be completed. (HealthKit error 5.)
   Context: operation=fetchWeightData_anchored, startDate=2025-10-07 15:30:00
```

### Test Methods:

#### 1. **App Launch Test**
- Run app in Xcode
- Check console for: "CrashReportManager initialized" logs
- Should see anonymous user ID set

#### 2. **Force HealthKit Error Test**
Add to any view temporarily:
```swift
Button("Test Crash Report") {
    let testError = NSError(domain: "Test", code: 999, userInfo: [
        NSLocalizedDescriptionKey: "This is a test crash report"
    ])
    CrashReportManager.shared.recordHealthKitError(testError, context: [
        "test": "button_pressed",
        "timestamp": Date().description
    ])
}
```

#### 3. **Test All Categories**
```swift
// Test different error types
CrashReportManager.shared.recordWeightError(testError)
CrashReportManager.shared.recordHydrationError(testError)
CrashReportManager.shared.recordFastingError(testError)
CrashReportManager.shared.recordChartError(testError)
CrashReportManager.shared.recordNotificationError(testError)
```

#### 4. **Performance Issue Test**
```swift
// Test performance monitoring
CrashReportManager.shared.recordPerformanceIssue(
    operation: "chart_render",
    duration: 5.0,
    threshold: 2.0
)
```

## 🚀 Production Mode Testing

### When you build for RELEASE:
- Firebase Crashlytics would be active (when properly configured)
- Errors send to Firebase Console
- No local logging (privacy/performance)

### Firebase Console Setup Required:
1. Create Firebase project at https://console.firebase.google.com
2. Add iOS app with bundle ID `com.fastlife.app`
3. Download real `GoogleService-Info.plist`
4. Replace template file
5. Add Firebase SDK via Swift Package Manager

## 📊 Current Integration Points

### Existing Error Logging:
✅ **HealthKitManager**: Weight/Water/Sleep/Fasting sync errors
✅ **WeightManager**: Authorization failures
✅ **FastingManager**: Persistence errors (after DataStore update)
✅ **App Launch**: Initialization tracking

### What Gets Logged:
- **Error Context**: Operation, timestamps, data sizes
- **User Context**: Anonymous device ID (privacy-compliant)
- **Performance Issues**: Slow operations (>2 second threshold)
- **Custom Messages**: App state debugging

## 🔍 Verification Steps

### 1. Check Xcode Console
Run app and look for:
```
📝 AppLogger[general]: CrashReportManager initialized for production
📝 AppLogger[general]: Setting user context: [device_hash]
🚨 CrashReport[healthkit]: Error message here
   Context: operation=xyz, key=value
```

### 2. Trigger Real Errors
- Revoke HealthKit permissions
- Try syncing data
- Check logs for crash reports

### 3. Performance Testing
- Load large datasets
- Watch for performance warnings
- Verify threshold logging

## 📋 Test Checklist

- [ ] App launches without crashes
- [ ] CrashReportManager initializes successfully
- [ ] Anonymous user ID is set
- [ ] Test button triggers crash reports in console
- [ ] HealthKit errors trigger crash reports
- [ ] Performance monitoring works
- [ ] All 7 categories work (healthkit, weight, hydration, sleep, fasting, charts, notifications)

## 🎯 Next Steps for Production

1. **Get real GoogleService-Info.plist** from Firebase
2. **Add Firebase SDK** via Xcode → File → Add Package Dependencies
3. **Uncomment production code** in CrashReportManager
4. **Test with TestFlight** to see crashes in Firebase Console