import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Settings")
                .font(.system(size: 24, weight: .semibold, design: .serif))

            VStack(alignment: .leading, spacing: 9) {
                Text("APPEARANCE")
                    .font(.caption2.weight(.bold))
                    .tracking(1.1)
                    .foregroundStyle(.secondary)
                Picker("Appearance", selection: appearanceBinding) {
                    ForEach(AppAppearance.allCases) { appearance in
                        Text(appearance.label).tag(appearance)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Divider().opacity(0.55)

            Toggle(isOn: launchAtLoginBinding) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Open Selah at login").font(.system(size: 14, weight: .semibold))
                    Text("Keep the day’s verse close at hand.").font(.caption).foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)

            Divider().opacity(0.55)

            VStack(alignment: .leading, spacing: 7) {
                Text("SCRIPTURE")
                    .font(.caption2.weight(.bold))
                    .tracking(1.1)
                    .foregroundStyle(.secondary)
                Text("World English Bible · Protestant Edition")
                    .font(.system(size: 13, weight: .semibold))
                Text("Public domain. Stored on this Mac and available entirely offline.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 14) {
                    Link("Attribution", destination: URL(string: "https://ebible.org/engwebp/")!)
                    Link("Privacy", destination: URL(string: "https://kolt6465.github.io/selah/privacy.html")!)
                    Link("Support", destination: URL(string: "https://kolt6465.github.io/selah/support.html")!)
                }
                .font(.caption.weight(.semibold))
            }

            Spacer(minLength: 8)

            Button { model.quit() } label: {
                HStack(spacing: 8) {
                    Image(systemName: "power")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundStyle(.orange)
                        .frame(width: 23, height: 23)
                        .background(.orange.opacity(0.14), in: Circle())

                    Text("Quit App")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.primary)
                .frame(width: 146, height: 34)
                .background(
                    LinearGradient(
                        colors: [.orange.opacity(0.105), .primary.opacity(0.035)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    in: RoundedRectangle(cornerRadius: 11, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(.orange.opacity(0.16), lineWidth: 1)
                }
            }
                .buttonStyle(.plain)
                .accessibilityLabel("Quit App")
                .keyboardShortcut("q")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
                .padding(.bottom, 4)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 26)
    }

    private var appearanceBinding: Binding<AppAppearance> {
        Binding(get: { model.preferences.appearance }, set: { model.setAppearance($0) })
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(get: { model.preferences.launchAtLogin }, set: { model.setLaunchAtLogin($0) })
    }
}
