import 'package:dart_read_time/dart_read_time.dart';
import 'package:test/test.dart';

void main() {
  /// What is left once the markup is gone, with the whitespace it leaves
  /// behind collapsed — the tests are about which *words* survive, and the
  /// gaps between them are the counter's business rather than this one's.
  String prose(String markdown) =>
      markdownToProse(markdown).replaceAll(RegExp(r'\s+'), ' ').trim();

  group('code', () {
    test('a fenced block goes, contents and all', () {
      expect(
        prose('Before\n\n```dart\nfinal x = 1;\n```\n\nAfter'),
        'Before After',
      );
    });

    test('a tilde fence goes too', () {
      expect(prose('Before\n~~~\nnot prose\n~~~\nAfter'), 'Before After');
    });

    test('an unclosed fence takes the rest of the document', () {
      expect(
        prose('Before\n```\nstill code\nand still code'),
        'Before',
        reason: "CommonMark's own reading of a fence nobody closed.",
      );
    });

    test('a longer fence can hold a shorter one', () {
      expect(
        prose('Before\n````\n```\ninner\n```\n````\nAfter'),
        'Before After',
      );
    });

    test('a code span goes', () {
      expect(prose('Call `estimateReadTime(text)` on it.'), 'Call on it.');
    });

    test('a code span does not have its contents read as a link', () {
      expect(prose('Write `[text](url)` for a link.'), 'Write for a link.');
    });
  });

  group('links and images', () {
    test('a link keeps its text and loses its destination', () {
      expect(
        prose('See [the map](../art/map.png) first.'),
        'See the map first.',
      );
    });

    test('a bare image is worth nothing', () {
      expect(
        prose('![](../art/map.png)'),
        '',
        reason:
            'The path is not read, and there is no alt text to read instead. '
            'A whitespace split counts it as a word.',
      );
    });

    test('an image keeps its alt text, which somebody wrote', () {
      expect(prose('![a stone gate](../art/map.png)'), 'a stone gate');
    });

    test('a reference link keeps its text', () {
      expect(prose('See [the map][atlas] first.'), 'See the map first.');
    });

    test('a link reference definition is bookkeeping and goes', () {
      expect(
        prose('Text.\n\n[atlas]: https://example.com/very/long/path "Atlas"'),
        'Text.',
      );
    });

    test('an autolink goes', () {
      expect(prose('Visit <https://example.com/a/b/c> today.'), 'Visit today.');
    });
  });

  group('block markers', () {
    test('a heading keeps its words and loses its hashes', () {
      expect(prose('## The Cold Hall'), 'The Cold Hall');
      expect(prose('### A closed heading ###'), 'A closed heading');
    });

    test('a blockquote keeps its words', () {
      expect(prose('> He said nothing.'), 'He said nothing.');
      expect(prose('>> Nested.'), 'Nested.');
    });

    test('a list keeps its items', () {
      expect(prose('- one\n- two\n- three'), 'one two three');
      expect(prose('1. one\n2. two'), 'one two');
    });

    test('a task list loses its checkbox', () {
      expect(prose('- [ ] open\n- [x] done'), 'open done');
    });

    test('a thematic break goes', () {
      expect(prose('Before\n\n---\n\nAfter'), 'Before After');
      expect(prose('Before\n\n***\n\nAfter'), 'Before After');
    });

    test("a setext heading keeps its text and loses its underline", () {
      expect(
        prose('The Cold Hall\n=============\n\nText.'),
        'The Cold Hall Text.',
      );
    });

    test('a table keeps its cells and loses its pipes', () {
      expect(
        prose('| name | value |\n| --- | --- |\n| gate | shut |'),
        'name value --- --- gate shut',
        reason:
            'The dashes survive as tokens but hold no letter, so the counter '
            'discards them.',
      );
    });
  });

  group('inline markers', () {
    test('emphasis goes and its words stay', () {
      expect(
        prose('He was *very* **quite** ~~almost~~ sure.'),
        'He was very quite almost sure.',
      );
    });

    test('an HTML tag goes and its text stays', () {
      expect(
        prose('A <br> and <span class="x">some text</span>.'),
        'A and some text .',
      );
    });

    test('an HTML comment goes', () {
      expect(prose('Before <!-- a note --> after.'), 'Before after.');
    });
  });

  test('nothing in, nothing out', () {
    expect(markdownToProse(''), '');
  });

  test('plain prose is left exactly alone', () {
    const passage = 'You arrive at the gate. It is shut.';
    expect(markdownToProse(passage), passage);
  });
}
