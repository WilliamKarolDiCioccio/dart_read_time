/// How fast a language is read, and what that number rests on.
library;

import 'package:meta/meta.dart';

import '../text/script_counts.dart';

/// Which reader the estimate is for.
///
/// Not a quality ranking. The bands come from the spread real studies measure
/// across a population and a purpose: [slow] is a reader studying the text or
/// one still acquiring the language, [average] is the adult average and the
/// only defensible default, [fast] is skimming or light prose already
/// familiar.
enum ReadingPace {
  /// Studying it, or reading in a language not yet fluent.
  slow,

  /// The adult average. The default, and the number everything else is
  /// anchored on.
  average,

  /// Skimming, or light prose read at speed.
  fast,
}

/// What a language's numbers actually rest on.
///
/// Kept on every entry and never dropped, because a table that mixes measured
/// figures with reasoned ones and says nothing about which is which invites
/// the reasoned ones to be quoted as findings. They are not findings.
enum SpeedEvidence {
  /// Taken from cross-linguistic reading studies — the IReST benchmark and the
  /// Brysbaert meta-analysis among them.
  measured,

  /// Reasoned from a measured language, by descent or by morphological type.
  /// The entry names which one and says why.
  derived,

  /// Nothing language-specific at all: the global default, for a tag this
  /// table has never heard of.
  fallback,
}

/// How fast one language is read, in both units, across the three bands.
///
/// **Both units on one entry, and that is the load-bearing part.** Every
/// language gets words per minute. A language whose script runs without spaces
/// *also* gets characters per minute, and names the scripts that rate applies
/// to — so kanji in a Japanese passage is read at the Japanese rate, while the
/// same characters quoted in an English one fall back to what Han costs in
/// general.
@immutable
final class ReadingSpeed {
  const ReadingSpeed({
    required this.slowWpm,
    required this.averageWpm,
    required this.fastWpm,
    required this.evidence,
    required this.note,
    this.slowCpm,
    this.averageCpm,
    this.fastCpm,
    this.nativeScripts = const {},
    this.derivedFrom,
  });

  /// Words per minute, studying or still learning.
  final int slowWpm;

  /// Words per minute, the adult average.
  final int averageWpm;

  /// Words per minute, skimming.
  final int fastWpm;

  /// Characters per minute, or null where the language is written with spaces
  /// and the question does not arise.
  final int? slowCpm;

  /// Characters per minute at the adult average, or null. **This is the field
  /// that decides whether the language is character-counted at all** — see
  /// [primaryUnit].
  final int? averageCpm;

  /// Characters per minute, skimming, or null.
  final int? fastCpm;

  /// The space-less scripts this language is actually written in.
  ///
  /// Empty for everything spaced. Japanese has two, because it is written in
  /// two. What it is *for* is deciding whose rate applies to a run: a Han run
  /// inside Japanese prose is Japanese, a Han run inside Thai prose is a
  /// quotation and is not read at Thai speed.
  final Set<CountingScript> nativeScripts;

  /// Where the numbers came from.
  final SpeedEvidence evidence;

  /// The language subtag this was reasoned from, or null when it was measured
  /// or is the fallback.
  final String? derivedFrom;

  /// One line on what makes this language read the way it does — or, for a
  /// derived entry, why it was reasoned from the language it was.
  final String note;

  /// Whether this language is counted by the character or by the word.
  ///
  /// Characters exactly when a character rate is present, which in this table
  /// is exactly the languages written without spaces.
  ReadingUnit get primaryUnit =>
      averageCpm == null ? ReadingUnit.words : ReadingUnit.characters;

  /// Words per minute at [pace].
  int wordsPerMinute(ReadingPace pace) => switch (pace) {
    ReadingPace.slow => slowWpm,
    ReadingPace.average => averageWpm,
    ReadingPace.fast => fastWpm,
  };

  /// Characters per minute at [pace], or null where this language has no
  /// character rate of its own.
  int? charactersPerMinute(ReadingPace pace) => switch (pace) {
    ReadingPace.slow => slowCpm,
    ReadingPace.average => averageCpm,
    ReadingPace.fast => fastCpm,
  };

  @override
  String toString() =>
      'ReadingSpeed($averageWpm wpm'
      '${averageCpm == null ? '' : ', $averageCpm cpm'}, ${evidence.name})';
}

/// The unit a language's text is measured in.
enum ReadingUnit {
  /// Split on whitespace and count what is left.
  words,

  /// Count the characters, because there is no whitespace to split on.
  characters,
}
