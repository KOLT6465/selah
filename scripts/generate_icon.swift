#!/usr/bin/env swift
import AppKit

let output = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "Selah/Assets.xcassets/AppIcon.appiconset")
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

func makeIcon(size: Int) throws {
    let s = CGFloat(size)
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else { return }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    defer { NSGraphicsContext.restoreGraphicsState() }

    let bounds = NSRect(x: 0, y: 0, width: s, height: s)
    let inset = s * 0.035
    let background = NSBezierPath(roundedRect: bounds.insetBy(dx: inset, dy: inset), xRadius: s * 0.22, yRadius: s * 0.22)
    NSGradient(colors: [
        NSColor(calibratedRed: 0.055, green: 0.075, blue: 0.12, alpha: 1),
        NSColor(calibratedRed: 0.12, green: 0.105, blue: 0.13, alpha: 1),
    ])!.draw(in: background, angle: -55)

    NSGraphicsContext.saveGraphicsState()
    let glow = NSBezierPath(ovalIn: NSRect(x: s * 0.47, y: s * 0.45, width: s * 0.6, height: s * 0.6))
    NSColor(calibratedRed: 1, green: 0.55, blue: 0.16, alpha: 0.17).setFill()
    glow.fill()
    NSGraphicsContext.restoreGraphicsState()

    let sunCenter = NSPoint(x: s * 0.69, y: s * 0.69)
    let sunRadius = s * 0.105
    NSColor(calibratedRed: 1, green: 0.58, blue: 0.18, alpha: 1).setStroke()
    let rays = NSBezierPath()
    rays.lineWidth = max(1, s * 0.018)
    rays.lineCapStyle = .round
    for index in 0..<12 {
        let angle = CGFloat(index) * .pi / 6
        rays.move(to: NSPoint(x: sunCenter.x + cos(angle) * sunRadius * 1.35, y: sunCenter.y + sin(angle) * sunRadius * 1.35))
        rays.line(to: NSPoint(x: sunCenter.x + cos(angle) * sunRadius * 1.72, y: sunCenter.y + sin(angle) * sunRadius * 1.72))
    }
    rays.stroke()
    NSColor(calibratedRed: 1, green: 0.56, blue: 0.14, alpha: 1).setFill()
    NSBezierPath(ovalIn: NSRect(x: sunCenter.x - sunRadius, y: sunCenter.y - sunRadius, width: sunRadius * 2, height: sunRadius * 2)).fill()

    let bookTop = s * 0.54
    let bookBottom = s * 0.22
    let center = s * 0.5
    let left = NSBezierPath()
    left.move(to: NSPoint(x: center, y: bookBottom))
    left.curve(to: NSPoint(x: s * 0.17, y: s * 0.29), controlPoint1: NSPoint(x: s * 0.4, y: s * 0.24), controlPoint2: NSPoint(x: s * 0.26, y: s * 0.3))
    left.line(to: NSPoint(x: s * 0.17, y: bookTop))
    left.curve(to: NSPoint(x: center, y: s * 0.45), controlPoint1: NSPoint(x: s * 0.28, y: s * 0.56), controlPoint2: NSPoint(x: s * 0.42, y: s * 0.52))
    left.close()
    let right = NSBezierPath()
    right.move(to: NSPoint(x: center, y: bookBottom))
    right.curve(to: NSPoint(x: s * 0.83, y: s * 0.29), controlPoint1: NSPoint(x: s * 0.6, y: s * 0.24), controlPoint2: NSPoint(x: s * 0.74, y: s * 0.3))
    right.line(to: NSPoint(x: s * 0.83, y: bookTop))
    right.curve(to: NSPoint(x: center, y: s * 0.45), controlPoint1: NSPoint(x: s * 0.72, y: s * 0.56), controlPoint2: NSPoint(x: s * 0.58, y: s * 0.52))
    right.close()
    NSColor(calibratedRed: 0.98, green: 0.94, blue: 0.82, alpha: 1).setFill()
    left.fill(); right.fill()
    NSColor(calibratedRed: 0.72, green: 0.36, blue: 0.15, alpha: 0.75).setStroke()
    let spine = NSBezierPath()
    spine.lineWidth = max(1, s * 0.012)
    spine.move(to: NSPoint(x: center, y: bookBottom))
    spine.line(to: NSPoint(x: center, y: s * 0.46))
    spine.stroke()

    guard let png = bitmap.representation(using: .png, properties: [:]) else { return }
    try png.write(to: output.appendingPathComponent("icon_\(size).png"))
}

for size in [16, 32, 64, 128, 256, 512, 1024] { try makeIcon(size: size) }
print("Generated Selah app icons in \(output.path)")
