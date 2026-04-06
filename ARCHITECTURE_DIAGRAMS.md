# Alto App - Architecture Diagrams

This document contains visual architecture diagrams for the Alto fitness app.

> **Note:** These diagrams use Mermaid syntax. View them on GitHub or use a Mermaid previewer for best results.

---

## 📊 Table of Contents

1. [System Architecture Overview](#1-system-architecture-overview)
2. [Component Diagram](#2-component-diagram)
3. [Data Flow - Daily Plan Generation](#3-data-flow---daily-plan-generation)
4. [API Integration Flow](#4-api-integration-flow)
5. [User Journey Flow](#5-user-journey-flow)
6. [Service Dependencies](#6-service-dependencies)
7. [State Management](#7-state-management)
8. [Meal Photo Analysis Flow](#8-meal-photo-analysis-flow)

---

## 1. System Architecture Overview

```mermaid
graph TB
    subgraph "User Interface Layer"
        UI[SwiftUI Views]
        Home[HomeView]
        Profile[ProfileView]
        Settings[SettingsView]
        Nutrition[NutritionView]
        Goals[GoalProgressView]
        Onboarding[OnboardingView]
    end

    subgraph "ViewModel Layer"
        DashVM[DashboardViewModel]
        NutVM[NutritionViewModel]
        GoalVM[GoalProgressViewModel]
        OnbVM[OnboardingViewModel]
    end

    subgraph "Service Layer - AI"
        Claude[ClaudeOrchestrationService<br/>Gemini AI Planning]
        Vision[GeminiVisionMacroService<br/>Meal Analysis]
        Sentinel[SentinelOrchestrator<br/>Rule-Based Fallback]
    end

    subgraph "Service Layer - Data"
        UserSettings[UserSettings<br/>API Key & Preferences]
        UserStore[UserStore<br/>User Profile State]
        HK[HealthKitService<br/>Sleep & Activity]
        Weather[WeatherService<br/>Location & Conditions]
        Voice[VoiceWorkoutParser<br/>NLP Parsing]
        Speech[SpeechTranscriptionService<br/>Voice Recognition]
    end

    subgraph "External Services"
        GeminiAPI[Google Gemini API]
        AppleHealth[Apple HealthKit]
        AppleWeather[Apple WeatherKit]
        AppleLocation[CoreLocation]
    end

    subgraph "Persistence"
        UD[UserDefaults]
        Supabase[(Supabase<br/>Optional)]
    end

    UI --> DashVM
    UI --> NutVM
    UI --> GoalVM
    UI --> OnbVM

    DashVM --> Claude
    DashVM --> Vision
    DashVM --> Sentinel
    DashVM --> UserSettings
    DashVM --> UserStore
    DashVM --> HK
    DashVM --> Weather
    DashVM --> Voice
    DashVM --> Speech

    Claude --> GeminiAPI
    Vision --> GeminiAPI
    
    HK --> AppleHealth
    Weather --> AppleWeather
    Weather --> AppleLocation

    UserSettings --> UD
    UserStore --> UD
    UserStore -.-> Supabase

    style Claude fill:#8B5CF6
    style Vision fill:#8B5CF6
    style UserSettings fill:#10B981
    style GeminiAPI fill:#4285F4
```

---

## 2. Component Diagram

```mermaid
graph LR
    subgraph "App Entry Point"
        AltoApp[AltoApp.swift<br/>@main]
    end

    subgraph "Global State"
        US[UserSettings<br/>@StateObject]
        Store[UserStore<br/>@StateObject]
        OnbVM[OnboardingViewModel<br/>@StateObject]
    end

    subgraph "Root Navigation"
        RootView[RootView<br/>Onboarding Router]
    end

    subgraph "Main App"
        MainTab[MainTabView<br/>4 Tabs]
        HomeTab[Home Tab]
        NutTab[Nutrition Tab]
        GoalsTab[Goals Tab]
        ProfTab[Profile Tab]
    end

    subgraph "Key Services"
        Claude[ClaudeOrchestrationService]
        Vision[GeminiVisionMacroService]
        Sentinel[SentinelOrchestrator]
    end

    AltoApp -->|inject| US
    AltoApp -->|inject| Store
    AltoApp -->|inject| OnbVM
    AltoApp --> RootView

    RootView -->|if complete| MainTab
    RootView -->|if not complete| Onboarding

    MainTab --> HomeTab
    MainTab --> NutTab
    MainTab --> GoalsTab
    MainTab --> ProfTab

    HomeTab -.->|uses| Claude
    HomeTab -.->|uses| Sentinel
    NutTab -.->|uses| Vision

    US -.->|provides API key| Claude
    US -.->|provides API key| Vision

    style US fill:#10B981
    style Claude fill:#8B5CF6
    style Vision fill:#8B5CF6
```

---

## 3. Data Flow - Daily Plan Generation

```mermaid
sequenceDiagram
    participant User
    participant HomeView
    participant DashboardVM
    participant UserSettings
    participant Claude
    participant Sentinel
    participant GeminiAPI

    User->>HomeView: Opens app
    HomeView->>DashboardVM: onAppear()
    
    alt Daily Sentinel needed
        DashboardVM->>User: Show Sentinel Popup
        User->>DashboardVM: Submit wellness scores
        DashboardVM->>DashboardVM: Calculate readiness
    end

    DashboardVM->>UserSettings: Check API key configured?
    
    alt API Key Configured
        UserSettings-->>DashboardVM: ✅ API key available
        DashboardVM->>Claude: buildPlanAsync(context)
        Note over Claude: Context includes:<br/>- Readiness score<br/>- Sleep hours<br/>- Weather data<br/>- Cycle phase<br/>- Goal phase
        
        Claude->>GeminiAPI: POST /generateContent
        Note over GeminiAPI: Gemini 1.5 Pro<br/>analyzes context
        GeminiAPI-->>Claude: JSON response
        
        alt API Success
            Claude-->>DashboardVM: OrchestratedPlan
            DashboardVM->>HomeView: Update UI with AI plan
        else API Error (429, network, etc)
            Claude-->>DashboardVM: Error
            DashboardVM->>Sentinel: buildPlan(context)
            Sentinel-->>DashboardVM: Rule-based plan
            DashboardVM->>HomeView: Update UI with fallback
        end
    else No API Key
        UserSettings-->>DashboardVM: ⚠️ No API key
        DashboardVM->>Sentinel: buildPlan(context)
        Sentinel-->>DashboardVM: Rule-based plan
        DashboardVM->>HomeView: Update UI with rules
    end

    HomeView->>User: Display today's plan
```

---

## 4. API Integration Flow

```mermaid
graph TB
    subgraph "User Configuration"
        User[User]
        SettingsUI[SettingsView]
        UserSettings[UserSettings Service]
    end

    subgraph "API Key Storage"
        UD[UserDefaults]
        Key[geminiAPIKey: String]
        Model[selectedGeminiModel: Enum]
    end

    subgraph "Service Initialization"
        ClaudeService[ClaudeOrchestrationService<br/>init apiKey, model]
        VisionService[GeminiVisionMacroService<br/>init apiKey, model]
    end

    subgraph "Gemini API"
        Endpoint1[/v1beta/models/gemini-1.5-pro:generateContent]
        Endpoint2[/v1beta/models/gemini-1.5-flash:generateContent]
    end

    subgraph "API Request"
        Headers[Headers:<br/>Content-Type: application/json]
        Body[Body:<br/>systemInstruction<br/>contents<br/>generationConfig]
        Params[URL Params:<br/>key=API_KEY]
    end

    subgraph "Response Handling"
        Success[200 OK<br/>Parse JSON]
        RateLimit[429 Rate Limit<br/>Fallback to Rules]
        Error[4xx/5xx Error<br/>Show user message]
    end

    User -->|1. Enter API key| SettingsUI
    SettingsUI -->|2. Save| UserSettings
    UserSettings -->|3. Persist| UD
    UserSettings -->|4. Store| Key
    UserSettings -->|4. Store| Model

    UserSettings -->|5. Provide credentials| ClaudeService
    UserSettings -->|5. Provide credentials| VisionService

    ClaudeService -->|6. HTTP POST| Endpoint1
    VisionService -->|6. HTTP POST| Endpoint2

    ClaudeService --> Headers
    ClaudeService --> Body
    ClaudeService --> Params

    Endpoint1 --> Success
    Endpoint1 --> RateLimit
    Endpoint1 --> Error

    style UserSettings fill:#10B981
    style ClaudeService fill:#8B5CF6
    style VisionService fill:#8B5CF6
    style Success fill:#10B981
    style RateLimit fill:#F59E0B
    style Error fill:#EF4444
```

---

## 5. User Journey Flow

```mermaid
graph TD
    Start([App Launch]) --> CheckOnboarding{Onboarding<br/>Complete?}
    
    CheckOnboarding -->|No| Onboarding1[Step 1: Profile Info]
    Onboarding1 --> Onboarding2[Step 2: Health Conditions]
    Onboarding2 --> Onboarding3[Step 3: Goal & Timeline]
    Onboarding3 --> SaveProfile[Save to UserStore]
    SaveProfile --> MainApp

    CheckOnboarding -->|Yes| MainApp[Main Tab View]

    MainApp --> Home[Home Tab]
    MainApp --> Nutrition[Nutrition Tab]
    MainApp --> Goals[Goals Tab]
    MainApp --> ProfileTab[Profile Tab]

    Home --> Sentinel{Daily Sentinel<br/>Needed?}
    Sentinel -->|Yes| SentinelPopup[Show Wellness Check-in]
    SentinelPopup --> Submit[Submit Scores]
    Submit --> GeneratePlan[Generate Daily Plan]
    
    Sentinel -->|No| GeneratePlan

    GeneratePlan --> CheckAPI{API Key<br/>Configured?}
    
    CheckAPI -->|Yes| AIPlan[🤖 AI Plan Generation]
    CheckAPI -->|No| RulePlan[📋 Rule-Based Plan]
    
    AIPlan --> DisplayPlan[Display Today's Plan]
    RulePlan --> DisplayPlan

    DisplayPlan --> Actions[User Actions]
    
    Actions --> VoiceLog[Voice Workout Log]
    Actions --> StartActivity[Start Activity]
    Actions --> CompleteActivity[Complete Activity]

    ProfileTab --> CheckAPIStatus{API Key<br/>Status?}
    CheckAPIStatus -->|Not Configured| SetupPrompt[Show Setup Required]
    CheckAPIStatus -->|Configured| ShowStatus[Show AI Active]
    
    SetupPrompt --> OpenSettings[Tap AI Features]
    ShowStatus --> OpenSettings
    
    OpenSettings --> SettingsView[Settings Screen]
    SettingsView --> EnterKey[Enter API Key]
    SettingsView --> SelectModel[Select Model]
    SettingsView --> Done[Save & Return]
    Done --> ProfileTab

    Nutrition --> MealPhoto[Take Meal Photo]
    MealPhoto --> AnalyzeAPI{API Key<br/>Available?}
    AnalyzeAPI -->|Yes| GeminiVision[🤖 Gemini Vision Analysis]
    AnalyzeAPI -->|No| ManualEntry[Manual Entry]
    GeminiVision --> ConfirmMacros[Confirm Macros]
    ConfirmMacros --> AddToTotal[Add to Daily Total]
    ManualEntry --> AddToTotal

    Goals --> Timeline[View 4-Phase Timeline]
    Timeline --> Progress[Track Progress]

    style AIPlan fill:#8B5CF6
    style GeminiVision fill:#8B5CF6
    style SetupPrompt fill:#F59E0B
    style ShowStatus fill:#10B981
```

---

## 6. Service Dependencies

```mermaid
graph TB
    subgraph "ViewModels"
        DashVM[DashboardViewModel]
        NutVM[NutritionViewModel]
        GoalVM[GoalProgressViewModel]
        OnbVM[OnboardingViewModel]
    end

    subgraph "Core Services"
        UserSettings[UserSettings<br/>🔑 API Configuration]
        UserStore[UserStore<br/>👤 User Profile]
    end

    subgraph "AI Services"
        Claude[ClaudeOrchestrationService<br/>🤖 Workout Planning]
        Vision[GeminiVisionMacroService<br/>📸 Meal Analysis]
        Sentinel[SentinelOrchestrator<br/>📋 Rule Engine]
    end

    subgraph "Data Services"
        HK[HealthKitService<br/>❤️ Sleep & Activity]
        Weather[WeatherService<br/>🌦️ Conditions]
        Location[LocationService<br/>📍 GPS]
        Speech[SpeechTranscriptionService<br/>🎤 Voice]
        Voice[VoiceWorkoutParser<br/>💬 NLP]
        Notifications[NotificationService<br/>🔔 Alerts]
    end

    subgraph "Repository"
        SupaRepo[SupabaseProfileRepository<br/>☁️ Optional Backend]
    end

    DashVM --> UserSettings
    DashVM --> UserStore
    DashVM --> Claude
    DashVM --> Vision
    DashVM --> Sentinel
    DashVM --> HK
    DashVM --> Weather
    DashVM --> Speech
    DashVM --> Voice
    DashVM --> Notifications

    NutVM --> UserStore
    NutVM --> Vision
    NutVM --> UserSettings

    GoalVM --> UserStore

    OnbVM --> UserStore
    OnbVM --> SupaRepo

    Claude -.->|requires| UserSettings
    Vision -.->|requires| UserSettings

    Weather --> Location

    UserStore -.->|optional| SupaRepo

    style UserSettings fill:#10B981
    style Claude fill:#8B5CF6
    style Vision fill:#8B5CF6
    style Sentinel fill:#6366F1
```

---

## 7. State Management

```mermaid
graph LR
    subgraph "App Level State"
        AltoApp[@main AltoApp]
    end

    subgraph "Global StateObjects"
        US[UserSettings<br/>@StateObject]
        Store[UserStore<br/>@StateObject]
        OnbVM[OnboardingViewModel<br/>@StateObject]
    end

    subgraph "View Level State"
        HomeVM[DashboardViewModel<br/>@StateObject]
        NutVM[NutritionViewModel<br/>@StateObject]
        GoalVM[GoalProgressViewModel<br/>@StateObject]
    end

    subgraph "Persistence"
        UD1[UserDefaults<br/>geminiAPIKey]
        UD2[UserDefaults<br/>selectedGeminiModel]
        UD3[UserDefaults<br/>notificationsEnabled]
        UD4[UserDefaults<br/>user profile data]
    end

    subgraph "Published Properties"
        P1[@Published var geminiAPIKey]
        P2[@Published var todayPlan]
        P3[@Published var readinessScore]
        P4[@Published var macroTotals]
    end

    AltoApp -->|creates| US
    AltoApp -->|creates| Store
    AltoApp -->|creates| OnbVM

    AltoApp -->|.environmentObject| RootView
    RootView -->|inherits| HomeView
    RootView -->|inherits| NutritionView
    RootView -->|inherits| GoalsView
    RootView -->|inherits| ProfileView

    HomeView -->|creates| HomeVM
    NutritionView -->|creates| NutVM
    GoalsView -->|creates| GoalVM

    US --> P1
    HomeVM --> P2
    HomeVM --> P3
    NutVM --> P4

    P1 -->|auto-save| UD1
    US -->|saves to| UD2
    US -->|saves to| UD3
    Store -->|saves to| UD4

    style US fill:#10B981
    style P1 fill:#F59E0B
    style UD1 fill:#60A5FA
```

---

## 8. Meal Photo Analysis Flow

```mermaid
sequenceDiagram
    participant User
    participant NutritionView
    participant NutVM as NutritionViewModel
    participant Settings as UserSettings
    participant Vision as GeminiVisionMacroService
    participant Gemini as Gemini API

    User->>NutritionView: Tap "Analyze Meal"
    NutritionView->>User: Open Camera
    User->>NutritionView: Take photo
    
    NutritionView->>NutVM: analyzeSelectedMealImage()
    
    NutVM->>Settings: Check isAPIKeyConfigured
    
    alt API Key Available
        Settings-->>NutVM: ✅ API key present
        
        NutVM->>NutVM: Convert UIImage to JPEG (0.8 quality)
        NutVM->>NutVM: Base64 encode
        
        NutVM->>Vision: init(apiKey, model)
        NutVM->>Vision: analyzeMeal(imageData)
        
        Vision->>Vision: Build prompt:<br/>"Analyze this food photo..."
        Vision->>Vision: Create request body:<br/>systemInstruction + inline_data
        
        Vision->>Gemini: POST /generateContent
        Note over Gemini: Gemini Vision analyzes:<br/>- Portion sizes<br/>- Food items<br/>- Calorie estimates
        
        alt Success Response
            Gemini-->>Vision: JSON: {calories, protein, carbs, fats}
            Vision->>Vision: Parse JSON
            Vision-->>NutVM: MacroEstimate
            
            NutVM->>NutritionView: Display pending estimate
            NutritionView->>User: Show macros for confirmation
            
            User->>NutritionView: Tap "Confirm"
            NutritionView->>NutVM: confirmMacros()
            NutVM->>NutVM: Add to macroTotals
            NutVM->>NutritionView: Update daily totals
            
        else Rate Limit (429)
            Gemini-->>Vision: 429 Error
            Vision-->>NutVM: MacroVisionError.apiError
            NutVM->>NutritionView: "Rate limit exceeded. Wait and retry."
            NutritionView->>User: Show error message
            
        else Network Error
            Gemini-->>Vision: Network failure
            Vision-->>NutVM: MacroVisionError.networkError
            NutVM->>NutritionView: "Network error. Check connection."
            NutritionView->>User: Show error message
        end
        
    else No API Key
        Settings-->>NutVM: ⚠️ No API key
        NutVM->>NutritionView: Show setup prompt
        NutritionView->>User: "Configure API key in Settings"
        User->>NutritionView: Tap "Go to Settings"
        NutritionView->>ProfileView: Navigate to Profile
        ProfileView->>SettingsView: Open Settings
    end
```

---

## 9. Readiness Scoring Algorithm

```mermaid
graph TD
    Start([Daily Sentinel Submission]) --> Init[Initialize score = 100]
    
    Init --> CheckSoreness{Soreness<br/>< 3?}
    CheckSoreness -->|Yes| DeductSoreness[score -= 30<br/>Add reason: high soreness]
    CheckSoreness -->|No| CheckStress
    DeductSoreness --> CheckStress
    
    CheckStress{Stress<br/>< 3?}
    CheckStress -->|Yes| DeductStress[score -= 20<br/>Add reason: high stress]
    CheckStress -->|No| CheckMood
    DeductStress --> CheckMood
    
    CheckMood{Mood<br/>< 3?}
    CheckMood -->|Yes| DeductMood20[score -= 20<br/>Add reason: low motivation]
    CheckMood -->|Mood == 3| DeductMood10[score -= 10]
    CheckMood -->|No| CheckCycle
    DeductMood20 --> CheckCycle
    DeductMood10 --> CheckCycle
    
    CheckCycle{Cycle Phase<br/>== Luteal?}
    CheckCycle -->|Yes| DeductCycle[score -= 10<br/>Add reason: luteal phase]
    CheckCycle -->|No| Clamp
    DeductCycle --> Clamp
    
    Clamp[Clamp score: max 0, min 100]
    Clamp --> Return[Return ReadinessScore]
    
    Return --> EvaluatePivot{Score < 40?}
    
    EvaluatePivot -->|Yes| ForcePivot[Force Rest & Walk<br/>25 min, RPE 2]
    EvaluatePivot -->|No| CheckWeather{Rain > 60%<br/>& Outdoor?}
    
    CheckWeather -->|Yes| IndoorPivot[Switch to Indoor Circuit<br/>Cap RPE at 6]
    CheckWeather -->|No| CheckLuteal{Luteal<br/>Phase?}
    
    CheckLuteal -->|Yes| LutealAdjust[Cap RPE at 7<br/>Reduce duration by 10%]
    CheckLuteal -->|No| UsePlanned[Use planned workout]
    
    ForcePivot --> GeneratePlan[Generate Daily Plan]
    IndoorPivot --> GeneratePlan
    LutealAdjust --> GeneratePlan
    UsePlanned --> GeneratePlan
    
    GeneratePlan --> End([Display Plan to User])
    
    style DeductSoreness fill:#EF4444
    style DeductStress fill:#F59E0B
    style DeductMood20 fill:#EF4444
    style ForcePivot fill:#EF4444
    style IndoorPivot fill:#F59E0B
    style LutealAdjust fill:#F59E0B
    style UsePlanned fill:#10B981
```

---

## 10. Voice Workout Logging Flow

```mermaid
stateDiagram-v2
    [*] --> Idle: HomeView loaded
    
    Idle --> Dictating: User taps "Dictate"
    Idle --> TextEntry: User types manually
    
    state Dictating {
        [*] --> RequestPermission
        RequestPermission --> CheckPermission: speechService.requestPermission()
        
        CheckPermission --> PermissionGranted: Allowed
        CheckPermission --> PermissionDenied: Denied
        
        PermissionGranted --> Recording: speechService.startTranscription()
        Recording --> Transcribing: Audio → Text
        Transcribing --> UpdateUI: voiceTranscript updates
        UpdateUI --> Recording: Continue listening
        
        PermissionDenied --> ShowError: Display permission error
        ShowError --> [*]
    end
    
    Dictating --> ReadyToParse: User taps "Stop"
    TextEntry --> ReadyToParse: Text entered
    
    state ReadyToParse {
        [*] --> Parse: User taps "Parse & Log"
        Parse --> VoiceParser: voiceParser.parse(transcript)
        
        VoiceParser --> RegexMatch: Pattern matching
        RegexMatch --> ExtractDuration: "30 mins"
        RegexMatch --> ExtractActivity: "yoga"
        
        ExtractDuration --> CreateEntry
        ExtractActivity --> CreateEntry
        
        CreateEntry --> Success: VoiceWorkoutEntry created
        CreateEntry --> Failure: Parse failed
        
        Success --> IncrementProgress: pathProgressSessions++
        Success --> ClearText: voiceTranscript = ""
        Success --> ShowConfirmation: "Logged: yoga · 30 min"
        
        Failure --> ShowError: "Could not parse. Try: I did 30 mins of yoga"
    end
    
    ReadyToParse --> Idle: Reset
    
    note right of Dictating
        Supported phrases:
        - "I did X mins of Y"
        - "Just finished X mins Y"
        - "Completed X mins of Y"
        - "X minutes of Y"
    end note
    
    note right of VoiceParser
        Extracts:
        - Duration (number + unit)
        - Activity type
        - Creates structured entry
    end note
```

---

## 11. Settings Configuration Flow

```mermaid
graph TD
    Start([User taps AI Features]) --> OpenSettings[Open SettingsView]
    
    OpenSettings --> ShowCurrent{Current<br/>State?}
    
    ShowCurrent -->|No Key| ShowEmpty[Show empty SecureField<br/>⚠️ API key required]
    ShowCurrent -->|Has Key| ShowMasked[Show masked key<br/>✅ API key configured]
    
    ShowEmpty --> UserActions
    ShowMasked --> UserActions
    
    subgraph "User Actions"
        EnterKey[Enter/Edit API Key]
        ToggleVisibility[Toggle show/hide]
        SelectModel[Select Gemini Model]
        TapHelp[Tap How to get API key]
        ClearKey[Tap Clear button]
    end
    
    EnterKey --> AutoSave[UserSettings auto-saves<br/>via didSet]
    SelectModel --> AutoSave
    
    AutoSave --> UpdateStatus{Validate<br/>Key}
    
    UpdateStatus -->|Not Empty| ConfiguredUI[Show ✅ configured<br/>Green border<br/>Show Clear button]
    UpdateStatus -->|Empty| RequiredUI[Show ⚠️ required<br/>Red border<br/>Hide Clear button]
    
    TapHelp --> OpenBrowser[Open Safari to<br/>aistudio.google.com/apikey]
    OpenBrowser --> UserGetsKey[User creates API key]
    UserGetsKey --> CopyKey[Copy key]
    CopyKey --> PasteKey[Paste in app]
    PasteKey --> EnterKey
    
    ClearKey --> Confirm{Show<br/>Alert}
    Confirm -->|Clear| DeleteKey[Set geminiAPIKey = empty]
    Confirm -->|Cancel| UserActions
    DeleteKey --> RequiredUI
    
    ToggleVisibility --> ShowPlain[Show plain text]
    ShowPlain --> ToggleVisibility2[Toggle again]
    ToggleVisibility2 --> ShowSecure[Show masked]
    
    ConfiguredUI --> Done[Tap Done button]
    RequiredUI --> Done
    
    Done --> CloseSettings[dismiss SettingsView]
    CloseSettings --> UpdateProfile[ProfileView refreshes]
    UpdateProfile --> ShowStatus{API Key<br/>Status?}
    
    ShowStatus -->|Configured| AIActive[Show AI Coaching Active<br/>Green card with model name]
    ShowStatus -->|Not Configured| SetupNeeded[Show Setup Required<br/>Red warning card]
    
    AIActive --> EnableFeatures[Enable AI Features:<br/>✅ Daily plan generation<br/>✅ Meal photo analysis]
    SetupNeeded --> FallbackFeatures[Fallback Mode:<br/>📋 Rule-based plans<br/>✍️ Manual meal entry]
    
    EnableFeatures --> End([User can use AI features])
    FallbackFeatures --> End
    
    style AutoSave fill:#10B981
    style ConfiguredUI fill:#10B981
    style AIActive fill:#10B981
    style RequiredUI fill:#F59E0B
    style SetupNeeded fill:#F59E0B
```

---

## 12. Four-Phase Training Timeline

```mermaid
gantt
    title Alto Training Timeline - 4 Phase System
    dateFormat YYYY-MM-DD
    
    section Base Phase (40%)
    Foundation Building      :base1, 2026-01-01, 56d
    Aerobic Development     :base2, after base1, 0d
    
    section Build Phase (30%)
    Intensity Increase      :build1, after base1, 42d
    Tempo Work             :build2, after build1, 0d
    
    section Peak Phase (20%)
    Race Pace              :peak1, after build1, 28d
    Max Performance        :peak2, after peak1, 0d
    
    section Taper Phase (10%)
    Volume Reduction       :taper1, after peak1, 14d
    Race Preparation       :taper2, after taper1, 0d
    
    section Milestone
    Goal Event            :milestone, after taper1, 1d
```

**Phase Characteristics:**

```mermaid
graph LR
    subgraph "Base Phase - 40%"
        Base1[Intensity: RPE 4-6]
        Base2[Focus: Aerobic foundation]
        Base3[Volume: Gradual increase]
    end
    
    subgraph "Build Phase - 30%"
        Build1[Intensity: RPE 6-8]
        Build2[Focus: Tempo work]
        Build3[Volume: Peak volume]
    end
    
    subgraph "Peak Phase - 20%"
        Peak1[Intensity: RPE 8-9]
        Peak2[Focus: Race pace]
        Peak3[Volume: Moderate]
    end
    
    subgraph "Taper Phase - 10%"
        Taper1[Intensity: RPE 4-6]
        Taper2[Focus: Recovery]
        Taper3[Volume: Reduced 40-60%]
    end
    
    Base1 --> Build1
    Build1 --> Peak1
    Peak1 --> Taper1
    
    style Base1 fill:#60A5FA
    style Build1 fill:#F59E0B
    style Peak1 fill:#EF4444
    style Taper1 fill:#10B981
```

---

## 13. Error Handling Strategy

```mermaid
graph TD
    Start([User Action]) --> APICall{Requires<br/>AI?}
    
    APICall -->|Yes| CheckKey{API Key<br/>Configured?}
    APICall -->|No| DirectAction[Execute locally]
    
    CheckKey -->|Yes| MakeRequest[Make API Request]
    CheckKey -->|No| ShowPrompt[Show Setup Prompt:<br/>Profile → Settings]
    
    MakeRequest --> Response{Response<br/>Status}
    
    Response -->|200 OK| ParseJSON{Parse<br/>JSON}
    Response -->|429 Rate Limit| RateLimit
    Response -->|401/403 Auth| InvalidKey
    Response -->|4xx Client Error| ClientError
    Response -->|5xx Server Error| ServerError
    Response -->|Network Error| NetworkError
    
    ParseJSON -->|Success| UseAIResult[Use AI Result]
    ParseJSON -->|Failure| ParseError
    
    subgraph "Error Recovery"
        RateLimit[Rate Limit Error]
        InvalidKey[Invalid API Key]
        ClientError[Client Error]
        ServerError[Server Error]
        NetworkError[Network Error]
        ParseError[JSON Parse Error]
    end
    
    RateLimit --> WaitRetry{Auto<br/>Retry?}
    WaitRetry -->|Yes| Wait[Wait 60s]
    WaitRetry -->|No| FallbackRules
    Wait --> MakeRequest
    
    InvalidKey --> UserMessage1[Show: Please check API key in Settings]
    ClientError --> UserMessage2[Show: Request error. Please try again.]
    ServerError --> UserMessage3[Show: Service temporarily unavailable]
    NetworkError --> UserMessage4[Show: Check internet connection]
    ParseError --> UserMessage5[Show: Unable to process response]
    
    UserMessage1 --> FallbackRules
    UserMessage2 --> FallbackRules
    UserMessage3 --> FallbackRules
    UserMessage4 --> FallbackRules
    UserMessage5 --> FallbackRules
    
    FallbackRules[Use Rule-Based Orchestrator] --> RuleResult[Generate Plan Locally]
    
    UseAIResult --> Success([Show AI Plan])
    RuleResult --> Success2([Show Rule Plan])
    ShowPrompt --> Manual([User manually configures])
    DirectAction --> Success3([Complete Action])
    
    style RateLimit fill:#F59E0B
    style InvalidKey fill:#EF4444
    style NetworkError fill:#EF4444
    style FallbackRules fill:#60A5FA
    style UseAIResult fill:#10B981
```

---

## How to Use These Diagrams

### Viewing on GitHub
GitHub automatically renders Mermaid diagrams. Just view this file on GitHub!

### Viewing Locally
1. **VS Code:** Install "Markdown Preview Mermaid Support" extension
2. **IntelliJ/WebStorm:** Built-in Mermaid support
3. **Browser:** Use [Mermaid Live Editor](https://mermaid.live/)

### Exporting
```bash
# Install Mermaid CLI
npm install -g @mermaid-js/mermaid-cli

# Export as PNG
mmdc -i ARCHITECTURE_DIAGRAMS.md -o diagrams/
```

---

## Legend

**Color Coding:**
- 🟢 Green (#10B981) - Success states, configured items
- 🟣 Purple (#8B5CF6) - AI services, Gemini-powered features
- 🔵 Blue (#60A5FA) - Data services, storage
- 🟡 Yellow (#F59E0B) - Warning states, fallback modes
- 🔴 Red (#EF4444) - Error states, required actions

**Shapes:**
- Rectangle - Process/Component
- Diamond - Decision point
- Circle - Start/End point
- Hexagon - External service
- Cylinder - Database/Storage

---

**Last Updated:** April 2026  
**Version:** 1.0.0  
**Maintained by:** Alto Development Team
