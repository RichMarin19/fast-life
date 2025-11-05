## Phase 3 – Weight Tracker Presentation Refactor

### Slice 3A – WeightControlCenterView Slimming (✅)
- Extracted gradient header/background into `WeightControlCenterHeaderView`.
- Added `WeightControlCenterCardList` to host the drop stack + about card.
- Verified sheet/alert bindings on-device.

### Slice 3B – Progress Story Modularization (🚧)
- Metrics helper + view model extraction done (335 LOC → 285 LOC).
- Remaining: ProgressStory card retirements once UI/UX signs off.

### Slice 3C – Stats & Chart Polish (🔜)
- Consolidate typography/spacing tokens across stats components.
- Verify VoiceOver + dynamic type compliance.
- Align graph palette with design tokens.

### Slice 3D – Notifications Cleanup (🔜)
- Delete legacy `NotificationsViewModel` once coordinator fully adopted.
- Update tests + docs accordingly.

### Post-Refactor QA
- Run Command‑U on device (weight tracker focus).
- Manual smoke: reorder, hide/restore, opt-out states.
