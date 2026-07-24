// One-off import for the fast-lit-ios Firebase project: seeds the shared
// reading "catalog" collection with the content that used to live as
// ReadableContent.samples in the iOS app itself. Authenticates via
// Application Default Credentials (gcloud auth application-default login)
// rather than a service account key file, so no credential ever needs to
// be stored in this repo. Safe to re-run — each item's ID is a fixed slug
// of its title, so re-running just overwrites the same docs rather than
// duplicating them.
//
// Usage:
//   node import-catalog.js

const { initializeApp, applicationDefault } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp({
  credential: applicationDefault(),
  projectId: "fast-lit-ios",
});
const db = getFirestore();

const items = [
  {
    title: "Welcome to Fast Lit",
    description: "A quick intro to reading with RSVP.",
    text: "Fast Lit shows one word at a time so your eyes stay still while your brain does the work. Each word is centered on a red focal letter, cutting down on the back-and-forth eye movement that slows most readers down. Start slow, get comfortable with the rhythm, and increase your speed as it starts to feel natural.",
  },
  {
    title: "The Deep Sea",
    // Deliberately ~4x the length of this catalog's other short pieces —
    // one of a couple items kept long on purpose so ReadView/ChooseView
    // have something realistic to test against beyond a few dozen words.
    description: "A longer passage on ocean exploration, for testing with more text than this catalog's other short pieces.",
    text: "Beneath the sunlit surface of the ocean lies a world almost entirely unmapped. Sunlight fades within the first few hundred feet, and by a thousand feet the water is in permanent darkness. Yet life thrives there in strange forms: fish with built-in headlights, creatures that survive crushing pressure, and entire ecosystems powered not by the sun but by heat rising from cracks in the seafloor. Those cracks, known as hydrothermal vents, spew mineral-rich water heated by magma far below the crust, sometimes reaching temperatures over seven hundred degrees Fahrenheit. Around them cluster tube worms, blind shrimp, and bacteria that convert chemicals into energy instead of relying on sunlight, a process called chemosynthesis. When these vent ecosystems were first discovered in the late 1970s, they overturned a basic assumption biologists had held for centuries: that all life on Earth ultimately depends on the sun. Farther down, in the aptly named midnight zone, bioluminescence becomes the dominant language of the deep. More than three-quarters of the animals living below two thousand feet can produce their own light, using it to lure prey, startle predators, or find mates in a place where eyes are otherwise nearly useless. The anglerfish is the best-known example, dangling a glowing lure just above its enormous jaws, but countless smaller, stranger creatures do the same in ways researchers are still cataloguing. Pressure only compounds the challenge of studying this world. At the bottom of the Mariana Trench, nearly seven miles down, the pressure exceeds eight tons per square inch, roughly the weight of fifty jumbo jets pressing down on a single person. Submersibles built to survive that depth are engineered more like spacecraft than boats, with thick titanium hulls and instruments designed to function in near-freezing cold and absolute darkness. Despite decades of effort, scientists estimate we have explored less than a quarter of the ocean floor, meaning most of our own planet remains less familiar to us than the surface of the moon. Every expedition still turns up species never recorded before, and marine biologists suspect the vast majority of deep-sea life has yet to be discovered at all. As pressure grows to mine the seafloor for rare minerals, that gap between how much we've mapped and how much remains unknown has become more than academic curiosity; it's a race to understand an ecosystem before it's disturbed.",
  },
  {
    title: "The Last Train",
    // Also deliberately long (~3.5-4x the shorter pieces) — see "The Deep
    // Sea" above for why.
    description: "A longer fiction excerpt, for testing with more text than this catalog's other short pieces.",
    text: "Mara ran the last stretch across the platform, her bag bouncing against her hip, just as the doors began their slow, mechanical slide shut. She wedged her arm through the gap, more out of instinct than plan, and the train's sensors reversed just long enough to let her stumble inside. The car was nearly empty. An old man in the corner glanced up from his newspaper, unbothered, as if breathless last-second arrivals were simply part of the evening schedule. Mara caught her breath and found a seat, watching the platform lights blur into streaks as the train pulled away. Her reflection stared back at her in the dark window, tired and a little disheveled, and for a moment she let herself feel the full weight of the day she'd just had: the missed call, the argument in the hallway, the meeting that had run twenty minutes past when it needed to. Three stops passed in silence before the old man folded his newspaper and set it on the seat beside him. \"Rough one?\" he asked, not looking for details so much as offering an opening. Mara considered brushing the question off the way she usually did, but something about the empty car, the late hour, made it feel safe to answer honestly instead. \"Long,\" she said. \"Just long.\" He nodded like that was answer enough and didn't push further. Instead he told her, unprompted, about riding this same line home thirty years ago after his own long days, back when the seats were a different color and the announcements were still made by a person instead of a recording. There was no lesson in it, no tidy moral, just a stranger filling the space between stops with something other than silence, and somehow that was exactly what she needed. By the time the train reached her station, the tightness in her chest had loosened slightly, the way it sometimes does when a stranger treats you like a person instead of an inconvenience. She thanked him, and he waved it off with the same unbothered ease he'd had when she'd sprinted through those closing doors. Walking up the stairs into the cool night air, Mara found herself already looking forward to nothing in particular, just the ordinary relief of being home, and the quiet, unexpected comfort of the last train.",
  },
  {
    title: "How the Printing Press Changed the World",
    description: "A brief look at a turning point in history.",
    text: "Before the 1450s, books were copied by hand, one page at a time, which made them rare and expensive. When Johannes Gutenberg introduced the movable-type printing press in Mainz, Germany, a single press could produce hundreds of copies of a book in the time it once took to copy a single page by hand. Literacy spread, ideas traveled faster than armies, and within decades printed material was reshaping science, religion, and politics across Europe. Few inventions have changed the flow of human knowledge as quickly or as permanently.",
  },
  {
    title: "Small Steps, Real Progress",
    description: "A short motivational passage.",
    text: "Most meaningful progress doesn't arrive as a single breakthrough. It arrives as a string of small, unremarkable steps taken consistently over time, long after the initial motivation has faded. The people who improve the most aren't necessarily the most talented; they're the ones who kept showing up on the ordinary days, when nothing exciting was happening and no one was watching. Trust the process, focus on today's step instead of the whole staircase, and let the results accumulate quietly in the background.",
  },
];

function slugify(title) {
  return title
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-|-$)/g, "");
}

async function main() {
  for (const item of items) {
    const id = slugify(item.title);
    await db.collection("catalog").doc(id).set({
      title: item.title,
      description: item.description,
      text: item.text,
      createdAt: FieldValue.serverTimestamp(),
    });
    console.log(`Imported ${id}`);
  }
}

main().then(() => process.exit(0)).catch((error) => {
  console.error(error);
  process.exit(1);
});
