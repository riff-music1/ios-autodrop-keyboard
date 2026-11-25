import SwiftUI
import UIKit

@main
struct AutoDropHostApp: App {
    @StateObject private var settingsStore = SettingsStore()

    init() {
        configureUIKitAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settingsStore)
                .preferredColorScheme(.dark)
        }
    }

    private func configureUIKitAppearance() {
        UITextView.appearance().backgroundColor = .clear
        UITextView.appearance().keyboardAppearance = .dark

        let segmented = UISegmentedControl.appearance()
        segmented.selectedSegmentTintColor = UIColor(
            red: 1.0,
            green: 89.0 / 255.0,
            blue: 158.0 / 255.0,
            alpha: 1.0
        )
        segmented.backgroundColor = UIColor(
            red: 21.0 / 255.0,
            green: 21.0 / 255.0,
            blue: 21.0 / 255.0,
            alpha: 1.0
        )
        segmented.setTitleTextAttributes(
            [.foregroundColor: UIColor.white],
            for: .selected
        )
        segmented.setTitleTextAttributes(
            [.foregroundColor: UIColor(red: 160.0 / 255.0, green: 160.0 / 255.0, blue: 160.0 / 255.0, alpha: 1.0)],
            for: .normal
        )
    }
}
