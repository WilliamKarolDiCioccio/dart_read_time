import 'package:dart_read_time/dart_read_time.dart';
import 'package:test/test.dart';

void main() {
  /// A span over the first occurrence of [needle] in [text].
  LanguageSpan spanOf(String text, String needle, String language) {
    final start = text.indexOf(needle);
    if (start < 0) throw ArgumentError('"$needle" is not in the text');
    return LanguageSpan(
      start: start,
      end: start + needle.length,
      language: language,
    );
  }

  group('pricing a span', () {
    test('a stretch in another language is read at that language rate', () {
      const text = 'one two three four five six seven eight';
      final spans = <LanguageSpan>[spanOf(text, 'five six seven eight', 'fi')];

      final mixed = estimateSpannedReadTime(
        text,
        spans,
        options: const ReadTimeOptions(language: 'en'),
      );
      final allEnglish = estimateReadTime(
        text,
        options: const ReadTimeOptions(language: 'en'),
      );

      expect(
        mixed.duration,
        greaterThan(allEnglish.duration),
        reason:
            'four of the eight words are Finnish, which is read at 161 words '
            'a minute rather than 238',
      );
      expect(mixed.words, allEnglish.words, reason: 'the same eight words');
    });

    test('the halves are priced separately and added', () {
      const text = 'one two three four';
      final spans = <LanguageSpan>[spanOf(text, 'three four', 'fi')];

      final mixed = estimateSpannedReadTime(
        text,
        spans,
        options: const ReadTimeOptions(language: 'en'),
      );
      final english = estimateReadTime(
        'one two',
        options: const ReadTimeOptions(language: 'en'),
      );
      final finnish = estimateReadTime(
        'three four',
        options: const ReadTimeOptions(language: 'fi'),
      );

      expect(
        mixed.duration.inMilliseconds,
        closeTo(
          english.duration.inMilliseconds + finnish.duration.inMilliseconds,
          2,
        ),
      );
    });

    test('no spans is the same answer as no spans API', () {
      const text = 'You arrive at the gate.';
      expect(
        estimateSpannedReadTime(
          text,
          const <LanguageSpan>[],
          options: const ReadTimeOptions(language: 'en'),
        ).duration,
        estimateReadTime(
          text,
          options: const ReadTimeOptions(language: 'en'),
        ).duration,
        reason: 'handing over nothing is the off switch, and costs nothing',
      );
    });

    test('a gap falls to the language of the document', () {
      const text = 'one two three four';
      final spans = <LanguageSpan>[spanOf(text, 'three', 'fi')];

      final estimate = estimateSpannedReadTime(
        text,
        spans,
        options: const ReadTimeOptions(language: 'en'),
      );

      expect(estimate.byLanguage.keys, containsAll(<String>['en', 'fi']));
      expect(estimate.words, 4);
    });

    test("with no document language, uncovered text is nobody's", () {
      const text = 'one two three four';
      final estimate = estimateSpannedReadTime(text, <LanguageSpan>[
        spanOf(text, 'three four', 'fi'),
      ]);

      expect(
        estimate.byLanguage.keys,
        <String>['fi'],
        reason:
            'the rest was priced by the global default, and the global '
            'default is not a language',
      );
      expect(
        estimate.byLanguage['fi'],
        lessThan(estimate.duration),
        reason: 'so the entries do not sum to the whole',
      );
    });
  });

  group('what the caller is allowed to hand over', () {
    const text = 'one two three four five six';

    test('spans out of order are sorted', () {
      final forwards = estimateSpannedReadTime(text, <LanguageSpan>[
        spanOf(text, 'one two', 'fi'),
        spanOf(text, 'five six', 'de'),
      ], options: const ReadTimeOptions(language: 'en'));
      final backwards = estimateSpannedReadTime(text, <LanguageSpan>[
        spanOf(text, 'five six', 'de'),
        spanOf(text, 'one two', 'fi'),
      ], options: const ReadTimeOptions(language: 'en'));

      expect(forwards.duration, backwards.duration);
      expect(forwards.byLanguage, backwards.byLanguage);
    });

    test('an overlap is settled in favour of the earlier span', () {
      // 'one two three' and then an overlapping span from inside it. Both
      // boundaries fall on spaces, so no word is cut.
      final estimate = estimateSpannedReadTime(text, <LanguageSpan>[
        const LanguageSpan(start: 0, end: 13, language: 'fi'),
        const LanguageSpan(start: 8, end: 18, language: 'de'),
      ], options: const ReadTimeOptions(language: 'en'));

      expect(
        estimate.words,
        6,
        reason: 'nothing is counted twice, whatever the caller overlapped',
      );
      expect(estimate.byLanguage.keys, containsAll(<String>['fi', 'de', 'en']));
    });

    test('a boundary through the middle of a word splits that word', () {
      final estimate = estimateSpannedReadTime(text, <LanguageSpan>[
        const LanguageSpan(start: 0, end: 10, language: 'fi'),
      ], options: const ReadTimeOptions(language: 'en'));

      expect(
        estimate.words,
        7,
        reason:
            'the span ends inside "three", so its halves are counted as two. '
            'Inherent to cutting a string at an offset rather than a fault: a '
            'caller segmenting by sentence or paragraph never lands here, and '
            'one that lands here has told us the two halves are in different '
            'languages',
      );
    });

    test('an out-of-range span is clamped rather than thrown at', () {
      final estimate = estimateSpannedReadTime(text, <LanguageSpan>[
        LanguageSpan(start: -50, end: text.length + 50, language: 'fi'),
      ], options: const ReadTimeOptions(language: 'en'));

      expect(estimate.words, 6);
      expect(
        estimate.byLanguage.keys,
        <String>['fi'],
        reason:
            'a detector handing over a stale offset should not throw '
            'underneath a caller who can do nothing about it',
      );
    });

    test('an empty or inverted span is dropped', () {
      final estimate = estimateSpannedReadTime(text, <LanguageSpan>[
        const LanguageSpan(start: 4, end: 4, language: 'fi'),
        const LanguageSpan(start: 10, end: 2, language: 'de'),
      ], options: const ReadTimeOptions(language: 'en'));

      expect(estimate.byLanguage.keys, <String>['en']);
      expect(estimate.words, 6);
    });
  });

  group('spans change the rate and never the unit', () {
    test('Korean called Chinese is still counted by the word', () {
      const korean = '그는 어두운 복도를 걸어가 문 앞에서 멈춰 섰다.';

      final right = estimateSpannedReadTime(korean, <LanguageSpan>[
        LanguageSpan(start: 0, end: korean.length, language: 'ko'),
      ]);
      final wrong = estimateSpannedReadTime(korean, <LanguageSpan>[
        LanguageSpan(start: 0, end: korean.length, language: 'zh'),
      ]);

      expect(wrong.words, right.words, reason: 'both count eight eojeol');
      expect(wrong.characters, 0);
      expect(
        wrong.duration.inMilliseconds / right.duration.inMilliseconds,
        closeTo(1, 0.15),
        reason:
            'the detectors a caller reaches for are documented to confuse '
            'these two. Because the script decides the unit and the span only '
            'decides the rate, getting it wrong costs the gap between 158 and '
            '170 words a minute rather than a factor of three',
      );
    });

    test('Chinese called Korean is still counted by the character', () {
      const chinese = '他走过昏暗的走廊，在门前停了下来。';

      final right = estimateSpannedReadTime(chinese, <LanguageSpan>[
        LanguageSpan(start: 0, end: chinese.length, language: 'zh'),
      ]);
      final wrong = estimateSpannedReadTime(chinese, <LanguageSpan>[
        LanguageSpan(start: 0, end: chinese.length, language: 'ko'),
      ]);

      expect(wrong.characters, right.characters);
      expect(wrong.words, 0);
      expect(
        wrong.duration,
        right.duration,
        reason:
            'Korean owns no space-less script, so Han falls to what Han costs '
            'in general — which is the same 300 a minute Chinese is priced at',
      );
    });

    test('a Japanese span inside English prose is counted by character', () {
      const text = 'The sign read 彼は暗い廊下を歩いて and nothing else.';
      final estimate = estimateSpannedReadTime(text, <LanguageSpan>[
        spanOf(text, '彼は暗い廊下を歩いて', 'ja'),
      ], options: const ReadTimeOptions(language: 'en'));

      expect(estimate.words, 6, reason: 'The sign read / and nothing else.');
      expect(estimate.characters, 10);
      expect(estimate.isMixedScript, isTrue);
    });
  });

  group('what the answer says about itself', () {
    const text = 'one two three four five six seven eight';

    test('it names the languages it drew on, and the biggest one', () {
      final estimate = estimateSpannedReadTime(text, <LanguageSpan>[
        spanOf(text, 'seven eight', 'fi'),
      ], options: const ReadTimeOptions(language: 'en'));

      expect(estimate.isMultilingual, isTrue);
      expect(
        estimate.dominantLanguage,
        'en',
        reason: 'six of the eight words are English',
      );
    });

    test('a single language is not multilingual', () {
      final estimate = estimateReadTime(
        text,
        options: const ReadTimeOptions(language: 'en'),
      );

      expect(estimate.isMultilingual, isFalse);
      expect(estimate.dominantLanguage, 'en');
      expect(
        estimate.byLanguage['en'],
        estimate.duration,
        reason:
            'the plain estimate fills this in too, so a caller reading it '
            'does not have to know which function produced the answer',
      );
    });

    test('naming no language names nothing', () {
      final estimate = estimateReadTime(text);

      expect(estimate.byLanguage, isEmpty);
      expect(estimate.dominantLanguage, isNull);
      expect(estimate.isMultilingual, isFalse);
    });

    test('the tag is kept as the caller wrote it', () {
      final estimate = estimateSpannedReadTime(text, <LanguageSpan>[
        spanOf(text, 'seven eight', 'fr-CA'),
      ], options: const ReadTimeOptions(language: 'en-US'));

      expect(
        estimate.byLanguage.keys,
        containsAll(<String>['en-US', 'fr-CA']),
        reason:
            'reducing these to en and fr would hand back something the caller '
            'has to map to a name all over again',
      );
    });
  });

  group('markdown, with spans over the source', () {
    test('the offsets index the markdown rather than the prose', () {
      const markdown =
          'Read this.\n\n```dart\nfinal ignored = 1;\n```\n\nUn peu de francais ici.';
      final french = markdown.indexOf('Un peu');

      final estimate = estimateSpannedMarkdownReadTime(markdown, <LanguageSpan>[
        LanguageSpan(start: french, end: markdown.length, language: 'fr'),
      ], options: const ReadTimeOptions(language: 'en'));

      expect(
        estimate.words,
        7,
        reason: 'Read this. plus five French words, and no code',
      );
      expect(
        estimate.byLanguage.keys,
        containsAll(<String>['en', 'fr']),
        reason:
            'the span was written against the source, and the fence between '
            'the two halves did not shift it',
      );
    });

    test('no spans is the same answer as the plain markdown estimate', () {
      const markdown = '## A heading\n\nSome `code` and [a link](/url).';
      expect(
        estimateSpannedMarkdownReadTime(
          markdown,
          const <LanguageSpan>[],
          options: const ReadTimeOptions(language: 'en'),
        ).duration,
        estimateMarkdownReadTime(
          markdown,
          options: const ReadTimeOptions(language: 'en'),
        ).duration,
      );
    });
  });
}
