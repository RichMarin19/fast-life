# handoff.md — Audit Checklist

- Project overview: purpose, audience, value proposition, glossary
- Architecture map: modules & ownership (App, Core, Features/*, UI/*, Onboarding, Testing)
- State rules: who owns AppSettings; rules for `@StateObject` vs `@ObservedObject`
- Build & capabilities: targets, signing, HealthKit, background delivery, notifications
- Environment/config: build configs, Info.plist keys, bundle IDs, feature flags
- Persistence: UD keys, Codable models, migration policy; App Group plan (watchOS/extension)
- HealthKit: read/write types; anchored + observer queries; anchors storage
- Logging & analytics: OSLog categories; onboarding funnel events (names & payloads)
- UX specs: default tracker behavior; per‑tracker settings; terminology; accessibility targets
- Testing & QA: unit test scope; fixtures; manual QA (TZ edges, first‑run, restore‑from‑backup)
- Release: TestFlight checklist; crash reporting; versioning; screenshots & ASO notes