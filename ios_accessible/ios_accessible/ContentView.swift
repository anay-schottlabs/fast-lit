import SwiftUI // brings in Apple's UI framework
import FirebaseCore

// App Group container this app shares with ShareExtension — must match
// ShareViewController.swift's copy of these two constants exactly.
// extensionContext.open(_:)'s completion handler was confirmed (via direct
// instrumentation) to report success: false in under a millisecond, before
// ever reaching the system — a local failure with no diagnosable cause, not
// something this app can fix by reacting to it differently. So the Share
// Extension writes the shared URL here regardless of what open() does, and
// ContentView checks for it below on launch and on returning to the
// foreground — the article is never lost even when the instant hand-off
// via .onOpenURL doesn't happen.
private let appGroupID = "group.com.anaydandekar.ios-accessible"
private let pendingSharedURLKey = "pendingSharedArticleURL"

// MARK: - Navigation

/// Which top-level screen ContentView is currently showing.
// enum = a fixed set of named cases; used here as a simple "which page" switch.
// No ".library" case — a library account's own home screen
// (LibraryHomeView) is reached directly from within LibrarySignUpView/
// LibraryLoginView's own local state once auth succeeds, not via a
// separate top-level page the way ChooseView is for readers.
enum Page {
    case home
    case choose
    case read
    case account
}

/// Which kind of account someone is signing into or creating.
// Chosen on AccountView before its username/password or six-digit-code
// form shows.
enum AccountType {
    case library
    case reader
}

/// Whether an account screen is showing its log-in form or its sign-up form.
// Chosen on each account type's screen before its actual form shows. Kept
// separate from AccountType since sign up asks for a name that log in
// doesn't need, so the two need different fields, not just different titles.
enum AuthMode {
    case login
    case signUp
}

// MARK: - Root View

/// The app's single root view — decides which top-level Page to show and
/// owns the state (current page, signed-in account type, content to read)
/// that needs to survive as the reader moves between pages. Each page's
/// own UI lives in its own struct further down this file.
// "struct" = value type. ": View" means it must provide a "body"
// describing its UI.
struct ContentView: View {
    // Needed here (not just deeper views like ChooseView) for the shared-
    // article dedup/save flow below — ensureReaderSignedIn/
    // findSavedContent/saveContent all need to run right where a shared
    // URL first arrives, before ReadView ever shows.
    @Environment(AuthService.self) private var authService

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
    // @AppStorage (not plain @State) so a reader who joined a library once
    // doesn't have to type their join code in again on every app launch —
    // ReaderAccountView already treats a non-nil value here as "already
    // joined" and skips straight to its own home content; persisting it is
    // the only piece that was missing for that to also survive a relaunch.
    @AppStorage("joinedLibraryUid") private var joinedLibraryUid: String?

    // Which kind of account the reader picked — either on HomeView's own
    // final onboarding step (see AccountChoiceScreen in this file), or on
    // AccountView's own copy of that same screen for every later visit.
    // Lives here, one level above both, so a choice made during onboarding
    // survives the hand-off from HomeView to AccountView: once picked,
    // AccountView skips straight to that account type's form instead of
    // asking the same question a second time.
    @State private var accountType: AccountType? = nil

    // Set by .onOpenURL below when the Share Extension hands back a
    // fastlit://share?url=... callback — the article URL a reader shared
    // from Safari (or any other app). .task(id:) below picks this up and
    // runs extraction; kept as its own @State (not going straight into
    // contentToRead) since there's real async work between "URL arrived"
    // and "have a ReadableContent to show."
    @State private var pendingSharedURL: URL? = nil

    // True only while ArticleExtractionService is fetching + parsing a
    // shared URL — drives the spinner overlay below, so "automatically
    // open in reader mode" still shows SOMETHING during the one
    // unavoidable async step (the page has to actually load).
    @State private var isExtractingSharedArticle: Bool = false

    // Set if extraction throws — see ArticleExtractionError's own cases
    // for why a shared link can fail in several genuinely different ways
    // (dead link, paywall, timeout) that deserve their own message rather
    // than a single generic "something went wrong."
    @State private var sharedArticleExtractionError: String? = nil

    // Drives the App Group pending-share check below — checked on launch
    // (initial .active) and every time the reader switches back into the
    // app (e.g. after Fast Lit's Share Extension saved a URL but couldn't
    // hand off live via .onOpenURL).
    @Environment(\.scenePhase) private var scenePhase

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
                } else if currentPage == .read {
                    // "if let" only unwraps and shows ReadView once contentToRead is
                    // actually set, which it always is by the time we reach this page.
                    if let contentToRead {
                        // .id(contentToRead.id) — load-bearing, not
                        // decorative. ReadView's own words array is a
                        // "let" computed once in its init, but indexNum/
                        // isPlaying/timer are all @State, keyed by VIEW
                        // IDENTITY, not by content. Every path into .read
                        // before shared articles existed left .read and
                        // came back (ChooseView's onAccept), which reset
                        // that identity as a side effect. Sharing a
                        // SECOND article while already mid-read is the
                        // first path where contentToRead can change while
                        // currentPage stays .read the whole time — without
                        // this .id(), SwiftUI would reuse the OLD ReadView
                        // instance, words would shrink to the new
                        // article's length, but indexNum would still be
                        // wherever the reader left off in the old one,
                        // which can index past the end of the new words
                        // array and crash.
                        ReadView(content: contentToRead, currentPage: $currentPage)
                            .id(contentToRead.id)
                    }
                }
            }

            // Full-screen spinner while a shared article is being fetched
            // + parsed — the one unavoidable delay between "tapped Fast
            // Lit in the share sheet" and actually landing in ReadView,
            // since the page has to load somewhere before Readability.js
            // can pull real article text out of it.
            if isExtractingSharedArticle {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.white)
                        Text("Opening article…")
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        // fastlit://share?url=<percent-encoded article URL> — the only
        // callback ShareExtension/ShareViewController.swift ever sends.
        // Attached here (not in ios_accessibleApp.swift's WindowGroup)
        // since ContentView is that WindowGroup's sole content anyway, and
        // keeping it here means ios_accessibleApp.swift needs zero edits —
        // sidesteps having to reason about its own Firebase-init-ordering
        // comment (see that file) for a code path that has no Firebase
        // dependency in the first place.
        .onOpenURL { url in
            guard
                url.scheme == "fastlit", url.host == "share",
                let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                let encodedURL = components.queryItems?.first(where: { $0.name == "url" })?.value,
                let articleURL = URL(string: encodedURL)
            else { return }
            pendingSharedURL = articleURL
        }
        // Catches the case .onOpenURL doesn't: the Share Extension's
        // extensionContext.open() failing (see the App Group comment
        // above), where the article is saved but this app never gets a
        // live fastlit:// callback telling it so. .active fires both on
        // cold launch and every return from background, so this is
        // checked every time the reader could plausibly be arriving to
        // read something they just shared.
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            checkForPendingSharedURL()
        }
        // .task(id:) (not .onChange) so this automatically re-runs — with
        // its own fresh isExtractingSharedArticle/error state — if a
        // reader shares a SECOND link while still on this same
        // ContentView instance (which is always, since it's the app's one
        // root view); .onChange would need that restart logic spelled out
        // by hand.
        .task(id: pendingSharedURL) {
            guard let pendingSharedURL else { return }
            isExtractingSharedArticle = true
            sharedArticleExtractionError = nil
            defer { isExtractingSharedArticle = false }

            let sourceURLString = pendingSharedURL.absoluteString
            // Sign-in and dedup lookup are both best-effort (try?, not
            // try) — a reader should still be able to read what they
            // just shared even if this device is offline or Firestore
            // is unreachable; persistence/dedup are conveniences on top
            // of the actual read, not a requirement for it.
            try? await authService.ensureReaderSignedIn()
            if let existing = try? await authService.findSavedContent(bySourceURL: sourceURLString) {
                // Sharing the same article a second time reopens the
                // saved copy from before instead of re-extracting and
                // creating a duplicate "Saved" entry.
                contentToRead = existing
                currentPage = .read
            } else {
                do {
                    let content = try await ArticleExtractionService.extract(from: pendingSharedURL)
                    // Also best-effort: extraction having already
                    // succeeded is what matters for THIS read; a failed
                    // save just means it won't be there to dedupe
                    // against or revisit later.
                    try? await authService.saveContent(content, sourceURL: sourceURLString)
                    contentToRead = content
                    currentPage = .read
                } catch {
                    sharedArticleExtractionError = error.localizedDescription
                }
            }
            self.pendingSharedURL = nil
        }
        .alert(
            "Couldn't Open Article",
            isPresented: Binding(
                get: { sharedArticleExtractionError != nil },
                set: { if !$0 { sharedArticleExtractionError = nil } }
            )
        ) {
            Button("OK") { sharedArticleExtractionError = nil }
        } message: {
            Text(sharedArticleExtractionError ?? "")
        }
    }

    // Consumes (reads + immediately clears) whatever ShareViewController
    // last wrote to the App Group — "immediately clears" matters so a
    // stale URL from days ago can't resurface and reopen itself the next
    // time the reader happens to background/foreground the app for an
    // unrelated reason.
    private func checkForPendingSharedURL() {
        let defaults = UserDefaults(suiteName: appGroupID)
        guard
            let storedURLString = defaults?.string(forKey: pendingSharedURLKey),
            let articleURL = URL(string: storedURLString)
        else { return }
        defaults?.removeObject(forKey: pendingSharedURLKey)
        pendingSharedURL = articleURL
    }
}

// MARK: - Onboarding & Home

/// Which step of the very-first-launch welcome sequence is showing (see
/// HomeView below).
// Not used again once hasCompletedOnboarding is true, when HomeView
// instead hands off straight to AccountView's picker.
enum OnboardingStep {
    case welcome
    case name
    case greeting
    case theme
    case accountChoice
}

/// The first screen shown when the app launches — walks a first-time
/// reader through onboarding, or (on every later visit) hands off
/// straight to AccountView's picker.
// The very first time
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
// out) skips straight past all of this to AccountView's picker instead,
// since there's no reason to re-ask a name or show the theme preview a
// second time.
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
                // Nothing left to show here on a later visit — Name and
                // Theme are already answered, so send them straight on to
                // AccountView's picker instead of re-running any of this
                // onboarding sequence. Color.clear rather than EmptyView()
                // so the frame stays a real, hit-testable view for the
                // instant before onAppear fires.
                Color.clear
                    .onAppear { currentPage = .account }
            } else {
                Group {
                    switch onboardingStep {
                    case .welcome:
                        welcomeStep
                    case .name:
                        nameStep
                    case .greeting:
                        greetingStep
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
        // hand-off away from this whole sequence once hasCompletedOnboarding
        // flips to true, so nothing about it ever cuts abruptly from one
        // screen to the next.
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
            OnboardingProgressBar(step: 1, total: 5)
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
                withAnimation { onboardingStep = .greeting }
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

    // Step 3: a one-screen "Hi, {name}" greeting inserted between Name
    // and Theme — the design's own reference has this sharing Name's
    // step number rather than advancing the bar, but that reads as the
    // bar stalling in place rather than the flow actually moving
    // forward, so this gets its own step here instead.
    private var greetingStep: some View {
        VStack(spacing: Spacing.medium) {
            OnboardingProgressBar(step: 2, total: 5)
                .padding(.bottom, Spacing.small)

            Spacer()

            OnboardingMascot(size: 110, sparkleCount: 1)

            OnboardingPageHeader(
                title: "Hi, \(readerName)",
                titleSize: 40
            )

            Spacer()

            Button(action: {
                withAnimation { onboardingStep = .theme }
            }, label: {
                Text("Continue")
            })
            .buttonStyle(OnboardingPrimaryButtonStyle())

            OnboardingBackButton(action: {
                withAnimation { onboardingStep = .name }
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
            OnboardingProgressBar(step: 3, total: 5)
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

            // The design's own prototype has this button reusing the
            // Greeting step's own "go back to Name" handler — almost
            // certainly a leftover from before Greeting existed between
            // Name and Theme, not deliberate; it contradicts the flow's
            // own stated rule that Go Back always moves exactly one step.
            // Goes to Greeting here instead, matching that rule.
            OnboardingBackButton(action: {
                withAnimation { onboardingStep = .greeting }
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

// MARK: - Settings

/// A signed-in reader or library account's own settings screen.
// Reachable via a gear icon on each account type's own landing page
// (ReaderAccountView's readerHomeContent, once joined, or LibraryHomeView,
// once signed in), never from ChooseView (a reader's catalog) or
// AccountView's own picker, since there's nothing to configure before an
// account actually exists. A real full screen, not a sheet — same
// reasoning, and same Binding-owned-by-the-presenting-view pattern, as
// LibraryCatalogManagementView's own move away from a sheet. Styled with
// OnboardingTheme.swift's components rather than Theme.swift's, matching
// the direction the rest of the app is headed.
struct SettingsView: View {
    // Set back to false by "Go Back" below — owned by whichever screen
    // presents this one, not this view itself.
    @Binding var isShowingSettings: Bool

    // Sent to .home by "Reset App" below, the same way LibraryHomeView/
    // ReaderAccountView's own Sign Out sends it to .account — reset goes
    // one step further, back to the very start of onboarding rather than
    // just the account picker.
    @Binding var currentPage: Page

    // Cleared to nil by "Reset App" below, same reasoning as Sign Out's
    // own copy of this in LibraryHomeView/ReaderAccountView: without
    // this, AccountView (reached again once onboarding finishes a second
    // time) would see it already set and skip its own picker.
    @Binding var accountType: AccountType?

    // Only ReaderAccountView has this concept — LibraryHomeView passes
    // nothing here, since a library account was never "joined" to
    // anything. nil-safe throughout "Reset App" below.
    var joinedLibraryUid: Binding<String?>? = nil

    @Environment(AuthService.self) private var authService

    // The same key HomeView's own onboarding theme step writes to, so a
    // change here takes effect (and persists) exactly the same way.
    @AppStorage("appColorScheme") private var appColorSchemeRaw: String = AppColorScheme.system.rawValue

    // The same key HomeView's onboarding name step writes to — shared
    // between the reader and library flows, since both ask for a name
    // before account type is even chosen (see HomeView's nameStep).
    @AppStorage("readerName") private var readerName: String = ""

    // The same key buttonPressHaptic(_:) (Theme.swift) reads before firing
    // any button's tap haptic — this Toggle is the only place that key
    // ever gets written, so every button in the app respects it live the
    // instant it's flipped, the same way appColorSchemeRaw's own live
    // effect works.
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true

    // The same key HomeView's body reads to decide whether to skip
    // straight to AccountView's picker — "Reset App" below is what flips
    // this back to false.
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    // Guards the destructive reset below behind a confirmation, so a
    // stray tap can't silently sign someone out and drop them back into
    // onboarding.
    @State private var isShowingResetConfirmation: Bool = false

    // Treats the untouched default ("system," from before this app
    // offered a real choice) as "Light" for DISPLAY purposes only — same
    // reasoning as HomeView's own displayedScheme. Nothing here ever
    // writes .system back; only Light/Dark are offered below.
    private var currentScheme: AppColorScheme {
        let stored = AppColorScheme(rawValue: appColorSchemeRaw) ?? .system
        return stored == .system ? .light : stored
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.extraLarge) {
                OnboardingPageHeader(title: "Settings", titleSize: 34)
                    .padding(.top, Spacing.large)

                nameSection
                appearanceSection
                hapticsSection
                resetSection
            }
            .padding(.horizontal, Spacing.large)
            .padding(.bottom, Spacing.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.onboardingBackground.ignoresSafeArea())
        // Top-left corner, like a modal sheet's own close button, rather
        // than inline at the bottom of the scrolling content — an
        // overlay (not part of the VStack above) so it stays fixed in
        // place as the settings list scrolls under it, instead of
        // scrolling away with everything else.
        .overlay(alignment: .topLeading) { closeButton }
        .alert("Reset App?", isPresented: $isShowingResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                resetApp()
            }
        } message: {
            Text("This signs you out and takes you back to the very start. Your name and settings will need to be entered again.")
        }
    }

    // try? — same reasoning as Sign Out's own copy of this call
    // elsewhere: failing to sign out of Firebase isn't something worth
    // blocking the reset over, since every field this actually needs to
    // clear (accountType, joinedLibraryUid, hasCompletedOnboarding,
    // readerName) is local either way.
    private func resetApp() {
        try? authService.signOut()
        accountType = nil
        joinedLibraryUid?.wrappedValue = nil
        readerName = ""
        hasCompletedOnboarding = false
        isShowingSettings = false
        currentPage = .home
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("Your Name")
                .font(OnboardingFont.body(16, weight: .semiBold))
                .foregroundStyle(Color.onboardingTextSecondary)

            TextField(
                "",
                text: $readerName,
                prompt: Text("Your name")
                    .foregroundStyle(Color.onboardingTextSecondary.opacity(0.7))
            )
            .textFieldStyle(.plain)
            .font(OnboardingFont.display(24))
            .foregroundStyle(Color.onboardingText)
            .textInputAutocapitalization(.words)
            .tint(Color.onboardingText)
            .padding(Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.onboardingCard)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Light or Dark only — no "Automatic" — mirroring HomeView's own
    // onboarding theme step, which offers the exact same two cards, same
    // reasoning: a reader who wants this app specifically in one mode
    // shouldn't have it silently flip because the rest of their device's
    // appearance changed.
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("Appearance")
                .font(OnboardingFont.body(16, weight: .semiBold))
                .foregroundStyle(Color.onboardingTextSecondary)

            OnboardingSelectableCard(
                leading: OnboardingThemeSwatch(palette: .light),
                title: "Light",
                isSelected: currentScheme == .light
            ) {
                appColorSchemeRaw = AppColorScheme.light.rawValue
            }

            OnboardingSelectableCard(
                leading: OnboardingThemeSwatch(palette: .dark),
                title: "Dark",
                isSelected: currentScheme == .dark
            ) {
                appColorSchemeRaw = AppColorScheme.dark.rawValue
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // A single on/off switch for the tap haptic every button in the app
    // fires (see buttonPressHaptic(_:) in Theme.swift) — some readers find
    // continuous tap feedback distracting or uncomfortable, the same
    // reasoning OnboardingMascot's own breathing animation respects
    // Reduce Motion for.
    private var hapticsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("Haptics")
                .font(OnboardingFont.body(16, weight: .semiBold))
                .foregroundStyle(Color.onboardingTextSecondary)

            Toggle("Tap Feedback", isOn: $hapticsEnabled)
                .font(OnboardingFont.body(18, weight: .semiBold))
                .foregroundStyle(Color.onboardingText)
                .padding(Spacing.medium)
                .background(Color.onboardingCard)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                // A hand-drawn switch (see OnboardingToggleStyle in
                // OnboardingTheme.swift), not the system ".switch" style —
                // recent iOS versions render that with a translucent glass
                // material that doesn't fit this flow's flat, opaque look.
                .toggleStyle(OnboardingToggleStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Signs out and clears every piece of onboarding/account state this
    // app tracks, sending the reader all the way back to HomeView's first
    // welcome screen — for someone who wants a genuinely fresh start
    // (new name, re-pick light/dark, join a different library) rather
    // than the ordinary Sign Out already available from their own
    // account's home screen, which only returns to the account picker.
    private var resetSection: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("Reset")
                .font(OnboardingFont.body(16, weight: .semiBold))
                .foregroundStyle(Color.onboardingTextSecondary)

            Button(action: {
                isShowingResetConfirmation = true
            }, label: {
                Text("Reset App")
                    .frame(maxWidth: .infinity)
            })
            .buttonStyle(OnboardingSecondaryButtonStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // The same round X CloseXShape button ReadView's own corner close
    // button uses (see headerRow there) rather than OnboardingBackButton's
    // plain "Go Back" text — a dedicated close icon reads more clearly as
    // "done with Settings" than a back chevron does, since this screen is
    // reached from a gear icon, not a forward step in a flow. Colored
    // with this view's own onboardingText/onboardingCard tokens (not
    // ReadColor, which CloseXShape was originally styled for) to match
    // every other control on this screen.
    private var closeButton: some View {
        Button(action: {
            isShowingSettings = false
        }, label: {
            CloseXShape()
                .stroke(Color.onboardingText, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .frame(width: 18, height: 18)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.onboardingCard))
                .contentShape(Circle())
        })
        .buttonStyle(HapticButtonStyle())
        .accessibilityLabel("Close Settings")
        .padding(.leading, Spacing.large)
        .padding(.top, Spacing.large)
    }
}

// MARK: - Account Type Selection

/// Lets the user choose which kind of account to log into or sign up for,
/// then shows that account type's form.
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

    @Environment(AuthService.self) private var authService

    var body: some View {
        // The "|| authService.isSignedIn" / "|| joinedLibraryUid != nil"
        // parts are what make a returning library account or a reader who
        // already joined skip this whole picker on relaunch: accountType
        // itself is never persisted (it always starts nil), but Firebase's
        // own session persistence and joinedLibraryUid's @AppStorage
        // (both in ContentView) already are — reading them here routes
        // straight to the matching branch below without asking "library
        // or reader" again. Each branch's own view (LibraryAccountView's
        // isSignedIn check, ReaderAccountView's joinedLibraryUid check)
        // is what then skips ITS OWN sign-in/join-code form too.
        if accountType == .library || authService.isSignedIn {
            LibraryAccountView(accountType: $accountType, currentPage: $currentPage)
        } else if accountType == .reader || joinedLibraryUid != nil {
            ReaderAccountView(accountType: $accountType, currentPage: $currentPage, joinedLibraryUid: $joinedLibraryUid)
        } else {
            // The same "Who's Joining Us?" screen HomeView's onboarding
            // shows as its own final step (see AccountChoiceScreen below)
            // — reached here on every later visit too, so no progress bar
            // and no "Go Back" (there's nothing before this to go back
            // to for a returning reader — HomeView sends them straight
            // here). No Settings access here either — this is a
            // sign-in/sign-up screen, not an account's own home, so
            // there's nothing yet to configure; see LibraryHomeView and
            // ReaderAccountView's own gear icons for where Settings
            // actually lives once signed in.
            AccountChoiceScreen(onContinue: { chosen in
                accountType = chosen
            })
        }
    }
}

/// The "Who's Joining Us?" choice screen, shared between HomeView's
/// onboarding sequence and AccountView's own picker on later visits.
// Shared between two different places it can appear: as the final step of
// HomeView's first-time onboarding sequence (showProgress: true, "Go
// Back" returns to the theme step) and as AccountView's own picker for
// every later visit (showProgress:
// false, no "Go Back" at all — see onBack's own doc comment for why).
// Built entirely from OnboardingTheme.swift's own components — same
// reasoning as HomeView's steps: this screen is part of the onboarding
// redesign even when a returning reader reaches it outside onboarding
// proper, so it keeps
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

    // Optional — nil means there's nowhere meaningful to go back to (a
    // returning reader lands directly on this screen now, with no
    // previous screen in this session — see AccountView's own use of
    // this below), so "Go Back" just isn't shown at all rather than
    // bouncing right back to this same screen.
    var onBack: (() -> Void)? = nil

    // Always starts nil, even when AccountView shows this again after a
    // reader taps "Go Back" from inside LibraryAccountView/
    // ReaderAccountView — that should ask the question fresh, not
    // silently remember their last pick.
    @State private var selection: AccountType? = nil

    var body: some View {
        VStack(spacing: Spacing.medium) {
            if showProgress {
                OnboardingProgressBar(step: 4, total: 5)
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

            if let onBack {
                OnboardingBackButton(action: onBack)
            }
        }
        .padding(Spacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.onboardingBackground.ignoresSafeArea())
    }
}

// MARK: - Library Account

/// Lets the user choose whether to log into an existing library account
/// or sign up for a new one, then shows that specific form.
// Library accounts use a username and password either way. This picker
// itself — "Set up your library" — is part of the onboarding redesign
// (it's step 5 of 5 in the overall onboarding flow's own progress count,
// same as Library Log In and Reader Join Code, all of which share that
// final step), built entirely from OnboardingTheme.swift's components
// rather than Theme.swift's, matching HomeView's own onboarding steps.
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

    @Environment(AuthService.self) private var authService

    var body: some View {
        // A returning library account whose Firebase session is still
        // valid (persisted on-device by Firebase Auth itself — see
        // AuthService's own init) skips straight to their home screen,
        // the same "you're already signed in, don't ask again" treatment
        // LibraryHomeView's own greeting: .loggedIn otherwise only gets
        // right after a fresh LibraryLoginView submit.
        if authService.isSignedIn {
            LibraryHomeView(greeting: .loggedIn, currentPage: $currentPage, accountType: $accountType)
        } else if authMode == .login {
            LibraryLoginView(authMode: $authMode, currentPage: $currentPage, accountType: $accountType)
        } else if authMode == .signUp {
            LibrarySignUpView(authMode: $authMode, currentPage: $currentPage, accountType: $accountType)
        } else {
            VStack(spacing: Spacing.medium) {
                OnboardingProgressBar(step: 5, total: 5)
                    .padding(.bottom, Spacing.small)

                // No glow/sparkle at this size — same treatment
                // AccountChoiceScreen's own mascot uses, since by this
                // point a reader's attention should be on the choice
                // itself, not on Ember.
                OnboardingMascot(size: 96, sparkleCount: 0, showsGlow: false)

                OnboardingPageHeader(
                    title: "Set up your library",
                    titleSize: 30,
                    subtitle: "Sign up to create a new library, or log in if you already have one.",
                    subtitleSize: 16
                )

                Spacer()

                Button(action: {
                    authMode = .signUp
                }, label: {
                    Text("Sign Up")
                })
                .buttonStyle(OnboardingPrimaryButtonStyle())

                Button(action: {
                    authMode = .login
                }, label: {
                    Text("Log In")
                })
                .buttonStyle(OnboardingSecondaryButtonStyle())

                Spacer()

                OnboardingBackButton(action: {
                    accountType = nil
                })
            }
            .padding(Spacing.large)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.onboardingBackground.ignoresSafeArea())
        }
    }
}

/// Normalizes a library username as it's typed: no capitals (lowercased,
/// rather than rejected) and no spaces (turned into hyphens, rather than
/// rejected).
// Shared by LibraryLoginView and LibrarySignUpView so the same
// typed input always produces the same username in both places — a
// username signed up as "Test User" becomes "test-user", and logging in
// with "Test User" (or "TEST USER", or "test-user") all need to normalize
// to that same thing to find the account.
private func sanitizedUsername(_ input: String) -> String {
    input.lowercased().replacingOccurrences(of: " ", with: "-")
}

/// Logging into an existing library account, for real via AuthService.
// Rebuilt to match the onboarding redesign — same mascot/title/subtitle
// pattern as LibraryAccountView's own "Set up your library" screen just
// above, with two stacked ghost fields (left-aligned, Quicksand — NOT
// the single centered Baloo-2 field the sign-up steps use, since two
// fields sharing one screen read better smaller and left-aligned than
// centered and oversized). A successful sign-in now lands directly on
// LibraryHomeView (see didSignIn below), same as LibrarySignUpView's own
// terminal state.
struct LibraryLoginView: View {
    // @Binding so "Go Back" can clear it, returning to LibraryAccountView's
    // log in/sign up picker.
    @Binding var authMode: AuthMode?

    // Passed straight through to LibraryHomeView once sign-in succeeds
    // (see didSignIn just below) — that screen's own "Sign Out" is the
    // only thing that actually changes this, and what it changes it to.
    @Binding var currentPage: Page

    // Also passed straight through to LibraryHomeView, for the same
    // reason — "Sign Out" clears this back to nil so AccountView shows
    // its own "library or reader" picker again, rather than skipping
    // straight back into this same library flow.
    @Binding var accountType: AccountType?

    @Environment(AuthService.self) private var authService

    @State private var username: String = ""
    @State private var password: String = ""

    // nil until a sign-in attempt fails; cleared again on the next attempt.
    @State private var errorMessage: String? = nil

    // Disables "Log In" for the duration of a sign-in attempt, so a slow
    // network can't be worked around by mashing the button into firing
    // several sign-ins at once.
    @State private var isSubmitting: Bool = false

    // Set once sign-in actually succeeds — lands directly on the
    // library's own home screen (see LibraryHomeView) rather than the
    // old version of this screen's own "skip straight to currentPage =
    // .library the instant Firebase confirmed sign-in."
    @State private var didSignIn: Bool = false

    var body: some View {
        if didSignIn {
            LibraryHomeView(greeting: .loggedIn, currentPage: $currentPage, accountType: $accountType)
        } else {
            loginForm
        }
    }

    private var loginForm: some View {
        VStack(spacing: Spacing.medium) {
            OnboardingProgressBar(step: 5, total: 5)
                .padding(.bottom, Spacing.small)

            OnboardingMascot(size: 96, sparkleCount: 0, showsGlow: false)

            OnboardingPageHeader(
                title: "Log in to your library",
                titleSize: 30,
                subtitle: "Enter your library credentials.",
                subtitleSize: 16
            )

            VStack(spacing: Spacing.medium) {
                VStack(spacing: Spacing.small) {
                    TextField(
                        "",
                        text: $username,
                        prompt: Text("Username")
                            .foregroundStyle(Color.onboardingTextSecondary.opacity(0.7))
                    )
                    .textFieldStyle(.plain)
                    .font(OnboardingFont.body(18, weight: .bold))
                    .foregroundStyle(Color.onboardingText)
                    // Stops the keyboard from auto-capitalizing the first
                    // letter, since capitals get stripped right back out
                    // anyway.
                    .textInputAutocapitalization(.never)
                    .tint(Color.onboardingText)
                    .onChange(of: username) { _, newValue in
                        username = sanitizedUsername(newValue)
                    }

                    Rectangle()
                        .fill(Color.onboardingBorder)
                        .frame(height: 2)
                }

                VStack(spacing: Spacing.small) {
                    // SecureField (not TextField) hides what's typed, the
                    // way password fields normally work.
                    SecureField(
                        "",
                        text: $password,
                        prompt: Text("Password")
                            .foregroundStyle(Color.onboardingTextSecondary.opacity(0.7))
                    )
                    .textFieldStyle(.plain)
                    .font(OnboardingFont.body(18, weight: .bold))
                    .foregroundStyle(Color.onboardingText)
                    .tint(Color.onboardingText)

                    Rectangle()
                        .fill(Color.onboardingBorder)
                        .frame(height: 2)
                }
            }

            if let errorMessage {
                OnboardingErrorLabel(message: errorMessage, isLeading: true)
            }

            Spacer()

            Button(action: {
                logIn()
            }, label: {
                Text("Log In")
            })
            .buttonStyle(OnboardingPrimaryButtonStyle())
            // Neither field can be left blank — an empty username or
            // password would just fail the sign-in anyway, so there's no
            // reason to let the button fire (and show a network error)
            // before both are actually filled in.
            .disabled(isSubmitting || username.isEmpty || password.isEmpty)

            OnboardingBackButton(action: {
                authMode = nil
            })
        }
        .padding(Spacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.onboardingBackground.ignoresSafeArea())
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
                didSignIn = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}

/// Which step of LibrarySignUpView's own wizard is showing.
// A dedicated enum (rather than the old plain Int) since each step is now
// its own full screen with its own title/copy/field, not just a
// swapped-out field within one shared layout.
private enum LibrarySignUpStep {
    case libraryName
    case username
    case password
    case confirmPassword
    case success
}

/// Signing up for a new library account, as four separate full-screen
/// steps — one field per screen — plus a final confirmation screen once
/// the account is actually created.
// Matching HomeView's own "What should we call you?" onboarding step
// exactly (mascot, centered Baloo 2 title, single underlined field,
// Continue/Go Back). Each step's own step-N-of-4 progress bar is separate
// from the main onboarding flow's — this sub-flow restarts its own count
// at step 1, since reaching here already means onboarding proper is
// finished.
struct LibrarySignUpView: View {
    @Binding var authMode: AuthMode?

    // Passed straight through to LibraryHomeView once the account is
    // actually created (see successStep below) — that screen's own
    // "Sign Out" is the only thing that actually changes this, and what
    // it changes it to.
    @Binding var currentPage: Page

    // Also passed straight through to LibraryHomeView, for the same
    // reason — "Sign Out" clears this back to nil so AccountView shows
    // its own "library or reader" picker again, rather than skipping
    // straight back into this same library flow.
    @Binding var accountType: AccountType?

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

    // The terminal step, once the account is actually created — lands
    // directly on the library's own home screen (see LibraryHomeView),
    // not a separate generic "you're all set" screen first.
    private var successStep: some View {
        LibraryHomeView(greeting: .signedUp, currentPage: $currentPage, accountType: $accountType)
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
                // Also best-effort, for the same reason — LibraryHomeView
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

/// Which flow just landed a library account here (Sign Up vs. Log In) —
/// both end on the exact same screen, differing only in the greeting.
// Sign Up and Log In both end on the exact same screen (same join code,
// same Manage Catalog/Sign Out actions), differing only in the very first
// thing it says.
enum LibraryHomeGreeting {
    case signedUp
    case loggedIn

    var title: String {
        switch self {
        case .signedUp: return "You're all set!"
        case .loggedIn: return "Welcome back!"
        }
    }
}

/// A library account's actual home screen — reached directly from either
/// LibrarySignUpView or LibraryLoginView the moment auth succeeds.
// Replacing the old separate "Welcome Back" LibraryView entirely. There's
// no reason to route through a generic "you're all set" screen and THEN a
// second, separate welcome screen when one screen can say hello and show
// the join code together — and styled with OnboardingTheme.swift's
// components, not Theme.swift's, since that's the direction the rest of
// the app is headed too, not just onboarding proper.
struct LibraryHomeView: View {
    let greeting: LibraryHomeGreeting

    // Set to .account by "Sign Out" below, landing on AccountView's own
    // "library or reader" picker directly.
    @Binding var currentPage: Page

    // Cleared to nil by "Sign Out" below, alongside currentPage — without
    // this, AccountView would see accountType still set to .library and
    // skip its own picker, landing right back in LibraryAccountView
    // instead of actually asking "library or reader" again.
    @Binding var accountType: AccountType?

    @Environment(AuthService.self) private var authService

    // nil until the join code finishes loading (or fails to). Distinct
    // from an empty string so the view can tell "still loading" apart from
    // "loaded, but there's nothing there".
    @State private var joinCode: String? = nil
    @State private var loadError: String? = nil

    // Toggled on by "Manage Catalog" below — swaps this whole view's own
    // body over to LibraryCatalogManagementView, a real full screen (see
    // that struct's own doc comment for why it's not a sheet anymore)
    // rather than presenting it separately.
    @State private var isManagingCatalog: Bool = false

    // Toggled on by the gear icon below — same "swap this view's own
    // body" pattern as isManagingCatalog just above, for the same reason
    // (see SettingsView's own doc comment for why it's not a sheet).
    @State private var isShowingSettings: Bool = false

    var body: some View {
        if isManagingCatalog {
            LibraryCatalogManagementView(isManagingCatalog: $isManagingCatalog)
        } else if isShowingSettings {
            SettingsView(isShowingSettings: $isShowingSettings, currentPage: $currentPage, accountType: $accountType)
        } else {
            homeContent
        }
    }

    private var homeContent: some View {
        VStack(spacing: Spacing.large) {
            Spacer()

            OnboardingMascot(size: 130, sparkleCount: 2)

            OnboardingPageHeader(title: greeting.title, titleSize: 44)

            // Readers use this to find and join THIS specific library —
            // see ReaderAccountView's own join-code field.
            Group {
                if let joinCode {
                    VStack(spacing: Spacing.small) {
                        Text("Your Join Code")
                            .font(OnboardingFont.body(16, weight: .semiBold))
                            .foregroundStyle(Color.onboardingTextSecondary)
                        Text(joinCode)
                            .font(OnboardingFont.display(32))
                            .tracking(4)
                            .foregroundStyle(Color.onboardingText)
                    }
                    .padding(Spacing.large)
                    .frame(maxWidth: .infinity)
                    .background(Color.onboardingCard)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                } else if let loadError {
                    OnboardingErrorLabel(message: loadError)
                } else {
                    ProgressView()
                }
            }

            Spacer()

            Button(action: {
                isManagingCatalog = true
            }, label: {
                Text("Manage Catalog")
            })
            .buttonStyle(OnboardingPrimaryButtonStyle())

            Button(action: {
                // try? rather than try: sign-out failing here isn't
                // something this screen needs to react to, and there's
                // nowhere more useful to send the user than the account
                // picker regardless of the outcome.
                try? authService.signOut()
                accountType = nil
                currentPage = .account
            }, label: {
                Text("Sign Out")
            })
            .buttonStyle(OnboardingSecondaryButtonStyle())
        }
        .padding(Spacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.onboardingBackground.ignoresSafeArea())
        .overlay(alignment: .topTrailing) {
            Button(action: {
                isShowingSettings = true
            }, label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.onboardingTextSecondary)
                    .padding(Spacing.large)
            })
            .buttonStyle(HapticButtonStyle())
            .accessibilityLabel("Settings")
        }
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
    }
}

/// Lets a signed-in library account choose which catalog items its
/// readers are allowed to read.
// A real full screen now (see LibraryHomeView's own isManagingCatalog
// toggle above), not a sheet, styled with OnboardingTheme.swift's
// components like the rest of the app is moving toward. Every toggle flip
// saves immediately (see save() below) rather than needing a separate
// "Save" button, since there's nothing else on this screen a half-saved
// toggle could conflict with — "Go Back" is exactly equivalent to the old
// sheet's "Done", just styled to match.
struct LibraryCatalogManagementView: View {
    // Set back to false by "Go Back" below — LibraryHomeView owns this,
    // not this view, the same way e.g. LibraryAccountView's own authMode
    // switches between its sub-screens rather than each one dismissing
    // itself.
    @Binding var isManagingCatalog: Bool

    @Environment(AuthService.self) private var authService

    @State private var catalog: [ReadableContent] = []
    @State private var enabledContentIds: Set<String> = []

    @State private var isLoading: Bool = true
    @State private var loadError: String? = nil
    @State private var saveError: String? = nil

    var body: some View {
        VStack(spacing: Spacing.medium) {
            OnboardingPageHeader(title: "Manage Catalog", titleSize: 34)
                .padding(.top, Spacing.large)

            Group {
                if isLoading {
                    Spacer()
                    ProgressView()
                        .tint(Color.onboardingText)
                    Spacer()
                } else if let loadError {
                    Spacer()
                    OnboardingErrorLabel(message: loadError)
                    Spacer()
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
                            .font(OnboardingFont.body(18, weight: .semiBold))
                            .foregroundStyle(Color.onboardingText)
                            // A hand-drawn switch (see OnboardingToggleStyle
                            // in OnboardingTheme.swift), not the system
                            // ".switch" style — recent iOS versions render
                            // that with a translucent glass material that
                            // doesn't fit this flow's flat, opaque look.
                            .toggleStyle(OnboardingToggleStyle())
                            .padding(.vertical, Spacing.small)
                            .listRowBackground(Color.onboardingCard)
                        }
                    }
                    .scrollContentBackground(.hidden)

                    if let saveError {
                        OnboardingErrorLabel(message: saveError)
                    }
                }
            }

            OnboardingBackButton(action: {
                isManagingCatalog = false
            })
        }
        .padding(.horizontal, Spacing.large)
        .padding(.bottom, Spacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.onboardingBackground.ignoresSafeArea())
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

// MARK: - Reader Account

/// Lets a reader join an organization/library with just its join code —
/// no account, no name, no log in/sign up split.
// Once a code resolves to a real library (via AuthService.fetchLibraryName),
// hands off to this reader's own proper landing page (see
// readerHomeContent below) instead of the join form — the reader-path
// equivalent of LibraryHomeView, reached the same way (directly, once
// "signed in," rather than via a separate generic success screen first).
struct ReaderAccountView: View {
    @Binding var accountType: AccountType?

    // Set to .choose once the reader taps "Start Reading" on the
    // joined-org page below.
    @Binding var currentPage: Page

    // Reported back up to ContentView so ChooseView knows whose
    // libraryCatalogSelections to filter the catalog against — and, since
    // it lives up there rather than as local @State here, also what this
    // view itself reads (see body below) to tell "joined" apart from
    // "not joined yet" across a round trip through ChooseView and back.
    // A plain local @State here would reset to nil every time ChooseView's
    // own "Go Back" sends currentPage to .account, since SwiftUI tears
    // this whole struct down and rebuilds it fresh whenever that branch of
    // ContentView's own if/else-if is re-entered — landing a reader who'd
    // already joined back on the join-code form instead of their own
    // landing page. Cleared back to nil by "Sign Out" below, the same way
    // LibraryHomeView's own Sign Out clears its own equivalent state.
    @Binding var joinedLibraryUid: String?

    // The same key HomeView's onboarding name step writes to — this is
    // what readerHomeContent's greeting below reads to say "Hi, {name}".
    @AppStorage("readerName") private var readerName: String = ""

    @Environment(AuthService.self) private var authService

    // Holds the code AS DISPLAYED, hyphen included (e.g. "AB3-9F2") —
    // unlike the old CodeEntryField-based "code" this replaces, which
    // only ever held the 6 raw characters and reconstructed the hyphen
    // separately at submit time. See formattedJoinCode(from:) below for
    // why keeping the hyphen inline here is simpler now.
    @State private var joinCode: String = ""

    // nil until a submit fails (malformed code, no match, or a network
    // error); cleared again as soon as the field's own value changes.
    @State private var errorMessage: String? = nil

    // Disables "Join Library" for the duration of a lookup, so a slow
    // network can't be worked around by mashing the button into firing
    // several at once. Unlike the design's own static mock, there's a
    // real network call here, so this is the one thing this screen adds
    // beyond the reference.
    @State private var isSubmitting: Bool = false

    // Toggled on by the gear icon below — swaps this whole view's own
    // body over to SettingsView, same pattern LibraryHomeView uses for
    // its own gear icon (see SettingsView's own doc comment for why it's
    // not a sheet).
    @State private var isShowingSettings: Bool = false

    var body: some View {
        if joinedLibraryUid != nil {
            if isShowingSettings {
                SettingsView(isShowingSettings: $isShowingSettings, currentPage: $currentPage, accountType: $accountType, joinedLibraryUid: $joinedLibraryUid)
            } else {
                readerHomeContent
            }
        } else {
            VStack(spacing: Spacing.medium) {
                OnboardingProgressBar(step: 5, total: 5)
                    .padding(.bottom, Spacing.small)

                OnboardingMascot(size: 96, sparkleCount: 0, showsGlow: false)

                OnboardingPageHeader(
                    title: "Enter your join code",
                    titleSize: 30,
                    subtitle: "Ask your library for this code.",
                    subtitleSize: 16
                )

                VStack(spacing: Spacing.small) {
                    TextField(
                        "",
                        text: $joinCode,
                        prompt: Text("Join code")
                            .foregroundStyle(Color.onboardingTextSecondary.opacity(0.7))
                    )
                    .textFieldStyle(.plain)
                    .font(OnboardingFont.display(32))
                    .tracking(4)
                    .foregroundStyle(Color.onboardingText)
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.characters)
                    .tint(Color.onboardingText)
                    .onChange(of: joinCode) { _, newValue in
                        joinCode = formattedJoinCode(from: newValue)
                        errorMessage = nil
                    }

                    Rectangle()
                        .fill(Color.onboardingBorder)
                        .frame(height: 2)
                }

                if let errorMessage {
                    OnboardingErrorLabel(message: errorMessage)
                }

                Spacer()

                Button(action: {
                    submitJoinCode()
                }, label: {
                    Text("Join Library")
                })
                .buttonStyle(OnboardingPrimaryButtonStyle())
                .disabled(isSubmitting)

                OnboardingBackButton(action: {
                    accountType = nil
                })
            }
            .padding(Spacing.large)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.onboardingBackground.ignoresSafeArea())
        }
    }

    // A reader's own landing page once joined — the reader-path
    // equivalent of LibraryHomeView's homeContent, right down to the
    // gear icon and Sign Out button in the same spots. "Hi, {name}"
    // reuses the exact same greeting HomeView's own onboarding greeting
    // step shows, so a reader sees a familiar, personal welcome here
    // too, not just a generic "you're in" message. Sign Out (not "Go
    // Back") is deliberate: a reader who leaves this page has nowhere
    // meaningful to "go back" to — clearing joinedLibraryUid and
    // accountType and landing on AccountView's own picker is a real
    // sign-out, exactly like LibraryHomeView's own Sign Out, even though
    // a reader was never actually authenticated with Firebase to begin
    // with (there's no authService.signOut() call to make here).
    private var readerHomeContent: some View {
        VStack(spacing: Spacing.large) {
            Spacer()

            OnboardingMascot(size: 130, sparkleCount: 2)

            OnboardingPageHeader(
                title: "Hi, \(readerName)",
                titleSize: 44,
                subtitle: "You're in. Time to find your next great read.",
                subtitleSize: 18
            )

            Spacer()

            Button(action: {
                currentPage = .choose
            }, label: {
                Text("Start Reading")
            })
            .buttonStyle(OnboardingPrimaryButtonStyle())

            Button(action: {
                joinedLibraryUid = nil
                accountType = nil
                currentPage = .account
            }, label: {
                Text("Sign Out")
            })
            .buttonStyle(OnboardingSecondaryButtonStyle())
        }
        .padding(Spacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.onboardingBackground.ignoresSafeArea())
        .overlay(alignment: .topTrailing) {
            Button(action: {
                isShowingSettings = true
            }, label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.onboardingTextSecondary)
                    .padding(Spacing.large)
            })
            .buttonStyle(HapticButtonStyle())
            .accessibilityLabel("Settings")
        }
    }

    // Reformats on every keystroke, same as the design's own
    // formatJoinCode: strip anything that isn't a letter/digit (so a
    // pasted "AB3-9F2" — hyphen included — still works), force
    // uppercase, cap at 6 real characters, then re-insert the hyphen
    // after the 3rd once there's anything past it. Stripping first and
    // re-inserting after means this handles backspacing through the
    // hyphen correctly too, without any special-case code for it.
    private func formattedJoinCode(from raw: String) -> String {
        let clean = String(raw.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(6))
        guard clean.count > 3 else { return clean }
        return "\(clean.prefix(3))-\(clean.dropFirst(3))"
    }

    private func submitJoinCode() {
        guard joinCode.range(of: "^[A-Z0-9]{3}-[A-Z0-9]{3}$", options: .regularExpression) != nil else {
            errorMessage = "Enter a valid code like ABC-123."
            return
        }

        errorMessage = nil
        isSubmitting = true
        Task {
            do {
                if let library = try await authService.fetchJoinedLibrary(forJoinCode: joinCode) {
                    // Setting this is what flips body above from the join
                    // form to readerHomeContent — library.name itself
                    // isn't kept anywhere; see readerHomeContent's own doc
                    // comment for why nothing downstream shows it.
                    joinedLibraryUid = library.uid
                } else {
                    errorMessage = "We couldn't find a library with that code."
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}

// MARK: - Catalog

/// The screen listing content to pick from, sectioned into "From Your
/// Library" (whatever the reader's joined library has enabled) and
/// "Saved by You" (whatever the reader has shared/read themselves before).
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
    // in-progress fetch. Two separate arrays (rather than one flat list
    // filtered by .source at render time) since they come from two
    // genuinely different fetches — library content is filtered against
    // libraryUid's enabled set, saved content is the signed-in reader's
    // own, unrelated to any library.
    @State private var libraryContent: [ReadableContent] = []
    @State private var savedContent: [ReadableContent] = []
    @State private var isLoading: Bool = true
    @State private var loadError: String? = nil

    var body: some View {
        VStack(spacing: Spacing.medium) {
            OnboardingPageHeader(title: "Choose Something to Read", titleSize: 34)
                .padding(.top, Spacing.large)

            Group {
                if isLoading {
                    Spacer()
                    ProgressView()
                        .tint(Color.onboardingText)
                    Spacer()
                } else if let loadError {
                    Spacer()
                    OnboardingErrorLabel(message: loadError)
                    Spacer()
                } else if libraryContent.isEmpty && savedContent.isEmpty {
                    Spacer()
                    Text("Nothing to read yet — your library hasn't added anything, and you haven't saved anything by sharing a link into Fast Lit.")
                        .font(OnboardingFont.body(16, weight: .semiBold))
                        .foregroundStyle(Color.onboardingTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.large)
                    Spacer()
                } else {
                    List {
                        // Only rendered when non-empty — an empty Section
                        // still draws its header with nothing underneath,
                        // which reads as "your library has zero content"
                        // even when the real reason is just that the
                        // OTHER section (Saved) is the one with items.
                        if !libraryContent.isEmpty {
                            Section("From Your Library") {
                                ForEach(libraryContent) { item in
                                    CatalogRow(content: item) {
                                        selectedContent = item // triggers the .sheet below
                                    }
                                }
                            }
                        }
                        if !savedContent.isEmpty {
                            Section("Saved by You") {
                                ForEach(savedContent) { item in
                                    CatalogRow(content: item) {
                                        selectedContent = item
                                    }
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }

            // .account, not .home — a reader reaching this page always has
            // hasCompletedOnboarding set, so .home would just immediately
            // redirect to .account anyway (see HomeView's own body); going
            // there directly skips that redirect hop. Lands back on
            // ReaderAccountView's own readerHomeContent ("Hi, {name}" +
            // Settings), not the join-code form, since joinedLibraryUid is
            // still set — see that view's own doc comment on why it reads
            // that Binding rather than its own local state for this.
            OnboardingBackButton(action: {
                currentPage = .account
            })
        }
        .padding(.horizontal, Spacing.large)
        .padding(.bottom, Spacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.onboardingBackground.ignoresSafeArea())
        // .sheet(item:) shows a modal whenever the bound value is non-nil,
        // passing the unwrapped value in. "$" turns @State into a two-way
        // Binding. Attached to the whole VStack (rather than nested inside
        // the List branch above) so it stays in place no matter which of
        // the loading/error/empty/list branches above is currently showing.
        .sheet(item: $selectedContent) { item in
            // onAccept is a closure we pass in; the detail view calls it
            // without knowing what it does here on our side. No
            // NavigationStack wrapper — ReadableContentDetailView is
            // styled with OnboardingTheme.swift's own components now,
            // which build their own header/buttons rather than relying
            // on a nav bar's title/toolbar for either.
            ReadableContentDetailView(content: item, onAccept: {
                contentToRead = item // remember what to read...
                currentPage = .read // ...then go straight to reading —
                // ReadView itself locks the screen into landscape on
                // appear (see its .onAppear), so there's no need for
                // an intermediate "please rotate your device" screen
                // asking the reader to do it by hand.
            })
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
            // ensureReaderSignedIn first (not raced alongside the other
            // two fetches below) — fetchSavedContent needs a signed-in
            // uid to know whose saved content to read, and this is the
            // one place besides ContentView's own share-arrival path
            // where a reader might be the very first time they've ever
            // needed a session at all (e.g. they joined a library but
            // have never shared anything).
            try? await authService.ensureReaderSignedIn()
            async let catalogFetch = authService.fetchCatalog()
            async let enabledFetch = authService.fetchEnabledContentIds(forLibraryUid: libraryUid)
            async let savedFetch = authService.fetchSavedContent()
            let catalog = try await catalogFetch
            let enabledIds = try await enabledFetch
            libraryContent = catalog.filter { enabledIds.contains($0.id) }
            // Best-effort (try?, not try): a signed-in-but-offline reader
            // should still see their library content even if the saved-
            // content fetch itself fails — an empty Saved section is a
            // much better failure mode here than losing the whole screen
            // to loadError over something that isn't even this reader's
            // library's fault.
            savedContent = (try? await savedFetch) ?? []
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }
}

/// One row in ChooseView's Library/Saved sections — shows a title plus
/// word count and estimated reading time.
// Bigger and more spacious than the old title-only row specifically so
// there's room for the word count and estimated reading time beneath the
// title, both computed from ReadingPace so the estimate always matches
// ReadView's own pacing (see that file's top comment).
private struct CatalogRow: View {
    let content: ReadableContent
    let action: () -> Void

    // 300 wpm — the same value ReadView's own @State wpm starts every
    // fresh read at (see ReadView's `wpm` property) — so this estimate
    // matches what a reader who hasn't touched the speed slider yet will
    // actually experience, rather than some other arbitrary reference
    // speed.
    private static let referenceWPM = 300

    private var wordCountAndDuration: (words: Int, minutes: Int) {
        let (wordCount, beats) = ReadingPace.wordCountAndTotalBeats(for: content.text)
        let seconds = Int((beats * 60.0 / Double(Self.referenceWPM)).rounded())
        // Rounds UP to the nearest minute (not down, and not "0 min" for
        // anything under 60s) — a reader deciding whether they have time
        // for something should never be told "0 min" for a piece that
        // will visibly take them some real time to read.
        let minutes = max(1, Int((Double(seconds) / 60.0).rounded(.up)))
        return (wordCount, minutes)
    }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: Spacing.medium) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(content.title)
                        .font(OnboardingFont.body(19, weight: .semiBold))
                        .foregroundStyle(Color.onboardingText)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    let (words, minutes) = wordCountAndDuration
                    Text("\(words.formatted()) words · \(minutes) min read")
                        .font(OnboardingFont.body(14, weight: .medium))
                        .foregroundStyle(Color.onboardingTextSecondary)
                }
                Spacer(minLength: Spacing.small)
                // A visible ">" hints the row is tappable, beyond just
                // the row itself looking like a button — a small extra
                // clarity cue.
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.onboardingTextSecondary)
            }
            // More generous than the old row's Spacing.medium alone —
            // this row now carries two lines of text instead of one, so
            // it needs more vertical room to still read as spacious
            // rather than cramped.
            .padding(.vertical, Spacing.medium + 4)
            // Full-width frame + an explicit rectangular hit-testing
            // shape: without these, SwiftUI only counts a tap as landing
            // on this Button if it's directly over the title/subtitle
            // Text or the chevron Image — the Spacer between them (and
            // the padding around both) draws nothing, so it's invisible
            // to hit-testing by default even though it's visually part
            // of the same row.
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(HapticButtonStyle())
        .listRowBackground(Color.onboardingCard)
    }
}

// MARK: - RSVP Reading

/// ReadView's own color palette, pulled literally from the design doc
/// rather than reused from OnboardingTheme.swift's Color.onboarding* tokens.
// (claude.ai/design project bc14e680, "Read Page Redesign -
// Landscape.dc.html", options 2a light / 2b dark). Checked every
// role against the actual asset-catalog hex values first: the DARK side
// of every single one matches OnboardingTheme's dark tokens exactly
// (background/rail/primary/secondary/divider all equal
// onboardingBackground/Card/Text/TextSecondary/Border|Track's own dark
// hexes), but the LIGHT side never does — 2a's own light palette is a
// distinct warm cream/tan (#FBF3E7 background, #3D3226 primary, ...)
// that's simply different from OnboardingTheme's neutral-gray light
// values, not an approximation of them. Since reusing the onboarding
// token would silently substitute the wrong LIGHT color while
// coincidentally still working in dark mode, every role here gets its
// own adaptive color built directly from the doc's literal light/dark
// hex pair instead.
private enum ReadColor {
    static let background = adaptive(light: 0xFBF3E7, dark: 0x1E1C1A)
    static let rail = adaptive(light: 0xFFFBF3, dark: 0x2A2826)
    static let primary = adaptive(light: 0x3D3226, dark: 0xF2EFE9)
    static let secondary = adaptive(light: 0x8A7A68, dark: 0xA8A399)
    static let divider = adaptive(light: 0xEADFCB, dark: 0x3A3733)
    // The Play tile's icon color: literally the doc's own background hex
    // in both modes (#FBF3E7 light / #1E1C1A dark) — light text on a
    // dark-filled tile in light mode, dark text on a light-filled tile
    // in dark mode, same as "background" above but named for what it's
    // actually used for at each call site.
    static let onPrimary = adaptive(light: 0xFBF3E7, dark: 0x1E1C1A)
    // Doc's own close-button alpha differs by appearance (.06 light /
    // .1 dark), not just its base hex, so this can't be expressed as a
    // plain "primary.opacity(x)" the way a single shared alpha could.
    static let closeButtonBackground = adaptive(light: 0x3D3226, lightAlpha: 0.06, dark: 0xF2EFE9, darkAlpha: 0.1)
    // Same story for the Back/Forward buttons' background (.05 light /
    // .06 dark).
    static let inactiveTileBackground = adaptive(light: 0x3D3226, lightAlpha: 0.05, dark: 0xF2EFE9, darkAlpha: 0.06)
    // The bottom bar's own drop shadow: "0 4px 16px rgba(61,50,38,.08)"
    // light, "0 4px 16px rgba(0,0,0,.3)" dark — a different base color in
    // dark mode (plain black), not just a different alpha on "primary".
    static let bottomBarShadow = adaptive(light: 0x3D3226, lightAlpha: 0.08, dark: 0x000000, darkAlpha: 0.3)

    private static func adaptive(light: UInt32, lightAlpha: CGFloat = 1, dark: UInt32, darkAlpha: CGFloat = 1) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(readHex: dark, alpha: darkAlpha)
                : UIColor(readHex: light, alpha: lightAlpha)
        })
    }
}

private extension UIColor {
    convenience init(readHex: UInt32, alpha: CGFloat) {
        self.init(
            red: CGFloat((readHex >> 16) & 0xFF) / 255,
            green: CGFloat((readHex >> 8) & 0xFF) / 255,
            blue: CGFloat(readHex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

/// The actual reading screen — shows one word at a time (RSVP: Rapid
/// Serial Visual Presentation), advancing automatically at a configurable
/// words-per-minute pace with punctuation-aware pauses (see ReadingPace.swift).
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

    // When the word currently on screen started its hold — set fresh in
    // scheduleNextAdvance() every time it (re)commits to a hold duration
    // for whichever word is now current (a fresh word advancing into
    // view, or play()/adjustWPM() restarting the current word's hold at
    // a new speed). timeRemainingLabel(asOf:) below uses this to
    // subtract elapsed real time from the current word's own hold, which
    // is what makes the displayed countdown tick smoothly every second
    // instead of holding flat for however many beats the current word is
    // worth (e.g. 3.5 beats after a sentence-ending period) and then
    // jumping down all at once the moment it advances.
    @State private var wordShownAt: Date = Date()

    // True only while a finger is actually down on the progress bar —
    // @GestureState (not plain @State) so it resets itself back to
    // false automatically the instant the drag ends, without needing an
    // explicit onEnded to set it back. headerRow's progress bar reads
    // this to skip its own eased animation while actively scrubbing.
    @GestureState private var isDraggingProgress: Bool = false

    // @ScaledMetric ties a value to Dynamic Type the same way a built-in
    // text style would, but for a plain number rather than a Font — the
    // base value below (100, the design doc's own literal font-size for
    // this word) is what this renders at under the system's default text
    // size, and it scales up or down from there as someone adjusts their
    // text size setting. "relativeTo: .largeTitle" caps how aggressively
    // it grows, since this word display already sits at the large end of
    // the scale.
    @ScaledMetric(relativeTo: .largeTitle) private var focalWordSize: CGFloat = 100

    // A long word drawn at the full focalWordSize can run far enough
    // toward either edge to sit under the Dynamic Island (the leading
    // edge, in this landscape layout) or run past the trailing edge
    // entirely — the before/after Text pieces in wordDisplay below have
    // nothing stopping them from growing that wide. Scaling the whole
    // word down around its own fixed center point (see wordDisplay's
    // own .scaleEffect) instead of truncating or wrapping keeps RSVP's
    // one-fixed-focal-point design intact while still pulling long words
    // back in from the edges.
    //
    // Character count, not a measured render width: a GeometryReader
    // here would re-measure on every single word tick, which is the
    // exact per-tick cost that was just removed from this view for
    // "words" itself (see that property's own comment) — a length
    // threshold is free to compute and close enough, since this only
    // needs to catch words that are ROUGHLY too long, not hit an exact
    // pixel boundary.
    private var focalWordScale: CGFloat {
        let length = tokenized.words[indexNum].count
        guard length > Self.wordScaleThreshold else { return 1.0 }
        let excess = CGFloat(length - Self.wordScaleThreshold)
        return max(Self.minimumFocalWordScale, 1.0 - excess * Self.focalWordScaleStep)
    }

    // Below this many characters, a word gets no scale-down at all —
    // this is comfortably longer than the vast majority of English
    // words, so ordinary reading is never touched by this at all.
    private static let wordScaleThreshold = 8

    // How much smaller the word gets per character past the threshold —
    // small enough that even a very long word (15-20 characters) scales
    // down gradually rather than snapping straight to the floor below.
    private static let focalWordScaleStep: CGFloat = 0.035

    // However long a word gets, it never shrinks past this fraction of
    // focalWordSize — keeps even extreme outliers (a long hyphenated
    // compound, say) legible rather than shrinking toward illegibility.
    private static let minimumFocalWordScale: CGFloat = 0.6

    // @State, split ONCE in the custom init below rather than a computed
    // property re-splitting content.text on every access. It was a
    // computed property originally, which reads fine for a short passage
    // but turned out to be the actual cause behind "RSVP skips words on
    // long passages" — tokenized.words is read from several places per
    // single word tick (scheduleNextAdvance's ReadingPace.beats(forWordAt:
    // indexNum), wordParts, the progress bar's word count, the caption
    // labels), and at 600 wpm that's every ~100ms. Re-splitting and
    // re-allocating a ~400-word array (the "Deep Sea" passage) that many
    // times a second is real, avoidable CPU work that a short ~50-word
    // passage (like "Welcome to Fast Lit," which never showed the bug)
    // never comes close to — matching exactly which passages the
    // reader-facing report separated into "always fine" vs "always
    // broken." content is fixed for this view's whole lifetime (see its
    // own comment above), so splitting once here is correct, not just
    // faster.
    //
    // ReadingPace.tokenize (not a bespoke split here) — see that file's
    // own top comment: the catalog's estimated-reading-time rows need the
    // exact same word/line-break/punctuation logic ReadView uses for live
    // playback pacing, so both live in one shared place instead of two
    // copies that could quietly drift apart.
    private let tokenized: ReadingPace.Tokenized

    // Custom init only because "tokenized" above needs "content" to
    // compute itself once, up front — every other property here still
    // just takes its own declared default the way the
    // compiler-synthesized memberwise init would have handed it.
    init(content: ReadableContent, currentPage: Binding<Page>) {
        self.content = content
        self._currentPage = currentPage
        self.tokenized = ReadingPace.tokenize(content.text)
    }

    // Splits the current word into the letters before its middle letter (the
    // "focal letter" RSVP readers center each word on), the middle letter
    // itself, and the letters after it. Kept as three separate pieces (rather
    // than one combined string) so body can lay each one out in its own
    // flexible-width container — that's what keeps the middle letter fixed
    // at screen-center regardless of how many letters sit on either side of it.
    var wordParts: (before: String, center: String, after: String) {
        let word = tokenized.words[indexNum]
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
    // Clamped to 0...tokenized.words.count - 1 so a tap at either end can't
    // push indexNum out of range, which would crash the words[indexNum]
    // lookup below.
    func updateIndex(increment: Int) -> Void {
        indexNum = min(max(indexNum + increment, 0), tokenized.words.count - 1)
    }

    // Punctuation that earns a brief extra beat when it ends a word — the
    // reader takes a short breath here, but the sentence keeps going.
    // Deliberately NOT a plain ASCII hyphen "-": that shows up at the end
    // of a whitespace-split "word" too easily for unrelated reasons (a
    // hard-hyphenated compound word broken across a line, for instance),
    // where it wouldn't actually mean "pause here" the way an em/en dash
    // does.
    //
    // (Punctuation tables and the beat-lookup itself now live in
    // ReadingPace.swift — shared with the catalog's estimated-reading-time
    // rows, see that file's own top comment. This section only keeps the
    // Timer-scheduling logic that actually belongs to live playback.)

    // (Re)creates the Timer driving playback at the current wpm and
    // current word's own pause length. Pulled out of play() so a wpm
    // change made mid-playback can rebuild it at the new speed too — a
    // Timer's own interval can't be edited in place once it's scheduled,
    // so the only way to change speed (or, now, the next word's pause
    // length) is to replace it.
    func startTimer() -> Void {
        timer?.invalidate()
        scheduleNextAdvance()
    }

    // A single one-shot Timer (not a repeating one) sized to however long
    // the word CURRENTLY shown should hold — see ReadingPace.beats(forWordAt:in:) —
    // which, once it fires, advances and schedules the next one the same
    // way. A repeating Timer can't vary its own interval between ticks,
    // which is what showing a longer pause after a period than after an
    // ordinary word actually requires.
    private func scheduleNextAdvance() -> Void {
        let interval = (60.0 / Double(wpm)) * ReadingPace.beats(forWordAt: indexNum, in: tokenized)
        wordShownAt = Date()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            // Stop instead of advancing once the last word is reached, so
            // playback doesn't keep firing forever with nothing left to show.
            if indexNum >= tokenized.words.count - 1 {
                pause()
            } else {
                updateIndex(increment: 1)
                scheduleNextAdvance()
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

    // "M:SS left" at the current wpm, based on however many words remain
    // after the one currently showing — summed via
    // ReadingPace.beats(forWordAt:in:) rather than assuming a flat 1 beat
    // per word, so a passage full of commas and periods doesn't show a
    // "time left" that's optimistic about how long it'll actually take to
    // finish at this speed. Takes "now" rather than reading Date()
    // internally so the TimelineView driving it (see mainReadingArea
    // below) controls exactly when this recomputes.
    //
    // The current word's own remaining hold is handled separately from
    // the ones after it: while playing, real time elapsed since
    // wordShownAt is subtracted from its full hold duration, so the
    // countdown actually ticks down second by second through a long
    // pause (e.g. 3.5 beats after a period) instead of sitting flat
    // for the word's whole hold and then jumping down all at once the
    // moment it advances — which is what a plain sum over
    // ReadingPace.beats(forWordAt:in:) for every remaining word, current
    // one included, used to do. While paused, elapsed is treated as 0
    // (the full current-word duration counts as "still remaining"),
    // matching pause()/adjustWPM()'s own behavior of restarting a word's
    // hold fully rather than resuming a partial one.
    private func timeRemainingLabel(asOf now: Date) -> String {
        let lastIndex = tokenized.words.count - 1
        guard indexNum < lastIndex else {
            return "0:00 left"
        }
        let futureBeats = (indexNum + 1..<lastIndex).reduce(into: 0.0) { total, i in
            total += ReadingPace.beats(forWordAt: i, in: tokenized)
        }
        let currentWordDuration = ReadingPace.beats(forWordAt: indexNum, in: tokenized) * 60.0 / Double(wpm)
        let elapsedInCurrentWord = isPlaying ? min(now.timeIntervalSince(wordShownAt), currentWordDuration) : 0
        let secondsRemainingRaw = (currentWordDuration - elapsedInCurrentWord) + futureBeats * 60.0 / Double(wpm)
        let secondsRemaining = max(0, Int(secondsRemainingRaw.rounded()))
        return String(format: "%d:%02d left", secondsRemaining / 60, secondsRemaining % 60)
    }

    // "M:SS total" — how long the whole passage takes at the current
    // wpm, start to finish. Unlike timeRemainingLabel(asOf:), this
    // doesn't depend on indexNum or wall-clock time at all (just words
    // and wpm), so it's a plain computed property rather than a
    // TimelineView-driven function — it only needs to change when wpm
    // itself does, which a normal body recompute already covers.
    private var totalDurationLabel: String {
        let totalBeats = (0..<tokenized.words.count - 1).reduce(into: 0.0) { total, i in
            total += ReadingPace.beats(forWordAt: i, in: tokenized)
        }
        let totalSeconds = Int((totalBeats * 60.0 / Double(wpm)).rounded())
        return String(format: "%d:%02d total", totalSeconds / 60, totalSeconds % 60)
    }

    var body: some View {
        // Bottom-bar layout, rebuilt pixel-for-pixel from the design
        // MCP's live copy of "Read Page Redesign - Landscape.dc.html"
        // (claude.ai/design project bc14e680, turn 4 "Bottom bar v2 —
        // island-aware, no stop, centered controls + counter", options
        // 4a light / 4b dark) — replaces the previous side-rail layout
        // entirely. The word fills the whole screen, centered (no
        // fixation ticks in this version — 4a/4b's markup doesn't have
        // them); a header row (close button + progress bar) floats over
        // the top; a single pill floats over the bottom holding the
        // word-count/time caption (left), Back/Play/Forward (center, no
        // Stop anymore), and the WPM stepper (right). Uses this file's
        // own ReadColor palette (above), NOT OnboardingTheme.swift's
        // Color.onboarding* tokens — see ReadColor's own doc comment for
        // why. Deliberately still NOT Color.accentPrimary anywhere, and
        // NOT OnboardingTheme's own Quicksand/Baloo 2 fonts either — the
        // doc's own CSS asks for the system's rounded font family here,
        // not this app's branded onboarding typography.
        // GeometryReader (not a plain composition) specifically so
        // bottomBar can read geometry.safeAreaInsets.bottom below —
        // measured this pixel-for-pixel against the design's flat 16pt
        // margin: .ignoresSafeArea() on the base view (still applied
        // below) does make the leading/trailing/top margins land exactly
        // on their coded values, verified at exactly 16.0pt each with no
        // residual gap. The BOTTOM edge alone still had a consistent
        // ~21pt leftover on top of its own coded 16pt (36.7pt measured
        // instead of 16pt) even with the identical .ignoresSafeArea
        // treatment — matching the home indicator's own reserved height
        // almost exactly, so rather than fight SwiftUI's safe-area
        // resolution for that one edge, bottomBar cancels it explicitly
        // with a measured offset instead of trusting ignoresSafeArea
        // alone to zero it out.
        GeometryReader { geometry in
            wordDisplay
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(ReadColor.background)
                // .ignoresSafeArea() here (on the whole base view, BEFORE
                // the two .overlay calls below) rather than only on the
                // background is load-bearing: .overlay(alignment:)
                // positions its content relative to THIS view's own
                // reported frame, so if this view didn't ignore the safe
                // area, both overlays' alignment anchors would
                // themselves sit inset from the true edges.
                .ignoresSafeArea()
                .overlay(alignment: .top) { headerRow }
                .overlay(alignment: .bottom) {
                    bottomBar(bottomSafeAreaInset: geometry.safeAreaInsets.bottom)
                }
        }
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

    // The header row: close button + progress bar, floating over the top
    // of the whole screen. Doc's own margin is a plain 20px on top/left/
    // right (no bottom — nothing sits below it in its own flex column)
    // and a 14px gap between the two, not the old layout's separate
    // corner-pinned button + asymmetric 76px-margined bar.
    private var headerRow: some View {
        HStack(alignment: .center, spacing: 14) {
            // Replaces the old "Choose Something Different" text button
            // below the controls — same destination (currentPage =
            // .choose sends the reader back to ChooseView; .onDisappear
            // above still stops playback the same way it always did).
            Button(action: {
                currentPage = .choose
            }, label: {
                CloseXShape()
                    .stroke(ReadColor.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .frame(width: 18, height: 18)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(ReadColor.closeButtonBackground))
                    .contentShape(Circle())
            })
            .buttonStyle(HapticButtonStyle())
            .accessibilityLabel("Close and choose something different")

            // A bespoke bar rather than OnboardingProgressBar: the doc's
            // own track is a RoundedRectangle(cornerRadius: 3) at height
            // 5, not OnboardingProgressBar's Capsule at height 6, against
            // ReadColor's own divider/primary (not onboardingTrack/
            // onboardingText). Draggable to seek — the visual bar stays a
            // thin 5pt, but the GeometryReader itself gets a taller 24pt
            // frame (below) purely so the drag/tap target isn't a
            // frustratingly thin 5pt-tall sliver.
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(ReadColor.divider)
                        .frame(height: 5)
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(ReadColor.primary)
                        .frame(width: geometry.size.width * CGFloat(indexNum + 1) / CGFloat(tokenized.words.count), height: 5)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .gesture(
                    // minimumDistance: 8, not 0 — a plain tap still seeks
                    // fine (real touches almost always carry a few points
                    // of natural jitter between touch-down and lift-off),
                    // but this stops a merely-resting or grazing thumb
                    // from silently reseeking the passage. This bar spans
                    // nearly the full screen width right at the top edge
                    // — with 0, ANY incidental contact there (not just an
                    // intentional drag) immediately jumped indexNum to
                    // that x-position, which read exactly like "RSVP is
                    // randomly skipping words" from the reader's side,
                    // even though the actual advance timer never skips
                    // anything on its own (verified with frame-precise
                    // timestamped captures at both 60 and 300 wpm).
                    DragGesture(minimumDistance: 8)
                        .updating($isDraggingProgress) { _, state, _ in
                            state = true
                        }
                        .onChanged { value in
                            // Scrubbing while playing would otherwise
                            // fight with the auto-advance timer the same
                            // way manually stepping while playing would
                            // — same reasoning as backButton/forwardButton
                            // disabling themselves while isPlaying, except
                            // here it's more natural to just pause once
                            // (like a video scrubber) than to block the
                            // drag outright.
                            if isPlaying {
                                pause()
                            }
                            let fraction = min(max(value.location.x / geometry.size.width, 0), 1)
                            indexNum = min(Int(fraction * Double(tokenized.words.count)), tokenized.words.count - 1)
                        }
                )
            }
            .frame(height: 24)
            // .animation(nil) while actively dragging so the filled bar
            // tracks the finger 1:1 instead of chasing it through a
            // 0.3s ease each time indexNum changes multiple times a
            // second during a drag — the eased animation is only for the
            // ordinary word-by-word auto-advance tick.
            .animation(isDraggingProgress ? nil : .easeInOut(duration: 0.3), value: indexNum)
            .accessibilityElement()
            .accessibilityLabel("Reading progress")
            .accessibilityValue("Word \(indexNum + 1) of \(tokenized.words.count)")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    updateIndex(increment: 1)
                case .decrement:
                    updateIndex(increment: -1)
                @unknown default:
                    break
                }
            }
        }
        .padding(.top, 20)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        // Load-bearing, not decorative: without this, the row still
        // respects the system's leading/trailing safe-area insets on top
        // of the 20pt padding above (landscapeRight's sensor housing
        // reserves the whole LEADING edge, not just the band it
        // physically occupies, and the trailing edge picks up its own
        // small inset too), pushing the row in from the true edges
        // further than the doc's own flat 20px margin. The top-left
        // corner itself is still safe from the island (see
        // lockOrientation(to:) in ios_accessibleApp.swift) — this just
        // stops SwiftUI from being conservative about it.
        .ignoresSafeArea(edges: [.top, .leading, .trailing])
    }

    // The bottom pill: word-count/time caption (left), Back/Play/Forward
    // (center), WPM stepper (right) — CSS grid's "1fr auto 1fr" columns,
    // recreated the same way wordDisplay keeps its focal letter fixed at
    // screen-center: the two OUTER groups each claim an equal share of
    // the remaining width via .frame(maxWidth: .infinity), so the fixed-
    // size center group ends up truly centered in the bar regardless of
    // how wide the caption or stepper text happen to be.
    private func bottomBar(bottomSafeAreaInset: CGFloat) -> some View {
        HStack(spacing: 0) {
            // TimelineView (not a plain Text) is what makes this redraw
            // once a second on its own — without it, this only recomputes
            // when indexNum/wpm/isPlaying change, i.e. it'd sit frozen for
            // however long the current word holds and then jump, same
            // problem timeRemainingLabel(asOf:) itself is solving.
            // Time left and total time, not "Word N of Total" — a
            // reader cares more about how much longer this'll take (now
            // and overall) than the current word's raw index.
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text("\(timeRemainingLabel(asOf: context.date)) · \(totalDurationLabel)")
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(ReadColor.secondary)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 14) {
                backButton
                playPauseButton
                forwardButton
            }

            HStack(spacing: 8) {
                wpmStepperButton(symbol: "−", accessibilityLabel: "Decrease speed") {
                    adjustWPM(by: -20)
                }

                Text("\(wpm) wpm")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(ReadColor.primary)
                    .lineLimit(1)
                // wpm has no separate .onChange(of:) here — adjustWPM(by:)
                // itself already rebuilds the timer mid-playback (see its
                // own doc comment), which is what the old Slider's
                // .onChange used to do too.

                wpmStepperButton(symbol: "+", accessibilityLabel: "Increase speed") {
                    adjustWPM(by: 20)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .frame(height: 76)
        .frame(maxWidth: .infinity)
        .background(ReadColor.rail)
        .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
        .shadow(color: ReadColor.bottomBarShadow, radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        // Same reasoning as headerRow's own .ignoresSafeArea above — the
        // doc's flat 16px bottom/left/right margin is meant against the
        // true screen edges, not further in from wherever the system's
        // own safe-area insets would otherwise land it. This alone gets
        // leading/trailing exactly right (measured), but leaves the
        // home indicator's own reservation still in effect for .bottom
        // specifically — the offset below is what actually cancels that.
        .ignoresSafeArea(edges: [.bottom, .leading, .trailing])
        // Pixel-measured fix, not a guess: even with the ignoresSafeArea
        // above, the bar's actual bottom margin came out to ~36.7pt
        // instead of the coded 16pt — a leftover ~21pt matching the home
        // indicator's own safe-area reservation almost exactly, still in
        // effect despite ignoresSafeArea. Shifting down by the real
        // system-reported bottomSafeAreaInset (not a hardcoded 21) cancels
        // exactly that leftover on whatever device this runs on.
        .offset(y: bottomSafeAreaInset)
    }

    private var playPauseButton: some View {
        // Same button throughout — only its glyph and action change
        // depending on isPlaying, rather than showing two buttons and
        // hiding whichever one doesn't apply.
        Button(action: {
            if isPlaying {
                pause()
            } else {
                play()
            }
        }, label: {
            Group {
                if isPlaying {
                    // Two rounded bars — already inherently "rounded
                    // corner", no custom Shape needed the way the
                    // triangle below requires. No pause state in the
                    // design doc to trace exact proportions from (4a/4b
                    // only show the Play glyph), so these keep their own
                    // pre-existing size.
                    HStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(ReadColor.onPrimary)
                            .frame(width: 6, height: 20)
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(ReadColor.onPrimary)
                            .frame(width: 6, height: 20)
                    }
                } else {
                    // A plain, symmetric triangle — filled AND stroked
                    // with the same thick, round-joined/round-capped
                    // line. The stroke is what rounds every corner; the
                    // path itself stays a perfectly sharp, centered
                    // triangle, so there's no hand-tuned bezier and no
                    // manual re-centering offset needed.
                    ZStack {
                        PlayTriangleShape().fill(ReadColor.onPrimary)
                        PlayTriangleShape().stroke(
                            ReadColor.onPrimary,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                        )
                    }
                    .frame(width: 26, height: 26)
                }
            }
        })
        .buttonStyle(HapticButtonStyle())
        .frame(width: 62, height: 62)
        .background(ReadColor.primary)
        .clipShape(Circle())
        .accessibilityLabel(isPlaying ? "Pause" : "Play")
    }

    private var backButton: some View {
        RepeatableControl(accessibilityLabel: "Previous word", isEnabled: !isPlaying, action: {
            updateIndex(increment: -1)
        }) {
            ChevronShape(pointsLeft: true)
                .stroke(ReadColor.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .frame(width: 22, height: 22)
        }
        .frame(width: 48, height: 48)
        .background(ReadColor.inactiveTileBackground)
        .clipShape(Circle())
        // Manually stepping while the timer is also advancing indexNum
        // would fight with playback, so stepping is disabled while playing.
        .opacity(isPlaying ? 0.35 : 1.0)
    }

    private var forwardButton: some View {
        RepeatableControl(accessibilityLabel: "Next word", isEnabled: !isPlaying, action: {
            updateIndex(increment: 1)
        }) {
            ChevronShape(pointsLeft: false)
                .stroke(ReadColor.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .frame(width: 22, height: 22)
        }
        .frame(width: 48, height: 48)
        .background(ReadColor.inactiveTileBackground)
        .clipShape(Circle())
        .opacity(isPlaying ? 0.35 : 1.0)
    }

    private func wpmStepperButton(symbol: String, accessibilityLabel: String, action: @escaping () -> Void) -> some View {
        RepeatableControl(accessibilityLabel: accessibilityLabel, isEnabled: true, action: action) {
            Text(symbol)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(ReadColor.primary)
                .frame(width: 30, height: 30)
                .overlay(Circle().stroke(ReadColor.divider, lineWidth: 2))
                .contentShape(Circle())
        }
    }

    // Rather than one Text centered as a block (which would put the focal
    // letter in a different screen position for every word, depending on
    // how many letters come before/after it), "before" and "after" each
    // get a flexible container of equal width via .frame(maxWidth: .infinity)
    // and pull their text toward the middle with alignment. Since both
    // containers always claim the same share of the remaining space,
    // "center" (a fixed size, so it's never squeezed) ends up fixed at
    // screen-center every time.
    private var wordDisplay: some View {
        HStack(spacing: 0) {
            // Muted — in this app's monochrome palette there's no separate
            // hue to lean on the way a colored accent used to provide, so
            // the before/after letters are pushed back with a lighter
            // color, leaving the focal letter (plain ReadColor.primary,
            // same .medium weight as these) to stand out through color
            // contrast alone.
            Text(wordParts.before)
                .foregroundStyle(ReadColor.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(wordParts.center)
                // Color contrast only, same weight as before/after — no
                // heavier fontWeight override.
                .foregroundStyle(ReadColor.primary)
                .fixedSize()
            Text(wordParts.after)
                .foregroundStyle(ReadColor.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        // Large, since this word is the whole point of the screen —
        // everything else (progress bar, bottom bar) is secondary to it.
        // Applied to the HStack (rather than each Text) since font/
        // kerning are environment values that flow down to all three.
        // Uses focalWordSize (see @ScaledMetric above, base 100 — the
        // doc's own font-size) rather than a plain fixed number, so this
        // still grows for someone using a larger system text size, within
        // a sensible clamp. ".rounded" design matches the doc's own
        // "ui-rounded" font-family — this is still the system font, not
        // OnboardingTheme's Quicksand/Baloo 2. ".kerning(-2)" matches the
        // doc's own letter-spacing: -2px exactly. No fixation ticks here
        // — 4a/4b's markup doesn't have them (unlike the older side-rail
        // design this replaced), so they're gone rather than kept as a
        // leftover from a different layout.
        .font(.system(size: focalWordSize, weight: .medium, design: .rounded))
        .kerning(-2)
        // Scales around the default center anchor, so a long word visibly
        // shrinks back in toward the middle of the screen on both sides
        // at once — exactly where it needed room. Deliberately no
        // .animation(_:value:) here: at RSVP's own reading speeds (up to
        // 600 wpm — a new word every 100ms) an eased scale change on top
        // of an already-changing word just blurs, since there's no time
        // for it to actually resolve before the next word replaces it.
        // The scale itself still needs to be instant and correct every
        // tick — only the easing is gone, not the clamping this exists
        // for in the first place.
        .scaleEffect(focalWordScale)
    }
}

// MARK: - Small Reusable Controls & Shapes

/// A button-like control that fires `action` once immediately on press,
/// then keeps firing it repeatedly for as long as the press is held.
// Used by backButton/forwardButton and the WPM +/- steppers so a
// reader can hold one down instead of tapping it over and over.
// Deliberately NOT a plain Button with an added hold gesture: a
// Button's own tap-completion and a second, simultaneous press gesture
// both watching the same touch would each fire their own action() for
// one ordinary tap, double-counting it. Driving everything (the single
// immediate fire AND the hold-repeat) off the one pressing-state
// callback avoids that.
private struct RepeatableControl<Label: View>: View {
    let accessibilityLabel: String
    let isEnabled: Bool
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    @State private var repeatTimer: Timer?

    // How long a press has to be held before it starts auto-repeating
    // (comfortably longer than any ordinary tap's press duration, so a
    // normal tap only ever fires action() the one time), and how fast
    // it repeats once it does.
    private static var initialDelay: TimeInterval { 0.45 }
    private static var repeatInterval: TimeInterval { 0.12 }

    var body: some View {
        label()
            .contentShape(Rectangle())
            // minimumDuration near-zero (not literally 0 — that value
            // has historically been unreliable) so "pressing" reflects
            // real finger-down/finger-up, not a genuine long-press
            // recognition delay; maximumDistance generous so ordinary
            // hand tremor during a hold doesn't cancel it the way the
            // default (10pt) would.
            .onLongPressGesture(minimumDuration: 0.01, maximumDistance: 50, pressing: { isPressing in
                guard isEnabled else { return }
                if isPressing {
                    startRepeating()
                } else {
                    stopRepeating()
                }
            }, perform: {})
            .accessibilityElement()
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityAction {
                if isEnabled {
                    action()
                }
            }
            // Guards against a hold that's still repeating the instant
            // isEnabled flips to false mid-press (e.g. isPlaying
            // becoming true while backButton is held) — without this,
            // the repeat timer would keep firing an action its own
            // control no longer permits.
            .onChange(of: isEnabled) { _, stillEnabled in
                if !stillEnabled {
                    stopRepeating()
                }
            }
    }

    private func startRepeating() {
        guard repeatTimer == nil else { return }
        action()
        repeatTimer = Timer.scheduledTimer(withTimeInterval: Self.initialDelay, repeats: false) { _ in
            repeatTimer = Timer.scheduledTimer(withTimeInterval: Self.repeatInterval, repeats: true) { _ in
                action()
            }
        }
    }

    private func stopRepeating() {
        repeatTimer?.invalidate()
        repeatTimer = nil
    }
}

/// A "<"/">" chevron built from two straight strokes, not SF Symbol's
/// "chevron.left"/".right".
// So the exact stroke width, cap, and join can be
// controlled directly — this screen's whole icon language is rounded caps
// + rounded joins throughout, which a system glyph doesn't guarantee.
// Traces the design doc's own SVG path proportions exactly (in a 24×24
// box: M15 6l-6 6 6 6 for left, M9 6l6 6-6 6 for right — a compact "V"
// occupying the middle half of the box, not a full edge-to-edge chevron).
private struct ChevronShape: Shape {
    let pointsLeft: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let nearX = rect.minX + rect.width * (9.0 / 24.0)
        let farX = rect.minX + rect.width * (15.0 / 24.0)
        let tipX = pointsLeft ? nearX : farX
        let baseX = pointsLeft ? farX : nearX
        let topY = rect.minY + rect.height * (6.0 / 24.0)
        let bottomY = rect.minY + rect.height * (18.0 / 24.0)
        path.move(to: CGPoint(x: baseX, y: topY))
        path.addLine(to: CGPoint(x: tipX, y: rect.midY))
        path.addLine(to: CGPoint(x: baseX, y: bottomY))
        return path
    }
}

/// A close "X" drawn as two independent crossing strokes, not one
/// four-point zigzag.
// So each one gets its own two rounded caps, the same
// way a real "X" glyph reads — a single continuous zigzag path would only
// round the two OUTER ends, leaving a sharp mitered corner in the middle
// where the strokes cross. Traces the reference's own SVG path exactly:
// "M6 6l12 12M18 6L6 18" in a 24×24 box — the X is inset to the box's
// middle half (6 to 18 out of 24 on each axis), not drawn full-bleed
// corner-to-corner.
private struct CloseXShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let near = 6.0 / 24.0
        let far = 18.0 / 24.0
        let x1 = rect.minX + rect.width * near
        let x2 = rect.minX + rect.width * far
        let y1 = rect.minY + rect.height * near
        let y2 = rect.minY + rect.height * far
        path.move(to: CGPoint(x: x1, y: y1))
        path.addLine(to: CGPoint(x: x2, y: y2))
        path.move(to: CGPoint(x: x2, y: y1))
        path.addLine(to: CGPoint(x: x1, y: y2))
        return path
    }
}

/// The rail's own Play glyph: a plain, symmetric triangle.
// Points at (8,6), (8,18), (18,12) in a 24×24 box, same as the design
// doc's own SVG path exactly (M8 6L8 18L18 12Z). Deliberately NOT a
// hand-tuned "rounded"
// bezier shape and NOT manually re-centered — this shape stays perfectly
// sharp-cornered and symmetric; playPauseTile above rounds its corners by
// filling AND stroking it with the same thick, round-joined line, which
// also keeps it correctly centered on its own with no offset needed.
private struct PlayTriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let left = rect.minX + rect.width * (8.0 / 24.0)
        let right = rect.minX + rect.width * (18.0 / 24.0)
        let top = rect.minY + rect.height * (6.0 / 24.0)
        let bottom = rect.minY + rect.height * (18.0 / 24.0)
        path.move(to: CGPoint(x: left, y: top))
        path.addLine(to: CGPoint(x: left, y: bottom))
        path.addLine(to: CGPoint(x: right, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Content Detail & Data Model

/// Shown inside the modal sheet for whichever catalog item was tapped —
/// title, description, and an "accept" action that hands off to ReadView.
struct ReadableContentDetailView: View {
    let content: ReadableContent // fixed for this view's lifetime

    // "() -> Void" is a closure type: a function taking no arguments, returning
    // nothing. The caller (ChooseView) decides what this actually does.
    let onAccept: () -> Void

    // @Environment reads a value the system provides; \.dismiss closes this sheet.
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Spacing.medium) {
            ScrollView { // lets long passages scroll
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    // No navigationTitle/toolbar here — OnboardingTheme
                    // screens build their own title and their own bottom
                    // buttons rather than relying on a nav bar, so the
                    // title is just the first thing inside the scroll
                    // content instead.
                    Text(content.title)
                        .font(OnboardingFont.display(28))
                        .foregroundStyle(Color.onboardingText)
                    Text(content.description)
                        .font(OnboardingFont.body(16, weight: .semiBold))
                        .foregroundStyle(Color.onboardingTextSecondary)
                    Text(content.text)
                        .font(OnboardingFont.body(17, weight: .medium))
                        .foregroundStyle(Color.onboardingText)
                        // A little extra breathing room between lines makes a
                        // full passage of body text noticeably easier to track
                        // line-to-line than the system default spacing.
                        .lineSpacing(6)
                }
                .padding(.top, Spacing.large)
            }

            HStack(spacing: Spacing.medium) {
                Button(action: {
                    dismiss()
                }, label: {
                    Text("Done")
                })
                .buttonStyle(OnboardingSecondaryButtonStyle())

                Button(action: {
                    onAccept() // tell ChooseView to move to the orient screen
                    dismiss() // then close this sheet
                }, label: {
                    Text("Accept")
                })
                .buttonStyle(OnboardingPrimaryButtonStyle())
            }
        }
        .padding(.horizontal, Spacing.large)
        .padding(.bottom, Spacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.onboardingBackground.ignoresSafeArea())
    }
}

/// Which of the two catalog sections a piece of content belongs to (see
/// ChooseView): .library is admin-curated and shared across every reader
/// whose library enabled it; .saved is one reader's own shared/read
/// articles, visible only to them.
// Nothing about ReadableContent itself
// changes behavior based on this beyond ChooseView's own sectioning; it
// exists so a single flat fetch-and-display path doesn't have to guess
// which list a given item belongs in from context.
enum ReadableContentSource {
    case library
    case saved
}

/// A single piece of reading material — either from the shared library
/// catalog or one reader's own saved content (see ReadableContentSource).
// Identifiable requires an "id" so List/ForEach/.sheet(item:) can tell rows
// apart. For catalog content, id is the Firestore document ID (see
// AuthService.fetchCatalog) — that content lives in Firestore, imported
// once via scripts/import-catalog.js, not shipped as static data in the
// app. Saved content (see AuthService.saveContent) uses a fresh UUID at
// save time, kept stable from then on (not re-synthesized on every fetch)
// so re-opening the same saved item twice doesn't create two SwiftUI
// identities for what's really one row.
struct ReadableContent: Identifiable {
    let id: String
    let title: String
    let description: String
    let text: String
    let source: ReadableContentSource

    // The original shared URL, for .saved content only (nil for
    // .library items, which have no such thing) — AuthService.
    // findSavedContent(bySourceURL:) matches on this so sharing the same
    // article twice reopens the existing saved copy instead of creating
    // a duplicate.
    let sourceURL: String?
}

// MARK: - Preview Support

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
