import SwiftUI // brings in Apple's UI framework
import FirebaseCore

// enum = a fixed set of named cases; used here as a simple "which page" switch.
enum Page {
    case home
    case choose
    case read
    case account
    case library
}

// Which kind of account the user is logging into or signing up for, chosen
// on AccountView before its username/password or six-digit-code form shows.
enum AccountType {
    case library
    case reader
}

// Whether the user wants to log into an existing account or create a new
// one — chosen on each account type's screen before its actual form shows.
// Kept separate from AccountType since sign up asks for a name that log in
// doesn't need, so the two need different fields, not just different titles.
enum AuthMode {
    case login
    case signUp
}

// "struct" = value type. ": View" means it must provide a "body" describing its UI.
// This view just decides which page to show; each page's own UI lives in its
// own struct below, for simplicity.
struct ContentView: View {
    // @State makes SwiftUI track this value and redraw when it changes.
    @State private var currentPage: Page = .home

    // Which content the user picked and accepted, so ReadView knows what to show.
    // Lives here (not in ChooseView) since it needs to survive past ChooseView
    // being swapped out for ReadView.
    @State private var contentToRead: ReadableContent? = nil

    // Set once a reader successfully joins a library by its code (in
    // ReaderAccountView, several screens deep under AccountView). Lives here
    // rather than there since ChooseView — which needs it to know whose
    // catalog selections to filter against — is a sibling of that whole
    // account flow, not a descendant of it.
    @State private var joinedLibraryUid: String? = nil

    // Which kind of account the reader picked — either on HomeView's own
    // final onboarding step (see AccountChoiceScreen in this file), or on
    // AccountView's own copy of that same screen for every later visit.
    // Lives here, one level above both, so a choice made during onboarding
    // survives the hand-off from HomeView to AccountView: once picked,
    // AccountView skips straight to that account type's form instead of
    // asking the same question a second time.
    @State private var accountType: AccountType? = nil

    // Computed property SwiftUI calls whenever it needs to redraw the screen.
    // "some View" = "returns some type conforming to View, exact type not spelled out."
    var body: some View {
        // "ZStack" stacks views on top of each other (unlike VStack/HStack,
        // which lay them out side by side). Color.surfaceBackground here is
        // a SIBLING in that stack, not a ".background()" modifier — that
        // distinction matters: ".background()" sizes the color to match
        // whatever frame the modified view resolves to, and several of the
        // page views below (e.g. AccountView's picker) are plain VStacks
        // with no Spacer, which only take up as much space as their content
        // needs rather than the whole screen — so a ".background()" there
        // would only paint a content-sized rectangle, not the full screen.
        // A ZStack sibling doesn't have that problem: Color is a "flexible"
        // view that expands to fill whatever space it's offered, so it
        // fills the entire screen regardless of how big the page on top of
        // it wants to be. ".ignoresSafeArea()" extends it behind the status
        // bar/notch/home indicator too.
        ZStack {
            Color.surfaceBackground
                .ignoresSafeArea()

            // "Group" is a transparent container — it doesn't add any
            // layout or visual effect of its own, it's just here so this
            // whole if/else chain counts as a single view for the ZStack
            // above to stack alongside the background color.
            Group {
                // We manually swap "pages" by comparing the enum with "==". Each branch
                // hands the $currentPage binding down so that page can change it.
                if currentPage == .home {
                    HomeView(currentPage: $currentPage, accountType: $accountType)
                } else if currentPage == .choose {
                    // "if let" only unwraps and shows ChooseView once joinedLibraryUid
                    // is actually set, which it always is by the time a reader can
                    // reach this page (see ReaderAccountView's "Start Reading" button).
                    if let joinedLibraryUid {
                        ChooseView(currentPage: $currentPage, contentToRead: $contentToRead, libraryUid: joinedLibraryUid)
                    }
                } else if currentPage == .account {
                    AccountView(currentPage: $currentPage, joinedLibraryUid: $joinedLibraryUid, accountType: $accountType)
                } else if currentPage == .library {
                    LibraryView(currentPage: $currentPage)
                } else if currentPage == .read {
                    // "if let" only unwraps and shows ReadView once contentToRead is
                    // actually set, which it always is by the time we reach this page.
                    if let contentToRead {
                        ReadView(content: contentToRead, currentPage: $currentPage)
                    }
                }
            }
        }
    }
}

// Which step of the very-first-launch welcome sequence is showing (see
// HomeView below). Not used again once hasCompletedOnboarding is true,
// when ReturningHomeView takes over instead.
enum OnboardingStep {
    case welcome
    case name
    case theme
    case accountChoice
}

// The first screen shown when the app launches. The very first time
// (while hasCompletedOnboarding is still false) this walks a reader
// through a short welcome sequence — an explicit "Get Started" tap, what
// to call them, a live preview of Light vs Dark, then "Who's Joining
// Us?" — using OnboardingTheme.swift's own separate mascot/fonts/colors,
// NOT the rest of the app's (see that file's own top comment for why).
// The mascot starts big for that first "Welcome" moment and settles
// smaller at each step after, as attention shifts from it to the actual
// choices being asked. Reaching the end hands off straight into
// whichever account type was picked (AccountView skips its own copy of
// that same question — see ContentView's own "accountType", shared
// between the two). Every later visit to Home (e.g. right after signing
// out) skips straight to ReturningHomeView instead, since there's no
// reason to re-ask a name or show the theme preview a second time —
// ReturningHomeView, unlike this one, uses the rest of the app's normal
// look.
struct HomeView: View {
    // @Binding links to a @State var owned by a parent view (ContentView's
    // currentPage), so changing it here updates the parent's value too.
    @Binding var currentPage: Page

    // The same ContentView-level property AccountView reads — set here,
    // on the final onboarding step, so AccountView finds it already
    // answered by the time currentPage switches to .account.
    @Binding var accountType: AccountType?

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("readerName") private var readerName: String = ""

    // Same key ios_accessibleApp.swift's own @AppStorage property reads,
    // and the SAME source of truth the theme step's Light/Dark cards
    // write to directly (see themeStep below) — @AppStorage just
    // reads/writes UserDefaults under the hood, so two separate
    // properties pointed at the same key (one here, one there)
    // automatically stay in sync, and so does the app's real root-level
    // ".preferredColorScheme(_:)" the instant either one changes. Written
    // on tap, not deferred to "Continue" — a reader's pick needs to
    // survive stepping back to Name or forward to Account Choice without
    // requiring a specific button press to "save" it first.
    @AppStorage("appColorScheme") private var appColorSchemeRaw: String = AppColorScheme.system.rawValue

    @State private var onboardingStep: OnboardingStep = .welcome

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                ReturningHomeView(currentPage: $currentPage)
            } else {
                Group {
                    switch onboardingStep {
                    case .welcome:
                        welcomeStep
                    case .name:
                        nameStep
                    case .theme:
                        themeStep
                    case .accountChoice:
                        accountChoiceStep
                    }
                }
                // ".id(onboardingStep)" gives each step's content its own
                // distinct identity, which is what lets the transition
                // below actually animate one step's content OUT and the
                // next step's content IN, rather than SwiftUI treating
                // every step as "the same view, quietly changing."
                .id(onboardingStep)
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        // Animates BOTH the step-to-step transition above and the final
        // hand-off to ReturningHomeView, so nothing about this sequence
        // ever cuts abruptly from one screen to the next.
        .animation(.easeInOut(duration: 0.45), value: onboardingStep)
        .animation(.easeInOut(duration: 0.45), value: hasCompletedOnboarding)
    }

    // Step 1: nothing to fill in yet, just the mascot at its biggest and
    // a real "Get Started" button — no progress bar yet either, since
    // there's nothing to show progress THROUGH until the next step.
    private var welcomeStep: some View {
        VStack(spacing: Spacing.large) {
            Spacer()

            OnboardingMascot(size: 170, sparkleCount: 2)

            OnboardingPageHeader(
                title: "Welcome",
                titleSize: 58,
                subtitle: "Your cozy corner for stories, at your own pace.",
                subtitleSize: 20
            )

            Spacer()

            Button(action: {
                withAnimation { onboardingStep = .name }
            }, label: {
                Text("Get Started")
            })
            .buttonStyle(OnboardingPrimaryButtonStyle())

            // Every other step has a real "Go Back" here; Welcome
            // doesn't (there's nowhere to go back to) — but reserving
            // the same amount of space below the button keeps "Get
            // Started" docked at the exact same height as those steps'
            // "Continue", instead of sitting lower with nothing below it.
            OnboardingBackButton(action: {})
                .hidden()
                .disabled(true)
                .accessibilityHidden(true)
        }
        .padding(Spacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.onboardingBackground.ignoresSafeArea())
    }

    // Step 2: a first name (or nickname) so later screens can greet a
    // reader by it — required, like every other field in this app (see
    // LibraryLoginView/LibrarySignUpView), not skippable.
    private var nameStep: some View {
        VStack(spacing: Spacing.medium) {
            OnboardingProgressBar(step: 1, total: 3)
                .padding(.bottom, Spacing.small)

            Spacer()

            OnboardingMascot(size: 110, sparkleCount: 1)

            OnboardingPageHeader(
                title: "What should we call you?",
                titleSize: 34,
                subtitle: "We'll use this to greet you.",
                subtitleSize: 16
            )

            // A "ghost" field — no box, no fill, just the text itself
            // and a thin line underneath as a subtle guide for where to
            // type — rather than the boxed ".roundedBorder" style every
            // other text field in this app uses. This is the one place
            // that difference makes sense: entering a name here is the
            // whole point of the screen, not one of several fields in a
            // longer form, so it can afford to feel like writing directly
            // on the page instead of filling in a box.
            VStack(spacing: Spacing.small) {
                // "prompt:" (rather than the plain string initializer)
                // lets the placeholder itself be styled — needed here so
                // even the placeholder shows this flow's own secondary
                // color instead of whatever the system's default
                // placeholder gray is.
                TextField(
                    "",
                    text: $readerName,
                    prompt: Text("Your name")
                        .foregroundStyle(Color.onboardingTextSecondary.opacity(0.7))
                )
                .textFieldStyle(.plain)
                .font(OnboardingFont.display(26))
                .foregroundStyle(Color.onboardingText)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.words)
                // Without this, the cursor/selection tint falls back to
                // the app-wide AccentColor (terracotta) — wrong here,
                // since this flow uses no accent color at all.
                .tint(Color.onboardingText)

                Rectangle()
                    .fill(Color.onboardingBorder)
                    .frame(height: 2)
            }
            .padding(.horizontal, Spacing.extraLarge)

            Spacer()

            Button(action: {
                withAnimation { onboardingStep = .theme }
            }, label: {
                Text("Continue")
            })
            .buttonStyle(OnboardingPrimaryButtonStyle())
            .disabled(readerName.trimmingCharacters(in: .whitespaces).isEmpty)

            OnboardingBackButton(action: {
                withAnimation { onboardingStep = .welcome }
            })
        }
        .padding(Spacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.onboardingBackground.ignoresSafeArea())
    }

    // What themeStep's two cards show as selected — reads
    // appColorSchemeRaw directly (see themeStep's own comment), but
    // treats the untouched default ("system," from a reader who hasn't
    // reached this step yet) as "Light" for DISPLAY purposes only, so a
    // card always looks pre-picked the first time this step shows,
    // same as before. Never writes ".system" anywhere itself — only an
    // actual tap on a card does that, via themeStep's own two actions.
    private var displayedScheme: AppColorScheme {
        let stored = AppColorScheme(rawValue: appColorSchemeRaw) ?? .system
        return stored == .system ? .light : stored
    }

    // Step 3: pick Light or Dark (see OnboardingThemeSwatch in
    // OnboardingTheme.swift). Tapping a card writes appColorSchemeRaw
    // directly — immediately, not deferred to "Continue" — so the whole
    // app (this screen included, via ios_accessibleApp.swift's own
    // root-level ".preferredColorScheme(_:)") updates live and the pick
    // survives stepping back to Name or forward to Account Choice either
    // way. "Continue" here just advances to the final "Who's Joining
    // Us?" step; it doesn't need to save anything itself anymore.
    private var themeStep: some View {
        VStack(spacing: Spacing.medium) {
            OnboardingProgressBar(step: 2, total: 3)
                .padding(.bottom, Spacing.small)

            OnboardingMascot(size: 96, sparkleCount: 1)

            OnboardingPageHeader(
                title: "Light or dark?",
                titleSize: 32,
                subtitle: "You can always change this later.",
                subtitleSize: 17
            )

            OnboardingSelectableCard(
                leading: OnboardingThemeSwatch(palette: .light),
                title: "Light",
                isSelected: displayedScheme == .light
            ) {
                appColorSchemeRaw = AppColorScheme.light.rawValue
            }

            OnboardingSelectableCard(
                leading: OnboardingThemeSwatch(palette: .dark),
                title: "Dark",
                isSelected: displayedScheme == .dark
            ) {
                appColorSchemeRaw = AppColorScheme.dark.rawValue
            }

            Spacer()

            Button(action: {
                withAnimation { onboardingStep = .accountChoice }
            }, label: {
                Text("Continue")
            })
            .buttonStyle(OnboardingPrimaryButtonStyle())
            .padding(.top, Spacing.small)

            OnboardingBackButton(action: {
                withAnimation { onboardingStep = .name }
            })
        }
        .padding(Spacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.onboardingBackground.ignoresSafeArea())
    }

    // Step 4, the final onboarding step: the same "Who's Joining Us?"
    // choice AccountView asks on every later visit (see
    // AccountChoiceScreen below), reused here with its progress bar
    // showing and "Go Back" returning to the theme step instead of Home.
    // Picking a type and tapping Continue is what finally marks
    // onboarding as finished and hands off to AccountView, which — since
    // accountType is already answered — skips straight to that type's
    // own form.
    private var accountChoiceStep: some View {
        AccountChoiceScreen(showProgress: true, onContinue: { chosen in
            accountType = chosen
            hasCompletedOnboarding = true
            currentPage = .account
        }, onBack: {
            withAnimation { onboardingStep = .theme }
        })
    }
}

// Shown every time a reader reaches Home EXCEPT the very first time (see
// HomeView above, which handles that one-time welcome sequence instead)
// — most commonly right after signing out. Deliberately much simpler
// than that first-time sequence: just Ember, a greeting, one tap to
// continue, and a small way into Settings — no need to re-ask a name or
// re-show the theme preview here, both are already saved from onboarding.
struct ReturningHomeView: View {
    @Binding var currentPage: Page

    // Toggled on by the gear icon below to present SettingsView as a sheet.
    @State private var isShowingSettings = false

    var body: some View {
        // The WHOLE screen is one big Button, same "tap anywhere" idea
        // HomeView's own welcome step uses — a real Button (rather than a
        // bare tap gesture) so VoiceOver, Switch Control, and keyboard
        // navigation all understand it as a control automatically.
        Button(action: {
            currentPage = .account
        }, label: {
            VStack(spacing: Spacing.large) {
                Spacer()

                AppMascot(size: 110, flickerIntensity: 0.9, flickerSpeed: 0.95)

                // Deliberately NOT personalized with the reader's saved
                // name here — this screen is reached before any actual
                // log in/join happens (it's just "back at the app's home
                // screen"), so a "Hi, <name>!" greeting belongs after a
                // reader actually signs in or joins a library, not here.
                PageHeader(eyebrow: "Welcome back", title: "Welcome to Fast Lit")

                Spacer()

                Text("Tap anywhere to start reading")
                    .font(.buttonLabel)
                    .foregroundStyle(Color.accentPrimary)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        })
        .buttonStyle(.plain)
        .padding(Spacing.large)
        // A small gear in the corner, overlaid ON TOP of the full-screen
        // button above — SwiftUI hit-tests the topmost view at whatever
        // point was actually tapped, so tapping this gear opens Settings
        // instead of triggering the big background button underneath it.
        .overlay(alignment: .topTrailing) {
            Button(action: {
                isShowingSettings = true
            }, label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.textSecondary)
                    .padding(Spacing.large)
            })
            .accessibilityLabel("Settings")
        }
        .sheet(isPresented: $isShowingSettings) {
            // NavigationStack lets .navigationTitle/.toolbar inside
            // SettingsView work.
            NavigationStack {
                SettingsView()
            }
        }
    }
}

// Reachable from ReturningHomeView's gear icon — holds the two things
// that don't belong cluttering up the simple day-to-day Home screen:
// changing Light/Dark/Automatic, and starting over from scratch.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    // See ReturningHomeView's own copy of this property for why it's
    // read here too — this is what lets a reader change their mind about
    // Light/Dark/Automatic any time, not just during onboarding.
    @AppStorage("appColorScheme") private var appColorSchemeRaw: String = AppColorScheme.system.rawValue

    // Clearing these two is the entire "reset" — HomeView reads
    // hasCompletedOnboarding to decide whether to show ReturningHomeView
    // or the full welcome sequence, so setting it back to false is what
    // actually sends a reader back to the very beginning once this sheet
    // is dismissed.
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("readerName") private var readerName: String = ""

    // Toggled on by "Reset & Start Over" below — confirming first means
    // an accidental tap can't silently clear a reader's saved name.
    @State private var isShowingResetConfirmation = false

    var body: some View {
        VStack(spacing: Spacing.extraLarge) {
            appearancePicker

            Button(action: {
                isShowingResetConfirmation = true
            }, label: {
                Text("Reset & Start Over")
            })
            .buttonStyle(SecondaryButtonStyle())

            Spacer()
        }
        .padding(Spacing.large)
        // Sheets are a separate view hierarchy from ContentView's own
        // ZStack (see its own comment for why that one uses a ZStack
        // rather than a plain ".background()") — that background doesn't
        // reach in here, so this sheet needs its own, the same way
        // LibraryCatalogManagementView and ReadableContentDetailView do.
        .background(Color.surfaceBackground.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: {
                    dismiss()
                }, label: {
                    Text("Done")
                })
                .buttonStyle(TextButtonStyle())
            }
        }
        .confirmationDialog(
            "Start over from the beginning?",
            isPresented: $isShowingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) {
                hasCompletedOnboarding = false
                readerName = ""
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears your saved name and takes you back to the welcome screens.")
        }
    }

    // Lets a reader change Light, Dark, or Automatic (follow the system
    // setting) any time, regardless of what the rest of their device is
    // set to — see AppColorScheme in Theme.swift and
    // ios_accessibleApp.swift's ".preferredColorScheme(_:)", which is
    // what actually applies this.
    private var appearancePicker: some View {
        VStack(spacing: Spacing.small) {
            Text("Appearance")
                .font(.comfortableBody)
                .foregroundStyle(Color.textSecondary)

            // "selection: $appColorSchemeRaw" binds directly to the raw
            // String, and each option below "tags" itself with the
            // matching case's own rawValue — Picker doesn't need to know
            // anything about AppColorScheme itself this way, just that
            // whichever tag matches the current selection gets highlighted.
            // Each option shows only its icon (see AppColorScheme.iconName)
            // rather than a text label — ".accessibilityLabel" still gives
            // VoiceOver the word ("Automatic"/"Light"/"Dark") to announce,
            // so nothing is lost for a screen reader even though sighted
            // readers only ever see a sun/moon/half-circle.
            Picker("Appearance", selection: $appColorSchemeRaw) {
                ForEach(AppColorScheme.allCases) { scheme in
                    Image(systemName: scheme.iconName)
                        .accessibilityLabel(scheme.label)
                        .tag(scheme.rawValue)
                }
            }
            .pickerStyle(.segmented)
            // Bigger icons and a taller control — matches this app's
            // larger-than-default sizing everywhere else.
            .controlSize(.large)
        }
        .padding(.top, Spacing.large)
    }
}

// Lets the user choose which kind of account to log into or sign up for,
// then shows that account type's form.
struct AccountView: View {
    @Binding var currentPage: Page

    // Reported back up to ContentView so ChooseView (a sibling of this
    // whole account flow, not a descendant of it) knows whose
    // libraryCatalogSelections to filter the catalog against, once a
    // reader joins one.
    @Binding var joinedLibraryUid: String?

    // Set by HomeView's own final onboarding step (see accountChoiceStep
    // there) before currentPage ever switches to .account — a @Binding,
    // not @State, specifically so that hand-off works: if it already
    // holds a value by the time this view appears, the picker below is
    // skipped entirely and the matching form shows right away. Cleared
    // back to nil by LibraryAccountView/ReaderAccountView's own "Go
    // Back", which is what brings the picker back for a reader who
    // changes their mind.
    @Binding var accountType: AccountType?

    var body: some View {
        if accountType == .library {
            LibraryAccountView(accountType: $accountType, currentPage: $currentPage)
        } else if accountType == .reader {
            ReaderAccountView(accountType: $accountType, currentPage: $currentPage, joinedLibraryUid: $joinedLibraryUid)
        } else {
            // The same "Who's Joining Us?" screen HomeView's onboarding
            // shows as its own final step (see AccountChoiceScreen below)
            // — reached here on every visit that DIDN'T just come through
            // onboarding, so no progress bar, and "Go Back" returns to
            // Home instead of an onboarding step.
            AccountChoiceScreen(onContinue: { chosen in
                accountType = chosen
            }, onBack: {
                currentPage = .home
            })
        }
    }
}

// The "Who's Joining Us?" choice, shared between two different places it
// can appear: as the final step of HomeView's first-time onboarding
// sequence (showProgress: true, "Go Back" returns to the theme step) and
// as AccountView's own picker for every later visit (showProgress:
// false, "Go Back" returns to Home instead). Built entirely from
// OnboardingTheme.swift's own components — same reasoning as HomeView's
// steps: this screen is part of the onboarding redesign even when a
// returning reader reaches it outside onboarding proper, so it keeps
// that flow's look rather than switching back to the rest of the app's.
// Tapping a card only highlights it; actually committing the choice
// needs a separate tap on "Continue", so a reader can change their mind
// before being swept into a form.
private struct AccountChoiceScreen: View {
    var showProgress: Bool = false

    // Called once "Continue" is tapped, with whichever type ended up
    // selected — never called while selection is nil, since Continue is
    // disabled until then (see ".disabled(selection == nil)" below).
    let onContinue: (AccountType) -> Void
    let onBack: () -> Void

    // Always starts nil, even when AccountView shows this again after a
    // reader taps "Go Back" from inside LibraryAccountView/
    // ReaderAccountView — that should ask the question fresh, not
    // silently remember their last pick.
    @State private var selection: AccountType? = nil

    var body: some View {
        VStack(spacing: Spacing.medium) {
            if showProgress {
                OnboardingProgressBar(step: 3, total: 3)
                    .padding(.bottom, Spacing.small)
            }

            // The smallest, calmest size this mascot is ever drawn at —
            // and, per the design, the only step with no glow or
            // sparkles at all, since by this point a reader's attention
            // should be entirely on the choice itself.
            OnboardingMascot(size: 56, sparkleCount: 0, showsGlow: false)

            OnboardingPageHeader(
                title: "Who's Joining Us?",
                titleSize: 25,
                subtitle: "Pick whichever one sounds like you.",
                subtitleSize: 15
            )

            OnboardingSelectableCard(
                leading: OnboardingIconTile(systemImage: "books.vertical.fill"),
                title: "I'm a Library",
                description: "Set up reading material for your members.",
                isSelected: selection == .library
            ) {
                selection = .library
            }

            OnboardingSelectableCard(
                leading: OnboardingIconTile(systemImage: "person.fill"),
                title: "I'm a Reader",
                description: "Join with a code from your library.",
                isSelected: selection == .reader
            ) {
                selection = .reader
            }

            Spacer()

            Button(action: {
                if let selection {
                    onContinue(selection)
                }
            }, label: {
                Text("Continue")
            })
            .buttonStyle(OnboardingPrimaryButtonStyle())
            .disabled(selection == nil)
            .padding(.top, Spacing.small)

            OnboardingBackButton(action: onBack)
        }
        .padding(Spacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.onboardingBackground.ignoresSafeArea())
    }
}

// Lets the user choose whether to log into an existing library account or
// sign up for a new one, then shows that specific form. Library accounts
// use a username and password either way.
struct LibraryAccountView: View {
    // @Binding (not "let") so "Go Back" below can clear it, returning to
    // AccountView's picker the same way it got here.
    @Binding var accountType: AccountType?

    // Passed straight through to the login/sign-up forms below, so either
    // one can jump to .library once authentication actually succeeds.
    @Binding var currentPage: Page

    // nil until the user picks log in or sign up below; once set, that
    // form replaces this picker.
    @State private var authMode: AuthMode? = nil

    var body: some View {
        if authMode == .login {
            LibraryLoginView(authMode: $authMode, currentPage: $currentPage)
        } else if authMode == .signUp {
            LibrarySignUpView(authMode: $authMode, currentPage: $currentPage)
        } else {
            VStack(spacing: Spacing.medium) {
                PageHeader(
                    title: "Welcome, Librarian!",
                    subtitle: "Log in to your account, or set up a new one."
                )

                ChoiceCard(
                    icon: "key.fill",
                    title: "Log In",
                    description: "Welcome back — sign in to your library."
                ) {
                    authMode = .login
                }

                ChoiceCard(
                    icon: "sparkles",
                    title: "Sign Up",
                    description: "Set up a brand new library account."
                ) {
                    authMode = .signUp
                }

                BackButton(action: {
                    accountType = nil
                })
            }
            .padding(Spacing.large)
        }
    }
}

// Normalizes a library username as it's typed: no capitals (lowercased,
// rather than rejected) and no spaces (turned into hyphens, rather than
// rejected). Shared by LibraryLoginView and LibrarySignUpView so the same
// typed input always produces the same username in both places — a
// username signed up as "Test User" becomes "test-user", and logging in
// with "Test User" (or "TEST USER", or "test-user") all need to normalize
// to that same thing to find the account.
private func sanitizedUsername(_ input: String) -> String {
    input.lowercased().replacingOccurrences(of: " ", with: "-")
}

// Logging into an existing library account, for real now via AuthService.
struct LibraryLoginView: View {
    // @Binding so "Go Back" can clear it, returning to LibraryAccountView's
    // log in/sign up picker.
    @Binding var authMode: AuthMode?

    // Set to .library on a successful sign-in.
    @Binding var currentPage: Page

    @Environment(AuthService.self) private var authService

    @State private var username: String = ""
    @State private var password: String = ""

    // nil until a sign-in attempt fails; cleared again on the next attempt.
    @State private var errorMessage: String? = nil

    // Disables "Log In" for the duration of a sign-in attempt, so a slow
    // network can't be worked around by mashing the button into firing
    // several sign-ins at once.
    @State private var isSubmitting: Bool = false

    var body: some View {
        VStack(spacing: Spacing.medium) {
            PageHeader(title: "Library Log In")

            TextField("Username", text: $username)
                .textFieldStyle(.roundedBorder)
                .font(.comfortableBody)
                .padding(.horizontal)
                // Stops the keyboard from auto-capitalizing the first
                // letter, since capitals get stripped right back out anyway.
                .textInputAutocapitalization(.never)
                .onChange(of: username) { _, newValue in
                    username = sanitizedUsername(newValue)
                }

            // SecureField (not TextField) hides what's typed, the way
            // password fields normally work.
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .font(.comfortableBody)
                .padding(.horizontal)

            if let errorMessage {
                ErrorLabel(message: errorMessage)
            }

            Button(action: {
                logIn()
            }, label: {
                Text("Log In")
            })
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top)
            // Neither field can be left blank — an empty username or
            // password would just fail the sign-in anyway, so there's no
            // reason to let the button fire (and show a network error)
            // before both are actually filled in.
            .disabled(isSubmitting || username.isEmpty || password.isEmpty)

            BackButton(action: {
                authMode = nil
            })
        }
        .padding(Spacing.large)
    }

    // Library accounts are identified by username, but Firebase's
    // email/password provider needs something shaped like an email — this
    // appends a fixed, made-up domain so a username becomes one, without
    // "email" ever appearing anywhere in this screen. LibrarySignUpView
    // builds the same shape, so a username signed up there can log back in
    // here.
    private func libraryEmail(for username: String) -> String {
        "\(username)@fastlit-library.app"
    }

    private func logIn() {
        errorMessage = nil
        isSubmitting = true
        Task {
            do {
                try await authService.signIn(email: libraryEmail(for: username), password: password)
                currentPage = .library
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}

// Which step of LibrarySignUpView's own wizard is showing — a dedicated
// enum (rather than the old plain Int) since each step is now its own
// full screen with its own title/copy/field, not just a swapped-out
// field within one shared layout.
private enum LibrarySignUpStep {
    case libraryName
    case username
    case password
    case confirmPassword
    case success
}

// Signing up for a new library account, rebuilt as four separate
// full-screen steps — one field per screen — matching HomeView's own
// "What should we call you?" onboarding step exactly (mascot, centered
// Baloo 2 title, single underlined field, Continue/Go Back), plus a
// final confirmation screen once the account is actually created. Each
// step's own step-N-of-4 progress bar is separate from the main
// onboarding flow's — this sub-flow restarts its own count at step 1,
// since reaching here already means onboarding proper is finished.
struct LibrarySignUpView: View {
    @Binding var authMode: AuthMode?

    // Set to .library once the reader taps "Continue" on this flow's own
    // success step — not the instant the account is actually created —
    // so there's always a clear confirmation moment first, the same
    // pattern ReaderAccountView's own "You're All Set!" screen uses.
    @Binding var currentPage: Page

    @Environment(AuthService.self) private var authService

    @State private var step: LibrarySignUpStep = .libraryName

    // "Library" is just a fun way to describe an organization account, so
    // this step asks for the organization's name, not a person's name —
    // unlike the reader flow, which asks "What should we call you?".
    @State private var libraryName: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""

    // nil until something goes wrong on the CURRENT step (a taken
    // username, too-short password, mismatched confirmation, or a failed
    // sign-up); cleared again whenever its own field changes.
    @State private var errorMessage: String? = nil

    // Disables "Continue"/"Create Library" for the duration of a network
    // call (the username-taken check, or the actual sign-up), so a slow
    // network can't be worked around by mashing the button into firing
    // several at once.
    @State private var isSubmitting: Bool = false

    var body: some View {
        Group {
            switch step {
            case .libraryName:
                libraryNameStep
            case .username:
                usernameStep
            case .password:
                passwordStep
            case .confirmPassword:
                confirmPasswordStep
            case .success:
                successStep
            }
        }
        // Same "each step is its own identity" trick HomeView's own
        // onboarding steps use — without it, SwiftUI treats every step as
        // one view quietly changing content, rather than something to
        // actually transition between.
        .id(step)
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
        .animation(.easeInOut(duration: 0.45), value: step)
    }

    // Step 1 of 4: the organization's name.
    private var libraryNameStep: some View {
        VStack(spacing: Spacing.medium) {
            OnboardingProgressBar(step: 1, total: 4)
                .padding(.bottom, Spacing.small)

            Spacer()

            OnboardingMascot(size: 110, sparkleCount: 1)

            OnboardingPageHeader(
                title: "What's your library called?",
                titleSize: 34,
                subtitle: "This is the name members will see.",
                subtitleSize: 16
            )

            VStack(spacing: Spacing.small) {
                TextField(
                    "",
                    text: $libraryName,
                    prompt: Text("Library name")
                        .foregroundStyle(Color.onboardingTextSecondary.opacity(0.7))
                )
                .textFieldStyle(.plain)
                .font(OnboardingFont.display(26))
                .foregroundStyle(Color.onboardingText)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.words)
                .tint(Color.onboardingText)

                Rectangle()
                    .fill(Color.onboardingBorder)
                    .frame(height: 2)
            }
            .padding(.horizontal, Spacing.extraLarge)

            Spacer()

            Button(action: {
                step = .username
            }, label: {
                Text("Continue")
            })
            .buttonStyle(OnboardingPrimaryButtonStyle())
            .disabled(libraryName.trimmingCharacters(in: .whitespaces).isEmpty)

            OnboardingBackButton(action: {
                authMode = nil
            })
        }
        .padding(Spacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.onboardingBackground.ignoresSafeArea())
    }

    // Step 2 of 4: a unique username — the same async "already taken"
    // check the old combined form ran, just triggered from its own full
    // screen now.
    private var usernameStep: some View {
        VStack(spacing: Spacing.medium) {
            OnboardingProgressBar(step: 2, total: 4)
                .padding(.bottom, Spacing.small)

            Spacer()

            OnboardingMascot(size: 110, sparkleCount: 1)

            OnboardingPageHeader(
                title: "Pick a username",
                titleSize: 34,
                subtitle: "You'll use this to log in.",
                subtitleSize: 16
            )

            VStack(spacing: Spacing.small) {
                TextField(
                    "",
                    text: $username,
                    prompt: Text("Username")
                        .foregroundStyle(Color.onboardingTextSecondary.opacity(0.7))
                )
                .textFieldStyle(.plain)
                .font(OnboardingFont.display(26))
                .foregroundStyle(Color.onboardingText)
                .multilineTextAlignment(.center)
                // Stops the keyboard from auto-capitalizing the first
                // letter, since capitals get stripped right back out
                // anyway.
                .textInputAutocapitalization(.never)
                .tint(Color.onboardingText)
                .onChange(of: username) { _, newValue in
                    username = sanitizedUsername(newValue)
                    // Clears a stale "already taken" error left over from
                    // a previous username typed on this step.
                    errorMessage = nil
                }

                Rectangle()
                    .fill(Color.onboardingBorder)
                    .frame(height: 2)
            }
            .padding(.horizontal, Spacing.extraLarge)

            if let errorMessage {
                OnboardingErrorLabel(message: errorMessage)
            }

            Spacer()

            Button(action: {
                advancePastUsernameStep()
            }, label: {
                Text("Continue")
            })
            .buttonStyle(OnboardingPrimaryButtonStyle())
            .disabled(isSubmitting || username.trimmingCharacters(in: .whitespaces).isEmpty)

            OnboardingBackButton(action: {
                step = .libraryName
            })
        }
        .padding(Spacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.onboardingBackground.ignoresSafeArea())
    }

    // Step 3 of 4: a password, at least 8 characters — validated with an
    // inline error on Continue rather than just leaving it disabled,
    // since (unlike an empty field) "too short" isn't obvious just from
    // looking at the field.
    private var passwordStep: some View {
        VStack(spacing: Spacing.medium) {
            OnboardingProgressBar(step: 3, total: 4)
                .padding(.bottom, Spacing.small)

            Spacer()

            OnboardingMascot(size: 110, sparkleCount: 1)

            OnboardingPageHeader(
                title: "Create a password",
                titleSize: 34,
                subtitle: "Use at least 8 characters.",
                subtitleSize: 16
            )

            VStack(spacing: Spacing.small) {
                SecureField(
                    "",
                    text: $password,
                    prompt: Text("Password")
                        .foregroundStyle(Color.onboardingTextSecondary.opacity(0.7))
                )
                .textFieldStyle(.plain)
                .font(OnboardingFont.display(26))
                .foregroundStyle(Color.onboardingText)
                .multilineTextAlignment(.center)
                .tint(Color.onboardingText)
                .onChange(of: password) { _, _ in
                    errorMessage = nil
                }

                Rectangle()
                    .fill(Color.onboardingBorder)
                    .frame(height: 2)
            }
            .padding(.horizontal, Spacing.extraLarge)

            if let errorMessage {
                OnboardingErrorLabel(message: errorMessage)
            }

            Spacer()

            Button(action: {
                continueFromPasswordStep()
            }, label: {
                Text("Continue")
            })
            .buttonStyle(OnboardingPrimaryButtonStyle())
            .disabled(password.isEmpty)

            OnboardingBackButton(action: {
                step = .username
            })
        }
        .padding(Spacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.onboardingBackground.ignoresSafeArea())
    }

    // Step 4 of 4: confirming the password — matching it is what
    // actually creates the account (see submitSignUp below), so this
    // step's own button reads "Create Library" rather than "Continue".
    private var confirmPasswordStep: some View {
        VStack(spacing: Spacing.medium) {
            OnboardingProgressBar(step: 4, total: 4)
                .padding(.bottom, Spacing.small)

            Spacer()

            OnboardingMascot(size: 110, sparkleCount: 1)

            OnboardingPageHeader(
                title: "Confirm your password",
                titleSize: 34,
                subtitle: "Just making sure it's right.",
                subtitleSize: 16
            )

            VStack(spacing: Spacing.small) {
                SecureField(
                    "",
                    text: $confirmPassword,
                    prompt: Text("Confirm password")
                        .foregroundStyle(Color.onboardingTextSecondary.opacity(0.7))
                )
                .textFieldStyle(.plain)
                .font(OnboardingFont.display(26))
                .foregroundStyle(Color.onboardingText)
                .multilineTextAlignment(.center)
                .tint(Color.onboardingText)
                .onChange(of: confirmPassword) { _, _ in
                    errorMessage = nil
                }

                Rectangle()
                    .fill(Color.onboardingBorder)
                    .frame(height: 2)
            }
            .padding(.horizontal, Spacing.extraLarge)

            if let errorMessage {
                OnboardingErrorLabel(message: errorMessage)
            }

            Spacer()

            Button(action: {
                submitSignUp()
            }, label: {
                Text("Create Library")
            })
            .buttonStyle(OnboardingPrimaryButtonStyle())
            .disabled(isSubmitting || confirmPassword.isEmpty)

            OnboardingBackButton(action: {
                step = .password
            })
        }
        .padding(Spacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.onboardingBackground.ignoresSafeArea())
    }

    // The terminal step, once the account is actually created — the same
    // "You're All Set!" pattern ReaderAccountView shows after a
    // successful join, adapted here for a library owner instead of a
    // joining reader. No progress bar, matching Welcome's own lack of one
    // — there's nothing left to show progress through.
    private var successStep: some View {
        VStack(spacing: Spacing.large) {
            Spacer()

            OnboardingMascot(size: 130, sparkleCount: 2)

            OnboardingPageHeader(
                title: "You're All Set!",
                titleSize: 44,
                subtitle: "Your library is ready. Time to start building your collection.",
                subtitleSize: 18
            )

            Spacer()

            Button(action: {
                currentPage = .library
            }, label: {
                Text("Continue")
            })
            .buttonStyle(OnboardingPrimaryButtonStyle())
        }
        .padding(Spacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.onboardingBackground.ignoresSafeArea())
    }

    // Same fixed-domain trick LibraryLoginView uses, so a username signed
    // up here can log back in there.
    private func libraryEmail(for username: String) -> String {
        "\(username)@fastlit-library.app"
    }

    // Only advances from the username step to the password step once a
    // check against Firestore's libraryUsernames registry confirms the
    // username isn't already taken — the whole point being that no one
    // should even reach the password step for a username that can't be
    // signed up with. (See AuthService.isUsernameTaken for why this goes
    // through Firestore rather than asking Firebase Auth directly.)
    private func advancePastUsernameStep() {
        errorMessage = nil
        isSubmitting = true
        Task {
            do {
                let taken = try await authService.isUsernameTaken(username)
                if taken {
                    errorMessage = "That username is already taken."
                } else {
                    step = .password
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }

    private func continueFromPasswordStep() {
        guard password.count >= 8 else {
            errorMessage = "Use at least 8 characters."
            return
        }
        errorMessage = nil
        step = .confirmPassword
    }

    private func submitSignUp() {
        guard confirmPassword == password else {
            errorMessage = "Passwords don't match."
            return
        }

        errorMessage = nil
        isSubmitting = true
        Task {
            do {
                try await authService.signUp(
                    email: libraryEmail(for: username),
                    password: password,
                    displayName: libraryName
                )
                // Best-effort: the Auth account above is what actually
                // makes this account real, and is already created by this
                // point — a network blip here shouldn't undo that or block
                // this person from continuing, it would just mean the
                // registry is briefly out of date for the next person's
                // "is this taken" check.
                try? await authService.registerUsername(username)
                // Also best-effort, for the same reason — LibraryView
                // handles a missing join code (e.g. from this failing)
                // gracefully rather than this blocking sign-up.
                try? await authService.createLibraryProfile(
                    username: username,
                    libraryName: libraryName,
                    joinCode: AuthService.generateJoinCode()
                )
                step = .success
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}

// Shown once a library account is signed in — a placeholder for now.
// Library accounts don't get access to ChooseView/ReadView at all; those
// pages are reader-only, so nothing here leads to them.
struct LibraryView: View {
    @Binding var currentPage: Page

    @Environment(AuthService.self) private var authService

    // nil until the join code finishes loading (or fails to). Distinct
    // from an empty string so the view can tell "still loading" apart from
    // "loaded, but there's nothing there".
    @State private var joinCode: String? = nil
    @State private var loadError: String? = nil

    // Toggled on by "Manage Catalog" below to present
    // LibraryCatalogManagementView as a sheet.
    @State private var isManagingCatalog: Bool = false

    var body: some View {
        VStack(spacing: Spacing.medium) {
            PageHeader(
                eyebrow: "Your Library",
                title: "Welcome Back",
                subtitle: "Share your join code below so your readers can join your library."
            )

            // Readers use this to find and sign up for this specific
            // library — see ReaderAccountView's "Library/Org Code" field.
            if let joinCode {
                VStack(spacing: Spacing.small) {
                    Text("Your Join Code")
                        .font(.sectionTitle)
                        .foregroundStyle(Color.textPrimary)
                    Text(joinCode)
                        .font(.joinCode)
                        .foregroundStyle(Color.accentPrimary)
                }
                .padding(Spacing.large)
                .frame(maxWidth: .infinity)
                .cardStyle()
                .padding(.bottom)
            } else if let loadError {
                ErrorLabel(message: loadError)
                    .padding(.bottom)
            } else {
                ProgressView()
                    .padding(.bottom)
            }

            Button(action: {
                isManagingCatalog = true
            }, label: {
                Text("Manage Catalog")
            })
            .buttonStyle(PrimaryButtonStyle())

            Button(action: {
                // try? rather than try: sign-out failing here isn't
                // something the placeholder page needs to react to, and
                // there's nowhere more useful to send the user than home
                // regardless of the outcome.
                try? authService.signOut()
                currentPage = .home
            }, label: {
                Text("Sign Out")
            })
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(Spacing.large)
        // .task (rather than .onAppear) ties this to the view's lifecycle —
        // it's automatically cancelled if the view disappears before the
        // fetch finishes, so a slow network can't set state on a view
        // that's no longer showing.
        .task {
            do {
                if let profile = try await authService.fetchLibraryProfile() {
                    joinCode = profile.joinCode
                } else {
                    loadError = "No join code found for this account."
                }
            } catch {
                loadError = error.localizedDescription
            }
        }
        .sheet(isPresented: $isManagingCatalog) {
            // NavigationStack lets .navigationTitle/.toolbar inside the
            // management view work.
            NavigationStack {
                LibraryCatalogManagementView()
            }
        }
    }
}

// Lets a signed-in library account choose which catalog items its readers
// are allowed to read — presented as a sheet from LibraryView's "Manage
// Catalog" button. Every toggle flip saves immediately (see save() below)
// rather than needing a separate "Save" button, since there's nothing else
// on this screen a half-saved toggle could conflict with.
struct LibraryCatalogManagementView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    @State private var catalog: [ReadableContent] = []
    @State private var enabledContentIds: Set<String> = []

    @State private var isLoading: Bool = true
    @State private var loadError: String? = nil
    @State private var saveError: String? = nil

    var body: some View {
        // See ContentView's ZStack for why the background is a sibling
        // here rather than a ".background()" modifier on Group: the
        // isLoading/loadError branches below (a bare ProgressView/
        // ErrorLabel, no List) hug their own small content size rather
        // than filling the sheet, so ".background()" on Group would only
        // paint a content-sized rectangle in those two states, not the
        // whole sheet.
        ZStack {
            Color.surfaceBackground
                .ignoresSafeArea()

            Group {
                if isLoading {
                    ProgressView()
                } else if let loadError {
                    ErrorLabel(message: loadError)
                } else {
                    List {
                        ForEach(catalog) { item in
                            Toggle(item.title, isOn: Binding(
                                get: { enabledContentIds.contains(item.id) },
                                set: { isEnabled in
                                    if isEnabled {
                                        enabledContentIds.insert(item.id)
                                    } else {
                                        enabledContentIds.remove(item.id)
                                    }
                                    save()
                                }
                            ))
                            .font(.comfortableBody)
                            .foregroundStyle(Color.textPrimary)
                            // ".large" makes the switch itself bigger and
                            // easier to hit precisely, and adds vertical
                            // padding around each row — both matter more for
                            // this app's audience than the default compact size.
                            .controlSize(.large)
                            .padding(.vertical, Spacing.small)
                            .listRowBackground(Color.surfaceCard)
                        }
                    }
                    .scrollContentBackground(.hidden)

                    if let saveError {
                        ErrorLabel(message: saveError)
                    }
                }
            }
        }
        .navigationTitle("Manage Catalog")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: {
                    dismiss()
                }, label: {
                    Text("Done")
                })
                .buttonStyle(TextButtonStyle())
            }
        }
        .task {
            await load()
        }
    }

    private func load() async {
        guard let uid = authService.currentUserUid else {
            loadError = "Not signed in."
            isLoading = false
            return
        }
        do {
            async let catalogFetch = authService.fetchCatalog()
            async let enabledFetch = authService.fetchEnabledContentIds(forLibraryUid: uid)
            catalog = try await catalogFetch
            enabledContentIds = try await enabledFetch
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }

    private func save() {
        saveError = nil
        Task {
            do {
                try await authService.setEnabledContentIds(enabledContentIds)
            } catch {
                saveError = error.localizedDescription
            }
        }
    }
}

// Lets a reader join an organization/library with just its join code — no
// account, no name, no log in/sign up split. Once a code resolves to a real
// library (via AuthService.fetchLibraryName), shows that library's name on
// its own page instead of the join form.
struct ReaderAccountView: View {
    @Binding var accountType: AccountType?

    // Set to .choose once the reader taps "Start Reading" on the
    // joined-org page below.
    @Binding var currentPage: Page

    // Reported back up to ContentView so ChooseView knows whose
    // libraryCatalogSelections to filter the catalog against.
    @Binding var joinedLibraryUid: String?

    @Environment(AuthService.self) private var authService

    @State private var code: String = ""

    // nil until a code is looked up successfully; once set, this view shows
    // the joined-org page instead of the join form.
    @State private var joinedLibraryName: String? = nil

    // nil until a lookup fails (bad code or a network error); cleared again
    // on the next attempt.
    @State private var errorMessage: String? = nil

    // Disables "Join" for the duration of a lookup, so a slow network can't
    // be worked around by mashing the button into firing several at once.
    @State private var isSubmitting: Bool = false

    var body: some View {
        if let joinedLibraryName {
            VStack(spacing: Spacing.medium) {
                Spacer()

                AppMascot()
                    .padding(.bottom, Spacing.medium)

                PageHeader(title: "You're All Set!")

                Text(joinedLibraryName)
                    .font(.sectionTitle)
                    .foregroundStyle(Color.accentPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, Spacing.large)

                Spacer()

                Button(action: {
                    currentPage = .choose
                }, label: {
                    Text("Start Reading")
                })
                .buttonStyle(PrimaryButtonStyle())

                BackButton(action: {
                    accountType = nil
                })
            }
            .padding(Spacing.large)
        } else {
            VStack(spacing: Spacing.medium) {
                PageHeader(
                    title: "Join Your Library",
                    subtitle: "Enter the code your library gave you."
                )

                // Styled as 6 individual boxes with the hyphen shown
                // automatically (see CodeEntryField in Theme.swift) rather
                // than one plain text box — the reader only ever types or
                // pastes the 6 real characters; "code" here never contains
                // the hyphen itself.
                CodeEntryField(code: $code)
                    .padding(Spacing.large)
                    .cardStyle()
                    .onChange(of: code) { _, _ in
                        errorMessage = nil
                    }

                if let errorMessage {
                    ErrorLabel(message: errorMessage)
                }

                Button(action: {
                    join()
                }, label: {
                    Text("Join")
                })
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top)
                // Matches a real code's length, so "Join" only becomes
                // tappable once all 6 characters are actually in — mashing
                // it early would just fail the lookup anyway.
                .disabled(isSubmitting || code.count < 6)

                BackButton(action: {
                    accountType = nil
                })
            }
            .padding(Spacing.large)
        }
    }

    private func join() {
        errorMessage = nil
        isSubmitting = true
        // "code" holds only the 6 raw characters (see CodeEntryField) —
        // the hyphen is reconstructed here, right before the lookup,
        // since that's the shape AuthService.generateJoinCode actually
        // produces and what's stored as each libraryJoinCodes document's
        // ID.
        let formattedCode = "\(code.prefix(3))-\(code.suffix(3))"
        Task {
            do {
                if let library = try await authService.fetchJoinedLibrary(forJoinCode: formattedCode) {
                    joinedLibraryUid = library.uid
                    joinedLibraryName = library.name
                } else {
                    errorMessage = "That code doesn't match any organization."
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}

// The screen listing content to pick from — just whichever catalog items
// the reader's joined library has enabled, not the whole shared catalog.
struct ChooseView: View {
    @Binding var currentPage: Page

    // The content the user accepted, reported back up to ContentView so it can
    // hand it to ReadView once we get there.
    @Binding var contentToRead: ReadableContent?

    // Whose enabled selections to filter the catalog against — set once,
    // from ReaderAccountView's successful join, and passed straight through
    // ContentView/AccountView to get here.
    let libraryUid: String

    @Environment(AuthService.self) private var authService

    // Holds whichever row was tapped, so the .sheet below knows what to show.
    @State private var selectedContent: ReadableContent? = nil

    // Empty until loadContent() finishes — see isLoading/loadError below for
    // telling "still loading" and "nothing enabled yet" apart from an
    // in-progress fetch.
    @State private var availableContent: [ReadableContent] = []
    @State private var isLoading: Bool = true
    @State private var loadError: String? = nil

    var body: some View {
        VStack(spacing: Spacing.medium) {
            PageHeader(eyebrow: "Reading Catalog", title: "Choose Something to Read")

            if isLoading {
                ProgressView()
                Spacer()
            } else if let loadError {
                ErrorLabel(message: loadError)
                Spacer()
            } else if availableContent.isEmpty {
                Text("Your library hasn't added any reading material yet. Please check back soon.")
                    .font(.comfortableBody)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            } else {
                List {
                    // "item" avoids clashing with the Text view type.
                    ForEach(availableContent) { item in
                        Button(action: {
                            selectedContent = item // triggers the .sheet below
                        }, label: {
                            HStack {
                                Text(item.title)
                                    .font(.comfortableBody)
                                    .foregroundStyle(Color.textPrimary)
                                Spacer()
                                // A visible ">" hints the row is tappable,
                                // beyond just the row itself looking like
                                // a button — a small extra clarity cue.
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(Color.textSecondary)
                            }
                            // Generous vertical padding makes each row a
                            // bigger, easier target to tap.
                            .padding(.vertical, Spacing.medium)
                        })
                        .listRowBackground(Color.surfaceCard)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.surfaceBackground)
            }

            BackButton(action: {
                currentPage = .home
            })
        }
        .padding(Spacing.large)
        // .sheet(item:) shows a modal whenever the bound value is non-nil,
        // passing the unwrapped value in. "$" turns @State into a two-way
        // Binding. Attached to the whole VStack (rather than nested inside
        // the List branch above) so it stays in place no matter which of
        // the loading/error/empty/list branches above is currently showing.
        .sheet(item: $selectedContent) { item in
            // NavigationStack lets .navigationTitle/.toolbar inside the detail
            // view work.
            NavigationStack {
                // onAccept is a closure we pass in; the detail view calls it
                // without knowing what it does here on our side.
                ReadableContentDetailView(content: item, onAccept: {
                    contentToRead = item // remember what to read...
                    currentPage = .read // ...then go straight to reading —
                    // ReadView itself locks the screen into landscape on
                    // appear (see its .onAppear), so there's no need for
                    // an intermediate "please rotate your device" screen
                    // asking the reader to do it by hand.
                })
            }
        }
        // .task (rather than .onAppear) ties this to the view's lifecycle —
        // it's automatically cancelled if the view disappears before the
        // fetch finishes, so a slow network can't set state on a view
        // that's no longer showing.
        .task {
            await loadContent()
        }
    }

    private func loadContent() async {
        do {
            async let catalogFetch = authService.fetchCatalog()
            async let enabledFetch = authService.fetchEnabledContentIds(forLibraryUid: libraryUid)
            let catalog = try await catalogFetch
            let enabledIds = try await enabledFetch
            availableContent = catalog.filter { enabledIds.contains($0.id) }
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }
}

// The actual reading screen — placeholder for now.
struct ReadView: View {
    // "let" (not "@Binding") since this view only reads the content, never
    // changes it — a plain stored property is all that's needed here.
    let content: ReadableContent

    // @Binding (not "let"), unlike content above — this one does need to
    // change, so the "choose something different" button below can send the
    // user back to ChooseView.
    @Binding var currentPage: Page

    // @State lets this value change and trigger a redraw. It can't be a plain
    // "let" (can't reassign it) or even a plain "var" (SwiftUI throws this
    // whole struct away and rebuilds it on every redraw, so a plain "var"
    // would reset to 0 each time) — @State is what actually survives across
    // those redraws.
    @State private var indexNum: Int = 0

    // Words per minute: how many words playback advances through per 60
    // seconds. Used below to work out how long to wait between words.
    @State private var wpm: Int = 300

    // Whether playback is currently advancing through words on its own.
    @State private var isPlaying: Bool = false

    // Holds the currently-running Timer (if any), so play()/pause() can
    // start and stop it. Timer is a class, so this property is just a
    // reference to it, not the timer's own state.
    @State private var timer: Timer? = nil

    // @ScaledMetric ties a value to Dynamic Type the same way a built-in
    // text style would, but for a plain number rather than a Font — the
    // base value below (64) is what this renders at under the system's
    // default text size, and it scales up or down from there as someone
    // adjusts their text size setting. "relativeTo: .largeTitle" caps how
    // aggressively it grows, since this word display already sits at the
    // large end of the scale and the three-segment layout below (before/
    // focal-letter/after) needs to stay roughly stable rather than
    // ballooning without limit at the most extreme accessibility sizes.
    @ScaledMetric(relativeTo: .largeTitle) private var focalWordSize: CGFloat = 64

    // A computed property, not a stored one: a stored property's initial
    // value runs before "self" exists, so it can't reference "content" (another
    // stored property) the way the old code tried to. Computing it fresh each
    // time also means there's nothing to manually keep in sync.
    // "whereSeparator: { $0.isWhitespace }" splits on any run of spaces,
    // tabs, or newlines, not just a single literal " ".
    var words: [String] {
        content.text.split(whereSeparator: { $0.isWhitespace }).map(String.init)
    }

    // Splits the current word into the letters before its middle letter (the
    // "focal letter" RSVP readers center each word on), the middle letter
    // itself, and the letters after it. Kept as three separate pieces (rather
    // than one combined string) so body can lay each one out in its own
    // flexible-width container — that's what keeps the middle letter fixed
    // at screen-center regardless of how many letters sit on either side of it.
    var wordParts: (before: String, center: String, after: String) {
        let word = words[indexNum]
        let centerIndex = word.index(word.startIndex, offsetBy: word.count / 2)
        let afterCenterIndex = word.index(after: centerIndex)

        return (
            before: String(word[word.startIndex..<centerIndex]),
            center: String(word[centerIndex..<afterCenterIndex]),
            after: String(word[afterCenterIndex...])
        )
    }

    // Moves the reading position forward (or back, with a negative increment).
    // No "mutating" keyword needed: @State's setter works even from a
    // non-mutating method, since the actual storage lives outside this struct.
    // Clamped to 0...words.count - 1 so a tap at either end can't push
    // indexNum out of range, which would crash the words[indexNum] lookup below.
    func updateIndex(increment: Int) -> Void {
        indexNum = min(max(indexNum + increment, 0), words.count - 1)
    }

    // (Re)creates the repeating Timer at the current wpm's interval. Pulled
    // out of play() so a wpm change made mid-playback can rebuild the timer
    // at the new speed too — a Timer's own interval can't be edited in place
    // once it's scheduled, so the only way to change speed is to replace it.
    func startTimer() -> Void {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60.0 / Double(wpm), repeats: true) { _ in
            // Stop instead of advancing once the last word is reached, so
            // playback doesn't keep firing forever with nothing left to show.
            if indexNum >= words.count - 1 {
                pause()
            } else {
                updateIndex(increment: 1)
            }
        }
    }

    // Starts advancing through words on its own, one word every 60/wpm
    // seconds (e.g. 300 wpm = 60/300 = a fifth of a second per word).
    func play() -> Void {
        isPlaying = true
        startTimer()
    }

    // Stops automatic advancing. Also called once the last word is reached.
    func pause() -> Void {
        isPlaying = false
        timer?.invalidate()
        timer = nil
    }

    // Stops playback like pause(), but also rewinds to the first word,
    // unlike pause() which just freezes wherever playback was.
    func stop() -> Void {
        pause()
        indexNum = 0
    }

    // Nudges wpm up or down by a fixed step, clamped to the Slider's own
    // 60...600 range so the +/- buttons below can never push it out of
    // bounds the way an unclamped tap could. A separate, explicit control
    // from the Slider itself — dragging a thin slider precisely can be
    // hard, so these buttons give an easier, exact way to make the same
    // adjustment one step at a time.
    func adjustWPM(by delta: Int) -> Void {
        wpm = min(max(wpm + delta, 60), 600)
        if isPlaying {
            startTimer()
        }
    }

    var body: some View {
        VStack(spacing: Spacing.large) {
            // "indexNum + 1" (not indexNum) so the bar reads as "words shown
            // so far out of the total" — it starts at a sliver of progress
            // on the very first word, rather than at empty.
            ProgressView(value: Double(indexNum + 1), total: Double(words.count))
                .tint(Color.accentPrimary)
                .padding(.horizontal)

            Spacer()

            // Rather than one Text centered as a block (which would put the
            // focal-color letter in a different screen position for every
            // word, depending on how many letters come before/after it),
            // "before" and "after" each get a flexible container of equal
            // width via .frame(maxWidth: .infinity) and pull their text
            // toward the middle with alignment. Since both containers
            // always claim the same share of the remaining space, "center"
            // (a fixed size, so it's never squeezed) ends up fixed at
            // screen-center every time.
            HStack(spacing: 0) {
                // Muted gray, medium weight (not the heavy black/white of
                // the focal letter below) — in this app's monochrome
                // palette there's no separate hue to lean on the way a
                // colored accent used to provide, so the before/after
                // letters are pushed back with BOTH a lighter color and a
                // lighter weight, leaving the focal letter to stand out
                // through contrast on two axes at once, not just one.
                Text(wordParts.before)
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text(wordParts.center)
                    .foregroundStyle(Color.rsvpFocalLetter)
                    // Overrides just the weight from the heavier .medium
                    // base set below, up to the heaviest weight available
                    // — the focal letter reads as unmistakably "the point
                    // of emphasis" even though it's the same hue family
                    // as everything else on screen.
                    .fontWeight(.black)
                    .fixedSize()
                Text(wordParts.after)
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            // Large, since this word is the whole point of the screen —
            // everything else (progress bar, controls) is secondary to
            // it. Applied to the HStack (rather than each Text) since
            // font is an environment value that flows down to all three,
            // with each Text's own .fontWeight() above adjusting weight
            // on top of this shared base. Uses focalWordSize (see
            // @ScaledMetric above) rather than a plain fixed 60, so this
            // still grows for someone using a larger system text size,
            // within a sensible clamp.
            .font(.system(size: focalWordSize, weight: .medium))

            Spacer()

            // Side-by-side buttons to step through words one at a time, play/
            // pause, and stop — each labeled with both an icon and a short
            // word underneath, rather than an icon alone, since an icon-only
            // button can be ambiguous (is "⏸" pause, or something else?) for
            // readers less familiar with media-player icon conventions.
            HStack(spacing: Spacing.medium) {
                Button(action: {
                    updateIndex(increment: -1)
                }, label: {
                    VStack(spacing: Spacing.small / 2) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 26))
                        Text("Back")
                            .font(.buttonCaption)
                    }
                })
                .buttonStyle(PrimaryButtonStyle())
                // Manually stepping while the timer is also advancing indexNum
                // would fight with playback, so stepping is disabled while playing.
                .disabled(isPlaying)
                .accessibilityLabel("Previous word")

                // Same button throughout — only its icon, label, and action
                // change depending on isPlaying, rather than showing two
                // buttons and hiding whichever one doesn't apply.
                Button(action: {
                    if isPlaying {
                        pause()
                    } else {
                        play()
                    }
                }, label: {
                    VStack(spacing: Spacing.small / 2) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 26))
                        Text(isPlaying ? "Pause" : "Play")
                            .font(.buttonCaption)
                    }
                })
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityLabel(isPlaying ? "Pause" : "Play")

                Button(action: {
                    updateIndex(increment: 1)
                }, label: {
                    VStack(spacing: Spacing.small / 2) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 26))
                        Text("Forward")
                            .font(.buttonCaption)
                    }
                })
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isPlaying)
                .accessibilityLabel("Next word")

                // Unlike the step buttons, stays enabled while playing — it
                // needs to be able to interrupt playback, not just adjust
                // position within it.
                Button(action: {
                    stop()
                }, label: {
                    VStack(spacing: Spacing.small / 2) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 26))
                        Text("Stop")
                            .font(.buttonCaption)
                    }
                })
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityLabel("Stop and rewind to the beginning")
            }

            // "-"/"+" buttons give an exact, easy way to change speed one
            // step at a time — an alternative to dragging the thin Slider
            // below, which takes more precision than tapping a big button.
            HStack(spacing: Spacing.medium) {
                Button(action: {
                    adjustWPM(by: -20)
                }, label: {
                    Image(systemName: "minus")
                })
                .buttonStyle(SecondaryButtonStyle())
                .frame(width: Spacing.compactButtonWidth)
                .accessibilityLabel("Decrease speed")

                Text("\(wpm) words per minute")
                    .font(.sectionTitle)
                    .foregroundStyle(Color.textPrimary)
                    .frame(minWidth: 220)

                Button(action: {
                    adjustWPM(by: 20)
                }, label: {
                    Image(systemName: "plus")
                })
                .buttonStyle(SecondaryButtonStyle())
                .frame(width: Spacing.compactButtonWidth)
                .accessibilityLabel("Increase speed")
            }

            // Slider only works with a floating-point Binding, so this wraps
            // wpm (an Int) in a Binding<Double> that converts on the way in
            // and out — nothing is stored twice, wpm is still the only source
            // of truth.
            Slider(
                value: Binding(
                    get: { Double(wpm) },
                    set: { wpm = Int($0) }
                ),
                in: 60...600,
                step: 20
            )
            .tint(Color.accentPrimary)
            .padding(.horizontal)
            // Only rebuilds the timer if playback is already running —
            // otherwise there's no timer to update, and play() will start
            // one at the current wpm anyway once tapped.
            .onChange(of: wpm) { _, _ in
                if isPlaying {
                    startTimer()
                }
            }

            // Sends the user back to ChooseView to pick something else;
            // .onDisappear below stops playback the same way it would for
            // any other reason this view goes away.
            Button(action: {
                currentPage = .choose
            }, label: {
                Text("Choose Something Different")
            })
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(Spacing.large)
        // Locks the screen into landscape the instant this view appears
        // — see lockOrientation(to:) in ios_accessibleApp.swift — rather
        // than asking the reader to rotate their device by hand (which
        // is what the OrientView screen this replaced used to do).
        .onAppear {
            lockOrientation(to: .landscape)
        }
        // Stops any running timer if this view goes away while playing, so
        // it doesn't keep firing pointlessly in the background, and locks
        // the screen back to portrait — every other screen in this app
        // expects portrait, so this needs to happen on the way OUT of
        // ReadView, not just rely on whatever screen comes next to ask
        // for it themselves.
        .onDisappear {
            pause()
            lockOrientation(to: .portrait)
        }
    }
}

// Shown inside the modal sheet for whichever content was tapped.
struct ReadableContentDetailView: View {
    let content: ReadableContent // fixed for this view's lifetime

    // "() -> Void" is a closure type: a function taking no arguments, returning
    // nothing. The caller (ChooseView) decides what this actually does.
    let onAccept: () -> Void

    // @Environment reads a value the system provides; \.dismiss closes this sheet.
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView { // lets long passages scroll
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text(content.description)
                    .font(.comfortableBody)
                    .foregroundStyle(Color.textSecondary)
                Text(content.text)
                    .font(.comfortableBody)
                    .foregroundStyle(Color.textPrimary)
                    // A little extra breathing room between lines makes a
                    // full passage of body text noticeably easier to track
                    // line-to-line than the system default spacing.
                    .lineSpacing(6)
            }
            .padding(Spacing.large)
        }
        // ScrollView already fills all the space it's offered (that's
        // needed for scrolling to make sense at all), so unlike the fixes
        // above, a plain ".background()" here already covers the whole
        // sheet — ".ignoresSafeArea()" just extends it fully to the edges.
        .background(Color.surfaceBackground.ignoresSafeArea())
        .navigationTitle(content.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // .cancellationAction is the standard "close this screen" spot (left side).
            ToolbarItem(placement: .cancellationAction) {
                Button(action: {
                    dismiss()
                }, label: {
                    Text("Done")
                })
                .buttonStyle(TextButtonStyle())
            }
            // .confirmationAction is the standard "confirm/accept" spot (right side).
            ToolbarItem(placement: .confirmationAction) {
                Button(action: {
                    onAccept() // tell ChooseView to move to the orient screen
                    dismiss() // then close this sheet
                }, label: {
                    Text("Accept")
                })
                .buttonStyle(TextButtonStyle(emphasized: true))
            }
        }
    }
}

// Identifiable requires an "id" so List/ForEach/.sheet(item:) can tell rows
// apart. id is the Firestore document ID from the "catalog" collection
// (see AuthService.fetchCatalog) rather than a locally-generated UUID —
// this content lives in Firestore now, imported once via
// scripts/import-catalog.js, not shipped as static data in the app.
struct ReadableContent: Identifiable {
    let id: String
    let title: String
    let description: String
    let text: String
}

// Unlike the real app, #Preview below instantiates ContentView() directly
// rather than going through ios_accessibleApp's WindowGroup — so neither
// FirebaseApp.configure() nor .environment(authService) has happened yet
// by the time it runs, and any view reading @Environment(AuthService.self)
// (e.g. LibraryLoginView) would otherwise crash. Pulled out into its own
// plain function (rather than inline in the #Preview closure) since a
// ViewBuilder closure mixing a bare "if" with view-building expressions
// hits a Swift compiler bug ("failed to produce diagnostic for
// expression") — a plain function has no such restriction. The
// FirebaseApp.app() == nil guard is for Xcode's preview host process
// reusing state across a live preview's recompiles, which would otherwise
// risk configuring twice (which crashes on its own).
private func previewAuthService() -> AuthService {
    if FirebaseApp.app() == nil {
        FirebaseApp.configure()
    }
    return AuthService()
}

// #Preview drives Xcode's live canvas preview.
#Preview {
    ContentView()
        .environment(previewAuthService())
}
