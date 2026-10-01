/// The table: fifty-four languages, and what each one's numbers rest on.
///
/// **Seventeen are measured and thirty-seven are reasoned, and every entry
/// says which it is.** The measured figures come from cross-linguistic reading
/// studies — the IReST benchmark and the Brysbaert meta-analysis among them.
/// The rest are extrapolations, marked [SpeedEvidence.derived], each naming
/// the measured language it was reasoned from and saying why that one.
///
/// The distinction is kept on the data rather than in a comment because it is
/// the kind that gets lost: a table that mixes the two silently invites its
/// guesses to be quoted back as findings.
///
/// **A lower words-per-minute is not slower comprehension.** German and
/// Finnish pack more into a word than English does, so a reader gets through
/// the same meaning in about the same time while crossing fewer words to do
/// it. The numbers measure the page, not the reader.
library;

import '../text/script_counts.dart';
import 'reading_speed.dart';

/// The global default for a language with no entry, in words a minute.
const int kFallbackWordsPerMinute = 200;

/// The global default for a space-less script with no rate of its own, in
/// characters a minute.
const int kFallbackCharactersPerMinute = 300;

/// What an unmapped language is assumed to read at.
///
/// Words rather than characters, because a tag nobody recognises is far more
/// likely to be a spaced language than not — and text that *is* space-less is
/// caught by its script anyway, through [characterRateFor], whatever its tag
/// claimed.
const ReadingSpeed kFallbackSpeed = ReadingSpeed(
  slowWpm: 150,
  averageWpm: kFallbackWordsPerMinute,
  fastWpm: 250,
  evidence: SpeedEvidence.fallback,
  note:
      'No entry for this language. 200 words a minute is the global default '
      'for spaced text; a space-less script is still counted by the '
      'character, at whatever that script costs.',
);

/// What a space-less script costs when the language is not one that owns it.
///
/// A Han run inside English prose is a quoted name, not Chinese being read, so
/// it is priced at what Han costs in general rather than at the reader's own
/// language rate. A Han run inside *Japanese* prose is kanji and is priced by
/// the Japanese entry — see [ReadingSpeed.nativeScripts], which is what
/// separates the two cases.
const Map<CountingScript, (int, int, int)> kScriptCharacterRates =
    <CountingScript, (int, int, int)>{
      CountingScript.han: (255, 300, 350),
      CountingScript.kana: (350, 400, 450),
      CountingScript.thai: (200, 250, 310),
      CountingScript.khmer: (180, 220, 270),
      CountingScript.lao: (180, 220, 270),
      CountingScript.myanmar: (175, 215, 265),
      CountingScript.tibetan: (170, 210, 260),
    };

/// What [script] costs at [pace] for a reader whose language does not own it.
int characterRateFor(CountingScript script, ReadingPace pace) {
  final rates = kScriptCharacterRates[script];
  if (rates == null) return kFallbackCharactersPerMinute;
  return switch (pace) {
    ReadingPace.slow => rates.$1,
    ReadingPace.average => rates.$2,
    ReadingPace.fast => rates.$3,
  };
}

/// Every language this package has a figure for, keyed by language subtag.
///
/// **Subtags, not locales.** `pt-BR` and `pt-PT` read at the same speed and
/// share one entry; so do `zh-CN` and `zh-TW`, and `sr-Latn-RS` with
/// `sr-Cyrl-RS`. Region and script tell you how a language is spelled, not how
/// fast it is crossed.
const Map<String, ReadingSpeed> _speeds = <String, ReadingSpeed>{
  'af': ReadingSpeed(
    slowWpm: 155,
    averageWpm: 207,
    fastWpm: 265,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'nl',
    note:
        "Dutch's descendant with most of the inflection dropped, so a shade "
        'quicker than the parent.',
  ),
  'ar': ReadingSpeed(
    slowWpm: 100,
    averageWpm: 138,
    fastWpm: 175,
    evidence: SpeedEvidence.measured,
    note:
        'Complex visual features. Unvocalised text, letters that change shape '
        'by position, and root-and-pattern words the reader resolves as they '
        'go.',
  ),
  'bal': ReadingSpeed(
    slowWpm: 110,
    averageWpm: 150,
    fastWpm: 190,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'ar',
    note:
        'Arabic script over Iranian morphology: the visual cost of the script '
        "without Arabic's root-and-pattern word forms.",
  ),
  'bg': ReadingSpeed(
    slowWpm: 135,
    averageWpm: 190,
    fastWpm: 245,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'ru',
    note:
        'Slavic vocabulary with the case system gone — the one Slavic language '
        'that became analytic, and quicker than Russian for it.',
  ),
  'brh': ReadingSpeed(
    slowWpm: 105,
    averageWpm: 143,
    fastWpm: 180,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'ar',
    note:
        'Arabic script over Dravidian agglutination: the script cost, and long '
        'words on top of it.',
  ),
  'ca': ReadingSpeed(
    slowWpm: 155,
    averageWpm: 205,
    fastWpm: 265,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'es',
    note:
        'Romance beside Spanish, with heavier syllable codas and more elision '
        'than the open-syllable rhythm Spanish is quick for.',
  ),
  'cs': ReadingSpeed(
    slowWpm: 122,
    averageWpm: 168,
    fastWpm: 212,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'pl',
    note:
        'West Slavic beside Polish: the same seven cases and the same '
        'consonant clusters.',
  ),
  'cy': ReadingSpeed(
    slowWpm: 128,
    averageWpm: 172,
    fastWpm: 220,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'fr',
    note:
        'No Celtic language is measured. Reasoned from French for word length '
        'and lowered for initial mutation, which changes the letter a reader '
        'looks a word up by.',
  ),
  'da': ReadingSpeed(
    slowWpm: 145,
    averageWpm: 197,
    fastWpm: 255,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'sv',
    note:
        'Scandinavian beside Swedish, and the same on the page — the reduced '
        'pronunciation Danish is known for is not something a reader sees.',
  ),
  'de': ReadingSpeed(
    slowWpm: 140,
    averageWpm: 179,
    fastWpm: 215,
    evidence: SpeedEvidence.measured,
    note:
        'Compound words lower the words-per-minute without lowering '
        'comprehension: one German word is often two or three English ones.',
  ),
  'el': ReadingSpeed(
    slowWpm: 130,
    averageWpm: 180,
    fastWpm: 232,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'ru',
    note:
        'Its own alphabet and a full case system put the reading load with the '
        'inflected languages rather than with the Romance ones.',
  ),
  'en': ReadingSpeed(
    slowWpm: 175,
    averageWpm: 238,
    fastWpm: 300,
    evidence: SpeedEvidence.measured,
    note:
        'The anchor the rest of the table is read against: short words, little '
        'inflection, and by far the most-measured language.',
  ),
  'es': ReadingSpeed(
    slowWpm: 165,
    averageWpm: 218,
    fastWpm: 280,
    evidence: SpeedEvidence.measured,
    note:
        'A high syllabic rate: open syllables and a shallow orthography, so '
        'the words go by quickly even though there are more of them.',
  ),
  'et': ReadingSpeed(
    slowWpm: 128,
    averageWpm: 166,
    fastWpm: 205,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'fi',
    note:
        'Finnic like Finnish, and agglutinative like it, but with shorter '
        'words after the final vowels Estonian lost.',
  ),
  'eu': ReadingSpeed(
    slowWpm: 122,
    averageWpm: 158,
    fastWpm: 197,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'fi',
    note:
        'An isolate with no measured relative at all. Reasoned from Finnish '
        'for the property that matters: agglutinative, case-rich, long words.',
  ),
  'fa': ReadingSpeed(
    slowWpm: 115,
    averageWpm: 155,
    fastWpm: 198,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'ar',
    note:
        'Arabic script over Indo-European morphology: the visual cost of the '
        "script without Arabic's templatic word forms, so above Arabic.",
  ),
  'fi': ReadingSpeed(
    slowWpm: 125,
    averageWpm: 161,
    fastWpm: 200,
    evidence: SpeedEvidence.measured,
    note:
        'Agglutinative, and the long words are the whole story: fifteen cases '
        'stack into single words an English sentence would need a clause for.',
  ),
  'fr': ReadingSpeed(
    slowWpm: 145,
    averageWpm: 195,
    fastWpm: 250,
    evidence: SpeedEvidence.measured,
    note:
        'A deep orthography — many written letters are not pronounced — over '
        'otherwise moderate word lengths.',
  ),
  'gl': ReadingSpeed(
    slowWpm: 133,
    averageWpm: 185,
    fastWpm: 238,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'pt',
    note:
        'Galician-Portuguese, split in two: the same language for this '
        'purpose, with clearer vowels than European Portuguese.',
  ),
  'he': ReadingSpeed(
    slowWpm: 130,
    averageWpm: 187,
    fastWpm: 240,
    evidence: SpeedEvidence.measured,
    note:
        'Unvocalised script: the vowels are absent and the reader supplies '
        'them from context, which costs more than the short words save.',
  ),
  'hi': ReadingSpeed(
    slowWpm: 122,
    averageWpm: 170,
    fastWpm: 220,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'ru',
    note:
        "Devanagari's conjunct clusters carry a visual cost of the same order "
        "as Cyrillic's, over a comparably inflected grammar.",
  ),
  'hr': ReadingSpeed(
    slowWpm: 125,
    averageWpm: 178,
    fastWpm: 228,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'sl',
    note:
        'South Slavic beside Slovenian — the same case load, without the dual '
        'number Slovenian keeps.',
  ),
  'hu': ReadingSpeed(
    slowWpm: 120,
    averageWpm: 157,
    fastWpm: 195,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'fi',
    note:
        'Agglutinative like Finnish and with more cases still, so the words '
        'run longer and the count runs lower.',
  ),
  'hy': ReadingSpeed(
    slowWpm: 125,
    averageWpm: 172,
    fastWpm: 222,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'ru',
    note:
        'Its own alphabet and a full case system: the reading load sits with '
        'the inflected Indo-European languages.',
  ),
  'id': ReadingSpeed(
    slowWpm: 150,
    averageWpm: 200,
    fastWpm: 255,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'es',
    note:
        'Open syllables and no inflection, like Spanish; what keeps it below '
        'Spanish is the affixed forms, which are long.',
  ),
  'is': ReadingSpeed(
    slowWpm: 130,
    averageWpm: 178,
    fastWpm: 228,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'sv',
    note:
        'Scandinavian vocabulary with the full case system the mainland lost, '
        'which puts it nearer German than Swedish.',
  ),
  'it': ReadingSpeed(
    slowWpm: 140,
    averageWpm: 188,
    fastWpm: 240,
    evidence: SpeedEvidence.measured,
    note:
        'A shallow orthography and open syllables, over words longer than '
        "Spanish's.",
  ),
  'ja': ReadingSpeed(
    slowWpm: 135,
    averageWpm: 193,
    fastWpm: 250,
    slowCpm: 350,
    averageCpm: 400,
    fastCpm: 450,
    nativeScripts: {CountingScript.han, CountingScript.kana},
    evidence: SpeedEvidence.measured,
    note:
        'Written without spaces, so it is counted by the character. Two '
        'scripts at once — kanji carrying the content, kana the grammar — and '
        'both are read at this rate, which is above what isolated Han costs.',
  ),
  'km': ReadingSpeed(
    slowWpm: 150,
    averageWpm: kFallbackWordsPerMinute,
    fastWpm: 250,
    slowCpm: 180,
    averageCpm: 220,
    fastCpm: 270,
    nativeScripts: {CountingScript.khmer},
    evidence: SpeedEvidence.derived,
    derivedFrom: 'zh',
    note:
        'Reasoned from Chinese not by any relation but by the property that '
        'decides the unit: no spaces between words, so it is counted by the '
        'character. Slower than Thai for the stacked subscript consonants. '
        'The words-per-minute figure is the global default and applies only to '
        'spaced text quoted inside it.',
  ),
  'ko': ReadingSpeed(
    slowWpm: 125,
    averageWpm: 170,
    fastWpm: 218,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'tr',
    note:
        'Agglutinative like Turkish. **Counted by the word, not the '
        'character**: Hangul looks East Asian but is spaced, by eojeol rather '
        'than by word, so it has no character rate at all.',
  ),
  'la': ReadingSpeed(
    slowWpm: 120,
    averageWpm: 162,
    fastWpm: 208,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'it',
    note:
        "Italian's ancestor with the case system intact, which costs about "
        'what it costs German.',
  ),
  'lij': ReadingSpeed(
    slowWpm: 138,
    averageWpm: 185,
    fastWpm: 236,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'it',
    note: 'Gallo-Italic beside Italian, and much the same word length.',
  ),
  'lt': ReadingSpeed(
    slowWpm: 118,
    averageWpm: 160,
    fastWpm: 205,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'pl',
    note:
        'Baltic rather than Slavic, but reasoned from Polish for what they '
        'share: a heavy case load and long words.',
  ),
  'lv': ReadingSpeed(
    slowWpm: 120,
    averageWpm: 163,
    fastWpm: 207,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'pl',
    note:
        'Baltic beside Lithuanian, with slightly shorter words after the '
        'endings Latvian shed.',
  ),
  'mn': ReadingSpeed(
    slowWpm: 118,
    averageWpm: 160,
    fastWpm: 207,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'tr',
    note:
        'Agglutinative like Turkish and written in Cyrillic; the suffix chains '
        'run longer than Turkish ones.',
  ),
  'ms': ReadingSpeed(
    slowWpm: 150,
    averageWpm: 200,
    fastWpm: 255,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'es',
    note:
        'Malay and Indonesian are one language for this purpose: open '
        'syllables and no inflection, like Spanish, held below it by '
        'affixation.',
  ),
  'nb': ReadingSpeed(
    slowWpm: 145,
    averageWpm: 198,
    fastWpm: 258,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'sv',
    note:
        "Scandinavian beside Swedish; Bokmål's Danish-derived spelling changes "
        'nothing about the reading.',
  ),
  'nl': ReadingSpeed(
    slowWpm: 150,
    averageWpm: 202,
    fastWpm: 260,
    evidence: SpeedEvidence.measured,
    note:
        'Germanic compounding like German, but less of it, and a shallower '
        'orthography.',
  ),
  'nn': ReadingSpeed(
    slowWpm: 143,
    averageWpm: 196,
    fastWpm: 255,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'sv',
    note:
        'Scandinavian beside Swedish, a little below Bokmål for the fuller '
        'inflection Nynorsk keeps.',
  ),
  'pa': ReadingSpeed(
    slowWpm: 112,
    averageWpm: 152,
    fastWpm: 193,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'ar',
    note:
        'Shahmukhi: Arabic script over Indic morphology, so the script cost '
        "without Arabic's word formation.",
  ),
  'pl': ReadingSpeed(
    slowWpm: 120,
    averageWpm: 166,
    fastWpm: 210,
    evidence: SpeedEvidence.measured,
    note:
        'High consonant density — digraph-heavy spelling and clusters that '
        'take longer to resolve than their letter count suggests.',
  ),
  'pt': ReadingSpeed(
    slowWpm: 130,
    averageWpm: 181,
    fastWpm: 235,
    evidence: SpeedEvidence.measured,
    note:
        'Romance, with vowel reduction and nasalisation that make the '
        'orthography deeper than Spanish or Italian.',
  ),
  'ro': ReadingSpeed(
    slowWpm: 135,
    averageWpm: 182,
    fastWpm: 233,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'it',
    note:
        'Romance beside Italian, with a case system and suffixed articles no '
        'other Romance language kept.',
  ),
  'ru': ReadingSpeed(
    slowWpm: 130,
    averageWpm: 184,
    fastWpm: 240,
    evidence: SpeedEvidence.measured,
    note:
        'Cyrillic over six cases: longer words than the Romance languages, and '
        'free word order that has to be resolved from the endings.',
  ),
  'sk': ReadingSpeed(
    slowWpm: 122,
    averageWpm: 168,
    fastWpm: 213,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'pl',
    note: 'West Slavic beside Czech and Polish, and the same case load.',
  ),
  'sl': ReadingSpeed(
    slowWpm: 125,
    averageWpm: 180,
    fastWpm: 230,
    evidence: SpeedEvidence.measured,
    note:
        'South Slavic, with six cases and a dual number on top of them, over '
        'moderate word lengths.',
  ),
  'sr': ReadingSpeed(
    slowWpm: 125,
    averageWpm: 178,
    fastWpm: 228,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'sl',
    note:
        'South Slavic beside Croatian and Slovenian, and the same figure in '
        'either script — Cyrillic and Latin are one language here.',
  ),
  'sv': ReadingSpeed(
    slowWpm: 145,
    averageWpm: 199,
    fastWpm: 260,
    evidence: SpeedEvidence.measured,
    note:
        'Germanic compounding over a shallow orthography and little '
        'inflection.',
  ),
  'th': ReadingSpeed(
    slowWpm: 150,
    averageWpm: kFallbackWordsPerMinute,
    fastWpm: 250,
    slowCpm: 200,
    averageCpm: 250,
    fastCpm: 310,
    nativeScripts: {CountingScript.thai},
    evidence: SpeedEvidence.derived,
    derivedFrom: 'zh',
    note:
        'Reasoned from Chinese not by any relation but by the property that '
        'decides the unit: no spaces between words, so it is counted by the '
        'character. The words-per-minute figure is the global default and '
        'applies only to spaced text quoted inside it.',
  ),
  'tl': ReadingSpeed(
    slowWpm: 148,
    averageWpm: 198,
    fastWpm: 253,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'es',
    note:
        'Open syllables like Spanish, held below it by affixation and '
        'reduplication, both of which lengthen words.',
  ),
  'tr': ReadingSpeed(
    slowWpm: 120,
    averageWpm: 166,
    fastWpm: 215,
    evidence: SpeedEvidence.measured,
    note:
        'Agglutinative grammar: suffixes chain into words that carry what '
        'other languages spread over a phrase.',
  ),
  'uk': ReadingSpeed(
    slowWpm: 130,
    averageWpm: 183,
    fastWpm: 238,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'ru',
    note:
        'East Slavic beside Russian — the same case load and the same script.',
  ),
  'vi': ReadingSpeed(
    slowWpm: 215,
    averageWpm: 290,
    fastWpm: 370,
    evidence: SpeedEvidence.derived,
    derivedFrom: 'es',
    note:
        '**Spaced by syllable rather than by word.** A whitespace split '
        'returns about a third more tokens than another language would for the '
        'same meaning, so the rate is raised by roughly that much and the '
        'duration comes out right. The token count does not compare to any '
        'other entry here. The least certain figure in the table: the ratio '
        'varies with how many function words the other language spends, and a '
        'parallel passage can come out anywhere from evens to half again.',
  ),
  'zh': ReadingSpeed(
    slowWpm: 120,
    averageWpm: 158,
    fastWpm: 200,
    slowCpm: 255,
    averageCpm: 300,
    fastCpm: 350,
    nativeScripts: {CountingScript.han},
    evidence: SpeedEvidence.measured,
    note:
        'Written without spaces, so it is counted by the character. One '
        'character carries about as much as a short English word, which is why '
        'the characters-per-minute figure looks low beside a word count.',
  ),
};

/// Looking a language up, and reducing a tag to one this table knows.
abstract final class ReadingSpeeds {
  const ReadingSpeeds._();

  /// Every language subtag with an entry, in alphabetical order.
  static Iterable<String> get languages => _speeds.keys;

  /// The language subtag [tag] means, whatever it was spelled like.
  ///
  /// Everything hands a language over differently — a platform gives
  /// `en_US.UTF-8`, a document written by hand gives `en`, a browser gives
  /// `zh-Hans-CN`. So the tail after `.` or `@` goes, `_` becomes `-`, case
  /// stops mattering, and what is left of the first subtag is the answer.
  ///
  /// It does **not** check the result is in the table — that is [lookUp]'s
  /// job. `qq` comes back as `qq`, because a caller asking what language a tag
  /// names is asking a different question from one asking how fast it reads.
  static String? languageOf(String tag) {
    var text = tag.trim();
    for (final separator in const <String>['.', '@']) {
      final cut = text.indexOf(separator);
      if (cut >= 0) text = text.substring(0, cut);
    }
    text = text.replaceAll('_', '-');
    if (text.isEmpty) return null;

    final language = text.split('-').first.toLowerCase();
    return language.isEmpty ? null : language;
  }

  /// The speed for [tag], or null when this table has never heard of it.
  ///
  /// Null rather than the fallback, so a caller that wants to know whether the
  /// language is covered can ask. [of] is the one that always answers.
  static ReadingSpeed? lookUp(String tag) {
    final language = languageOf(tag);
    return language == null ? null : _speeds[language];
  }

  /// The speed for [tag], falling back to [kFallbackSpeed].
  ///
  /// A null [tag] is the same as an unknown one: the caller did not say, so
  /// the global default is the honest answer. It is marked
  /// [SpeedEvidence.fallback] either way, so nothing downstream has to guess
  /// whether the number meant anything.
  static ReadingSpeed of(String? tag) {
    if (tag == null) return kFallbackSpeed;
    return lookUp(tag) ?? kFallbackSpeed;
  }
}
