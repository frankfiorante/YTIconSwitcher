# YTIconSwitcher

Replace the YouTube app icon with custom PNG assets. Designed for IPA injection via [cyan](https://github.com/asdfzxcvbn/pyzule-rw).

## Requirements

- iOS 15+
- Theos with Logos (to build)

## Build

```bash
export THEOS=/opt/theos    # adjust to your Theos path
make package DEBUG=0 FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless
```

The `.deb` will be in `packages/`.

## Inject into an IPA

Pass the built `.deb` to cyan along with your other tweaks:

```bash
cyan -i YouTube.ipa -o YouTube_patched.ipa -uwef yticonswitcher.deb
```

The `-f` flag (`UIFileSharingEnabled`) is required — it is what makes the icon folder visible in Finder.

## Add icons

On the iPhone directly (no Mac needed):

1. Open the **Files** app.
2. Browse → **On My iPhone → YouTube**.
3. Open (or create) the **YTIconSwitcher** folder.
4. Drop any number of **180 × 180 px PNG** files in — the filename (minus `.png`) becomes the label shown in the picker.

PNGs can come from Safari downloads, iCloud Drive, AirDrop, or anywhere else Files can reach.

Alternatively, via a Mac:

1. Open **Finder**, select your device → **Files** → **YouTube**.
2. Drop PNGs into the **YTIconSwitcher** folder.

## Change the icon

Open YouTube and tap the **palette button** (🎨) in the top-right of the home screen nav bar. An action sheet lists every PNG found in the `YTIconSwitcher` folder. Tap one to apply it — the change takes effect immediately, no restart needed.

## How it works

- Hooks `UIImage +imageNamed:` and `NSBundle -pathForResource:ofType:` to intercept YouTube's icon asset lookups. Only names in a known set (`AppIcon*`, `YTLogo`, `UIApplicationIcon`) are redirected — all other image calls pass through untouched.
- The selected icon name is persisted to `Documents/YTIconSwitcher.plist`. In-memory state and the image cache update immediately on selection.
- The settings button is injected into `YTRightNavigationButtons` using `YTQTMButton`, the same approach used by iSponsorBlock.
