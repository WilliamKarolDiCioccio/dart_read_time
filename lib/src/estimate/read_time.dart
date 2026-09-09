/// The estimate itself: counts in, a duration out.
library;

import 'package:meta/meta.dart';

import '../speeds/reading_speed.dart';
import '../speeds/speed_table.dart';
import '../text/markdown_prose.dart';
import '../text/script_counts.dart';

/// The multipliers for the kinds of writing people actually measure.
///
/// They scale the **speed**, so a number below one makes the estimate
/// *longer*: dense writing is read more slowly, not more quickly. The field
/// that takes them is an ordinary `double`, so a caller with its own figure
/// does not have to be in this list.
abstract final class ContentKind {
  const ContentKind._();

  /// Ordinary writing. The default, and the multiplier that changes nothing.
  static const double prose = 1.0;

  /// Technical or legal writing — dense, and re-read as it goes.
  static const double technical = 0.8;

  /// Light fiction, read at a clip.
  static const double fiction = 1.1;
}

/// Who is reading, in what, and how densely it is written.
@immutable
final class ReadTimeOptions {
  const ReadTimeOptions({
    this.language,
    this.pace = ReadingPace.medium,
    this.contentMultiplier = ContentKind.prose,
  }) : assert(contentMultiplier > 0, 'contentMultiplier must be positive');

  /// Any BCP 47-ish tag — `en`, `pt-BR`, `zh-Hans-CN`, `en_US.UTF-8`.
  ///
  /// Null means the caller did not say, which is treated exactly like a
  /// language the table does not know: the global default, marked as such. The
  /// tag is a *hint* rather than the authority — text is counted by the script
  /// it is written in either way, so a wrong tag costs less than it looks.
  final String? language;

  /// Which of the three bands to read at. [ReadingPace.medium] by default,
  /// because it is the adult average and the only defensible guess.
  final ReadingPace pace;

  /// How dense the writing is, as a multiplier on the speed. See
  /// [ContentKind].
  final double contentMultiplier;

  /// This, with whatever is named replaced.
  ReadTimeOptions copyWith({
    String? language,
    ReadingPace? pace,
    double? contentMultiplier,
  }) => ReadTimeOptions(
    language: language ?? this.language,
    pace: pace ?? this.pace,
    contentMultiplier: contentMultiplier ?? this.contentMultiplier,
  );
}

/// How long a piece of text takes to read, and how that was arrived at.
///
/// The counts and the speed are kept rather than thrown away, because an
/// estimate nobody can check is one nobody should trust: [speed] says whether
/// the language was measured, derived or defaulted, and [counts] says what was
/// actually found in the text.
@immutable
final class ReadTime {
  const ReadTime({
    required this.duration,
    required this.counts,
    required this.speed,
    this.byLanguage = const <String, Duration>{},
  });

  /// Nothing to read, which is what empty text comes to.
  ReadTime.empty(this.speed)
    : duration = Duration.zero,
      counts = const TextCounts.empty(),
      byLanguage = const <String, Duration>{};

  /// How long it takes.
  final Duration duration;

  /// What was found in the text, in both units.
  final TextCounts counts;

  /// The entry the **document's** language resolved to — including its
  /// [ReadingSpeed.evidence], which is how a caller tells a measurement from a
  /// default.
  ///
  /// With spans, stretches of the text may have been priced by other entries
  /// than this one; [byLanguage] is what says so.
  final ReadingSpeed speed;

  /// How much of [duration] each **named** language accounted for, keyed by
  /// the tag as the caller wrote it.
  ///
  /// Text covered by no span and by no [ReadTimeOptions.language] is absent
  /// rather than filed under a placeholder: it was priced by the global
  /// default, and the global default is not a language. So the values sum to
  /// [duration] only when something named covered all of it.
  final Map<String, Duration> byLanguage;

  /// The language that accounts for most of the reading, or null when none was
  /// named.
  ///
  /// What a caller wants in order to say "mostly English" without deciding for
  /// itself what "mostly" means.
  String? get dominantLanguage {
    String? best;
    var longest = Duration.zero;
    for (final entry in byLanguage.entries) {
      if (entry.value > longest) {
        longest = entry.value;
        best = entry.key;
      }
    }
    return best;
  }

  /// Whether more than one language was named for this text.
  bool get isMultilingual => byLanguage.length > 1;

  /// Words found in the spaced runs.
  int get words => counts.words;

  /// Characters found in the space-less runs, across every script.
  int get characters => counts.totalCharacters;

  /// Whether both units contributed — Japanese prose with an English title in
  /// it, or English prose quoting a Chinese name.
  bool get isMixedScript => counts.isMixed;

  /// The figure to put in front of a reader: whole minutes, and never zero for
  /// text that has something in it.
  ///
  /// "Less than a minute" is a sentence the caller writes, not a number this
  /// package can round to — so anything non-empty is at least 1, and only
  /// genuinely empty text is 0.
  int get roundedMinutes {
    if (counts.isEmpty) return 0;
    final minutes = (duration.inMilliseconds / 60000).round();
    return minutes < 1 ? 1 : minutes;
  }

  @override
  String toString() =>
      'ReadTime(${duration.inSeconds}s, words: $words, '
      'characters: $characters, ${speed.evidence.name})';
}

/// A stretch of text known to be in one language.
///
/// **This package detects nothing**, and that is the design rather than a gap.
/// Whoever knows what language a passage is in — a detector, a `lang=`
/// attribute, an author who said so — hands the ranges over, and this prices
/// them. Baking one detector in would have made it normative, tied this to
/// that detector's platform and dependencies, and put an initialisation step
/// in front of a synchronous function.
///
/// [start] is inclusive and [end] exclusive, both in **code units** — the
/// indices `String.substring` takes, and the ones a scanner naturally produces.
@immutable
final class LanguageSpan {
  const LanguageSpan({
    required this.start,
    required this.end,
    required this.language,
  });

  final int start;
  final int end;

  /// Any BCP 47-ish tag, read the same way [ReadTimeOptions.language] is.
  final String language;

  /// How many code units this covers.
  int get length => end - start;

  @override
  String toString() => 'LanguageSpan($start..$end, $language)';
}

/// How long [text] takes to read when different stretches of it are in
/// different languages.
///
/// **Spans change the rate, never the unit.** What is counted in words and
/// what is counted in characters is decided by the script the runes are
/// actually written in, exactly as it is without spans — so a span that names
/// the wrong language costs a rate rather than an order of magnitude. That
/// containment is deliberate: the detectors a caller is likely to reach for
/// are documented to confuse Chinese with Korean, which is precisely the pair
/// this package is otherwise most careful about, and a wrong answer there
/// would be a rounding error rather than a threefold one.
///
/// The spans need not be sorted, need not touch, and need not cover
/// everything. What they do:
///
/// - **A gap** is priced by [ReadTimeOptions.language], like any other text.
/// - **An overlap** is resolved in favour of whichever span starts earlier;
///   the later one is trimmed. Nothing is ever counted twice.
/// - **Out of range** is clamped, and anything left empty is dropped. A
///   detector that hands over a stale offset should not throw underneath a
///   caller who cannot do anything about it.
///
/// The one thing worth aligning: a boundary that falls **inside a word** cuts
/// it, and the two halves are counted as two words. That is inherent to
/// cutting a string at an offset rather than a fault to work around — a caller
/// segmenting by sentence or paragraph never lands there, and one that does
/// has said the halves are in different languages.
ReadTime estimateSpannedReadTime(
  String text,
  List<LanguageSpan> spans, {
  ReadTimeOptions options = const ReadTimeOptions(),
}) {
  final base = ReadingSpeeds.of(options.language);
  if (text.isEmpty) return ReadTime.empty(base);
  if (spans.isEmpty) return estimateReadTime(text, options: options);

  final ordered = _tidy(spans, text.length);

  var words = 0;
  final characters = <CountingScript, int>{};
  var total = Duration.zero;
  final byLanguage = <String, Duration>{};

  void take(int start, int end, String? language) {
    if (end <= start) return;
    final counts = countText(text.substring(start, end));
    if (counts.isEmpty) return;

    final speed = ReadingSpeeds.of(language);
    final slice = _durationOf(counts, speed, options);

    words += counts.words;
    for (final entry in counts.characters.entries) {
      characters[entry.key] = (characters[entry.key] ?? 0) + entry.value;
    }
    total += slice;
    if (language != null) {
      byLanguage[language] = (byLanguage[language] ?? Duration.zero) + slice;
    }
  }

  var cursor = 0;
  for (final span in ordered) {
    take(cursor, span.start, options.language);
    take(span.start, span.end, span.language);
    cursor = span.end;
  }
  take(cursor, text.length, options.language);

  return ReadTime(
    duration: total,
    counts: TextCounts(words: words, characters: characters),
    speed: base,
    byLanguage: byLanguage,
  );
}

/// The same, with the Markdown taken out of [markdown] first.
///
/// **The spans must index the Markdown**, not the prose underneath it: this is
/// the form a caller has, and asking them to offset around markup they did not
/// remove would be asking them to do the removal twice. Stripping happens here
/// and the spans are carried across with it.
ReadTime estimateSpannedMarkdownReadTime(
  String markdown,
  List<LanguageSpan> spans, {
  ReadTimeOptions options = const ReadTimeOptions(),
}) {
  if (spans.isEmpty) {
    return estimateMarkdownReadTime(markdown, options: options);
  }
  // Prose per span rather than one pass over the document: a span is a range
  // of the *source*, and stripping the whole thing first would leave every
  // offset after the first fence pointing somewhere else.
  final pieces = <LanguageSpan>[];
  final prose = StringBuffer();
  var cursor = 0;

  void append(int start, int end, String? language) {
    if (end <= start) return;
    final text = markdownToProse(markdown.substring(start, end));
    if (text.isEmpty) return;
    final from = prose.length;
    prose.write(text);
    if (language != null) {
      pieces.add(
        LanguageSpan(start: from, end: prose.length, language: language),
      );
    }
  }

  for (final span in _tidy(spans, markdown.length)) {
    append(cursor, span.start, null);
    append(span.start, span.end, span.language);
    cursor = span.end;
  }
  append(cursor, markdown.length, null);

  return estimateSpannedReadTime(prose.toString(), pieces, options: options);
}

/// Sorted, clamped, de-overlapped, and with the empties dropped.
List<LanguageSpan> _tidy(List<LanguageSpan> spans, int length) {
  final sorted = <LanguageSpan>[...spans]
    ..sort((a, b) => a.start.compareTo(b.start));

  final kept = <LanguageSpan>[];
  var reached = 0;
  for (final span in sorted) {
    final start = span.start < reached ? reached : span.start;
    final from = start < 0 ? 0 : start;
    final to = span.end > length ? length : span.end;
    if (to <= from) continue;
    kept.add(LanguageSpan(start: from, end: to, language: span.language));
    reached = to;
  }
  return kept;
}

/// How long [text] takes to read.
///
/// [text] is taken as plain prose. Markdown goes through
/// [estimateMarkdownReadTime] instead, which strips the markup first. Text in
/// more than one language goes through [estimateSpannedReadTime].
ReadTime estimateReadTime(
  String text, {
  ReadTimeOptions options = const ReadTimeOptions(),
}) {
  final speed = ReadingSpeeds.of(options.language);
  if (text.isEmpty) return ReadTime.empty(speed);

  final counts = countText(text);
  final duration = _durationOf(counts, speed, options);
  final language = options.language;
  return ReadTime(
    duration: duration,
    counts: counts,
    speed: speed,
    // One entry, or none where the caller named no language — the same rule
    // the spanned estimate follows, so a caller reading `byLanguage` does not
    // have to know which function produced the answer.
    byLanguage: language == null
        ? const <String, Duration>{}
        : <String, Duration>{language: duration},
  );
}

/// How long the prose in [markdown] takes to read.
///
/// The markup goes first — see [markdownToProse] for exactly what counts as
/// markup — so a fenced code block costs nothing and a link is worth its text
/// rather than its URL.
ReadTime estimateMarkdownReadTime(
  String markdown, {
  ReadTimeOptions options = const ReadTimeOptions(),
}) => estimateReadTime(markdownToProse(markdown), options: options);

/// The sum of every run's own duration.
///
/// **Both units are added rather than one being chosen.** That is the whole
/// argument for counting by script: a passage that is nine tenths Japanese and
/// one tenth English is priced as nine tenths of a Japanese passage plus a
/// tenth of an English one, which neither unit alone would get right.
Duration _durationOf(
  TextCounts counts,
  ReadingSpeed speed,
  ReadTimeOptions options,
) {
  final multiplier = options.contentMultiplier;
  if (multiplier <= 0) {
    throw ArgumentError.value(
      multiplier,
      'contentMultiplier',
      'must be positive',
    );
  }

  var seconds = 0.0;

  if (counts.words > 0) {
    final rate = speed.wordsPerMinute(options.pace) * multiplier;
    seconds += counts.words / rate * 60;
  }

  for (final entry in counts.characters.entries) {
    // The reader's own rate only where the script is one the language is
    // written in. Kanji in Japanese prose is Japanese; the same characters
    // quoted in Thai prose are a quotation, and are not read at Thai speed.
    final own = speed.nativeScripts.contains(entry.key)
        ? speed.charactersPerMinute(options.pace)
        : null;
    final rate =
        (own ?? characterRateFor(entry.key, options.pace)) * multiplier;
    seconds += entry.value / rate * 60;
  }

  return Duration(milliseconds: (seconds * 1000).round());
}
