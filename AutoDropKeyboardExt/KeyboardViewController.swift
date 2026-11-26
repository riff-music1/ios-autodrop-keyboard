import UIKit

final class KeyboardViewController: UIInputViewController {
    private var settings: AutoDropSettingsSnapshot = AutoDropConfig.load()
    private var shiftState: KeyboardShiftState = .lowercase
    private var lastShiftTapTime: TimeInterval = 0
    private var isResizerOpen = false
    private var hasPendingWordChars = false

    private var debounceTimer: Timer?
    private var backspaceDelayTimer: Timer?
    private var backspaceRepeatTimer: Timer?
    private var backspaceRepeatCount = 0

    private var heightConstraint: NSLayoutConstraint?
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)

    private var toolbarView: KeyboardToolbarView!
    private var layoutContainer: KeyboardLayoutContainer!
    private var resizerOverlay: InlineResizerOverlay!

    deinit {
        cancelAllTimers()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = AutoDropTheme.background
        if let keyboardInputView = inputView {
            keyboardInputView.backgroundColor = AutoDropTheme.background
            keyboardInputView.allowsSelfSizing = true
        }

        setupViews()
        setupHeightConstraint()
        applyLoadedSettings(syncPageForMode: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadSettingsFromDisk()
        layoutContainer.updateGlobeVisibility(needsInputModeSwitchKey)
        updateKeyboardHeight()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancelAllTimers()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutContainer.updateGlobeVisibility(needsInputModeSwitchKey)
        updateKeyboardHeight(layoutNow: false)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateKeyboardHeight(layoutNow: false)
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        layoutContainer.updateGlobeVisibility(needsInputModeSwitchKey)
        if textDocumentProxy.documentContextBeforeInput != nil && !hasNonEmptyLineBeforeCursor() {
            hasPendingWordChars = false
            cancelDebounceTimer()
        }
    }

    // MARK: - Setup

    private func setupViews() {
        toolbarView = KeyboardToolbarView()
        toolbarView.onSelectMode = { [weak self] mode in
            self?.selectMode(mode)
        }
        toolbarView.onTapDelayChip = { [weak self] in
            self?.cycleDelayPreset()
        }
        toolbarView.onTapResize = { [weak self] in
            self?.toggleResizerOverlay()
        }

        layoutContainer = KeyboardLayoutContainer(
            fontSize: CGFloat(settings.keyFontSize),
            gap: CGFloat(settings.keyGapMode.spacing),
            needsGlobe: needsInputModeSwitchKey
        ) { [weak self] button in
            self?.wireKeyButton(button)
        }

        resizerOverlay = InlineResizerOverlay()
        resizerOverlay.isHidden = true
        resizerOverlay.alpha = 0.0
        resizerOverlay.onModeChanged = { [weak self] mode in
            self?.selectMode(mode)
        }
        resizerOverlay.onNumberDelayChanged = { [weak self] seconds in
            guard let self = self else { return }
            self.settings.numberDelaySeconds = AutoDropConfig.clamp(seconds, to: AutoDropConfig.numberDelayRange)
            AutoDropConfig.save(self.settings)
            self.toolbarView.update(with: self.settings, isResizerOpen: self.isResizerOpen)
        }
        resizerOverlay.onWordDelayChanged = { [weak self] seconds in
            guard let self = self else { return }
            self.settings.wordDelaySeconds = AutoDropConfig.clamp(seconds, to: AutoDropConfig.wordDelayRange)
            AutoDropConfig.save(self.settings)
            self.toolbarView.update(with: self.settings, isResizerOpen: self.isResizerOpen)
        }
        resizerOverlay.onWordTriggerChanged = { [weak self] trigger in
            guard let self = self else { return }
            self.playHaptic(.light)
            self.settings.wordTrigger = trigger
            AutoDropConfig.save(self.settings)
            self.resizerOverlay.update(with: self.settings)
            self.toolbarView.update(with: self.settings, isResizerOpen: self.isResizerOpen)
        }
        resizerOverlay.onHeightPtChanged = { [weak self] heightPt in
            guard let self = self else { return }
            self.settings.keyboardHeightPt = AutoDropConfig.clamp(heightPt, to: AutoDropConfig.heightPtRange)
            self.updateKeyboardHeight()
            AutoDropConfig.save(self.settings)
        }
        resizerOverlay.onFontSizeChanged = { [weak self] fontSize in
            guard let self = self else { return }
            self.settings.keyFontSize = AutoDropConfig.clamp(fontSize, to: AutoDropConfig.fontSizeRange)
            self.layoutContainer.updateFontSize(CGFloat(self.settings.keyFontSize), shiftState: self.shiftState)
            AutoDropConfig.save(self.settings)
        }
        resizerOverlay.onGapModeChanged = { [weak self] gapMode in
            guard let self = self else { return }
            self.playHaptic(.light)
            self.settings.keyGapMode = gapMode
            self.layoutContainer.updateGap(CGFloat(gapMode.spacing))
            self.resizerOverlay.update(with: self.settings)
            AutoDropConfig.save(self.settings)
        }
        resizerOverlay.onHapticsChanged = { [weak self] enabled in
            guard let self = self else { return }
            self.settings.hapticsEnabled = enabled
            AutoDropConfig.save(self.settings)
            if enabled {
                self.playHaptic(.light)
            }
        }
        resizerOverlay.onReset = { [weak self] in
            self?.resetAllSettings()
        }
        resizerOverlay.onDone = { [weak self] in
            self?.setResizerOverlayVisible(false)
        }

        view.addSubview(toolbarView)
        view.addSubview(layoutContainer.rootView)
        view.addSubview(resizerOverlay)

        let safeGuide = view.safeAreaLayoutGuide

        let overlayBottomLimit = resizerOverlay.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -4.0)
        overlayBottomLimit.priority = .required

        NSLayoutConstraint.activate([
            toolbarView.topAnchor.constraint(equalTo: view.topAnchor),
            toolbarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            layoutContainer.rootView.topAnchor.constraint(equalTo: toolbarView.bottomAnchor, constant: 6.0),
            layoutContainer.rootView.leadingAnchor.constraint(equalTo: safeGuide.leadingAnchor, constant: 4.0),
            layoutContainer.rootView.trailingAnchor.constraint(equalTo: safeGuide.trailingAnchor, constant: -4.0),
            layoutContainer.rootView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -4.0),

            resizerOverlay.topAnchor.constraint(equalTo: view.topAnchor, constant: 4.0),
            resizerOverlay.leadingAnchor.constraint(equalTo: safeGuide.leadingAnchor, constant: 4.0),
            resizerOverlay.trailingAnchor.constraint(equalTo: safeGuide.trailingAnchor, constant: -4.0),
            overlayBottomLimit
        ])
    }

    private func setupHeightConstraint() {
        let constraint = view.heightAnchor.constraint(equalToConstant: targetKeyboardHeight())
        constraint.priority = UILayoutPriority(999)
        constraint.isActive = true
        heightConstraint = constraint
    }

    private func targetKeyboardHeight() -> CGFloat {
        let portraitPt = CGFloat(AutoDropConfig.clamp(settings.keyboardHeightPt, to: AutoDropConfig.heightPtRange))
        if isLandscapeOrientation() {
            let screenHeight = UIScreen.main.bounds.height
            let scaled = (portraitPt * 0.68).rounded()
            return min(max(120.0, scaled), max(160.0, screenHeight * 0.56))
        }
        return portraitPt.rounded()
    }

    private func isLandscapeOrientation() -> Bool {
        if traitCollection.verticalSizeClass == .compact {
            return true
        }
        if let orientation = view.window?.windowScene?.interfaceOrientation {
            return orientation.isLandscape
        }
        let screenSize = UIScreen.main.bounds.size
        return screenSize.width > screenSize.height
    }

    private func updateKeyboardHeight(layoutNow: Bool = true) {
        let newHeight = targetKeyboardHeight()
        if let constraint = heightConstraint, abs(constraint.constant - newHeight) > 0.5 {
            constraint.constant = newHeight
            if layoutNow {
                view.layoutIfNeeded()
            }
        }
    }

    // MARK: - Settings Sync

    private func reloadSettingsFromDisk() {
        let loaded = AutoDropConfig.load()
        let modeChanged = (loaded.mode != settings.mode)
        settings = loaded
        applyLoadedSettings(syncPageForMode: modeChanged)
    }

    private func applyLoadedSettings(syncPageForMode: Bool) {
        toolbarView.update(with: settings, isResizerOpen: isResizerOpen)
        resizerOverlay.update(with: settings)
        layoutContainer.updateFontSize(CGFloat(settings.keyFontSize), shiftState: shiftState)
        layoutContainer.updateGap(CGFloat(settings.keyGapMode.spacing))
        updateKeyboardHeight()

        if syncPageForMode {
            if settings.mode == .number123 {
                layoutContainer.showPage(.numpad)
            } else {
                layoutContainer.showPage(.qwerty)
            }
        }
    }

    // MARK: - Key Wiring

    private func wireKeyButton(_ button: KeyButton) {
        switch button.action {
        case .globe:
            button.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
            button.addTarget(self, action: #selector(handleTouchDownHaptic(_:)), for: .touchDown)
        case .backspace:
            button.addTarget(self, action: #selector(handleBackspaceTouchDown(_:)), for: .touchDown)
            button.addTarget(
                self,
                action: #selector(handleBackspaceTouchEnd(_:)),
                for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit]
            )
        default:
            button.addTarget(self, action: #selector(handleTouchDownHaptic(_:)), for: .touchDown)
            button.addTarget(self, action: #selector(handleKeyTouchUpInside(_:)), for: .touchUpInside)
        }
    }

    // MARK: - Toolbar Actions

    private func selectMode(_ mode: AutoDropMode) {
        playHaptic(.light)
        cancelDebounceTimer()
        hasPendingWordChars = false

        settings.mode = mode
        AutoDropConfig.save(settings)

        switch mode {
        case .number123:
            layoutContainer.showPage(.numpad)
        case .off, .abc, .word:
            layoutContainer.showPage(.qwerty)
        }

        toolbarView.update(with: settings, isResizerOpen: isResizerOpen)
        resizerOverlay.update(with: settings)
    }

    private func cycleDelayPreset() {
        playHaptic(.light)
        switch settings.mode {
        case .number123, .off, .abc:
            let next = AutoDropConfig.nextPreset(
                after: settings.numberDelaySeconds,
                in: AutoDropConfig.delayPresets
            )
            settings.numberDelaySeconds = next
        case .word:
            if settings.wordTrigger == .onSpacebar {
                settings.wordTrigger = .onPause
            } else {
                let next = AutoDropConfig.nextPreset(
                    after: settings.wordDelaySeconds,
                    in: AutoDropConfig.wordDelayPresets
                )
                settings.wordDelaySeconds = next
            }
        }
        AutoDropConfig.save(settings)
        toolbarView.update(with: settings, isResizerOpen: isResizerOpen)
        resizerOverlay.update(with: settings)
    }

    private func toggleResizerOverlay() {
        playHaptic(.light)
        setResizerOverlayVisible(!isResizerOpen)
    }

    private func setResizerOverlayVisible(_ visible: Bool) {
        isResizerOpen = visible
        toolbarView.update(with: settings, isResizerOpen: isResizerOpen)

        if visible {
            resizerOverlay.update(with: settings)
            resizerOverlay.isHidden = false
            resizerOverlay.transform = CGAffineTransform(translationX: 0, y: -6.0)
            UIView.animate(withDuration: 0.16, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
                self.resizerOverlay.alpha = 1.0
                self.resizerOverlay.transform = .identity
            }
        } else {
            UIView.animate(withDuration: 0.14, delay: 0, options: [.curveEaseIn, .allowUserInteraction]) {
                self.resizerOverlay.alpha = 0.0
                self.resizerOverlay.transform = CGAffineTransform(translationX: 0, y: -6.0)
            } completion: { _ in
                if !self.isResizerOpen {
                    self.resizerOverlay.isHidden = true
                    self.resizerOverlay.transform = .identity
                }
            }
        }
    }

    private func resetAllSettings() {
        let defaults = AutoDropSettingsSnapshot.defaultValue
        settings.numberDelaySeconds = defaults.numberDelaySeconds
        settings.wordDelaySeconds = defaults.wordDelaySeconds
        settings.wordTrigger = defaults.wordTrigger
        settings.keyboardHeightPt = defaults.keyboardHeightPt
        settings.keyFontSize = defaults.keyFontSize
        settings.keyGapMode = defaults.keyGapMode
        settings.hapticsEnabled = defaults.hapticsEnabled

        AutoDropConfig.save(settings)
        playHaptic(.medium)

        toolbarView.update(with: settings, isResizerOpen: isResizerOpen)
        resizerOverlay.update(with: settings)
        layoutContainer.updateFontSize(CGFloat(settings.keyFontSize), shiftState: shiftState)
        layoutContainer.updateGap(CGFloat(settings.keyGapMode.spacing))
        updateKeyboardHeight()
    }

    // MARK: - Key Input Handling

    @objc private func handleTouchDownHaptic(_ sender: KeyButton) {
        switch sender.action {
        case .dropReturn:
            playHaptic(.medium)
        default:
            playHaptic(.light)
        }
    }

    @objc private func handleKeyTouchUpInside(_ sender: KeyButton) {
        switch sender.action {
        case .character(let char):
            handleCharacterInput(char)
        case .shift:
            handleShiftTap()
        case .space:
            handleSpaceTap()
        case .dropReturn:
            handleDropReturnTap()
        case .switchToSymbols:
            layoutContainer.showPage(.symbols)
        case .switchToSecondarySymbols:
            layoutContainer.showPage(.secondarySymbols)
        case .switchToLetters:
            handleSwitchToLetters()
        case .backspace, .globe:
            break
        }
    }

    private func handleCharacterInput(_ char: String) {
        textDocumentProxy.insertText(char)

        if shiftState == .uppercase && layoutContainer.currentPage == .qwerty {
            shiftState = .lowercase
            layoutContainer.updateShiftState(.lowercase, fontSize: CGFloat(settings.keyFontSize))
        }

        switch settings.mode {
        case .off:
            break
        case .abc:
            if isAsciiLetter(char) {
                hasPendingWordChars = false
                triggerAutoDrop()
            }
        case .number123:
            hasPendingWordChars = true
            resetDebounceTimer(delay: settings.numberDelaySeconds)
        case .word:
            hasPendingWordChars = true
            if settings.wordTrigger == .onPause {
                resetDebounceTimer(delay: settings.wordDelaySeconds)
            }
        }
    }

    private func handleShiftTap() {
        let now = Date.timeIntervalSinceReferenceDate
        switch shiftState {
        case .lowercase:
            shiftState = .uppercase
        case .uppercase:
            if (now - lastShiftTapTime) <= 0.35 {
                shiftState = .capsLock
            } else {
                shiftState = .lowercase
            }
        case .capsLock:
            shiftState = .lowercase
        }
        lastShiftTapTime = now
        layoutContainer.updateShiftState(shiftState, fontSize: CGFloat(settings.keyFontSize))
    }

    private func handleSpaceTap() {
        switch settings.mode {
        case .word:
            if settings.wordTrigger == .onSpacebar {
                if hasWordBeforeCursor() {
                    hasPendingWordChars = false
                    triggerAutoDrop()
                } else {
                    textDocumentProxy.insertText(" ")
                }
            } else {
                textDocumentProxy.insertText(" ")
                if hasPendingWordChars || hasNonEmptyLineBeforeCursor() {
                    resetDebounceTimer(delay: settings.wordDelaySeconds)
                }
            }
        case .number123:
            textDocumentProxy.insertText(" ")
            if hasPendingWordChars || hasNonEmptyLineBeforeCursor() {
                resetDebounceTimer(delay: settings.numberDelaySeconds)
            }
        case .off, .abc:
            textDocumentProxy.insertText(" ")
        }
    }

    private func handleDropReturnTap() {
        cancelDebounceTimer()
        hasPendingWordChars = false

        if settings.mode == .off {
            textDocumentProxy.insertText("\n")
        } else {
            triggerAutoDrop()
        }
    }

    private func handleSwitchToLetters() {
        if settings.mode == .number123 && layoutContainer.currentPage == .numpad {
            cancelDebounceTimer()
            hasPendingWordChars = false
            settings.mode = .off
            AutoDropConfig.save(settings)
            toolbarView.update(with: settings, isResizerOpen: isResizerOpen)
            resizerOverlay.update(with: settings)
        }
        layoutContainer.showPage(.qwerty)
    }

    // MARK: - Backspace & Hold-to-Delete

    @objc private func handleBackspaceTouchDown(_ sender: KeyButton) {
        playHaptic(.light)
        performBackspaceStep()

        cancelBackspaceTimers()
        backspaceRepeatCount = 0

        backspaceDelayTimer = Timer.scheduledTimer(withTimeInterval: 0.42, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.backspaceRepeatTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.backspaceRepeatCount += 1
                self.performBackspaceStep()
                if self.backspaceRepeatCount == 12 {
                    self.accelerateBackspaceRepeat()
                }
            }
        }
    }

    @objc private func handleBackspaceTouchEnd(_ sender: KeyButton) {
        cancelBackspaceTimers()
    }

    private func accelerateBackspaceRepeat() {
        backspaceRepeatTimer?.invalidate()
        backspaceRepeatTimer = Timer.scheduledTimer(withTimeInterval: 0.045, repeats: true) { [weak self] _ in
            self?.performBackspaceStep()
        }
    }

    private func performBackspaceStep() {
        textDocumentProxy.deleteBackward()

        if !hasNonEmptyLineBeforeCursor() {
            hasPendingWordChars = false
            cancelDebounceTimer()
        } else if debounceTimer != nil {
            switch settings.mode {
            case .number123:
                resetDebounceTimer(delay: settings.numberDelaySeconds)
            case .word where settings.wordTrigger == .onPause:
                resetDebounceTimer(delay: settings.wordDelaySeconds)
            default:
                break
            }
        }
    }

    // MARK: - Smart Auto-Drop Engine

    func triggerAutoDrop() {
        cancelDebounceTimer()
        hasPendingWordChars = false
        textDocumentProxy.insertText("\n")
        toolbarView.flashActiveModePill()
    }

    private func resetDebounceTimer(delay: TimeInterval) {
        cancelDebounceTimer()
        let clampedDelay = max(0.05, delay)
        debounceTimer = Timer.scheduledTimer(withTimeInterval: clampedDelay, repeats: false) { [weak self] _ in
            self?.triggerAutoDrop()
        }
    }

    private func cancelDebounceTimer() {
        debounceTimer?.invalidate()
        debounceTimer = nil
    }

    private func cancelBackspaceTimers() {
        backspaceDelayTimer?.invalidate()
        backspaceDelayTimer = nil
        backspaceRepeatTimer?.invalidate()
        backspaceRepeatTimer = nil
        backspaceRepeatCount = 0
    }

    private func cancelAllTimers() {
        cancelDebounceTimer()
        cancelBackspaceTimers()
    }

    // MARK: - Helpers

    private func isAsciiLetter(_ text: String) -> Bool {
        guard text.unicodeScalars.count == 1, let scalar = text.unicodeScalars.first else {
            return false
        }
        return (65...90).contains(scalar.value) || (97...122).contains(scalar.value)
    }

    private func hasWordBeforeCursor() -> Bool {
        if let before = textDocumentProxy.documentContextBeforeInput, let lastChar = before.last {
            return !lastChar.isWhitespace && !lastChar.isNewline
        }
        return hasPendingWordChars
    }

    private func hasNonEmptyLineBeforeCursor() -> Bool {
        guard let before = textDocumentProxy.documentContextBeforeInput, !before.isEmpty else {
            return false
        }
        let currentLine = before.split(separator: "\n", omittingEmptySubsequences: false).last ?? ""
        return !currentLine.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func playHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard settings.hapticsEnabled else { return }
        switch style {
        case .medium:
            impactMedium.prepare()
            impactMedium.impactOccurred()
        default:
            impactLight.prepare()
            impactLight.impactOccurred()
        }
    }
}
