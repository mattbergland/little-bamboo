import SwiftUI

enum BambooTheme {
    static let canvas = Color(hex: 0xFAF9F5)
    static let card = Color(hex: 0xEFE9DE)
    static let soft = Color(hex: 0xF5F0E8)
    static let strong = Color(hex: 0xE8E0D2)
    static let ink = Color(hex: 0x141413)
    static let body = Color(hex: 0x3D3D3A)
    static let muted = Color(hex: 0x6C6A64)
    static let line = Color(hex: 0xE6DFD8)
    static let coral = Color(hex: 0xCC785C)
    static let action = Color(hex: 0xA9583E)
    static let onAction = Color.white
    static let error = Color(hex: 0xC64545)
    static let radius: CGFloat = 16
    static let gap: CGFloat = 24
    static func display(_ size: CGFloat) -> Font { .custom("Georgia", size: size, relativeTo: .largeTitle) }
}

private extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 255) / 255,
                  green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1)
    }
}

struct BambooMark: View {
    var size: CGFloat = 32
    var body: some View {
        Canvas { context, canvas in
            let scale = canvas.width / 40
            var stem = Path()
            stem.move(to: CGPoint(x: 17 * scale, y: 36 * scale))
            stem.addQuadCurve(to: CGPoint(x: 22 * scale, y: 5 * scale), control: CGPoint(x: 24 * scale, y: 17 * scale))
            context.stroke(stem, with: .color(BambooTheme.action), style: StrokeStyle(lineWidth: 2 * scale, lineCap: .round))
            for (x, y, right) in [(20.0, 12.0, true), (20.0, 21.0, false), (18.0, 30.0, true)] {
                var leaf = Path()
                let start = CGPoint(x: x * scale, y: y * scale)
                let end = CGPoint(x: (x + (right ? 14 : -14)) * scale, y: (y - 9) * scale)
                leaf.move(to: start)
                leaf.addQuadCurve(to: end, control: CGPoint(x: end.x, y: start.y + 3 * scale))
                leaf.addQuadCurve(to: start, control: CGPoint(x: start.x, y: end.y - 4 * scale))
                context.fill(leaf, with: .color(BambooTheme.action))
            }
        }.frame(width: size, height: size).accessibilityHidden(true)
    }
}

struct TogetherIllustration: View {
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack {
                Circle().fill(BambooTheme.strong).frame(width: 180, height: 180).offset(x: width * 0.1, y: 24)
                Ellipse().fill(BambooTheme.canvas).frame(width: 170, height: 30).offset(y: 93)
                // Two simple paper-cut figures leaning toward each other.
                Capsule().fill(BambooTheme.action).frame(width: 70, height: 118).rotationEffect(.degrees(-12)).offset(x: -30, y: 35)
                Circle().fill(BambooTheme.coral).frame(width: 47, height: 47).offset(x: -44, y: -36)
                Capsule().fill(BambooTheme.ink).frame(width: 47, height: 75).rotationEffect(.degrees(16)).offset(x: 33, y: 60)
                Circle().fill(BambooTheme.coral).frame(width: 33, height: 33).offset(x: 43, y: 13)
                Capsule().fill(BambooTheme.coral).frame(width: 61, height: 17).rotationEffect(.degrees(25)).offset(x: 5, y: 45)
                BambooMark(size: 74).rotationEffect(.degrees(-15)).offset(x: -100, y: 35)
                Image(systemName: "sparkle").font(.system(size: 17, weight: .light)).foregroundStyle(BambooTheme.action).offset(x: 86, y: -40)
            }.frame(width: width, height: proxy.size.height)
        }.frame(height: 220).clipped().accessibilityLabel("A parent and child growing together")
    }
}

struct PrimaryButton: View {
    let title: String
    var symbol = "arrow.up.right"
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack { Text(title); Spacer(); Image(systemName: symbol) }
                .font(.system(.body, weight: .medium)).padding(16)
                .foregroundStyle(BambooTheme.onAction).background(BambooTheme.action, in: RoundedRectangle(cornerRadius: 12))
        }.buttonStyle(.plain)
    }
}

struct SectionLabel: View {
    let title: String
    var body: some View {
        Text(title).font(.system(.caption, weight: .medium)).tracking(1.4).foregroundStyle(BambooTheme.muted)
    }
}
