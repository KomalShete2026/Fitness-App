# Alto Architecture Documentation

## System Overview

Alto follows a **Model-View-ViewModel (MVVM)** architecture with SwiftUI, combining AI-driven orchestration with rule-based safety systems.

```
┌─────────────────────────────────────────────────────────────┐
│                         User Interface                       │
│                          (SwiftUI)                           │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                       View Models                            │
│  (DashboardViewModel, NutritionViewModel, etc.)             │
└──────────┬────────────────────────┬─────────────────────────┘
           │                        │
           ▼                        ▼
┌──────────────────┐    ┌──────────────────────────────────┐
│   AI Services    │    │     Rule-Based Services          │
│  (Gemini API)    │    │  (SentinelOrchestrator)         │
└────────┬─────────┘    └──────────┬───────────────────────┘
         │                         │
         ▼                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   Data Layer                                 │
│  (HealthKit, WeatherKit, UserDefaults, Supabase)            │
└─────────────────────────────────────────────────────────────┘
```

---

## Core Components

### 1. Services Layer

#### UserSettings
**Purpose:** Centralized configuration and preference management

**Responsibilities:**
- Store/retrieve Gemini API key
- Manage AI model selection
- Handle notification preferences
- Persist user settings to UserDefaults

**Key Methods:**
```swift
class UserSettings: ObservableObject {
    @Published var geminiAPIKey: String
    @Published var selectedGeminiModel: GeminiModel
    @Published var notificationsEnabled: Bool
    
    var isAPIKeyConfigured: Bool { /* ... */ }
    func clearAllSettings()
}
```

**Storage:**
- UserDefaults for all settings
- Auto-saves on property change via `didSet`

---

#### ClaudeOrchestrationService (Gemini AI)
**Purpose:** Generate personalized daily workout plans

**Input:**
```swift
struct OrchestratorContext {
    let mood: DailyMood
    let sleepHours: Double?
    let rainProbability: Double?
    let temperatureCelsius: Double?
    let activityPreset: String
    let goalName: String
    let goalPhase: GoalPhase
    let readiness: DailyReadiness?
    let weatherImpact: WeatherImpact
    let healthConditions: [String]
    let workoutPreferences: [String]
    let calorieTarget: Int
}
```

**Output:**
```swift
struct OrchestratedPlan {
    let headline: String
    let why: String
    let workoutName: String
    let workoutDurationMinutes: Int
    let actions: [OrchestratedAction]
    let shouldPivot: Bool
    let plannedActivities: [PlannedActivity]
    let calorieTarget: Int
    let readinessSummary: String
    let coachNote: String
    let pivotReason: String?
}
```

**Prompt Engineering:**
```
System Instructions:
1. If readiness < 40 → rest/recovery day
2. If rain > 60% + outdoor → indoor swap
3. If luteal phase → cap RPE at 7, reduce duration 10%
4. Respect health conditions
5. Honor user-entered activities unless safety rules override
6. Add short add-on if planned calories < target
7. Specific, motivating descriptions
8. Explain WHY in 1-2 sentences
9. Personal, warm coach note

Response: JSON only, no markdown
```

**Error Handling:**
```swift
enum ClaudeOrchestrationError: LocalizedError {
    case missingAPIKey
    case networkError(Error)
    case invalidResponse(String)
    case jsonParseError(String)
}
```

---

#### GeminiVisionMacroService
**Purpose:** Analyze meal photos for nutritional content

**Flow:**
```
Photo → JPEG → Base64 → Gemini Vision API → JSON → MacroEstimate
```

**Prompt:**
```
Analyze this food photo and provide nutritional information in JSON format.

Respond with ONLY a valid JSON object (no markdown):
{
    "calories": <integer>,
    "proteinGrams": <number>,
    "carbsGrams": <number>,
    "fatGrams": <number>
}

Guidelines:
- Be realistic with portion sizes
- Round calories to nearest 10
- Round macros to 1 decimal place
- If uncertain, provide conservative estimates
```

**Configuration:**
```swift
"generationConfig": [
    "temperature": 0.4,        // Lower = more conservative
    "maxOutputTokens": 256,    // Short response
    "responseMimeType": "application/json"  // Forces JSON
]
```

---

#### SentinelOrchestrator (Rule-Based Fallback)
**Purpose:** Provide deterministic workout plans without API

**Readiness Scoring Algorithm:**
```swift
score = 100

if soreness < 3:
    score -= 30
    
if stress < 3:
    score -= 20
    
if mood < 3:
    score -= 20
elif mood == 3:
    score -= 10
    
if cyclePhase == .luteal:
    score -= 10
    
return max(0, min(100, score))
```

**Pivoting Rules:**
```swift
// Priority 1: Safety override
if readinessScore < 40:
    return RestAndWalk(25 min, RPE 2)

// Priority 2: Weather adaptation
if weatherImpact == .rain && location == .outdoor:
    task.name = "Indoor Circuit"
    task.location = .indoor
    task.targetRPE = min(targetRPE, 6)

// Priority 3: Cycle adaptation
if cyclePhase == .luteal:
    task.targetRPE = min(targetRPE, 7)
    task.duration = duration * 0.9
```

**Effort Gap Analysis:**
```swift
ratio = actualCalories / plannedCalories

if ratio < 0.5:
    trigger compassionate re-engagement notification
    
if targetRPE <= 4 && reportedRPE >= 9:
    insert mandatory recovery day
```

---

### 2. View Models

#### DashboardViewModel
**Purpose:** Orchestrate home screen logic

**Dependencies:**
- HealthKitService
- WeatherService
- VoiceWorkoutParser
- SpeechTranscriptionService
- SentinelOrchestrator
- NotificationService
- UserSettings

**State:**
```swift
@Published var readinessScore: Int?
@Published var orchestratedPlan: OrchestratedPlan?
@Published var todayPlan: TodayPlan
@Published var voiceTranscript: String
@Published var selectedMealImage: UIImage?
@Published var pendingMacroEstimate: MacroEstimate?
```

**Key Flows:**

**1. App Launch:**
```
onAppear()
├── Check if Sentinel needed (daily)
├── connectHealthKit()
│   ├── Request permissions
│   ├── Fetch sleep hours
│   └── Fetch active energy
├── refreshWeather()
│   ├── Request location
│   └── Fetch weather data
└── generateTodayPlanWithClaude()
    ├── Check API key configured
    ├── Build OrchestratorContext
    ├── Call Gemini API
    └── Update todayPlan
```

**2. Daily Sentinel Submission:**
```
submitDailyWellness()
├── Build DailyReadiness from scores
├── Calculate readiness score
├── Refresh orchestrated plan
└── generateTodayPlanWithClaude()
```

**3. Voice Workout Logging:**
```
toggleDictation()
├── Request speech permission
├── Start transcription
└── Update voiceTranscript

parseVoiceLog()
├── Parse transcript
├── Extract workout type & duration
├── Increment path progress
└── Clear transcript
```

**4. Meal Photo Analysis:**
```
analyzeSelectedMealImage()
├── Check API key configured
├── Create GeminiVisionMacroService
├── Convert image to JPEG
├── Call Gemini Vision API
└── Display pendingMacroEstimate

confirmMacros()
├── Add to macroTotals
└── Clear pending estimate
```

---

### 3. Data Models

#### ProfileModels
```swift
struct UserProfile {
    let name: String
    let age: Int
    let heightInches: Int
    let weightLb: Int
    let healthConditions: [String]
    let preferredWorkouts: [String]
    let activityPreset: String
}
```

#### OrchestratorModels
```swift
struct DailyReadiness {
    let soreness: Int        // 1-5
    let stress: Int          // 1-5
    let mood: Int            // 1-5
    let cyclePhase: CyclePhase
}

enum DailyMood {
    case readyToPush
    case balanced
    case lowEnergy
    case muscleFatigue
    case mentallyDrained
    case needRecovery
}

enum GoalPhase {
    case base    // 40% of timeline
    case build   // 30% of timeline
    case peak    // 20% of timeline
    case taper   // 10% of timeline
}

enum CyclePhase {
    case menstrual   // Days 1-5
    case follicular  // Days 6-13
    case ovulation   // Days 14-16
    case luteal      // Days 17-28
    case unknown
}
```

#### ActivityModels
```swift
struct PlannedActivity: Identifiable {
    let id: UUID
    let name: String
    let emoji: String
    let durationMinutes: Int
    let targetCalories: Double
    let details: String
    var status: ActivityStatus
    var actualCalories: Double?
}

enum ActivityStatus {
    case notStarted
    case inProgress
    case done
}

struct TodayPlan {
    var activities: [PlannedActivity]
    let calorieGoal: Double
    
    var progressFraction: Double
    var totalCaloriesBurned: Double
    var currentActivity: PlannedActivity?
}
```

#### NutritionModels
```swift
struct MacroEstimate: Codable {
    let calories: Int
    let proteinGrams: Double
    let carbsGrams: Double
    let fatGrams: Double
}

struct DailyMacroTotal {
    var calories: Int
    var proteinGrams: Double
    var carbsGrams: Double
    var fatGrams: Double
    
    mutating func add(_ estimate: MacroEstimate)
}
```

---

## Data Flow Diagrams

### Daily Plan Generation

```
User completes Sentinel check-in
         │
         ▼
Build DailyReadiness (soreness, stress, mood)
         │
         ▼
Calculate readiness score (SentinelOrchestrator)
         │
         ▼
Fetch HealthKit data (sleep, HRV)
         │
         ▼
Fetch WeatherKit data (temp, precipitation)
         │
         ▼
Build OrchestratorContext
         │
         ▼
[API Key configured?]
    │               │
    YES             NO
    │               │
    ▼               ▼
Gemini API    SentinelOrchestrator
    │               │
    ▼               ▼
OrchestratedPlan ←──┘
    │
    ▼
Update TodayPlan
    │
    ▼
Display in HomeView
```

### Meal Photo Analysis

```
User takes photo
         │
         ▼
Convert to JPEG (0.8 quality)
         │
         ▼
Base64 encode
         │
         ▼
Send to Gemini Vision API
    with prompt
         │
         ▼
Gemini analyzes image
         │
         ▼
Returns JSON:
{
  "calories": 520,
  "proteinGrams": 28.5,
  "carbsGrams": 45.2,
  "fatGrams": 22.1
}
         │
         ▼
Parse to MacroEstimate
         │
         ▼
Display pending estimate
         │
         ▼
[User confirms?]
    │       │
    YES     NO
    │       │
    ▼       ▼
Add to   Discard
totals
```

---

## State Management

### Global State (EnvironmentObject)

```swift
@main
struct AltoApp: App {
    @StateObject private var userStore = UserStore()
    @StateObject private var userSettings = UserSettings()
    @StateObject private var onboardingViewModel = OnboardingViewModel(...)
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(userStore)
                .environmentObject(userSettings)
                .environmentObject(onboardingViewModel)
        }
    }
}
```

**Access in any view:**
```swift
struct HomeView: View {
    @EnvironmentObject var userStore: UserStore
    @EnvironmentObject var userSettings: UserSettings
    
    // ...
}
```

### Local State (@State, @StateObject)

```swift
struct HomeView: View {
    @StateObject private var viewModel: DashboardViewModel
    @State private var showSentinelPopup = false
    
    // ...
}
```

---

## API Integration

### Gemini API Request Format

```json
{
  "systemInstruction": {
    "parts": [{"text": "You are Alto's AI fitness coach..."}]
  },
  "contents": [
    {
      "role": "user",
      "parts": [{"text": "USER PROFILE\nGoal: Marathon...\n\nTODAY'S SIGNALS\n..."}]
    }
  ],
  "generationConfig": {
    "temperature": 0.7,
    "maxOutputTokens": 1024,
    "responseMimeType": "application/json"
  }
}
```

**Response:**
```json
{
  "candidates": [
    {
      "content": {
        "parts": [
          {
            "text": "{\"headline\":\"Power Through...\",\"activities\":[...]}"
          }
        ]
      }
    }
  ]
}
```

---

## Error Handling Strategy

### Graceful Degradation

```
AI Plan Generation Error
         │
         ▼
[Error Type?]
    │
    ├─ Missing API Key
    │    └─> Show setup prompt in UI
    │
    ├─ Rate Limit (429)
    │    └─> Wait & retry OR fallback to rule-based
    │
    ├─ Network Error
    │    └─> Fallback to SentinelOrchestrator
    │
    └─ JSON Parse Error
         └─> Fallback to SentinelOrchestrator
```

### User-Facing Messages

```swift
// Good
"Rate limit exceeded. Please wait a moment and try again."

// Bad
"HTTP 429: Resource has been exhausted (e.g. check quota)."
```

---

## Performance Considerations

### API Call Optimization

1. **Batch requests:** Generate plan once per day, not per screen load
2. **Cache results:** Store today's plan in memory
3. **Lazy loading:** Only call API when needed
4. **Model selection:** Use Flash for speed, Pro for quality

### Image Compression

```swift
image.jpegData(compressionQuality: 0.7)
// Balance between quality and upload speed
```

### HealthKit Queries

```swift
// Don't query on every view appearance
func onAppear() {
    guard lastHealthKitFetch == nil 
       || Date().timeIntervalSince(lastHealthKitFetch!) > 3600 else { 
        return 
    }
    
    await connectHealthKit()
}
```

---

## Security Best Practices

### Current Implementation
- ✅ API key in UserDefaults (encrypted at rest by iOS)
- ✅ No hardcoded secrets
- ✅ HTTPS-only communication
- ✅ No logging of sensitive data

### Production Recommendations
- 🔐 Migrate API key to iOS Keychain
- 🔐 Add biometric lock for settings
- 🔐 Implement certificate pinning
- 🔐 Add API key rotation support

### Keychain Migration Example
```swift
import Security

class SecureStorage {
    static func saveAPIKey(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "gemini_api_key",
            kSecValueData as String: key.data(using: .utf8)!
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func loadAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "gemini_api_key",
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
}
```

---

## Testing Strategy

### Unit Tests

**SentinelOrchestratorTests:**
- Readiness score calculation
- Pivot logic (low readiness, weather, cycle)
- Effort gap evaluation
- Onboarding audit (injury risk)

**GoalTimelineTests:**
- 4-phase generation
- Chronological ordering
- No overlap between phases
- Full timeline coverage

**VoiceWorkoutParserTests:**
- Parse "30 mins of yoga"
- Parse "1 hour running"
- Handle edge cases
- Abbreviation support

**NutritionViewModelTests:**
- Add/edit/delete meals
- Calorie summation
- Water tracking
- Macro goal calculations

### Integration Tests

```swift
func testFullOnboardingToFirstPlan() async throws {
    // 1. Complete onboarding
    let onboarding = OnboardingViewModel(...)
    onboarding.userName = "Test User"
    // ... fill all fields
    try await onboarding.saveProfile()
    
    // 2. Complete Sentinel
    let dashboard = DashboardViewModel(...)
    dashboard.sorenessScore = 4
    dashboard.stressScore = 3
    dashboard.motivationScore = 5
    dashboard.submitDailyWellness()
    
    // 3. Generate plan
    await dashboard.generateTodayPlanWithClaude()
    
    // 4. Verify
    XCTAssertNotNil(dashboard.todayPlan)
    XCTAssertFalse(dashboard.todayPlan.activities.isEmpty)
}
```

### Manual Testing Scenarios

1. **Fresh install flow:**
   - Onboarding → API key setup → First Sentinel → First plan

2. **Edge cases:**
   - No internet → Should fallback to rule-based
   - Invalid API key → Should show error
   - Rate limit → Should display friendly message

3. **Cross-feature:**
   - Voice log → Plan updates calories
   - Meal photo → Macros add to totals
   - Low readiness → Plan pivots to rest

---

## Future Enhancements

### Planned Features
- [ ] Advanced analytics dashboard
- [ ] Workout history calendar
- [ ] Custom workout builder
- [ ] Social sharing
- [ ] Apple Watch companion app
- [ ] Siri shortcuts integration

### Technical Debt
- [ ] Migrate to Keychain for API key storage
- [ ] Add Combine/async pipeline for health data
- [ ] Implement proper logging framework
- [ ] Add Crashlytics/analytics
- [ ] Modularize into Swift Packages

---

## Deployment Pipeline

```
Developer
    │
    ▼
Git Push → main branch
    │
    ▼
GitHub Actions (optional)
    ├─ Run SwiftLint
    ├─ Run Unit Tests
    └─ Archive build
    │
    ▼
Xcode Cloud / Manual
    ├─ Build for TestFlight
    ├─ Upload to App Store Connect
    └─ Submit for review
    │
    ▼
App Store
```

---

## Monitoring & Analytics

### Key Metrics to Track

**User Engagement:**
- Daily active users (DAU)
- Sentinel completion rate
- AI plan generation success rate
- Voice log usage frequency
- Meal photo analysis usage

**Technical:**
- API response times (p50, p95, p99)
- API error rates by type
- HealthKit connection success rate
- App crash rate
- Battery usage

**Business:**
- User retention (D1, D7, D30)
- Onboarding completion rate
- API key configuration rate

### Recommended Tools
- **Firebase Analytics** for user behavior
- **Sentry** for crash reporting
- **Mixpanel** for funnel analysis
- **App Store Connect** for reviews & ratings

---

## Glossary

| Term | Definition |
|------|------------|
| **Sentinel** | Daily wellness check-in popup |
| **Readiness Score** | 0-100 metric of body's readiness to train |
| **Pivot** | Automatic workout adjustment based on readiness/weather |
| **RPE** | Rate of Perceived Exertion (1-10 scale) |
| **Orchestration** | AI-driven workout plan generation |
| **Effort Gap** | Difference between planned and actual workout output |
| **Macro** | Macronutrient (protein, carbs, fats) |
| **Base Phase** | Initial aerobic foundation building (40% of timeline) |
| **Build Phase** | Intensity increase period (30% of timeline) |
| **Peak Phase** | Maximum performance period (20% of timeline) |
| **Taper Phase** | Recovery before goal event (10% of timeline) |

---

**Last Updated:** April 2026  
**Version:** 1.0.0  
**Author:** Alto Development Team
