# ✦ GalacticJailbreak

> iOS jailbreak frontend · SwiftUI · Galactic UI · Dopamine · Dopamine 2
> Package manager selector runs **before** the jailbreak activates.

<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=6,11,20&height=200&section=header&text=GalacticJailbreak&fontSize=50&fontColor=ffffff&animation=twinkling&fontAlignY=35&desc=iOS%20Jailbreak%20Frontend%20%E2%80%94%20SwiftUI%20%C2%B7%20Dopamine%20%C2%B7%20Dopamine%202&descAlignY=55&descSize=16" />
</p>

---

## ⚠️ Supported Devices Only

| Chip | Jailbreak | Exploit | iOS Range |
|------|-----------|---------|-----------|
| A12 – A15 | Dopamine | weightBufs kernel r/w | 15.0 – 16.7.x |
| A16 | Dopamine 2 | kfd / XPF primitive | 16.0 – 16.7.x |

**Not supported:**
- iPhone X and older (A11 and below)
- iOS 17 and above
- iOS 26 / 27

If your device is unsupported, the app will show a clear message explaining why. No crash, no confusion.

---

## Package Managers

| Name | Style |
|------|-------|
| Sileo | Modern, Swift-native |
| Zebra | Lightweight APT |
| Cydia | Classic |
| Installer 5 | Minimalist |

Selected before the jailbreak activates.

---

## Build — GitHub Actions

Push to `main` → Actions builds the IPA automatically on a `macos-15` runner.

```bash
# Tag a release
git tag v1.0.0
git push --tags
```

IPA attaches to the GitHub Release automatically.

---

## Sideload

| Method | Notes |
|--------|-------|
| TrollStore | Best — permanent, no cert expiry |
| Sideloadly | Free Apple ID, 7-day renewal |
| AltStore | Same as Sideloadly |

---

## Project Structure

```
GalacticJailbreak/
├── .github/workflows/build.yml     # Actions pipeline
├── Assets.xcassets/                # App icon
├── Frameworks/                     # Dopamine exploit frameworks
├── Sources/
│   ├── App/
│   │   └── GalacticJailbreakApp.swift
│   ├── Engine/
│   │   ├── DeviceInfo.swift        # Hardware detection + routing
│   │   ├── JailbreakEngine.swift   # Stage orchestration
│   │   └── PackageManager.swift    # PM model
│   └── Views/
│       ├── Components/
│       │   └── GlowButton.swift
│       ├── ContentView.swift       # Phase router + unsupported screen
│       ├── GalacticBackgroundView.swift
│       ├── JailbreakView.swift
│       └── PackageManagerView.swift
├── ExportOptions.plist
├── Info.plist
└── project.yml
```

---

## Credits

- Exploit engine: [opa334/Dopamine](https://github.com/opa334/Dopamine)
- UI: Built with SwiftUI
- CI/CD: GitHub Actions (macos-15 runner)
