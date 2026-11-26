import UIKit

final class MainViewController: UIViewController, UITextViewDelegate {
    private let bgColor = UIColor(red: 21.0 / 255.0, green: 21.0 / 255.0, blue: 21.0 / 255.0, alpha: 1.0)
    private let cardColor = UIColor(red: 32.0 / 255.0, green: 32.0 / 255.0, blue: 32.0 / 255.0, alpha: 1.0)
    private let borderColor = UIColor(red: 44.0 / 255.0, green: 44.0 / 255.0, blue: 44.0 / 255.0, alpha: 1.0)
    private let specialKeyColor = UIColor(red: 44.0 / 255.0, green: 44.0 / 255.0, blue: 44.0 / 255.0, alpha: 1.0)
    private let accentColor = UIColor(red: 1.0, green: 89.0 / 255.0, blue: 158.0 / 255.0, alpha: 1.0)
    private let secondaryTextColor = UIColor(red: 160.0 / 255.0, green: 160.0 / 255.0, blue: 160.0 / 255.0, alpha: 1.0)

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let testerTextView = UITextView()
    private let testerPlaceholderLabel = UILabel()
    private let dropBadgeLabel = UILabel()
    private let doneEditingButton = UIButton(type: .system)

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        view.backgroundColor = bgColor

        setupLayout()
        observeKeyboardNotifications()
    }

    // MARK: - UI Setup

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = bgColor
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive

        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 16.0
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safe.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safe.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 12.0),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16.0),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16.0),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -28.0),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32.0)
        ])

        contentStack.addArrangedSubview(buildHeaderView())
        contentStack.addArrangedSubview(buildSetupGuideCard())
        contentStack.addArrangedSubview(buildLiveTesterCard())
        contentStack.addArrangedSubview(buildInKeyboardTipsCard())
    }

    private func buildHeaderView() -> UIView {
        let iconContainer = UIView()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.backgroundColor = accentColor.withAlphaComponent(0.18)
        iconContainer.layer.cornerRadius = 12.0
        iconContainer.layer.cornerCurve = .continuous

        let iconView = UIImageView(
            image: UIImage(
                systemName: "keyboard",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 20.0, weight: .semibold)
            )
        )
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.tintColor = accentColor
        iconView.contentMode = .scaleAspectFit
        iconContainer.addSubview(iconView)

        NSLayoutConstraint.activate([
            iconContainer.widthAnchor.constraint(equalToConstant: 44.0),
            iconContainer.heightAnchor.constraint(equalToConstant: 44.0),
            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor)
        ])

        let titleLabel = UILabel()
        titleLabel.text = "AutoDrop Keyboard"
        titleLabel.font = .systemFont(ofSize: 24.0, weight: .bold)
        titleLabel.textColor = .white

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Instant letter, number & word drop keyboard"
        subtitleLabel.font = .systemFont(ofSize: 13.0, weight: .medium)
        subtitleLabel.textColor = secondaryTextColor
        subtitleLabel.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2.0

        let headerStack = UIStackView(arrangedSubviews: [iconContainer, textStack])
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.spacing = 12.0
        return headerStack
    }

    private func buildSetupGuideCard() -> UIView {
        let header = makeCardHeader(iconName: "gearshape.fill", title: "Setup Guide")

        let stepsStack = UIStackView()
        stepsStack.axis = .vertical
        stepsStack.spacing = 8.0

        let steps = [
            "Open Settings > General > Keyboard > Keyboards",
            "Tap Add New Keyboard and select AutoDrop",
            "Tap AutoDrop and enable Allow Full Access",
            "Switch keyboards anytime using the Globe key"
        ]
        for (index, text) in steps.enumerated() {
            stepsStack.addArrangedSubview(makeStepRow(number: "\(index + 1)", text: text))
        }

        let openSettingsBtn = UIButton(type: .system)
        openSettingsBtn.setTitle("  Open Settings", for: .normal)
        openSettingsBtn.setImage(
            UIImage(
                systemName: "arrow.up.right.square.fill",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 14.0, weight: .semibold)
            ),
            for: .normal
        )
        openSettingsBtn.titleLabel?.font = .systemFont(ofSize: 15.0, weight: .bold)
        openSettingsBtn.tintColor = .white
        openSettingsBtn.setTitleColor(.white, for: .normal)
        openSettingsBtn.backgroundColor = accentColor
        openSettingsBtn.layer.cornerRadius = 11.0
        openSettingsBtn.layer.cornerCurve = .continuous
        openSettingsBtn.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
        openSettingsBtn.addTarget(self, action: #selector(handleOpenSettings), for: .touchUpInside)

        let bodyStack = UIStackView(arrangedSubviews: [header, stepsStack, openSettingsBtn])
        bodyStack.axis = .vertical
        bodyStack.spacing = 12.0
        return makeCardContainer(with: bodyStack)
    }

    private func buildLiveTesterCard() -> UIView {
        let headerLeft = makeCardHeader(iconName: "text.cursor", title: "Live Tester")

        dropBadgeLabel.text = "0 drops"
        dropBadgeLabel.font = .monospacedDigitSystemFont(ofSize: 11.0, weight: .bold)
        dropBadgeLabel.textColor = accentColor
        dropBadgeLabel.textAlignment = .center
        dropBadgeLabel.backgroundColor = accentColor.withAlphaComponent(0.16)
        dropBadgeLabel.layer.cornerRadius = 11.0
        dropBadgeLabel.clipsToBounds = true
        dropBadgeLabel.isHidden = true
        dropBadgeLabel.setContentHuggingPriority(.required, for: .horizontal)
        dropBadgeLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 22.0).isActive = true

        doneEditingButton.setTitle("Done", for: .normal)
        doneEditingButton.titleLabel?.font = .systemFont(ofSize: 13.0, weight: .semibold)
        doneEditingButton.setTitleColor(secondaryTextColor, for: .normal)
        doneEditingButton.backgroundColor = specialKeyColor
        doneEditingButton.layer.cornerRadius = 8.0
        doneEditingButton.layer.cornerCurve = .continuous
        doneEditingButton.isHidden = true
        doneEditingButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 54.0).isActive = true
        doneEditingButton.heightAnchor.constraint(equalToConstant: 28.0).isActive = true
        doneEditingButton.addTarget(self, action: #selector(handleDismissKeyboard), for: .touchUpInside)

        let clearButton = UIButton(type: .system)
        clearButton.setTitle("Clear", for: .normal)
        clearButton.titleLabel?.font = .systemFont(ofSize: 13.0, weight: .semibold)
        clearButton.setTitleColor(accentColor, for: .normal)
        clearButton.backgroundColor = accentColor.withAlphaComponent(0.16)
        clearButton.layer.cornerRadius = 8.0
        clearButton.layer.cornerCurve = .continuous
        clearButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 56.0).isActive = true
        clearButton.heightAnchor.constraint(equalToConstant: 28.0).isActive = true
        clearButton.addTarget(self, action: #selector(handleClearTester), for: .touchUpInside)

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let headerRow = UIStackView(arrangedSubviews: [headerLeft, dropBadgeLabel, spacer, doneEditingButton, clearButton])
        headerRow.axis = .horizontal
        headerRow.alignment = .center
        headerRow.spacing = 8.0

        testerTextView.translatesAutoresizingMaskIntoConstraints = false
        testerTextView.backgroundColor = bgColor
        testerTextView.textColor = .white
        testerTextView.tintColor = accentColor
        testerTextView.font = .systemFont(ofSize: 15.0, weight: .regular)
        testerTextView.keyboardAppearance = .dark
        testerTextView.layer.cornerRadius = 12.0
        testerTextView.layer.cornerCurve = .continuous
        testerTextView.layer.borderWidth = 1.2
        testerTextView.layer.borderColor = UIColor(red: 48.0 / 255.0, green: 48.0 / 255.0, blue: 48.0 / 255.0, alpha: 1.0).cgColor
        testerTextView.textContainerInset = UIEdgeInsets(top: 12.0, left: 10.0, bottom: 12.0, right: 10.0)
        testerTextView.delegate = self
        testerTextView.heightAnchor.constraint(equalToConstant: 140.0).isActive = true

        testerPlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
        testerPlaceholderLabel.text = "Test Your Keyboard Here"
        testerPlaceholderLabel.font = .systemFont(ofSize: 15.0, weight: .regular)
        testerPlaceholderLabel.textColor = secondaryTextColor.withAlphaComponent(0.75)

        let editorWrapper = UIView()
        editorWrapper.translatesAutoresizingMaskIntoConstraints = false
        editorWrapper.addSubview(testerTextView)
        editorWrapper.addSubview(testerPlaceholderLabel)

        NSLayoutConstraint.activate([
            testerTextView.topAnchor.constraint(equalTo: editorWrapper.topAnchor),
            testerTextView.leadingAnchor.constraint(equalTo: editorWrapper.leadingAnchor),
            testerTextView.trailingAnchor.constraint(equalTo: editorWrapper.trailingAnchor),
            testerTextView.bottomAnchor.constraint(equalTo: editorWrapper.bottomAnchor),

            testerPlaceholderLabel.topAnchor.constraint(equalTo: testerTextView.topAnchor, constant: 12.0),
            testerPlaceholderLabel.leadingAnchor.constraint(equalTo: testerTextView.leadingAnchor, constant: 15.0),
            testerPlaceholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: testerTextView.trailingAnchor, constant: -15.0)
        ])

        let hintLabel = UILabel()
        hintLabel.text = "Tap inside above, switch to AutoDrop via Globe, and tap the toolbar gear icon to customize all modes, delays, height, font & haptics."
        hintLabel.font = .systemFont(ofSize: 12.0, weight: .medium)
        hintLabel.textColor = secondaryTextColor
        hintLabel.numberOfLines = 0

        let bodyStack = UIStackView(arrangedSubviews: [headerRow, editorWrapper, hintLabel])
        bodyStack.axis = .vertical
        bodyStack.spacing = 12.0
        return makeCardContainer(with: bodyStack)
    }

    private func buildInKeyboardTipsCard() -> UIView {
        let header = makeCardHeader(iconName: "slider.horizontal.3", title: "Built-In Keyboard Settings")

        let detailLabel = UILabel()
        detailLabel.text = "All settings live directly inside the keyboard toolbar panel (tap the Gear icon on the top right of the keyboard):\n\n• Mode Selector: OFF, ABC (0ms drop), 123 (Numpad), WORD\n• Delays: Number Delay (0.2s–1.5s) & Word Delay (0.3s–2.0s)\n• Word Trigger: On Pause vs On Spacebar\n• Live Sizing: Height (180pt–340pt), Font (14pt–24pt) & Gap\n• Haptic Vibration: ON / OFF"
        detailLabel.font = .systemFont(ofSize: 13.0, weight: .regular)
        detailLabel.textColor = secondaryTextColor
        detailLabel.numberOfLines = 0

        let bodyStack = UIStackView(arrangedSubviews: [header, detailLabel])
        bodyStack.axis = .vertical
        bodyStack.spacing = 10.0
        return makeCardContainer(with: bodyStack)
    }

    // MARK: - Component Builders

    private func makeCardContainer(with innerView: UIView) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = cardColor
        card.layer.cornerRadius = 16.0
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 1.0
        card.layer.borderColor = borderColor.cgColor

        innerView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(innerView)

        NSLayoutConstraint.activate([
            innerView.topAnchor.constraint(equalTo: card.topAnchor, constant: 16.0),
            innerView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16.0),
            innerView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16.0),
            innerView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16.0)
        ])
        return card
    }

    private func makeCardHeader(iconName: String, title: String) -> UIStackView {
        let icon = UIImageView(
            image: UIImage(
                systemName: iconName,
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 14.0, weight: .semibold)
            )
        )
        icon.tintColor = accentColor
        icon.contentMode = .scaleAspectFit
        icon.setContentHuggingPriority(.required, for: .horizontal)

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16.0, weight: .bold)
        label.textColor = .white

        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8.0
        return stack
    }

    private func makeStepRow(number: String, text: String) -> UIStackView {
        let badge = UILabel()
        badge.text = number
        badge.font = .systemFont(ofSize: 12.0, weight: .bold)
        badge.textColor = accentColor
        badge.textAlignment = .center
        badge.backgroundColor = accentColor.withAlphaComponent(0.18)
        badge.layer.cornerRadius = 11.0
        badge.clipsToBounds = true
        NSLayoutConstraint.activate([
            badge.widthAnchor.constraint(equalToConstant: 22.0),
            badge.heightAnchor.constraint(equalToConstant: 22.0)
        ])

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 13.5, weight: .medium)
        label.textColor = secondaryTextColor
        label.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [badge, label])
        stack.axis = .horizontal
        stack.alignment = .top
        stack.spacing = 10.0
        return stack
    }

    // MARK: - Actions & UITextViewDelegate

    @objc private func handleOpenSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    @objc private func handleClearTester() {
        testerTextView.text = ""
        updateTesterState()
    }

    @objc private func handleDismissKeyboard() {
        testerTextView.resignFirstResponder()
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        doneEditingButton.isHidden = false
        testerTextView.layer.borderColor = accentColor.cgColor
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        doneEditingButton.isHidden = true
        testerTextView.layer.borderColor = UIColor(red: 48.0 / 255.0, green: 48.0 / 255.0, blue: 48.0 / 255.0, alpha: 1.0).cgColor
    }

    func textViewDidChange(_ textView: UITextView) {
        updateTesterState()
    }

    private func updateTesterState() {
        let text = testerTextView.text ?? ""
        testerPlaceholderLabel.isHidden = !text.isEmpty
        let drops = text.filter { $0 == "\n" }.count
        dropBadgeLabel.isHidden = (drops == 0)
        let noun = (drops == 1) ? "drop" : "drops"
        dropBadgeLabel.text = "  \(drops) \(noun)  "
    }

    // MARK: - Keyboard Avoidance

    private func observeKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func handleKeyboardWillChangeFrame(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        let converted = view.convert(endFrame, from: nil)
        let isDockedAtBottom = converted.maxY >= view.bounds.maxY - 1.0 && converted.width >= view.bounds.width * 0.8
        let overlap = isDockedAtBottom ? max(0.0, view.bounds.maxY - converted.minY) : 0.0
        let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval) ?? 0.25

        UIView.animate(withDuration: duration) {
            self.scrollView.contentInset.bottom = overlap
            self.scrollView.verticalScrollIndicatorInsets.bottom = overlap
        }

        if testerTextView.isFirstResponder && overlap > 0 {
            let targetRect = testerTextView.convert(testerTextView.bounds, to: scrollView)
            scrollView.scrollRectToVisible(targetRect.insetBy(dx: 0, dy: -12), animated: true)
        }
    }

    @objc private func handleKeyboardWillHide(_ notification: Notification) {
        let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval) ?? 0.25
        UIView.animate(withDuration: duration) {
            self.scrollView.contentInset.bottom = 0.0
            self.scrollView.verticalScrollIndicatorInsets.bottom = 0.0
        }
    }
}
