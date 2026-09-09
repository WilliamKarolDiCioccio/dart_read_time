import 'package:dart_read_time/dart_read_time.dart';
import 'package:test/test.dart';

void main() {
  /// Japanese, written the way Japanese is: no spaces, two scripts at once.
  const japanese = '彼は暗い廊下を歩いて、扉の前で立ち止まった。';

  /// The same sentence in Korean — which looks East Asian and is spaced.
  const korean = '그는 어두운 복도를 걸어가 문 앞에서 멈춰 섰다.';

  const chinese = '他走过昏暗的走廊，在门前停了下来。';

  group('continuousScriptOf', () {
    test('sends each script where it belongs', () {
      expect(continuousScriptOf('漢'.runes.first), CountingScript.han);
      expect(continuousScriptOf('ひ'.runes.first), CountingScript.kana);
      expect(continuousScriptOf('カ'.runes.first), CountingScript.kana);
      expect(continuousScriptOf('ก'.runes.first), CountingScript.thai);
      expect(continuousScriptOf('ក'.runes.first), CountingScript.khmer);
    });

    test('leaves Hangul to the word count', () {
      expect(
        continuousScriptOf('한'.runes.first),
        isNull,
        reason:
            'Korean is spaced by eojeol. Counting it by the character would '
            'roughly triple every Korean estimate.',
      );
    });

    test('leaves everything spaced alone', () {
      for (final sample in <String>['a', 'Ω', 'д', 'א', 'ا', 'अ', '7', ' ']) {
        expect(continuousScriptOf(sample.runes.first), isNull, reason: sample);
      }
    });

    test('takes the two Han marks out of the punctuation block', () {
      expect(continuousScriptOf('々'.runes.first), CountingScript.han);
      expect(continuousScriptOf('〇'.runes.first), CountingScript.han);
      expect(
        continuousScriptOf('。'.runes.first),
        isNull,
        reason: 'A full stop is a separator, not a character that is read.',
      );
    });

    test('reaches the ideographs above the basic plane', () {
      expect(continuousScriptOf(0x20000), CountingScript.han);
    });
  });

  group('countText', () {
    test('counts ordinary English by the word', () {
      final counts = countText('You arrive at the gate.');
      expect(counts.words, 5);
      expect(counts.totalCharacters, 0);
      expect(counts.isMixed, isFalse);
    });

    test('counts Japanese by the character, and by script', () {
      final counts = countText(japanese);
      expect(counts.characters[CountingScript.han], 9);
      expect(counts.characters[CountingScript.kana], 11);
      expect(counts.totalCharacters, 20);
      expect(
        counts.words,
        0,
        reason:
            'The only spaced tokens are 、 and 。, and punctuation on its own '
            'is not a word.',
      );
    });

    test('counts Chinese by the character', () {
      final counts = countText(chinese);
      expect(counts.characters[CountingScript.han], 15);
      expect(counts.words, 0);
    });

    test('counts Korean by the word', () {
      final counts = countText(korean);
      expect(
        counts.words,
        8,
        reason: 'Eight eojeol, separated by the spaces Korean actually writes.',
      );
      expect(counts.totalCharacters, 0);
    });

    test('counts Thai by the character and finds no words', () {
      final counts = countText('เขาเดินไปตามทางเดินที่มืดมิด');
      expect(counts.characters[CountingScript.thai], greaterThan(20));
      expect(counts.words, 0);
    });

    test('splits mixed text into both counts', () {
      final counts = countText('彼は Tokyo Tower を見た。');
      expect(counts.words, 2, reason: 'Tokyo and Tower.');
      expect(counts.characters[CountingScript.han], 2, reason: '彼 and 見.');
      expect(counts.characters[CountingScript.kana], 3, reason: 'は, を, た.');
      expect(counts.isMixed, isTrue);
    });

    test('never glues two words across a character run', () {
      expect(
        countText('The general 曹操 waited.').words,
        3,
        reason:
            'general and waited are separate words even with no space left '
            'between them once the Han runes are taken out.',
      );
      expect(countText('The general 曹操 waited.').totalCharacters, 2);
    });

    test('does not count punctuation as a word', () {
      expect(countText('— … ?! 。').words, 0);
      expect(countText('3.14 is a number').words, 4);
    });

    test('is empty for empty and blank text', () {
      expect(countText('').isEmpty, isTrue);
      expect(countText('   \n\t ').isEmpty, isTrue);
    });
  });
}
