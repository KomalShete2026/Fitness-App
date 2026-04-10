# Alto — AI Fitness Coach

> **Your AI-powered fitness coach that creates personalized workout and nutrition plans, learns from your progress, and adapts in real time so you always train smarter.**

![Gemini AI](https://img.shields.io/badge/Gemini_AI-orange?style=flat-square) ![iOS 17+](https://img.shields.io/badge/iOS_17%2B-green?style=flat-square) ![Privacy First](https://img.shields.io/badge/Privacy_First-blue?style=flat-square) ![On-Device](https://img.shields.io/badge/On--Device-orange?style=flat-square) ![Agentic](https://img.shields.io/badge/Agentic-green?style=flat-square) ![HealthKit](https://img.shields.io/badge/HealthKit-blue?style=flat-square)

**Product Requirements Document · April 2026 · v1.0**

---

## Table of Contents

1. [Vision & Mission](#1-vision--mission)
2. [The Problem](#2-the-problem)
3. [Our Hypothesis](#3-our-hypothesis)
4. [Use Cases](#4-use-cases)
5. [Key Features](#5-key-features)
6. [App Screens](#6-app-screens)
7. [Agentic Architecture](#7-agentic-architecture)
8. [Agents & Their Roles](#8-agents--their-roles)
9. [Tech Stack](#9-tech-stack)
10. [Data & Privacy](#10-data--privacy)
11. [Roadmap](#11-roadmap)
12. [Setup & Installation](#12-setup--installation)
13. [Testing](#13-testing)

---

## 1. Vision & Mission

### Vision

A world where every person — regardless of budget, access, or experience — has a world-class fitness coach in their pocket that actually knows them.

### Mission

Build an AI-native fitness experience that removes the friction between intention and action. Alto listens, adapts, and shows up for users every single day — not just when they remember to open an app.

### Core Belief

> **Fitness plans fail people. People don't fail fitness plans.**
>
> Generic plans ignore how you slept, how stressed you are, where you are in your cycle, and what the weather looks like outside. Alto doesn't. It treats you like a person, not a profile.

---

## 2. The Problem

| Problem | Current Reality | What Alto Does |
|---|---|---|
| **Generic plans** | 1-size-fits-all programs | Personalized daily plans from real signals |
| **No adaptation** | Same plan whether you slept 4hrs or 8hrs | Readiness score adjusts every single day |
| **Nutrition guesswork** | Manual calorie logging is tedious | Photo-based AI macro estimation in seconds |
| **Weather-blind coaching** | Outdoor run scheduled in a thunderstorm | Automatically pivots to indoor alternatives |
| **Cycle-ignorant training** | Same intensity regardless of hormonal phase | Training adapts to menstrual cycle phases |
| **No recovery intelligence** | Rest days are arbitrary | Evidence-based recovery triggers from effort gaps |

---

## 3. Our Hypothesis

> If we give an AI coach access to the right real-time signals — sleep, stress, mood, weather, cycle phase, and calorie data — it will generate better daily training decisions than any static 12-week program.

### Supporting Bets

- **Readiness > Rigidity** — Users who train based on daily readiness will sustain habits longer than those on fixed schedules.
- **Friction kills compliance** — Removing manual logging (via voice and photo) increases daily check-in rates by 3–5×.
- **Personalization compounds** — Each data signal multiplies plan quality; the more Alto knows, the better it gets.
- **Cycle-aware training reduces injury** — Adapting intensity to hormonal phases reduces overtraining and improves long-term adherence for female athletes.

---

## 4. Use Cases

### The Busy Professional
**Works 9–6 · high stress · inconsistent sleep**

Detects low readiness from sleep and stress signals. Swaps a planned 10K run for a 25-min mobility session. Sends a compassionate nudge instead of a guilt trip.

### The Marathon Trainer
**Training for a race · needs periodization**

Builds a 4-phase goal timeline. Tracks weekly mileage increases and warns if the ramp rate exceeds 15% (injury risk threshold). Adjusts taper week automatically.

### The Postpartum Athlete
**Returning to fitness · cycle-aware needs**

Menstrual cycle phase detection. Caps RPE at 7 during luteal phase. Prioritizes recovery and mobility when readiness is low.

### The Calorie Tracker
**Focused on body composition · macro-conscious**

Point camera at a meal → AI returns calories, protein, carbs, fat in seconds. Cross-references daily calorie target and suggests add-on exercises if needed.

### The Outdoor Runner
**Loves running outside · weather-dependent**

Checks rain probability via WeatherKit before generating the plan. If rain > 60%, auto-pivots outdoor run to an indoor treadmill or circuit alternative.

### The Data-Driven Athlete
**Apple Watch user · biometric-focused**

Pulls resting heart rate, HRV, sleep stages, and steps from HealthKit. Uses biometrics as primary readiness input alongside self-reported mood.

---

## 5. Key Features

| Stat | Value |
|---|---|
| Real-time signals | 10+ |
| AI agents | 6 |
| Unit tests | 39 |
| Third-party trackers | 0 |

| Feature | Description |
|---|---|
| **AI Orchestration** | Gemini-powered daily plan generation from 10+ real-time signals |
| **Macro Vision** | Photo-based meal analysis — point, shoot, get macros instantly |
| **Smart Pivoting** | Automatically adjusts plans based on weather, readiness, and cycle phase |
| **Voice Logging** | Log workouts by speaking — parsed by on-device NLP |
| **Weather Awareness** | WeatherKit integration — plans adapt to real forecast |
| **HealthKit Sync** | Sleep, heart rate, steps, and cycle data from Apple Health |
| **Goal Timelines** | 4-phase periodization: Base → Build → Peak → Taper |
| **Privacy First** | All data stays on-device. No analytics. No tracking. No ads. |
| **Offline Fallback** | Rule-based orchestration works without internet connection |

---

## 6. App Screens

| Screen | Description |
|---|---|
| **Onboarding** | 4-step animated flow with welcome screen |
| **Dashboard** | Daily AI plan, nutrition summary, weather, recovery status |
| **Goals** | Multi-goal tracking with 4-phase training timelines |
| **Profile** | Stats, body data, goals, and settings |

### Onboarding Journey

| Step | Screen | Purpose |
|---|---|---|
| Welcome | Animated logo + rings | Brand impression + CTA |
| Step 1 | Identity | Name, gender, age, height, weight |
| Step 2 | Health Info | Conditions (asthma, joint issues, heart, diabetes) |
| Step 3 | Activity Rhythm | Workout frequency + preferred workout types |
| Step 4 *(female only)* | Cycle Details | Period duration, cycle length, last period date |
| Finish | Success screen | Personalized completion with name + stats |

---

## 7. Agentic Architecture

Alto's intelligence is built on a multi-agent pipeline that runs every morning when the user opens the app. Each agent has a single responsibility and a defined input/output contract.

```
┌──────────────────────────────────────────────────────────────────────┐
│                      ALTO AGENTIC PIPELINE                           │
└──────────────────────────────────────────────────────────────────────┘

  [1] DATA COLLECTION          Signal sources gather real-time context
       ├── HealthKit          → sleep hours, resting HR, steps, cycle phase
       ├── WeatherKit         → rain probability, temperature, conditions
       ├── Location           → indoor / outdoor context
       └── User check-in      → soreness (1–5), stress (1–5), mood (1–5)
                │
                ▼
  [2] READINESS SCORING        Produces a 0–100 readiness score
       ├── soreness  × 0.40
       ├── stress    × 0.30
       ├── mood      × 0.30
       └── luteal    − 10 pts
                │
                ▼
  [3] PIVOT ENGINE             Hard safety overrides before AI runs
       ├── readiness < 40?    → REST & WALK, no exceptions
       ├── rain > 60%?        → INDOOR alternative
       ├── sleep < 6.5 hrs?   → REDUCE intensity
       └── luteal phase?      → CAP RPE at 7, −10% duration
                │
                ▼
  [4] ORCHESTRATOR AGENT       Gemini 1.5 Pro generates the daily plan
       ├── Input: full context prompt (profile + signals + environment)
       ├── System rules: safety overrides, calorie targets, pivot flags
       ├── Output: workout name, duration, activities, RPE, coach note
       └── Fallback: SentinelOrchestrator (rule-based, works offline)
                │
                ▼
  [5] EFFORT GAP EVALUATION    Post-workout analysis (runs next morning)
       ├── achieved / target < 0.50?  → recovery trigger
       ├── high effort on easy day?   → compassionate re-engagement
       └── → tomorrow's plan adjusted accordingly
                │
                ▼
  [6] PLAN DELIVERY
       ├── Dashboard updated with today's plan
       ├── Push notification: headline + coach note
       └── Onboarding audit: ramp rate > 15%? → recommend extension
```

---

## 8. Agents & Their Roles

### Orchestrator Agent
**`ClaudeOrchestrationService.swift` · AI Agent · Gemini 1.5 Pro**

The brain. Generates a complete daily training plan from 10+ signals. Takes user profile, readiness score, weather, cycle phase, calorie target, and goal phase — outputs a full workout plan with headline, activities, RPE, and a personalized coaching note.

```json
{
  "headline":      "Easy Recovery Run",
  "why":           "You slept 6h and flagged moderate soreness — keeping it light.",
  "workoutName":   "30-min Easy Jog",
  "duration":      30,
  "calorieTarget": 420,
  "coachNote":     "Recovery days are where the gains are made. Trust the process."
}
```

---

### Sentinel Orchestrator
**`OrchestratorAgent.swift` · Rule-based Agent · Offline Fallback**

Mirrors the AI orchestrator's behaviour when no API key is configured or there is no internet. Implements readiness scoring, pivot logic, onboarding audits, and effort gap evaluation deterministically — no AI required.

| Function | Description |
|---|---|
| `readinessScore()` | Weighted scoring: soreness (40%) + stress (30%) + mood (30%) − luteal |
| `pivotTaskIfNeeded()` | Applies safety rules deterministically |
| `auditOnboarding()` | Flags injury risk if weekly increase > 15% |
| `evaluateEffortGap()` | Post-workout analysis — triggers compassion or recovery messages |

---

### Pivot Engine
**`PivotEngine.swift` · Decision Agent**

Binary pivot/no-pivot decisions based on environmental signals. Runs before the orchestrator to apply hard overrides. Also finds the next high-readiness date for scheduling make-up sessions.

```
evaluate(sleepHours: 5.8, rainProbability: 0.72)
→ PivotDecision.pivot(reasons: ["Low sleep detected", "Rain forecast"])

nextHighReadinessDate(projections)
→ Scans upcoming days → returns first date with HIGH readiness
```

---

### Macro Vision Agent
**`MacroVisionService.swift` · Vision AI Agent · Gemini Vision**

Analyses meal photos and returns macro estimates in under 2 seconds. Image is base64-encoded and sent to Gemini Vision. Returns structured JSON with calories, protein, carbs, and fat. Temperature set to 0.4 for conservative, accurate estimates.

```
User taps camera → photo captured
→ base64 encode image
→ Gemini Vision API call
→ { "calories": 520, "proteinGrams": 34, "carbsGrams": 48, "fatGrams": 18 }
→ Added to daily nutrition total
```

---

### Voice Workout Parser
**`VoiceWorkoutParser.swift` · NLP Agent · On-Device**

Converts spoken workout descriptions into structured data using on-device regex-based NLP. No internet required. Handles running, strength, cycling, and swimming patterns.

```
"I ran 5 miles in 45 minutes"
→ { type: run, distance: 5, unit: miles, duration: 45 }

"Did 3 sets of 12 bench press at 135 pounds"
→ { type: strength, sets: 3, reps: 12, exercise: "bench press", weight: 135 }
```

---

### Goal Timeline Generator
**`GoalTimelineGenerator.swift` · Planning Agent**

Takes a goal name + target date and generates a 4-phase periodized training timeline. Audits if weekly training increase exceeds 15% — if so, flags injury risk and recommends extending the timeline.

| Phase | Duration | Focus |
|---|---|---|
| **Base** | 25% of total time | Aerobic foundation, low intensity |
| **Build** | 40% of total time | Volume + intensity increase |
| **Peak** | 25% of total time | Race-specific workouts, max load |
| **Taper** | 10% of total time | Reduce volume, maintain intensity |

---

## 9. Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.9 |
| UI Framework | SwiftUI |
| Architecture | MVVM + Service Locator |
| AI / LLM | Google Gemini 1.5 Flash · 2.0 Flash · 1.5 Pro |
| Database | Supabase (PostgreSQL) — optional |
| Health Data | Apple HealthKit |
| Weather | Apple WeatherKit |
| Location | Core Location |
| Voice | AVAudioEngine + Speech Recognition |
| Notifications | UNUserNotificationCenter |
| Networking | URLSession (no third-party SDKs) |
| Testing | XCTest · 39 unit tests |
| Minimum iOS | iOS 17.0+ |

---

## 10. Data & Privacy

Alto is built privacy-first by design. No analytics. No third-party tracking. No ads. No data sold.

| Data | Where It Lives | Who Can See It |
|---|---|---|
| Health data (HealthKit) | On-device only | You only |
| Onboarding profile | Supabase (optional) | You only — RLS enforced |
| Gemini API key | iOS UserDefaults (encrypted at rest) | You only |
| Workout logs | On-device only | You only |
| Meal photos | Sent to Gemini for analysis, not stored | You only |
| Location | On-device only, used for weather lookup | You only |

> **All AI calls go directly from your device to Gemini — Alto's servers never see your data.**

---

## 11. Roadmap

### Done — v1.0
- [x] AI-powered daily plan generation (Gemini)
- [x] Readiness scoring + smart pivoting
- [x] Macro Vision — photo-based meal analysis
- [x] Menstrual cycle-aware training adjustments
- [x] Voice workout logging (on-device NLP)
- [x] 4-phase goal timeline generation
- [x] WeatherKit integration
- [x] HealthKit integration (sleep, energy, cycle)
- [x] Offline fallback — rule-based orchestration

### Next Up
- [ ] Apple Watch companion app (readiness check-in from wrist)
- [ ] Sleep stage integration (deep / REM / light breakdown)
- [ ] Nutrition barcode scanner
- [ ] Keychain migration for API key storage
- [ ] Profile-driven macro targets (calculated from weight + goal + activity)

### Future
- [ ] Social challenges and streak sharing
- [ ] Garmin / Whoop / Oura wearable integration
- [ ] Android version
- [ ] Coach persona customization
- [ ] Expanded workout type library (Pilates, Yoga, HIIT phase templates)

---

## 12. Setup & Installation

### 1. Open in Xcode

```bash
open Alto.xcodeproj
```

### 2. Configure Capabilities

In **Target → Signing & Capabilities**, add:
- HealthKit
- WeatherKit *(requires Apple Developer Program membership — $99/year)*

### 3. Add Info.plist Permissions

```xml
<key>NSHealthShareUsageDescription</key>
<string>Alto needs access to your health data to personalize your training plan based on sleep quality and activity levels.</string>

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

### 4. Build & Run

Press `⌘R` or click Play in Xcode. Target an iPhone simulator (iOS 17+) or physical device.

### 5. First-Time Setup in App

1. Complete onboarding (name, goal, preferences)
2. Go to **Profile → AI Features → Enter API Key**
3. Get a free Gemini key at [Google AI Studio](https://aistudio.google.com/apikey) (key starts with `AIza...`)
4. Select model: **Gemini 1.5 Flash** (recommended — 15 RPM free tier)
5. Grant HealthKit, location, and notification permissions when prompted

### Gemini Model Guide

| Model | Speed | Free Tier | Best For |
|---|---|---|---|
| Gemini 1.5 Flash | Fast | 15 RPM | Daily use (recommended) |
| Gemini 2.0 Flash | Fastest | 15 RPM | Experimental |
| Gemini 1.5 Pro | Slowest | 2 RPM | Most capable responses |

---

## 13. Testing

### Run Tests

```bash
# In Xcode
⌘U

# Via CLI
xcodebuild test \
  -scheme Alto \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -enableCodeCoverage YES
```

### Test Suite

| Suite | Tests | Coverage |
|---|---|---|
| `SentinelOrchestratorTests` | 18 | Readiness scoring, pivot logic, effort gap analysis |
| `GoalTimelineTests` | 5 | 4-phase generation, phase ordering, date coverage |
| `VoiceWorkoutParserTests` | 6 | Natural language duration and activity parsing |
| `NutritionViewModelTests` | 10 | Meal CRUD, calorie and macro aggregation |
| **Total** | **39** | |

---

## Troubleshooting

| Symptom | Solution |
|---|---|
| "API key required" | Profile → AI Features → Enter API Key |
| Rate limit (429) | Wait 60s or switch to Gemini 1.5 Pro in Settings |
| WeatherKit not working | Requires Apple Developer membership + WeatherKit capability + location permission |
| HealthKit fails | Add capability + Info.plist keys + grant permissions in iOS Settings → Health |
| Build errors | `⌘⇧K` to clean, then File → Packages → Reset Package Caches |

---

Built with Swift, SwiftUI & Google Gemini · © 2026 Komal Shete · MIT License
