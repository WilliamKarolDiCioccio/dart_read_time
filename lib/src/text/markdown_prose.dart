/// Markdown with the markup taken out, so that what is left is what is read.
///
/// **Ordinary Markdown, and nothing anyone invented on top of it.** No
/// templating syntax, no shortcodes, no custom fences: a host with a dialect
/// of its own strips it before calling here, because a package that knew about
/// one host's braces would be the wrong package.
///
/// This is a counting aid, not a renderer. It does not have to agree with
/// CommonMark on the hard cases; it has to stop a URL being counted as a word
/// and a fenced code block being counted as prose, which are the two that
/// actually move an estimate.
library;

/// A fence opener: up to three spaces, then three or more backticks or tildes.
final RegExp _fenceOpen = RegExp(r'^ {0,3}(`{3,}|~{3,})');

final RegExp _htmlComment = RegExp(r'<!--[\s\S]*?-->');

/// A code span, matched from a run of backticks to the same run again.
final RegExp _codeSpan = RegExp(r'(`+)[\s\S]*?\1');

/// A link reference definition — `[label]: /url "title"` — which is
/// bookkeeping rather than prose and is never rendered.
final RegExp _linkDefinition = RegExp(
  r'^ {0,3}\[[^\]]+\]:.*$',
  multiLine: true,
);

/// `![alt](src)`. The alt text is kept: somebody wrote it, and a reader with
/// no picture reads it.
final RegExp _image = RegExp(r'!\[([^\]]*)\]\([^)]*\)');

/// `[text](href)`. The text is kept, the destination is not — a URL is not
/// read, and counted as words it is worth several.
final RegExp _inlineLink = RegExp(r'\[([^\]]*)\]\([^)]*\)');

/// `[text][label]` and `[text][]`, the reference forms.
final RegExp _referenceLink = RegExp(r'\[([^\]]*)\]\[[^\]]*\]');

/// `<https://example.com>` and `<mailto:…>`.
final RegExp _autolink = RegExp(r'<[a-zA-Z][a-zA-Z0-9+.\-]*:[^>\s]*>');

final RegExp _htmlTag = RegExp(r'</?[a-zA-Z][^>]*>');

/// A thematic break, and a setext heading's underline, which are markup with
/// no text in them at all.
final RegExp _ruleLine = RegExp(
  r'^ {0,3}(?:(?:[-*_] *){3,}|=+|-+) *$',
  multiLine: true,
);

/// An ATX heading's leading hashes, and the optional closing run.
final RegExp _headingMarks = RegExp(
  r'^ {0,3}#{1,6} +| +#+ *$',
  multiLine: true,
);

final RegExp _blockquoteMarks = RegExp(r'^ {0,3}(?:> ?)+', multiLine: true);

/// A bullet or an ordered marker at the head of a list item.
final RegExp _listMarks = RegExp(
  r'^( *)(?:[-*+]|\d{1,9}[.)]) +',
  multiLine: true,
);

/// A task-list checkbox, which sits after the bullet has already gone.
final RegExp _taskMarks = RegExp(r'^ *\[[ xX]\] +', multiLine: true);

final RegExp _emphasisMarks = RegExp(r'[*_~]{1,3}');

/// Markdown [markdown], reduced to the prose a reader actually reads.
///
/// What goes: fenced code and its contents, code spans, HTML tags and
/// comments, link and image destinations, link reference definitions,
/// autolinks, heading and blockquote and list markers, thematic breaks, table
/// pipes, and emphasis marks. What stays: everything a reader would say out
/// loud, link text and image alt text included.
///
/// **Indented code blocks are not removed**, and that is a limit rather than
/// an oversight: telling four leading spaces of code from four leading spaces
/// of a wrapped list item needs a real block parser, and guessing wrong would
/// silently drop prose. Prose that quotes code almost always fences it.
String markdownToProse(String markdown) {
  if (markdown.isEmpty) return '';

  var text = _withoutFences(markdown);

  // Before anything else that looks inside a line: what a code span holds is
  // not prose, and it may hold something shaped exactly like a link.
  text = text.replaceAll(_htmlComment, ' ');
  text = text.replaceAll(_codeSpan, ' ');

  text = text.replaceAll(_linkDefinition, ' ');
  text = text.replaceAllMapped(_image, (match) => ' ${match[1] ?? ''} ');
  text = text.replaceAllMapped(_inlineLink, (match) => ' ${match[1] ?? ''} ');
  text = text.replaceAllMapped(
    _referenceLink,
    (match) => ' ${match[1] ?? ''} ',
  );
  text = text.replaceAll(_autolink, ' ');
  text = text.replaceAll(_htmlTag, ' ');

  // Line-level markers, rules before headings: a setext underline of dashes
  // has to go as a rule, and a `---` left behind would survive everything
  // after it.
  text = text.replaceAll(_ruleLine, '');
  text = text.replaceAll(_headingMarks, '');
  text = text.replaceAll(_blockquoteMarks, '');
  text = text.replaceAllMapped(_listMarks, (match) => match[1] ?? '');
  text = text.replaceAll(_taskMarks, '');

  // A table's pipes separate cells, so they become the space that separates
  // the words in them rather than being deleted into a join.
  text = text.replaceAll('|', ' ');

  return text.replaceAll(_emphasisMarks, '');
}

/// [markdown] with every fenced block, and everything inside it, gone.
///
/// A fence that is never closed takes the rest of the document, which is
/// CommonMark's own reading of it.
String _withoutFences(String markdown) {
  if (!markdown.contains('```') && !markdown.contains('~~~')) return markdown;

  final kept = StringBuffer();
  String? closing;

  for (final line in markdown.split('\n')) {
    if (closing == null) {
      final open = _fenceOpen.firstMatch(line);
      if (open != null) {
        closing = open[1];
        continue;
      }
      kept
        ..write(line)
        ..write('\n');
      continue;
    }

    // A closing fence is the same character, at least as long, and alone on
    // its line — so a longer run of backticks can hold a fence inside itself.
    final trimmed = line.trimLeft();
    if (trimmed.startsWith(closing[0]) &&
        trimmed.trimRight().length >= closing.length &&
        trimmed.trimRight().split('').every((char) => char == closing![0])) {
      closing = null;
    }
  }

  return kept.toString();
}
