import Foundation
import Combine

final class SettingsStore: ObservableObject {
    @Published var numberDelayMs: Double {
        didSet { persistHostSettings() }
    }
    @Published var wordDelayMs: Double {
        didSet { persistHostSettings() }
    }
    @Published var wordTrigger: WordTriggerMode {
        didSet { persistHostSettings() }
    }
    @Published var hapticsEnabled: Bool {
        didSet { persistHostSettings() }
    }

    @Published private(set) var activeMode: AutoDropMode
    @Published private(set) var keyboardHeightScale: Double
    @Published private(set) var keyFontSize: Double
    @Published private(set) var keyGapMode: KeyGapMode

    private var isReloading = false
    private var observer: NSObjectProtocol?

    init() {
        let initial = AutoDropConfig.load()
        self.numberDelayMs = (initial.numberDelaySeconds * 1000.0).rounded()
        self.wordDelayMs = (initial.wordDelaySeconds * 1000.0).rounded()
        self.wordTrigger = initial.wordTrigger
        self.hapticsEnabled = initial.hapticsEnabled
        self.activeMode = initial.mode
        self.keyboardHeightScale = initial.keyboardHeightScale
        self.keyFontSize = initial.keyFontSize
        self.keyGapMode = initial.keyGapMode

        AutoDropDarwinSync.startObserving()
        observer = NotificationCenter.default.addObserver(
            forName: .autoDropSettingsDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reload()
        }
    }

    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func reload() {
        let snapshot = AutoDropConfig.load()
        isReloading = true
        defer { isReloading = false }

        let loadedNumMs = (snapshot.numberDelaySeconds * 1000.0).rounded()
        let loadedWordMs = (snapshot.wordDelaySeconds * 1000.0).rounded()

        if abs(numberDelayMs - loadedNumMs) > 1.0 {
            numberDelayMs = loadedNumMs
        }
        if abs(wordDelayMs - loadedWordMs) > 1.0 {
            wordDelayMs = loadedWordMs
        }
        if wordTrigger != snapshot.wordTrigger {
            wordTrigger = snapshot.wordTrigger
        }
        if hapticsEnabled != snapshot.hapticsEnabled {
            hapticsEnabled = snapshot.hapticsEnabled
        }
        if activeMode != snapshot.mode {
            activeMode = snapshot.mode
        }
        if abs(keyboardHeightScale - snapshot.keyboardHeightScale) > 0.005 {
            keyboardHeightScale = snapshot.keyboardHeightScale
        }
        if abs(keyFontSize - snapshot.keyFontSize) > 0.1 {
            keyFontSize = snapshot.keyFontSize
        }
        if keyGapMode != snapshot.keyGapMode {
            keyGapMode = snapshot.keyGapMode
        }
    }

    private func persistHostSettings() {
        guard !isReloading else { return }
        var snapshot = AutoDropConfig.load()
        snapshot.numberDelaySeconds = AutoDropConfig.clamp(
            numberDelayMs / 1000.0,
            to: AutoDropConfig.numberDelayRange
        )
        snapshot.wordDelaySeconds = AutoDropConfig.clamp(
            wordDelayMs / 1000.0,
            to: AutoDropConfig.wordDelayRange
        )
        snapshot.wordTrigger = wordTrigger
        snapshot.hapticsEnabled = hapticsEnabled
        AutoDropConfig.save(snapshot, notify: true)
    }
}
