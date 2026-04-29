# YTIconSwitcher

Dynamically replace the YouTube app icon on a rootless jailbreak.

## Requirements

- iOS 15+ (rootless jailbreak, e.g. Dopamine / palera1n)
- Theos with Logos
- PreferenceLoader installed on device

## Build

```bash
export THEOS=/opt/theos          # adjust to your Theos path
make package FINALPACKAGE=1
```

The `.deb` will be in `packages/`.

## Install icons

Place PNG files in:

```
/var/mobile/Library/Application Support/YTIconSwitcher/icons/
```

| Filename | Label in Settings |
|---|---|
| `default.png` | Default |
| `dark.png` | Dark |
| `classic.png` | Classic |
| `amoled.png` | AMOLED |
| `minimal.png` | Minimal |

Recommended size: **180 × 180 px** (PNG, no transparency required).

## Usage

1. Open **Settings → YTIconSwitcher**.
2. Pick an icon.
3. Tap **Refresh Icon Cache**, then **Respring** if the home-screen icon does not update.

## How it works

- `Tweak.x` hooks `UIImage +imageNamed:` and `NSBundle -pathForResource:ofType:`.
- Only calls whose asset name matches a known icon set (AppIcon*, YTLogo, etc.) are intercepted — all other image requests pass through untouched.
- The selected icon name is read from `com.frankfiorante.yticonswitcher.plist` and the resolved `UIImage` is cached for the process lifetime; cache is cleared on preference change via Darwin notification.
- Preference bundle live-notifies the tweak so the icon updates immediately inside a running YouTube session.

## Stretch features (not yet implemented)

- Random icon per day
- Dark-mode adaptive icon
- Theme packs
- Per-version fallback
