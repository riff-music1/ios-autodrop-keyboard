import UIKit

enum KeyboardPage {
    case qwerty
    case symbols
    case secondarySymbols
    case numpad
}

final class KeyboardLayoutContainer {
    let rootView = UIView()

    private let qwertyGrid = UIStackView()
    private let symbolsGrid = UIStackView()
    private let secondarySymbolsGrid = UIStackView()
    private let numpadGrid = UIStackView()

    private var allRowStacks: [UIStackView] = []
    private var allGridStacks: [UIStackView] = []
    private var allButtons: [KeyButton] = []
    private var letterButtons: [KeyButton] = []
    private var shiftButtons: [KeyButton] = []
    private var globeEntries: [(button: KeyButton, widthConstraint: NSLayoutConstraint)] = []

    private(set) var currentPage: KeyboardPage = .qwerty

    init(
        fontSize: CGFloat,
        gap: CGFloat,
        needsGlobe: Bool,
        configureButton: (KeyButton) -> Void
    ) {
        rootView.translatesAutoresizingMaskIntoConstraints = false
        rootView.backgroundColor = .clear

        buildQwertyGrid(fontSize: fontSize, gap: gap, configureButton: configureButton)
        buildSymbolsGrid(
            grid: symbolsGrid,
            row1: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
            row2: ["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""],
            row3ToggleTitle: "#+=",
            row3ToggleAction: .switchToSecondarySymbols,
            fontSize: fontSize,
            gap: gap,
            configureButton: configureButton
        )
        buildSymbolsGrid(
            grid: secondarySymbolsGrid,
            row1: ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="],
            row2: ["_", "\\", "|", "~", "<", ">", "€", "£", "¥", "•"],
            row3ToggleTitle: "123",
            row3ToggleAction: .switchToSymbols,
            fontSize: fontSize,
            gap: gap,
            configureButton: configureButton
        )
        buildNumpadGrid(fontSize: fontSize, gap: gap, configureButton: configureButton)

        for grid in [qwertyGrid, symbolsGrid, secondarySymbolsGrid, numpadGrid] {
            rootView.addSubview(grid)
            NSLayoutConstraint.activate([
                grid.topAnchor.constraint(equalTo: rootView.topAnchor),
                grid.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),
                grid.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
                grid.trailingAnchor.constraint(equalTo: rootView.trailingAnchor)
            ])
        }

        updateGlobeVisibility(needsGlobe)
        showPage(.qwerty)
    }

    func showPage(_ page: KeyboardPage) {
        currentPage = page
        qwertyGrid.isHidden = (page != .qwerty)
        symbolsGrid.isHidden = (page != .symbols)
        secondarySymbolsGrid.isHidden = (page != .secondarySymbols)
        numpadGrid.isHidden = (page != .numpad)
    }

    func updateShiftState(_ state: KeyboardShiftState, fontSize: CGFloat) {
        let isUpper = state.isUppercase
        for button in letterButtons {
            button.applyCase(uppercase: isUpper)
        }
        for shiftButton in shiftButtons {
            shiftButton.applyShiftVisualState(state, fontSize: fontSize)
        }
    }

    func updateFontSize(_ fontSize: CGFloat, shiftState: KeyboardShiftState) {
        for button in allButtons {
            button.updateFontSize(fontSize)
        }
        for shiftButton in shiftButtons {
            shiftButton.applyShiftVisualState(shiftState, fontSize: fontSize)
        }
    }

    func updateGap(_ gap: CGFloat) {
        for row in allRowStacks {
            row.spacing = gap
        }
        for grid in allGridStacks {
            grid.spacing = gap
        }
    }

    func updateGlobeVisibility(_ visible: Bool) {
        for entry in globeEntries {
            entry.button.isHidden = !visible
            entry.widthConstraint.isActive = visible
        }
    }

    // MARK: - QWERTY

    private func buildQwertyGrid(
        fontSize: CGFloat,
        gap: CGFloat,
        configureButton: (KeyButton) -> Void
    ) {
        configureGridStack(qwertyGrid, gap: gap)

        // Row 1: Q-P
        let row1Letters = ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]
        let row1Stack = makeHorizontalStack(distribution: .fillEqually, spacing: gap)
        var row1Buttons: [KeyButton] = []
        for ch in row1Letters {
            let btn = makeLetterButton(ch, fontSize: fontSize, configureButton: configureButton)
            row1Buttons.append(btn)
            row1Stack.addArrangedSubview(btn)
        }
        allRowStacks.append(row1Stack)

        let referenceKey = row1Buttons[0]

        // Row 2: A-L centered with side padding
        let row2Letters = ["a", "s", "d", "f", "g", "h", "j", "k", "l"]
        let row2Inner = makeHorizontalStack(distribution: .fillEqually, spacing: gap)
        var row2Buttons: [KeyButton] = []
        for ch in row2Letters {
            let btn = makeLetterButton(ch, fontSize: fontSize, configureButton: configureButton)
            row2Buttons.append(btn)
            row2Inner.addArrangedSubview(btn)
        }
        allRowStacks.append(row2Inner)

        let leadingSpacer = UIView()
        let trailingSpacer = UIView()
        leadingSpacer.translatesAutoresizingMaskIntoConstraints = false
        trailingSpacer.translatesAutoresizingMaskIntoConstraints = false

        let row2Outer = makeHorizontalStack(distribution: .fill, spacing: 0.0)
        row2Outer.addArrangedSubview(leadingSpacer)
        row2Outer.addArrangedSubview(row2Inner)
        row2Outer.addArrangedSubview(trailingSpacer)

        let row2WidthMatch = row2Buttons[0].widthAnchor.constraint(equalTo: referenceKey.widthAnchor)
        row2WidthMatch.priority = UILayoutPriority(998)
        NSLayoutConstraint.activate([
            leadingSpacer.widthAnchor.constraint(equalTo: trailingSpacer.widthAnchor),
            row2WidthMatch
        ])

        // Row 3: Shift + Z-M + Backspace
        let shiftBtn = KeyButton(
            action: .shift,
            style: .special,
            symbolName: "shift",
            fontSize: fontSize
        )
        registerButton(shiftBtn, configureButton: configureButton)
        shiftButtons.append(shiftBtn)

        let row3Letters = ["z", "x", "c", "v", "b", "n", "m"]
        let row3Inner = makeHorizontalStack(distribution: .fillEqually, spacing: gap)
        var row3Buttons: [KeyButton] = []
        for ch in row3Letters {
            let btn = makeLetterButton(ch, fontSize: fontSize, configureButton: configureButton)
            row3Buttons.append(btn)
            row3Inner.addArrangedSubview(btn)
        }
        allRowStacks.append(row3Inner)

        let backspaceBtn = KeyButton(
            action: .backspace,
            style: .special,
            symbolName: "delete.left",
            fontSize: fontSize
        )
        registerButton(backspaceBtn, configureButton: configureButton)

        let row3Outer = makeHorizontalStack(distribution: .fill, spacing: gap)
        row3Outer.addArrangedSubview(shiftBtn)
        row3Outer.addArrangedSubview(row3Inner)
        row3Outer.addArrangedSubview(backspaceBtn)
        allRowStacks.append(row3Outer)

        let row3WidthMatch = row3Buttons[0].widthAnchor.constraint(equalTo: referenceKey.widthAnchor)
        row3WidthMatch.priority = UILayoutPriority(998)
        let shiftBackspaceMatch = shiftBtn.widthAnchor.constraint(equalTo: backspaceBtn.widthAnchor)
        shiftBackspaceMatch.priority = UILayoutPriority(998)
        NSLayoutConstraint.activate([row3WidthMatch, shiftBackspaceMatch])

        // Row 4: ?123 + Globe + Spacebar + Period + Drop/Return
        let row4Stack = buildStandardBottomRow(
            leftTitle: "?123",
            leftAction: .switchToSymbols,
            fontSize: fontSize,
            gap: gap,
            configureButton: configureButton
        )

        qwertyGrid.addArrangedSubview(row1Stack)
        qwertyGrid.addArrangedSubview(row2Outer)
        qwertyGrid.addArrangedSubview(row3Outer)
        qwertyGrid.addArrangedSubview(row4Stack)
    }

    // MARK: - ?123 and #+= Symbols

    private func buildSymbolsGrid(
        grid: UIStackView,
        row1: [String],
        row2: [String],
        row3ToggleTitle: String,
        row3ToggleAction: KeyAction,
        fontSize: CGFloat,
        gap: CGFloat,
        configureButton: (KeyButton) -> Void
    ) {
        configureGridStack(grid, gap: gap)

        let row1Stack = makeHorizontalStack(distribution: .fillEqually, spacing: gap)
        for char in row1 {
            row1Stack.addArrangedSubview(makeCharButton(char, style: .standard, fontSize: fontSize, configureButton: configureButton))
        }
        allRowStacks.append(row1Stack)

        let row2Stack = makeHorizontalStack(distribution: .fillEqually, spacing: gap)
        for char in row2 {
            row2Stack.addArrangedSubview(makeCharButton(char, style: .standard, fontSize: fontSize, configureButton: configureButton))
        }
        allRowStacks.append(row2Stack)

        // Row 3: toggle + [. , ? ! '] + Backspace
        let toggleBtn = KeyButton(
            action: row3ToggleAction,
            style: .special,
            title: row3ToggleTitle,
            fontSize: fontSize
        )
        registerButton(toggleBtn, configureButton: configureButton)

        let punctInner = makeHorizontalStack(distribution: .fillEqually, spacing: gap)
        for char in [".", ",", "?", "!", "'"] {
            punctInner.addArrangedSubview(makeCharButton(char, style: .standard, fontSize: fontSize, configureButton: configureButton))
        }
        punctInner.setContentHuggingPriority(.defaultLow, for: .horizontal)
        allRowStacks.append(punctInner)

        let backspaceBtn = KeyButton(
            action: .backspace,
            style: .special,
            symbolName: "delete.left",
            fontSize: fontSize
        )
        registerButton(backspaceBtn, configureButton: configureButton)

        let row3Stack = makeHorizontalStack(distribution: .fill, spacing: gap)
        row3Stack.addArrangedSubview(toggleBtn)
        row3Stack.addArrangedSubview(punctInner)
        row3Stack.addArrangedSubview(backspaceBtn)
        allRowStacks.append(row3Stack)

        let toggleWidth = toggleBtn.widthAnchor.constraint(equalTo: row3Stack.widthAnchor, multiplier: 0.145)
        toggleWidth.priority = UILayoutPriority(998)
        let backWidth = backspaceBtn.widthAnchor.constraint(equalTo: toggleBtn.widthAnchor)
        backWidth.priority = UILayoutPriority(998)
        NSLayoutConstraint.activate([toggleWidth, backWidth])

        let row4Stack = buildStandardBottomRow(
            leftTitle: "ABC",
            leftAction: .switchToLetters,
            fontSize: fontSize,
            gap: gap,
            configureButton: configureButton
        )

        grid.addArrangedSubview(row1Stack)
        grid.addArrangedSubview(row2Stack)
        grid.addArrangedSubview(row3Stack)
        grid.addArrangedSubview(row4Stack)
    }

    // MARK: - Fast Numpad (123 Mode)

    private func buildNumpadGrid(
        fontSize: CGFloat,
        gap: CGFloat,
        configureButton: (KeyButton) -> Void
    ) {
        configureGridStack(numpadGrid, gap: gap)

        // Row 1: 1 | 2 | 3 | Backspace
        let row1Stack = makeHorizontalStack(distribution: .fillEqually, spacing: gap)
        let btn1 = makeCharButton("1", style: .numpadDigit, fontSize: fontSize, configureButton: configureButton)
        let btn2 = makeCharButton("2", style: .numpadDigit, fontSize: fontSize, configureButton: configureButton)
        let btn3 = makeCharButton("3", style: .numpadDigit, fontSize: fontSize, configureButton: configureButton)
        let backspaceBtn = KeyButton(action: .backspace, style: .special, symbolName: "delete.left", fontSize: fontSize)
        registerButton(backspaceBtn, configureButton: configureButton)
        [btn1, btn2, btn3, backspaceBtn].forEach { row1Stack.addArrangedSubview($0) }
        allRowStacks.append(row1Stack)

        // Row 2: 4 | 5 | 6 | .
        let row2Stack = makeHorizontalStack(distribution: .fillEqually, spacing: gap)
        let btn4 = makeCharButton("4", style: .numpadDigit, fontSize: fontSize, configureButton: configureButton)
        let btn5 = makeCharButton("5", style: .numpadDigit, fontSize: fontSize, configureButton: configureButton)
        let btn6 = makeCharButton("6", style: .numpadDigit, fontSize: fontSize, configureButton: configureButton)
        let dotBtn = makeCharButton(".", style: .special, fontSize: fontSize, configureButton: configureButton)
        [btn4, btn5, btn6, dotBtn].forEach { row2Stack.addArrangedSubview($0) }
        allRowStacks.append(row2Stack)

        // Row 3: 7 | 8 | 9 | Space
        let row3Stack = makeHorizontalStack(distribution: .fillEqually, spacing: gap)
        let btn7 = makeCharButton("7", style: .numpadDigit, fontSize: fontSize, configureButton: configureButton)
        let btn8 = makeCharButton("8", style: .numpadDigit, fontSize: fontSize, configureButton: configureButton)
        let btn9 = makeCharButton("9", style: .numpadDigit, fontSize: fontSize, configureButton: configureButton)
        let spaceBtn = KeyButton(action: .space, style: .special, title: "space", fontSize: fontSize)
        registerButton(spaceBtn, configureButton: configureButton)
        [btn7, btn8, btn9, spaceBtn].forEach { row3Stack.addArrangedSubview($0) }
        allRowStacks.append(row3Stack)

        // Row 4: ABC | 0 | [Globe (if needed) + Drop/Return]
        let abcBtn = KeyButton(action: .switchToLetters, style: .special, title: "ABC", fontSize: fontSize)
        registerButton(abcBtn, configureButton: configureButton)

        let btn0 = makeCharButton("0", style: .numpadDigit, fontSize: fontSize, configureButton: configureButton)

        let globeBtn = KeyButton(action: .globe, style: .special, symbolName: "globe", fontSize: fontSize)
        registerButton(globeBtn, configureButton: configureButton)

        let dropBtn = KeyButton(action: .dropReturn, style: .accent, title: "Drop", fontSize: fontSize)
        registerButton(dropBtn, configureButton: configureButton)
        dropBtn.setContentHuggingPriority(.defaultLow, for: .horizontal)
        dropBtn.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let rightActionsStack = makeHorizontalStack(distribution: .fill, spacing: gap)
        rightActionsStack.addArrangedSubview(globeBtn)
        rightActionsStack.addArrangedSubview(dropBtn)
        rightActionsStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        allRowStacks.append(rightActionsStack)

        let row4Stack = makeHorizontalStack(distribution: .fill, spacing: gap)
        row4Stack.addArrangedSubview(abcBtn)
        row4Stack.addArrangedSubview(btn0)
        row4Stack.addArrangedSubview(rightActionsStack)
        allRowStacks.append(row4Stack)

        let abcWidth = abcBtn.widthAnchor.constraint(equalTo: btn1.widthAnchor)
        abcWidth.priority = UILayoutPriority(998)
        let zeroWidth = btn0.widthAnchor.constraint(equalTo: btn2.widthAnchor)
        zeroWidth.priority = UILayoutPriority(998)
        let globeWidth = globeBtn.widthAnchor.constraint(equalTo: row4Stack.widthAnchor, multiplier: 0.12)
        globeWidth.priority = UILayoutPriority(998)
        NSLayoutConstraint.activate([abcWidth, zeroWidth, globeWidth])
        globeEntries.append((button: globeBtn, widthConstraint: globeWidth))

        numpadGrid.addArrangedSubview(row1Stack)
        numpadGrid.addArrangedSubview(row2Stack)
        numpadGrid.addArrangedSubview(row3Stack)
        numpadGrid.addArrangedSubview(row4Stack)
    }

    // MARK: - Helpers

    private func buildStandardBottomRow(
        leftTitle: String,
        leftAction: KeyAction,
        fontSize: CGFloat,
        gap: CGFloat,
        configureButton: (KeyButton) -> Void
    ) -> UIStackView {
        let leftBtn = KeyButton(action: leftAction, style: .special, title: leftTitle, fontSize: fontSize)
        registerButton(leftBtn, configureButton: configureButton)

        let globeBtn = KeyButton(action: .globe, style: .special, symbolName: "globe", fontSize: fontSize)
        registerButton(globeBtn, configureButton: configureButton)

        let spaceBtn = KeyButton(action: .space, style: .special, title: "space", fontSize: fontSize)
        registerButton(spaceBtn, configureButton: configureButton)
        spaceBtn.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spaceBtn.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let periodBtn = makeCharButton(".", style: .special, fontSize: fontSize, configureButton: configureButton)

        let dropBtn = KeyButton(action: .dropReturn, style: .accent, title: "Drop", fontSize: fontSize)
        registerButton(dropBtn, configureButton: configureButton)

        let rowStack = makeHorizontalStack(distribution: .fill, spacing: gap)
        rowStack.addArrangedSubview(leftBtn)
        rowStack.addArrangedSubview(globeBtn)
        rowStack.addArrangedSubview(spaceBtn)
        rowStack.addArrangedSubview(periodBtn)
        rowStack.addArrangedSubview(dropBtn)
        allRowStacks.append(rowStack)

        let leftWidth = leftBtn.widthAnchor.constraint(equalTo: rowStack.widthAnchor, multiplier: 0.14)
        leftWidth.priority = UILayoutPriority(998)

        let globeWidth = globeBtn.widthAnchor.constraint(equalTo: rowStack.widthAnchor, multiplier: 0.11)
        globeWidth.priority = UILayoutPriority(998)
        globeEntries.append((button: globeBtn, widthConstraint: globeWidth))

        let periodWidth = periodBtn.widthAnchor.constraint(equalTo: rowStack.widthAnchor, multiplier: 0.11)
        periodWidth.priority = UILayoutPriority(998)

        let dropWidth = dropBtn.widthAnchor.constraint(equalTo: rowStack.widthAnchor, multiplier: 0.21)
        dropWidth.priority = UILayoutPriority(998)

        NSLayoutConstraint.activate([leftWidth, globeWidth, periodWidth, dropWidth])
        return rowStack
    }

    private func configureGridStack(_ stack: UIStackView, gap: CGFloat) {
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = gap
        stack.translatesAutoresizingMaskIntoConstraints = false
        allGridStacks.append(stack)
    }

    private func makeHorizontalStack(distribution: UIStackView.Distribution, spacing: CGFloat) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = distribution
        stack.spacing = spacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }

    private func makeLetterButton(
        _ lower: String,
        fontSize: CGFloat,
        configureButton: (KeyButton) -> Void
    ) -> KeyButton {
        let upper = lower.uppercased()
        let btn = KeyButton(
            action: .character(lower),
            style: .standard,
            title: lower,
            lowercaseChar: lower,
            uppercaseChar: upper,
            fontSize: fontSize
        )
        registerButton(btn, configureButton: configureButton)
        letterButtons.append(btn)
        return btn
    }

    private func makeCharButton(
        _ char: String,
        style: KeyVisualStyle,
        fontSize: CGFloat,
        configureButton: (KeyButton) -> Void
    ) -> KeyButton {
        let btn = KeyButton(
            action: .character(char),
            style: style,
            title: char,
            fontSize: fontSize
        )
        registerButton(btn, configureButton: configureButton)
        return btn
    }

    private func registerButton(_ button: KeyButton, configureButton: (KeyButton) -> Void) {
        allButtons.append(button)
        configureButton(button)
    }
}
