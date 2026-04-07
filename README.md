# Alto — AI-Powered Fitness Coach

> **Your AI-powered fitness coach that creates personalized workout and nutrition plans, learns from your progress, and adapts in real time so you always train smarter.**

<p align="center">
  <img src="docs/screenshots/home_dashboard.png" alt="Alto Dashboard" width="220"/>
  <img src="docs/screenshots/onboarding.png" alt="Alto Onboarding" width="220"/>
  <img src="docs/screenshots/goals.png" alt="Alto Goals" width="220"/>
  <img src="docs/screenshots/profile.png" alt="Alto Profile" width="220"/>
</p>

> 📸 *Add screenshots to `docs/screenshots/` to populate the preview above.*

---

## Table of Contents

- [Vision & Mission](#vision--mission)
- [The Problem](#the-problem)
- [Our Hypothesis](#our-hypothesis)
- [Use Cases](#use-cases)
- [Key Features](#key-features)
- [App Screens](#app-screens)
- [Agentic Architecture](#agentic-architecture)
- [Agents & Their Roles](#agents--their-roles)
- [Tech Stack](#tech-stack)
- [Data & Privacy](#data--privacy)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Running Tests](#running-tests)

---

## Vision & Mission

### Vision
A world where every person — regardless of budget, access, or experience — has a world-class fitness coach in their pocket that actually knows them.

### Mission
Build an AI-native fitness experience that removes the friction between intention and action. Alto listens, adapts, and shows up for users every single day — not just when they remember to open an app.

### Core Belief
**Fitness plans fail people. People don't fail fitness plans.**

Generic plans ignore how you slept, how stressed you are, where you are in your cycle, and what the weather looks like outside. Alto doesn't. It treats you like a person, not a profile.

---

## The Problem

| Problem | Current Reality | What Alto Does |
|---------|----------------|----------------|
| Generic plans | 1-size-fits-all programs | Personalized daily plans from your actual signals |
| No adaptation | Same plan whether you slept 4hrs or 8hrs | Readiness score adjusts every day |
| Nutrition guesswork | Manual calorie logging is tedious | Photo-based AI macro estimation in seconds |
| Weather-blind coaching | Outdoor run scheduled during a thunderstorm | Automatically pivots to indoor alternatives |
| Cycle-ignorant training | Same intensity regardless of hormonal phase | Training intensity adapts to menstrual cycle phases |
| No recovery intelligence | Rest days are arbitrary | Evidence-based recovery triggers based on effort gaps |

---

## Our Hypothesis

> **If we give an AI coach access to the right real-time signals — sleep, stress, mood, weather, cycle phase, and calorie data — it will generate better daily training decisions than any static 12-week program.**

### Supporting Bets
1. **Readiness > Rigidity** — Users who train based on daily readiness will sustain habits longer than those on fixed schedules.
2. **Friction kills compliance** — Removing manual logging (via voice and photo) increases daily check-in rates by 3–5×.
3. **Personalization compounds** — Each data signal multiplies plan quality; the more Alto knows, the better it gets.
4. **Cycle-aware training reduces injury** — Adapting intensity to hormonal phases reduces overtraining and improves long-term adherence for female athletes.

---

## Use Cases

### 1. The Busy Professional
**Who:** Works 9–6, inconsistent sleep, high stress, wants to stay in shape.
**How Alto helps:** Detects low readiness from sleep and stress signals. Swaps a planned 10K run for a 25-min mobility session. Sends a compassionate nudge instead of a guilt trip.

### 2. The Marathon Trainer
**Who:** Training for a specific race, needs periodized phases (base → build → peak → taper).
**How Alto helps:** Builds a 4-phase goal timeline. Tracks weekly mileage increases and warns if the ramp rate exceeds 15% (injury risk). Adjusts taper week automatically.

### 3. The New Mom / Postpartum Athlete
**Who:** Returning to fitness after pregnancy, needs cycle-aware, low-impact options.
**How Alto helps:** Menstrual cycle phase detection. Caps RPE at 7 during luteal phase. Prioritizes recovery and mobility when readiness is low.

### 4. The Calorie Tracker
**Who:** Focused on body composition, wants accurate macro tracking without tedious logging.
**How Alto helps:** Point camera at meal → AI returns calories, protein, carbs, fat in seconds. Cross-references with daily calorie target and suggests add-on exercises if needed.

### 5. The Weather-Dependent Outdoor Runner
**Who:** Loves running outside but lives somewhere with unpredictable weather.
**How Alto helps:** Checks rain probability via WeatherKit before generating the plan. If rain > 60%, automatically pivots outdoor run to an indoor treadmill or circuit alternative.

### 6. The Data-Driven Athlete
**Who:** Wears an Apple Watch, syncs HealthKit daily, wants coaching based on actual biometrics.
**How Alto helps:** Pulls resting heart rate, HRV, sleep stages, and step count from HealthKit. Uses this as primary readiness input alongside self-reported mood.

---

## Key Features

| Feature | Description |
|---------|-------------|
| 🧠 **AI Orchestration** | Gemini-powered daily plan generation from 10+ real-time signals |
| 📸 **Macro Vision** | Photo-based meal analysis — point, shoot, get macros |
| 🔄 **Smart Pivoting** | Automatically adjusts plans based on weather, readiness, and cycle phase |
| 🗣️ **Voice Logging** | Log workouts by speaking — parsed by on-device NLP |
| 🌤️ **Weather Awareness** | WeatherKit integration — plans adapt to forecast |
| ❤️ **HealthKit Sync** | Sleep, heart rate, steps, and cycle data from Apple Health |
| 🎯 **Goal Timelines** | 4-phase periodization: Base → Build → Peak → Taper |
| 🔒 **Privacy First** | All data stays on-device. No analytics. No tracking. |
| 📴 **Offline Fallback** | Rule-based orchestration works without an internet connection |

---

## App Screens

### Onboarding Journey
A 4-step onboarding flow that builds your complete fitness profile. Animated, mobile-first, with smooth step transitions.

| Step | Screen | Purpose |
|------|--------|---------|
| Welcome | Intro with animated logo | Brand impression + CTA |
| Step 1 | Identity | Name, gender, age, height, weight |
| Step 2 | Health Info | Conditions (asthma, joint issues, heart, diabetes) |
| Step 3 | Activity Rhythm | Workout frequency, preferred workout types |
| Step 4 *(female)* | Cycle Details | Period duration, cycle length, last period date |
| Finish | Success screen | Personalized completion with name + stats |

> *HTML prototype:* [`mockups_html/onboarding_journey_stitched.html`](Alto/mockups_html/onboarding_journey_stitched.html)

---

### Home Dashboard
The daily command center. Generated fresh every morning by the AI orchestrator.

**Cards on screen:**
- **Sentinel alert** — Today's readiness summary and any pivots applied
- **Today's workout** — AI-generated plan with workout name, duration, RPE, and activities
- **Nutrition ring** — Real-time calorie and macro progress
- **Weather tile** — Current conditions and forecast impact on today's plan
- **Recovery insight** — Effort gap analysis from yesterday's session
- **Coaching note** — A personalized message from Alto's AI persona

> *HTML prototype:* [`mockups_html/home_dashboard_updated.html`](Alto/mockups_html/home_dashboard_updated.html)

---

### Goals
Multi-goal tracking with 4-phase periodization timelines.

**Features:**
- Create goals with a name and target date
- Alto generates a Base → Build → Peak → Taper phase breakdown
- Each phase shows weekly focus, workout types, and milestones
- Progress tracked as percentage with visual timeline

> *HTML prototype:* [`mockups_html/goals_multi.html`](Alto/mockups_html/goals_multi.html)

---

### Profile
Your fitness identity and app settings hub.

**Sections:**
- Avatar, level badge, and streak tracker (daily dots)
- Quick stats: goal progress %, total active hours, calories burned
- Body stats: weight, height, BMI, age + activity rhythm
- Active goals with inline progress bars
- Health conditions chips
- Settings: units, HealthKit sync, notifications, AI personalization, privacy
- Sign out

> *HTML prototype:* [`mockups_html/profile.html`](Alto/mockups_html/profile.html)

---

## Agentic Architecture

Alto's intelligence is built on a multi-agent pipeline that runs every morning when the user opens the app.

```
┌─────────────────────────────────────────────────────────────────────┐
│                        ALTO AGENTIC PIPELINE                        │
│                                                                     │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────────┐  │
│  │  DATA        │    │  READINESS   │    │  ORCHESTRATOR        │  │
│  │  COLLECTION  │───▶│  SCORING     │───▶│  AGENT               │  │
│  │  AGENT       │    │  AGENT       │    │  (Gemini 1.5 Pro)    │  │
│  └──────────────┘    └──────────────┘    └──────────────────────┘  │
│         │                  │                        │               │
│         │                  ▼                        ▼               │
│         │           ┌──────────────┐    ┌──────────────────────┐  │
│         │           │  PIVOT       │    │  PLAN DELIVERY       │  │
│         │           │  ENGINE      │    │  + NOTIFICATION      │  │
│         │           └──────────────┘    │  AGENT               │  │
│         │                               └──────────────────────┘  │
│         ▼                                                           │
│  ┌─────────────────────────────────────────────────┐               │
│  │              SIGNAL SOURCES                      │               │
│  │  HealthKit │ WeatherKit │ Mood Check-in │ GPS   │               │
│  └─────────────────────────────────────────────────┘               │
└─────────────────────────────────────────────────────────────────────┘
```

### How It Works — Step by Step

```
1. USER OPENS APP
       │
       ▼
2. DATA COLLECTION
   ├── HealthKit: sleep hours, resting HR, steps, cycle phase
   ├── WeatherKit: rain probability, temperature, conditions
   ├── Location: indoor / outdoor context
   └── User Input: soreness (1–5), stress (1–5), mood (1–5)
       │
       ▼
3. READINESS SCORING
   ├── soreness score  × 0.40
   ├── stress score    × 0.30
   ├── mood score      × 0.30
   ├── luteal phase    − 10 pts
   └── → readiness_score (0–100)
       │
       ▼
4. PIVOT ENGINE CHECK
   ├── readiness < 40?    → REST & WALK override
   ├── rain > 60%?        → INDOOR alternative
   ├── sleep < 6.5hrs?    → REDUCE intensity
   └── luteal phase?      → CAP RPE at 7, –10% duration
       │
       ▼
5. ORCHESTRATOR (Gemini AI)
   ├── Receives: full context prompt (profile + signals + environment)
   ├── System rules: safety overrides, calorie targets, pivot flags
   ├── Generates: workout name, duration, activities, RPE, coach note
   └── Fallback: SentinelOrchestrator (rule-based, works offline)
       │
       ▼
6. EFFORT GAP EVALUATION (post-workout)
   ├── achieved_calories / target_calories < 0.50? → recovery trigger
   ├── high effort on easy day? → compassionate re-engagement
   └── → tomorrow's plan adjusted accordingly
       │
       ▼
7. PLAN DELIVERY
   ├── Dashboard updated with today's plan
   ├── Push notification with headline + coach note
   └── Onboarding audit: ramp rate > 15%? → recommend extension
```

---

## Agents & Their Roles

### 1. Orchestrator Agent — `ClaudeOrchestrationService.swift`
**Type:** AI Agent (Gemini 1.5 Pro / 2.0 Flash)
**Role:** The brain. Generates a complete daily training plan from all available signals.

**Inputs:**
- User profile (age, weight, height, gender, health conditions, workout preferences)
- Daily readiness score + individual signal breakdown
- Weather forecast (rain %, temperature, conditions)
- Cycle phase (follicular / ovulatory / luteal / menstrual)
- Calorie target for the day
- Current goal phase (Base / Build / Peak / Taper)

**Outputs:**
```json
{
  "headline": "Easy Recovery Run",
  "why": "You slept 6h and flagged moderate soreness — keeping it light today.",
  "workoutName": "30-min Easy Jog",
  "duration": 30,
  "actions": [
    { "title": "Warm-up", "details": "5 min dynamic stretching" },
    { "title": "Run", "details": "25 min at conversational pace (RPE 5)" }
  ],
  "shouldPivot": false,
  "calorieTarget": 420,
  "coachNote": "Recovery days are where the gains are made. Trust the process."
}
```

**Safety Rules (hard-coded in system prompt):**
- `readiness < 40` → Rest & Walk, no exceptions
- `rain > 60% AND outdoor activity` → swap to indoor
- `luteal phase` → cap RPE at 7, reduce duration by 10%
- `calorie target not met by plan` → suggest add-on activity

---

### 2. Sentinel Orchestrator — `OrchestratorAgent.swift`
**Type:** Rule-based Agent (offline fallback)
**Role:** Mirrors the AI orchestrator's behaviour when no API key is configured or there is no internet connection.

**Key Functions:**

| Function | Description |
|----------|-------------|
| `readinessScore()` | Weighted scoring: soreness (40%) + stress (30%) + mood (30%) − luteal adjustment |
| `pivotTaskIfNeeded()` | Applies safety rules deterministically |
| `auditOnboarding()` | Checks if weekly training increase > 15% — flags injury risk |
| `evaluateEffortGap()` | Post-workout analysis — triggers compassion or recovery messages |
| `buildPlan()` | Full orchestration pipeline without AI |

---

### 3. Pivot Engine — `PivotEngine.swift`
**Type:** Decision Agent
**Role:** Binary pivot/no-pivot decisions based on environmental signals. Runs before the orchestrator to apply hard overrides.

**Decision Logic:**

```
evaluate(sleepHours, rainProbability):
  if sleepHours < 6.5  → PivotDecision.pivot(reason: "Low sleep detected")
  if rainProbability > 0.50 → PivotDecision.pivot(reason: "Rain forecast")
  else → PivotDecision.noPivot

nextHighReadinessDate(projections):
  → Scans upcoming DailyProjection array
  → Returns first date where readiness is HIGH
  → Used to schedule make-up sessions
```

---

### 4. Macro Vision Agent — `MacroVisionService.swift`
**Type:** Vision AI Agent (Gemini Vision)
**Role:** Analyses meal photos and returns macro estimates in under 2 seconds.

**Flow:**
```
User taps camera → photo captured
      ↓
Image base64-encoded → sent to Gemini Vision API
      ↓
Gemini analyses: food items, portion sizes, preparation method
      ↓
Returns JSON: { calories, proteinGrams, carbsGrams, fatGrams }
      ↓
Displayed in Nutrition card + added to daily total
```

**Config:** Temperature 0.4 (conservative estimates), max 256 tokens, forced JSON output via `responseMimeType: "application/json"`.

---

### 5. Voice Workout Parser — `VoiceWorkoutParser.swift`
**Type:** NLP Agent (on-device)
**Role:** Converts spoken workout descriptions into structured data using regex-based NLP.

**Examples:**
- *"I ran 5 miles in 45 minutes"* → `{ type: run, distance: 5, unit: miles, duration: 45 }`
- *"Did 3 sets of 12 bench press at 135 pounds"* → `{ type: strength, sets: 3, reps: 12, exercise: bench press, weight: 135 }`

---

### 6. Goal Timeline Generator — `GoalTimelineGenerator.swift`
**Type:** Planning Agent
**Role:** Takes a goal name + target date and generates a 4-phase periodized training timeline.

**Phase Distribution:**
```
Base Phase    → 25% of total time  (aerobic foundation, low intensity)
Build Phase   → 40% of total time  (volume + intensity increase)
Peak Phase    → 25% of total time  (race-specific workouts, max load)
Taper Phase   → 10% of total time  (reduce volume, maintain intensity)
```

**Safety Audit:** If weekly training increase > 15%, flags injury risk and recommends extending the timeline.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Language** | Swift 5.9 |
| **UI Framework** | SwiftUI |
| **Architecture** | MVVM + Service Locator |
| **AI / LLM** | Google Gemini 1.5 Flash · 2.0 Flash · 1.5 Pro |
| **Database** | Supabase (PostgreSQL) |
| **Health Data** | Apple HealthKit |
| **Weather** | Apple WeatherKit |
| **Location** | Core Location |
| **Voice** | AVAudioEngine + Speech Recognition |
| **Notifications** | UNUserNotificationCenter |
| **Networking** | URLSession (no third-party SDK) |
| **Testing** | XCTest (39 unit tests) |
| **Minimum iOS** | iOS 17.0+ |
| **Platform** | iPhone (portrait) |

---

## Data & Privacy

Alto is built privacy-first by design.

| Data | Where it lives | Who can see it |
|------|---------------|----------------|
| Health data (HealthKit) | On-device only | You only |
| Onboarding profile | Supabase (optional) | You only (RLS enforced) |
| Gemini API key | iOS UserDefaults (encrypted at rest) | You only |
| Workout logs | On-device only | You only |
| Meal photos | Sent to Gemini for analysis, not stored | You only |
| Location | On-device only, used for weather | You only |

- **No analytics**
- **No third-party tracking**
- **No ads**
- **No data sold**
- All AI calls go directly from your device to Gemini — Alto never sees your data.

---

## Project Structure

```
Fitness-App/
└── Alto/
    ├── AltoApp/
    │   ├── AltoApp.swift               # App entry point
    │   ├── RootView.swift              # Onboarding router
    │   ├── Models/                     # Data structures
    │   │   ├── ActivityModels.swift
    │   │   ├── InputModels.swift
    │   │   ├── NutritionModels.swift
    │   │   ├── OrchestratorModels.swift
    │   │   ├── PivotModels.swift
    │   │   ├── ProfileModels.swift
    │   │   └── ReadinessModels.swift
    │   ├── Services/                   # Business logic & AI agents
    │   │   ├── ClaudeOrchestrationService.swift   # Gemini AI orchestrator
    │   │   ├── OrchestratorAgent.swift            # Rule-based fallback
    │   │   ├── PivotEngine.swift                  # Pivot decision logic
    │   │   ├── MacroVisionService.swift           # Meal photo AI
    │   │   ├── VoiceWorkoutParser.swift           # Voice NLP
    │   │   ├── HealthKitService.swift             # Apple HealthKit
    │   │   ├── WeatherService.swift               # Apple WeatherKit
    │   │   ├── LocationService.swift              # Core Location
    │   │   ├── SpeechTranscriptionService.swift   # Speech Recognition
    │   │   ├── NotificationService.swift          # Push notifications
    │   │   ├── ProfileRepository.swift            # Supabase interface
    │   │   ├── SupabaseProfileRepository.swift    # Supabase HTTP impl
    │   │   ├── UserSettings.swift                 # API key management
    │   │   └── UserStore.swift                    # Local state
    │   ├── ViewModels/
    │   │   ├── DashboardViewModel.swift
    │   │   ├── OnboardingViewModel.swift
    │   │   ├── NutritionViewModel.swift
    │   │   └── GoalProgressViewModel.swift
    │   ├── Views/
    │   │   ├── Home/
    │   │   ├── Nutrition/
    │   │   ├── Goals/
    │   │   ├── Onboarding/
    │   │   ├── Profile/
    │   │   └── Components/
    │   └── Utils/
    │       ├── GoalTimelineGenerator.swift
    │       └── HeightConverter.swift
    ├── AltoTests/                      # 39 unit tests
    │   ├── SentinelOrchestratorTests.swift  (18 tests)
    │   ├── GoalTimelineTests.swift           (5 tests)
    │   ├── VoiceWorkoutParserTests.swift     (6 tests)
    │   └── NutritionViewModelTests.swift    (10 tests)
    ├── Supabase/
    │   ├── schema.sql
    │   └── migrations/
    └── mockups_html/                   # UI prototypes
        ├── home_dashboard_updated.html
        ├── onboarding_journey_stitched.html
        ├── goals_multi.html
        └── profile.html
```

---

## Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 17.0+ device or simulator
- Apple Developer account (required for WeatherKit)
- Google Gemini API key — [get one free](https://aistudio.google.com/app/apikey)

### Setup

```bash
# 1. Clone the repo
git clone https://github.com/KomalShete2026/Fitness-App.git
cd Fitness-App

# 2. Open in Xcode
open Alto/Alto.xcodeproj
```

**Xcode Capabilities to enable:**
- HealthKit
- WeatherKit
- Background Modes → Background fetch

**Info.plist permissions required:**
```xml
NSHealthShareUsageDescription
NSHealthUpdateUsageDescription
NSLocationWhenInUseUsageDescription
NSCameraUsageDescription
NSMicrophoneUsageDescription
NSSpeechRecognitionUsageDescription
```

### First Run
1. Build and run on device (`⌘R`)
2. Complete the onboarding flow
3. Go to **Profile → Settings** and enter your Gemini API key
4. Return to Dashboard — Alto will generate your first AI-powered plan

> **No API key?** Alto still works using the rule-based SentinelOrchestrator fallback — all features except AI-generated plans remain available.

---

## Running Tests

```bash
# Run all tests in Xcode
⌘U

# Or via command line
xcodebuild test \
  -scheme Alto \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

**Test Coverage:**

| Suite | Tests | Covers |
|-------|-------|--------|
| `SentinelOrchestratorTests` | 18 | Readiness scoring, pivot logic, effort gap, onboarding audit |
| `GoalTimelineTests` | 5 | Phase distribution, taper calculation, ramp rate audit |
| `VoiceWorkoutParserTests` | 6 | Running, strength, cycling, swimming parsing |
| `NutritionViewModelTests` | 10 | CRUD, calorie aggregation, macro totals |

---

## Roadmap

- [ ] Apple Watch companion app (readiness from wrist)
- [ ] Social challenges and streak sharing
- [ ] Sleep stage integration (deep / REM / light)
- [ ] Nutrition database search (barcode scanning)
- [ ] Android version
- [ ] Coach persona customization (tone, strictness)
- [ ] Integration with Garmin / Whoop / Oura

---

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you'd like to change.

---

## License

MIT © 2026 Komal Shete

---

<p align="center">
  Built with ❤️ using Swift, SwiftUI, and Google Gemini
  <br/>
  <em>Alto — Your AI-powered fitness coach that creates personalized workout and nutrition plans, learns from your progress, and adapts in real time so you always train smarter.</em>
</p>
