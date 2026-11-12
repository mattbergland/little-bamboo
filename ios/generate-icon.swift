import AppKit

// Regenerate the original paper-and-bamboo icon: swift ios/generate-icon.swift
let size = 1024
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
let context = NSGraphicsContext(bitmapImageRep: bitmap)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
NSColor(srgbRed: 250/255, green: 249/255, blue: 245/255, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: size, height: size).fill()
NSColor(srgbRed: 232/255, green: 224/255, blue: 210/255, alpha: 1).setFill()
NSBezierPath(ovalIn: NSRect(x: 145, y: 145, width: 734, height: 734)).fill()
NSColor(srgbRed: 169/255, green: 88/255, blue: 62/255, alpha: 1).set()
let stem = NSBezierPath()
stem.move(to: NSPoint(x: 430, y: 200))
stem.curve(to: NSPoint(x: 540, y: 815), controlPoint1: NSPoint(x: 560, y: 420), controlPoint2: NSPoint(x: 560, y: 650))
stem.lineWidth = 22
stem.lineCapStyle = .round
stem.stroke()
for (x, y, endX, endY) in [(530.0, 670.0, 770.0, 800.0), (527.0, 510.0, 280.0, 690.0), (490.0, 355.0, 750.0, 515.0)] {
    let leaf = NSBezierPath()
    leaf.move(to: NSPoint(x: x, y: y))
    leaf.curve(to: NSPoint(x: endX, y: endY), controlPoint1: NSPoint(x: endX, y: y - 20), controlPoint2: NSPoint(x: endX, y: endY - 10))
    leaf.curve(to: NSPoint(x: x, y: y), controlPoint1: NSPoint(x: x + 30, y: endY + 65), controlPoint2: NSPoint(x: x - 25, y: endY))
    leaf.fill()
}
NSGraphicsContext.restoreGraphicsState()
let directory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    .appendingPathComponent("LittleBamboo/Assets.xcassets/AppIcon.appiconset")
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
try bitmap.representation(using: .png, properties: [:])!.write(to: directory.appendingPathComponent("AppIcon.png"))
