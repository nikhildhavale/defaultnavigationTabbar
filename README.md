# CheckColor

A minimal UIKit reference app for one specific problem: **applying a custom brand colour
to the navigation bar and tab bar across iOS 18, 26 and 27.**

The system APIs that are supposed to do this (`UITabBarAppearance`,
`unselectedItemTintColor`, `navigationBar.tintColor`) stopped working for the tab bar
when iOS 26 introduced the floating Liquid Glass bar, and the replacements are not
documented. This project is the working result of finding out what does work, verified by
running on device runtimes and sampling the rendered pixels rather than trusting the docs.

If you just want the recipe to apply elsewhere, read **[TINTED_BARS_RECIPE.md](TINTED_BARS_RECIPE.md)**.

## What it demonstrates

- A `UITabBarController` built in code, each tab wrapped in its own `UINavigationController`
  (no storyboard entry point)
- Red navigation bar with white large and inline titles
- `backButtonDisplayMode = .minimal` — chevron only, no "Back" text
- A **white** back chevron, which `navigationBar.tintColor` alone does not give you on iOS 26+
- Red tab bar with white selected and unselected items
- `largeTitleDisplayMode = .never` on a pushed screen, since `.inline` does *not* mean a
  small title

## Results by OS version

Measured from screenshots of the running app — the numbers are sampled pixel values.

| | tab bar fill | unselected label | nav bar + white chevron |
|---|---|---|---|
| **iOS 18.5** | solid red | white @ 65% | works |
| **iOS 26.0** | **pale pink (255,194,183)** | **dark (70,8,0)** | works |
| **iOS 27.0** | solid red (255,56,60) | white | works |

**iOS 26 is a known broken case.** The fill composites *underneath* the glass layer instead
of replacing it, so red dilutes to pink, and the trick that turns unselected labels white on
27 has no effect there. The navigation bar is correct on all three. Same binary, same SDK —
this is purely an OS behaviour difference, which is worth remembering before relying on any
of it long term.

## Layout

| file | role |
|---|---|
| `CheckColor/AppRootBuilder.swift` | all the bar styling, both OS paths |
| `CheckColor/SceneDelegate.swift` | builds the window; forces it dark on iOS 26+ |
| `CheckColor/ViewController.swift` | Home tab, pushes the detail screen |
| `CheckColor/DetailViewController.swift` | pushed screen, shows the minimal back button |
| `CheckColor/SettingsViewController.swift` | second tab |

`Main.storyboard` is still in the project but unused — the storyboard entry point was
removed from both `Info.plist` and the build settings.

## Running it

```sh
open CheckColor.xcodeproj
```

Deployment target is **iOS 18.0**, so it builds and runs on all three runtimes above. Tap
**Push Detail** on the Home tab to see the minimal back button.
