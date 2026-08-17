# ✦ GalacticJailbreak

> iOS jailbreak frontend · SwiftUI · Galactic UI · Dopamine · Dopamine 2
> Package manager selector runs **before** the jailbreak activates.

<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=6,11,20&height=200&section=header&text=GalacticJailbreak&fontSize=50&fontColor=ffffff&animation=twinkling&fontAlignY=35&desc=iOS%20Jailbreak%20Frontend%20%E2%80%94%20SwiftUI%20%C2%B7%20Dopamine%20%C2%B7%20Dopamine%202&descAlignY=55&descSize=16" />
</p>

<p align="center">
  <a href="https://github.com/YOURUSERNAME/YOURREPO/actions/workflows/build.yml">
    <img src="https://github.com/YOURUSERNAME/YOURREPO/actions/workflows/build.yml/badge.svg" alt="Build" />
  </a>
  <img src="https://img.shields.io/badge/iOS-15.0--16.7-purple?style=flat-square&logo=apple" alt="iOS" />
  <img src="https://img.shields.io/badge/Swift-5.9-orange?style=flat-square&logo=swift" alt="Swift" />
  <img src="https://img.shields.io/badge/Signer-TrollStore-blue?style=flat-square" alt="TrollStore" />
</p>

---

## ⚠️ Requirements

### TrollStore is required

GalacticJailbreak **must** be installed via [TrollStore](https://github.com/opa334/TrollStore).
Other signers (Sideloadly, AltStore, KSign, Esign) will strip the private entitlements
the exploit needs, and the jailbreak will fail at Stage 3.

| Signer | Private entitlements | Exploit works |
|--------|---------------------|---------------|
| **TrollStore** | ✓ preserved | ✓ **Yes** |
| ldid / zsign | ✓ preserved | ✓ Yes |
| Sideloadly | ✗ stripped | ✗ Stage 3 fails |
| AltStore | ✗ stripped | ✗ Stage 3 fails |
| KSign + muacert | ✗ stripped | ✗ Stage 3 fails |
| Esign | ✗ stripped | ✗ Stage 3 fails |

### How to install TrollStore (non-jailbroken devices)

TrollStore supports **iOS 14.0 – 16.6.1, 16.7 RC, and 17.0 only**.

| iOS Version | Method | PC needed |
|-------------|--------|-----------|
| 14.0 – 15.6.1 | TrollHelperOTA | No |
| 15.7 – 16.6.1 | TrollInstallerX | Yes (once) |
| 17.0 exactly | TrollRestore | Yes |
| 17.0.1+ / 26 / 27 | ✗ Not supported | — |

Full guide: **ios.cfw.guide/installing-trollstore**

---

## ⚠️ Supported Devices

| Chip | Jailbreak | Exploit | iOS Range |
|------|-----------|---------|-----------|
| A12 – A15 | Dopamine | weightBufs kernel r/w | 15.0 – 16.7.x |
| A16 | Dopamine 2 | kfd / XPF primitive | 16.0 – 16.7.x |

**Not supported:**
- A11 and below (iPhone X and older) — needs a computer with palera1n
- A17, M-series — no exploit available
- iOS 17 and above — no jailbreak available
- iOS 26 / 27 — no jailbreak available

Unsupported devices see a clear error screen with device info. No crash.

---

## Entitlements

GalacticJailbreak ships with `Entitlements.plist` containing the exact same
entitlements as the official Dopamine app. These are required for the kernel
exploit to execute. They are preserved only when installed via TrollStore.

Key entitlements:
- `platform-application` — marks the app as a platform binary
- `com.apple.private.security.no-sandbox` — allows writing to `/var/jb/`
- `proc_info-allow` — required for credential replacement
- `com.apple.private.persona-mgmt` — required for the credential swap stage
- `com.apple.developer.kernel.extended-virtual-addressing` — needed by weightBufs/kfd

---

## Jailbreak Engine

`JailbreakEngine.swift` runs a 6-stage pipeline when BEGIN is tapped:

| Stage | What happens | Real or stub |
|-------|-------------|-------------|
| 1 | Download Dopamine IPA from GitHub releases, extract frameworks + dylibs | ✓ Real |
| 2 | `dlopen` weightBufs or kfd framework + support frameworks | ✓ Real |
| 3 | Load `libjailbreak.dylib` + `libxpf.dylib`, call exploit via `dlsym` or ObjC runtime | ✓ Real |
| 4 | Extract `bootstrap_1800.tar.zst` or `bootstrap_1900.tar.zst` to `/var/jb/` | ✓ Real |
| 5 | Install selected package manager via `dpkg -i` using bundled `.deb` | ✓ Real |
| 6 | Run `uicache -a` + `sbreload` to activate the jailbreak environment | ✓ Real |

The engine also checks entitlements at runtime before Stage 1 runs and warns
the user if `platform-application` is missing — so KSign/Sideloadly users
see a clear message instead of a silent failure.

---

## Package Managers

Selected before the jailbreak activates. Sileo and Zebra use bundled `.deb`
files from the Dopamine IPA — no separate download needed.

| Name | Source | Style |
|------|--------|-------|
| Sileo | Bundled in Dopamine IPA | Modern, Swift-native |
| Zebra | Bundled in Dopamine IPA | Lightweight APT |
| Cydia | Download at runtime | Classic |
| Installer 5 | Download at runtime | Minimalist |

---

## Build — GitHub Actions

Push to `main` → Actions builds the IPA automatically on a `macos-15` runner.

```bash
git tag v1.0.0
git push --tags
```

IPA attaches to the GitHub Release automatically.

---

## Sideload via TrollStore

1. Download the IPA from the Actions artifacts or Releases
2. Open TrollStore on your device
3. Tap the IPA → Install
4. Open GalacticJailbreak from your home screen
5. Pick your package manager → tap BEGIN

---

## Project Structure

```
GalacticJailbreak/
├── .github/workflows/build.yml         # Actions pipeline (macos-15)
├── Assets.xcassets/AppIcon.appiconset/ # Galactic star icon
├── Entitlements.plist                  # Required — must install via TrollStore
├── Sources/
│   ├── App/
│   │   └── GalacticJailbreakApp.swift
│   ├── Engine/
│   │   ├── DeviceInfo.swift            # Hardware detection + chip routing
│   │   ├── EntitlementChecker.swift    # Runtime signer + entitlement detection
│   │   ├── JailbreakEngine.swift       # 6-stage jailbreak pipeline
│   │   └── PackageManager.swift        # PM model + bundled deb URLs
│   └── Views/
│       ├── Components/GlowButton.swift
│       ├── ContentView.swift           # Phase router + unsupported screen
│       ├── GalacticBackgroundView.swift # Animated starfield + nebulae
│       ├── JailbreakView.swift         # Progress ring + log console
│       └── PackageManagerView.swift    # Selector cards
├── ExportOptions.plist
├── Info.plist
└── project.yml
```

---

## Credits

- Exploit engine: [opa334/Dopamine](https://github.com/opa334/Dopamine)
- TrollStore: [opa334/TrollStore](https://github.com/opa334/TrollStore)
- UI: Built with SwiftUI
- CI/CD: GitHub Actions (macos-15 runner)

---

## EntitlementChecker

`EntitlementChecker.swift` runs automatically at the start of every jailbreak
attempt and prints a full report to the log console before Stage 1 begins.

**What it checks:**

| Check | How | What it means |
|-------|-----|---------------|
| Signer type | Attempts `task_for_pid` on PID 1 (launchd) | TrollStore/ldid = succeeds, free signers = fails |
| `platform-application` | Same `task_for_pid` check | Required for exploit to execute |
| Sandbox disabled | Tries writing outside sandbox boundary to `/var/testGalactic` | Required for `/var/jb/` writes |

**What you see in the log console:**

If installed via TrollStore:
```
Signer: TrollStore
platform-application entitlement active ✓
Sandbox disabled ✓
```

If installed via Sideloadly / KSign / AltStore:
```
Signer: Sideloadly / AltStore
⚠ platform-application missing — install via TrollStore
⚠ Sandbox active — /var/jb writes will fail
```

The jailbreak continues regardless — but the warnings tell the user exactly
why Stage 3 will fail before it does. No silent failures.

**File location:** `Sources/Engine/EntitlementChecker.swift`
