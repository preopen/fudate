import SwiftUI

public enum PrepFlowColor {
    public static let ink = Color(red: 0.082, green: 0.090, blue: 0.102)
    public static let g2 = Color(red: 0.439, green: 0.459, blue: 0.482)
    public static let g3 = Color(red: 0.761, green: 0.776, blue: 0.792)
    public static let g4 = Color(red: 0.914, green: 0.922, blue: 0.929)
    public static let g5 = Color(red: 0.965, green: 0.969, blue: 0.973)
    public static let time = Color(red: 0.761, green: 0.255, blue: 0.047)
    public static let ok = Color(red: 0.227, green: 0.416, blue: 0.165)
    public static let white = Color.white
    public static let clear = Color.clear
}

public enum PrepFlowSpacing {
    public static let none: CGFloat = 0
    public static let xxs: CGFloat = 4
    public static let xs: CGFloat = 8
    public static let sm: CGFloat = 12
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
    public static let xxl: CGFloat = 40
}

public enum PrepFlowRadius {
    public static let sm: CGFloat = 6
    public static let md: CGFloat = 8
    public static let xl: CGFloat = 18
    public static let xxl: CGFloat = 22
    public static let xxxl: CGFloat = 24
    public static let lg: CGFloat = 16
    public static let pill: CGFloat = 999
}

public enum PrepFlowMotion {
    public static let response = 0.32
    public static let dampingFraction = 0.82
}

public enum PrepFlowProgress {
    public static let countdown: CGFloat = 0.62
    public static let schedule: Double = 0.36
}

public enum PrepFlowAngle {
    public static let countdownStart = Angle.degrees(-90)
}

public enum PrepFlowFont {
    public static func satoshi(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Satoshi", size: size).weight(weight)
    }

    public static let topTitle = satoshi(18, weight: .black)
    public static let topSubtitle = satoshi(12, weight: .medium)
    public static let segment = satoshi(14, weight: .heavy)
    public static let countdownLabel = satoshi(10, weight: .heavy)
    public static let countdownValue = satoshi(20, weight: .black)
    public static let nowLabel = satoshi(14, weight: .black)
    public static let focusTitle = satoshi(40, weight: .black)
    public static let chip = satoshi(15, weight: .bold)
    public static let rowTitle = satoshi(19, weight: .bold)
    public static let rowMeta = satoshi(14, weight: .medium)
    public static let sectionTitle = satoshi(14, weight: .black)
    public static let railTitle = satoshi(15, weight: .bold)
    public static let railMeta = satoshi(12, weight: .medium)
    public static let action = satoshi(18, weight: .black)
    public static let body = satoshi(16, weight: .regular)
    public static let bodyBold = satoshi(16, weight: .bold)
    public static let small = satoshi(13, weight: .medium)
    public static let smallBold = satoshi(13, weight: .bold)
    public static let icon = satoshi(20, weight: .bold)
    public static let iconLarge = satoshi(28, weight: .bold)
}

public enum PrepFlowMetric {
    public static let topBarHeight: CGFloat = 72
    public static let bottomBarHeight: CGFloat = 88
    public static let boardHorizontalPadding: CGFloat = 34
    public static let railWidth: CGFloat = 372
    public static let topInset: CGFloat = 100
    public static let bottomInset: CGFloat = 108
    public static let countdownRing: CGFloat = 32
    public static let countdownRingInner: CGFloat = 22
    public static let countdownIslandWidth: CGFloat = 188
    public static let checkSize: CGFloat = 50
    public static let timelineDot: CGFloat = 10
    public static let timelineRuleWidth: CGFloat = 2
    public static let taskRowMinHeight: CGFloat = 80
    public static let actionButtonHeight: CGFloat = 60
    public static let catalogTreeWidth: CGFloat = 312
    public static let catalogPreviewWidth: CGFloat = 300
    public static let catalogFieldHeight: CGFloat = 46
    public static let catalogMediaThumbWidth: CGFloat = 90
    public static let catalogMediaThumbHeight: CGFloat = 66
    public static let lineWidth: CGFloat = 1
    public static let heavyLineWidth: CGFloat = 2.5
    public static let textMinimumScale: CGFloat = 0.72
}

public enum PrepFlowOpacity {
    public static let glass = 0.46
    public static let contentHeader = 0.72
    public static let glassStroke = 0.60
    public static let glassShadow = 0.14
    public static let darkGlass = 0.50
    public static let timeGlass = 0.13
    public static let timeStroke = 0.30
    public static let timeSoft = 0.12
    public static let timeNow = 0.10
    public static let rule = 0.10
    public static let selection = 0.06
}
