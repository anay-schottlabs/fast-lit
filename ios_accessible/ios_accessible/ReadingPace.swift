import Foundation

// Shared between ReadView (live RSVP playback pacing) and the catalog's
// list rows (estimated reading time, shown before a reader even opens a
// piece) — pulled out of ReadView specifically so there's exactly one
// definition of what a comma, a sentence end, or a paragraph break is
// "worth." Two separate copies of this logic would silently drift the
// moment either one's beat values got retuned, and the catalog's estimate
// would quietly stop matching what ReadView actually does.
enum ReadingPace {
    // MARK: - Tokenizing

    // A word plus whether the run of whitespace right after it in the
    // source text contained a newline (a paragraph break) rather than
    // just a single space — beats(forWordAt:in:) below reads that to
    // give line breaks their own, longer pause. A plain
    // `.split(whereSeparator: { $0.isWhitespace })` throws that
    // distinction away entirely, which is what used to let sentence-
    // ending punctuation from one paragraph sit right next to the first
    // word of the next with no beat between them.
    struct Tokenized {
        let words: [String]
        let hadLineBreakAfter: [Bool]
    }

    // Hand-rolled instead of `.split(whereSeparator:)` specifically to
    // keep the one thing that simpler call throws away: whether each gap
    // between words was a newline or just a space. Every whitespace
    // character still splits words exactly the same way
    // .split(whereSeparator: { $0.isWhitespace }) did — this only adds
    // bookkeeping on top of that, not different splitting behavior.
    static func tokenize(_ text: String) -> Tokenized {
        var words: [String] = []
        var hadLineBreakAfter: [Bool] = []
        var currentWord = ""
        var sawLineBreakSinceLastWord = false

        for character in text {
            if character.isWhitespace {
                if !currentWord.isEmpty {
                    words.append(currentWord)
                    hadLineBreakAfter.append(false)
                    currentWord = ""
                }
                if character.isNewline {
                    sawLineBreakSinceLastWord = true
                }
            } else {
                if sawLineBreakSinceLastWord, let lastIndex = hadLineBreakAfter.indices.last {
                    hadLineBreakAfter[lastIndex] = true
                }
                sawLineBreakSinceLastWord = false
                currentWord.append(character)
            }
        }
        if !currentWord.isEmpty {
            words.append(currentWord)
            hadLineBreakAfter.append(false)
        }
        return Tokenized(words: words, hadLineBreakAfter: hadLineBreakAfter)
    }

    // MARK: - Beats

    // Punctuation that earns a brief extra beat when it ends a word — the
    // reader takes a short breath here, but the sentence keeps going.
    // Deliberately NOT a plain ASCII hyphen "-": that shows up at the end
    // of a whitespace-split "word" too easily for unrelated reasons (a
    // hard-hyphenated compound word broken across a line, for instance),
    // where it wouldn't actually mean "pause here" the way an em/en dash
    // does.
    private static let shortPauseCharacters: Set<Character> = [",", ";", ":", "—", "–"]

    // Punctuation that ends a full sentence (or trails off, for an
    // ellipsis) — worth noticeably longer than a mid-sentence comma. "…"
    // is the single-character ellipsis glyph; a literal "..." needs no
    // separate entry here since its LAST character is still a plain "."
    // already in this set.
    private static let sentenceEndCharacters: Set<Character> = [".", "!", "?", "…", "‽"]

    // Closing quotes/brackets that can trail the REAL punctuation mark —
    // e.g. the closing " in `He said, "Stop."` — stripped off first (see
    // beats(forWordAt:in:) below) so the mark underneath still gets
    // recognized instead of being masked by whatever's wrapping it.
    // Covers straight and curly quotes, both common angle-quote
    // directions, and the three bracket styles, since any of them could
    // plausibly sit between the real mark and the end of the word.
    private static let trailingClosingCharacters: Set<Character> = [
        "\"", "'", "”", "’", "»", "«", "›", "‹", ")", "]", "}",
    ]

    // Bigger than sentenceEndBeats — a paragraph break is a bigger pause
    // for a reader's eyes than even a sentence ending mid-paragraph, so
    // it gets the longest hold of the four beat amounts, checked first
    // in beats(forWordAt:in:) below and taking priority over whatever
    // punctuation the word itself ends with.
    private static let lineBreakBeats: Double = 4.5
    private static let sentenceEndBeats: Double = 3.5
    private static let shortPauseBeats: Double = 2.0
    private static let ordinaryBeats: Double = 1.0

    // How many "beats" (one beat = the current wpm's own word-to-word
    // interval) to hold on a given word before advancing past it —
    // reading punctuation off the word just shown, not the one about to
    // appear, mirrors how a reader's eyes actually pause AFTER a comma or
    // period, not before it. Strips any trailing closing quotes/brackets
    // first so punctuation like `."` (a period immediately before a
    // closing quote) is still recognized as sentence-ending, not masked
    // by the quote sitting on top of it.
    static func beats(forWordAt index: Int, in tokenized: Tokenized) -> Double {
        if tokenized.hadLineBreakAfter[index] {
            return lineBreakBeats
        }
        var characters = Array(tokenized.words[index])
        while let last = characters.last, trailingClosingCharacters.contains(last) {
            characters.removeLast()
        }
        guard let last = characters.last else { return ordinaryBeats }
        if sentenceEndCharacters.contains(last) {
            return sentenceEndBeats
        }
        if shortPauseCharacters.contains(last) {
            return shortPauseBeats
        }
        return ordinaryBeats
    }

    // MARK: - Whole-passage estimates

    // Word count plus the summed beats across every word-to-word gap in
    // the whole passage (count - 1 gaps for `count` words, matching
    // ReadView's own totalDurationLabel) — the two pieces a catalog row
    // needs to show "1,240 words · 6 min" without duplicating this
    // file's punctuation tables itself.
    static func wordCountAndTotalBeats(for text: String) -> (wordCount: Int, beats: Double) {
        let tokenized = tokenize(text)
        guard tokenized.words.count > 1 else { return (tokenized.words.count, 0) }
        let totalBeats = (0..<tokenized.words.count - 1).reduce(into: 0.0) { total, i in
            total += beats(forWordAt: i, in: tokenized)
        }
        return (tokenized.words.count, totalBeats)
    }

    // Estimated seconds to read the whole passage start to finish at a
    // given wpm — same math as ReadView's totalDurationLabel, just
    // exposed here so a catalog row can show it before ReadView (or its
    // own tokenizing) ever runs.
    static func estimatedSeconds(for text: String, wpm: Int) -> Int {
        let (_, totalBeats) = wordCountAndTotalBeats(for: text)
        return Int((totalBeats * 60.0 / Double(wpm)).rounded())
    }
}
