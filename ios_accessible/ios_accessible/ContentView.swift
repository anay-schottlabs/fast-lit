import SwiftUI

struct ContentView: View {
    
    // an enum to manage each of the pages on the app
    enum Page {
        case home
        case choose
        case orientScreen
        case read
    }
    
    // save the current page in a state var
    @State private var currentPage: Page = .home

    // the content tapped in the list, shown in a modal when non-nil
    @State private var selectedContent: ReadableContent? = nil
    
    // different content to choose from
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
    
    var body: some View {
        VStack {
            
            // home page

            if currentPage == Page.home {
                // title
                Text("Welcome to Fast Lit.")
                    .font(.system(size: 30))
                    .bold()
                    .padding()
                
                // subtitle
                Text("You're on the accessible version, made to make reading easy for everyone.")
                    .multilineTextAlignment(.center)
                    .padding()
                
                // action button to move to next page
                Button("Start Reading") {
                    currentPage = .choose
                }
                .buttonStyle(.glassProminent)
            }
            
            // page to choose something to read
            
            else if currentPage == Page.choose {
                List {
                    ForEach(content) { text in
                        Button(text.title) {
                            selectedContent = text
                        }
                    }
                }
                .sheet(item: $selectedContent) { text in
                    NavigationStack {
                        ReadableContentDetailView(content: text)
                    }
                }

                Button("Go Back") {
                    currentPage = .home
                }
                .buttonStyle(.glassProminent)
            }
            
            // an intermediary page to make sure that the screen is in landscape
            // this makes sure that viewing is easy
            
            else if currentPage == Page.orientScreen {
            }
            
            // the page with the reader
            // that lets the user actually read the content they selected
            
            else if currentPage == Page.read {
            }
        }
        .padding()
    }
}

struct ReadableContentDetailView: View {
    let content: ReadableContent
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
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
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

struct ReadableContent: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let text: String
}

#Preview {
    ContentView()
}
