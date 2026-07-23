import SwiftUI

struct VersePopoverView: View {
    enum Page { case verse, saved, settings }

    @ObservedObject var model: AppModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page: Page = .verse
    @State private var measuredVerseHeight: CGFloat = 90

    private let minuteTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            ParchmentBackground()
            VStack(spacing: 0) {
                header
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
                Group {
                    switch page {
                    case .verse: versePage
                    case .saved: savedPage
                    case .settings: SettingsView(model: model)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 380, height: popoverHeight)
        .onReceive(minuteTimer) { _ in model.refreshTodayIfNeeded() }
        .onPreferenceChange(VerseTextHeightKey.self) { height in
            guard height > 0 else { return }
            measuredVerseHeight = height
        }
        .overlay(alignment: .bottom) { noticeToast }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: page)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: model.notice)
        .accessibilityElement(children: .contain)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button {
                page = .verse
                model.showToday()
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.orange)
                        .frame(width: 28, height: 28)
                    Text(model.isShowingToday ? formattedDate : "A verse for this moment")
                        .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.7)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Show today’s verse")

            Spacer()
            HeaderButton(symbol: "heart.fill", label: page == .saved ? "Return home" : "Saved verses", selected: page == .saved) {
                page = page == .saved ? .verse : .saved
            }
            HeaderButton(symbol: "gearshape.fill", label: page == .settings ? "Return home" : "Settings", selected: page == .settings) {
                page = page == .settings ? .verse : .settings
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 16)
        .padding(.bottom, 9)
    }

    private var versePage: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 20, weight: .light))
                        .foregroundStyle(.orange.opacity(0.72))

                    Text(model.displayedVerse.text)
                        .font(.system(size: verseFontSize, weight: .regular, design: .serif))
                        .foregroundStyle(primaryInk)
                        .lineSpacing(6)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                        .background {
                            GeometryReader { geometry in
                                Color.clear.preference(key: VerseTextHeightKey.self, value: geometry.size.height)
                            }
                        }
                        .id(model.displayedVerse.id)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))

                    HStack {
                        Spacer()
                        Image(systemName: "quote.closing")
                            .font(.system(size: 20, weight: .light))
                            .foregroundStyle(.orange.opacity(0.72))
                            .accessibilityHidden(true)
                    }

                    Text(model.displayedVerse.reference)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.orange)
                        .accessibilityLabel("From \(model.displayedVerse.reference)")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 25)
                .padding(.vertical, 19)
            }
            .scrollIndicators(.hidden)

            actionBar
        }
    }

    private var actionBar: some View {
        HStack(spacing: 10) {
            ActionButton(symbol: "doc.on.doc", label: "Copy") { model.copyVerse() }
            ActionButton(symbol: model.isFavorite ? "heart.fill" : "heart", label: model.isFavorite ? "Saved" : "Save", tint: model.isFavorite ? .pink : nil) { model.toggleFavorite() }
            ShareLink(item: model.displayedVerse.shareText) {
                ActionButtonLabel(symbol: "square.and.arrow.up", label: "Share", tint: nil)
            }
            .buttonStyle(ActionButtonStyle())
            .accessibilityLabel("Share verse")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 19)
    }

    private var savedPage: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Saved verses")
                .font(.system(size: 24, weight: .semibold, design: .serif))
                .padding(.horizontal, 24)

            if model.favoriteVerses.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "heart")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(.orange)
                    Text("A quiet place to return")
                        .font(.system(size: 17, weight: .semibold, design: .serif))
                    Text("Save a verse and it will appear here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxHeight: .infinity)
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(model.favoriteVerses) { verse in
                            HStack(spacing: 8) {
                                VStack(alignment: .leading, spacing: 7) {
                                    Text(verse.text)
                                        .font(.system(size: 14, design: .serif))
                                        .lineLimit(3)
                                        .multilineTextAlignment(.leading)
                                    Text(verse.reference)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.orange)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .accessibilityElement(children: .combine)

                                Button {
                                    model.removeFavorite(verse)
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 26, height: 26)
                                        .background(.primary.opacity(0.07), in: Circle())
                                }
                                .buttonStyle(.plain)
                                .help("Remove from saved verses")
                                .accessibilityLabel("Remove \(verse.reference) from saved verses")
                            }
                            .padding(14)
                            .background(.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)
                }
                .scrollIndicators(.hidden)
            }
        }
        .padding(.top, 8)
    }

    @ViewBuilder private var noticeToast: some View {
        if let notice = model.notice {
            Text(notice)
                .font(.caption.weight(.medium))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(.ultraThickMaterial, in: Capsule())
                .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
                .padding(.bottom, 12)
                .onTapGesture { model.dismissNotice() }
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var formattedDate: String {
        Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    private var verseFontSize: CGFloat {
        model.displayedVerse.text.count > 270 ? 20 : model.displayedVerse.text.count > 180 ? 22 : 24
    }

    private var primaryInk: Color {
        colorScheme == .dark ? Color(red: 0.94, green: 0.92, blue: 0.86) : Color(red: 0.16, green: 0.18, blue: 0.22)
    }

    private var popoverHeight: CGFloat {
        switch page {
        case .verse:
            min(506, max(330, 270 + measuredVerseHeight))
        case .saved:
            model.favoriteVerses.isEmpty ? 330 : min(480, max(330, 220 + CGFloat(model.favoriteVerses.count) * 92))
        case .settings:
            420
        }
    }
}

private struct VerseTextHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 90
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
