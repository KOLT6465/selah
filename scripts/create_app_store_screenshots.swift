#!/usr/bin/env swift

import AppKit

struct Shot {
    let source: String
    let output: String
    let eyebrow: String
    let title: String
    let subtitle: String
    let dark: Bool
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let shots = [
    Shot(
        source: "AppStore/Screenshots/raw/main-dark.png",
        output: "AppStore/Screenshots/01-daily-verse.png",
        eyebrow: "SELAH FOR macOS",
        title: "A quiet verse\nfor every day.",
        subtitle: "Thoughtful Scripture, waiting in your menu bar.",
        dark: true
    ),
    Shot(
        source: "AppStore/Screenshots/raw/main-light.png",
        output: "AppStore/Screenshots/02-private-offline.png",
        eyebrow: "SIMPLE BY DESIGN",
        title: "Entirely offline.\nCompletely private.",
        subtitle: "No account. No tracking. No distractions.",
        dark: false
    ),
    Shot(
        source: "AppStore/Screenshots/raw/saved-light.png",
        output: "AppStore/Screenshots/03-saved-verses.png",
        eyebrow: "KEEP WHAT MOVES YOU",
        title: "Return to the words\nthat stay with you.",
        subtitle: "Save meaningful verses with a single click.",
        dark: false
    ),
    Shot(
        source: "AppStore/Screenshots/raw/settings-dark.png",
        output: "AppStore/Screenshots/04-made-for-mac.png",
        eyebrow: "AT HOME ON YOUR MAC",
        title: "Beautifully simple.\nQuietly yours.",
        subtitle: "Light, dark, and system themes. Ready when you are.",
        dark: true
    ),
]

let canvasSize = NSSize(width: 2560, height: 1600)
let accent = NSColor(calibratedRed: 0.96, green: 0.57, blue: 0.13, alpha: 1)

func drawText(_ text: String, rect: NSRect, font: NSFont, color: NSColor, lineSpacing: CGFloat = 0) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineBreakMode = .byWordWrapping
    paragraph.lineSpacing = lineSpacing
    text.draw(
        in: rect,
        withAttributes: [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
    )
}

func roundedImage(_ image: NSImage, in rect: NSRect, radius: CGFloat) {
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.42)
    shadow.shadowBlurRadius = 55
    shadow.shadowOffset = NSSize(width: 0, height: -22)
    shadow.set()
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    NSColor.black.setFill()
    path.fill()
    path.addClip()
    image.draw(in: rect, from: NSRect(origin: .zero, size: image.size), operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    let border = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    border.lineWidth = 2
    NSColor.white.withAlphaComponent(0.18).setStroke()
    border.stroke()
    NSGraphicsContext.restoreGraphicsState()
}

for shot in shots {
    let sourceURL = root.appendingPathComponent(shot.source)
    guard let source = NSImage(contentsOf: sourceURL) else {
        fatalError("Unable to load \(sourceURL.path)")
    }

    // Remove the Xcode preview title bar while preserving the actual app UI.
    let cropTop: CGFloat = 28
    let cropRect = NSRect(x: 0, y: 0, width: source.size.width, height: source.size.height - cropTop)
    let cropped = NSImage(size: cropRect.size)
    cropped.lockFocus()
    source.draw(
        in: NSRect(origin: .zero, size: cropRect.size),
        from: cropRect,
        operation: .copy,
        fraction: 1
    )
    cropped.unlockFocus()

    let image = NSImage(size: canvasSize)
    image.lockFocus()

    let background: NSGradient
    let primary: NSColor
    let secondary: NSColor
    if shot.dark {
        background = NSGradient(colors: [
            NSColor(calibratedRed: 0.035, green: 0.045, blue: 0.07, alpha: 1),
            NSColor(calibratedRed: 0.09, green: 0.07, blue: 0.065, alpha: 1),
            NSColor(calibratedRed: 0.025, green: 0.032, blue: 0.05, alpha: 1),
        ])!
        primary = NSColor(calibratedWhite: 0.97, alpha: 1)
        secondary = NSColor(calibratedWhite: 0.76, alpha: 1)
    } else {
        background = NSGradient(colors: [
            NSColor(calibratedRed: 0.99, green: 0.965, blue: 0.90, alpha: 1),
            NSColor(calibratedRed: 0.94, green: 0.88, blue: 0.76, alpha: 1),
            NSColor(calibratedRed: 0.985, green: 0.95, blue: 0.87, alpha: 1),
        ])!
        primary = NSColor(calibratedRed: 0.105, green: 0.105, blue: 0.13, alpha: 1)
        secondary = NSColor(calibratedRed: 0.30, green: 0.28, blue: 0.26, alpha: 1)
    }
    background.draw(in: NSRect(origin: .zero, size: canvasSize), angle: -20)

    let glow = NSGradient(starting: accent.withAlphaComponent(0.24), ending: accent.withAlphaComponent(0))!
    glow.draw(
        fromCenter: NSPoint(x: 2210, y: 1260),
        radius: 0,
        toCenter: NSPoint(x: 2210, y: 1260),
        radius: 820,
        options: []
    )

    let sunRect = NSRect(x: 190, y: 1320, width: 46, height: 46)
    accent.setFill()
    NSBezierPath(ovalIn: sunRect).fill()
    drawText(shot.eyebrow, rect: NSRect(x: 260, y: 1317, width: 800, height: 52),
             font: .systemFont(ofSize: 31, weight: .bold), color: accent)
    let titleSize: CGFloat = shot.output.contains("03-") ? 96 : 112
    drawText(shot.title, rect: NSRect(x: 185, y: 715, width: 1160, height: 510),
             font: .systemFont(ofSize: titleSize, weight: .bold), color: primary, lineSpacing: 8)
    drawText(shot.subtitle, rect: NSRect(x: 192, y: 520, width: 1040, height: 150),
             font: .systemFont(ofSize: 42, weight: .regular), color: secondary, lineSpacing: 5)

    let pillRect = NSRect(x: 188, y: 325, width: 560, height: 74)
    let pill = NSBezierPath(roundedRect: pillRect, xRadius: 37, yRadius: 37)
    (shot.dark ? NSColor.white.withAlphaComponent(0.09) : NSColor.white.withAlphaComponent(0.46)).setFill()
    pill.fill()
    drawText("FREE  •  OFFLINE  •  PRIVATE", rect: NSRect(x: 226, y: 344, width: 500, height: 42),
             font: .systemFont(ofSize: 24, weight: .semibold), color: shot.dark ? .white : primary)

    let maxWidth: CGFloat = shot.output.contains("04-") ? 930 : 990
    let scale = min(maxWidth / cropped.size.width, 1230 / cropped.size.height)
    let renderedSize = NSSize(width: cropped.size.width * scale, height: cropped.size.height * scale)
    let appRect = NSRect(
        x: 2560 - renderedSize.width - 170,
        y: (1600 - renderedSize.height) / 2,
        width: renderedSize.width,
        height: renderedSize.height
    )
    roundedImage(cropped, in: appRect, radius: 38)

    image.unlockFocus()

    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let png = bitmap.representation(using: .png, properties: [:])
    else {
        fatalError("Unable to render \(shot.output)")
    }

    let outputURL = root.appendingPathComponent(shot.output)
    try FileManager.default.createDirectory(
        at: outputURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try png.write(to: outputURL, options: .atomic)
    print("Created \(outputURL.path)")
}
