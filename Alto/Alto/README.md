# Alto iOS - Phase 1 Scaffold

This folder contains a Phase 1 + Phase 2 + Phase 3 + Phase 4 SwiftUI implementation:

- Story 1.1: Personal Profile & Privacy
- Story 1.2: Health Shield
- Story 1.3: Goal Architect
- Story 2.1: Bio-Sync (HealthKit)
- Story 2.2: Environment Scout (WeatherKit)
- Story 3.1: Morning Pivot
- Story 4.1: Invisible Log (Voice)
- Story 4.2: Macro-Vision (Camera)

## Included

- SwiftUI onboarding flow (3 steps)
- Name-required validation
- Height Imperial/Metric toggle with conversion
- Heart condition mandatory disclaimer popup
- Privacy footer on health screen
- Goal timeline generation (Base -> Build -> Peak -> Taper)
- First milestone shown immediately in Path UI
- Supabase REST insert into `user_profiles`
- SQL schema in `Supabase/schema.sql`
- HealthKit permissions for Sleep, HRV, Menstrual Cycle
- Dashboard card with "Last Night's Sleep"
- WeatherKit fetch for temperature + precipitation probability
- Weather Conflict flag when rain probability > 50%
- Morning Pivot engine: if Sleep < 6.5h OR Rain > 50%, show Pivoted state with Why
- Accept action reschedules hard workout to next high-readiness day
- Voice dictation (Speech framework) + parser for phrases like "I did 30 mins of Yoga"
- Path progress sessions increment instantly after parsed log
- Camera capture flow + OpenAI Vision macro estimate
- Required user confirmation before macros are added to daily totals

## Wire into Xcode

1. Create a new iOS App project in Xcode named `Alto` (SwiftUI lifecycle).
2. Add all files under `AltoApp/` into your Xcode target.
3. In Supabase SQL editor, run:
   - fresh setup: `Supabase/schema.sql`
   - upgrade existing table: `Supabase/migrations/20260308_onboarding_profile_v2.sql`
4. Provide environment values before running app:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `SUPABASE_ACCESS_TOKEN` (optional, required if your RLS needs auth bearer)
   - `OPENAI_API_KEY` (for macro analysis)
5. In your app target `Signing & Capabilities`, add:
   - HealthKit
   - WeatherKit
6. In `Info.plist`, add usage descriptions:
   - `NSHealthShareUsageDescription`
   - `NSLocationWhenInUseUsageDescription`
   - `NSCameraUsageDescription`
   - `NSMicrophoneUsageDescription`
   - `NSSpeechRecognitionUsageDescription`

## Notes

- `SupabaseProfileRepository` uses Supabase PostgREST (`/rest/v1/user_profiles`) with `URLSession`, so no SDK is required for Phase 1.
- Weather requires location access and can return unavailable if user declines permission.
