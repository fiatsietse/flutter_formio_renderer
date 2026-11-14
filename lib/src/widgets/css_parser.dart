import 'package:flutter/material.dart';

/// Parsed CSS styles for HTML container and text layout.
class FormioCssStyle {
  final Color? backgroundColor;
  final Color? color;
  final Border? border;
  final BorderRadius? borderRadius;
  final bool isCircle;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final double? fontSize;
  final FontWeight? fontWeight;
  final double? lineHeight;
  final bool isFlex;
  final double? gap;
  final int? flex;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final bool isDivider;

  const FormioCssStyle({
    this.backgroundColor,
    this.color,
    this.border,
    this.borderRadius,
    this.isCircle = false,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.fontSize,
    this.fontWeight,
    this.lineHeight,
    this.isFlex = false,
    this.gap,
    this.flex,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.isDivider = false,
  });

  /// Parses a CSS `style="..."` string and class names into [FormioCssStyle].
  factory FormioCssStyle.parse(String? styleAttr,
      {String? className, String? tag}) {
    Color? backgroundColor;
    Color? color;
    BorderSide? borderLeft;
    BorderSide? borderRight;
    BorderSide? borderTop;
    BorderSide? borderBottom;
    BorderSide? borderAll;
    BorderRadius? borderRadius;
    bool isCircle = false;
    EdgeInsets? padding;
    EdgeInsets? margin;
    double? width;
    double? height;
    double? fontSize;
    FontWeight? fontWeight;
    double? lineHeight;
    bool isFlex = false;
    double? gap;
    int? flex;
    CrossAxisAlignment crossAxis = CrossAxisAlignment.start;
    MainAxisAlignment mainAxis = MainAxisAlignment.start;
    bool isDivider = tag == 'hr';

    final cls = className?.toLowerCase() ?? '';
    if (cls.contains('line') ||
        cls.contains('divider') ||
        cls.contains('autre-line')) {
      isDivider = true;
    }

    if (styleAttr != null && styleAttr.isNotEmpty) {
      final declarations = styleAttr.split(';');
      for (final decl in declarations) {
        final colon = decl.indexOf(':');
        if (colon == -1) continue;

        final prop = decl.substring(0, colon).trim().toLowerCase();
        final rawVal = decl.substring(colon + 1).trim();
        final val = rawVal.replaceAll('!important', '').trim().toLowerCase();

        switch (prop) {
          case 'background':
          case 'background-color':
            final parsedColor = _parseColor(val);
            if (parsedColor != null) backgroundColor = parsedColor;
            break;

          case 'color':
            final parsedColor = _parseColor(val);
            if (parsedColor != null) color = parsedColor;
            break;

          case 'border':
            borderAll = _parseBorderSide(val);
            break;

          case 'border-left':
            borderLeft = _parseBorderSide(val);
            break;

          case 'border-right':
            borderRight = _parseBorderSide(val);
            break;

          case 'border-top':
            borderTop = _parseBorderSide(val);
            break;

          case 'border-bottom':
            borderBottom = _parseBorderSide(val);
            break;

          case 'border-radius':
            if (val == '50%' || val == '100%') {
              isCircle = true;
            } else {
              final radius = _parsePixels(val);
              if (radius != null) borderRadius = BorderRadius.circular(radius);
            }
            break;

          case 'padding':
            padding = _parseEdgeInsets(val);
            break;

          case 'padding-left':
            final p = _parsePixels(val);
            if (p != null) {
              padding = EdgeInsets.only(
                left: p,
                top: padding?.top ?? 0,
                right: padding?.right ?? 0,
                bottom: padding?.bottom ?? 0,
              );
            }
            break;

          case 'margin':
            margin = _parseEdgeInsets(val);
            break;

          case 'margin-top':
            final m = _parsePixels(val);
            if (m != null) {
              margin = EdgeInsets.only(
                left: margin?.left ?? 0,
                top: m,
                right: margin?.right ?? 0,
                bottom: margin?.bottom ?? 0,
              );
            }
            break;

          case 'margin-bottom':
            final m = _parsePixels(val);
            if (m != null) {
              margin = EdgeInsets.only(
                left: margin?.left ?? 0,
                top: margin?.top ?? 0,
                right: margin?.right ?? 0,
                bottom: m,
              );
            }
            break;

          case 'margin-right':
            final m = _parsePixels(val);
            if (m != null) {
              margin = EdgeInsets.only(
                left: margin?.left ?? 0,
                top: margin?.top ?? 0,
                right: m,
                bottom: margin?.bottom ?? 0,
              );
            }
            break;

          case 'width':
            width = _parsePixels(val);
            break;

          case 'height':
            height = _parsePixels(val);
            if (height == 1.0) isDivider = true;
            break;

          case 'font-size':
            fontSize = _parsePixels(val);
            break;

          case 'font-weight':
            fontWeight = _parseFontWeight(val);
            break;

          case 'line-height':
            lineHeight = double.tryParse(val) ?? _parsePixels(val);
            break;

          case 'display':
            if (val.contains('flex')) isFlex = true;
            break;

          case 'gap':
            gap = _parsePixels(val);
            break;

          case 'flex':
            flex = int.tryParse(val.split(' ').first);
            break;

          case 'align-items':
            if (val == 'center') {
              crossAxis = CrossAxisAlignment.center;
            } else if (val == 'flex-start' || val == 'start') {
              crossAxis = CrossAxisAlignment.start;
            } else if (val == 'flex-end' || val == 'end') {
              crossAxis = CrossAxisAlignment.end;
            }
            break;

          case 'justify-content':
            if (val == 'center') {
              mainAxis = MainAxisAlignment.center;
            } else if (val == 'flex-start' || val == 'start') {
              mainAxis = MainAxisAlignment.start;
            } else if (val == 'space-between') {
              mainAxis = MainAxisAlignment.spaceBetween;
            }
            break;
        }
      }
    }

    // Combine borders
    Border? border;
    if (borderAll != null) {
      border = Border.all(color: borderAll.color, width: borderAll.width);
    } else if (borderLeft != null ||
        borderRight != null ||
        borderTop != null ||
        borderBottom != null) {
      border = Border(
        left: borderLeft ?? BorderSide.none,
        right: borderRight ?? BorderSide.none,
        top: borderTop ?? BorderSide.none,
        bottom: borderBottom ?? BorderSide.none,
      );
    }

    return FormioCssStyle(
      backgroundColor: backgroundColor,
      color: color,
      border: border,
      borderRadius: borderRadius,
      isCircle: isCircle,
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      fontSize: fontSize,
      fontWeight: fontWeight,
      lineHeight: lineHeight,
      isFlex: isFlex,
      gap: gap,
      flex: flex,
      crossAxisAlignment: crossAxis,
      mainAxisAlignment: mainAxis,
      isDivider: isDivider,
    );
  }

  static Color? _parseColor(String val) {
    var clean = val.trim().toLowerCase();
    if (clean == 'transparent') return Colors.transparent;
    if (clean == '#fff' || clean == '#ffffff' || clean == 'white') {
      return Colors.white;
    }
    if (clean == '#000' || clean == '#000000' || clean == 'black') {
      return Colors.black;
    }

    // Hex colors #RRGGBB or #RGB
    if (clean.startsWith('#')) {
      final hex = clean.substring(1);
      if (hex.length == 3) {
        final r = hex[0];
        final g = hex[1];
        final b = hex[2];
        final full = 'ff$r$r$g$g$b$b';
        final intVal = int.tryParse(full, radix: 16);
        if (intVal != null) return Color(intVal);
      } else if (hex.length == 6) {
        final intVal = int.tryParse('ff$hex', radix: 16);
        if (intVal != null) return Color(intVal);
      } else if (hex.length == 8) {
        final intVal = int.tryParse(hex, radix: 16);
        if (intVal != null) return Color(intVal);
      }
    }

    // rgba(r, g, b, a)
    final rgbaMatch = RegExp(
            r'rgba?\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)(?:\s*,\s*([\d.]+))?\s*\)')
        .firstMatch(clean);
    if (rgbaMatch != null) {
      final r = int.tryParse(rgbaMatch.group(1)!) ?? 0;
      final g = int.tryParse(rgbaMatch.group(2)!) ?? 0;
      final b = int.tryParse(rgbaMatch.group(3)!) ?? 0;
      final aStr = rgbaMatch.group(4);
      final a =
          aStr != null ? ((double.tryParse(aStr) ?? 1.0) * 255).round() : 255;
      return Color.fromARGB(a, r, g, b);
    }

    return null;
  }

  static BorderSide? _parseBorderSide(String val) {
    // e.g. "1px solid #f0f0f0" or "5px solid #9a8b3c"
    final parts = val.split(' ');
    double width = 1.0;
    Color color = Colors.grey.shade300;

    for (final p in parts) {
      final px = _parsePixels(p);
      if (px != null) {
        width = px;
        continue;
      }
      final c = _parseColor(p);
      if (c != null) {
        color = c;
        continue;
      }
    }
    return BorderSide(width: width, color: color);
  }

  static double? _parsePixels(String val) {
    final clean = val
        .replaceAll('px', '')
        .replaceAll('pt', '')
        .replaceAll('%', '')
        .trim();
    return double.tryParse(clean);
  }

  static FontWeight? _parseFontWeight(String val) {
    if (val == 'bold' || val == '700' || val == '800' || val == '900') {
      return FontWeight.bold;
    }
    if (val == '600') return FontWeight.w600;
    if (val == '500') return FontWeight.w500;
    if (val == 'normal' || val == '400') return FontWeight.normal;
    return null;
  }

  static EdgeInsets? _parseEdgeInsets(String val) {
    final parts = val.split(' ').map((p) => _parsePixels(p) ?? 0.0).toList();
    if (parts.isEmpty) return null;
    if (parts.length == 1) return EdgeInsets.all(parts[0]);
    if (parts.length == 2) {
      return EdgeInsets.symmetric(vertical: parts[0], horizontal: parts[1]);
    }
    if (parts.length == 3) {
      return EdgeInsets.only(
          top: parts[0], left: parts[1], right: parts[1], bottom: parts[2]);
    }
    if (parts.length >= 4) {
      return EdgeInsets.only(
          top: parts[0], right: parts[1], bottom: parts[2], left: parts[3]);
    }
    return null;
  }
}
