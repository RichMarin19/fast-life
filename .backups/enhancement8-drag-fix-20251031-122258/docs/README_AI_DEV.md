# How the AI Developer Works (Repo‑Only Loop)

1. Read `SPRINT_PLAN.md`. Start with the lowest ticket ID not done.
2. Create a branch: `feat/<ticket-id>-short-name`.
3. Implement **only** what satisfies the 3 acceptance bullets.
4. Open a PR using `.github/pull_request_template.md` and **paste the same 3 bullets**.
5. On approval, merge; then mark the ticket **Done** in `SPRINT_PLAN.md` (commit included).
6. Update `docs/BUILD_STATUS.md` with a one‑line entry (date, PR, pass/fail, notes).

## Commit format
`<ticket-id>: <short description>`
Example: `T2: route app to default start tracker on launch`

## Notes
- Keep files ≤ 400 LOC or extract subviews/helpers.
- **SwiftUI views >500 LOC hit compilation timeouts** - use @ViewBuilder computed properties to decompose large views
- No `!` or `as!`. Use `guard`/`if let` with error logging.
- `.onChange` closures use two params: `{ oldValue, newValue in }` or `{ _, newValue in }`.