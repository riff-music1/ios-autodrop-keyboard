import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    @State private var testerText: String = ""
    @FocusState private var isTesterFocused: Bool

    private var droppedLineCount: Int {
        guard !testerText.isEmpty else { return 0 }
        return testerText.filter { $0 == "\n" }.count
    }

    var body: some View {
        ZStack {
            Color.autoDropBackground
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 16) {
                    headerView
                    setupGuideCard
                    liveTesterCard
                    autoDropSettingsCard
                    hapticsCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                settings.reload()
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.autoDropAccent.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: "keyboard")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.autoDropAccent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("AutoDrop Keyboard")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.autoDropPrimaryText)
                Text("Instant letter, number & word drop keyboard")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.autoDropSecondaryText)
            }

            Spacer(minLength: 0)
        }
        .padding(.bottom, 2)
    }

    // MARK: - 1. Setup Guide Card

    private var setupGuideCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 12) {
                cardHeader(
                    icon: "gearshape.fill",
                    title: "Setup Guide",
                    badge: nil
                )

                VStack(alignment: .leading, spacing: 8) {
                    setupStep(number: "1", text: "Open Settings > General > Keyboard > Keyboards")
                    setupStep(number: "2", text: "Tap Add New Keyboard and choose AutoDrop Keyboard")
                    setupStep(number: "3", text: "Tap AutoDrop Keyboard and enable Allow Full Access")
                    setupStep(number: "4", text: "Switch keyboards anytime using the Globe key")
                }

                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.right.square.fill")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Open Settings")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(.autoDropPrimaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(Color.autoDropAccent)
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
    }

    // MARK: - 2. Live Tester Card

    private var liveTesterCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    cardHeader(
                        icon: "text.cursor",
                        title: "Live Tester",
                        badge: droppedLineCount > 0 ? "\(droppedLineCount) drops" : nil
                    )

                    Spacer()

                    if isTesterFocused {
                        Button("Done") {
                            isTesterFocused = false
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.autoDropSecondaryText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.autoDropSpecialKey)
                        )
                        .buttonStyle(.plain)
                    }

                    Button("Clear") {
                        testerText = ""
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.autoDropAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.autoDropAccent.opacity(0.16))
                    )
                    .buttonStyle(.plain)
                }

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.autoDropBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(
                                    isTesterFocused ? Color.autoDropAccent : Color(hex: 0x303030),
                                    lineWidth: 1.2
                                )
                        )

                    if testerText.isEmpty {
                        Text("Test Your Keyboard Here")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.autoDropSecondaryText.opacity(0.75))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $testerText)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.autoDropPrimaryText)
                        .focused($isTesterFocused)
                        .modifier(HiddenTextEditorBackgroundModifier())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .tint(.autoDropAccent)
                }
                .frame(height: 132)

                HStack(spacing: 10) {
                    Text("Mode: \(settings.activeMode.pillTitle)")
                    Text("•")
                    Text("Height: \(Int((settings.keyboardHeightScale * 100).rounded()))%")
                    Text("•")
                    Text("Font: \(Int(settings.keyFontSize.rounded()))pt")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.autoDropSecondaryText)
            }
        }
    }

    // MARK: - 3. Auto-Drop Settings Card

    private var autoDropSettingsCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 16) {
                cardHeader(
                    icon: "timer",
                    title: "Auto-Drop Settings",
                    badge: nil
                )

                // Number Delay Slider (200ms - 1500ms)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Number Delay (123 Mode)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.autoDropPrimaryText)
                        Spacer()
                        Text("\(Int(settings.numberDelayMs.rounded())) ms")
                            .font(.system(size: 13, weight: .bold).monospacedDigit())
                            .foregroundColor(.autoDropAccent)
                    }

                    Slider(
                        value: $settings.numberDelayMs,
                        in: 200...1500,
                        step: 50
                    )
                    .tint(.autoDropAccent)

                    HStack {
                        Text("200 ms")
                        Spacer()
                        Text("1500 ms")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.autoDropSecondaryText)
                }

                Divider()
                    .background(Color(hex: 0x2D2D2D))

                // Word Delay Slider (300ms - 2000ms)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Word Delay (On Pause)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.autoDropPrimaryText)
                        Spacer()
                        Text("\(Int(settings.wordDelayMs.rounded())) ms")
                            .font(.system(size: 13, weight: .bold).monospacedDigit())
                            .foregroundColor(.autoDropAccent)
                    }

                    Slider(
                        value: $settings.wordDelayMs,
                        in: 300...2000,
                        step: 50
                    )
                    .tint(.autoDropAccent)

                    HStack {
                        Text("300 ms")
                        Spacer()
                        Text("2000 ms")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.autoDropSecondaryText)
                }

                Divider()
                    .background(Color(hex: 0x2D2D2D))

                // Word Trigger Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Word Trigger")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.autoDropPrimaryText)

                    Picker("Word Trigger", selection: $settings.wordTrigger) {
                        ForEach(WordTriggerMode.allCases) { trigger in
                            Text(trigger.displayName).tag(trigger)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }

    // MARK: - 4. Haptics Card

    private var hapticsCard: some View {
        CardContainer {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.autoDropAccent.opacity(0.16))
                        .frame(width: 36, height: 36)
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.autoDropAccent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Key Press Haptics")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.autoDropPrimaryText)
                    Text("Subtle tactile feedback via UIImpactFeedbackGenerator")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.autoDropSecondaryText)
                }

                Spacer(minLength: 8)

                Toggle("", isOn: $settings.hapticsEnabled)
                    .labelsHidden()
                    .tint(.autoDropAccent)
                    .onChange(of: settings.hapticsEnabled) { enabled in
                        if enabled {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }
                    }
            }
        }
    }

    // MARK: - Helpers

    private func cardHeader(icon: String, title: String, badge: String?) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.autoDropAccent)
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.autoDropPrimaryText)

            if let badge = badge {
                Text(badge)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.autoDropAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.autoDropAccent.opacity(0.16))
                    )
            }
        }
    }

    private func setupStep(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.autoDropAccent)
                .frame(width: 22, height: 22)
                .background(
                    Circle()
                        .fill(Color.autoDropAccent.opacity(0.18))
                )

            Text(text)
                .font(.system(size: 13.5, weight: .medium))
                .foregroundColor(.autoDropSecondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct CardContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.autoDropCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color(hex: 0x2C2C2C), lineWidth: 1)
                    )
            )
    }
}

private struct HiddenTextEditorBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.scrollContentBackground(.hidden)
        } else {
            content
        }
    }
}

private extension Color {
    static let autoDropBackground = Color(hex: AutoDropPalette.backgroundHex)
    static let autoDropCard = Color(hex: AutoDropPalette.cardHex)
    static let autoDropSpecialKey = Color(hex: AutoDropPalette.specialKeyHex)
    static let autoDropAccent = Color(hex: AutoDropPalette.accentHex)
    static let autoDropPrimaryText = Color(hex: AutoDropPalette.primaryTextHex)
    static let autoDropSecondaryText = Color(hex: AutoDropPalette.secondaryTextHex)

    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
