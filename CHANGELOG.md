## 0.2.2

* Fixed real-time localization updates so switching locales updates labels and options without resetting form data.
* Fixed localized error summary banner (`fixErrorsBeforeSubmitting`) to honor the active locale.
* Added bilingual (`en` / `fr`) `i18n` schemas across example fixtures.
* Added `controller.setLocale()` for programmatic locale switching.

## 0.2.1

* Fixed compatibility with newer Flutter theme data types.
* Declared support for Android, iOS, Linux, macOS, Web, and Windows.
* Expanded the `intl` constraint to include 0.20.x while preserving Dart 3.5 compatibility.

## 0.2.0

* Added default HTTP GET loading for select components using `dataSrc: "url"`.
* Added configurable headers and base URL support through `FormioHttpRemoteOptionsAdapter`.
* Added remote option mapping for `valueProperty` and Form.io templates.

## 0.1.1

* Sanitized test suites and removed client-specific schemas.
* Added `safe_script_evaluator_test.dart` for generic conditional and calculation scripts.
* Added `html_styling_widget_test.dart` for CSS style parsing and native flex cards.
* Cleaned up example fixtures and dependencies.

## 0.1.0

* Initial release of `flutter_formio_renderer`.
* Pure Flutter rendering of Form.io JSON forms and multi-step wizards.
* Reactive engine supporting conditional visibility, JSON Logic, and calculated values.
* Built-in `SafeScriptEvaluator` for client-side Form.io JavaScript expressions in pure Dart.
* Structured repeaters: DataGrid and EditGrid components.
* Multi-language translation support (`i18n` dictionary merging and template interpolation).
* Layout and styling support for HTML elements, cards, and dividers.
* Comprehensive validation engine (required, lengths, bounds, formats, regex, custom messages).
* Pluggable adapters for remote options, file storage, nested subforms, and custom components.
