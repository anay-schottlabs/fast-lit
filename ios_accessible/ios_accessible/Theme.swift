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
enum AppColorScheme: String {
    case system
    case light
    case dark

    // What gets handed to SwiftUI's ".preferredColorScheme(_:)" modifier.
    // That modifier's parameter is ColorScheme? (optional) — nil there
    // specifically means "don't override, follow the system setting,"
    // which is exactly what .system should do; .light/.dark map onto
    // ColorScheme's own .light/.dark cases to force one or the other.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
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

    // Page titles ("Library Home", "Join Your Library", etc.) —
    // ".rounded" gives every letterform soft, friendly terminals instead
    // of sharp corners, which reads as warmer and more approachable —
    // important for an app meant to feel comforting to seniors and
    // welcoming to readers of all kinds, including kids with special
    // needs. Bold (not the heaviest possible weight) so titles feel
    // confident without feeling like they're shouting.
    static let pageTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)

    // Smaller headings within a screen (e.g. "Your Join Code").
    static let sectionTitle = Font.system(.title, design: .rounded).weight(.semibold)

    // A short, small, bold, letter-spaced label shown ABOVE a PageHeader's
    // title (e.g. "YOUR LIBRARY") — see PageHeader's optional "eyebrow"
    // parameter below. ".uppercase" is applied by PageHeader itself, not
    // baked in here, so callers can still pass ordinary-cased strings.
    static let eyebrow = Font.system(.caption, design: .rounded).weight(.bold)

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

    // Error messages — one step larger than SwiftUI's ".footnote", since
    // an error is important information a reader needs to actually
    // register, not a fine-print afterthought.
    static let errorMessage = Font.system(.callout).weight(.semibold)
}

// MARK: - Spacing & sizing

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

    // A smaller, roughly-square button size used for the WPM +/- steppers
    // in ReadView, where a full-width button wouldn't make sense sitting
    // next to a number.
    static let compactButtonWidth: CGFloat = 64
}

enum Radius {
    // Buttons themselves are full capsules now (see PrimaryButtonStyle/
    // SecondaryButtonStyle below, which use Shape "Capsule()" rather than
    // a RoundedRectangle at all) — this radius is for everything else
    // that's still a rounded rectangle: cards, the join-code entry boxes,
    // list rows. Generously rounded, matching a soft, modern "card" look.
    static let card: CGFloat = 24

    // A tighter radius for small elements (e.g. each box in
    // CodeEntryField) where the full card radius would look odd on
    // something this small.
    static let small: CGFloat = 12
}

// MARK: - Button styles

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
    }

    private func disabledAdjustedOpacity(pressed: Bool) -> Double {
        guard isEnabled else { return 0.4 }
        return pressed ? 0.85 : 1.0
    }
}

// The "secondary" style — outlined rather than filled — used for
// less-emphasized actions like "Go Back".
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
    }

    private func disabledAdjustedOpacity(pressed: Bool) -> Double {
        guard isEnabled else { return 0.4 }
        return pressed ? 0.6 : 1.0
    }
}

// The "Go Back" action repeats across nearly every screen in this app —
// pulling it into one shared button means it always gets the same
// leading chevron icon (rather than being plain text), and any future
// tweak to how "going back" looks/reads only needs to happen here once.
struct BackButton: View {
    let action: () -> Void

    // HomeView's onboarding steps deliberately use the lighter,
    // unbordered TextButtonStyle for "Go Back" (so it doesn't compete
    // with that screen's own "Continue" pill) — everywhere else uses the
    // outlined SecondaryButtonStyle pill, same as every other secondary
    // action in the app.
    var plain: Bool = false

    var body: some View {
        Button(action: action) {
            Label("Go Back", systemImage: "chevron.left")
        }
        .buttonStyle(plain ? AnyButtonStyle(TextButtonStyle()) : AnyButtonStyle(SecondaryButtonStyle()))
    }
}

// SwiftUI's ".buttonStyle(_:)" expects one single concrete type at each
// call site — it can't take "either TextButtonStyle or
// SecondaryButtonStyle depending on a condition" directly, since a
// ternary needs both branches to already be the exact same type. This
// small wrapper erases either one down to the same "AnyButtonStyle" type
// so BackButton's own ternary above can compile.
struct AnyButtonStyle: ButtonStyle {
    private let makeBodyClosure: (Configuration) -> AnyView

    init<S: ButtonStyle>(_ style: S) {
        makeBodyClosure = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        makeBodyClosure(configuration)
    }
}

// A minimal, text-only style — no fill, no outline, just the label
// itself — for actions too light-touch for even SecondaryButtonStyle's
// outlined pill, like stepping back one step in HomeView's onboarding
// sequence. "Never mind, take me back" doesn't need to compete visually
// with the actual forward-moving "Continue" button on the same screen.
// Also used for toolbar buttons (see LibraryCatalogManagementView,
// SettingsView, ReadableContentDetailView) — a toolbar slot is too
// small/compact for even a pill-shaped button, but every button in this
// app should still be one of ITS OWN custom styles rather than falling
// back to the platform-default blue toolbar text.
struct TextButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    // Toolbar "confirm" actions (e.g. "Accept") use this to read as
    // bolder/accent-colored — a primary action, not a de-emphasized one
    // like "Go Back" or a toolbar "Done"/"Cancel".
    var emphasized: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(emphasized ? .buttonLabel : .comfortableBody)
            .foregroundStyle(emphasized ? Color.accentPrimary : Color.textSecondary)
            .opacity(disabledAdjustedOpacity(pressed: configuration.isPressed))
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }

    private func disabledAdjustedOpacity(pressed: Bool) -> Double {
        guard isEnabled else { return 0.4 }
        return pressed ? 0.5 : 1.0
    }
}

// MARK: - Shared screen chrome

// The heading almost every screen in this app starts with: an optional
// small bold all-caps "eyebrow" label, a big heavy title, and an optional
// smaller subtitle underneath. Pulling this out once means every screen's
// heading looks and behaves identically, instead of each of the ~13
// screens hand-rolling its own Text/font/padding combination.
struct PageHeader: View {
    // Optional: a short label shown above the title in small, bold,
    // letter-spaced capitals (e.g. "YOUR LIBRARY") — echoes the small
    // all-caps section labels this app's design language is drawing on.
    // Most screens don't need one, so this defaults to nil.
    var eyebrow: String? = nil

    let title: String

    // Optional: some screens want a short explanatory line under the
    // title, others don't need one. Defaulting to nil means call sites
    // that don't need a subtitle can just omit the parameter entirely,
    // rather than passing an empty string.
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: Spacing.small) {
            if let eyebrow {
                Text(eyebrow)
                    .font(.eyebrow)
                    .foregroundStyle(Color.textSecondary)
                    // ".textCase(.uppercase)" here (rather than requiring
                    // every caller to type their eyebrow text in capitals
                    // already) means callers can write normal, readable
                    // Swift string literals and still always get capitals
                    // on screen.
                    .textCase(.uppercase)
                    // Letter-spacing (".tracking") is what makes a short
                    // all-caps label like this read as an intentional
                    // "label," rather than looking like a title that's
                    // just too small.
                    .tracking(2)
            }

            Text(title)
                .font(.pageTitle)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)

            // "if let subtitle" only unwraps and shows this Text once
            // subtitle is actually non-nil.
            if let subtitle {
                Text(subtitle)
                    .font(.comfortableBody)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.bottom, Spacing.medium)
    }
}

// A consistent "card" treatment — background fill, rounded corners, and a
// soft shadow — used for the handful of standalone card-like containers
// in this app (the join-code display, the code-entry field). Written as
// a View extension (rather than yet another custom ButtonStyle-style
// struct) since it's not swapping out a whole view's content the way
// PrimaryButtonStyle does, just adding a few chained modifiers — the
// exact thing View extensions are for.
extension View {
    func cardStyle() -> some View {
        self
            .background(Color.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            // A soft, low-opacity black shadow reads as "this card is
            // gently raised off the page" in both light and dark mode —
            // unlike a tinted shadow, plain black-at-low-opacity doesn't
            // need its own light/dark variant to still look right.
            .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }
}

// A consistent error message treatment used everywhere a form can fail
// (bad password, username taken, network error, ...). Pairs the error
// color with a warning icon via SwiftUI's "Label" view — which lays out
// an icon next to text for you — rather than relying on color alone,
// since a color-only signal is easy to miss, especially for the
// colorblind readers or less-experienced readers this app is meant to
// welcome.
struct ErrorLabel: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.errorMessage)
            .foregroundStyle(Color.errorText)
            .multilineTextAlignment(.leading)
            .padding(.horizontal)
    }
}

