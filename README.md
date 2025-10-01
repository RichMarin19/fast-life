# Fast lIFe - iOS Fasting Timer App

A customizable iOS app for tracking intermittent fasting with dual timer display, progress ring, and history.

## Features

- ⏱️ **Dual Timer Display**: Shows both elapsed fasting time AND countdown to goal
- 🎯 **Visual Progress**: Circular progress ring showing completion percentage
- ⚙️ **Customizable Goals**: Set any fasting goal from 8-48 hours (with popular presets)
- 🔔 **Notifications**: Alert when your custom fasting goal is reached
- 📊 **History**: Track your last 10 completed fasts
- 💾 **Data Persistence**: Saves active fast, history, and goal preference
- 🌙 **Dark Mode**: Fully compatible with system appearance

## Quick Start

```bash
cd ~/Desktop/FastingTracker
./run.sh
```

## Usage

### Setting Your Goal (e.g., 20 hours)

1. Tap the **gear icon** next to "Goal: Xh"
2. Use slider or tap **"20h"** preset
3. Tap **"Save Goal"**

### Starting a Fast

Tap **"Start Fast"** to see:
- **Fasting**: 00:00:00 (elapsed time, counting up)
- **Remaining**: 20:00:00 (countdown to goal)

### Understanding the Display

After 8 hours into a 20-hour fast:
- **Fasting**: 08:00:00 ← How long you've been fasting
- **Remaining**: 12:00:00 ← Time until goal (blue countdown)
- **Progress**: 40%

When goal is reached:
- **Remaining** turns green and shows 00:00:00
- Notification appears
- Fast continues counting if you want to go longer

## App Configuration

- **App Name:** Fast lIFe
- **Bundle ID:** com.fastlife.app
- **Target:** iPhone 16 Pro Max simulator
- **iOS:** 17.0+

## CLI Commands

```bash
./build.sh              # Build only
./run.sh                # Build + launch in simulator
open FastingTracker.xcodeproj  # Open in Xcode
```

## Troubleshooting

**Build fails?**
```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

**Different simulator?**
Edit `build.sh` and `run.sh`:
```bash
SIMULATOR="iPhone 15 Pro"
```

**Reset app data?**
```bash
xcrun simctl erase "iPhone 16 Pro Max"
```

## License

MIT - Free to use and modify
