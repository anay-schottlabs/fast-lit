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

// The reader-facing choice behind HomeView's "Appearance" picker: follow
// the system's own Light/Dark setting, or override it one way regardless
// of what the system says. A plain String rawValue (rather than Int or
// no rawValue at all) so this can be saved directly with @AppStorage,
// which needs its stored type to be one of a small set of simple types
// UserDefaults understands — String is the simplest fit here.
enum AppColorScheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    // Identifiable (needed for ForEach below) just needs some stable,
    // unique id per case — the case's own rawValue already is one, so
    // there's no reason to invent a second value.
    var id: String { rawValue }

    // Not shown on screen — HomeView's picker displays iconName below
    // instead, so this is only ever read as each icon's VoiceOver
    // accessibility label, so the choice is still announced as a word
    // ("Automatic"/"Light"/"Dark") for anyone using a screen reader,
    // even though sighted readers only ever see an icon.
    var label: String {
        switch self {
        case .system: return "Automatic"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    // The SF Symbol (Apple's built-in icon set) shown for each case —
    // the same icon vocabulary iOS's own Settings app uses for
    // Automatic/Light/Dark, so it should already read as familiar rather
    // than needing to be learned.
    var iconName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    // Literal colors used ONLY by ThemePreviewCard's small swatch — NOT
    // the dynamic Color.surfaceBackground/.textPrimary/.accentPrimary
    // used everywhere else in the app. A dynamic named color can only
    // ever resolve to whichever appearance is currently active, but
    // ThemePreviewCard needs to show what BOTH Light and Dark actually
    // look like side by side, at the same time — these mirror the exact
    // values in Assets.xcassets' SurfaceBackground/TextPrimary/
    // AccentColor color sets for each appearance, so if that palette is
    // ever retuned, these three should be updated to match.
    var previewBackground: Color {
        switch self {
        case .system, .light: return Color(red: 0.984, green: 0.953, blue: 0.906)
        case .dark: return Color(red: 0.141, green: 0.114, blue: 0.086)
        }
    }

    var previewText: Color {
        switch self {
        case .system, .light: return Color(red: 0.239, green: 0.196, blue: 0.149)
        case .dark: return Color(red: 0.949, green: 0.914, blue: 0.863)
        }
    }

    var previewAccent: Color {
        switch self {
        case .system, .light: return Color(red: 0.910, green: 0.475, blue: 0.310)
        case .dark: return Color(red: 0.949, green: 0.588, blue: 0.420)
        }
    }

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
    // everywhere in this app. Deliberately one step larger than SwiftUI's
    // default ".body" (17pt) — "comfortable" reading size is this app's
    // baseline for every reader, not an opt-in accessibility extra.
    static let comfortableBody = Font.system(.title3, design: .rounded)

    // Text inside PrimaryButtonStyle/SecondaryButtonStyle buttons — large
    // and semibold so every button reads clearly at a glance.
    static let buttonLabel = Font.system(.title2, design: .rounded).weight(.semibold)

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

// A minimal, text-only style — no fill, no outline, just the label
// itself — for actions too light-touch for even SecondaryButtonStyle's
// outlined pill, like stepping back one step in HomeView's onboarding
// sequence. "Never mind, take me back" doesn't need to compete visually
// with the actual forward-moving "Continue" button on the same screen.
struct TextButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.comfortableBody)
            .foregroundStyle(Color.textSecondary)
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

// MARK: - Mascot

// "Ember" — a simple, friendly placeholder character — drawn entirely
// from basic SwiftUI shapes, no image files involved. This stands in for
// real illustrated artwork the app doesn't have yet; every call site
// just says "AppMascot()" so swapping this out later for a real
// illustration (an Image, most likely) only ever means changing this one
// file. Deliberately just a flame — no face — so it reads as a warm,
// living presence without needing to represent any specific age, gender,
// or identity, approachable to as wide an audience as possible, including
// young readers and readers with special needs. Flickers continuously,
// the way a candle flame never quite sits still, and is skipped entirely
// for anyone with Reduce Motion turned on.
struct AppMascot: View {
    // How big to draw the mascot — every other measurement below is
    // computed as a fraction of this one number, so the whole character
    // scales as a single unit wherever it's used. HomeView's onboarding
    // flow passes a larger size at each step, so Ember visibly "grows"
    // as a reader moves through it.
    var size: CGFloat = 120

    // Multiplies how far Ember sways/breathes each flicker — 1.0 is the
    // default motion; HomeView's onboarding flow passes a larger value
    // at each step, alongside a bigger size, so Ember reads as more
    // energetic/alive the further along a reader gets.
    var flickerIntensity: Double = 1.0

    // Multiplies how FAST each flicker cycle runs — above 1.0 is faster
    // (a shorter cycle duration), below 1.0 is slower.
    var flickerSpeed: Double = 1.0

    // Reads the system's "Reduce Motion" accessibility setting — some
    // readers find continuous motion uncomfortable or distracting, so
    // Ember's flicker is skipped entirely rather than just made smaller
    // when this is on.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Toggled once, on appear, to animate between two slightly different
    // poses forever — see .onAppear below. Starting both the rotation
    // and the scale off the SAME boolean keeps the sway and the "breathe"
    // in sync with each other, rather than drifting in and out of phase.
    @State private var isFlickering = false

    private var currentRotationDegrees: Double {
        let amount = 2.5 * flickerIntensity
        return isFlickering ? amount : -amount
    }

    private var currentScale: Double {
        let amount = 0.04 * flickerIntensity
        return isFlickering ? 1 + amount : 1 - amount
    }

    var body: some View {
        ZStack {
            // The outer flame — fuller and rounder than a slender candle
            // flame (see FlameShape's own comment), filled with the
            // app's vibrant accent color.
            FlameShape()
                .fill(Color.accentPrimary)
                .frame(width: size * 0.82, height: size)

            // A smaller, warm-gold "inner flame" near the base — the
            // same trick real flame icons use to suggest a brighter,
            // hotter core, using its own dedicated gold color (see
            // Assets.xcassets/FlameGlow.colorset) rather than just a
            // translucent version of the outer color.
            FlameShape()
                .fill(Color.flameGlow)
                .frame(width: size * 0.4, height: size * 0.5)
                .offset(y: size * 0.2)
        }
        // Both the sway and the "breathe" pivot from the bottom, the way
        // a real flame sways from its base while the tip drifts most —
        // rotating/scaling from the center (SwiftUI's default anchor)
        // would look like the whole shape wobbling in place instead.
        // Each amount is computed as its own local constant first (rather
        // than inline math inside the ternary) — partly for readability,
        // partly because Swift's type-checker can be slow to resolve a
        // ternary with arithmetic on both branches inline.
        .rotationEffect(.degrees(currentRotationDegrees), anchor: .bottom)
        .scaleEffect(currentScale, anchor: .bottom)
        .onAppear {
            guard !reduceMotion else { return }
            // ".repeatForever(autoreverses: true)" keeps swinging back
            // and forth between the two states above indefinitely.
            // flickerSpeed divides the base 1.4-second duration, so a
            // speed above 1.0 cycles faster.
            withAnimation(.easeInOut(duration: 1.4 / flickerSpeed).repeatForever(autoreverses: true)) {
                isFlickering = true
            }
        }
        // Purely decorative — VoiceOver has nothing meaningful to say
        // about a small drawn flame, so it's hidden from the
        // accessibility tree entirely rather than announcing something
        // like "path, path."
        .accessibilityHidden(true)
    }
}

// The flame silhouette AppMascot draws above (twice — once for the outer
// flame, smaller for the inner one): a full, rounded teardrop leaning to
// an off-center point near the top. Wider/fuller than a slender candle
// flame — the extra width low down is what gives Ember some real
// presence rather than reading as a thin sliver.
private struct FlameShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width * 0.5, y: height))
        path.addCurve(
            to: CGPoint(x: width * 0.58, y: 0),
            control1: CGPoint(x: width * -0.08, y: height * 0.74),
            control2: CGPoint(x: width * 0.08, y: height * 0.22)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height),
            control1: CGPoint(x: width * 1.1, y: height * 0.4),
            control2: CGPoint(x: width * 0.95, y: height * 0.88)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Choice cards

// A large, icon-led tappable card — used wherever a screen offers a
// small number of clearly distinct paths (e.g. "I'm a Library" vs "I'm a
// Reader") and a plain text button would leave the choice feeling terse
// or unclear. An icon plus a short title plus a one-line description
// gives a reader more context at a glance than a label alone, and the
// WHOLE card (not just its text) is one big, easy tap target.
struct ChoiceCard: View {
    // The name of an SF Symbol (Apple's built-in icon set) to show in
    // the little circle on the left — e.g. "books.vertical.fill".
    let icon: String

    let title: String
    let description: String

    // "() -> Void" is a closure type: a function taking no arguments,
    // returning nothing. The caller decides what tapping this card
    // actually does.
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.medium) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(Color.accentPrimary)
                    .frame(width: 56, height: 56)
                    // A soft, low-opacity tint of the accent color
                    // (rather than a solid fill) behind the icon — a
                    // gentler, more "pastel" treatment than a hard-edged
                    // solid circle would be.
                    .background(Color.accentPrimary.opacity(0.18))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.sectionTitle)
                        .foregroundStyle(Color.textPrimary)
                    Text(description)
                        .font(.comfortableBody)
                        .foregroundStyle(Color.textSecondary)
                }
                // Lets the text column wrap onto a second line rather
                // than truncating if a description runs long, and keeps
                // the chevron below pinned to the right edge.
                .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(Spacing.large)
        }
        // ".plain" strips SwiftUI's own default button chrome (which
        // would otherwise fight with — or hide entirely — the
        // background/shape/shadow cardStyle() below applies), leaving
        // just this card's own custom look.
        .buttonStyle(.plain)
        .cardStyle()
    }
}

// MARK: - Theme preview

// A big, tappable card used on the onboarding "Light or Dark?" step
// (see HomeView) — shows a genuinely accurate LIVE preview of what the
// app looks like in that specific appearance (not just a label), so a
// reader can actually see both before picking one, and a checkmark/ring
// showing whether this card is the current selection.
struct ThemePreviewCard: View {
    // Only .light or .dark are meaningful here — there's no "preview" of
    // .system, since that's "whatever the device is already set to."
    let scheme: AppColorScheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.medium) {
                // The preview swatch: sample text and a sample pill,
                // colored with LITERAL light/dark values (see
                // AppColorScheme.previewBackground/previewText/
                // previewAccent below) rather than this app's normal
                // dynamic Color.surfaceBackground/.textPrimary/
                // .accentPrimary. A dynamic named color can only ever
                // resolve to whichever appearance is CURRENTLY active —
                // ".preferredColorScheme()" applied to just this small
                // subview turned out not to reliably force the other one
                // to render here, since both cards need to show their
                // true colors AT THE SAME TIME regardless of the device's
                // actual current appearance, literal values are the
                // reliable way to guarantee that.
                VStack(spacing: Spacing.small) {
                    Text("Aa")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(scheme.previewText)
                    Capsule()
                        .fill(scheme.previewAccent)
                        .frame(width: 56, height: 14)
                }
                .frame(width: 88, height: 88)
                .background(scheme.previewBackground)
                .clipShape(RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )

                Text(scheme.label)
                    .font(.sectionTitle)
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                // A filled checkmark when selected, an empty ring when
                // not — same "fill in as you go" idea CodeBox uses below,
                // so the selected card is unmistakable at a glance.
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.accentPrimary)
                } else {
                    Circle()
                        .strokeBorder(Color.textSecondary.opacity(0.35), lineWidth: 2)
                        .frame(width: 28, height: 28)
                }
            }
            .padding(Spacing.large)
        }
        .buttonStyle(.plain)
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .stroke(isSelected ? Color.accentPrimary : Color.clear, lineWidth: 3)
        )
    }
}

// MARK: - Code entry

// A join-code entry field styled as 6 individual boxes (like a one-time-
// passcode UI) rather than one plain text box, with a hyphen drawn
// between the 3rd and 4th box automatically — never typed, just always
// there, since every code AuthService.generateJoinCode() produces is
// exactly 3 characters, a hyphen, then 3 more characters, in that fixed
// shape every time. "code" only ever holds the 6 real characters (no
// hyphen inside it) — callers reconstruct the hyphenated form themselves
// where they actually need it (see ReaderAccountView.join()).
struct CodeEntryField: View {
    @Binding var code: String

    // Every join code is exactly this many real characters, not counting
    // the hyphen — used both to cap typing and to lay out 6 boxes.
    private let codeLength = 6

    // A real, working TextField still has to exist somewhere to actually
    // receive typed characters, paste, and the keyboard — the boxes drawn
    // below are a purely visual read-out of "code", not an input in their
    // own right. This is the standard way to build a custom-looking text
    // field in SwiftUI: keep one real (here, invisible) TextField around
    // to do the actual text-editing work, and draw whatever's wanted
    // reading its bound value. @FocusState lets this view move keyboard
    // focus into that TextField programmatically, from the tap gesture
    // on the boxes below.
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            // The real input. Fully transparent (".clear" foreground and
            // tint hide both the typed characters and the blinking
            // cursor) — only the boxes drawn below it are ever visible.
            TextField("", text: $code)
                .focused($isFocused)
                .textFieldStyle(.plain)
                .foregroundStyle(.clear)
                .tint(.clear)
                // Not .numberPad: join codes mix letters and digits (see
                // AuthService.generateJoinCode), so a digit-only keyboard
                // would make half of any code untypeable.
                .keyboardType(.asciiCapable)
                .textInputAutocapitalization(.characters)
                .onChange(of: code) { _, newValue in
                    // Strips anything that isn't a letter/digit (so
                    // pasting a full "AB3-9F2" — hyphen included — still
                    // works, rather than only accepting raw "AB39F2"),
                    // forces uppercase to match generateJoinCode's own
                    // output, and caps the result at 6 characters so
                    // typing past a complete code just does nothing
                    // rather than growing forever.
                    let cleaned = newValue.uppercased().filter { $0.isLetter || $0.isNumber }
                    code = String(cleaned.prefix(codeLength))
                }

            HStack(spacing: Spacing.small) {
                ForEach(0..<3, id: \.self) { index in
                    CodeBox(character: character(at: index))
                }

                // A drawn bar rather than a Text("-") glyph — a plain
                // hyphen character renders as a thin, easy-to-miss mark
                // in most fonts at this size, especially sitting between
                // two much taller boxes. An explicit shape is guaranteed
                // to actually be as wide/tall as specified, no font
                // rendering involved.
                Capsule()
                    .fill(Color.accentPrimary)
                    .frame(width: 16, height: 5)

                ForEach(3..<6, id: \.self) { index in
                    CodeBox(character: character(at: index))
                }
            }
            // Tapping anywhere on the row of boxes focuses the real,
            // invisible TextField above — the same as tapping directly
            // on an ordinary TextField would.
            .contentShape(Rectangle())
            .onTapGesture {
                isFocused = true
            }
        }
    }

    // The character sitting at a given position in "code", or nil if the
    // reader hasn't typed that far yet — nil is what tells CodeBox below
    // to draw an empty box rather than a letter.
    private func character(at index: Int) -> Character? {
        guard index < code.count else { return nil }
        return code[code.index(code.startIndex, offsetBy: index)]
    }
}

// One box in the CodeEntryField row above: a bordered square showing
// either a single character or nothing. A private type, since nothing
// outside this file has any reason to use a lone code box on its own.
private struct CodeBox: View {
    let character: Character?

    var body: some View {
        Text(character.map(String.init) ?? "")
            .font(.system(.title2, design: .monospaced).weight(.bold))
            .foregroundStyle(Color.textPrimary)
            .frame(width: 44, height: 56)
            .background(Color.surfaceCard)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                    // A filled-in box gets the accent color border, so the
                    // reader can see at a glance how much of the code
                    // they've entered so far — not just by reading the
                    // letters, but by the row of borders "filling in"
                    // left to right.
                    .stroke(character == nil ? Color.textSecondary.opacity(0.4) : Color.accentPrimary, lineWidth: 2)
            )
    }
}
