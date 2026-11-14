/// Abstract interface providing localized string templates for validation messages,
/// wizard navigation buttons, and grid actions.
abstract class FormioStrings {
  String get required;
  String get minLength;
  String get maxLength;
  String get min;
  String get max;
  String get pattern;
  String get email;
  String get url;
  String get phone;
  String get minSelected;
  String get maxSelected;
  String get minRows;
  String get maxRows;
  String get invalidJsonLogic;
  String get invalidScript;

  // Wizard / Navigation
  String get next;
  String get previous;
  String get submit;
  String get cancel;
  String get reset;
  String get page;
  String get ofPage;

  // Grids / Repeating
  String get addAnother;
  String get removeRow;
  String get edit;
  String get saveRow;
  String get cancelRow;
  String get noRows;

  // File Upload
  String get uploadFile;
  String get dropFile;
  String get removeFile;

  // Signature
  String get signHere;
  String get clearSignature;

  // Placeholders / Diagnostics
  String get selectPlaceholder;
  String get unsupportedComponent;
  String get fixErrorsBeforeSubmitting;
}
