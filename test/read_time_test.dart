import 'package:dart_read_time/dart_read_time.dart';
import 'package:test/test.dart';

void main() {
  /// [count] words of nothing in particular. Length is the only property any
  /// of these tests cares about.
  String words(int count) => List<String>.filled(count, 'word').join(' ');

  /// A paragraph of Japanese — no spaces anywhere in it, which is the whole
  /// reason this package exists.
  const japanese =
      '彼は暗い廊下を歩いて、扉の前で立ち止まった。'
      '扉の向こうから物音が聞こえたが、誰の声かは分からなかった。'
      '手を伸ばして、冷たい取っ手をゆっくりと回した。';

  /// The same length of Korean, which looks like it belongs with the above and
  /// does not.
  const korean =
      '그는 어두운 복도를 걸어가 문 앞에서 멈춰 섰다. '
      '문 너머에서 소리가 들렸지만 누구의 목소리인지 알 수 없었다. '
      '손을 뻗어 차가운 손잡이를 천천히 돌렸다.';

  ReadTime read(String text, {String? language, ReadingPace? pace}) =>
      estimateReadTime(
        text,
        options: ReadTimeOptions(
          language: language,
          pace: pace ?? ReadingPace.medium,
        ),
      );

  group('the anchor', () {
    test('238 English words is about a minute', () {
      final estimate = estimateReadTime(
        words(238),
        options: const ReadTimeOptions(language: 'en'),
      );
      expect(
        estimate.duration.inSeconds,
        60,
        reason:
            'The adult average for English is the number the whole table is '
            'anchored on, so this one has to be exact.',
      );
      expect(estimate.roundedMinutes, 1);
      expect(estimate.speed.evidence, SpeedEvidence.measured);
    });

    test('a language with longer words takes longer per word', () {
      final english = read(words(200), language: 'en');
      final finnish = read(words(200), language: 'fi');
      expect(
        finnish.duration,
        greaterThan(english.duration),
        reason:
            'Fewer Finnish words carry the same meaning, so the same *count* '
            'of them is more to read.',
      );
    });
  });

  group('space-less scripts', () {
    test('a Japanese paragraph is not counted as one word', () {
      final estimate = read(japanese, language: 'ja');
      expect(estimate.words, 0);
      expect(estimate.characters, greaterThan(50));
      expect(
        estimate.duration.inSeconds,
        greaterThan(8),
        reason:
            'A whitespace split would find one token here and answer well '
            'under a second.',
      );
    });

    test('Korean of the same weight is counted by the word', () {
      final estimate = read(korean, language: 'ko');
      expect(estimate.characters, 0);
      expect(estimate.words, greaterThan(10));
      expect(estimate.duration.inSeconds, greaterThan(4));
    });

    test('kanji reads faster inside Japanese than quoted in English', () {
      const quoted = '曹操曹操曹操曹操曹操曹操曹操曹操曹操曹操';
      final inJapanese = read(quoted, language: 'ja');
      final inEnglish = read(quoted, language: 'en');
      expect(
        inJapanese.duration,
        lessThan(inEnglish.duration),
        reason:
            'Han is a native script of Japanese and is priced by the Japanese '
            'entry; in English prose the same characters are a quotation and '
            'fall to what Han costs in general.',
      );
    });

    test('a script the language does not own is not priced by it', () {
      const quoted = '曹操曹操曹操曹操曹操';
      expect(
        read(quoted, language: 'th').duration,
        read(quoted, language: 'en').duration,
        reason:
            'Thai owns Thai, not Han. A Han run inside Thai prose is a '
            'quotation and costs what a quotation costs anywhere else.',
      );
    });
  });

  group('mixed script', () {
    test('reports both counts and lands between the two single answers', () {
      const mixed = '彼は Tokyo Tower を見た。';
      final estimate = read(mixed, language: 'ja');
      expect(estimate.isMixedScript, isTrue);
      expect(estimate.words, 2);
      expect(estimate.characters, 5);
      expect(estimate.duration, greaterThan(Duration.zero));
    });

    test('English prose quoting a Chinese name counts both', () {
      final estimate = read('The general 曹操 waited.', language: 'en');
      expect(estimate.words, 3);
      expect(estimate.characters, 2);
      expect(estimate.isMixedScript, isTrue);
    });

    test('the two halves add up rather than one winning', () {
      const latin = 'Tokyo Tower';
      const han = '彼は見た';
      final both = read('$latin $han', language: 'ja');
      final justLatin = read(latin, language: 'ja');
      final justHan = read(han, language: 'ja');
      expect(
        both.duration.inMilliseconds,
        closeTo(
          justLatin.duration.inMilliseconds + justHan.duration.inMilliseconds,
          2,
        ),
        reason: 'Each run is priced in its own unit and the durations sum.',
      );
    });
  });

  group('pace and density', () {
    test('skimming is quicker and studying is slower', () {
      final slow = read(words(200), language: 'en', pace: ReadingPace.slow);
      final medium = read(words(200), language: 'en');
      final fast = read(words(200), language: 'en', pace: ReadingPace.fast);
      expect(fast.duration, lessThan(medium.duration));
      expect(medium.duration, lessThan(slow.duration));
    });

    test('a dense document takes longer, not less', () {
      final plain = estimateReadTime(
        words(200),
        options: const ReadTimeOptions(language: 'en'),
      );
      final technical = estimateReadTime(
        words(200),
        options: const ReadTimeOptions(
          language: 'en',
          contentMultiplier: ContentKind.technical,
        ),
      );
      final fiction = estimateReadTime(
        words(200),
        options: const ReadTimeOptions(
          language: 'en',
          contentMultiplier: ContentKind.fiction,
        ),
      );
      expect(
        technical.duration,
        greaterThan(plain.duration),
        reason:
            'The multiplier scales the speed, so 0.8 is slower reading and a '
            'longer estimate. Getting this backwards is the easy mistake.',
      );
      expect(fiction.duration, lessThan(plain.duration));
    });

    test('the multiplier reaches the character count as well', () {
      final plain = estimateReadTime(
        japanese,
        options: const ReadTimeOptions(language: 'ja'),
      );
      final technical = estimateReadTime(
        japanese,
        options: const ReadTimeOptions(
          language: 'ja',
          contentMultiplier: ContentKind.technical,
        ),
      );
      expect(technical.duration, greaterThan(plain.duration));
    });

    test('a multiplier of zero is refused rather than answered', () {
      expect(
        () => ReadTimeOptions(
          language: 'en',
          contentMultiplier: double.parse('0'),
        ),
        throwsA(isA<AssertionError>()),
        reason:
            'The assert fires first and is the one a developer sees. The '
            'estimator carries a second guard that throws an ArgumentError, '
            'for the release build where asserts are stripped and a zero rate '
            'would otherwise reach Duration as an infinity — which cannot be '
            'reached from here, because asserts are on under `dart test`.',
      );
    });
  });

  group('falling back', () {
    test('an unmapped spaced language is 200 words a minute', () {
      final estimate = estimateReadTime(
        words(200),
        options: const ReadTimeOptions(language: 'qq-ZZ'),
      );
      expect(estimate.speed.evidence, SpeedEvidence.fallback);
      expect(estimate.duration.inSeconds, 60);
    });

    test('an unmapped language writing Han is still counted by character', () {
      final estimate = estimateReadTime(
        '曹操曹操曹操曹操曹操曹操曹操曹操曹操曹操',
        options: const ReadTimeOptions(language: 'qq-ZZ'),
      );
      expect(estimate.words, 0);
      expect(estimate.characters, 20);
      expect(
        estimate.duration.inSeconds,
        4,
        reason:
            'Twenty characters at the stated 300 CPM default. The tag was no '
            'help; the script was.',
      );
    });

    test('naming no language at all still works', () {
      final estimate = estimateReadTime(words(200));
      expect(estimate.speed.evidence, SpeedEvidence.fallback);
      expect(estimate.duration.inSeconds, 60);
    });
  });

  group('markdown', () {
    test('a document that is mostly code costs almost nothing', () {
      final markdown = 'Here:\n\n```dart\n${words(500)}\n```\n\nDone.';
      final estimate = estimateMarkdownReadTime(
        markdown,
        options: const ReadTimeOptions(language: 'en'),
      );
      expect(estimate.words, 2, reason: 'Only "Here:" and "Done." are prose.');
    });

    test('an image path is not worth a word', () {
      final estimate = estimateMarkdownReadTime(
        '![](../art/map.png)',
        options: const ReadTimeOptions(language: 'en'),
      );
      expect(estimate.words, 0);
      expect(estimate.duration, Duration.zero);
    });

    test('a link is worth its text and not its URL', () {
      final estimate = estimateMarkdownReadTime(
        'See [the map](https://example.com/a/very/long/path/indeed).',
        options: const ReadTimeOptions(language: 'en'),
      );
      expect(estimate.words, 3, reason: 'See, the, map.');
    });
  });

  group('rounding', () {
    test('nothing to read is nothing', () {
      final estimate = estimateReadTime('');
      expect(estimate.duration, Duration.zero);
      expect(estimate.roundedMinutes, 0);
      expect(estimate.counts.isEmpty, isTrue);
    });

    test('whitespace is nothing too', () {
      expect(estimateReadTime('   \n\t ').roundedMinutes, 0);
    });

    test('something short is one minute rather than none', () {
      final estimate = estimateReadTime(
        'Three words here.',
        options: const ReadTimeOptions(language: 'en'),
      );
      expect(estimate.duration.inSeconds, lessThan(30));
      expect(
        estimate.roundedMinutes,
        1,
        reason:
            '"Less than a minute" is a sentence the caller writes; this is a '
            'count of minutes, and zero would be a lie about a passage that '
            'has words in it.',
      );
    });
  });

  test('the estimate carries its own provenance', () {
    final estimate = estimateReadTime(
      words(10),
      options: const ReadTimeOptions(language: 'da'),
    );
    expect(estimate.speed.evidence, SpeedEvidence.derived);
    expect(estimate.speed.derivedFrom, 'sv');
  });

  test('options copy one field at a time', () {
    const base = ReadTimeOptions(language: 'en');
    final faster = base.copyWith(pace: ReadingPace.fast);
    expect(faster.language, 'en');
    expect(faster.pace, ReadingPace.fast);
    expect(faster.contentMultiplier, ContentKind.prose);
  });
}
