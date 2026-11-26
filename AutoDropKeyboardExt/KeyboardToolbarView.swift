import UIKit

private final class PaddedPillButton: UIButton {
    var horizontalPadding: CGFloat = 10.0

    override var intrinsicContentSize: CGSize {
        let base = super.intrinsicContentSize
        return CGSize(width: base.width + horizontalPadding * 2.0, height: 28.0)
    }
}

final class KeyboardToolbarView: UIView {
    var onSelectMode: ((AutoDropMode) -> Void)?
    var onTapDelayChip: (() -> Void)?
    var onTapResize: (() -> Void)?

    private var modeButtons: [AutoDropMode: PaddedPillButton] = [:]
    private let delayChipButton = PaddedPillButton(type: .custom)
    private let resizeButton = UIButton(type: .system)
    private let bottomHairline = UIView()

    private var activeMode: AutoDropMode = .off

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = AutoDropTheme.toolbarBackground

        heightAnchor.constraint(equalToConstant: 42.0).isActive = true

        let modesStack = UIStackView()
        modesStack.axis = .horizontal
        modesStack.alignment = .center
        modesStack.distribution = .fill
        modesStack.spacing = 4.0
        modesStack.translatesAutoresizingMaskIntoConstraints = false

        for mode in AutoDropMode.allCases {
            let button = PaddedPillButton(type: .custom)
            button.horizontalPadding = 8.0
            button.setTitle(mode.pillTitle, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .bold)
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.titleLabel?.minimumScaleFactor = 0.8
            button.layer.cornerRadius = 8.0
            button.layer.cornerCurve = .continuous
            button.tag = AutoDropMode.allCases.firstIndex(of: mode) ?? 0
            button.setContentHuggingPriority(.required, for: .horizontal)
            button.setContentCompressionResistancePriority(.required, for: .horizontal)
            button.addTarget(self, action: #selector(handleModeTapped(_:)), for: .touchUpInside)
            modeButtons[mode] = button
            modesStack.addArrangedSubview(button)
        }

        delayChipButton.horizontalPadding = 8.0
        delayChipButton.titleLabel?.font = .monospacedDigitSystemFont(ofSize: 11.5, weight: .semibold)
        delayChipButton.backgroundColor = AutoDropTheme.pillInactive
        delayChipButton.setTitleColor(AutoDropTheme.primaryText, for: .normal)
        delayChipButton.layer.cornerRadius = 8.0
        delayChipButton.layer.cornerCurve = .continuous
        delayChipButton.layer.borderWidth = 1.0
        delayChipButton.layer.borderColor = UIColor(hex: 0x343434).cgColor
        delayChipButton.setContentHuggingPriority(.required, for: .horizontal)
        delayChipButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        delayChipButton.addTarget(self, action: #selector(handleDelayTapped), for: .touchUpInside)
        delayChipButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 42.0).isActive = true

        resizeButton.translatesAutoresizingMaskIntoConstraints = false
        resizeButton.backgroundColor = AutoDropTheme.pillInactive
        resizeButton.tintColor = AutoDropTheme.primaryText
        resizeButton.layer.cornerRadius = 8.0
        resizeButton.layer.cornerCurve = .continuous
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 13.5, weight: .semibold)
        resizeButton.setImage(UIImage(systemName: "gearshape.fill", withConfiguration: iconConfig), for: .normal)
        resizeButton.addTarget(self, action: #selector(handleResizeTapped), for: .touchUpInside)
        NSLayoutConstraint.activate([
            resizeButton.widthAnchor.constraint(equalToConstant: 32.0),
            resizeButton.heightAnchor.constraint(equalToConstant: 28.0)
        ])

        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let rightStack = UIStackView(arrangedSubviews: [delayChipButton, resizeButton])
        rightStack.axis = .horizontal
        rightStack.alignment = .center
        rightStack.spacing = 6.0
        rightStack.translatesAutoresizingMaskIntoConstraints = false

        let mainStack = UIStackView(arrangedSubviews: [modesStack, spacer, rightStack])
        mainStack.axis = .horizontal
        mainStack.alignment = .center
        mainStack.distribution = .fill
        mainStack.spacing = 6.0
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        bottomHairline.translatesAutoresizingMaskIntoConstraints = false
        bottomHairline.backgroundColor = AutoDropTheme.divider

        addSubview(mainStack)
        addSubview(bottomHairline)

        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6.0),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6.0),
            mainStack.topAnchor.constraint(equalTo: topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor),

            bottomHairline.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomHairline.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomHairline.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomHairline.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }

    func update(with settings: AutoDropSettingsSnapshot, isResizerOpen: Bool) {
        activeMode = settings.mode

        for (mode, button) in modeButtons {
            let isSelected = (mode == settings.mode)
            button.backgroundColor = isSelected ? AutoDropTheme.accent : AutoDropTheme.pillInactive
            button.setTitleColor(
                isSelected ? AutoDropTheme.primaryText : AutoDropTheme.secondaryText,
                for: .normal
            )
        }

        switch settings.mode {
        case .number123:
            delayChipButton.setTitle(AutoDropConfig.formatDelayChip(settings.numberDelaySeconds), for: .normal)
            delayChipButton.setTitleColor(AutoDropTheme.primaryText, for: .normal)
            delayChipButton.alpha = 1.0
        case .word:
            if settings.wordTrigger == .onSpacebar {
                delayChipButton.setTitle("SPC", for: .normal)
                delayChipButton.setTitleColor(AutoDropTheme.accent, for: .normal)
                delayChipButton.alpha = 1.0
            } else {
                delayChipButton.setTitle(AutoDropConfig.formatDelayChip(settings.wordDelaySeconds), for: .normal)
                delayChipButton.setTitleColor(AutoDropTheme.primaryText, for: .normal)
                delayChipButton.alpha = 1.0
            }
        case .off, .abc:
            delayChipButton.setTitle(AutoDropConfig.formatDelayChip(settings.numberDelaySeconds), for: .normal)
            delayChipButton.setTitleColor(AutoDropTheme.secondaryText, for: .normal)
            delayChipButton.alpha = 0.72
        }

        resizeButton.backgroundColor = isResizerOpen ? AutoDropTheme.accent : AutoDropTheme.pillInactive
        resizeButton.tintColor = AutoDropTheme.primaryText
    }

    func flashActiveModePill() {
        guard let pill = modeButtons[activeMode] else { return }
        pill.layer.removeAllAnimations()
        pill.layer.shadowColor = AutoDropTheme.accent.cgColor
        pill.layer.shadowOffset = .zero
        pill.layer.shadowRadius = 10.0
        pill.layer.shadowOpacity = 0.95
        pill.layer.masksToBounds = false

        let restColor = AutoDropTheme.accent
        UIView.animate(
            withDuration: 0.075,
            delay: 0,
            options: [.allowUserInteraction, .beginFromCurrentState]
        ) {
            pill.backgroundColor = AutoDropTheme.accentFlash
            pill.transform = CGAffineTransform(scaleX: 1.12, y: 1.12)
        } completion: { _ in
            UIView.animate(
                withDuration: 0.075,
                delay: 0,
                options: [.allowUserInteraction, .beginFromCurrentState]
            ) {
                pill.backgroundColor = restColor
                pill.transform = .identity
                pill.layer.shadowOpacity = 0.0
            }
        }
    }

    @objc private func handleModeTapped(_ sender: UIButton) {
        guard sender.tag >= 0, sender.tag < AutoDropMode.allCases.count else { return }
        onSelectMode?(AutoDropMode.allCases[sender.tag])
    }

    @objc private func handleDelayTapped() {
        onTapDelayChip?()
    }

    @objc private func handleResizeTapped() {
        onTapResize?()
    }
}
