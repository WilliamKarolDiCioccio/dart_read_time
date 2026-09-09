# dart_read_time

How long a piece of text takes to read. A standalone package with its own
repository, its own hooks and its own release cadence — consumed by
ripple_effect as a submodule, and by anything else as an ordinary pub
dependency.

The public surface is described in [`README.md`](README.md), which is what
pub.dev shows and is not repeated here. This file is the reasoning.

## The one rule

**Not one path through this package's dependency graph may reach
`package:flutter`.** The bar is higher than avoiding `dart:ui`:
`package:flutter/foundation.dart` pulls it in on its own through
`assertions.dart`, so `@immutable` from `foundation` is as disqualifying as
`TextPainter` is. `@immutable` comes from `package:meta`.

That is not tidiness. How fast a language is read is a fact about the language,
so this has to be usable by a browser, a CLI, a server and a Flutter app alike
— and by a campaign runtime that is itself forbidden Flutter. The check is one
command, and a pre-commit hook runs it:

```sh
fvm dart pub deps --style=list | tail -n +3 | grep -i flutter    # nothing
```

`tail -n +3` drops FVM's own `Flutter SDK 3.41.9` banner, which is printed
before the dependency graph and otherwise makes the check pass for the wrong
reason — it says nothing about what this package depends on.

`lints/recommended`, not `flutter_lints`, for the same reason: a ruleset that
assumes Flutter is the first dependency to sneak back in.

## What is here

| | |
| --- | --- |
| `src/text/script_counts.dart` | Walks the runes and counts each script in its own unit. The load-bearing file. |
| `src/text/markdown_prose.dart` | Markdown with the markup taken out, so what is left is what is read. |
| `src/speeds/reading_speed.dart` | What one language's numbers are, and what they rest on. |
| `src/speeds/speed_table.dart` | The fifty-four entries, the per-script rates, and the tag reduction. |
| `src/estimate/read_time.dart` | Counts in, a `Duration` out. |

## The script decides the unit, not the tag

The obvious design is to let the declared language pick words or characters for
the whole string. It is wrong twice over, and both cases are ordinary rather
than exotic: a Japanese passage quoting an English title is not all characters,
and an English passage quoting a Chinese name is not all words.

So the text is cut into runs by script and each run is priced in its own unit,
and the durations are **added**. What that buys beyond correctness is that the
tag stops being load-bearing: text in a language this table has never heard of
is still counted by the script it is actually written in, so a wrong or missing
tag costs a rate rather than an order of magnitude.

**Hangul is not a counted script**, and it is the one thing here most likely to
be "fixed" by somebody going on appearance. Korean spaces its eojeol. Moving it
in with Han and kana would roughly triple every Korean estimate, and
`speed_table_test.dart` has a test named after it for exactly that reason.

`ReadingSpeed.nativeScripts` is what separates a language's own script from a
quotation in someone else's. Kanji inside Japanese prose is priced by the
Japanese entry; the same characters inside Thai prose are a quotation and fall
to what Han costs in general. Without that field a Han rate would leak into
every language that happened to carry one.

## Measured and derived are kept on the data

Seventeen entries come from cross-linguistic reading studies. Thirty-seven are
extrapolations, and `SpeedEvidence` plus `derivedFrom` say so on every one.

The distinction lives on the data rather than in a comment because it is the
kind that gets lost: a table that mixes the two silently invites its guesses to
be quoted back as findings. A caller can ask, and the app that consumes this
can show a reader which it got.

**No extrapolation rests on another.** Malay is reasoned from Spanish directly
rather than from Indonesian, even though Indonesian is the closer relative,
because a chain of extrapolations is a guess wearing a citation. The test
enforces it: every `derived` entry must name a `measured` one.

Three entries resist the neighbour rule and say so in their own `note`:

- **Vietnamese** spaces every *syllable*, so a whitespace split returns roughly
  twice the tokens another language would. Its words-per-minute is raised to
  match, which makes the duration right and the word count incomparable.
- **Thai** and **Khmer** are derived from *Chinese* — not by any relation, but
  by the only property that decides the unit: no spaces between words.

## Working on it

```sh
fvm dart pub get
fvm dart format lib test
fvm dart analyze
fvm dart test
```

`fvm dart`, never `fvm flutter`, and never a bare `dart`: the toolchain is
pinned in `.fvmrc` and reaching for the Flutter tooling is how the one rule
starts to erode. `pre-commit install` once per clone wires all four up, plus
the dependency check.

The tests are the specification. Each one pins something that would otherwise
be assumed — the Japanese and Chinese character counts are hand-counted, the
multiplier test exists because scaling the speed rather than the duration is
easy to get backwards, and the Korean test exists because the bug it guards
against would look like a reasonable simplification.
