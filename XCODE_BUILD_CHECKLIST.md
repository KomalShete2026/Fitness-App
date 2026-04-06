# Xcode Build Checklist ✅

## Quick Verification Guide

Follow these steps to ensure Alto compiles and runs successfully.

---

## 🎯 Prerequisites

- ✅ macOS with Xcode 15.0+ installed
- ✅ iOS 17.0+ SDK available
- ✅ Apple Developer account (free or paid)

---

## 📋 Step-by-Step Build Guide

### Step 1: Open Project (30 seconds)

```bash
cd /Users/kkannav/Desktop/github_personal/Fitness-App/Alto/Alto
open Alto.xcodeproj
```

**Verify:**
- [ ] Xcode opens without errors
- [ ] Project navigator shows AltoApp folder
- [ ] No red errors in Issue Navigator

---

### Step 2: Select Team & Signing (1 minute)

**Actions:**
1. Click **Alto** in project navigator (top left)
2. Select **Alto** target (under TARGETS)
3. Click **Signing & Capabilities** tab
4. Under "Signing", choose your **Team** from dropdown

**If you don't have a team:**
- Xcode → Preferences → Accounts → Add Apple ID
- Use free Apple ID (no paid developer account needed for testing)

**Verify:**
- [ ] Team selected (not "None")
- [ ] Signing Certificate shows (Developer or Personal Team)
- [ ] Provisioning Profile shows "Xcode Managed Profile"

---

### Step 3: Add Capabilities (2 minutes)

**Still in Signing & Capabilities tab:**

1. Click **+ Capability** button
2. Search for **HealthKit**
3. Double-click to add
4. Click **+ Capability** again
5. Search for **WeatherKit**
6. Double-click to add

**Verify:**
- [ ] HealthKit section appears with checkboxes
- [ ] WeatherKit section appears
- [ ] No errors shown in capabilities

**Note:** WeatherKit requires Apple Developer membership ($99/year). If you don't have it, the app will still build but weather features won't work.

---

### Step 4: Update Info.plist (3 minutes)

**Find Info.plist:**
1. Project navigator → Alto → AltoApp → Info.plist
2. Right-click Info.plist → **Open As** → **Source Code**

**Add these entries before the closing `</dict>` tag:**

```xml
<key>NSHealthShareUsageDescription</key>
<string>Alto needs access to your health data to personalize your training plan.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>Alto may update your health data with workout information.</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>Alto uses your location to provide weather-based workout recommendations.</string>

<key>NSCameraUsageDescription</key>
<string>Alto uses your camera to analyze meal photos for nutrition tracking.</string>

<key>NSMicrophoneUsageDescription</key>
<string>Alto uses your microphone for voice-based workout logging.</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>Alto uses speech recognition to understand your voice workout logs.</string>
```

**Verify:**
- [ ] All 6 keys added
- [ ] No syntax errors (XML should be valid)
- [ ] File saves successfully

---

### Step 5: Build Project (30 seconds)

**Action:** Press **⌘B** or Product → Build

**Expected Output:**
```
Build succeeded
0 errors, 0 warnings
```

**If build fails:**

**Common Error 1:** "No such module SwiftUI"
- Solution: Check deployment target is iOS 17.0+
- Target → General → Minimum Deployments → iOS 17.0

**Common Error 2:** "Signing requires a development team"
- Solution: Go back to Step 2, select your Team

**Common Error 3:** "Bundle identifier ... cannot be registered"
- Solution: Change bundle ID to something unique
- Target → General → Identity → Bundle Identifier
- Change to: `com.yourname.alto`

**Verify:**
- [ ] Build completes without errors
- [ ] Issue Navigator shows no red errors
- [ ] Status bar shows "Build Succeeded"

---

### Step 6: Select Simulator (30 seconds)

**Action:**
1. Click device selector (next to Play button)
2. Choose **iPhone 15** or newer
3. If no simulators shown, download via Settings

**Verify:**
- [ ] iPhone 15 (or similar) selected
- [ ] Not showing "Any iOS Device"

---

### Step 7: Run App (1 minute)

**Action:** Press **⌘R** or click ▶️ Play button

**Expected Flow:**
1. Simulator launches (if not already open)
2. App installs on simulator
3. App icon appears on home screen
4. App opens automatically
5. Onboarding screen appears

**Verify:**
- [ ] Simulator launches
- [ ] App installs successfully
- [ ] No crash on launch
- [ ] Onboarding screen shows

---

### Step 8: Test Core Features (5 minutes)

**Test 1: Onboarding**
- [ ] Enter name → Next button enables
- [ ] Enter age, height, weight
- [ ] Select health conditions (optional)
- [ ] Choose goal and date
- [ ] Timeline generated
- [ ] Reaches main app

**Test 2: Settings Access**
- [ ] Tap **Profile** tab (bottom right)
- [ ] See API Features card with "Setup Required"
- [ ] Tap card → Settings opens
- [ ] See API key input field
- [ ] See model picker
- [ ] Tap "Done" → Returns to profile

**Test 3: Daily Sentinel**
- [ ] Force quit app
- [ ] Reopen app
- [ ] Daily Sentinel popup appears
- [ ] Move sliders (1-5 scale)
- [ ] Submit → Popup dismisses

**Test 4: Voice Logging (Basic)**
- [ ] Tap **Home** tab
- [ ] Scroll to "Log a Workout" card
- [ ] Type "30 mins of yoga"
- [ ] Tap "Parse & Log"
- [ ] See "Logged: yoga · 30 min"

---

## 🔧 Troubleshooting

### Issue: Build Fails with Signing Error

**Symptoms:**
```
Signing for "Alto" requires a development team.
Select a development team in the Signing & Capabilities editor.
```

**Solution:**
1. Xcode → Preferences → Accounts
2. Click **+** → Add Apple ID
3. Sign in with any Apple ID (free account OK)
4. Back to project → Signing & Capabilities
5. Team dropdown → Select your account

---

### Issue: Simulator Doesn't Launch

**Solution 1:** Reset simulator
```bash
xcrun simctl shutdown all
xcrun simctl erase all
```

**Solution 2:** Download iOS 17.0 simulator
- Xcode → Settings → Platforms
- Click **+** next to iOS
- Download iOS 17.0 simulator

---

### Issue: App Crashes on Launch

**Check Console for errors:**
- View → Debug Area → Show Debug Area (⌘⇧Y)
- Look for red error messages

**Common causes:**
- Missing HealthKit capability
- Missing Info.plist permissions
- Invalid code signing

---

### Issue: WeatherKit Errors

**Expected behavior:**
- Without paid developer account: Weather features disabled
- App should still work for everything else

**To verify:**
- Look for "WeatherKit: Unavailable" in console
- App should fall back gracefully

---

## ✅ Final Verification

### Build System
- [ ] ✅ Project builds without errors (⌘B)
- [ ] ✅ No warnings in build log
- [ ] ✅ App runs in simulator (⌘R)
- [ ] ✅ No crashes on launch

### Configuration
- [ ] ✅ Team selected for signing
- [ ] ✅ HealthKit capability added
- [ ] ✅ WeatherKit capability added (or accepted as unavailable)
- [ ] ✅ All 6 Info.plist permissions added

### Functionality
- [ ] ✅ Onboarding completes successfully
- [ ] ✅ Settings screen accessible
- [ ] ✅ API key can be entered (but not required to test)
- [ ] ✅ Voice logging works with manual text entry
- [ ] ✅ Daily Sentinel popup appears

---

## 🎉 Success!

If all checkboxes are marked, your Alto app is:
- ✅ **Building successfully**
- ✅ **Running on simulator**
- ✅ **Ready for testing**
- ✅ **Ready for API key setup**

---

## 🚀 Next Steps

### For Testing
1. Get free Gemini API key at [aistudio.google.com/apikey](https://aistudio.google.com/apikey)
2. Enter key in app: Profile → AI Features → Settings
3. Test AI features:
   - Daily workout plan generation
   - Meal photo analysis (take photo of food)
   - Voice dictation (tap "Dictate" button)

### For Deployment
1. Test on real iPhone:
   - Connect via USB
   - Select device instead of simulator
   - Press ⌘R
2. Prepare for TestFlight:
   - Product → Archive
   - Distribute to App Store Connect
3. Submit to App Store:
   - Create listing at [appstoreconnect.apple.com](https://appstoreconnect.apple.com)

---

## 📞 Still Having Issues?

### Quick Fixes
```bash
# Clean build folder
⌘⇧K in Xcode

# Reset simulators
xcrun simctl erase all

# Restart Xcode
Close Xcode, reopen project
```

### Documentation
- **Setup Guide:** SETUP_GUIDE.md
- **Architecture:** ARCHITECTURE.md
- **Changes:** CHANGES_SUMMARY.md

### Support
- Open an issue on GitHub
- Check documentation for detailed guides
- Review error messages carefully

---

## 📊 Build Time Estimates

| Step | Expected Time |
|------|---------------|
| Open project | 30 seconds |
| Configure signing | 1 minute |
| Add capabilities | 2 minutes |
| Update Info.plist | 3 minutes |
| Build | 30 seconds |
| Run | 1 minute |
| Test | 5 minutes |
| **TOTAL** | **~13 minutes** |

---

<div align="center">

**Happy Building! 🎉**

If you reached this point with all ✅ checkboxes marked,  
your Alto app is ready to change lives! 💪

</div>
