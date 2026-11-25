import UIKit

final class InlineResizerOverlay: UIView {
    var onHeightScaleChanged: ((Double, Bool) -> Void)?
    var onFontSizeChanged: ((Double, Bool) -> Void)?
    var onGapModeChanged: ((KeyGapMode) -> Void)?
    var onReset: (() -> Void)?
    var onDone: (() -> Void)?

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let resetButton = UIButton(type: .system)
    private let doneButton = UIButton(type: .system)

    private let heightValueLabel = UILabel()
    private let heightSlider = UISlider()

    private let fontValueLabel = UILabel()
    private let fontSlider = UISlider()

    private let tightButton = UIButton(type: .custom)
    private let comfortableButton = UIButton(type: .custom)

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
        backgroundColor = AutoDropTheme.toolbarBackground.withAlphaComponent(0.98)
        layer.cornerRadius = 12.0
        layer.cornerCurve = .continuous
        layer.borderWidth = 1.0
        layer.borderColor = UIColor(hex: 0x333333).cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 10.0
        layer.shadowOpacity = 0.45

        titleLabel.text = "Resize"
        titleLabel.font = .systemFont(ofSize: 13.0, weight: .bold)
        titleLabel.textColor = AutoDropTheme.primaryText

        subtitleLabel.text = "Compact / Tall"
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
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = false

        controlsStack.axis = .vertical
        controlsStack.alignment = .fill
        controlsStack.distribution = .fill
        controlsStack.spacing = 6.0
        controlsStack.translatesAutoresizingMaskIntoConstraints = false

        // Row 1: Height Slider
        let heightLabel = makeRowTitleLabel("Height")
        heightSlider.minimumValue = Float(AutoDropConfig.heightScaleRange.lowerBound)
        heightSlider.maximumValue = Float(AutoDropConfig.heightScaleRange.upperBound)
        heightSlider.minimumTrackTintColor = AutoDropTheme.accent
        heightSlider.maximumTrackTintColor = AutoDropTheme.pressedKey
        heightSlider.thumbTintColor = AutoDropTheme.primaryText
        heightSlider.isContinuous = true
        heightSlider.addTarget(self, action: #selector(handleHeightSliderChanged), for: .valueChanged)
        heightSlider.addTarget(self, action: #selector(handleHeightSliderEnded), for: [.touchUpInside, .touchUpOutside, .touchCancel])

        configureValueLabel(heightValueLabel)
        let heightRow = makeControlRow(label: heightLabel, control: heightSlider, valueLabel: heightValueLabel)

        // Row 2: Font Size Slider
        let fontLabel = makeRowTitleLabel("Font")
        fontSlider.minimumValue = Float(AutoDropConfig.fontSizeRange.lowerBound)
        fontSlider.maximumValue = Float(AutoDropConfig.fontSizeRange.upperBound)
        fontSlider.minimumTrackTintColor = AutoDropTheme.accent
        fontSlider.maximumTrackTintColor = AutoDropTheme.pressedKey
        fontSlider.thumbTintColor = AutoDropTheme.primaryText
        fontSlider.isContinuous = true
        fontSlider.addTarget(self, action: #selector(handleFontSliderChanged), for: .valueChanged)
        fontSlider.addTarget(self, action: #selector(handleFontSliderEnded), for: [.touchUpInside, .touchUpOutside, .touchCancel])

        configureValueLabel(fontValueLabel)
        let fontRow = makeControlRow(label: fontLabel, control: fontSlider, valueLabel: fontValueLabel)

        // Row 3: Key Gap Toggle
        let gapLabel = makeRowTitleLabel("Gap")
        configureGapButton(tightButton, title: "Tight (3pt)", tag: 0)
        configureGapButton(comfortableButton, title: "Comfortable (6pt)", tag: 1)

        let gapSegmentedStack = UIStackView(arrangedSubviews: [tightButton, comfortableButton])
        gapSegmentedStack.axis = .horizontal
        gapSegmentedStack.alignment = .fill
        gapSegmentedStack.distribution = .fillEqually
        gapSegmentedStack.spacing = 6.0

        let gapRow = UIStackView(arrangedSubviews: [gapLabel, gapSegmentedStack])
        gapRow.axis = .horizontal
        gapRow.alignment = .center
        gapRow.spacing = 8.0
        gapRow.heightAnchor.constraint(equalToConstant: 26.0).isActive = true

        controlsStack.addArrangedSubview(heightRow)
        controlsStack.addArrangedSubview(fontRow)
        controlsStack.addArrangedSubview(gapRow)

        addSubview(headerStack)
        addSubview(scrollView)
        scrollView.addSubview(controlsStack)

        let scrollHeightConstraint = scrollView.heightAnchor.constraint(equalTo: controlsStack.heightAnchor)
        scrollHeightConstraint.priority = UILayoutPriority(750)

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: topAnchor, constant: 8.0),
            headerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10.0),
            headerStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10.0),
            headerStack.heightAnchor.constraint(equalToConstant: 28.0),

            scrollView.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 6.0),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10.0),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10.0),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8.0),
            scrollHeightConstraint,

            controlsStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            controlsStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            controlsStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            controlsStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            controlsStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    private func makeRowTitleLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 12.0, weight: .medium)
        label.textColor = AutoDropTheme.primaryText
        label.widthAnchor.constraint(equalToConstant: 44.0).isActive = true
        return label
    }

    private func configureValueLabel(_ label: UILabel) {
        label.font = .monospacedDigitSystemFont(ofSize: 11.5, weight: .semibold)
        label.textColor = AutoDropTheme.accent
        label.textAlignment = .right
        label.widthAnchor.constraint(equalToConstant: 40.0).isActive = true
    }

    private func makeControlRow(label: UILabel, control: UIView, valueLabel: UILabel) -> UIStackView {
        let row = UIStackView(arrangedSubviews: [label, control, valueLabel])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8.0
        row.heightAnchor.constraint(equalToConstant: 28.0).isActive = true
        return row
    }

    private func configureGapButton(_ button: UIButton, title: String, tag: Int) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .semibold)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.8
        button.layer.cornerRadius = 7.0
        button.layer.cornerCurve = .continuous
        button.tag = tag
        button.heightAnchor.constraint(equalToConstant: 26.0).isActive = true
        button.addTarget(self, action: #selector(handleGapTapped(_:)), for: .touchUpInside)
    }

    func update(with settings: AutoDropSettingsSnapshot) {
        let clampedScale = AutoDropConfig.clamp(settings.keyboardHeightScale, to: AutoDropConfig.heightScaleRange)
        let clampedFont = AutoDropConfig.clamp(settings.keyFontSize, to: AutoDropConfig.fontSizeRange)

        heightSlider.value = Float(clampedScale)
        heightValueLabel.text = "\(Int((clampedScale * 100.0).rounded()))%"

        fontSlider.value = Float(clampedFont)
        fontValueLabel.text = "\(Int(clampedFont.rounded()))pt"

        let isTight = (settings.keyGapMode == .tight)
        tightButton.backgroundColor = isTight ? AutoDropTheme.accent : AutoDropTheme.standardKey
        tightButton.setTitleColor(isTight ? AutoDropTheme.primaryText : AutoDropTheme.secondaryText, for: .normal)

        comfortableButton.backgroundColor = isTight ? AutoDropTheme.standardKey : AutoDropTheme.accent
        comfortableButton.setTitleColor(isTight ? AutoDropTheme.secondaryText : AutoDropTheme.primaryText, for: .normal)
    }

    @objc private func handleHeightSliderChanged() {
        let value = Double(heightSlider.value)
        heightValueLabel.text = "\(Int((value * 100.0).rounded()))%"
        onHeightScaleChanged?(value, false)
    }

    @objc private func handleHeightSliderEnded() {
        let value = Double(heightSlider.value)
        onHeightScaleChanged?(value, true)
    }

    @objc private func handleFontSliderChanged() {
        let value = Double(fontSlider.value.rounded())
        fontValueLabel.text = "\(Int(value))pt"
        onFontSizeChanged?(value, false)
    }

    @objc private func handleFontSliderEnded() {
        let value = Double(fontSlider.value.rounded())
        fontSlider.setValue(Float(value), animated: true)
        fontValueLabel.text = "\(Int(value))pt"
        onFontSizeChanged?(value, true)
    }

    @objc private func handleGapTapped(_ sender: UIButton) {
        let mode: KeyGapMode = (sender.tag == 0) ? .tight : .comfortable
        onGapModeChanged?(mode)
    }

    @objc private func handleReset() {
        onReset?()
    }

    @objc private func handleDone() {
        onDone?()
    }
}
