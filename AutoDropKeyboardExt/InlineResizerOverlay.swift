import UIKit

final class InlineResizerOverlay: UIView {
    var onModeChanged: ((AutoDropMode) -> Void)?
    var onNumberDelayChanged: ((Double) -> Void)?
    var onWordDelayChanged: ((Double) -> Void)?
    var onWordTriggerChanged: ((WordTriggerMode) -> Void)?
    var onHeightPtChanged: ((Double) -> Void)?
    var onFontSizeChanged: ((Double) -> Void)?
    var onGapModeChanged: ((KeyGapMode) -> Void)?
    var onHapticsChanged: ((Bool) -> Void)?
    var onReset: (() -> Void)?
    var onDone: (() -> Void)?

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let resetButton = UIButton(type: .system)
    private let doneButton = UIButton(type: .system)

    private var modeButtons: [AutoDropMode: UIButton] = [:]

    private let numberDelayValueLabel = UILabel()
    private let numberDelaySlider = UISlider()

    private let wordDelayValueLabel = UILabel()
    private let wordDelaySlider = UISlider()

    private let onPauseButton = UIButton(type: .custom)
    private let onSpacebarButton = UIButton(type: .custom)

    private let heightValueLabel = UILabel()
    private let heightSlider = UISlider()

    private let fontValueLabel = UILabel()
    private let fontSlider = UISlider()

    private let tightButton = UIButton(type: .custom)
    private let comfortableButton = UIButton(type: .custom)

    private let hapticsSwitch = UISwitch()
    private let hapticsValueLabel = UILabel()

    private let scrollView = UIScrollView()
    private let controlsStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = AutoDropTheme.toolbarBackground.withAlphaComponent(0.97)
        layer.cornerRadius = 12.0
        layer.cornerCurve = .continuous
        layer.borderWidth = 1.0
        layer.borderColor = UIColor(hex: 0x353535).cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 10.0
        layer.shadowOpacity = 0.45

        titleLabel.text = "Settings"
        titleLabel.font = .systemFont(ofSize: 13.0, weight: .bold)
        titleLabel.textColor = AutoDropTheme.primaryText

        subtitleLabel.text = "Auto-Drop & Size"
        subtitleLabel.font = .systemFont(ofSize: 11.0, weight: .medium)
        subtitleLabel.textColor = AutoDropTheme.secondaryText

        let titleGroup = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleGroup.axis = .horizontal
        titleGroup.alignment = .firstBaseline
        titleGroup.spacing = 6.0

        resetButton.setTitle("Reset", for: .normal)
        resetButton.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .semibold)
        resetButton.setTitleColor(AutoDropTheme.secondaryText, for: .normal)
        resetButton.backgroundColor = AutoDropTheme.specialKey
        resetButton.layer.cornerRadius = 7.0
        resetButton.layer.cornerCurve = .continuous
        resetButton.addTarget(self, action: #selector(handleReset), for: .touchUpInside)
        NSLayoutConstraint.activate([
            resetButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 52.0),
            resetButton.heightAnchor.constraint(equalToConstant: 26.0)
        ])

        doneButton.setTitle("Done", for: .normal)
        doneButton.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .bold)
        doneButton.setTitleColor(AutoDropTheme.primaryText, for: .normal)
        doneButton.backgroundColor = AutoDropTheme.accent
        doneButton.layer.cornerRadius = 7.0
        doneButton.layer.cornerCurve = .continuous
        doneButton.addTarget(self, action: #selector(handleDone), for: .touchUpInside)
        NSLayoutConstraint.activate([
            doneButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 54.0),
            doneButton.heightAnchor.constraint(equalToConstant: 26.0)
        ])

        let headerSpacer = UIView()
        headerSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let headerStack = UIStackView(arrangedSubviews: [titleGroup, headerSpacer, resetButton, doneButton])
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.spacing = 6.0
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.indicatorStyle = .white
        scrollView.alwaysBounceVertical = true

        controlsStack.axis = .vertical
        controlsStack.alignment = .fill
        controlsStack.distribution = .fill
        controlsStack.spacing = 8.0
        controlsStack.translatesAutoresizingMaskIntoConstraints = false

        // 1. Mode Selector (OFF, ABC, 123, WORD)
        let modeLabel = makeRowTitleLabel("Mode")
        let modeSegmentedStack = UIStackView()
        modeSegmentedStack.axis = .horizontal
        modeSegmentedStack.alignment = .fill
        modeSegmentedStack.distribution = .fillEqually
        modeSegmentedStack.spacing = 4.0
        for (index, mode) in AutoDropMode.allCases.enumerated() {
            let btn = UIButton(type: .custom)
            configurePillButton(btn, title: mode.pillTitle, tag: index)
            btn.addTarget(self, action: #selector(handleModeTapped(_:)), for: .touchUpInside)
            modeButtons[mode] = btn
            modeSegmentedStack.addArrangedSubview(btn)
        }
        let modeRow = UIStackView(arrangedSubviews: [modeLabel, modeSegmentedStack])
        modeRow.axis = .horizontal
        modeRow.alignment = .center
        modeRow.spacing = 8.0
        modeRow.heightAnchor.constraint(equalToConstant: 28.0).isActive = true

        // 2. Number Mode Pause Delay Slider (0.2s to 1.5s)
        let numDelayLabel = makeRowTitleLabel("123 Delay")
        configureSlider(
            numberDelaySlider,
            min: Float(AutoDropConfig.numberDelayRange.lowerBound),
            max: Float(AutoDropConfig.numberDelayRange.upperBound)
        )
        numberDelaySlider.addTarget(self, action: #selector(handleNumberDelayChanged), for: .valueChanged)
        configureValueLabel(numberDelayValueLabel)
        let numDelayRow = makeControlRow(label: numDelayLabel, control: numberDelaySlider, valueLabel: numberDelayValueLabel)

        // 3. Word Mode Pause Delay Slider (0.3s to 2.0s)
        let wordDelayLabel = makeRowTitleLabel("Word Delay")
        configureSlider(
            wordDelaySlider,
            min: Float(AutoDropConfig.wordDelayRange.lowerBound),
            max: Float(AutoDropConfig.wordDelayRange.upperBound)
        )
        wordDelaySlider.addTarget(self, action: #selector(handleWordDelayChanged), for: .valueChanged)
        configureValueLabel(wordDelayValueLabel)
        let wordDelayRow = makeControlRow(label: wordDelayLabel, control: wordDelaySlider, valueLabel: wordDelayValueLabel)

        // 4. Word Trigger Toggle (On Pause vs On Spacebar)
        let triggerLabel = makeRowTitleLabel("Trigger")
        configurePillButton(onPauseButton, title: "On Pause", tag: 0)
        configurePillButton(onSpacebarButton, title: "On Spacebar", tag: 1)
        onPauseButton.addTarget(self, action: #selector(handleTriggerTapped(_:)), for: .touchUpInside)
        onSpacebarButton.addTarget(self, action: #selector(handleTriggerTapped(_:)), for: .touchUpInside)

        let triggerStack = UIStackView(arrangedSubviews: [onPauseButton, onSpacebarButton])
        triggerStack.axis = .horizontal
        triggerStack.alignment = .fill
        triggerStack.distribution = .fillEqually
        triggerStack.spacing = 6.0

        let triggerRow = UIStackView(arrangedSubviews: [triggerLabel, triggerStack])
        triggerRow.axis = .horizontal
        triggerRow.alignment = .center
        triggerRow.spacing = 8.0
        triggerRow.heightAnchor.constraint(equalToConstant: 28.0).isActive = true

        // 5. Keyboard Height Slider (180pt to 340pt)
        let heightLabel = makeRowTitleLabel("Height")
        configureSlider(
            heightSlider,
            min: Float(AutoDropConfig.heightPtRange.lowerBound),
            max: Float(AutoDropConfig.heightPtRange.upperBound)
        )
        heightSlider.addTarget(self, action: #selector(handleHeightSliderChanged), for: .valueChanged)
        configureValueLabel(heightValueLabel)
        let heightRow = makeControlRow(label: heightLabel, control: heightSlider, valueLabel: heightValueLabel)

        // 6. Key Font Size Slider (14pt to 24pt)
        let fontLabel = makeRowTitleLabel("Font Size")
        configureSlider(
            fontSlider,
            min: Float(AutoDropConfig.fontSizeRange.lowerBound),
            max: Float(AutoDropConfig.fontSizeRange.upperBound)
        )
        fontSlider.addTarget(self, action: #selector(handleFontSliderChanged), for: .valueChanged)
        fontSlider.addTarget(self, action: #selector(handleFontSliderEnded), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        configureValueLabel(fontValueLabel)
        let fontRow = makeControlRow(label: fontLabel, control: fontSlider, valueLabel: fontValueLabel)

        // 7. Key Gap Toggle (Tight 3pt vs Comfortable 6pt)
        let gapLabel = makeRowTitleLabel("Key Gap")
        configurePillButton(tightButton, title: "Tight (3pt)", tag: 0)
        configurePillButton(comfortableButton, title: "Comfortable (6pt)", tag: 1)
        tightButton.addTarget(self, action: #selector(handleGapTapped(_:)), for: .touchUpInside)
        comfortableButton.addTarget(self, action: #selector(handleGapTapped(_:)), for: .touchUpInside)

        let gapStack = UIStackView(arrangedSubviews: [tightButton, comfortableButton])
        gapStack.axis = .horizontal
        gapStack.alignment = .fill
        gapStack.distribution = .fillEqually
        gapStack.spacing = 6.0

        let gapRow = UIStackView(arrangedSubviews: [gapLabel, gapStack])
        gapRow.axis = .horizontal
        gapRow.alignment = .center
        gapRow.spacing = 8.0
        gapRow.heightAnchor.constraint(equalToConstant: 28.0).isActive = true

        // 8. Haptic Vibration Toggle (ON / OFF)
        let hapticsLabel = makeRowTitleLabel("Haptics")
        hapticsSwitch.onTintColor = AutoDropTheme.accent
        hapticsSwitch.addTarget(self, action: #selector(handleHapticsToggled), for: .valueChanged)

        configureValueLabel(hapticsValueLabel)
        let hapticsSpacer = UIView()
        hapticsSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let hapticsRow = UIStackView(arrangedSubviews: [hapticsLabel, hapticsSpacer, hapticsSwitch, hapticsValueLabel])
        hapticsRow.axis = .horizontal
        hapticsRow.alignment = .center
        hapticsRow.spacing = 8.0
        hapticsRow.heightAnchor.constraint(equalToConstant: 32.0).isActive = true

        [modeRow, numDelayRow, wordDelayRow, triggerRow, heightRow, fontRow, gapRow, hapticsRow].forEach {
            controlsStack.addArrangedSubview($0)
        }

        addSubview(headerStack)
        addSubview(scrollView)
        scrollView.addSubview(controlsStack)

        let desiredScrollHeight = scrollView.heightAnchor.constraint(equalToConstant: 146.0)
        desiredScrollHeight.priority = UILayoutPriority(750)

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: topAnchor, constant: 8.0),
            headerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10.0),
            headerStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10.0),
            headerStack.heightAnchor.constraint(equalToConstant: 28.0),

            scrollView.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 6.0),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10.0),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10.0),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8.0),
            desiredScrollHeight,

            controlsStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            controlsStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            controlsStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            controlsStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -4.0),
            controlsStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    private func makeRowTitleLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 11.5, weight: .medium)
        label.textColor = AutoDropTheme.primaryText
        label.widthAnchor.constraint(equalToConstant: 66.0).isActive = true
        return label
    }

    private func configureValueLabel(_ label: UILabel) {
        label.font = .monospacedDigitSystemFont(ofSize: 11.5, weight: .semibold)
        label.textColor = AutoDropTheme.accent
        label.textAlignment = .right
        label.widthAnchor.constraint(equalToConstant: 44.0).isActive = true
    }

    private func configureSlider(_ slider: UISlider, min: Float, max: Float) {
        slider.minimumValue = min
        slider.maximumValue = max
        slider.minimumTrackTintColor = AutoDropTheme.accent
        slider.maximumTrackTintColor = AutoDropTheme.pressedKey
        slider.thumbTintColor = AutoDropTheme.primaryText
        slider.isContinuous = true
    }

    private func makeControlRow(label: UILabel, control: UIView, valueLabel: UILabel) -> UIStackView {
        let row = UIStackView(arrangedSubviews: [label, control, valueLabel])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8.0
        row.heightAnchor.constraint(equalToConstant: 28.0).isActive = true
        return row
    }

    private func configurePillButton(_ button: UIButton, title: String, tag: Int) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 11.0, weight: .semibold)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.75
        button.layer.cornerRadius = 7.0
        button.layer.cornerCurve = .continuous
        button.tag = tag
        button.heightAnchor.constraint(equalToConstant: 26.0).isActive = true
    }

    func update(with settings: AutoDropSettingsSnapshot) {
        for (mode, button) in modeButtons {
            let isSelected = (mode == settings.mode)
            button.backgroundColor = isSelected ? AutoDropTheme.accent : AutoDropTheme.standardKey
            button.setTitleColor(isSelected ? AutoDropTheme.primaryText : AutoDropTheme.secondaryText, for: .normal)
        }

        let clampedNumDelay = AutoDropConfig.clamp(settings.numberDelaySeconds, to: AutoDropConfig.numberDelayRange)
        numberDelaySlider.value = Float(clampedNumDelay)
        numberDelayValueLabel.text = String(format: "%.2fs", clampedNumDelay)

        let clampedWordDelay = AutoDropConfig.clamp(settings.wordDelaySeconds, to: AutoDropConfig.wordDelayRange)
        wordDelaySlider.value = Float(clampedWordDelay)
        wordDelayValueLabel.text = String(format: "%.2fs", clampedWordDelay)

        let isPauseTrigger = (settings.wordTrigger == .onPause)
        onPauseButton.backgroundColor = isPauseTrigger ? AutoDropTheme.accent : AutoDropTheme.standardKey
        onPauseButton.setTitleColor(isPauseTrigger ? AutoDropTheme.primaryText : AutoDropTheme.secondaryText, for: .normal)
        onSpacebarButton.backgroundColor = isPauseTrigger ? AutoDropTheme.standardKey : AutoDropTheme.accent
        onSpacebarButton.setTitleColor(isPauseTrigger ? AutoDropTheme.secondaryText : AutoDropTheme.primaryText, for: .normal)

        let clampedHeight = AutoDropConfig.clamp(settings.keyboardHeightPt, to: AutoDropConfig.heightPtRange)
        heightSlider.value = Float(clampedHeight)
        heightValueLabel.text = "\(Int(clampedHeight.rounded()))pt"

        let clampedFont = AutoDropConfig.clamp(settings.keyFontSize, to: AutoDropConfig.fontSizeRange)
        fontSlider.value = Float(clampedFont)
        fontValueLabel.text = "\(Int(clampedFont.rounded()))pt"

        let isTight = (settings.keyGapMode == .tight)
        tightButton.backgroundColor = isTight ? AutoDropTheme.accent : AutoDropTheme.standardKey
        tightButton.setTitleColor(isTight ? AutoDropTheme.primaryText : AutoDropTheme.secondaryText, for: .normal)
        comfortableButton.backgroundColor = isTight ? AutoDropTheme.standardKey : AutoDropTheme.accent
        comfortableButton.setTitleColor(isTight ? AutoDropTheme.secondaryText : AutoDropTheme.primaryText, for: .normal)

        hapticsSwitch.isOn = settings.hapticsEnabled
        hapticsValueLabel.text = settings.hapticsEnabled ? "ON" : "OFF"
        hapticsValueLabel.textColor = settings.hapticsEnabled ? AutoDropTheme.accent : AutoDropTheme.secondaryText
    }

    // MARK: - Actions

    @objc private func handleModeTapped(_ sender: UIButton) {
        guard sender.tag >= 0, sender.tag < AutoDropMode.allCases.count else { return }
        onModeChanged?(AutoDropMode.allCases[sender.tag])
    }

    @objc private func handleNumberDelayChanged() {
        let stepped = (Double(numberDelaySlider.value) * 20.0).rounded() / 20.0
        numberDelayValueLabel.text = String(format: "%.2fs", stepped)
        onNumberDelayChanged?(stepped)
    }

    @objc private func handleWordDelayChanged() {
        let stepped = (Double(wordDelaySlider.value) * 20.0).rounded() / 20.0
        wordDelayValueLabel.text = String(format: "%.2fs", stepped)
        onWordDelayChanged?(stepped)
    }

    @objc private func handleTriggerTapped(_ sender: UIButton) {
        let trigger: WordTriggerMode = (sender.tag == 0) ? .onPause : .onSpacebar
        onWordTriggerChanged?(trigger)
    }

    @objc private func handleHeightSliderChanged() {
        let value = Double(heightSlider.value.rounded())
        heightValueLabel.text = "\(Int(value))pt"
        onHeightPtChanged?(value)
    }

    @objc private func handleFontSliderChanged() {
        let value = Double(fontSlider.value.rounded())
        fontValueLabel.text = "\(Int(value))pt"
        onFontSizeChanged?(value)
    }

    @objc private func handleFontSliderEnded() {
        let value = Double(fontSlider.value.rounded())
        fontSlider.setValue(Float(value), animated: true)
        fontValueLabel.text = "\(Int(value))pt"
        onFontSizeChanged?(value)
    }

    @objc private func handleGapTapped(_ sender: UIButton) {
        let mode: KeyGapMode = (sender.tag == 0) ? .tight : .comfortable
        onGapModeChanged?(mode)
    }

    @objc private func handleHapticsToggled() {
        let enabled = hapticsSwitch.isOn
        hapticsValueLabel.text = enabled ? "ON" : "OFF"
        hapticsValueLabel.textColor = enabled ? AutoDropTheme.accent : AutoDropTheme.secondaryText
        onHapticsChanged?(enabled)
    }

    @objc private func handleReset() {
        onReset?()
    }

    @objc private func handleDone() {
        onDone?()
    }
}
