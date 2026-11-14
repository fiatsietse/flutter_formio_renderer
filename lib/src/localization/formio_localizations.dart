import 'dart:ui';
import 'formio_strings.dart';
import 'strings_en.dart';
import 'strings_fr.dart';

/// Provides access to localized strings and message interpolation for Form.io components.
class FormioLocalizations {
  final Locale locale;
  final FormioStrings strings;

  const FormioLocalizations({
    this.locale = const Locale('en'),
    this.strings = const FormioStringsEn(),
  });

  /// Factory resolving strings according to [locale].
  factory FormioLocalizations.forLocale(Locale? locale) {
    if (locale == null) {
      return const FormioLocalizations(
          locale: Locale('en'), strings: FormioStringsEn());
    }
    final code = locale.languageCode.toLowerCase();
    switch (code) {
      case 'fr':
        return FormioLocalizations(
            locale: locale, strings: const FormioStringsFr());
      case 'en':
      default:
        return FormioLocalizations(
            locale: locale, strings: const FormioStringsEn());
    }
  }

  /// Helper to interpolate placeholders `{param}` within a template string.
  static String format(String template, Map<String, dynamic> params) {
    var result = template;
    for (final entry in params.entries) {
      result =
          result.replaceAll('{${entry.key}}', entry.value?.toString() ?? '');
    }
    return result;
  }
}
