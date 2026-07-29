import SwiftUI

/// A second, SEPARATE design system from Theme.swift — used only by the
/// first-time onboarding sequence, the account-choice screen it shares
/// with AccountView, and the library sign-up flow. Every type/color/font
/// in this file is prefixed "Onboarding" so it's never ambiguous which
/// design system a given line of code is drawing from.
// A second, SEPARATE little design system, used ONLY by the first-time
// onboarding sequence (HomeView's welcome/name/theme/account-choice
// steps), the "Who's Joining Us?" screen those steps share with
// AccountView, and the library sign-up flow (LibrarySignUpView) that
// continues on from it. Deliberately its own file, with its own colors,
// fonts, and button/card styles — NOT built from Theme.swift's own
// Color.surfaceBackground/.textPrimary/.accentPrimary,
// PrimaryButtonStyle, PageHeader, etc. Those are the rest of the app's
// look (warm cream/terracotta, SF Rounded) and stay exactly as they
// are; onboarding's own look (cooler grayscale/beige, no accent color
// at all, Baloo 2 + Quicksand) is a deliberately different, from-scratch
// redesign that shouldn't bleed into — or be bled into by — anything
// else in the app. Every type/color/font here is prefixed "Onboarding"
// for exactly that reason: so it's never ambiguous, at a glance, which
// design system a given line of code is drawing from.

// MARK: - Colors

// Like Theme.swift's own colors, these all come from Assets.xcassets
// (OnboardingBackground.colorset, OnboardingCard.colorset, etc.) — Xcode
// generates a matching static Color property for each one automatically,
// already resolving to the right light/dark variant, so there's nothing
// to declare here. Their values are the exact hex codes from the design
// handoff doc (see design_handoff_onboarding_flow/README.md's "Design
// Tokens" section) — not approximations of the rest of the app's
// palette. OnboardingError is the one exception to "strictly
// grayscale/beige" — see OnboardingErrorLabel below for why.

// MARK: - Fonts

// The design's two Google Fonts, Baloo 2 (bubbly display face, used for
// every title) and Quicksand (body/UI face, used for everything else),
// bundled as two variable font files (see the project's Fonts/ folder)
// rather than one file per weight — modern Google Fonts ship as a single
// "variable font" covering a whole weight range, but they still embed
// separate NAMED INSTANCES for each traditional weight (Regular, Medium,
// SemiBold, Bold, ...), each with its own real PostScript name
// (e.g. "Baloo2-Bold") that Font.custom(_:size:) can address directly,
// exactly as if it were its own separate font file.
/// Onboarding's two type faces: `.display` (Baloo 2, titles) and `.body`
/// (Quicksand, everything else).
enum OnboardingFont {
    // Every title in this flow ("Welcome", "What should we call you?",
    // ...) uses the same Baloo 2 weight (Bold/700) — just at a different
    // size per screen — so this takes a size but no weight parameter.
    static func display(_ size: CGFloat) -> Font {
        .custom("Baloo2-Bold", size: size)
    }

    // Everything else — taglines, subtext, button labels, "Go Back",
    // the small uppercase wordmark — uses Quicksand at one of three
    // weights.
    static func body(_ size: CGFloat, weight: QuicksandWeight) -> Font {
        .custom(weight.postScriptName, size: size)
    }

    enum QuicksandWeight {
        case medium
        case semiBold
        case bold

        var postScriptName: String {
            switch self {
            case .medium: return "Quicksand-Medium"
            case .semiBold: return "Quicksand-SemiBold"
            case .bold: return "Quicksand-Bold"
            }
        }
    }
}

// MARK: - Button styles

// The pill "Get Started"/"Continue" button every onboarding screen ends
// with — same shape as Theme.swift's own PrimaryButtonStyle (full-width
// capsule, 60pt tall) but filled with the onboarding flow's own
// monochrome "text" color rather than the app's terracotta accent, since
// this flow deliberately uses no accent color anywhere.
/// The pill "Get Started"/"Continue" button every onboarding screen ends
/// with — onboarding's equivalent of Theme.swift's PrimaryButtonStyle.
struct OnboardingPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(OnboardingFont.body(19, weight: .bold))
            .foregroundStyle(Color.onboardingOnPrimary)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(Color.onboardingText)
            .clipShape(Capsule())
            .opacity(disabledAdjustedOpacity(pressed: configuration.isPressed))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.15), value: isEnabled)
            .buttonPressHaptic(configuration.isPressed)
    }

    private func disabledAdjustedOpacity(pressed: Bool) -> Double {
        // The design spec's own number for a disabled Continue button —
        // matches Theme.swift's PrimaryButtonStyle by coincidence, not
        // by sharing code with it.
        guard isEnabled else { return 0.4 }
        return pressed ? 0.85 : 1.0
    }
}

// The outlined pill next to a filled OnboardingPrimaryButtonStyle one —
// used where this flow needs a second, less-emphasized full-width action
// alongside its primary one (e.g. "Log In" beside "Sign Up" on the
// library auth choice screen). Same capsule shape and sizing as the
// primary style, just a 2px border in this flow's own border token
// instead of a solid fill — matching Theme.swift's own
// SecondaryButtonStyle shape, built from this flow's separate tokens.
/// The outlined pill that pairs with OnboardingPrimaryButtonStyle for a
/// secondary, less-emphasized action.
struct OnboardingSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(OnboardingFont.body(19, weight: .bold))
            .foregroundStyle(Color.onboardingText)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(
                Capsule()
                    .strokeBorder(Color.onboardingBorder, lineWidth: 2)
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

// A hand-drawn switch — a capsule track plus a circular knob, both
// simple solid fills — for the same reason PrimaryButtonStyle/
// SecondaryButtonStyle above don't use SwiftUI's own default button
// chrome: the platform's own default Toggle (".switch" style) on recent
// iOS versions renders with a translucent "glass" material baked in,
// which doesn't fit this flow's flat, opaque, no-accent-color look.
// Drawing the two shapes ourselves sidesteps that entirely rather than
// fighting the system style to turn it off.
/// A hand-drawn capsule-track switch, standing in for the system Toggle
/// so this flow's flat, no-glass look stays consistent.
struct OnboardingToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label

            Spacer()

            Capsule()
                .fill(configuration.isOn ? Color.onboardingText : Color.onboardingBorder)
                .frame(width: 56, height: 34)
                .overlay(
                    Circle()
                        .fill(Color.onboardingCard)
                        .padding(3)
                        // Slides from one edge to the other rather than
                        // scaling/fading — the same "one continuous
                        // motion" feel a real switch has.
                        .offset(x: configuration.isOn ? 11 : -11)
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        configuration.isOn.toggle()
                    }
                }
        }
    }
}

// "Go Back" on every non-welcome onboarding screen — plain text, no
// border or fill, in the flow's secondary (not primary) text color.
/// The "Go Back" link shown near the top of most onboarding screens.
struct OnboardingBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Go Back", systemImage: "chevron.left")
        }
        .buttonStyle(OnboardingTextButtonStyle())
    }
}

/// Plain-text button chrome (no capsule/border) used by OnboardingBackButton.
private struct OnboardingTextButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(OnboardingFont.body(17, weight: .semiBold))
            .foregroundStyle(Color.onboardingTextSecondary)
            .opacity(isEnabled ? (configuration.isPressed ? 0.5 : 1.0) : 0.4)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .buttonPressHaptic(configuration.isPressed)
    }
}

// MARK: - Errors

// The inline validation message under a ghost field (e.g. "Use at least
// 8 characters." on the sign-up password step) — the one place this
// design system departs from strict grayscale/beige, since an error
// genuinely needs to read as different from everything else on screen,
// not just another line of secondary text.
/// The red-toned inline validation message shown under a form field.
struct OnboardingErrorLabel: View {
    let message: String

    // The single-field sign-up steps center everything (their one field
    // is centered too), but LibraryLoginView's two stacked fields are
    // left-aligned — this follows suit there rather than looking
    // oddly centered under left-aligned fields.
    var isLeading: Bool = false

    var body: some View {
        Text(message)
            .font(OnboardingFont.body(14, weight: .semiBold))
            .foregroundStyle(Color.onboardingError)
            .multilineTextAlignment(isLeading ? .leading : .center)
            .frame(maxWidth: .infinity, alignment: isLeading ? .leading : .center)
    }
}

// MARK: - Page header

// The title (Baloo 2 Bold) + optional subtitle (Quicksand SemiBold)
// every onboarding screen shows below its mascot — a title SIZE is
// passed in rather than fixed, since the design spec gives each screen
// its own distinct size (58/34/32/25) rather than one shared scale.
/// The title + optional subtitle block every onboarding screen shows
/// below its mascot.
struct OnboardingPageHeader: View {
    let title: String
    var titleSize: CGFloat = 32
    var subtitle: String? = nil
    var subtitleSize: CGFloat = 17

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(OnboardingFont.display(titleSize))
                .foregroundStyle(Color.onboardingText)
                .multilineTextAlignment(.center)

            if let subtitle {
                Text(subtitle)
                    .font(OnboardingFont.body(subtitleSize, weight: .semiBold))
                    .foregroundStyle(Color.onboardingTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Mascot

// The onboarding flow's own mascot — simple concentric-circle shapes,
// a deliberately separate character from anything in Theme.swift, which
// this flow doesn't draw from at all (see this file's own top comment).
// The design spec defines three interchangeable
// styles; "orbit" is the one actually used throughout this flow, but all
// three are implemented here since the design explicitly calls this out
// as a swappable style rather than a one-off choice.
/// The three interchangeable shapes OnboardingMascot can render.
enum OnboardingMascotStyle {
    case dot
    case orbit
    case crescent
}

/// The onboarding flow's animated mascot: a breathing, optionally
/// sparkle-and-glow-decorated shape drawn in one of three
/// OnboardingMascotStyle variants.
struct OnboardingMascot: View {
    // Every other measurement is a fraction of this one number —
    // HomeView's onboarding passes a smaller size at each successive
    // step (170 → 110 → 96 → 56), so the mascot visibly settles down in
    // size as a reader's attention shifts toward the actual choices
    // being asked of them.
    var size: CGFloat = 120

    // "orbit" is this flow's actual default — see OnboardingMascotStyle
    // just above for why "dot" and "crescent" still exist as real,
    // selectable alternatives rather than being deleted outright.
    var style: OnboardingMascotStyle = .orbit

    // The design shows 2 pulsing "sparkle" dots on Welcome, 1 on
    // Name/Theme, and none at all at the smallest (account-choice)
    // size — passed as a count rather than a bool so each call site can
    // match that exactly.
    var sparkleCount: Int = 0

    // Also absent at the smallest size — see AccountChoiceScreen's own
    // use of this mascot in ContentView.swift.
    var showsGlow: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isBreathing = false
    @State private var sparkle1Pulsing = false
    @State private var sparkle2Pulsing = false

    var body: some View {
        ZStack {
            if showsGlow {
                Circle()
                    .fill(Color.onboardingText)
                    .opacity(0.06)
                    .frame(width: size * 1.4, height: size * 1.4)
                    .blur(radius: size * 0.18)
            }

            if sparkleCount >= 1 {
                sparkle(diameter: size * 0.06)
                    .offset(x: size * 0.42, y: -size * 0.42)
                    .opacity(sparkle1Pulsing ? 0.6 : 0.25)
                    .scaleEffect(sparkle1Pulsing ? 1.1 : 0.85)
            }

            if sparkleCount >= 2 {
                sparkle(diameter: size * 0.04)
                    .offset(x: -size * 0.46, y: size * 0.4)
                    .opacity(sparkle2Pulsing ? 0.6 : 0.25)
                    .scaleEffect(sparkle2Pulsing ? 1.1 : 0.85)
            }

            mascotShape
                .frame(width: size, height: size)
        }
        // Both the sway-free "breathe" scale and the sparkle pulses
        // share this one pivot, matching how the design applies all
        // three as siblings rather than nesting one inside another.
        .scaleEffect(isBreathing ? 1.07 : 1.0)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                sparkle1Pulsing = true
            }
            // A short delay before starting the second sparkle's own
            // identical animation — matches the design's 0.5s offset
            // between the two, so they pulse out of phase with each
            // other rather than in unison.
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true).delay(0.5)) {
                sparkle2Pulsing = true
            }
        }
        .accessibilityHidden(true)
    }

    private func sparkle(diameter: CGFloat) -> some View {
        Circle()
            .fill(Color.onboardingText)
            .frame(width: diameter, height: diameter)
    }

    @ViewBuilder
    private var mascotShape: some View {
        switch style {
        case .dot:
            // A ringed outline with a solid center.
            ZStack {
                Circle()
                    .stroke(Color.onboardingText.opacity(0.25), lineWidth: size * 0.02)
                    .frame(width: size * 0.6, height: size * 0.6)
                Circle()
                    .fill(Color.onboardingText)
                    .frame(width: size * 0.44, height: size * 0.44)
            }
        case .orbit:
            // A thicker ring around a smaller centered dot — this flow's
            // actual default (see OnboardingMascot's own "style" default
            // just above).
            ZStack {
                Circle()
                    .stroke(Color.onboardingText.opacity(0.35), lineWidth: size * 0.04)
                    .frame(width: size * 0.68, height: size * 0.68)
                Circle()
                    .fill(Color.onboardingText)
                    .frame(width: size * 0.32, height: size * 0.32)
            }
        case .crescent:
            // A solid circle with a second, smaller, BACKGROUND-colored
            // circle offset on top of it — the overlapping part reads
            // as "cut out," the same trick the design's own SVG uses,
            // relying on the second circle matching whatever's actually
            // behind the mascot (see OnboardingBackground) rather than
            // any real clipping/masking.
            ZStack {
                Circle()
                    .fill(Color.onboardingText)
                    .frame(width: size * 0.64, height: size * 0.64)
                Circle()
                    .fill(Color.onboardingBackground)
                    .frame(width: size * 0.54, height: size * 0.54)
                    .offset(x: size * 0.13, y: -size * 0.13)
            }
        }
    }
}

// MARK: - Progress bar

// The thin bar shown across the top of every onboarding step after the
// very first — absent on "Welcome" itself, since there's nothing to
// show progress THROUGH yet. "step" is 1-based (Name passes 1, Theme
// passes 2, Account Choice passes 3), matching how a reader would count
// "step 1 of 3" out loud.
/// The thin top-of-screen progress bar shown on every onboarding step
/// after the first.
struct OnboardingProgressBar: View {
    let step: Int
    let total: Int

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.onboardingTrack)
                Capsule()
                    .fill(Color.onboardingText)
                    .frame(width: geometry.size.width * CGFloat(step) / CGFloat(total))
            }
        }
        .frame(height: 6)
        .animation(.easeInOut(duration: 0.3), value: step)
        .accessibilityHidden(true)
    }
}

// MARK: - Selectable cards

// A single generic card shape used for BOTH the Theme step's light/dark
// swatch rows and the Account-choice step's Library/Reader icon rows —
// the two only differ in what sits in the leading slot (a swatch
// preview vs. an icon tile), everything else (title, optional
// description, the 22pt selection ring, the border/fill treatment) is
// identical between them, so it's one generic view rather than two
// near-duplicate ones.
/// A generic tappable row (leading icon/swatch + title + optional
/// description + selection ring) shared by every onboarding "pick one
/// of these options" step.
struct OnboardingSelectableCard<Leading: View>: View {
    // A plain stored value, not an @ViewBuilder closure — every call
    // site passes one already-built view (OnboardingThemeSwatch or
    // OnboardingIconTile) directly, rather than composing several views
    // together the way a trailing-closure @ViewBuilder would be for.
    let leading: Leading
    let title: String
    var description: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                leading

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(OnboardingFont.body(18, weight: .bold))
                        .foregroundStyle(Color.onboardingText)
                    if let description {
                        Text(description)
                            .font(OnboardingFont.body(14, weight: .semiBold))
                            .foregroundStyle(Color.onboardingTextSecondary)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)

                Spacer()

                // A filled ring when selected, a bordered empty one when
                // not — exactly the 22pt/2pt spec, not the app-wide
                // 26/28pt sizes Theme.swift's own selection indicators
                // use elsewhere.
                Circle()
                    .fill(isSelected ? Color.onboardingText : Color.clear)
                    .frame(width: 18, height: 18)
                    .padding(2)
                    .overlay(
                        Circle().stroke(isSelected ? Color.onboardingText : Color.onboardingBorder, lineWidth: 2)
                    )
            }
            .padding(20)
            // Without this, taps only register on the actual rendered
            // content (the icon, text, or ring) — not the padding or the
            // empty space the Spacer() above takes up — so most of the
            // card's own body would silently do nothing when tapped.
            .contentShape(Rectangle())
        }
        // HapticButtonStyle (Theme.swift) rather than plain ".plain" — same
        // "leave the label untouched" behavior, plus the same tap haptic
        // every other button in the app gets.
        .buttonStyle(HapticButtonStyle())
        .background(Color.onboardingCard)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isSelected ? Color.onboardingText : Color.clear, lineWidth: 2)
        )
    }
}

// The Theme step's light/dark swatch — LITERAL colors, not the dynamic
// Color.onboarding* tokens used everywhere else in this file, for the
// same reason Theme.swift's own ThemePreviewCard needed literal colors:
// a dynamic named color only ever resolves to whichever appearance is
// CURRENTLY active, but both the light and dark swatch need to show
// their true colors at the same time, regardless of the device's actual
// current appearance.
/// Literal (not dynamic) light/dark color sets for OnboardingThemeSwatch.
enum OnboardingSwatchPalette {
    case light
    case dark

    var background: Color {
        switch self {
        case .light: return Color(red: 0.949, green: 0.937, blue: 0.914)
        case .dark: return Color(red: 0.118, green: 0.110, blue: 0.102)
        }
    }

    var text: Color {
        switch self {
        case .light: return Color(red: 0.169, green: 0.161, blue: 0.149)
        case .dark: return Color(red: 0.949, green: 0.937, blue: 0.914)
        }
    }

    var border: Color {
        switch self {
        case .light: return Color(red: 0.847, green: 0.827, blue: 0.776)
        case .dark: return Color(red: 0.227, green: 0.216, blue: 0.200)
        }
    }
}

/// A small "Aa" preview card for one OnboardingSwatchPalette, used in the
/// Theme step's light/dark picker.
struct OnboardingThemeSwatch: View {
    let palette: OnboardingSwatchPalette

    var body: some View {
        VStack(spacing: 6) {
            Text("Aa")
                .font(OnboardingFont.body(16, weight: .bold))
                .foregroundStyle(palette.text)
            Capsule()
                .fill(palette.text)
                .frame(width: 36, height: 9)
        }
        .frame(width: 64, height: 64)
        .background(palette.background)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(palette.border, lineWidth: 1)
        )
    }
}

// The Account-choice step's Library/Reader icon tile — sits on the
// onboarding background color (not a tinted accent circle, since this
// flow uses no accent color), leaving the selection ring as the only
// thing on the card that means "selected."
/// A single SF Symbol on a rounded background tile, used as the leading
/// element of the Account-choice step's Library/Reader cards.
struct OnboardingIconTile: View {
    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 24))
            .foregroundStyle(Color.onboardingText)
            .frame(width: 52, height: 52)
            .background(Color.onboardingBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
