# Recipe: tinting UIKit bars on iOS 18 / 26 / 27

A drop-in reference for applying a brand colour to a `UINavigationController` +
`UITabBarController` chrome. Written to be handed to Claude Code (or read directly) when the
same change is needed in another project.

Everything here was established empirically on simulator runtimes by sampling rendered
pixels, because several of these APIs silently do nothing on iOS 26+. Where a technique
fails, that is recorded too — the failures are the valuable part.

Replace `tint` / `barForeground` with the project's own colours.

---

## 1. What does NOT work on iOS 26+ (verified, do not retry)

The iOS 26+ tab bar is a floating Liquid Glass bar drawn through a GPU/SDF pipeline. It
ignores the entire background half of `UITabBarAppearance`. Each of these was built, run and
pixel-sampled — all left the bar glass-coloured `(252,252,252)`:

| attempted | result |
|---|---|
| `appearance.configureWithOpaqueBackground()` + `appearance.backgroundColor` | ignored |
| `appearance.backgroundEffect = nil` | ignored |
| `appearance.backgroundImage = <solid colour>` | ignored |
| `tabBar.barTintColor` | ignored |
| `tabBar.isTranslucent = false` | ignored |
| `UIDesignRequiresCompatibility = true` in Info.plist | **ignored** when built with the iOS 27 SDK; produced a pixel-identical screenshot |

And for the **unselected** item colour, all of these left the label black:

| attempted | result |
|---|---|
| `tabBar.unselectedItemTintColor` (solid or with alpha) | ignored |
| `UITabBarAppearance` `stackedLayoutAppearance.normal.iconColor` / `titleTextAttributes` | ignored |
| `item.setTitleTextAttributes(_:for: .normal)` | ignored |
| `UILabel.appearance(whenContainedInInstancesOf: [UITabBar.self]).textColor` | ignored |
| walking the bar's subviews and setting `label.textColor`, even re-applied at 10 Hz | ignored |
| `tabBar.overrideUserInterfaceStyle = .dark` | sets the bar's traits, but does **not** change the rendered colour |

Baking the colour into the image (`item.image?.withTintColor(_, renderingMode: .alwaysOriginal)`)
*does* work for the unselected **icon**, but is unnecessary once the window trick below is used.

## 2. What works

### Tab bar background — the plain `UIView` property

```swift
tabBar.backgroundColor = tint   // iOS 26+: the ONLY thing that paints the bar
```

This also drops the floating capsule for a full-width opaque bar.

### Unselected item colour — via the window's interface style

The bar draws unselected items with `labelColor`, resolved against the **window's** interface
style (not the bar's own). So force the window dark and force the content back to light:

```swift
// SceneDelegate
if #available(iOS 26.0, *) {
    window.overrideUserInterfaceStyle = .dark
}

// every navigation controller / content container
if #available(iOS 26.0, *) {
    navigationController.overrideUserInterfaceStyle = .light
}
```

Without the second line the whole app turns dark. Watch for other system UI (alerts, action
sheets, keyboards) presented outside those containers — they inherit the dark window.

### White back chevron

`navigationBar.tintColor` does **not** colour the chevron on iOS 26+, because the glass back
button picks its own legibility colour. Replace the indicator artwork instead, with
`.alwaysOriginal` so UIKit does not re-tint it:

```swift
let chevron = UIImage(systemName: "chevron.backward")?
    .withConfiguration(UIImage.SymbolConfiguration(weight: .semibold))
    .withTintColor(barForeground, renderingMode: .alwaysOriginal)
appearance.setBackIndicatorImage(chevron, transitionMaskImage: chevron)
```

This keeps the real system back button — swipe-back gesture, long-press history menu and
`backButtonDisplayMode` all keep working. A custom `UIBarButtonItem` would cost all three.

### Navigation bar

Set all four appearance slots, or the bar goes transparent at scroll edge and in landscape:

```swift
let appearance = UINavigationBarAppearance()
appearance.configureWithOpaqueBackground()
appearance.backgroundColor = tint
appearance.titleTextAttributes = [.foregroundColor: barForeground]
appearance.largeTitleTextAttributes = [.foregroundColor: barForeground]

let buttonAppearance = UIBarButtonItemAppearance()
buttonAppearance.normal.titleTextAttributes = [.foregroundColor: barForeground]
appearance.buttonAppearance = buttonAppearance
appearance.backButtonAppearance = buttonAppearance
// ...plus setBackIndicatorImage from above

navigationBar.standardAppearance = appearance
navigationBar.compactAppearance = appearance
navigationBar.scrollEdgeAppearance = appearance
navigationBar.compactScrollEdgeAppearance = appearance
navigationBar.tintColor = barForeground
```

`appearance.doneButtonAppearance` is deprecated in iOS 26 — omit it.

### Pre-iOS 26 path

The classic bar honours the appearance API normally, so keep both paths:

```swift
private static func styleTabBar(_ tabBar: UITabBar) {
    tabBar.tintColor = barForeground

    if #available(iOS 26.0, *) {
        tabBar.backgroundColor = tabBarBackground
        return
    }

    let unselected = barForeground.withAlphaComponent(0.65)
    let appearance = UITabBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = tabBarBackground
    appearance.shadowColor = nil

    for itemAppearance in [
        appearance.stackedLayoutAppearance,
        appearance.inlineLayoutAppearance,
        appearance.compactInlineLayoutAppearance
    ] {
        itemAppearance.selected.iconColor = barForeground
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: barForeground]
        itemAppearance.normal.iconColor = unselected
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: unselected]
    }

    tabBar.standardAppearance = appearance
    tabBar.scrollEdgeAppearance = appearance
    tabBar.unselectedItemTintColor = unselected
}
```

## 3. Unrelated gotcha: `largeTitleDisplayMode`

`.inline` does **not** mean a small title. From `UINavigationItem.h`:

> `Inline` (iOS 17+) — *"Always use a large title when this item is topmost. If there is a
> back button present, this will revert to `Always`."*

So on a pushed screen `.inline` still renders a large title. Use `.never` for a small,
centred one.

## 4. Coverage — apply this honestly

| | tab bar fill | unselected label | nav bar |
|---|---|---|---|
| iOS 18.5 | solid | white @ 65% | works |
| **iOS 26.0** | **pale pink — fill composites under the glass** | **stays dark** | works |
| iOS 27.0 | solid | white | works |

**The tab bar half of this only fully works on iOS 27.** If the target app must support
iOS 26, either accept the system glass bar there (tint the selected item only) or re-run the
bisect in §5 against a 26 runtime — its glass may respond to a different property.

## 5. How to verify (do not trust the docs or the headers)

The headers describe none of this. The method that found it:

1. Build one binary with an env-var switch selecting one styling variant per launch:
   ```swift
   switch ProcessInfo.processInfo.environment["VARIANT"] ?? "baseline" { ... }
   ```
2. Launch each variant and screenshot, without rebuilding:
   ```sh
   SIMCTL_CHILD_VARIANT=effect xcrun simctl launch <udid> <bundle-id>
   xcrun simctl io <udid> screenshot out.png
   ```
3. Sample the pixels rather than eyeballing — a washed-out fill looks "kind of right" in a
   screenshot but reads `(255,194,183)` instead of `(255,56,60)`:
   ```python
   from PIL import Image
   im = Image.open("out.png").convert("RGB"); w, h = im.size
   print(im.getpixel((w // 2, h - 60)))
   ```
4. When a property is ignored, dump the bar's real view tree to find what draws the pixels:
   recursively print `type(of: view)` plus `UILabel.textColor` / `UIImageView.tintColor`, and
   read the app's stdout with `xcrun simctl launch --console-pty`. That is what revealed the
   `SelectedContentView` (uses `UITintColor`) vs `ContentView` (uses `labelColor`) split, and
   pointed at the window's interface style as the lever.

Screenshots taken during launch or while a simulator is shutting down are blank or all-black
— always settle a few seconds and sanity-check the sampled values.
