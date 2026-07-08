function text(stringList) {
    return stringList.join(" ");
}

export class HomeScripts {
    static heroBadge = "Rapid Serial Visual Presentation";
    static heroTitle = "Unlock your potential.";
    static heroContent = text([
        "Read faster, stay focused, and absorb more.",
        "Fast Lit uses RSVP and a focal point system to help you concentrate and cut out distractions.",
        "No ads—just a clean, efficient reading experience."
    ]);
    static heroButton = "Start Reading";

    // words cycled through by the live preview widget in the hero section
    static demoText = "Read at the speed of thought, and get through text faster than you ever have.";
    static demoWords = HomeScripts.demoText.split(" ");
    static demoWpm = 380;

    static steps = [
        {
            title: "Paste or Grab",
            description: "Paste any text, or use the Fast Lit Grabber browser extension to pull in an article from the web."
        },
        {
            title: "Set Your Pace",
            description: "Choose a comfortable words-per-minute speed, and adjust it on the fly with the arrow keys."
        },
        {
            title: "Read & Focus",
            description: "Follow the red focal point as words stream by, cutting out eye movement and distraction."
        }
    ];

    static ctaTitle = "Ready to read faster?";
    static ctaContent = "Jump in with the sample text, or paste your own in Settings.";
}

export class ReadScripts {
    static sampleText = text([
        "Welcome to Fast Lit.",
        "This application uses Rapid Serial Visual Presentation, or RSVP,",
        "to display words one at a time and help you focus on the content instead of moving your eyes across a page.",
        "Each word is centered around a red focal point letter,",
        "allowing your gaze to remain fixed while your peripheral vision processes the rest of the word.",
        "This reduces unnecessary eye movement and creates a smoother reading experience.",
    
        "To get started, press the play button and follow the words as they appear.",
        "If the speed feels too fast or too slow, open the Settings menu in the top-right corner",
        "to adjust your words per minute, paste your own text, import content using the Fast Lit Grabber extension,",
        "or view the available keyboard shortcuts.",
        "Press the spacebar to play or pause at any time.",
        "Press R to reset the reader to the beginning.",
        "While paused, use the left and right arrow keys to move backward or forward one word at a time.",
        "You can also use the up and down arrow keys while paused",
        "to adjust your reading speed without opening Settings.",
    
        "As you read, try to resist the urge to pronounce every word in your head.",
        "Many readers subconsciously speak each word as they read,",
        "which limits reading speed to roughly the pace of speech.",
        "Instead, focus on understanding the meaning of the words and phrases as they appear.",
        "The goal is not to rush through the text,",
        "but to allow your brain to absorb information more efficiently.",
        "You may also notice that traditional reading often involves jumping backward",
        "to reread words or lines.",
        "Fast Lit removes much of that temptation by presenting text in a steady stream,",
        "helping you maintain focus and momentum.",
    
        "Like any skill, speed reading improves with practice.",
        "When you first begin, it is completely normal to use a slower reading speed",
        "and gradually work your way up.",
        "Over time, your brain becomes more comfortable processing information",
        "without relying on constant eye movement or subvocalization.",
        "Many users find that the focused nature of RSVP reading",
        "not only increases their reading speed,",
        "but also strengthens their ability to concentrate for longer periods.",
        "Because the text continues moving forward,",
        "it is easier to stay engaged with the material",
        "instead of drifting into the passive habits that often occur during traditional reading.",
        "The consistent pace encourages active attention",
        "and helps train you to remain focused on the content in front of you.",
    
        "Fast Lit also includes the Fast Lit Grabber browser extension,",
        "which allows you to import articles directly from the web.",
        "Instead of copying and pasting text manually,",
        "simply open an article, activate the extension,",
        "and send the content directly into Fast Lit.",
        "The extension extracts the readable text from a page and loads it into the reader,",
        "making it easy to move from browsing to focused reading in just a few clicks.",
        "Whether you are reading news articles, blog posts, research papers,",
        "or online documentation,",
        "the Grabber helps eliminate distractions and keeps your workflow simple.",
    
        "This passage serves as a demonstration of the reader.",
        "Once you are comfortable with the controls,",
        "open Settings and replace this text with your own article, notes, assignment,",
        "or any other content you would like to read.",
        "Start at a comfortable speed, gradually increase your words per minute as you improve,",
        "and enjoy a distraction-free reading experience",
        "with no advertisements, subscriptions, or usage limits."
    ]);
}

export class FeedbackScripts {
    static formUrl =
        "https://docs.google.com/forms/d/e/1FAIpQLSdaEN4WwLu2AzdmdHN8mrzijrTXoN-K_JK5rBbj5dCeXVxqdA/viewform?usp=publish-editor";
    static heroTitle = "Tell Us What You Think";
    static heroContent = text([
        "Fast Lit is built to help people read faster and stay focused.",
        "If you've found a bug, have an idea for a new feature,",
        "or want to share your experience using the app, we'd love to hear from you.",
        "Every suggestion helps make Fast Lit better for everyone."
    ]);
    static heroButton = "Share Your Feedback";
    static categories = ["Bug Reports", "Feature Ideas", "General Thoughts"];
}

export class ChangelogScripts {
    static Entry = class {
        constructor(date, version, changes) {
            this.date = date;
            this.version = version;
            this.changes = changes;
        }
    };
    static changelog = [
        new this.Entry(
            "May 31, 2026",
            "1.0.0",
            [
                "Published Fast Lit to the internet."
            ]
        ),
        new this.Entry(
            "June 3, 2026",
            "1.1.0",
            [
                "Simplified usage for Fast Lit Grabber extension and removed grabber modal in settings."
            ]
        ),
        new this.Entry(
            "July 6, 2026",
            "1.2.0",
            [
                "Redesigned the Fast Lit Grabber extension popup with a clearer step-by-step layout and a grab progress indicator.",
                "Closing the settings modal now saves your changes instead of discarding them.",
                "Created a basic page for Fast Lit Write, with functionality for drawing characters on a grid. At the time of this release, this page is 'secret' and can't be navigated to from the sidebar like other pages."
            ]
        ),
        new this.Entry(
            "July 7, 2026",
            "1.3.0",
            [
                "Redesigned the changelog page for a more modern look.",
                "Rebuilt the home page with more info, an improved look, and a live demo of RSVP with some sample text to make the point of the site a little less mysterious.",
                "Capped the size of the write page's grid to work on both phone and laptop screens.",
                "Restyled the sidebar to match the rest of the app, with a highlight showing which page you're on.",
                "The up and down arrow keys can now change your reading speed while the reader is playing, not just while paused.",
                "Redesigned the feedback page to match the rest of the app, with a clearer card layout and categories for the kind of feedback you can share.",
                "Redesigned the read page's settings modal with card sections and a more prominent speed display, fixed the close button's hover feedback, and matched the Update button's width and corner rounding to the sections above it.",
                "Rounded corners are now consistent across every red and white button on the site, including the reader's playback controls.",
                "Gave the read page a fresh look: a framed reading stage with focal-point guide marks, a clearer speed display, and a bit of hover polish on the controls — kept free of the ambient glow used elsewhere so it stays distraction-free for reading.",
                "Fixed a tiny blank button showing up at the bottom of the collapsed sidebar.",
                "Fixed the sidebar's tooltips, which weren't showing any label when collapsed.",
                "Added shadows to cards that were missing them (home page stats, How It Works, and every changelog entry) for visual consistency.",
                "Improved color contrast on small red text and labels across the site for better readability.",
                "Home page stats now show a loading placeholder instead of a misleading zero while they load.",
                "Added visible keyboard focus outlines to the sidebar, playback controls, and other interactive elements that were missing them.",
                "The reader now shows a friendly message instead of a blank screen when there's no text to read.",
                "Fixed a rare crash when saving your reading stats if they hadn't finished loading yet.",
                "Restructured the settings modal's header and keyboard shortcuts list for cleaner alignment, and closing it with unsaved blank text no longer wipes out your current article.",
                "Gave the (currently hidden) write page the same card styling and layout as the rest of the site.",
                "Fixed the Start Reading and Share Your Feedback buttons rendering narrower than intended — a longstanding sizing bug across the site.",
                "Text you paste or send over from the Fast Lit Grabber extension, your reading speed, and your progress through the text are now all saved on your device, so you can pick up right where you left off the next time you open the read page.",
                "Fixed the play/pause and stop buttons rendering noticeably smaller than the previous/next word buttons next to them.",
                "Fixed a bug where reloading the read page with Ctrl+R or Cmd+R would reset your reading progress instead of restoring it, since that key combo was also triggering the reader's own \"press R to reset\" shortcut a moment before the reload."
            ]
        )
    ]
}
