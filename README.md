# ✦ GalacticJailbreak

> Built on top of [Dopamine](https://github.com/opa334/Dopamine) by [@opa334dev](https://twitter.com/opa334dev)
> and [TrollStore](https://github.com/opa334/TrollStore). All exploit code belongs to the original authors.
> GalacticJailbreak is a UI frontend only. The jailbreak itself is Dopamine.

<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=6,11,20&height=200&section=header&text=GalacticJailbreak&fontSize=50&fontColor=ffffff&animation=twinkling&fontAlignY=35&desc=iOS%20Jailbreak%20Frontend%20%E2%80%94%20SwiftUI%20%C2%B7%20Dopamine%20%C2%B7%20Dopamine%202&descAlignY=55&descSize=16" />
</p>

<p align="center">
  <a href="https://github.com/Galactus-byte/GalacticJailbreak/actions/workflows/build.yml">
    <img src="https://github.com/Galactus-byte/GalacticJailbreak/actions/workflows/build.yml/badge.svg" alt="Build" />
  </a>
  <img src="https://img.shields.io/badge/iOS-15.0--16.7-purple?style=flat-square&logo=apple" alt="iOS" />
  <img src="https://img.shields.io/badge/Swift-5.9-orange?style=flat-square&logo=swift" alt="Swift" />
  <img src="https://img.shields.io/badge/Signer-TrollStore-blue?style=flat-square" alt="TrollStore" />
  <img src="https://img.shields.io/badge/Exploit-Dopamine-blueviolet?style=flat-square" alt="Dopamine" />
</p>

---

## ✦ Credits

This project would not exist without these people. Full stop.

| Person | Contribution |
|--------|-------------|
| **[@opa334dev](https://twitter.com/opa334dev)** | Dopamine, Dopamine 2, TrollStore — all exploit frameworks, bootstrap, package manager debs |
| **[@wh1te4ever](https://twitter.com/wh1te4ever)** | kfd exploit used by Dopamine 2 on A16 |
| **[@hrtowii](https://twitter.com/hrtowii)** | Dopamine contributions |
| **[@alfiecg_dev](https://twitter.com/alfiecg_dev)** | weightBufs exploit used by Dopamine on A12–A15 |
| **[@Linus Henze](https://github.com/LinusHenze)** | CoreTrust bug that makes TrollStore possible |

GalacticJailbreak is a **UI frontend only**. Every exploit, framework, bootstrap tarball,
and package manager deb comes directly from opa334's Dopamine project.
This app downloads Dopamine's own IPA at runtime and calls into it.

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
- A11 and below (iPhone X and older) — needs palera1n on a computer
- A17, M-series — no exploit available
- iOS 17 and above — no jailbreak available
- iOS 26 / 27 — no jailbreak available

Unsupported devices see a clear error screen. No crash.

---

## Entitlements

`Entitlements.plist` contains the exact same entitlements as the official Dopamine app.
Required for the kernel exploit. Preserved only when installed via TrollStore.

Key entitlements:
- `platform-application` — marks the app as a platform binary
- `com.apple.private.security.no-sandbox` — allows writing to `/var/jb/`
- `proc_info-allow` — required for credential replacement
- `com.apple.private.persona-mgmt` — required for the credential swap stage
- `com.apple.developer.kernel.extended-virtual-addressing` — needed by weightBufs/kfd

---

## Jailbreak Engine

`JailbreakEngine.swift` runs a 6-stage pipeline when BEGIN is tapped:

| Stage | What happens | Status |
|-------|-------------|--------|
| 1 | Download Dopamine IPA, extract frameworks + dylibs to `/var/jb/` | ✓ Real |
| 2 | `dlopen` weightBufs or kfd + support frameworks | ✓ Real |
| 3 | Load `libjailbreak.dylib` + `libxpf.dylib`, call exploit via `dlsym` or ObjC runtime | ✓ Real |
| 4 | Extract bootstrap to `/var/jb/` using bundled `bootstrap.tar.zst` | ✓ Real |
| 5 | Install selected PM via `dpkg -i` using bundled `.deb` from Dopamine IPA | ✓ Real |
| 6 | Run `uicache -a` + `sbreload` to activate jailbreak environment | ✓ Real |

---

## EntitlementChecker

`EntitlementChecker.swift` runs before Stage 1 and logs to the console:

**TrollStore install:**
```
Signer: TrollStore
platform-application entitlement active ✓
Sandbox disabled ✓
All entitlements active — ready to jailbreak ✓
```

**Free signer install:**
```
Signer: Sideloadly / AltStore / KSign
⚠ platform-application missing — install via TrollStore
⚠ Sandbox active — /var/jb writes will fail
Recommendation: reinstall via TrollStore
```

---

## Package Managers

| Name | Source | Style |
|------|--------|-------|
| Sileo | Bundled in Dopamine IPA | Modern, Swift-native |
| Zebra | Bundled in Dopamine IPA | Lightweight APT |
| Cydia | Download at runtime | Classic |
| Installer 5 | Download at runtime | Minimalist |

---

## Build

Push to `main` → GitHub Actions builds the IPA on `macos-15` automatically.

```bash
git tag v1.0.0
git push --tags
```

---

## Install

1. Download IPA from Actions artifacts or Releases
2. Open TrollStore → tap IPA → Install
3. Open GalacticJailbreak
4. Pick your package manager → tap BEGIN

---

## Project Structure

```
GalacticJailbreak/
├── .github/workflows/build.yml
├── Assets.xcassets/AppIcon.appiconset/
├── Entitlements.plist
├── Sources/
│   ├── App/GalacticJailbreakApp.swift
│   ├── Engine/
│   │   ├── DeviceInfo.swift
│   │   ├── EntitlementChecker.swift
│   │   ├── JailbreakEngine.swift
│   │   └── PackageManager.swift
│   └── Views/
│       ├── Components/GlowButton.swift
│       ├── ContentView.swift
│       ├── GalacticBackgroundView.swift
│       ├── JailbreakView.swift
│       └── PackageManagerView.swift
├── ExportOptions.plist
├── Info.plist
└── project.yml
```
