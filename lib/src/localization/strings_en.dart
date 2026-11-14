import 'formio_strings.dart';

class FormioStringsEn implements FormioStrings {
  const FormioStringsEn();

  @override
  String get required => '{field} is required';
  @override
  String get minLength => '{field} must have at least {min} characters';
  @override
  String get maxLength => '{field} must not exceed {max} characters';
  @override
  String get min => '{field} must be at least {min}';
  @override
  String get max => '{field} must not exceed {max}';
  @override
  String get pattern => '{field} format is invalid';
  @override
  String get email => '{field} must be a valid email address';
  @override
  String get url => '{field} must be a valid URL';
  @override
  String get phone => '{field} must be a valid phone number';
  @override
  String get minSelected => 'Please select at least {min} option(s)';
  @override
  String get maxSelected => 'Please select at most {max} option(s)';
  @override
  String get minRows => 'Must contain at least {min} row(s)';
  @override
  String get maxRows => 'Must not exceed {max} row(s)';
  @override
  String get invalidJsonLogic =>
      '{field} does not satisfy validation condition';
  @override
  String get invalidScript => '{field} validation failed';

  @override
  String get next => 'Next';
  @override
  String get previous => 'Previous';
  @override
  String get submit => 'Submit';
  @override
  String get cancel => 'Cancel';
  @override
  String get reset => 'Reset';
  @override
  String get page => 'Page';
  @override
  String get ofPage => 'of';

  @override
  String get addAnother => 'Add Another';
  @override
  String get removeRow => 'Remove';
  @override
  String get edit => 'Edit';
  @override
  String get saveRow => 'Save';
  @override
  String get cancelRow => 'Cancel';
  @override
  String get noRows => 'No items yet';

  @override
  String get uploadFile => 'Upload File';
  @override
  String get dropFile => 'Choose a file or tap to upload';
  @override
  String get removeFile => 'Remove file';

  @override
  String get signHere => 'Sign above';
  @override
  String get clearSignature => 'Clear';

  @override
  String get selectPlaceholder => 'Select an option...';
  @override
  String get unsupportedComponent => 'Unsupported component: {type}';
  @override
  String get fixErrorsBeforeSubmitting =>
      'Please fix the errors before submitting the form.';
}
