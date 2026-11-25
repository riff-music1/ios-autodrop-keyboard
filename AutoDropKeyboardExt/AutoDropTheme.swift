import UIKit

enum AutoDropTheme {
    static let background = UIColor(hex: AutoDropPalette.backgroundHex)
    static let toolbarBackground = UIColor(hex: AutoDropPalette.toolbarHex)
    static let cardBackground = UIColor(hex: AutoDropPalette.cardHex)
    static let standardKey = UIColor(hex: AutoDropPalette.standardKeyHex)
    static let specialKey = UIColor(hex: AutoDropPalette.specialKeyHex)
    static let pressedKey = UIColor(hex: AutoDropPalette.pressedKeyHex)
    static let accent = UIColor(hex: AutoDropPalette.accentHex)
    static let accentPressed = UIColor(hex: 0xD94582)
    static let accentFlash = UIColor(hex: 0xFF8EC0)
    static let primaryText = UIColor(hex: AutoDropPalette.primaryTextHex)
    static let secondaryText = UIColor(hex: AutoDropPalette.secondaryTextHex)
    static let pillInactive = UIColor(hex: 0x262626)
    static let divider = UIColor(hex: 0x282828)
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >> 8) & 0xFF) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}
