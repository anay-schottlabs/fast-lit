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

export class WriteScripts {
    static devCharInputPlaceholder = "What are you drawing?";
    static accordionHeaderClosed = "Show Data";
    static accordionHeaderOpen = "Hide Data";
    static downloadJsonButton = "Download JSON";
    static viewJsonButton = "View JSON";

    // shown in the show-data modal in place of the data list when nothing
    // has been saved yet
    static noDataTitle = "No Data Yet";
    static noDataDescription = "Collect a few characters to see them here.";
    static noDataSteps = [
        {
            title: "Label the Character",
            description: "Type the character you're drawing into the label field above, so it's saved under the right classification."
        },
        {
            title: "Draw It",
            description: "Use the grid on the left to draw a character, using the horizontal guide line as a reference for where it should sit."
        },
        {
            title: "Release to Save",
            description: "Releasing the mouse saves your drawing under that label and clears the grid for the next one."
        }
    ];
}

export class ExtensionScripts {
    static storeUrl = "https://chromewebstore.google.com/detail/fast-lit-grabber/kmlpobbeoknaajpbfpnogchfpifaobfl";
    static heroBadge = "Chrome Extension";
    static heroTitle = "Fast Lit Grabber";
    static heroContent = text([
        "Fast Lit Grabber pulls the readable text out of any article and sends it straight into Fast Lit —",
        "no copying, no pasting, no cleanup.",
        "Open an article, click the extension, and start reading at speed in seconds."
    ]);
    static installButton = "Add to Chrome — It's Free";

    static features = [
        {
            title: "One-Click Import",
            description: "Click the Fast Lit Grabber icon on any article and its content lands directly in Fast Lit's reader, ready to go."
        },
        {
            title: "Clean Article Extraction",
            description: "The extension strips out ads, navigation, comments, and other clutter, keeping only the actual article text."
        },
        {
            title: "Works Almost Anywhere",
            description: "News sites, blogs, documentation, research papers — if a page has a readable article, the Grabber can pull it."
        }
    ];

    static stepsTitle = "How It Works";
    static steps = [
        {
            title: "Install the Extension",
            description: "Add Fast Lit Grabber to Chrome from the Chrome Web Store. It takes a few seconds and doesn't require an account."
        },
        {
            title: "Open an Article",
            description: "Browse to any page with an article, blog post, or other readable content you'd like to read faster."
        },
        {
            title: "Click the Grabber Icon",
            description: "Click the Fast Lit Grabber icon in your browser toolbar to extract the page's readable text."
        },
        {
            title: "Read Instantly",
            description: "Fast Lit opens automatically with your text loaded and ready — press play and start reading at speed."
        }
    ];

    static faq = [
        {
            question: "Is Fast Lit Grabber free?",
            answer: "Yes. Fast Lit Grabber is completely free, with no account, subscription, or hidden costs."
        },
        {
            question: "What happens to the page content?",
            answer: "The extension only reads a page when you click its icon. The extracted text is sent to Fast Lit to display for reading — it isn't stored by the extension or shared with third parties."
        },
        {
            question: "What if a page won't grab cleanly?",
            answer: "Some pages (paywalled articles, apps disguised as websites, pages with little actual text) can't be reliably extracted. You can always paste text into Fast Lit directly instead."
        },
        {
            question: "Is it available for browsers other than Chrome?",
            answer: "Fast Lit Grabber currently supports Chrome and other Chromium-based browsers (like Edge and Brave) through the Chrome Web Store."
        }
    ];

    static privacyTitle = "Your Privacy Comes First";
    static privacyContent = text([
        "Fast Lit Grabber only reads a page's content when you explicitly click the extension icon — it never runs in the background,",
        "never tracks your browsing, and never collects personal information or login credentials."
    ]);
    static privacyLinkText = "Read the full Privacy Policy";
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

export class PrivacyScripts {
    static title = "Privacy Policy for Fast Lit Grabber";
    static lastUpdated = "Last Updated: July 2026";
    static intro = text([
        "Fast Lit Grabber is designed to help users quickly send article text from webpages to the Fast Lit reading application.",
        "We respect your privacy and are committed to collecting as little information as possible."
    ]);
    static sections = [
        {
            heading: "Information We Access",
            paragraphs: [
                "When you use the extension, Fast Lit Grabber temporarily accesses the content of the webpage you choose. This content is used solely to extract readable article text and send it to the Fast Lit web application so you can read it using Fast Lit's interface.",
                "The extension does not access webpage content unless you explicitly activate it."
            ]
        },
        {
            heading: "Information We Collect",
            paragraphs: ["Fast Lit Grabber does not collect or store:"],
            list: [
                "Personal information",
                "Names or email addresses",
                "Browsing history",
                "Login credentials",
                "Payment information",
                "Cookies",
                "Analytics about your browsing activity"
            ],
            after: ["The extension does not create user accounts."]
        },
        {
            heading: "How Website Content Is Used",
            paragraphs: [
                "Website content is processed only to perform the extension's core functionality.",
                "Specifically, webpage content is:"
            ],
            list: [
                "Read only when you activate the extension.",
                "Processed to extract readable text.",
                "Sent to the Fast Lit website so the text can be displayed for reading."
            ],
            after: ["Website content is not permanently stored by the extension and is not sold or shared with third parties for advertising or marketing purposes."]
        },
        {
            heading: "Data Stored by Fast Lit",
            paragraphs: [
                "The Fast Lit website may maintain anonymous aggregate statistics, such as the total number of words read across all users. These statistics do not identify individual users and are not linked to personal information."
            ]
        },
        {
            heading: "Third-Party Services",
            paragraphs: [
                "Fast Lit uses Google Firebase to store anonymous aggregate application statistics. No personally identifiable information is stored through Firebase."
            ]
        },
        {
            heading: "Data Sharing",
            paragraphs: [
                "We do not sell, rent, or share personal information with third parties."
            ]
        },
        {
            heading: "Security",
            paragraphs: [
                "Communication between the extension and the Fast Lit website occurs over encrypted HTTPS connections."
            ]
        },
        {
            heading: "Changes to This Policy",
            paragraphs: [
                "This Privacy Policy may be updated from time to time. Any changes will be reflected on this page with an updated effective date."
            ]
        }
    ];
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
                "Fixed a bug where reloading the read page with Ctrl+R or Cmd+R would reset your reading progress instead of restoring it, since that key combo was also triggering the reader's own \"press R to reset\" shortcut a moment before the reload.",
                "Words read by the home page's live preview now count toward the site's total words read stat, saved as you leave the page.",
                "Added a Privacy Policy page for the Fast Lit Grabber extension, styled to match the rest of the site with numbered section badges and a red accent."
            ]
        ),
        new this.Entry(
            "July 8, 2026",
            "1.4.0",
            [
                "The sidebar's active page indicator now uses the full brand red instead of a lighter, softer red.",
                "Fixed the (currently hidden) write page registering a new character any time you released the mouse anywhere on the page, instead of only when you actually drew on the grid.",
                "Restyled the (currently hidden) write page's Write/Learn/Developer tabs and developer tools (label input, buttons, data accordion) to match the rest of the site's dark theme, and split the layout into the drawing grid on the left with the active tab's panel on the right.",
                "Added basic syntax highlighting to the write page's two JSON code views, coloring keys, string values, and grid numbers to match the site's palette.",
                "Styled the write page's View JSON modal to match the rest of the site, with a bordered header, close icon, and a scrollable code panel.",
                "The View JSON modal now sizes itself to fit the full width of the JSON it's displaying instead of clipping long lines, and its code panel has more breathing room on the right to match the left.",
                "Replaced the write page's Show Data accordion with a modal, matching the View JSON modal's styling.",
                "Implemented the write page's grid view: each saved character now renders on its own mini canvas, showing the actual drawn shape and writing-line guide instead of a placeholder.",
                "Polished the Show Data modal: bigger grid-view canvases so it doesn't jump in size when switching modes, a proper walkthrough instead of a blank modal when no data has been saved yet, a segmented Grid/Code toggle matching the page's tabs, and red badge labels in place of the light kbd chips.",
                "Revamped the write page's code view syntax highlighting: commas are now plain white, and 1s and 0s in the grid data are colored differently from each other instead of sharing one color.",
                "Fixed the Show Data modal's label pill forcing every label to uppercase, and made it bigger and more prominent.",
                "Added the ability to delete individual saved characters from the Show Data modal, in both grid and code view.",
                "Fixed the Download JSON button not visually dimming when disabled, unlike the View JSON button next to it.",
                "Made the write page's character-label field the visual focus of the developer panel: a large bold input in its own red-tinted card, with a live count of how many characters are saved under the current label.",
                "Saved write page characters now persist in the browser via IndexedDB, so they survive a reload instead of being lost.",
                "The write page's developer panel now matches the drawing grid's height, filling the extra space with simple stats (total characters, labels, and the most common label) and a Clear All Data button.",
                "Fixed the write page's drawing grid changing size depending on which tab was active or how much data was saved — it's now a consistent size everywhere.",
                "Clear All Data on the write page now also clears the current label, not just the saved characters."
            ]
        ),
        new this.Entry(
            "July 9, 2026",
            "1.5.0",
            [
                "Redesigned the sidebar: nav buttons are now a consistent size and span the full sidebar width instead of shrinking to fit their label, the active page gets a red pill background instead of just red text, and the collapse toggle now has a working tooltip and a chevron that flips direction to show which way it'll collapse.",
                "The sidebar's version badge is now a proper card pinned to the bottom of the sidebar instead of a floating label, and expanding/collapsing the sidebar now animates smoothly instead of snapping instantly.",
                "Every sidebar button now shows a pointer cursor on hover, and the collapse toggle is noticeably smaller and dimmer than the main nav buttons so it reads as a secondary control instead of competing with Home/Read/Feedback/Changelog.",
                "Swapped the collapse toggle's icon for a simple centered chevron (the old panel-shaped icon was asymmetric and looked off-center) and moved it above the nav list with its own divider, so it reads as menu chrome instead of another item in the list.",
                "Fixed every collapsed sidebar icon sitting slightly left of center in its square hit target instead of being truly centered.",
                "The write page is no longer hidden — it now has its own Write entry in the sidebar, directly under Read.",
                "Replaced the home page's Books Finished stat with Words Written, tracking characters drawn on the write page and converting them to an approximate word count. Hours Saved now also credits the estimated 0.24 seconds saved per character written, on top of the existing reading-based estimate.",
                "The home page's live word preview no longer counts toward the site's Words Read stat.",
                "Redrew every sidebar icon from scratch as one cohesive set (Home, Read, Write, Feedback, Changelog) — same viewBox, stroke weight, and line style throughout, replacing the old Feedback icon, which was a mismatched filled illustration at a completely different scale from the rest.",
                "Thickened the new sidebar icons' strokes so they read as bold and clean instead of thin, matching the rest of the site's weight.",
                "Redesigned the sidebar icons again as bolder, wider, much simpler marks (2-3 strokes each) instead of detailed line drawings — a plain roofline house, three text lines for Read, a signature scribble for Write, a simplified thumbs-up, and a clock for Changelog.",
                "Replaced the home page's stat icons (previously an unrelated info-circle and archive box borrowed from a generic icon set) with marks that actually match what they measure: the same text-line and scribble marks as the sidebar's Read/Write icons, and a bolt for Hours Saved.",
                "Added an Extension page covering the Fast Lit Grabber Chrome extension in depth: what it does, how it works step by step, an FAQ, a link to the Chrome Web Store listing, and a privacy callout linking to the full Privacy Policy. It has its own entry in the sidebar, directly under Write.",
                "The sidebar is now a floating card (rounded corners, border, shadow) inset evenly from the top, bottom, and left edges instead of a flush-docked panel, matching the card styling used everywhere else on the site."
            ]
        )
    ]
}
