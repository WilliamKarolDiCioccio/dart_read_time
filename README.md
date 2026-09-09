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
print(estimate.speed.evidence);                 // SpeedEvidence.measured
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
  pace: ReadingPace.fast,                     // slow | medium | fast
  contentMultiplier: ContentKind.technical,   // 0.8
)
```

`ReadingPace.medium` is the adult average and the default. `slow` is a reader
studying the text or still acquiring the language; `fast` is skimming.

The multiplier scales the **speed**, so `ContentKind.technical` (0.8) makes the
estimate *longer* — dense writing is read more slowly. `ContentKind.fiction` is
1.1, and the field is an ordinary `double` if you have measured your own.

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
  dart_read_time: ^0.1.0
```

## Licence

MIT.
