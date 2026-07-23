# App Review Notes — Selah 1.0

Selah is a menu-bar-only macOS application. It intentionally has no Dock icon or conventional main window.

To review the app:

1. Launch Selah.
2. Select the book-and-sun icon in the macOS menu bar.
3. The main popover immediately displays the local calendar day’s verse.
4. Use Copy, Save, or Share at the bottom of the popover.
5. Select the heart icon to view or remove saved verses. Select the active heart again to return.
6. Select the gear icon to review appearance, the optional launch-at-login setting, attribution, privacy, support, and Quit App. Select the active gear again to return.

No account, login, network connection, purchase, subscription, or special hardware is required. Launch at login is off by default and is registered only after the user explicitly enables it.

The app does not collect or transmit data. Favorites, recent history, and settings are stored locally in the app sandbox using UserDefaults. The app contains no third-party SDKs.

The bundled Scripture text is the public-domain World English Bible, Protestant Edition. Source and public-domain statement: https://ebible.org/engwebp/

Daily selection is deterministic from the user’s local calendar. It remains stable during the day and automatically advances after local midnight. The selector guarantees a different adjacent-day candidate and does not repeat until it has traversed the complete candidate set.
