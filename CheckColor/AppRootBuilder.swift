//
//  AppRootBuilder.swift
//  CheckColor
//

import UIKit

/// Builds the app's root view controller: a tab bar controller whose tabs are
/// each wrapped in their own navigation controller.
enum AppRootBuilder {

    /// The tint applied to the tab bar and the navigation bar background.
    static let tint: UIColor = .systemRed

    /// Drawn on top of the red bars.
    static let barForeground: UIColor = .white

    /// Tab bar background. Matches the navigation bar so the chrome reads as
    /// one surface top and bottom.
    static let tabBarBackground: UIColor = tint


    static func makeRootViewController() -> UITabBarController {
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [
            makeNavigationController(
                root: ViewController(),
                title: "Home",
                image: UIImage(systemName: "house"),
                selectedImage: UIImage(systemName: "house.fill")
            ),
            makeNavigationController(
                root: SettingsViewController(),
                title: "Settings",
                image: UIImage(systemName: "gearshape"),
                selectedImage: UIImage(systemName: "gearshape.fill")
            )
        ]
        styleTabBar(tabBarController.tabBar)

        return tabBarController
    }

    /// Paints the tab bar red with white items, on both designs.
    ///
    /// iOS 26+ draws a floating Liquid Glass bar that ignores UITabBarAppearance's
    /// background entirely (backgroundColor, backgroundImage, backgroundEffect,
    /// barTintColor and isTranslucent all do nothing) -- the plain UIView
    /// background is what paints it, and doing so also drops the glass capsule
    /// for a full-width opaque bar. That bar also ignores unselectedItemTintColor
    /// and the appearance item colours, drawing unselected items with
    /// `labelColor` resolved against the WINDOW's interface style; SceneDelegate
    /// forces the window dark for that, and each navigation controller forces its
    /// own content back to light.
    ///
    /// iOS 25 and earlier use the classic bar, where the appearance API works.
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

    static func makeNavigationController(
        root: UIViewController,
        title: String,
        image: UIImage?,
        selectedImage: UIImage?
    ) -> UINavigationController {
        root.title = title
        // Back buttons pushed on top of this root show the chevron only.
        root.navigationItem.backButtonDisplayMode = .minimal

        let navigationController = UINavigationController(rootViewController: root)
        navigationController.tabBarItem = UITabBarItem(
            title: title,
            image: image,
            selectedImage: selectedImage
        )
        navigationController.navigationBar.prefersLargeTitles = true

        let appearance = makeNavigationBarAppearance()
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactScrollEdgeAppearance = appearance
        // Back chevron and bar button items, drawn on top of the red bar.
        navigationController.navigationBar.tintColor = barForeground
        if #available(iOS 26.0, *) {
            // Keep page content light even though the window is forced dark.
            navigationController.overrideUserInterfaceStyle = .light
        }

        return navigationController
    }

    /// An opaque red navigation bar with white titles and items.
    private static func makeNavigationBarAppearance() -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = tint
        appearance.titleTextAttributes = [.foregroundColor: barForeground]
        appearance.largeTitleTextAttributes = [.foregroundColor: barForeground]

        let buttonAppearance = UIBarButtonItemAppearance()
        buttonAppearance.normal.titleTextAttributes = [.foregroundColor: barForeground]
        appearance.buttonAppearance = buttonAppearance
        appearance.backButtonAppearance = buttonAppearance

        // The back chevron is drawn by the system and does not follow
        // `navigationBar.tintColor`, so bake the colour into the indicator image.
        let chevron = UIImage(systemName: "chevron.backward")?
            .withConfiguration(UIImage.SymbolConfiguration(weight: .semibold))
            .withTintColor(barForeground, renderingMode: .alwaysOriginal)
        appearance.setBackIndicatorImage(chevron, transitionMaskImage: chevron)

        return appearance
    }
}
