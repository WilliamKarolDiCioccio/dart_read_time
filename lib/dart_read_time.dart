/// Estimates how long a piece of text takes to read.
///
/// Fifty-four languages, and **the script decides the unit rather than the
/// tag**. A whitespace split is the wrong instrument for Japanese, Chinese,
/// Thai and Khmer, which are written without spaces between words and come out
/// of one as a single enormous token. So the text is walked a rune at a time
/// and split into runs by script: the spaced runs are counted in words, the
/// space-less ones in characters, and the two durations are added. Text that
/// is Japanese with an English title in it is priced as both, because it is
/// both.
///
/// ```dart
/// final estimate = estimateReadTime(
///   passage,
///   options: const ReadTimeOptions(language: 'ja'),
/// );
/// print('${estimate.roundedMinutes} min');
/// ```
///
/// **Seventeen of the languages are measured and thirty-seven are reasoned**,
/// and every entry says which it is through [ReadingSpeed.evidence]. The
/// measured figures come from cross-linguistic reading studies; the rest are
/// extrapolations from a measured neighbour, each naming the one it came from
/// and why. Nothing here hides which is which.
///
/// **Pure Dart, and not one path to `package:flutter`.** How fast a language
/// is read is a fact about the language, so this runs in a browser, in a CLI,
/// on a server and inside a Flutter app alike.
library;

export 'src/estimate/read_time.dart'
    show
        ContentMultiplier,
        LanguageSpan,
        ReadTime,
        ReadTimeOptions,
        estimateMarkdownReadTime,
        estimateReadTime,
        estimateSpannedMarkdownReadTime,
        estimateSpannedReadTime;
export 'src/speeds/reading_speed.dart'
    show ReadingPace, ReadingSpeed, ReadingUnit, SpeedEvidence;
export 'src/speeds/speed_table.dart'
    show
        ReadingSpeeds,
        characterRateFor,
        kFallbackCharactersPerMinute,
        kFallbackSpeed,
        kFallbackWordsPerMinute,
        kScriptCharacterRates;
export 'src/text/markdown_prose.dart' show markdownToProse;
export 'src/text/script_counts.dart'
    show CountingScript, TextCounts, continuousScriptOf, countText;
