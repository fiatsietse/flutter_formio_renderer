import '../registry/component_registry.dart';
import 'basic/basic_inputs.dart';
import 'layout/layout_components.dart';
import 'structured/structured_components.dart';
import 'advanced/advanced_components.dart';

/// Registers all standard built-in Form.io components into the provided [registry].
void registerDefaultComponents([FormioComponentRegistry? targetRegistry]) {
  final reg = targetRegistry ?? FormioComponentRegistry.defaultRegistry;

  // Basic Inputs
  reg.register('textfield', buildTextField);
  reg.register('textarea', buildTextArea);
  reg.register('number', buildNumber);
  reg.register('password', buildPassword);
  reg.register('email', buildEmail);
  reg.register('url', buildUrl);
  reg.register('phoneNumber', buildPhoneNumber);
  reg.register('phonenumber', buildPhoneNumber);
  reg.register('checkbox', buildCheckbox);
  reg.register('selectboxes', buildSelectBoxes);
  reg.register('radio', buildRadio);
  reg.register('select', buildSelect);
  reg.register('datetime', buildDateTime);
  reg.register('day', buildDay);
  reg.register('time', buildTime);
  reg.register('hidden', buildHidden);
  reg.register('button', buildButton);

  // Layout & Presentation
  reg.register('panel', buildPanel);
  reg.register('fieldset', buildFieldset);
  reg.register('columns', buildColumns);
  reg.register('table', buildTable);
  reg.register('tabs', buildTabs);
  reg.register('content', buildContent);
  reg.register('htmlelement', buildHtmlElement);
  reg.register('well', buildPanel); // Standard well alias in Form.io

  // Structured Data
  reg.register('container', buildContainer);
  reg.register('datagrid', buildDataGrid);
  reg.register('editgrid', buildEditGrid);

  // Advanced Integrations
  reg.register('file', buildFile);
  reg.register('signature', buildSignature);
  reg.register('form', buildNestedForm);
  reg.register('nestedform', buildNestedForm);
}
