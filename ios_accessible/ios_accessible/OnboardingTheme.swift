import SwiftUI

// A second, SEPARATE little design system, used ONLY by the first-time
// onboarding sequence (HomeView's welcome/name/theme/account-choice
// steps) and the "Who's Joining Us?" screen those steps share with
// AccountView. Deliberately its own file, with its own colors, fonts,
// and button/card styles — NOT built from Theme.swift's own
// Color.surfaceBackground/.textPrimary/.accentPrimary,
// PrimaryButtonStyle, AppMascot, etc. Those are the rest of the app's
// look (warm cream/terracotta, SF Rounded) and stay exactly as they
// are; onboarding's own look (cooler grayscale/beige, no accent color
// at all, Baloo 2 + Quicksand) is a deliberately different, from-scratch
// redesign that shouldn't bleed into — or be bled into by — anything
// else in the app. Every type/color/font here is prefixed "Onboarding"
// for exactly that reason: so it's never ambiguous, at a glance, which
// design system a given line of code is drawing from.

// MARK: - Colors

// Like Theme.swift's own colors, these seven all come from
// Assets.xcassets (OnboardingBackground.colorset, OnboardingCard.colorset,
// etc.) — Xcode generates a matching static Color property for each one
// automatically, already resolving to the right light/dark variant, so
// there's nothing to declare here. Their values are the exact hex codes
// from the design handoff doc (see design_handoff_onboarding_flow/
// README.md's "Design Tokens" section) — not approximations of the rest
// of the app's palette.

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
    }

    private func disabledAdjustedOpacity(pressed: Bool) -> Double {
        // The design spec's own number for a disabled Continue button —
        // matches Theme.swift's PrimaryButtonStyle by coincidence, not
        // by sharing code with it.
        guard isEnabled else { return 0.4 }
        return pressed ? 0.85 : 1.0
    }
}

// "Go Back" on every non-welcome onboarding screen — plain text, no
// border or fill, in the flow's secondary (not primary) text color.
struct OnboardingBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Go Back", systemImage: "chevron.left")
        }
        .buttonStyle(OnboardingTextButtonStyle())
    }
}

private struct OnboardingTextButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(OnboardingFont.body(17, weight: .semiBold))
            .foregroundStyle(Color.onboardingTextSecondary)
            .opacity(isEnabled ? (configuration.isPressed ? 0.5 : 1.0) : 0.4)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Page header

// The title (Baloo 2 Bold) + optional subtitle (Quicksand SemiBold)
// every onboarding screen shows below its mascot — a title SIZE is
// passed in rather than fixed, since the design spec gives each screen
// its own distinct size (58/34/32/25) rather than one shared scale.
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
// NOT Theme.swift's flame "Ember" (AppMascot), which stays exactly as
// it is for every OTHER screen in the app (ReturningHomeView,
// ReaderAccountView, ...). The design spec defines three interchangeable
// styles; "orbit" is the one actually used throughout this flow, but all
// three are implemented here since the design explicitly calls this out
// as a swappable style rather than a one-off choice.
enum OnboardingMascotStyle {
    case dot
    case orbit
    case crescent
}

struct OnboardingMascot: View {
    // Every other measurement is a fraction of this one number, same
    // idea as Theme.swift's own AppMascot — HomeView's onboarding
    // passes a smaller size at each successive step (170 → 110 → 96 →
    // 56), so the mascot visibly settles down in size as a reader's
    // attention shifts toward the actual choices being asked of them.
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
        }
        .buttonStyle(.plain)
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
