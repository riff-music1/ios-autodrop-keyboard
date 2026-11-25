import UIKit

enum KeyboardShiftState {
    case lowercase
    case uppercase
    case capsLock

    var isUppercase: Bool {
        self != .lowercase
    }
}

enum KeyAction {
    case character(String)
    case shift
    case backspace
    case space
    case dropReturn
    case switchToSymbols
    case switchToSecondarySymbols
    case switchToLetters
    case globe
}

enum KeyVisualStyle {
    case standard
    case numpadDigit
    case special
    case accent
}

final class KeyButton: UIButton {
    var action: KeyAction
    let style: KeyVisualStyle
    let lowercaseChar: String?
    let uppercaseChar: String?
    private var symbolName: String?

    private var normalBgColor: UIColor
    private var pressedBgColor: UIColor
    private var isKeyPressed = false

    init(
        action: KeyAction,
        style: KeyVisualStyle,
        title: String? = nil,
        lowercaseChar: String? = nil,
        uppercaseChar: String? = nil,
        symbolName: String? = nil,
        fontSize: CGFloat = 19.0
    ) {
        self.action = action
        self.style = style
        self.lowercaseChar = lowercaseChar
        self.uppercaseChar = uppercaseChar
        self.symbolName = symbolName

        switch style {
        case .standard, .numpadDigit:
            self.normalBgColor = AutoDropTheme.standardKey
            self.pressedBgColor = AutoDropTheme.pressedKey
        case .special:
            self.normalBgColor = AutoDropTheme.specialKey
            self.pressedBgColor = AutoDropTheme.pressedKey
        case .accent:
            self.normalBgColor = AutoDropTheme.accent
            self.pressedBgColor = AutoDropTheme.accentPressed
        }

        super.init(frame: .zero)
        setupAppearance(title: title, symbolName: symbolName, fontSize: fontSize)
        setupTouchVisuals()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupAppearance(title: String?, symbolName: String?, fontSize: CGFloat) {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = normalBgColor
        layer.cornerRadius = 8.0
        layer.cornerCurve = .continuous
        clipsToBounds = true
        isExclusiveTouch = false

        titleLabel?.adjustsFontSizeToFitWidth = true
        titleLabel?.minimumScaleFactor = 0.6
        titleLabel?.lineBreakMode = .byClipping
        titleLabel?.textAlignment = .center

        setTitleColor(AutoDropTheme.primaryText, for: .normal)
        tintColor = AutoDropTheme.primaryText

        if let title = title {
            setTitle(title, for: .normal)
        }

        updateFontSize(fontSize)
        if let symbolName = symbolName {
            setSymbol(symbolName, fontSize: fontSize)
        }
    }

    private func setupTouchVisuals() {
        addTarget(self, action: #selector(handlePressDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(handlePressRelease), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
    }

    func applyCase(uppercase: Bool) {
        guard let lower = lowercaseChar, let upper = uppercaseChar else { return }
        let char = uppercase ? upper : lower
        action = .character(char)
        setTitle(char, for: .normal)
    }

    func applyShiftVisualState(_ state: KeyboardShiftState, fontSize: CGFloat) {
        switch state {
        case .lowercase:
            normalBgColor = AutoDropTheme.specialKey
            pressedBgColor = AutoDropTheme.pressedKey
            tintColor = AutoDropTheme.primaryText
            setSymbol("shift", fontSize: fontSize)
        case .uppercase:
            normalBgColor = AutoDropTheme.pressedKey
            pressedBgColor = AutoDropTheme.specialKey
            tintColor = AutoDropTheme.accent
            setSymbol("shift.fill", fontSize: fontSize)
        case .capsLock:
            normalBgColor = AutoDropTheme.accent
            pressedBgColor = AutoDropTheme.accentPressed
            tintColor = AutoDropTheme.primaryText
            setSymbol("capslock.fill", fontSize: fontSize)
        }
        if !isKeyPressed {
            layer.removeAllAnimations()
            backgroundColor = normalBgColor
            transform = .identity
        }
    }

    func updateFontSize(_ pointSize: CGFloat) {
        switch style {
        case .standard:
            titleLabel?.font = .systemFont(ofSize: pointSize, weight: .regular)
        case .numpadDigit:
            titleLabel?.font = .systemFont(ofSize: pointSize, weight: .medium)
        case .special:
            let scaled = max(11.0, (pointSize * 0.72).rounded())
            titleLabel?.font = .systemFont(ofSize: scaled, weight: .medium)
        case .accent:
            let scaled = max(12.0, (pointSize * 0.76).rounded())
            titleLabel?.font = .systemFont(ofSize: scaled, weight: .semibold)
        }

        if let symbolName = symbolName {
            setSymbol(symbolName, fontSize: pointSize)
        }
    }

    private func setSymbol(_ name: String, fontSize: CGFloat) {
        self.symbolName = name
        let symbolPointSize = max(14.0, (fontSize * 0.90).rounded())
        let config = UIImage.SymbolConfiguration(pointSize: symbolPointSize, weight: .medium)
        setImage(UIImage(systemName: name, withConfiguration: config), for: .normal)
    }

    @objc private func handlePressDown() {
        guard !isKeyPressed else { return }
        isKeyPressed = true
        UIView.animate(
            withDuration: 0.05,
            delay: 0,
            options: [.allowUserInteraction, .beginFromCurrentState]
        ) {
            self.backgroundColor = self.pressedBgColor
            self.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
        }
    }

    @objc private func handlePressRelease() {
        guard isKeyPressed else { return }
        isKeyPressed = false
        UIView.animate(
            withDuration: 0.10,
            delay: 0,
            options: [.allowUserInteraction, .beginFromCurrentState]
        ) {
            self.backgroundColor = self.normalBgColor
            self.transform = .identity
        }
    }
}
