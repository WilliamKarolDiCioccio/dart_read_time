import 'package:dart_read_time/dart_read_time.dart';
import 'package:test/test.dart';

void main() {
  /// Every entry in the table, so a rule can be asserted of all of them at
  /// once rather than of whichever were remembered.
  Iterable<MapEntry<String, ReadingSpeed>> entries() => ReadingSpeeds.languages
      .map((language) => MapEntry(language, ReadingSpeeds.lookUp(language)!));

  group('the table itself', () {
    test('carries fifty-four languages', () {
      expect(ReadingSpeeds.languages, hasLength(54));
    });

    test('is seventeen measured and thirty-seven derived', () {
      final measured = entries().where(
        (entry) => entry.value.evidence == SpeedEvidence.measured,
      );
      final derived = entries().where(
        (entry) => entry.value.evidence == SpeedEvidence.derived,
      );
      expect(measured, hasLength(17));
      expect(derived, hasLength(37));
      expect(
        entries().where(
          (entry) => entry.value.evidence == SpeedEvidence.fallback,
        ),
        isEmpty,
        reason: 'The fallback is not a language and does not belong in here.',
      );
    });

    test('orders every band, in both units', () {
      for (final entry in entries()) {
        final speed = entry.value;
        expect(
          speed.slowWpm,
          lessThan(speed.mediumWpm),
          reason: '${entry.key} words',
        );
        expect(
          speed.mediumWpm,
          lessThan(speed.fastWpm),
          reason: '${entry.key} words',
        );
        if (speed.mediumCpm != null) {
          expect(
            speed.slowCpm!,
            lessThan(speed.mediumCpm!),
            reason: '${entry.key} characters',
          );
          expect(
            speed.mediumCpm!,
            lessThan(speed.fastCpm!),
            reason: '${entry.key} characters',
          );
        }
      }
    });

    test('says something about every language', () {
      for (final entry in entries()) {
        expect(entry.value.note, isNotEmpty, reason: entry.key);
      }
    });
  });

  group('what a derived entry rests on', () {
    test('names a language that is in the table and was measured', () {
      for (final entry in entries()) {
        if (entry.value.evidence != SpeedEvidence.derived) continue;
        final source = entry.value.derivedFrom;
        expect(source, isNotNull, reason: '${entry.key} says nothing');
        final parent = ReadingSpeeds.lookUp(source!);
        expect(parent, isNotNull, reason: '${entry.key} points at $source');
        expect(
          parent!.evidence,
          SpeedEvidence.measured,
          reason:
              '${entry.key} is derived from $source, which is itself not '
              'measured — a chain of extrapolations is a guess wearing a '
              'citation.',
        );
      }
    });

    test('a measured entry claims no source', () {
      for (final entry in entries()) {
        if (entry.value.evidence != SpeedEvidence.measured) continue;
        expect(entry.value.derivedFrom, isNull, reason: entry.key);
      }
    });
  });

  group('which unit a language is counted in', () {
    test('a character rate and native scripts arrive together', () {
      for (final entry in entries()) {
        final speed = entry.value;
        expect(
          speed.mediumCpm != null,
          speed.nativeScripts.isNotEmpty,
          reason:
              '${entry.key} has one of a character rate and a native script '
              'without the other, so a run in that script would be priced by '
              'the wrong table.',
        );
        expect(
          speed.slowCpm == null,
          speed.mediumCpm == null,
          reason: '${entry.key} has a partial character rate',
        );
        expect(speed.fastCpm == null, speed.mediumCpm == null);
      }
    });

    test('exactly the space-less languages are counted by character', () {
      final byCharacter = entries()
          .where((entry) => entry.value.primaryUnit == ReadingUnit.characters)
          .map((entry) => entry.key)
          .toList();
      expect(byCharacter, unorderedEquals(<String>['ja', 'km', 'th', 'zh']));
    });

    test('Korean is counted by the word', () {
      final korean = ReadingSpeeds.lookUp('ko')!;
      expect(
        korean.primaryUnit,
        ReadingUnit.words,
        reason:
            'Hangul is spaced. This is the entry most likely to be filed with '
            'Chinese and Japanese by somebody going on appearance.',
      );
      expect(korean.nativeScripts, isEmpty);
    });

    test('Japanese owns both of its scripts', () {
      expect(ReadingSpeeds.lookUp('ja')!.nativeScripts, <CountingScript>{
        CountingScript.han,
        CountingScript.kana,
      });
    });
  });

  group('reducing a tag', () {
    test('takes the language off a locale', () {
      expect(ReadingSpeeds.languageOf('pt-BR'), 'pt');
      expect(ReadingSpeeds.languageOf('pt-PT'), 'pt');
      expect(ReadingSpeeds.languageOf('PT'), 'pt');
      expect(ReadingSpeeds.languageOf('sr-Latn-RS'), 'sr');
      expect(ReadingSpeeds.languageOf('zh-Hans-CN'), 'zh');
    });

    test('survives the shapes a platform hands over', () {
      expect(ReadingSpeeds.languageOf('en_US.UTF-8'), 'en');
      expect(ReadingSpeeds.languageOf('it_IT@euro'), 'it');
      expect(ReadingSpeeds.languageOf('  de-DE  '), 'de');
    });

    test('answers nothing for nothing', () {
      expect(ReadingSpeeds.languageOf(''), isNull);
      expect(ReadingSpeeds.languageOf('   '), isNull);
      expect(ReadingSpeeds.languageOf('.UTF-8'), isNull);
    });

    test('does not vouch for what it reduces to', () {
      expect(
        ReadingSpeeds.languageOf('qq-ZZ'),
        'qq',
        reason:
            'Naming the language a tag means is a different question from '
            'knowing how fast it reads.',
      );
      expect(ReadingSpeeds.lookUp('qq-ZZ'), isNull);
    });
  });

  group('looking one up', () {
    test('every dialect of a language reaches the one entry', () {
      expect(ReadingSpeeds.of('pt-BR'), same(ReadingSpeeds.of('pt-PT')));
      expect(ReadingSpeeds.of('zh-CN'), same(ReadingSpeeds.of('zh-TW')));
      expect(
        ReadingSpeeds.of('sr-Cyrl-RS'),
        same(ReadingSpeeds.of('sr-Latn-RS')),
      );
    });

    test('an unknown tag falls back, and says so', () {
      final speed = ReadingSpeeds.of('qq-ZZ');
      expect(speed.evidence, SpeedEvidence.fallback);
      expect(speed.mediumWpm, kFallbackWordsPerMinute);
    });

    test('no tag at all is the same as an unknown one', () {
      expect(ReadingSpeeds.of(null), same(kFallbackSpeed));
    });

    test('the fallback has no character rate of its own', () {
      expect(
        kFallbackSpeed.mediumCpm,
        isNull,
        reason:
            'Space-less text is caught by its script rather than by its tag, '
            'so the fallback does not need to guess at one.',
      );
      expect(kFallbackSpeed.nativeScripts, isEmpty);
    });
  });

  group('what a script costs on its own', () {
    test('every space-less script has a rate', () {
      for (final script in CountingScript.values) {
        expect(kScriptCharacterRates[script], isNotNull, reason: script.name);
      }
    });

    test('the rates are ordered', () {
      for (final entry in kScriptCharacterRates.entries) {
        expect(
          entry.value.$1,
          lessThan(entry.value.$2),
          reason: entry.key.name,
        );
        expect(
          entry.value.$2,
          lessThan(entry.value.$3),
          reason: entry.key.name,
        );
      }
    });

    test('Han on its own is the stated global default', () {
      expect(
        characterRateFor(CountingScript.han, ReadingPace.medium),
        kFallbackCharactersPerMinute,
      );
    });

    test('kana is quicker than Han, which is why they are kept apart', () {
      expect(
        characterRateFor(CountingScript.kana, ReadingPace.medium),
        greaterThan(characterRateFor(CountingScript.han, ReadingPace.medium)),
      );
    });
  });
}
