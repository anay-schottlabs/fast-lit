import SwiftUI // brings in Apple's UI framework

// "struct" = value type. ": View" means it must provide a "body" describing its UI.
struct ContentView: View {

    // enum = a fixed set of named cases; used here as a simple "which page" switch.
    enum Page {
        case home
        case choose
        case orient
        case read
    }

    // @State makes SwiftUI track this value and redraw when it changes.
    @State private var currentPage: Page = .home

    // Optional (the "?") means this can be a ReadableContent OR nil (nothing yet).
    // nil = no row tapped, so the modal below stays hidden.
    @State private var selectedContent: ReadableContent? = nil

    // Array literal of sample content, built via ReadableContent's initializer.
    var content: [ReadableContent] = [
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
    
    @State private var orientation = UIDevice.current.orientation

    // Computed property SwiftUI calls whenever it needs to redraw the screen.
    // "some View" = "returns some type conforming to View, exact type not spelled out."
    var body: some View {
        VStack { // stacks children vertically

            // We manually swap "pages" by comparing the enum with "==".
            if currentPage == Page.home {
                Text("Welcome to Fast Lit.")
                    .font(.system(size: 30)) // modifiers chain, each wrapping the last
                    .bold()
                    .padding()

                Text("You're on the accessible version, made to make reading easy for everyone.")
                    .multilineTextAlignment(.center)
                    .padding()

                // Button(action:label:) spells out both parts: what runs on tap,
                // and what view is drawn as the button.
                Button(action: {
                    currentPage = .choose
                }, label: {
                    Text("Start Reading")
                })
                .buttonStyle(.glassProminent)
            }

            else if currentPage == Page.choose {
                List {
                    // ForEach loops over content, needing Identifiable (below) to
                    // track each row. "item" avoids clashing with the Text view type.
                    ForEach(content) { item in
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
                    // NavigationStack lets .navigationTitle/.toolbar below work.
                    NavigationStack {
                        // onAccept is a closure we pass in; the detail view calls it
                        // without knowing what it does here on our side.
                        ReadableContentDetailView(content: item, onAccept: {
                            currentPage = .orient
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

            else if currentPage == Page.orient {
                Text("You're in portrait mode, rotate your device into landscape.")
                    // iOS doesn't track orientation changes by default (battery
                    // saving); this switches tracking on while this page is shown.
                    .onAppear {
                        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
                        orientation = UIDevice.current.orientation // check right away
                        if orientation.isLandscape {
                            currentPage = .read
                        }
                    }
                    .onDisappear {
                        UIDevice.current.endGeneratingDeviceOrientationNotifications()
                    }
                    // .onReceive runs every time this notification fires (unlike
                    // .onAppear, which only runs once), so rotating after arriving
                    // on this page is what actually gets caught here.
                    .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                        orientation = UIDevice.current.orientation
                        if orientation.isLandscape {
                            currentPage = .read
                        }
                    }
            }
            
            else if currentPage == Page.read {
            }
        }
        .padding()
    }
}

// Shown inside the modal sheet for whichever content was tapped.
struct ReadableContentDetailView: View {
    let content: ReadableContent // fixed for this view's lifetime

    // "() -> Void" is a closure type: a function taking no arguments, returning
    // nothing. The caller (ContentView) decides what this actually does.
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
                    onAccept() // tell ContentView to move to the orient screen
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
}

// #Preview drives Xcode's live canvas preview.
#Preview {
    ContentView()
}
