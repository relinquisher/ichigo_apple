import Foundation

enum PhraseExtractor {

    private static let irregularVerbs: [String: [String]] = [
        "tear": ["tore", "torn", "tearing"], "bear": ["bore", "borne", "born", "bearing"],
        "wear": ["wore", "worn", "wearing"], "swear": ["swore", "sworn", "swearing"],
        "break": ["broke", "broken", "breaking"], "speak": ["spoke", "spoken", "speaking"],
        "steal": ["stole", "stolen", "stealing"], "choose": ["chose", "chosen", "choosing"],
        "freeze": ["froze", "frozen", "freezing"], "drive": ["drove", "driven", "driving"],
        "write": ["wrote", "written", "writing"], "ride": ["rode", "ridden", "riding"],
        "rise": ["rose", "risen", "rising"], "give": ["gave", "given", "giving"],
        "take": ["took", "taken", "taking"], "shake": ["shook", "shaken", "shaking"],
        "make": ["made", "making"], "come": ["came", "coming"],
        "become": ["became", "becoming"], "get": ["got", "gotten", "getting"],
        "forget": ["forgot", "forgotten", "forgetting"], "begin": ["began", "begun", "beginning"],
        "run": ["ran", "running"], "swim": ["swam", "swum", "swimming"],
        "sing": ["sang", "sung", "singing"], "ring": ["rang", "rung", "ringing"],
        "drink": ["drank", "drunk", "drinking"], "sink": ["sank", "sunk", "sinking"],
        "blow": ["blew", "blown", "blowing"], "grow": ["grew", "grown", "growing"],
        "know": ["knew", "known", "knowing"], "throw": ["threw", "thrown", "throwing"],
        "draw": ["drew", "drawn", "drawing"], "fly": ["flew", "flown", "flying"],
        "show": ["showed", "shown", "showing"], "fall": ["fell", "fallen", "falling"],
        "hold": ["held", "holding"], "stand": ["stood", "standing"],
        "understand": ["understood", "understanding"], "find": ["found", "finding"],
        "bind": ["bound", "binding"], "wind": ["wound", "winding"],
        "lead": ["led", "leading"], "feed": ["fed", "feeding"],
        "keep": ["kept", "keeping"], "sleep": ["slept", "sleeping"],
        "feel": ["felt", "feeling"], "leave": ["left", "leaving"],
        "meet": ["met", "meeting"], "send": ["sent", "sending"],
        "spend": ["spent", "spending"], "build": ["built", "building"],
        "lend": ["lent", "lending"], "sell": ["sold", "selling"],
        "tell": ["told", "telling"], "bring": ["brought", "bringing"],
        "buy": ["bought", "buying"], "think": ["thought", "thinking"],
        "catch": ["caught", "catching"], "teach": ["taught", "teaching"],
        "seek": ["sought", "seeking"], "fight": ["fought", "fighting"],
        "lay": ["laid", "laying"], "pay": ["paid", "paying"],
        "say": ["said", "saying"], "do": ["did", "done", "doing"],
        "go": ["went", "gone", "going"], "see": ["saw", "seen", "seeing"],
        "be": ["was", "were", "been", "being"], "have": ["had", "having"],
        "set": ["setting"], "put": ["putting"], "cut": ["cutting"],
        "shut": ["shutting"], "hit": ["hitting"], "let": ["letting"],
        "sit": ["sat", "sitting"], "win": ["won", "winning"],
        "lose": ["lost", "losing"], "hide": ["hid", "hidden", "hiding"],
        "dig": ["dug", "digging"], "stick": ["stuck", "sticking"],
        "strike": ["struck", "stricken", "striking"], "hang": ["hung", "hanging"],
        "spin": ["spun", "spinning"], "cling": ["clung", "clinging"],
        "sting": ["stung", "stinging"], "swing": ["swung", "swinging"],
        "spring": ["sprang", "sprung", "springing"], "slide": ["slid", "sliding"],
        "grind": ["ground", "grinding"], "weave": ["wove", "woven", "weaving"],
        "strive": ["strove", "striven", "striving"], "lie": ["lay", "lain", "lying"],
        "wake": ["woke", "woken", "waking"], "eat": ["ate", "eaten", "eating"]
    ]

    // MARK: - Public API

    /// Find the target word (or conjugated form) in the sentence. Returns character offset range.
    static func findWordRange(word: String, sentence: String) -> (start: Int, end: Int)? {
        let lower = word.lowercased()
        let parts = lower.split(separator: " ").map(String.init)

        // Phrasal verb handling
        if parts.count >= 2 {
            let verb = parts[0]
            let rest = parts.dropFirst().joined(separator: " ")
            var verbForms = [verb] + generateRegularForms(verb)
            if let irregulars = irregularVerbs[verb] { verbForms += irregulars }
            verbForms = Array(Set(verbForms))

            for form in verbForms {
                let pattern = form + " " + rest
                if let range = findWithWordBoundary(pattern: pattern, in: sentence) {
                    return range
                }
            }
        }

        // Single word
        var patterns = [lower] + generateRegularForms(lower)
        if let irregulars = irregularVerbs[lower] { patterns += irregulars }
        patterns = Array(Set(patterns))

        for pattern in patterns {
            if let range = findWithWordBoundary(pattern: pattern, in: sentence) {
                return range
            }
        }
        return nil
    }

    /// Extract phrase range based on word category.
    static func extractPhraseRange(word: String, category: String, sentence: String) -> (start: Int, end: Int)? {
        guard let wordRange = findWordRange(word: word, sentence: sentence) else { return nil }
        switch category {
        case "動詞": return expandForward(sentence: sentence, wordRange: wordRange, maxExtraWords: 4)
        case "形容詞": return expandForward(sentence: sentence, wordRange: wordRange, maxExtraWords: 2)
        case "名詞": return expandBackward(sentence: sentence, wordRange: wordRange, maxExtraWords: 2)
        default: return wordRange
        }
    }

    /// Extract phrase string.
    static func extractPhrase(word: String, category: String, sentence: String) -> String? {
        guard let range = extractPhraseRange(word: word, category: category, sentence: sentence) else { return nil }
        let chars = Array(sentence)
        let end = min(range.end + 1, chars.count)
        return String(chars[range.start..<end])
    }

    /// Find Japanese meaning in Japanese sentence.
    static func findMeaningRange(meaning: String, sentence: String) -> (start: Int, end: Int)? {
        let meanings = meaning.components(separatedBy: CharacterSet(charactersIn: "、・"))

        // Exact match
        for m in meanings {
            if let idx = sentence.range(of: m) {
                let start = sentence.distance(from: sentence.startIndex, to: idx.lowerBound)
                let end = sentence.distance(from: sentence.startIndex, to: idx.upperBound) - 1
                return (start, end)
            }
        }

        // Stem matching
        let suffixes = ["する", "な", "い", "に", "の", "く", "させる", "される"]
        for m in meanings {
            for suffix in suffixes {
                if m.hasSuffix(suffix) {
                    let stem = String(m.dropLast(suffix.count))
                    if stem.isEmpty { continue }
                    if let idx = sentence.range(of: stem) {
                        let startOffset = sentence.distance(from: sentence.startIndex, to: idx.lowerBound)
                        var endIdx = idx.upperBound
                        let chars = Array(sentence.unicodeScalars)
                        var endOffset = sentence.distance(from: sentence.startIndex, to: endIdx)
                        while endOffset < chars.count && isHiragana(chars[endOffset]) {
                            endOffset += 1
                        }
                        return (startOffset, endOffset - 1)
                    }
                }
            }
        }

        // Last resort: substring match
        for m in meanings where m.count >= 2 {
            let prefix = String(m.prefix(m.count - 1))
            if let idx = sentence.range(of: prefix) {
                let startOffset = sentence.distance(from: sentence.startIndex, to: idx.lowerBound)
                var endOffset = startOffset + m.count - 1
                let chars = Array(sentence.unicodeScalars)
                while endOffset < chars.count && isHiragana(chars[endOffset]) {
                    endOffset += 1
                }
                return (startOffset, endOffset - 1)
            }
        }

        return nil
    }

    // MARK: - Private Helpers

    private static func isVowel(_ c: Character) -> Bool {
        "aeiouAEIOU".contains(c)
    }

    private static func isHiragana(_ scalar: Unicode.Scalar) -> Bool {
        scalar.value >= 0x3040 && scalar.value <= 0x309F
    }

    private static func generateRegularForms(_ word: String) -> [String] {
        var forms = [
            word + "s", word + "es", word + "d", word + "ed", word + "ing"
        ]
        if word.hasSuffix("e") {
            let stem = String(word.dropLast())
            forms += [stem + "ing", stem + "ed"]
        }
        if word.hasSuffix("y") {
            let stem = String(word.dropLast())
            forms += [stem + "ied", stem + "ies"]
        }
        if word.count >= 3, let last = word.last, !isVowel(last) {
            forms += [word + String(last) + "ed", word + String(last) + "ing"]
        }
        return forms
    }

    private static func findWithWordBoundary(pattern: String, in sentence: String) -> (start: Int, end: Int)? {
        let escaped = NSRegularExpression.escapedPattern(for: pattern)
        guard let regex = try? NSRegularExpression(pattern: "\\b\(escaped)\\b", options: .caseInsensitive) else { return nil }
        let nsRange = NSRange(sentence.startIndex..., in: sentence)
        guard let match = regex.firstMatch(in: sentence, range: nsRange) else { return nil }
        guard let range = Range(match.range, in: sentence) else { return nil }
        let start = sentence.distance(from: sentence.startIndex, to: range.lowerBound)
        let end = sentence.distance(from: sentence.startIndex, to: range.upperBound) - 1
        return (start, end)
    }

    private static func expandForward(sentence: String, wordRange: (start: Int, end: Int), maxExtraWords: Int) -> (start: Int, end: Int) {
        let chars = Array(sentence)
        var endPos = wordRange.end + 1
        var wordsAdded = 0
        var inWord = false

        while endPos < chars.count && wordsAdded < maxExtraWords {
            let ch = chars[endPos]
            if ".,:;!?".contains(ch) { break }
            if ch == " " {
                if inWord { wordsAdded += 1; inWord = false }
            } else { inWord = true }
            endPos += 1
        }
        while endPos > wordRange.end + 1 && chars[endPos - 1] == " " { endPos -= 1 }
        return (wordRange.start, max(wordRange.end, endPos - 1))
    }

    private static func expandBackward(sentence: String, wordRange: (start: Int, end: Int), maxExtraWords: Int) -> (start: Int, end: Int) {
        let chars = Array(sentence)
        var startPos = wordRange.start
        var wordsAdded = 0
        var inWord = false

        while startPos > 0 && wordsAdded < maxExtraWords {
            startPos -= 1
            let ch = chars[startPos]
            if ".,:;!?".contains(ch) { startPos += 1; break }
            if ch == " " {
                if inWord { wordsAdded += 1; inWord = false }
            } else { inWord = true }
        }
        while startPos < wordRange.start && chars[startPos] == " " { startPos += 1 }
        return (startPos, wordRange.end)
    }
}
