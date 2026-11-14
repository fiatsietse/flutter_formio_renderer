import 'package:flutter/material.dart';
import 'html_parser.dart';

/// Lightweight, safe pure-Flutter HTML and CSS renderer for Form.io Content and HTMLElement components.
///
/// Converts HTML elements, inline CSS styles, cards, flex rows, borders, circle badges,
/// images, and bullet lists into native Flutter widgets.
class FormioHtmlRenderer extends StatelessWidget {
  final String html;
  final TextStyle? style;
  final String? tag;
  final String Function(String key)? translate;
  final Map<String, dynamic>? data;

  const FormioHtmlRenderer({
    super.key,
    required this.html,
    this.style,
    this.tag,
    this.translate,
    this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (html.isEmpty) return const SizedBox.shrink();

    // 1. Ignore stylesheet components (tag: "style" or tag: "script")
    if (tag == 'style' || tag == 'script') {
      return const SizedBox.shrink();
    }

    // 2. Preprocess HTML: sanitize scripts/styles and interpolate templates
    final clean = _preprocessHtml(html, translate, data);
    if (clean.isEmpty) return const SizedBox.shrink();

    // 3. Ignore pure CSS stylesheet text
    if (_isPureCss(clean)) {
      return const SizedBox.shrink();
    }

    // 4. Parse into DOM nodes
    const parser = FormioHtmlParser();
    final nodes = parser.parse(clean);
    if (nodes.isEmpty) return const SizedBox.shrink();

    // 5. If it's a single plain text node with no tags, render as Text
    if (nodes.length == 1 && nodes.first.isText) {
      return Text(nodes.first.text!,
          style: style ?? Theme.of(context).textTheme.bodyMedium);
    }

    // 6. Build widget tree from nodes
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final node in nodes) _buildNode(context, node),
      ],
    );
  }

  static String _preprocessHtml(
    String rawHtml,
    String Function(String key)? translate,
    Map<String, dynamic>? data,
  ) {
    // A. Strip style, script, and svg tags with their contents
    var clean = rawHtml
        .replaceAll(
            RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), '')
        .replaceAll(
            RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false), '')
        .replaceAll(
            RegExp(r'<svg[^>]*>[\s\S]*?</svg>', caseSensitive: false), '');

    // B. Interpolate translation templates: {{ t('key') }} or {{ t("key") }}
    clean = clean.replaceAllMapped(
      RegExp(r'''{{\s*t\(['"]([^'"]+)['"]\)\s*}}'''),
      (m) => translate?.call(m.group(1)!) ?? m.group(1)!,
    );

    // C. Interpolate ternary templates: {{ data.x === 'val' ? 'A' : 'B' }}
    clean = clean.replaceAllMapped(
      RegExp(
          r'''{{\s*data\.([a-zA-Z0-9_]+)\s*===?\s*['"]([^'"]+)['"]\s*\?\s*([^:}]+)\s*:\s*([^}]+)\s*}}'''),
      (m) {
        final field = m.group(1)!;
        final expected = m.group(2)!;
        final trueVal = _cleanTemplateToken(m.group(3)!, translate);
        final falseVal = _cleanTemplateToken(m.group(4)!, translate);
        final actual = data?[field]?.toString();
        return actual == expected ? trueVal : falseVal;
      },
    );

    // D. Interpolate simple variable templates: {{ data.x }}
    clean = clean.replaceAllMapped(
      RegExp(r'{{\s*data\.([a-zA-Z0-9_]+)\s*}}'),
      (m) => data?[m.group(1)!]?.toString() ?? '',
    );

    return clean.trim();
  }

  static bool _isPureCss(String s) {
    final t = s.trim();
    if (t.startsWith('@media') || t.startsWith('/*')) return true;
    if (t.contains('{') &&
        t.contains('}') &&
        !t.contains('<') &&
        !t.contains('>')) {
      return true;
    }
    return false;
  }

  Widget _buildNode(BuildContext context, HtmlNode node) {
    // A. Plain text node
    if (node.isText) {
      if (node.text == null || node.text!.isEmpty) {
        return const SizedBox.shrink();
      }
      return Text(
        node.text!,
        style: style ?? Theme.of(context).textTheme.bodyMedium,
      );
    }

    final css = node.style;

    // B. Horizontal divider (<hr> or class="autre-line")
    if (css.isDivider) {
      return Divider(
        color: css.backgroundColor ?? Colors.grey.shade300,
        height: 28,
        thickness: 1,
      );
    }

    // C. Image tag (<img src="..." />)
    if (node.tag == 'img') {
      final src = node.attributes['src'] ?? '';
      final w =
          double.tryParse(node.attributes['width'] ?? '') ?? css.width ?? 32.0;
      final h = double.tryParse(node.attributes['height'] ?? '') ??
          css.height ??
          32.0;

      if (src.startsWith('http://') || src.startsWith('https://')) {
        return Padding(
          padding: EdgeInsets.only(bottom: css.margin?.bottom ?? 8.0),
          child: Image.network(
            src,
            width: w,
            height: h,
            errorBuilder: (_, __, ___) => Icon(Icons.image_outlined,
                size: w, color: Colors.grey.shade400),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    // D. Circular Badge (e.g. ? or step numbers 1, 2, 3 with border-radius: 50%)
    if (css.isCircle) {
      final badgeText = node.text ?? _extractNodeText(node);
      final size = css.width ?? css.height ?? 28.0;

      return Container(
        width: size,
        height: size,
        margin: css.margin ?? EdgeInsets.zero,
        decoration: BoxDecoration(
          color: css.backgroundColor ?? Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          badgeText,
          style: TextStyle(
            color: css.color ?? Colors.white,
            fontWeight: css.fontWeight ?? FontWeight.bold,
            fontSize: css.fontSize ?? 14,
          ),
        ),
      );
    }

    // E. Flex row layout (e.g. display: flex; gap: 16px)
    if (css.isFlex) {
      return _buildFlexLayout(context, node);
    }

    // F. Styled Container Card (background color or border specified)
    if (css.backgroundColor != null || css.border != null) {
      return Container(
        margin: css.margin ?? const EdgeInsets.only(bottom: 16.0),
        padding: css.padding ?? const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: css.backgroundColor,
          border: css.border,
          borderRadius: css.borderRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final child in node.children) _buildNode(context, child),
          ],
        ),
      );
    }

    // G. Headings (h1 - h6)
    if (node.tag.startsWith('h') && node.tag.length == 2) {
      final level = int.tryParse(node.tag.substring(1)) ?? 3;
      return Padding(
        padding: EdgeInsets.only(
          top: css.margin?.top ?? 8.0,
          bottom: css.margin?.bottom ?? 6.0,
        ),
        child: Text(
          _extractNodeText(node),
          style: TextStyle(
            fontSize: css.fontSize ?? _defaultHeadingSize(level),
            fontWeight: css.fontWeight ?? FontWeight.bold,
            color: css.color ?? Colors.black87,
          ),
        ),
      );
    }

    // H. Unordered / Ordered lists (ul, ol)
    if (node.tag == 'ul' || node.tag == 'ol') {
      final isOrdered = node.tag == 'ol';
      final liChildren = node.children.where((c) => c.tag == 'li').toList();

      return Padding(
        padding: EdgeInsets.only(
          top: css.margin?.top ?? 4.0,
          bottom: css.margin?.bottom ?? 12.0,
          left: css.padding?.left ?? 8.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < liChildren.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOrdered ? '${i + 1}. ' : '• ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: css.color ?? Colors.grey.shade800,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _extractNodeText(liChildren[i]),
                        style: TextStyle(
                          fontSize: liChildren[i].style.fontSize ??
                              css.fontSize ??
                              14,
                          color: liChildren[i].style.color ??
                              css.color ??
                              Colors.grey.shade900,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    // I. Paragraph or Div containing children
    if (node.children.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.only(
          top: css.margin?.top ?? 0,
          bottom: css.margin?.bottom ?? (node.tag == 'p' ? 8.0 : 4.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final child in node.children) _buildNode(context, child),
          ],
        ),
      );
    }

    // J. Fallback text element
    final nodeText = node.text ?? _extractNodeText(node);
    if (nodeText.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(
        top: css.margin?.top ?? 0,
        bottom: css.margin?.bottom ?? (node.tag == 'p' ? 8.0 : 4.0),
      ),
      child: Text(
        nodeText,
        style: TextStyle(
          fontSize: css.fontSize ?? 14,
          fontWeight: css.fontWeight ?? FontWeight.normal,
          color: css.color ?? Colors.grey.shade900,
          height: css.lineHeight ?? 1.5,
        ),
      ),
    );
  }

  Widget _buildFlexLayout(BuildContext context, HtmlNode node) {
    final css = node.style;
    final childNodes = node.children;
    if (childNodes.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: css.margin ?? EdgeInsets.zero,
      padding: css.padding ?? EdgeInsets.zero,
      decoration: (css.backgroundColor != null || css.border != null)
          ? BoxDecoration(
              color: css.backgroundColor,
              border: css.border,
              borderRadius: css.borderRadius,
            )
          : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 640;
          final hasFlexChildren = childNodes.any((c) => c.style.flex != null);

          // If narrow screen and children are cards with flex:1, stack vertically
          if (isNarrow && hasFlexChildren) {
            return Column(
              crossAxisAlignment: css.crossAxisAlignment,
              children: [
                for (var i = 0; i < childNodes.length; i++) ...[
                  if (i > 0) SizedBox(height: css.gap ?? 12),
                  _buildNode(context, childNodes[i]),
                ],
              ],
            );
          }

          // Otherwise render side-by-side flex row
          return Row(
            crossAxisAlignment: css.crossAxisAlignment,
            mainAxisAlignment: css.mainAxisAlignment,
            children: [
              for (var i = 0; i < childNodes.length; i++) ...[
                if (i > 0) SizedBox(width: css.gap ?? 12),
                if (childNodes[i].style.flex != null)
                  Expanded(child: _buildNode(context, childNodes[i]))
                else if (childNodes[i].style.width == null &&
                    !childNodes[i].style.isCircle &&
                    childNodes[i].tag != 'img')
                  Expanded(child: _buildNode(context, childNodes[i]))
                else
                  _buildNode(context, childNodes[i]),
              ],
            ],
          );
        },
      ),
    );
  }

  static double _defaultHeadingSize(int level) {
    switch (level) {
      case 1:
        return 24;
      case 2:
        return 20;
      case 3:
        return 17;
      default:
        return 15;
    }
  }

  static String _extractNodeText(HtmlNode node) {
    if (node.text != null) return node.text!;
    final buffer = StringBuffer();
    for (final child in node.children) {
      if (child.isText && child.text != null) {
        buffer.write(child.text);
      } else {
        buffer.write(_extractNodeText(child));
      }
    }
    return buffer.toString().trim();
  }

  static String _cleanTemplateToken(
      String raw, String Function(String key)? translate) {
    var s = raw.trim();
    if ((s.startsWith("'") && s.endsWith("'")) ||
        (s.startsWith('"') && s.endsWith('"'))) {
      s = s.substring(1, s.length - 1);
    }
    final tMatch = RegExp(r'''t\(['"]([^'"]+)['"]\)''').firstMatch(s);
    if (tMatch != null) {
      return translate?.call(tMatch.group(1)!) ?? tMatch.group(1)!;
    }
    return s;
  }
}
