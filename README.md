# ✦ GalacticJailbreak

> iOS jailbreak frontend · SwiftUI · Galactic UI · palera1n + Dopamine
> Package manager selector runs **before** the jailbreak activates.

---

## Device Routing

| Chip | Jailbreak | Exploit | iOS Range |
|------|-----------|---------|-----------|
| A8 – A11 | palera1n | checkm8 (bootrom) | 15.0 – 16.x |
| A12 – A15 | Dopamine | weightBufs kernel r/w | 15.0 – 16.7.x |
| A16 | Dopamine 2 | kfd / XPF primitive | 16.0 – 16.7.x |

- **palera1n devices:** the IPA saves the package manager preference;
  jailbreak completes via the palera1n CLI on a Mac or Linux host.
- **Dopamine devices:** fully on-device execution.

---

## Package Managers

| Name | Style | Default for |
|------|-------|-------------|
| Sileo | Modern, Swift-native | Dopamine, palera1n |
| Zebra | Lightweight APT | Older hardware |
| Cydia | Classic | Legacy repos |
| Installer 5 | Minimalist | IPA-centric workflows |

---

## Build — GitHub Actions (macos-14 runner)

Push to `main` or open a PR → Actions builds the IPA automatically.

```
# Tag a public release
git tag v1.0.0
git push --tags
```

The `release` job attaches the IPA to the GitHub Release automatically.

### Signing

The default export is **unsigned** (ad-hoc). To sideload:
- **TrollStore** — install directly, no signing needed on supported devices
- **AltStore / Sideloadly** — sign with a free Apple ID (7-day cert)
- **Paid developer account** — update `ExportOptions.plist` method to `development`

---

## GitHub Codespaces

Open in Codespaces for Swift editing. The devcontainer runs on Ubuntu (Swift
toolchain for source editing only). All actual IPA builds run via Actions on
the macOS runner — push your changes and let the workflow do the compile.

---

## Exploit Integration Points

The engine stubs in `JailbreakEngine.swift` mark each stage clearly:

```swift
// Integration: ExploitBridge.shared.triggerWeightBufs()
// Integration: ExploitBridge.shared.escalatePrivileges()
// Integration: Bootstrap.shared.extract(to: "/var/jb")
// Integration: PackageInstaller.shared.install(pm, to: "/var/jb/Applications")
// Integration: SpringBoardBridge.shared.reloadWithInjection()
```

Wire in the native exploit implementations from:
- **Dopamine:** https://github.com/opa334/Dopamine
- **palera1n:**  https://github.com/palera1n/palera1n

---

## Project Structure

```
GalacticJailbreak/
├── .devcontainer/devcontainer.json     # Codespaces config
├── .github/workflows/build.yml         # Actions pipeline (macos-14)
├── ExportOptions.plist                 # Unsigned ad-hoc export
├── Info.plist
└── Sources/
    ├── App/
    │   └── GalacticJailbreakApp.swift
    ├── Engine/
    │   ├── DeviceInfo.swift            # Hardware detection + routing
    │   ├── JailbreakEngine.swift       # Stage orchestration + progress
    │   └── PackageManager.swift        # PM model
    └── Views/
        ├── Components/
        │   └── GlowButton.swift
        ├── ContentView.swift           # Phase router + header
        ├── GalacticBackgroundView.swift # Animated starfield + nebulae
        ├── JailbreakView.swift         # Ring, log console, controls
        └── PackageManagerView.swift    # Selector cards
```
