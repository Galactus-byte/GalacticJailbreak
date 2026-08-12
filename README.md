<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=6,11,20&height=200&section=header&text=GalacticJailbreak&fontSize=50&fontColor=ffffff&animation=twinkling&fontAlignY=35&desc=iOS%20Jailbreak%20Frontend%20%E2%80%94%20SwiftUI%20%C2%B7%20palera1n%20%C2%B7%20Dopamine&descAlignY=55&descSize=16" />
</p>

<p align="center">
  <a href="https://github.com/Galactus-byte/GalacticJailbreak/actions/workflows/build.yml">
    <img src="https://github.com/Galactus-byte/GalacticJailbreak/actions/workflows/build.yml/badge.svg" alt="Build" />
  </a>
  <a href="https://github.com/Galactus-byte/GalacticJailbreak/releases/latest">
    <img src="https://img.shields.io/github/v/release/Galactus-byte/GalacticJailbreak?color=cyan&label=latest&style=flat-square" alt="Release" />
  </a>
  <img src="https://img.shields.io/badge/iOS-15.0--16.7-purple?style=flat-square&logo=apple" alt="iOS" />
  <img src="https://img.shields.io/badge/Swift-5.9-orange?style=flat-square&logo=swift" alt="Swift" />
  <img src="https://img.shields.io/badge/Xcode-16-blue?style=flat-square&logo=xcode" alt="Xcode" />
  <a href="https://github.com/Galactus-byte/GalacticJailbreak/stargazers">
    <img src="https://img.shields.io/github/stars/Galactus-byte/GalacticJailbreak?color=yellow&style=flat-square" alt="Stars" />
  </a>
  <a href="https://github.com/Galactus-byte/GalacticJailbreak/forks">
    <img src="https://img.shields.io/github/forks/Galactus-byte/GalacticJailbreak?color=green&style=flat-square" alt="Forks" />
  </a>
</p>

---

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
