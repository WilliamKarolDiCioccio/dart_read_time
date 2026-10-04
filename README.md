# dart_read_time

Estimates how long a piece of text takes to read, in fifty-four languages —
and gets Japanese, Chinese, Thai and Khmer right, which the usual
`text.split(' ').length / 200` does not.

Pure Dart. No Flutter anywhere in it, so it runs in a browser, in a CLI, on a
server and inside a Flutter app alike.

```dart
import 'package:dart_read_time/dart_read_time.dart';

final estimate = estimateReadTime(
  passage,
  options: const ReadTimeOptions(language: 'ja'),
);

print('${estimate.roundedMinutes} min read');   // 3 min read
print(estimate.words);                          // 12
print(estimate.characters);                     // 840
print(estimate.readingSpeed.evidence);          // SpeedEvidence.measured
```

## The script decides the unit, not the tag

Chinese, Japanese, Thai and Khmer are written without spaces between words. A
whitespace split finds *one token* in a whole paragraph of any of them and
reports it as a two-second read.

So the text is walked a rune at a time and cut into runs by script. Spaced runs
are counted in words at that language's words-per-minute; space-less runs are
counted in characters at its characters-per-minute; the two durations are
added. Text that is Japanese with an English title in the middle is priced as
both, because it is both.

```dart
final estimate = estimateReadTime('彼は Tokyo Tower を見た。');
estimate.words;          // 2
estimate.characters;     // 5
estimate.isMixedScript;  // true
```

The consequence worth knowing: **the language tag is a hint rather than the
authority**, so a wrong one costs far less than it looks. Text in an unmapped
language still gets counted by whatever script it is actually written in.

**Korean is counted by the word.** Hangul looks East Asian and is not written
like it — Korean spaces its eojeol — so filing it with Chinese and Japanese
would roughly triple every Korean estimate. It is the mistake this library is
most careful about.

## Text in more than one language

Mixed *scripts* are handled above without you doing anything. Mixed
*languages in the same script* — English quoting a French sentence — need
someone to say where the French is, and **this package detects nothing**:

```dart
estimateSpannedReadTime(
  text,
  [LanguageSpan(start: 42, end: 96, language: 'fr')],
  options: const ReadTimeOptions(language: 'en'),
);
```

Spans come from wherever you have them — a detector, a `lang=` attribute, an
author who said so. Baking one detector in would have made it normative, tied
this package to that detector's platform, and put an `await` in front of a
synchronous function. `estimateSpannedMarkdownReadTime` is the same thing with
offsets into the Markdown source.

Handing over no spans is the off switch and costs nothing. Gaps fall to
`options.language`; overlaps go to whichever span starts earlier; out-of-range
offsets are clamped rather than thrown at.

**Spans change the rate, never the unit.** What is counted in words and what in
characters is still decided by the script the runes are in, so a span naming
the wrong language costs a rate rather than an order of magnitude. That is
worth knowing before you wire a detector to it: the common ones are documented
to confuse Chinese with Korean, and here that is the difference between 158 and
170 words a minute rather than the threefold error it would be if the language
picked the unit.

The result says what it drew on:

```dart
estimate.byLanguage;        // {'en': 0:00:22.6, 'fr': 0:00:03.1}
estimate.dominantLanguage;  // 'en'
estimate.isMultilingual;    // true
```

## Used in production

dart_read_time puts a reading time under every passage in [Ripple
Effect](https://ripplefx.app), a desktop application for writing interactive
stories as graphs, built with Flutter and Rust for Linux, macOS and Windows. A
passage there is a Markdown file per language, and the bar beneath the editor
shows the counts, the three pace bands and the estimate, recomputed when the
author stops typing. The app does what this package deliberately leaves to its
caller: it removes its own embedded Python snippets before the Markdown goes in,
and supplies the language spans from a detector, so a passage mixing Japanese
and English is counted a run at a time. The reader's pace is a setting, kept as
a `ReadingPace`.

## Seventeen languages are measured; thirty-seven are reasoned

The measured figures come from cross-linguistic reading studies, including the
IReST benchmark and the Brysbaert meta-analysis. The rest are extrapolations
from a measured language, by descent (Danish from Swedish, Czech from Polish)
or by morphological type (Estonian and Hungarian from Finnish, Korean from
Turkish).

**Every entry says which it is**, and no extrapolation is derived from another
extrapolation:

```dart
final danish = ReadingSpeeds.of('da');
danish.evidence;     // SpeedEvidence.derived
danish.derivedFrom;  // 'sv'
danish.note;         // 'Scandinavian beside Swedish, and the same on the …'
```

A language with no entry falls back to 200 words a minute, or 300 characters a
minute for a space-less script, and is marked `SpeedEvidence.fallback`.

| | measured | | |
| --- | --- | --- | --- |
| English 238 | Spanish 218 | Dutch 202 | Swedish 199 |
| French 195 | Japanese 193 | Italian 188 | Hebrew 187 |
| Russian 184 | Portuguese 181 | Slovenian 180 | German 179 |
| Polish 166 | Turkish 166 | Finnish 161 | Chinese 158 |
| Arabic 138 | | | |

Words a minute at the adult average. Japanese and Chinese also carry 400 and
300 characters a minute respectively, which is what actually prices them.

**A lower words-per-minute is not slower comprehension.** German and Finnish
pack more into a word than English does, so a reader gets through the same
meaning in about the same time while crossing fewer words to do it. The numbers
measure the page, not the reader.

## Pace and density

```dart
const ReadTimeOptions(
  language: 'de',
  pace: ReadingPace.fast,                          // slow | average | fast
  contentMultiplier: ContentMultiplier.technical,  // 0.8
)
```

`ReadingPace.average` is the adult average and the default. `slow` is a reader
studying the text or still acquiring the language; `fast` is skimming.

The multiplier scales the **speed**, so `ContentMultiplier.technical` (0.8)
makes the estimate *longer* — dense writing is read more slowly.
`ContentMultiplier.fiction` is 1.1, and the field is an ordinary `double` if you
have measured your own.

`copyWith` treats a null argument as *keep*; `copyWith(clearLanguage: true)` is
how a language is taken away.

## Markdown

```dart
estimateMarkdownReadTime(document, options: const ReadTimeOptions(language: 'en'));
```

Strips fenced code and its contents, code spans, HTML, link and image
destinations, heading and list and blockquote markers, and emphasis — then
counts what is left. A link is worth its text and not its URL; a bare
`![](../art/map.png)` is worth nothing.

Ordinary Markdown only. A host with a templating dialect of its own strips that
first: this package knowing about one host's braces would make it the wrong
package.

One limit, stated rather than hidden: **indented code blocks are not removed**.
Telling four leading spaces of code from four leading spaces of a wrapped list
item needs a real block parser, and guessing wrong would silently drop prose.

## Install

```yaml
dependencies:
  dart_read_time: ^1.0.0
```

## Licence

MIT.
