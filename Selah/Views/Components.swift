import SwiftUI

struct ParchmentBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(colors: baseColors, startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle()
                .fill(Color.orange.opacity(colorScheme == .dark ? 0.12 : 0.16))
                .frame(width: 270, height: 270)
                .blur(radius: 70)
                .offset(x: 155, y: -215)
            Circle()
                .fill(Color.blue.opacity(colorScheme == .dark ? 0.08 : 0.055))
                .frame(width: 220, height: 220)
                .blur(radius: 80)
                .offset(x: -170, y: 235)
            Canvas { context, size in
                for index in 0..<34 {
                    let x = CGFloat((index * 83) % 379) / 379 * size.width
                    let y = CGFloat((index * 137) % 521) / 521 * size.height
                    context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.2, height: 1.2)), with: .color(.primary.opacity(0.035)))
                }
            }
        }
        .ignoresSafeArea()
    }

    private var baseColors: [Color] {
        colorScheme == .dark
            ? [Color(red: 0.055, green: 0.067, blue: 0.09), Color(red: 0.09, green: 0.085, blue: 0.095)]
            : [Color(red: 0.985, green: 0.965, blue: 0.91), Color(red: 0.96, green: 0.925, blue: 0.84)]
    }
}

struct HeaderButton: View {
    let symbol: String
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 28, height: 28)
                .background(selected ? Color.orange.opacity(0.16) : Color.primary.opacity(0.055), in: Circle())
                .foregroundStyle(selected ? .orange : .secondary)
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct ActionButtonLabel: View {
    let symbol: String
    let label: String
    let tint: Color?

    var body: some View {
        Label(label, systemImage: symbol)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(tint ?? .primary)
            .frame(maxWidth: .infinity)
            .frame(height: 34)
    }
}

struct ActionButton: View {
    let symbol: String
    let label: String
    var tint: Color? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) { ActionButtonLabel(symbol: symbol, label: label, tint: tint) }
            .buttonStyle(ActionButtonStyle())
            .accessibilityLabel(label)
    }
}

struct ActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(.primary.opacity(configuration.isPressed ? 0.12 : 0.065), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}
