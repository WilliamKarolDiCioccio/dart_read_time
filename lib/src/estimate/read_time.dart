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
  });

  /// Nothing to read, which is what empty text comes to.
  ReadTime.empty(this.speed)
    : duration = Duration.zero,
      counts = const TextCounts.empty();

  /// How long it takes.
  final Duration duration;

  /// What was found in the text, in both units.
  final TextCounts counts;

  /// The entry the estimate was priced with — including its
  /// [ReadingSpeed.evidence], which is how a caller tells a measurement from a
  /// default.
  final ReadingSpeed speed;

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

/// How long [text] takes to read.
///
/// [text] is taken as plain prose. Markdown goes through
/// [estimateMarkdownReadTime] instead, which strips the markup first.
ReadTime estimateReadTime(
  String text, {
  ReadTimeOptions options = const ReadTimeOptions(),
}) {
  final speed = ReadingSpeeds.of(options.language);
  if (text.isEmpty) return ReadTime.empty(speed);

  final counts = countText(text);
  return ReadTime(
    duration: _durationOf(counts, speed, options),
    counts: counts,
    speed: speed,
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
