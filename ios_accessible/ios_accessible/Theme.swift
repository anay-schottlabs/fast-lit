import SwiftUI

// This file is the app's whole "design system" in one place: the colors,
// fonts, spacing, and button chrome every screen in ContentView.swift
// draws from. Centralizing these means retuning a color or a button's
// look happens once, here, rather than hunting through 1200+ lines of
// individual screens — and it means every screen automatically looks
// consistent with every other one, rather than each hand-rolling its own
// styling (which is how this app looked before this file existed).
//
// This app is meant for senior readers, so every size chosen below is
// deliberately larger and more generous than a typical iOS app's
// defaults: bigger text, bigger buttons, more spacing between tappable
// things. That's a design decision, not an oversight.

// MARK: - Colors

// Xcode automatically generates a static Color property for every named
// color set in Assets.xcassets (that's what
// DerivedSources/GeneratedAssetSymbols.swift is — a file Xcode writes
// itself at build time, not something in this project's source). So
// Color.surfaceBackground, .surfaceCard, .textPrimary, .textSecondary,
// .rsvpFocalLetter, and .errorText already exist automatically, matching
// each color set's name exactly, each already resolving to the right
// light/dark variant for the current appearance — nothing needs to be
// declared for them here.
//
// The one alias actually worth adding is below: the built-in "AccentColor"
// asset generates as `Color.accent`, not `Color.accentColor` or
// `Color.accentPrimary` — this gives it the more descriptive name used
// everywhere else in this app's code and PrimaryButtonStyle/
// SecondaryButtonStyle below.
extension Color {
    static let accentPrimary = Color.accent
}

// Note: Color.onAccentText (used by PrimaryButtonStyle below, for text/
// icons sitting on top of a solid accentPrimary fill) comes from Xcode's
// auto-generated asset symbols too — deliberately NOT the same as
// surfaceBackground, even though they're close in value in light mode:
// surfaceBackground flips to a warm near-black in dark mode (correct for
// a PAGE background), but a button's warm terracotta fill needs light
// cream text regardless of which appearance the rest of the screen is
// in, so OnAccentText is its own color set that never inverts (see
// Assets.xcassets/OnAccentText.colorset — a single value, no dark variant).

// MARK: - Appearance

// The reader-facing choice behind SettingsView's and HomeView's own
// Light/Dark cards. ".system" still exists as an internal "untouched"
// sentinel value — the default before a reader has picked anything —
// but neither screen's UI offers it as a real choice; both treat it as
// "Light" for display purposes (see each one's own displayedScheme/
// currentScheme) and only ever write .light/.dark back. A plain String
// rawValue (rather than Int or no rawValue at all) so this can be saved
// directly with @AppStorage, which needs its stored type to be one of a
// small set of simple types UserDefaults understands — String is the
// simplest fit here.
/// The reader-facing Light/Dark appearance choice, persisted via
/// @AppStorage as a raw String.
enum AppColorScheme: String {
    case system
    case light
    case dark

    // What gets handed to SwiftUI's ".preferredColorScheme(_:)" modifier.
    // .system deliberately does NOT map to nil ("follow the system
    // setting") — a fresh install (or a Settings reset, see
    // SettingsView's resetApp()) has this as its untouched default, and
    // the app must always open in Light that first time regardless of
    // the device's own Dark Mode setting, matching what the Light/Dark
    // picker already displays as selected in that untouched state (see
    // this enum's own top comment). So .system forces .light exactly
    // like an explicit .light choice would; only an explicit .dark pick
    // ever produces Dark.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return .light
        case .light: return .light
        case .dark: return .dark
        }
    }

    // The Home Screen icon no longer changes with this pick — Fast Lit
    // now ships one single AppIcon.appiconset entry regardless of
    // appearance (see Assets.xcassets/AppIcon.appiconset). This used to
    // switch between AppIconLight.appiconset/AppIconDark.appiconset via
    // UIApplication.setAlternateIconName(_:), but that API always shows
    // a system confirmation alert ("Fast Lit Wants to Change the App
    // Icon") with no way to suppress it — jarring on every reader
    // Light/Dark pick for a benefit (matching Home Screen icon to in-app
    // theme) that wasn't worth that interruption.
}

// MARK: - Fonts

// "extension Font" works the same way as the Color extension above: it
// adds new named font styles to SwiftUI's existing Font type.
extension Font {
    // Every style below builds on one of SwiftUI's built-in "text
    // styles" (.largeTitle, .title, .title2, .title3, .callout, etc.)
    // rather than a fixed point size like ".system(size: 30)" — text
    // styles automatically grow or shrink when someone changes their
    // system text size in Settings > Accessibility > Display & Text
    // Size > Larger Text. Given this app's audience, respecting that
    // setting matters more than pixel-perfect control over exact sizes.

    // The everyday body/label/paragraph text style used almost
    // everywhere in this app. Deliberately several steps larger than
    // SwiftUI's default ".body" (17pt) — "comfortable" reading size is
    // this app's baseline for every reader, not an opt-in accessibility
    // extra.
    static let comfortableBody = Font.system(.title2, design: .rounded)

    // Text inside PrimaryButtonStyle/SecondaryButtonStyle buttons — large
    // and semibold so every button reads clearly at a glance.
    static let buttonLabel = Font.system(.title, design: .rounded).weight(.semibold)

    // The small caption under an icon-only button (see ReadView's
    // transport controls) — smaller than buttonLabel since it sits below
    // a big icon rather than being the whole point of the button.
    static let buttonCaption = Font.system(.caption, design: .rounded).weight(.semibold)

    // A library's join code is something a reader needs to read
    // correctly off the screen (often to type or say aloud elsewhere),
    // so it gets its own large, bold, monospaced style — monospaced
    // keeps every character the same width, which makes strings like
    // "2P5-G3U" easier to read letter-by-letter than proportional text.
    // (Kept as the true ".monospaced" design, not ".rounded", since a
    // code is meant to be read character-by-character precisely, not
    // to feel decorative.)
    static let joinCode = Font.system(.title, design: .monospaced).weight(.bold)
}

// MARK: - Spacing & sizing

/// Shared spacing/sizing constants — a namespace-only enum (no cases),
/// e.g. `Spacing.medium`.
// A plain enum used purely as a namespace here (it has no cases) — this
// is a common Swift pattern for grouping related constants under one
// name, e.g. "Spacing.medium", without needing an instance of anything.
enum Spacing {
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let extraLarge: CGFloat = 32

    // Every button in this app (via PrimaryButtonStyle/SecondaryButtonStyle
    // below) is at least this tall. Apple's own minimum recommended tap
    // target is 44pt; this app deliberately goes well beyond that, since
    // older adults on average have less precise fine motor control than
    // Apple's baseline guidance assumes.
    static let buttonHeight: CGFloat = 60
}

// MARK: - Button styles

// A light UIKit impact haptic fired the instant a button is pressed down
// (the false→true edge of isPressed only, via the condition closure —
// not the release too, which would otherwise fire a second pulse on
// every tap). Every custom ButtonStyle below and in OnboardingTheme.swift
// calls this from its own makeBody(configuration:), so every button in
// the app — old design and new — gets the same tactile click without
// each style re-implementing it by hand.
//
// Reads "hapticsEnabled" straight from UserDefaults (rather than an
// @AppStorage property on each ButtonStyle struct that would call this)
// since this is a plain extension method, not a View/ButtonStyle of its
// own — a direct read is simplest, and it's read fresh on every tap
// anyway rather than needing to redraw when the setting changes, so
// there's no reactivity to lose by skipping @AppStorage here. Missing
// key (nothing in UserDefaults yet, e.g. a reader who's never opened
// Settings) defaults to true — haptics on, matching this app's behavior
// before the toggle existed — rather than the false a plain
// ".bool(forKey:)" would silently fall back to.
extension View {
    func buttonPressHaptic(_ isPressed: Bool) -> some View {
        sensoryFeedback(.impact, trigger: isPressed) { _, isPressedNow in
            isPressedNow && (UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true)
        }
    }
}

/// The app's filled, capsule-shaped primary button style — solid
/// accent-colored fill, for the main/emphasized action on a screen.
// ButtonStyle is a protocol SwiftUI provides specifically for this:
// implementing "makeBody(configuration:)" lets one type control exactly
// how EVERY button using it looks (and how it reacts to being pressed),
// rather than repeating the same stack of modifiers on each Button by
// hand across 13 different screens. This app previously used the
// system-provided ".glassProminent"/".glass" button styles; these two
// custom styles replace them with the app's own branded look — fully
// rounded "pill"/capsule buttons, matching this app's monochrome,
// modern-product design language.
struct PrimaryButtonStyle: ButtonStyle {
    // Reads whether the Button this style is attached to is currently
    // disabled (e.g. via ".disabled(readerName.isEmpty)") — SwiftUI's
    // OWN built-in button styles dim automatically when disabled, but a
    // custom ButtonStyle like this one has to opt into that by hand,
    // reading it from the environment the same way any other view would.
    @Environment(\.isEnabled) private var isEnabled

    // "some View" here (like everywhere else "some View" appears in this
    // app) means "returns some specific view type, without spelling out
    // exactly what that type is" — the caller doesn't need to know or
    // care, only that whatever comes back conforms to View.
    func makeBody(configuration: Configuration) -> some View {
        // "configuration.label" is the button's own content (whatever
        // Text/Image/VStack was passed as the button's label) — a
        // ButtonStyle doesn't replace what's INSIDE the button, only how
        // it's framed, colored, and sized.
        configuration.label
            .font(.buttonLabel)
            .foregroundStyle(Color.onAccentText)
            // ".frame(maxWidth: .infinity)" makes the button expand to
            // fill the full width of whatever contains it, rather than
            // hugging just its text — a bigger, more consistent, easier
            // tap target across the whole app.
            .frame(maxWidth: .infinity, minHeight: Spacing.buttonHeight)
            .background(Color.accentPrimary)
            // "Capsule()" — a fully-rounded pill shape, corners rounded
            // to exactly half the button's own height — rather than a
            // RoundedRectangle with some fixed corner radius.
            .clipShape(Capsule())
            // Dimmed further whenever the button is disabled, on top of
            // (not instead of) the isPressed dimming below — so a
            // disabled "Continue" visibly reads as unavailable rather
            // than looking identical to a tappable one.
            .opacity(disabledAdjustedOpacity(pressed: configuration.isPressed))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.15), value: isEnabled)
            .buttonPressHaptic(configuration.isPressed)
    }

    private func disabledAdjustedOpacity(pressed: Bool) -> Double {
        guard isEnabled else { return 0.4 }
        return pressed ? 0.85 : 1.0
    }
}

/// The app's outlined, capsule-shaped secondary button style, for
/// less-emphasized actions like "Go Back".
struct SecondaryButtonStyle: ButtonStyle {
    // See PrimaryButtonStyle's own copy of this property just above for
    // why a custom ButtonStyle needs to read this explicitly.
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.buttonLabel)
            .foregroundStyle(Color.accentPrimary)
            .frame(maxWidth: .infinity, minHeight: Spacing.buttonHeight)
            .background(
                Capsule()
                    // "strokeBorder" draws just the outline of the shape
                    // (rather than filling it), which is what makes this
                    // style read as "secondary" next to PrimaryButtonStyle's
                    // solid fill.
                    .strokeBorder(Color.accentPrimary, lineWidth: 2)
            )
            .opacity(disabledAdjustedOpacity(pressed: configuration.isPressed))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.15), value: isEnabled)
            .buttonPressHaptic(configuration.isPressed)
    }

    private func disabledAdjustedOpacity(pressed: Bool) -> Double {
        guard isEnabled else { return 0.4 }
        return pressed ? 0.6 : 1.0
    }
}

/// A style for buttons whose visuals are already fully hand-built by
/// their own call site — behaves like SwiftUI's own `.plain`, plus the
/// same press haptic every other style in this file bakes in.
// For buttons that don't want ANY of Primary/Secondary's own color,
// sizing, or opacity — icon-only overlays (a Settings gear), ChooseView's
// own list rows, OnboardingSelectableCard's tappable cards — but should
// still feel tappable the same way every other button in this app does.
struct HapticButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .buttonPressHaptic(configuration.isPressed)
    }
}

