# Alto - AI-Powered Adaptive Fitness Coach

<div align="center">

**Personalized training that adapts to your body, not the other way around**

[![Platform](https://img.shields.io/badge/platform-iOS%2017.0%2B-blue.svg)]()
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-orange.svg)]()
[![Gemini](https://img.shields.io/badge/AI-Google%20Gemini-blueviolet.svg)]()
[![License](https://img.shields.io/badge/license-MIT-green.svg)]()

</div>

---

## 🌟 Overview

Alto is an intelligent iOS fitness app that uses Google Gemini AI to create personalized, adaptive training plans based on your daily readiness, sleep quality, weather conditions, and menstrual cycle phase. It combines cutting-edge AI orchestration with rule-based safety systems to prevent overtraining and optimize performance.

### ✨ Key Features

- **🧠 AI-Powered Daily Planning** - Gemini generates personalized workout plans every morning
- **📊 Smart Readiness Scoring** - Daily wellness check-in with soreness, stress, and motivation tracking
- **🔄 Intelligent Pivoting** - Automatically adjusts workouts when readiness < 40 or weather is poor
- **🎙️ Voice Workout Logging** - Speak your workouts: "I did 30 mins of yoga"
- **📸 Meal Analysis** - Photo-based macro estimation using Gemini Vision
- **🌙 Cycle-Aware Training** - Reduces intensity during luteal/menstrual phases
- **⚡ HealthKit Integration** - Sleep, HRV, and activity tracking
- **🌦️ WeatherKit Integration** - Outdoor/indoor workout adaptation
- **🎯 4-Phase Training** - Base → Build → Peak → Taper progression

---

## 🚀 Getting Started

### Prerequisites

- **Xcode 15.0+** (for iOS 17.0 support)
- **iOS 17.0+ device or simulator**
- **Google Gemini API Key** ([Get it free here](https://aistudio.google.com/apikey))

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/Fitness-App.git
   cd Fitness-App/Alto/Alto
   ```

2. **Open in Xcode**
   ```bash
   open Alto.xcodeproj
   ```

3. **Configure capabilities**
   - Select your target → Signing & Capabilities
   - Add **HealthKit**
   - Add **WeatherKit** (requires Apple Developer membership)

4. **Add required permissions to Info.plist**
   ```xml
   <key>NSHealthShareUsageDescription</key>
   <string>Alto needs access to your health data to personalize your training plan.</string>
   
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>Alto uses your location to provide weather-based workout recommendations.</string>
   
   <key>NSCameraUsageDescription</key>
   <string>Alto uses your camera to analyze meal photos for nutrition tracking.</string>
   
   <key>NSMicrophoneUsageDescription</key>
   <string>Alto uses your microphone for voice workout logging.</string>
   
   <key>NSSpeechRecognitionUsageDescription</key>
   <string>Alto uses speech recognition to log workouts by voice.</string>
   ```

5. **Build and Run** (⌘R)

### First-Time Setup (In-App)

1. **Complete Onboarding**
   - Enter personal details (name, age, height, weight)
   - Select health conditions and workout preferences
   - Set your fitness goal and target date

2. **Configure Gemini API Key**
   - Open **Profile** → Tap **AI Features** card
   - Visit [Google AI Studio](https://aistudio.google.com/apikey)
   - Create a free API key
   - Paste it in the app
   - Select your preferred model (Gemini 1.5 Flash recommended)

3. **Grant Permissions**
   - Allow HealthKit access for sleep and activity tracking
   - Allow location access for weather-based recommendations
   - Allow notifications for daily wellness reminders

---

## 🏗️ Architecture

### Tech Stack

| Component | Technology |
|-----------|-----------|
| **UI Framework** | SwiftUI |
| **AI Provider** | Google Gemini 1.5/2.0 |
| **Health Data** | Apple HealthKit |
| **Weather** | Apple WeatherKit |
| **Speech** | Apple Speech Framework |
| **Storage** | UserDefaults + Supabase (optional) |
| **Design System** | Custom AltoTheme |

### Project Structure

```
Alto/
├── AltoApp/
│   ├── AltoApp.swift                 # App entry point
│   ├── RootView.swift                # Onboarding/Main router
│   │
│   ├── Models/
│   │   ├── ProfileModels.swift       # User profile data
│   │   ├── NutritionModels.swift     # Meal tracking
│   │   ├── ActivityModels.swift      # Workout sessions
│   │   └── OrchestratorModels.swift  # AI planning context
│   │
│   ├── Services/
│   │   ├── UserSettings.swift        # 🆕 API key & preferences management
│   │   ├── ClaudeOrchestrationService.swift  # Gemini AI planning
│   │   ├── MacroVisionService.swift  # 🆕 Gemini Vision meal analysis
│   │   ├── OrchestratorAgent.swift   # Rule-based fallback
│   │   ├── HealthKitService.swift    # HealthKit integration
│   │   ├── WeatherService.swift      # WeatherKit integration
│   │   ├── VoiceWorkoutParser.swift  # Voice log parsing
│   │   └── UserStore.swift           # User state management
│   │
│   ├── ViewModels/
│   │   ├── DashboardViewModel.swift  # Home screen logic
│   │   ├── OnboardingViewModel.swift # Onboarding flow
│   │   ├── NutritionViewModel.swift  # Meal tracking
│   │   └── GoalProgressViewModel.swift # Goal timeline
│   │
│   └── Views/
│       ├── Home/
│       │   ├── HomeView.swift        # Main dashboard
│       │   └── SentinelPopupView.swift # Daily check-in
│       ├── Nutrition/
│       │   └── NutritionView.swift   # Meal logging
│       ├── Goals/
│       │   └── GoalProgressView.swift # Timeline view
│       ├── Profile/
│       │   ├── ProfileView.swift     # User profile
│       │   └── SettingsView.swift    # 🆕 API key configuration
│       ├── Onboarding/
│       │   └── OnboardingContainerView.swift
│       └── Components/
│           └── AltoTheme.swift       # Design system
```

---

## 🧠 How It Works

### 1. Daily Wellness Check-In

Every morning, Alto shows a **Sentinel Popup** with 3 quick questions:

```swift
"How do your muscles feel?" (1-5)
"How is your mental life load today?" (1-5)
"What is your motivation level?" (1-5)
```

These are converted into a **readiness score** (0-100):

```
Readiness = 100 - penalties
- Soreness < 3: -30
- Stress < 3: -20
- Motivation < 3: -20
- Luteal phase: -10
```

### 2. AI Plan Generation

Alto sends this context to Gemini:

```json
{
  "readinessScore": 72,
  "sleepHours": 7.2,
  "cyclePhase": "follicular",
  "weatherImpact": "clear",
  "goalPhase": "build",
  "healthConditions": ["knee pain"],
  "workoutPreferences": ["running", "yoga"]
}
```

Gemini responds with a structured plan:

```json
{
  "headline": "Power Through Build Phase",
  "activities": [
    {
      "name": "Tempo Run",
      "emoji": "🏃",
      "durationMinutes": 45,
      "targetCalories": 420,
      "details": "10 min warm-up → 3×8 min tempo → cool-down",
      "location": "outdoor",
      "rpe": 7
    }
  ],
  "shouldPivot": false,
  "coachNote": "Your follicular phase energy is perfect for this tempo session. Stay consistent!"
}
```

### 3. Intelligent Pivoting

Alto has **hard safety rules** that override AI suggestions:

| Condition | Action |
|-----------|--------|
| Readiness < 40 | → Rest & Walk (25 min, RPE 2) |
| Rain > 60% + Outdoor | → Indoor Circuit |
| Luteal Phase | → Cap RPE at 7, reduce duration by 10% |
| Menstrual Phase | → Gentle movement priority |

### 4. Effort Gap Analysis

After workouts, Alto compares:

```
Effort Ratio = Actual Calories Burned / Planned Calories

if ratio < 0.5:
  → "Compassionate re-engagement" notification

if targetRPE <= 4 but reportedRPE >= 9:
  → Insert mandatory recovery day
```

---

## 🔧 Configuration

### Gemini Models

| Model | Speed | Quality | Free Tier Limit |
|-------|-------|---------|-----------------|
| **Gemini 1.5 Flash** ⚡ | Fastest | Good | 15 RPM |
| **Gemini 2.0 Flash** ✨ | Very Fast | Better | 15 RPM |
| **Gemini 1.5 Pro** 🧠 | Slower | Best | 2 RPM |

**Recommendation:** Use **Gemini 1.5 Flash** for daily use. Switch to **Pro** if you want higher quality analysis and don't mind slower responses.

### API Costs (as of April 2025)

| Usage | Cost |
|-------|------|
| **Free Tier** | 15 requests/minute, 1,500 requests/day |
| **Paid Tier** | $0.35 per 1M tokens (~3,000 workout plans) |

### Settings Location

All user settings are stored in **UserDefaults** and managed by the `UserSettings` class:

```swift
// Access settings anywhere:
@EnvironmentObject var settings: UserSettings

// Check API key status:
if settings.isAPIKeyConfigured {
    // AI features enabled
}

// Get selected model:
let model = settings.selectedGeminiModel // .flash15, .flash20, .pro15
```

---

## 📱 Features Deep Dive

### Voice Workout Logging

Speak naturally:
- ✅ "I did 30 mins of yoga"
- ✅ "Just finished a 45 minute run"
- ✅ "Completed 1 hour of strength training"

Parser extracts:
```swift
struct VoiceWorkoutEntry {
    let workoutType: String  // "yoga"
    let durationMinutes: Int // 30
}
```

### Meal Photo Analysis

1. Take photo of meal
2. Gemini Vision analyzes:
   ```json
   {
     "calories": 520,
     "proteinGrams": 28.5,
     "carbsGrams": 45.2,
     "fatGrams": 22.1
   }
   ```
3. Review and confirm
4. Macros added to daily total

### Goal Timeline Generator

Creates a 4-phase plan:

```
Base Phase (40%) → Build Phase (30%) → Peak Phase (20%) → Taper Phase (10%)
```

Each phase has:
- Milestone dates
- Intensity targets
- Volume progression
- Recovery weeks

---

## 🧪 Testing

### Run Unit Tests

```bash
# In Xcode: Cmd+U

# Or via command line:
xcodebuild test -scheme Alto -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Test Coverage

| Module | Tests | Coverage |
|--------|-------|----------|
| **SentinelOrchestrator** | 18 tests | Readiness scoring, pivoting, effort gap |
| **GoalTimeline** | 5 tests | 4-phase generation, ordering |
| **VoiceWorkoutParser** | 6 tests | Natural language parsing |
| **NutritionViewModel** | 10 tests | Meal CRUD, calorie tracking |

### Manual Testing Checklist

- [ ] Onboarding flow completes successfully
- [ ] API key can be added/removed in Settings
- [ ] Daily Sentinel popup appears on first launch
- [ ] AI plan generates after entering API key
- [ ] Voice logging parses "30 mins of yoga"
- [ ] Meal photo analysis returns macros
- [ ] HealthKit permission request shows
- [ ] Weather fetches location and precipitation

---

## 🐛 Troubleshooting

### "API key required" error

**Solution:** Go to **Profile → AI Features → Enter API Key**

### "Rate limit exceeded (429)"

**Solutions:**
1. Wait 60 seconds (rate limit resets)
2. Switch to Gemini 1.5 Pro (2 RPM limit)
3. Check your quota at [Google AI Studio](https://aistudio.google.com)

### WeatherKit not working

**Requirements:**
- Apple Developer membership
- WeatherKit capability enabled
- Location permission granted

### HealthKit not connecting

**Check:**
1. HealthKit capability added to target
2. Usage description in Info.plist
3. Permissions granted in Settings → Health

### Voice logging not parsing

**Common phrases:**
- "I did [duration] of [activity]"
- "Just finished a [duration] [activity]"
- "Completed [duration] [activity]"

**Supported activities:** yoga, running, cycling, swimming, strength, HIIT, walking

---

## 🎨 Design System (AltoTheme)

### Colors

```swift
AltoTheme.primary       // #6B4CE6 (Purple)
AltoTheme.background    // #0A0A0B (Dark)
AltoTheme.card          // #1A1A1C (Card background)
AltoTheme.surface       // #242426 (Input fields)
AltoTheme.textPrimary   // #FFFFFF (White)
AltoTheme.textSecondary // #8E8E93 (Gray)
AltoTheme.border        // #2C2C2E (Dividers)
AltoTheme.green         // #34C759 (Success)
AltoTheme.red           // #FF3B30 (Error)
```

### Typography

```swift
// Headlines
.font(.system(size: 24, weight: .heavy))

// Body
.font(.system(size: 14))

// Captions
.font(.system(size: 12))

// Section labels
.font(.system(size: 10, weight: .bold))
.tracking(2)
.textCase(.uppercase)
```

---

## 🔐 Privacy & Security

### Data Storage

| Data | Storage | Uploaded? |
|------|---------|-----------|
| **API Key** | UserDefaults (local) | ❌ No |
| **HealthKit Data** | Apple Health (local) | ❌ No |
| **Workout History** | Local only | ❌ No |
| **Meal Photos** | Sent to Gemini → Deleted | ⚠️ Temporarily |
| **User Profile** | Local + Supabase (optional) | ⚠️ Optional |

### What Gets Sent to Gemini?

1. **Daily Planning:** Readiness scores, sleep hours, weather, cycle phase
2. **Meal Analysis:** Photo only (no personal data)

**Never sent:** Name, location, raw HealthKit data, email

### API Key Security

- Stored locally in UserDefaults
- Never logged or transmitted to servers
- Can be cleared anytime in Settings
- Not included in backups (use keychain for production)

**⚠️ Production Recommendation:** Migrate API key storage from UserDefaults to iOS Keychain for enhanced security.

---

## 🚢 Deployment Checklist

Before releasing to TestFlight/App Store:

- [ ] Update `CFBundleShortVersionString` in Info.plist
- [ ] Add App Store Connect screenshots
- [ ] Write privacy policy (required for HealthKit)
- [ ] Test on multiple device sizes (iPhone SE, Pro Max)
- [ ] Verify all permissions work on fresh install
- [ ] Test without API key (should show setup prompt)
- [ ] Remove debug print statements
- [ ] Enable bitcode (if applicable)
- [ ] Test offline mode (graceful degradation)

---

## 📖 API Documentation

### ClaudeOrchestrationService

```swift
let service = ClaudeOrchestrationService(
    apiKey: "YOUR_API_KEY",
    model: .pro15
)

let plan = try await service.buildPlanAsync(
    context: OrchestratorContext(...),
    userEnteredActivities: [...]
)
```

### GeminiVisionMacroService

```swift
let service = GeminiVisionMacroService(
    apiKey: "YOUR_API_KEY",
    model: .flash15
)

let macros = try await service.analyzeMeal(imageData: jpegData)
// Returns: MacroEstimate(calories, proteinGrams, carbsGrams, fatGrams)
```

### UserSettings

```swift
let settings = UserSettings()

// Configure
settings.geminiAPIKey = "AIza..."
settings.selectedGeminiModel = .flash15
settings.notificationsEnabled = true

// Check status
if settings.isAPIKeyConfigured {
    // Proceed
}
```

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Use SwiftLint for consistency
- Follow Apple's Swift API Design Guidelines
- Add inline documentation for public APIs
- Write unit tests for business logic

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Google Gemini** for AI orchestration
- **Apple HealthKit** for health data integration
- **Apple WeatherKit** for weather-based recommendations
- **SwiftUI** for declarative UI framework

---

## 📞 Support

- **Issues:** [GitHub Issues](https://github.com/yourusername/Fitness-App/issues)
- **Discussions:** [GitHub Discussions](https://github.com/yourusername/Fitness-App/discussions)
- **Email:** support@alto-fitness.app

---

<div align="center">

**Built with ❤️ using SwiftUI and Google Gemini AI**

[🌟 Star this repo](https://github.com/yourusername/Fitness-App) • [🐛 Report a bug](https://github.com/yourusername/Fitness-App/issues) • [💡 Request a feature](https://github.com/yourusername/Fitness-App/issues)

</div>
