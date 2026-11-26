import Foundation

public enum AutoDropMode: String, CaseIterable, Codable {
    case off = "off"
    case abc = "abc"
    case number123 = "123"
    case word = "word"

    public var pillTitle: String {
        switch self {
        case .off: return "OFF"
        case .abc: return "ABC"
        case .number123: return "123"
        case .word: return "WORD"
        }
    }
}

public enum WordTriggerMode: String, CaseIterable, Codable, Identifiable {
    case onPause = "onPause"
    case onSpacebar = "onSpacebar"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .onPause: return "On Pause"
        case .onSpacebar: return "On Spacebar"
        }
    }
}

public enum KeyGapMode: String, CaseIterable, Codable, Identifiable {
    case tight = "tight"
    case comfortable = "comfortable"

    public var id: String { rawValue }

    public var spacing: Double {
        switch self {
        case .tight: return 3.0
        case .comfortable: return 6.0
        }
    }

    public var displayName: String {
        switch self {
        case .tight: return "Tight"
        case .comfortable: return "Comfortable"
        }
    }
}

public enum AutoDropPalette {
    public static let backgroundHex: UInt32 = 0x151515
    public static let toolbarHex: UInt32 = 0x1A1A1A
    public static let cardHex: UInt32 = 0x202020
    public static let standardKeyHex: UInt32 = 0x232323
    public static let specialKeyHex: UInt32 = 0x2C2C2C
    public static let pressedKeyHex: UInt32 = 0x383838
    public static let accentHex: UInt32 = 0xFF599E
    public static let primaryTextHex: UInt32 = 0xFFFFFF
    public static let secondaryTextHex: UInt32 = 0xA0A0A0
}

public struct AutoDropSettingsSnapshot: Equatable {
    public var mode: AutoDropMode
    public var numberDelaySeconds: Double
    public var wordDelaySeconds: Double
    public var wordTrigger: WordTriggerMode
    public var keyboardHeightPt: Double
    public var keyFontSize: Double
    public var keyGapMode: KeyGapMode
    public var hapticsEnabled: Bool

    public static let defaultValue = AutoDropSettingsSnapshot(
        mode: .off,
        numberDelaySeconds: 0.5,
        wordDelaySeconds: 0.6,
        wordTrigger: .onPause,
        keyboardHeightPt: 260.0,
        keyFontSize: 19.0,
        keyGapMode: .comfortable,
        hapticsEnabled: true
    )
}

public enum AutoDropConfig {
    public static let numberDelayRange: ClosedRange<Double> = 0.2...1.5
    public static let wordDelayRange: ClosedRange<Double> = 0.3...2.0
    public static let heightPtRange: ClosedRange<Double> = 180.0...340.0
    public static let fontSizeRange: ClosedRange<Double> = 14.0...24.0

    public static let delayPresets: [Double] = [0.2, 0.35, 0.5, 0.7, 1.0, 1.5]
    public static let wordDelayPresets: [Double] = [0.35, 0.5, 0.7, 1.0, 1.5]

    private enum Keys {
        static let mode = "autodrop.mode"
        static let numberDelay = "autodrop.numberDelaySeconds"
        static let wordDelay = "autodrop.wordDelaySeconds"
        static let wordTrigger = "autodrop.wordTrigger"
        static let heightPt = "autodrop.keyboardHeightPt"
        static let keyFontSize = "autodrop.keyFontSize"
        static let keyGapMode = "autodrop.keyGapMode"
        static let hapticsEnabled = "autodrop.hapticsEnabled"
    }

    public static func load() -> AutoDropSettingsSnapshot {
        let defaults = UserDefaults.standard
        let fallback = AutoDropSettingsSnapshot.defaultValue

        let mode = (defaults.string(forKey: Keys.mode).flatMap(AutoDropMode.init(rawValue:)))
            ?? fallback.mode

        let numberDelay: Double
        if defaults.object(forKey: Keys.numberDelay) != nil {
            numberDelay = clamp(defaults.double(forKey: Keys.numberDelay), to: numberDelayRange)
        } else {
            numberDelay = fallback.numberDelaySeconds
        }

        let wordDelay: Double
        if defaults.object(forKey: Keys.wordDelay) != nil {
            wordDelay = clamp(defaults.double(forKey: Keys.wordDelay), to: wordDelayRange)
        } else {
            wordDelay = fallback.wordDelaySeconds
        }

        let wordTrigger = (defaults.string(forKey: Keys.wordTrigger).flatMap(WordTriggerMode.init(rawValue:)))
            ?? fallback.wordTrigger

        let heightPt: Double
        if defaults.object(forKey: Keys.heightPt) != nil {
            heightPt = clamp(defaults.double(forKey: Keys.heightPt), to: heightPtRange)
        } else {
            heightPt = fallback.keyboardHeightPt
        }

        let fontSize: Double
        if defaults.object(forKey: Keys.keyFontSize) != nil {
            fontSize = clamp(defaults.double(forKey: Keys.keyFontSize), to: fontSizeRange)
        } else {
            fontSize = fallback.keyFontSize
        }

        let keyGapMode = (defaults.string(forKey: Keys.keyGapMode).flatMap(KeyGapMode.init(rawValue:)))
            ?? fallback.keyGapMode

        let hapticsEnabled: Bool
        if defaults.object(forKey: Keys.hapticsEnabled) != nil {
            hapticsEnabled = defaults.bool(forKey: Keys.hapticsEnabled)
        } else {
            hapticsEnabled = fallback.hapticsEnabled
        }

        return AutoDropSettingsSnapshot(
            mode: mode,
            numberDelaySeconds: numberDelay,
            wordDelaySeconds: wordDelay,
            wordTrigger: wordTrigger,
            keyboardHeightPt: heightPt,
            keyFontSize: fontSize,
            keyGapMode: keyGapMode,
            hapticsEnabled: hapticsEnabled
        )
    }

    public static func save(_ snapshot: AutoDropSettingsSnapshot) {
        let defaults = UserDefaults.standard
        defaults.set(snapshot.mode.rawValue, forKey: Keys.mode)
        defaults.set(clamp(snapshot.numberDelaySeconds, to: numberDelayRange), forKey: Keys.numberDelay)
        defaults.set(clamp(snapshot.wordDelaySeconds, to: wordDelayRange), forKey: Keys.wordDelay)
        defaults.set(snapshot.wordTrigger.rawValue, forKey: Keys.wordTrigger)
        defaults.set(clamp(snapshot.keyboardHeightPt, to: heightPtRange), forKey: Keys.heightPt)
        defaults.set(clamp(snapshot.keyFontSize, to: fontSizeRange), forKey: Keys.keyFontSize)
        defaults.set(snapshot.keyGapMode.rawValue, forKey: Keys.keyGapMode)
        defaults.set(snapshot.hapticsEnabled, forKey: Keys.hapticsEnabled)
    }

    public static func formatDelayChip(_ seconds: Double) -> String {
        let hundredths = Int((seconds * 100.0).rounded())
        if hundredths % 10 != 0 {
            return String(format: "%.2fs", Double(hundredths) / 100.0)
        }
        return String(format: "%.1fs", Double(hundredths) / 100.0)
    }

    public static func nextPreset(after current: Double, in presets: [Double]) -> Double {
        guard let first = presets.first else { return current }
        for preset in presets where preset > current + 0.015 {
            return preset
        }
        return first
    }

    public static func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
