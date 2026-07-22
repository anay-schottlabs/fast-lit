import SwiftUI // brings in Apple's UI framework

// enum = a fixed set of named cases; used here as a simple "which page" switch.
enum Page {
    case home
    case choose
    case orient
    case read
    case account
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
    // being swapped out for OrientView and then ReadView.
    @State private var contentToRead: ReadableContent? = nil

    // Computed property SwiftUI calls whenever it needs to redraw the screen.
    // "some View" = "returns some type conforming to View, exact type not spelled out."
    var body: some View {
        // We manually swap "pages" by comparing the enum with "==". Each branch
        // hands the $currentPage binding down so that page can change it.
        if currentPage == .home {
            HomeView(currentPage: $currentPage)
        } else if currentPage == .choose {
            ChooseView(currentPage: $currentPage, contentToRead: $contentToRead)
        } else if currentPage == .orient {
            OrientView(currentPage: $currentPage)
        } else if currentPage == .account {
            AccountView(currentPage: $currentPage)
        } else if currentPage == .read {
            // "if let" only unwraps and shows ReadView once contentToRead is
            // actually set, which it always is by the time we reach this page.
            if let contentToRead {
                ReadView(content: contentToRead, currentPage: $currentPage)
            }
        }
    }
}

// The first screen shown when the app launches.
struct HomeView: View {
    // @Binding links to a @State var owned by a parent view (ContentView's
    // currentPage), so changing it here updates the parent's value too.
    @Binding var currentPage: Page

    var body: some View {
        VStack {
            Text("Welcome to Fast Lit.")
                .font(.system(size: 30))
                .bold()
                .padding()

            Text("You're on the accessible version, made to make reading easy for everyone.")
                .multilineTextAlignment(.center)
                .padding()

            // No more direct route to ChooseView from here — reading now
            // requires logging in first, via the button below.
            Button(action: {
                currentPage = .account
            }, label: {
                Text("Log In / Sign Up")
            })
            .buttonStyle(.glassProminent)
        }
        .padding()
    }
}

// Lets the user choose which kind of account to log into or sign up for,
// then shows that account type's form.
struct AccountView: View {
    @Binding var currentPage: Page

    // nil until an account type is picked below; once set, its form replaces
    // the picker. This sub-choice doesn't need to survive anywhere outside
    // this screen, so — unlike currentPage — it doesn't need to live any
    // higher up than right here.
    @State private var accountType: AccountType? = nil

    var body: some View {
        if accountType == .library {
            LibraryAccountView(accountType: $accountType)
        } else if accountType == .reader {
            ReaderAccountView(accountType: $accountType)
        } else {
            VStack {
                Text("Log In / Sign Up")
                    .font(.system(size: 30))
                    .bold()
                    .padding()

                Text("What kind of account do you have?")
                    .padding()

                Button(action: {
                    accountType = .library
                }, label: {
                    Text("Library")
                })
                .buttonStyle(.glassProminent)

                Button(action: {
                    accountType = .reader
                }, label: {
                    Text("Reader")
                })
                .buttonStyle(.glassProminent)

                Button(action: {
                    currentPage = .home
                }, label: {
                    Text("Go Back")
                })
                .buttonStyle(.glass)
            }
            .padding()
        }
    }
}

// Lets the user choose whether to log into an existing library account or
// sign up for a new one, then shows that specific form. Library accounts
// use a username and password either way.
struct LibraryAccountView: View {
    // @Binding (not "let") so "Go Back" below can clear it, returning to
    // AccountView's picker the same way it got here.
    @Binding var accountType: AccountType?

    // nil until the user picks log in or sign up below; once set, that
    // form replaces this picker.
    @State private var authMode: AuthMode? = nil

    var body: some View {
        if authMode == .login {
            LibraryLoginView(authMode: $authMode)
        } else if authMode == .signUp {
            LibrarySignUpView(authMode: $authMode)
        } else {
            VStack {
                Text("Library Account")
                    .font(.system(size: 24))
                    .bold()
                    .padding()

                Button(action: {
                    authMode = .login
                }, label: {
                    Text("Log In")
                })
                .buttonStyle(.glassProminent)

                Button(action: {
                    authMode = .signUp
                }, label: {
                    Text("Sign Up")
                })
                .buttonStyle(.glassProminent)

                Button(action: {
                    accountType = nil
                }, label: {
                    Text("Go Back")
                })
                .buttonStyle(.glass)
            }
            .padding()
        }
    }
}

// Logging into an existing library account. Doesn't do anything yet when
// "Log In" is tapped — just the empty fields for now.
struct LibraryLoginView: View {
    // @Binding so "Go Back" can clear it, returning to LibraryAccountView's
    // log in/sign up picker.
    @Binding var authMode: AuthMode?

    @State private var username: String = ""
    @State private var password: String = ""

    var body: some View {
        VStack {
            Text("Library Log In")
                .font(.system(size: 24))
                .bold()
                .padding()

            TextField("Username", text: $username)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            // SecureField (not TextField) hides what's typed, the way
            // password fields normally work.
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            Button(action: {}, label: {
                Text("Log In")
            })
            .buttonStyle(.glassProminent)
            .padding(.top)

            Button(action: {
                authMode = nil
            }, label: {
                Text("Go Back")
            })
            .buttonStyle(.glass)
        }
        .padding()
    }
}

// Signing up for a new library account. Same fields as LibraryLoginView,
// plus a name, since sign up (unlike log in) is creating a new person's
// account rather than authenticating one that already exists. "Sign Up"
// doesn't do anything yet, same as everywhere else in this flow.
struct LibrarySignUpView: View {
    @Binding var authMode: AuthMode?

    // Which step of the wizard is showing: 0 = library name, 1 = username,
    // 2 = password + confirm password. A plain Int (rather than an enum)
    // since it's only ever used as "current step" / "step + 1", and this
    // view is the only place that needs it.
    @State private var step: Int = 0

    // "Library" is just a fun way to describe an organization account, so
    // this step asks for the organization's name, not a person's name —
    // unlike ReaderSignUpView, which asks "What should we call you?".
    @State private var libraryName: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""

    var body: some View {
        VStack {
            Text("Library Sign Up")
                .font(.system(size: 24))
                .bold()
                .padding()

            Text("Step \(step + 1) of 3")
                .foregroundStyle(.secondary)
                .padding(.bottom)

            if step == 0 {
                TextField("What's your library called?", text: $libraryName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
            } else if step == 1 {
                TextField("Choose a username", text: $username)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
            } else {
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
            }

            // On the last step this is the actual (still non-functional)
            // "Sign Up" submit; on earlier steps it just moves forward.
            Button(action: {
                if step < 2 {
                    step += 1
                }
            }, label: {
                Text(step < 2 ? "Next" : "Sign Up")
            })
            .buttonStyle(.glassProminent)
            .padding(.top)

            // On the first step, "Go Back" leaves the wizard entirely, back
            // to the log in/sign up picker; on later steps it just moves
            // back one step instead.
            Button(action: {
                if step > 0 {
                    step -= 1
                } else {
                    authMode = nil
                }
            }, label: {
                Text("Go Back")
            })
            .buttonStyle(.glass)
        }
        .padding()
    }
}

// Lets the user choose whether to log into an existing reader account or
// sign up for a new one, then shows that specific form. Reader accounts
// use a six-digit code either way, instead of a username/password.
struct ReaderAccountView: View {
    @Binding var accountType: AccountType?

    @State private var authMode: AuthMode? = nil

    var body: some View {
        if authMode == .login {
            ReaderLoginView(authMode: $authMode)
        } else if authMode == .signUp {
            ReaderSignUpView(authMode: $authMode)
        } else {
            VStack {
                Text("Reader Account")
                    .font(.system(size: 24))
                    .bold()
                    .padding()

                Button(action: {
                    authMode = .login
                }, label: {
                    Text("Log In")
                })
                .buttonStyle(.glassProminent)

                Button(action: {
                    authMode = .signUp
                }, label: {
                    Text("Sign Up")
                })
                .buttonStyle(.glassProminent)

                Button(action: {
                    accountType = nil
                }, label: {
                    Text("Go Back")
                })
                .buttonStyle(.glass)
            }
            .padding()
        }
    }
}

// Logging into an existing reader account. Doesn't do anything yet when
// "Log In" is tapped — just the empty field for now.
struct ReaderLoginView: View {
    @Binding var authMode: AuthMode?

    @State private var code: String = ""

    var body: some View {
        VStack {
            Text("Reader Log In")
                .font(.system(size: 24))
                .bold()
                .padding()

            // .numberPad brings up a digit-only keyboard, since the code is
            // always six digits.
            TextField("6-digit code", text: $code)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: {}, label: {
                Text("Log In")
            })
            .buttonStyle(.glassProminent)
            .padding(.top)

            Button(action: {
                authMode = nil
            }, label: {
                Text("Go Back")
            })
            .buttonStyle(.glass)
        }
        .padding()
    }
}

// Signing up for a new reader account, one step at a time: the reader's
// name, then their library/org code (the same six-digit code
// ReaderLoginView uses). "Sign Up" still doesn't do anything yet.
struct ReaderSignUpView: View {
    @Binding var authMode: AuthMode?

    // Which step is showing: 0 = name, 1 = library/org code. Only two steps
    // here (vs. LibrarySignUpView's three) since readers just need a name
    // and a code, not a username/password.
    @State private var step: Int = 0

    @State private var name: String = ""
    @State private var code: String = ""

    var body: some View {
        VStack {
            Text("Reader Sign Up")
                .font(.system(size: 24))
                .bold()
                .padding()

            Text("Step \(step + 1) of 2")
                .foregroundStyle(.secondary)
                .padding(.bottom)

            if step == 0 {
                TextField("What should we call you?", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
            } else {
                // .numberPad brings up a digit-only keyboard, since the
                // code is always six digits.
                TextField("Library/Org Code", text: $code)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // On the last step this is the actual (still non-functional)
            // "Sign Up" submit; on the first step it just moves forward.
            Button(action: {
                if step < 1 {
                    step += 1
                }
            }, label: {
                Text(step < 1 ? "Next" : "Sign Up")
            })
            .buttonStyle(.glassProminent)
            .padding(.top)

            // On the first step, "Go Back" leaves the wizard entirely, back
            // to the log in/sign up picker; on the second step it just
            // moves back to the first step instead.
            Button(action: {
                if step > 0 {
                    step -= 1
                } else {
                    authMode = nil
                }
            }, label: {
                Text("Go Back")
            })
            .buttonStyle(.glass)
        }
        .padding()
    }
}

// The screen listing sample content to pick from.
struct ChooseView: View {
    @Binding var currentPage: Page

    // The content the user accepted, reported back up to ContentView so it can
    // hand it to ReadView once we get there.
    @Binding var contentToRead: ReadableContent?

    // Holds whichever row was tapped, so the .sheet below knows what to show.
    @State private var selectedContent: ReadableContent? = nil

    var body: some View {
        VStack {
            List {
                // ForEach loops over ReadableContent.samples, needing Identifiable
                // (in ReadableContent) to track each row. "item" avoids clashing
                // with the Text view type.
                ForEach(ReadableContent.samples) { item in
                    Button(action: {
                        selectedContent = item // triggers the .sheet below
                    }, label: {
                        Text(item.title)
                    })
                }
            }
            // .sheet(item:) shows a modal whenever the bound value is non-nil,
            // passing the unwrapped value in. "$" turns @State into a two-way Binding.
            .sheet(item: $selectedContent) { item in
                // NavigationStack lets .navigationTitle/.toolbar inside the detail
                // view work.
                NavigationStack {
                    // onAccept is a closure we pass in; the detail view calls it
                    // without knowing what it does here on our side.
                    ReadableContentDetailView(content: item, onAccept: {
                        contentToRead = item // remember what to read...
                        currentPage = .orient // ...then move on to orienting
                    })
                }
            }

            Button(action: {
                currentPage = .home
            }, label: {
                Text("Go Back")
            })
            .buttonStyle(.glassProminent)
        }
        .padding()
    }
}

// Intermediary screen: makes sure the device is in landscape before reading.
struct OrientView: View {
    @Binding var currentPage: Page

    var body: some View {
        VStack {
            // GeometryReader hands us this view's actual current size, which is
            // correct immediately (even on first appearance) and updates the
            // instant the view is redrawn after a rotation. This sidesteps
            // UIDevice.current.orientation, whose sensor reading can be stale
            // or .unknown right when a screen first appears.
            GeometryReader { geometry in
                Text("You're in portrait mode, rotate your device into landscape.")
                    // width > height means landscape; check as soon as we appear...
                    .onAppear {
                        if geometry.size.width > geometry.size.height {
                            currentPage = .read
                        }
                    }
                    // ...and again every time the size changes (i.e. every rotation).
                    .onChange(of: geometry.size) { _, newSize in
                        if newSize.width > newSize.height {
                            currentPage = .read
                        }
                    }
            }

            Button(action: {
                currentPage = .choose
            }, label: {
                Text("Go Back")
            })
            .buttonStyle(.glassProminent)
        }
        .padding()
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

    var body: some View {
        VStack {
            // "indexNum + 1" (not indexNum) so the bar reads as "words shown
            // so far out of the total" — it starts at a sliver of progress
            // on the very first word, rather than at empty.
            ProgressView(value: Double(indexNum + 1), total: Double(words.count))
                .padding(.horizontal)

            // Rather than one Text centered as a block (which would put the
            // blue letter in a different screen position for every word,
            // depending on how many letters come before/after it), "before"
            // and "after" each get a flexible container of equal width via
            // .frame(maxWidth: .infinity) and pull their text toward the
            // middle with alignment. Since both containers always claim the
            // same share of the remaining space, "center" (a fixed size, so
            // it's never squeezed) ends up fixed at screen-center every time.
            HStack(spacing: 0) {
                Text(wordParts.before)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text(wordParts.center)
                    .foregroundColor(.blue)
                    .fixedSize()
                Text(wordParts.after)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            // Large and bold, since this word is the whole point of the
            // screen — everything else (progress bar, controls) is
            // secondary to it. Applied to the HStack (rather than each Text)
            // since font is an environment value that flows down to all three.
            .font(.system(size: 60, weight: .bold))

            // Side-by-side left/right buttons to step through words one at a time.
            HStack {
                Button(action: {
                    updateIndex(increment: -1)
                }, label: {
                    Image(systemName: "arrow.left")
                })
                .buttonStyle(.glassProminent)
                // Manually stepping while the timer is also advancing indexNum
                // would fight with playback, so stepping is disabled while playing.
                .disabled(isPlaying)

                // Same button throughout — only its icon and action change
                // depending on isPlaying, rather than showing two buttons and
                // hiding whichever one doesn't apply.
                Button(action: {
                    if isPlaying {
                        pause()
                    } else {
                        play()
                    }
                }, label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                })
                .buttonStyle(.glassProminent)

                Button(action: {
                    updateIndex(increment: 1)
                }, label: {
                    Image(systemName: "arrow.right")
                })
                .buttonStyle(.glassProminent)
                .disabled(isPlaying)

                // Unlike the step buttons, stays enabled while playing — it
                // needs to be able to interrupt playback, not just adjust
                // position within it.
                Button(action: {
                    stop()
                }, label: {
                    Image(systemName: "stop.fill")
                })
                .buttonStyle(.glassProminent)
            }

            Text("\(wpm) wpm")

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
            .buttonStyle(.glass)
        }
        .padding()
        // Stops any running timer if this view goes away while playing, so
        // it doesn't keep firing pointlessly in the background.
        .onDisappear {
            pause()
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
            VStack(alignment: .leading, spacing: 16) {
                Text(content.description)
                    .foregroundStyle(.secondary)
                Text(content.text)
            }
            .padding()
        }
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
            }
            // .confirmationAction is the standard "confirm/accept" spot (right side).
            ToolbarItem(placement: .confirmationAction) {
                Button(action: {
                    onAccept() // tell ChooseView to move to the orient screen
                    dismiss() // then close this sheet
                }, label: {
                    Text("Accept")
                })
            }
        }
    }
}

// Identifiable requires an "id" so List/ForEach/.sheet(item:) can tell rows apart.
struct ReadableContent: Identifiable {
    let id = UUID() // random unique value, fixed per instance
    let title: String
    let description: String
    let text: String

    // Sample content the app ships with. Lives here (as a static, rather
    // than a local var on ChooseView) so other views — like HomeView's dev
    // "skip to read" button — can reach the same list without duplicating it.
    static let samples: [ReadableContent] = [
        ReadableContent(
            title: "Welcome to Fast Lit",
            description: "A quick intro to reading with RSVP.",
            text: "Fast Lit shows one word at a time so your eyes stay still while your brain does the work. Each word is centered on a red focal letter, cutting down on the back-and-forth eye movement that slows most readers down. Start slow, get comfortable with the rhythm, and increase your speed as it starts to feel natural."
        ),
        ReadableContent(
            title: "The Deep Sea",
            description: "A short passage on ocean exploration.",
            text: "Beneath the sunlit surface of the ocean lies a world almost entirely unmapped. Sunlight fades within the first few hundred feet, and by a thousand feet the water is in permanent darkness. Yet life thrives there in strange forms: fish with built-in headlights, creatures that survive crushing pressure, and entire ecosystems powered not by the sun but by heat rising from cracks in the seafloor. Scientists estimate we have explored less than a quarter of the ocean floor, meaning most of our own planet remains less familiar to us than the surface of the moon."
        ),
        ReadableContent(
            title: "The Last Train",
            description: "A short fiction excerpt.",
            text: "Mara ran the last stretch across the platform, her bag bouncing against her hip, just as the doors began their slow, mechanical slide shut. She wedged her arm through the gap, more out of instinct than plan, and the train's sensors reversed just long enough to let her stumble inside. The car was nearly empty. An old man in the corner glanced up from his newspaper, unbothered, as if breathless last-second arrivals were simply part of the evening schedule. Mara caught her breath and found a seat, watching the platform lights blur into streaks as the train pulled away."
        ),
        ReadableContent(
            title: "How the Printing Press Changed the World",
            description: "A brief look at a turning point in history.",
            text: "Before the 1450s, books were copied by hand, one page at a time, which made them rare and expensive. When Johannes Gutenberg introduced the movable-type printing press in Mainz, Germany, a single press could produce hundreds of copies of a book in the time it once took to copy a single page by hand. Literacy spread, ideas traveled faster than armies, and within decades printed material was reshaping science, religion, and politics across Europe. Few inventions have changed the flow of human knowledge as quickly or as permanently."
        ),
        ReadableContent(
            title: "Small Steps, Real Progress",
            description: "A short motivational passage.",
            text: "Most meaningful progress doesn't arrive as a single breakthrough. It arrives as a string of small, unremarkable steps taken consistently over time, long after the initial motivation has faded. The people who improve the most aren't necessarily the most talented; they're the ones who kept showing up on the ordinary days, when nothing exciting was happening and no one was watching. Trust the process, focus on today's step instead of the whole staircase, and let the results accumulate quietly in the background."
        )
    ]
}

// #Preview drives Xcode's live canvas preview.
#Preview {
    ContentView()
}
