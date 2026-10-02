# Changelog

## 1.0.0

The API is now stable. The algorithm and every figure in the table are
unchanged, so an estimate made with 0.1.1 is the same estimate today. Four
breaking renames, each to say more exactly what was already there:

- **`ContentKind` is now `ContentMultiplier`.** It never was a kind: it holds
  three `double` constants for `ReadTimeOptions.contentMultiplier`, a field
  that takes any positive `double`. The old name read like an enum and led
  people to expect one.
- **`ReadingPace.medium` is now `ReadingPace.average`**, which is what it
  always meant: the adult average. `ReadingSpeed.mediumWpm` and `mediumCpm`
  follow as `averageWpm` and `averageCpm`. A caller that stores a pace by
  `name` should still read a stored `'medium'` as `average`.
- **`ReadTime.speed` is now `ReadTime.readingSpeed`**, the name of its type.
- **`ReadTimeOptions.copyWith` can clear the language** with
  `clearLanguage: true`. A null `language` still means *keep*. Passing both is
  an `ArgumentError`.

Migrating from 0.1.x is a find-and-replace:

| 0.1.x | 1.0.0 |
| --- | --- |
| `ContentKind.technical` | `ContentMultiplier.technical` |
| `ReadingPace.medium` | `ReadingPace.average` |
| `speed.mediumWpm`, `speed.mediumCpm` | `speed.averageWpm`, `speed.averageCpm` |
| `estimate.speed` | `estimate.readingSpeed` |

## 0.1.1

- `example/dart_read_time_example.dart`: every entry point on the kinds of
  text that tell them apart — a plain paragraph, Japanese with an English
  title in it, English quoting French, a Markdown document — and what a
  derived rate says about itself. No change to the library.

## 0.1.0

The first release.

### Estimating a reading time

`estimateReadTime` takes text and answers a `ReadTime` — a `Duration`, the
counts it was arrived at from, and the `ReadingSpeed` it was priced with.
`estimateMarkdownReadTime` is the same thing with the markup taken out first.

`ReadTimeOptions` carries the language, one of three `ReadingPace` bands, and a
content multiplier. The multiplier scales the *speed*, so `ContentKind.technical`
(0.8) makes the estimate longer rather than shorter.

### Text in more than one language

`estimateSpannedReadTime` takes `LanguageSpan`s — ranges the caller says are in
a given language — and prices each in its own. `estimateSpannedMarkdownReadTime`
is the same with offsets into the Markdown source. **Nothing here detects a
language**: whoever knows hands the ranges over, so the package stays pure Dart,
stays synchronous, and does not make one detector normative.

Spans change the *rate* and never the *unit* — the script still decides whether
a stretch is counted in words or characters — so a span naming the wrong
language costs a rate rather than an order of magnitude. `ReadTime.byLanguage`,
`dominantLanguage` and `isMultilingual` say what the answer drew on.

### Counting by script rather than by tag

`countText` walks the runes and splits the text into runs by script: spaced
runs are counted in words, space-less ones in characters, and both counts come
back. That is what lets Japanese prose with an English title in it be priced as
both, and what stops a whitespace split reporting a paragraph of Chinese as one
token.

**Hangul is counted by the word**, deliberately. Korean spaces its eojeol;
filing it with Chinese and Japanese by appearance would roughly triple every
Korean estimate.

### Fifty-four languages, seventeen of them measured

The measured figures come from cross-linguistic reading studies. The other
thirty-seven are extrapolations from a measured language — by descent or by
morphological type — and each names the one it came from and says why.
`ReadingSpeed.evidence` and `ReadingSpeed.derivedFrom` keep the distinction on
the data rather than in a comment, and no extrapolation rests on another.

Anything unmapped falls back to 200 words a minute, or 300 characters a minute
for a space-less script.

### Stripping Markdown

`markdownToProse` removes fenced code and its contents, code spans, HTML tags
and comments, link and image destinations, link reference definitions,
autolinks, block markers and emphasis. Link text and image alt text stay:
somebody wrote them and somebody reads them. Indented code blocks are left
alone, because telling them from a wrapped list item needs a block parser.
