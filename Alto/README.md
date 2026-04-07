# Alto iOS - Production Ready v1.0

This is the complete Alto fitness app implementation with user-friendly API key management.

## ✨ What's New in v1.0

### 🔑 User-Managed API Keys
- **No more environment variables!** Users enter their Gemini API key directly in the app
- Settings screen with secure API key storage
- Model selection (Gemini 1.5 Flash, 2.0 Flash, 1.5 Pro)
- Visual status indicators

### 🤖 Gemini-Powered Features
- **AI Coaching:** Personalized daily workout plans
- **Meal Analysis:** Photo-based macro estimation using Gemini Vision
- **Voice Logging:** Natural language workout parsing
- **Smart Pivoting:** Automatic workout adjustments

### 🏗️ Architecture Improvements
- MVVM pattern with SwiftUI
- UserSettings service for centralized configuration
- Graceful fallback to rule-based orchestration
- Comprehensive error handling

---

## 📋 Setup Instructions

### 1. Open in Xcode

```bash
cd Alto/Alto
open Alto.xcodeproj
```

### 2. Configure Capabilities

Go to **Target → Signing & Capabilities** and add:

- ✅ **HealthKit** (required for sleep/activity tracking)
- ✅ **WeatherKit** (required for weather-based recommendations)

### 3. Add Privacy Permissions to Info.plist

Add these entries to your `Info.plist`:

```xml
<key>NSHealthShareUsageDescription</key>
<string>Alto needs access to your health data to personalize your training plan based on sleep quality and activity levels.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>Alto may update your health data with workout information.</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>Alto uses your location to provide weather-based workout recommendations and adapt your training to conditions.</string>

<key>NSCameraUsageDescription</key>
<string>Alto uses your camera to analyze meal photos for nutrition tracking.</string>

<key>NSMicrophoneUsageDescription</key>
<string>Alto uses your microphone for voice-based workout logging.</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>Alto uses speech recognition to understand your voice workout logs.</string>
```

### 4. Build and Run

Press **⌘R** or click the Play button in Xcode.

---

## 🔧 First-Time User Flow

### Step 1: Complete Onboarding
- Enter name, age, height, weight
- Select health conditions (optional)
- Choose workout preferences
- Set fitness goal and target date
- App generates 4-phase training timeline

### Step 2: Configure Gemini API Key

1. Open **Profile** tab
2. Tap the **AI Features** card (will show "Setup Required")
3. Tap **"How to get API key"**
4. Visit [Google AI Studio](https://aistudio.google.com/apikey)
5. Sign in with your Google account
6. Click **"Create API Key"** → **"Create API key in new project"**
7. Copy the key (starts with `AIza...`)
8. Paste into the app
9. Select preferred model:
   - **Gemini 1.5 Flash** (recommended) - Fast, 15 RPM free tier
   - **Gemini 2.0 Flash** - Experimental, faster
   - **Gemini 1.5 Pro** - Most capable, 2 RPM free tier

### Step 3: Grant Permissions
- **HealthKit** - Tap "Connect" when prompted
- **Location** - Tap "Allow While Using App"
- **Notifications** - Tap "Allow" for daily reminders

---

## 🧪 Running Unit Tests

### In Xcode (Recommended)
Press **⌘U** or go to **Product → Test**

### Via Command Line
```bash
xcodebuild test \
  -scheme Alto \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -enableCodeCoverage YES
```

### Test Coverage
- ✅ **SentinelOrchestratorTests** (18 tests) - Readiness scoring, pivot logic, effort gap analysis
- ✅ **GoalTimelineTests** (5 tests) - 4-phase generation, ordering, coverage
- ✅ **VoiceWorkoutParserTests** (6 tests) - Natural language parsing
- ✅ **NutritionViewModelTests** (10 tests) - Meal CRUD, calorie tracking

---

## 📁 Project Structure

```
AltoApp/
├── AltoApp.swift              # App entry point with UserSettings injection
├── RootView.swift             # Onboarding/Main router
│
├── Services/
│   ├── UserSettings.swift     # 🆕 API key & preferences management
│   ├── ClaudeOrchestrationService.swift  # Gemini AI planning
│   ├── MacroVisionService.swift         # 🆕 Gemini Vision meal analysis
│   ├── OrchestratorAgent.swift          # Rule-based fallback
│   ├── HealthKitService.swift
│   ├── WeatherService.swift
│   ├── VoiceWorkoutParser.swift
│   └── UserStore.swift
│
├── ViewModels/
│   ├── DashboardViewModel.swift
│   ├── OnboardingViewModel.swift
│   ├── NutritionViewModel.swift
│   └── GoalProgressViewModel.swift
│
├── Views/
│   ├── Home/
│   │   ├── HomeView.swift
│   │   └── SentinelPopupView.swift
│   ├── Profile/
│   │   ├── ProfileView.swift
│   │   └── SettingsView.swift      # 🆕 API key configuration UI
│   ├── Nutrition/
│   ├── Goals/
│   ├── Onboarding/
│   └── Components/
│       └── AltoTheme.swift
│
└── Models/
    ├── ProfileModels.swift
    ├── NutritionModels.swift
    ├── ActivityModels.swift
    └── OrchestratorModels.swift
```

---

## 🔑 API Key Management

### Where is it stored?
- **UserDefaults** (encrypted at rest by iOS)
- Key: `"geminiAPIKey"`
- Auto-saved on every change

### How to access?
```swift
@EnvironmentObject var settings: UserSettings

if settings.isAPIKeyConfigured {
    // Proceed with AI features
} else {
    // Show setup prompt
}
```

### Security Notes
- ✅ Never logged or transmitted to external servers
- ✅ Only sent to Google Gemini API
- ✅ Can be cleared anytime in Settings
- ⚠️ **Production:** Consider migrating to iOS Keychain for enhanced security

---

## 🎯 Feature Flags

### With API Key Configured
- ✅ AI-powered daily workout plans
- ✅ Meal photo analysis with macros
- ✅ Personalized coaching insights

### Without API Key (Fallback)
- ✅ Rule-based workout plans
- ✅ Manual meal entry
- ✅ Voice workout logging
- ✅ Goal timeline tracking

---

## 🐛 Troubleshooting

### "API key required" error
**Solution:** Profile → AI Features → Enter API Key

### "Rate limit exceeded (429)"
**Solutions:**
1. Wait 60 seconds (rate limit resets)
2. Switch to Gemini 1.5 Pro in Settings
3. Check quota at [Google AI Studio](https://aistudio.google.com)

### WeatherKit not working
**Requirements:**
- Apple Developer membership ($99/year)
- WeatherKit capability enabled
- Location permission granted

### HealthKit connection fails
**Check:**
1. HealthKit capability added to target
2. Privacy permissions in Info.plist
3. Permissions granted in iOS Settings → Health

### Build errors
**Common fixes:**
```bash
# Clean build folder
⌘⇧K (Xcode)

# Reset package cache
File → Packages → Reset Package Caches

# Delete derived data
~/Library/Developer/Xcode/DerivedData
```

---

## 📚 Additional Documentation

- **[README.md](../../README.md)** - User guide and features overview
- **[ARCHITECTURE.md](../../ARCHITECTURE.md)** - Technical architecture deep-dive
- **Testing Guide** - See `AltoTests/` folder

---

## 🚀 Deployment

### TestFlight

1. Archive the app: **Product → Archive**
2. Validate the archive
3. Distribute to App Store Connect
4. Create new TestFlight build
5. Add external testers

### App Store

1. Complete App Store Connect listing
2. Upload screenshots (required sizes)
3. Write privacy policy (required for HealthKit)
4. Submit for review

**Important:** WeatherKit requires Apple Developer Program membership.

---

## 🔒 Privacy Compliance

### Data Collection
- ❌ No personal data collected
- ❌ No analytics or tracking
- ❌ No third-party SDKs

### Data Storage
- ✅ All data stored locally
- ✅ HealthKit data stays in Apple Health
- ✅ API key stored in UserDefaults
- ⚠️ Meal photos sent to Gemini (temporarily, then deleted)

### User Control
- Users can clear API key anytime
- No account required
- No data syncing (unless Supabase configured)

---

## 📄 License

MIT License - See LICENSE file for details

---

## 🙏 Credits

- **Google Gemini** for AI orchestration
- **Apple HealthKit** for health data
- **Apple WeatherKit** for weather data
- **SwiftUI** for UI framework

---

**Version:** 1.0.0  
**Last Updated:** April 2026  
**Support:** See main [README.md](../../README.md#-support)
