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
    description: "A short passage on ocean exploration.",
    text: "Beneath the sunlit surface of the ocean lies a world almost entirely unmapped. Sunlight fades within the first few hundred feet, and by a thousand feet the water is in permanent darkness. Yet life thrives there in strange forms: fish with built-in headlights, creatures that survive crushing pressure, and entire ecosystems powered not by the sun but by heat rising from cracks in the seafloor. Scientists estimate we have explored less than a quarter of the ocean floor, meaning most of our own planet remains less familiar to us than the surface of the moon.",
  },
  {
    title: "The Last Train",
    description: "A short fiction excerpt.",
    text: "Mara ran the last stretch across the platform, her bag bouncing against her hip, just as the doors began their slow, mechanical slide shut. She wedged her arm through the gap, more out of instinct than plan, and the train's sensors reversed just long enough to let her stumble inside. The car was nearly empty. An old man in the corner glanced up from his newspaper, unbothered, as if breathless last-second arrivals were simply part of the evening schedule. Mara caught her breath and found a seat, watching the platform lights blur into streaks as the train pulled away.",
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
