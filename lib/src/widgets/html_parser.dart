import 'css_parser.dart';

/// Lightweight DOM node representing an HTML element or text fragment.
class HtmlNode {
  final String tag;
  final Map<String, String> attributes;
  final FormioCssStyle style;
  final List<HtmlNode> children;
  final String? text;

  const HtmlNode({
    required this.tag,
    this.attributes = const {},
    this.style = const FormioCssStyle(),
    this.children = const [],
    this.text,
  });

  bool get isText => tag == '#text';
  bool get isVoidTag => const {'img', 'br', 'hr', 'input'}.contains(tag);
}

/// Simple, robust HTML parser for Form.io styled HTML content.
class FormioHtmlParser {
  const FormioHtmlParser();

  List<HtmlNode> parse(String html) {
    var clean = html
        .replaceAll(
            RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), '')
        .replaceAll(
            RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false), '')
        .replaceAll(
            RegExp(r'<svg[^>]*>[\s\S]*?</svg>', caseSensitive: false), '');

    final nodes = <HtmlNode>[];
    _parseChildren(clean, nodes);
    return nodes;
  }

  void _parseChildren(String content, List<HtmlNode> result) {
    var index = 0;
    final len = content.length;

    while (index < len) {
      final nextTagStart = content.indexOf('<', index);
      if (nextTagStart == -1) {
        // Trailing text
        final text = _decodeEntities(content.substring(index).trim());
        if (text.isNotEmpty) {
          result.add(HtmlNode(tag: '#text', text: text));
        }
        break;
      }

      if (nextTagStart > index) {
        final text =
            _decodeEntities(content.substring(index, nextTagStart).trim());
        if (text.isNotEmpty) {
          result.add(HtmlNode(tag: '#text', text: text));
        }
      }

      // Check if closing tag
      if (nextTagStart + 1 < len && content[nextTagStart + 1] == '/') {
        final closeEnd = content.indexOf('>', nextTagStart);
        if (closeEnd == -1) break;
        index = closeEnd + 1;
        continue;
      }

      final tagEnd = content.indexOf('>', nextTagStart);
      if (tagEnd == -1) break;

      final tagContent = content.substring(nextTagStart + 1, tagEnd).trim();
      final isSelfClosing = tagContent.endsWith('/');
      final tagBody = isSelfClosing
          ? tagContent.substring(0, tagContent.length - 1).trim()
          : tagContent;

      final firstSpace = tagBody.indexOf(RegExp(r'\s'));
      final tagName =
          (firstSpace == -1 ? tagBody : tagBody.substring(0, firstSpace))
              .toLowerCase();
      final attrsStr =
          firstSpace == -1 ? '' : tagBody.substring(firstSpace).trim();
      final attrs = _parseAttributes(attrsStr);
      final style = FormioCssStyle.parse(
        attrs['style'],
        className: attrs['class'],
        tag: tagName,
      );

      // Void / self-closing tag
      if (isSelfClosing ||
          const {'img', 'br', 'hr', 'input'}.contains(tagName)) {
        result.add(HtmlNode(
          tag: tagName,
          attributes: attrs,
          style: style,
        ));
        index = tagEnd + 1;
        continue;
      }

      // Find matching closing tag </tagName>
      final closingTag = '</$tagName>';
      final endTagIdx = _findMatchingClosingTag(content, tagName, tagEnd + 1);

      if (endTagIdx != -1) {
        final innerContent = content.substring(tagEnd + 1, endTagIdx);
        final children = <HtmlNode>[];
        _parseChildren(innerContent, children);

        result.add(HtmlNode(
          tag: tagName,
          attributes: attrs,
          style: style,
          children: children,
          text: children.isEmpty ? _decodeEntities(innerContent.trim()) : null,
        ));
        index = endTagIdx + closingTag.length;
      } else {
        // Tag wasn't closed properly
        index = tagEnd + 1;
      }
    }
  }

  int _findMatchingClosingTag(String content, String tagName, int startIndex) {
    final lower = content.toLowerCase();
    final openPattern = '<$tagName';
    final closePattern = '</$tagName>';

    var depth = 1;
    var searchIdx = startIndex;

    while (depth > 0 && searchIdx < content.length) {
      final nextOpen = lower.indexOf(openPattern, searchIdx);
      final nextClose = lower.indexOf(closePattern, searchIdx);

      if (nextClose == -1) return -1; // Unclosed tag

      if (nextOpen != -1 && nextOpen < nextClose) {
        // Verify it's a real tag boundary e.g. <div or <div class=
        final charAfter = nextOpen + openPattern.length;
        if (charAfter < content.length) {
          final c = content[charAfter];
          if (c == '>' || c == ' ' || c == '/' || c == '\t' || c == '\n') {
            depth++;
          }
        }
        searchIdx = nextOpen + openPattern.length;
      } else {
        depth--;
        if (depth == 0) return nextClose;
        searchIdx = nextClose + closePattern.length;
      }
    }

    return -1;
  }

  Map<String, String> _parseAttributes(String raw) {
    final attrs = <String, String>{};
    if (raw.isEmpty) return attrs;

    final regex = RegExp(
        r'''([a-zA-Z0-9_\-]+)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))''');
    for (final match in regex.allMatches(raw)) {
      final name = match.group(1)!.toLowerCase();
      final val = match.group(2) ?? match.group(3) ?? match.group(4) ?? '';
      attrs[name] = val;
    }
    return attrs;
  }

  String _decodeEntities(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&eacute;', 'é')
        .replaceAll('&egrave;', 'è')
        .replaceAll('&ecirc;', 'ê')
        .replaceAll('&agrave;', 'à')
        .replaceAll('&acirc;', 'â')
        .replaceAll('&icirc;', 'î')
        .replaceAll('&iuml;', 'ï')
        .replaceAll('&ocirc;', 'ô')
        .replaceAll('&ugrave;', 'ù')
        .replaceAll('&ucirc;', 'û')
        .replaceAll('&ccedil;', 'ç');
  }
}
