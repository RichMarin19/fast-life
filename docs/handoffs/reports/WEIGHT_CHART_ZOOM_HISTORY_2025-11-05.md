# Weight Chart Zoom & Selection History (2025-11-05)

## Timeline

- **Nov 4:** Original pinch/pan overlay introduced; selection lost because gestures moved outside `chartOverlay`.
- **Nov 5 (AM):** Rewrote zoom to bind `visibleDomain`, but selection still absent and zoom responded to single-finger drags.
- **Nov 5 (Midday):** Added overlay layer with `SpatialTapGesture`, two-finger `MagnificationGesture`, drag-only when zoomed, and double-tap reset. Guarded `ChartProxy.plotFrame` for iOS 17 to avoid deprecation warnings.

## Current Behaviour

- Tap once on a data point → detail callout updates (`selectedDate`).
- Pinch with two fingers → both x- and y-axis domains scale using helper clamps.
- Drag while zoomed → pans within allowed bounds; no effect at full extent.
- Double-tap → resets zoom/pan state.
- Zoom requires `plotFrame` availability; falls back to static view when unavailable.

## Follow-up

- After each code change, run `Command-U` on device and manual smoke: tap, pinch, drag, double-tap.
- Review `docs/handoffs/HANDOFF.md` entry **3.23** for What/How/Expected/Actual summary.
