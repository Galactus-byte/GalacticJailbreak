# ✦ GalacticJailbreak

> Built on top of [Dopamine](https://github.com/opa334/Dopamine) by [@opa334dev](https://twitter.com/opa334dev)
> and [TrollStore](https://github.com/opa334/TrollStore). All exploit code belongs to the original authors.
> GalacticJailbreak is a modernized SwiftUI frontend for Dopamine rootless jailbreaks.

<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=6,11,20&height=200&section=header&text=GalacticJailbreak&fontSize=50&fontColor=ffffff&animation=twinkling&fontAlignY=35&desc=iOS%20Jailbreak%20Frontend%20%E2%80%94%20SwiftUI%20%C2%B7%20Dopamine%202&descAlignY=55&descSize=16" />
</p>

<p align="center">
  <a href="https://github.com/Galactus-byte/GalacticJailbreak/actions/workflows/build.yml">
    <img src="https://github.com/Galactus-byte/GalacticJailbreak/actions/workflows/build.yml/badge.svg" alt="Build" />
  </a>
  <img src="https://img.shields.io/badge/iOS-15.0--16.6.1-purple?style=flat-square&logo=apple" alt="iOS" />
  <img src="https://img.shields.io/badge/Swift-5.9-orange?style=flat-square&logo=swift" alt="Swift" />
  <img src="https://img.shields.io/badge/Signer-TrollStore-blue?style=flat-square" alt="TrollStore" />
  <img src="https://img.shields.io/badge/Exploit-Dopamine%202-blueviolet?style=flat-square" alt="Dopamine" />
</p>

---

## ✦ Credits

This project stands on the shoulders of the iOS jailbreaking community:

| Person / Team | Contribution |
|---------------|--------------|
| **[@opa334dev](https://twitter.com/opa334dev)** | Dopamine, Dopamine 2, TrollStore — exploit orchestration, basebin, bootstrap integration |
| **[@wh1te4ever](https://twitter.com/wh1te4ever)** | kfd and landa exploit primitives used in Dopamine 2 |
| **[@alfiecg_dev](https://twitter.com/alfiecg_dev)** | weightBufs exploit primitive |
| **[@LinusHenze](https://github.com/LinusHenze)** | CoreTrust bug enabling TrollStore, Fugu15 |
| **Procursus Team** | Procursus rootless bootstrap environment |

---

## ⚠️ Requirements

### TrollStore is required

GalacticJailbreak **must** be installed via [TrollStore](https://github.com/opa334/TrollStore).
Free signers (Sideloadly, AltStore, standard developer certificates) will strip the private entitlements
the exploit requires.

| Signer | Private Entitlements | Compatible |
|--------|----------------------|------------|
| **TrollStore** | ✓ Preserved | ✓ **Yes** |
| ldid / CoreTrust | ✓ Preserved | ✓ Yes |
| Sideloadly | ✗ Stripped | ✗ No |
| AltStore | ✗ Stripped | ✗ No |
| Standard Free Signers | ✗ Stripped | ✗ No |

### Installing TrollStore

TrollStore supports **iOS 14.0 – 16.6.1, 16.7 RC, and 17.0**.

| iOS Version | Method | PC Needed |
|-------------|--------|-----------|
| 14.0 – 15.6.1 | TrollHelperOTA | No |
| 15.7 – 16.6.1 | TrollInstallerX | Yes (one-time) |
| 17.0 exactly | TrollRestore | Yes |
| 17.0.1+ | ✗ Unsupported | — |

Comprehensive installation guide: **[ios.cfw.guide/installing-trollstore](https://ios.cfw.guide/installing-trollstore)**

---

## ⚠️ Supported Devices & iOS Versions

GalacticJailbreak targets arm64e hardware on Dopamine 2 supported releases:

| Chip Generation | Example Devices | Supported iOS Range | Exploit Primitives |
|-----------------|-----------------|---------------------|--------------------|
| **A12 – A14** | iPhone XS – iPhone 12 Pro Max, iPad Air 4 | **iOS 15.0 – 16.6.1** | kfd / landa / weightBufs |
| **A15 – A16** | iPhone 13 / 14 / 15 series | **iOS 15.0 – 16.6.1** | kfd / landa / weightBufs |
| **M1 – M2** | iPad Pro / iPad Air (Apple Silicon) | **iPadOS 15.0 – 16.6.1** | kfd / landa / weightBufs |

**Not supported:**
- **A11 and earlier (iPhone X, 8, 7, 6s)**: Use [palera1n](https://palera.in) (checkm8-based)
- **A17 Pro / M4 and newer**: No public kernel r/w exploit available
- **iOS 17.0.1 and newer**: No public jailbreak available

---

## Entitlements

`Entitlements.plist` contains the required entitlements preserved by TrollStore:
- `platform-application` — Marks app as a platform binary
- `com.apple.private.security.no-sandbox` — Grants unsandboxed access for bootstrap staging
- `proc_info-allow` — Required for process introspection and credential swap
- `com.apple.private.persona-mgmt` — Required for persona credential migration
- `com.apple.developer.kernel.extended-virtual-addressing` — Required for kernel address space mappings

---

## Supported Rootless Package Managers

| Package Manager | Status | Description |
|-----------------|--------|-------------|
| **Sileo** | Bundled / Recommended | Fast, modern, Swift-native package manager |
| **Zebra** | Bundled / Alternative | Lightweight, high-performance APT package manager |

*(Note: Legacy managers like Cydia are 32-bit/rootful only and are not supported on modern rootless jailbreaks).*

---

## Build & Installation

### Automated Build (GitHub Actions)
Pushing a tag or commit to `main` automatically triggers the GitHub Actions workflow to generate an unsigned IPA.

### Local Build via XcodeGen
```bash
brew install xcodegen
xcodegen generate
xcodebuild archive \
  -project GalacticJailbreak.xcodeproj \
  -scheme GalacticJailbreak \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath build/GalacticJailbreak.xcarchive \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO
```

### Installation
1. Download `GalacticJailbreak.ipa` from Releases / Artifacts.
2. Share the IPA to **TrollStore** and tap **Install**.
3. Open GalacticJailbreak, choose your preferred package manager (Sileo / Zebra), and proceed.
