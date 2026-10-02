// Every entry point in the package, on the kinds of text that tell them
// apart: a plain paragraph, a Japanese one with an English title in it, an
// English one quoting French, and a Markdown document.
//
//   dart run example/dart_read_time_example.dart

import 'package:dart_read_time/dart_read_time.dart';

void main() {
  // A paragraph in one language: words counted, priced at that language's
  // words per minute.
  final english = estimateReadTime(
    'The library was quiet at that hour, and the only sound was the '
    'radiator ticking as it cooled. She turned the page.',
    options: const ReadTimeOptions(language: 'en'),
  );
  print('English: ${english.words} words, ${_seconds(english)}');

  // Japanese is written without spaces, so it is counted in characters —
  // and the English title inside it is still counted in words, because the
  // script decides the unit, not the language tag.
  final japanese = estimateReadTime(
    '彼女は Tokyo Tower の展望台から街を見下ろした。',
    options: const ReadTimeOptions(language: 'ja'),
  );
  print(
    'Japanese: ${japanese.characters} characters and ${japanese.words} words '
    '(mixed script: ${japanese.isMixedScript}), ${_seconds(japanese)}',
  );

  // Two languages in one script need someone to say where the second one
  // is. The package detects nothing; the caller hands over the ranges.
  const quoting = 'He looked up and said, "Je ne regrette rien," and meant it.';
  final start = quoting.indexOf('Je');
  final spanned = estimateSpannedReadTime(quoting, [
    LanguageSpan(
      start: start,
      end: start + 'Je ne regrette rien'.length,
      language: 'fr',
    ),
  ], options: const ReadTimeOptions(language: 'en'));
  print(
    'Quoting: ${_seconds(spanned)} across ${spanned.byLanguage.keys.join(', ')}; '
    'dominant ${spanned.dominantLanguage}',
  );

  // Markdown: code, link destinations and markers are stripped first, so a
  // URL is worth nothing and a link is worth its text.
  const document = '''
# Getting started

Install the package, then read the [guide](https://example.com/guide).

```sh
dart pub add dart_read_time
```
''';
  final markdown = estimateMarkdownReadTime(
    document,
    options: const ReadTimeOptions(
      language: 'en',
      contentMultiplier: ContentMultiplier.technical,
    ),
  );
  print('Markdown: ${markdown.words} words, ${_seconds(markdown)}');

  // Every rate says whether it was measured or reasoned from another.
  final danish = ReadingSpeeds.of('da');
  print(
    'Danish: ${danish.evidence.name}, derived from ${danish.derivedFrom} — '
    '${danish.note}',
  );
}

String _seconds(ReadTime estimate) =>
    '${(estimate.duration.inMilliseconds / 1000).toStringAsFixed(1)} s';
