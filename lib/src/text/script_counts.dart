/// How much text there is, counted the way each script is actually read.
///
/// **The declared language does not decide the unit — the characters do.** A
/// Japanese passage quoting an English title is not all characters, and an
/// English passage quoting a Chinese name is not all words. So this walks the
/// runes, sends each one to the count its own script belongs in, and answers
/// both numbers. What to do with them is `estimateReadTime`'s problem.
library;

import 'package:meta/meta.dart';

/// A script whose text runs without spaces, and so is counted by the
/// character rather than by the word.
///
/// **Hangul is deliberately absent**, and it is the trap this enum exists to
/// avoid. Korean looks East Asian and is not written like it: it spaces its
/// eojeol, so Korean is word-counted like any Latin text. Filing it here would
/// roughly triple every Korean estimate.
enum CountingScript {
  /// Chinese characters, wherever they appear — hanzi, kanji, hanja.
  han,

  /// Hiragana and katakana.
  kana,

  /// Thai.
  thai,

  /// Khmer.
  khmer,

  /// Lao.
  lao,

  /// Burmese.
  myanmar,

  /// Tibetan.
  tibetan,
}

/// The space-less script [rune] belongs to, or null when it does not belong to
/// one.
///
/// Null is the answer for **everything else** — Latin letters, Cyrillic,
/// Hangul, whitespace, digits and punctuation alike — because everything else
/// goes into the same word-counted pile. It is not a claim that the rune is a
/// letter; [countText] decides that separately.
CountingScript? continuousScriptOf(int rune) {
  // Ordered by how often a rune is expected to land in each branch, and cut
  // short for the Latin range that most text is: a codepoint below U+0E00 can
  // be none of these, and testing that once beats testing it nine times.
  if (rune < 0x0E00) return null;

  if (rune <= 0x0E7F) return CountingScript.thai;
  if (rune <= 0x0EFF) return CountingScript.lao;
  if (rune <= 0x0FFF) return CountingScript.tibetan;
  if (rune >= 0x1000 && rune <= 0x109F) return CountingScript.myanmar;
  if (rune >= 0x1780 && rune <= 0x17FF) return CountingScript.khmer;
  // Khmer symbols, which are part of the same reading load.
  if (rune >= 0x19E0 && rune <= 0x19FF) return CountingScript.khmer;

  // Hiragana, katakana, the katakana phonetic extensions, and the halfwidth
  // katakana that older Japanese text is full of.
  if (rune >= 0x3041 && rune <= 0x30FF) return CountingScript.kana;
  if (rune >= 0x31F0 && rune <= 0x31FF) return CountingScript.kana;
  if (rune >= 0xFF66 && rune <= 0xFF9F) return CountingScript.kana;

  // The iteration mark 々 and the ideographic zero 〇 sit in the CJK
  // punctuation block, where everything around them is punctuation. Named one
  // at a time because the block they are in cannot be taken wholesale: 。 and
  // 、 are separators and must not be counted as characters read.
  if (rune == 0x3005 || rune == 0x3007) return CountingScript.han;

  // The unified ideographs, their extensions and the compatibility blocks.
  if (rune >= 0x3400 && rune <= 0x4DBF) return CountingScript.han;
  if (rune >= 0x4E00 && rune <= 0x9FFF) return CountingScript.han;
  if (rune >= 0xF900 && rune <= 0xFAFF) return CountingScript.han;
  if (rune >= 0x20000 && rune <= 0x2A6DF) return CountingScript.han;
  if (rune >= 0x2A700 && rune <= 0x2EBEF) return CountingScript.han;
  if (rune >= 0x2F800 && rune <= 0x2FA1F) return CountingScript.han;

  return null;
}

/// How much text there is, in both units at once.
@immutable
final class TextCounts {
  /// Nothing counted, which is what empty text and whitespace both come to.
  const TextCounts.empty() : words = 0, characters = const {};

  const TextCounts({required this.words, required this.characters});

  /// Words in the spaced runs — the Latin, Cyrillic, Arabic and Hangul of it.
  final int words;

  /// Characters in the space-less runs, kept **apart by script** rather than
  /// summed.
  ///
  /// Apart, because they are not read at the same rate: kana runs faster than
  /// hanzi, and a passage holding both would be mispriced by a single total.
  /// A script with nothing in it is absent rather than zero.
  final Map<CountingScript, int> characters;

  /// Every space-less character, whatever its script.
  int get totalCharacters =>
      characters.values.fold(0, (sum, count) => sum + count);

  /// Whether the text is written in more than one kind of script at once.
  ///
  /// True for Japanese prose with an English loanword in it, and for English
  /// prose quoting a Chinese name. Worth knowing because an estimate for such
  /// text rests on two rates rather than one.
  bool get isMixed => words > 0 && totalCharacters > 0;

  /// Whether there is nothing here to read.
  bool get isEmpty => words == 0 && totalCharacters == 0;

  @override
  String toString() => 'TextCounts(words: $words, characters: $characters)';
}

/// A token counts as a word only if it holds a letter or a digit.
///
/// Without this, a Japanese sentence would report words it does not have: its
/// kanji and kana are counted as characters and leave the spaces behind them,
/// but `。` and `、` are separators rather than script, so they fall through to
/// the word pile and would each arrive as a token of their own.
final RegExp _hasWordCharacter = RegExp(r'[\p{L}\p{N}]', unicode: true);

final RegExp _whitespace = RegExp(r'\s+');

/// Counts [text] in whichever units its scripts call for.
///
/// One pass. A rune in a space-less script is added to that script's tally and
/// leaves a space behind it in the word stream, so that Latin either side of a
/// kanji is never glued into one word. Everything else — letters, digits,
/// punctuation, whitespace — is passed through to be split on whitespace at
/// the end.
TextCounts countText(String text) {
  if (text.isEmpty) return const TextCounts.empty();

  final spaced = StringBuffer();
  final characters = <CountingScript, int>{};

  for (final rune in text.runes) {
    final script = continuousScriptOf(rune);
    if (script == null) {
      spaced.writeCharCode(rune);
    } else {
      characters[script] = (characters[script] ?? 0) + 1;
      spaced.write(' ');
    }
  }

  var words = 0;
  for (final token in spaced.toString().split(_whitespace)) {
    if (_hasWordCharacter.hasMatch(token)) words++;
  }

  return TextCounts(words: words, characters: characters);
}
