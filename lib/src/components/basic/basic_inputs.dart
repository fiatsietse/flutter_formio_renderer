import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../registry/component_renderer_builder.dart';
import '../../widgets/formio_field_wrapper.dart';
import '../../adapters/remote_options_adapter.dart';
import '../../models/schema/select_option.dart';

/// Text field component renderer.
Widget buildTextField(FormioRenderContext ctx) {
  final comp = ctx.state.schema;
  final isReadOnly = ctx.manager.options.readOnly || ctx.state.disabled;

  if (comp.multiple) {
    return _buildMultipleTextField(ctx);
  }

  return FormioFieldWrapper(
    state: ctx.state,
    child: _FormioTextInput(
      initialValue: ctx.value?.toString() ?? '',
      placeholder: comp.placeholder != null
          ? ctx.manager.translate(comp.placeholder!)
          : null,
      prefix: comp.prefix,
      suffix: comp.suffix,
      readOnly: isReadOnly,
      keyboardType: TextInputType.text,
      onChanged: (val) => ctx.setValue(val),
    ),
  );
}

/// Textarea component renderer.
Widget buildTextArea(FormioRenderContext ctx) {
  final comp = ctx.state.schema;
  final isReadOnly = ctx.manager.options.readOnly || ctx.state.disabled;
  final rows = (comp.rawJson['rows'] as num?)?.toInt() ?? 3;

  return FormioFieldWrapper(
    state: ctx.state,
    child: _FormioTextInput(
      initialValue: ctx.value?.toString() ?? '',
      placeholder: comp.placeholder != null
          ? ctx.manager.translate(comp.placeholder!)
          : null,
      readOnly: isReadOnly,
      maxLines: rows > 1 ? rows : 3,
      minLines: rows > 1 ? rows : 2,
      keyboardType: TextInputType.multiline,
      onChanged: (val) => ctx.setValue(val),
    ),
  );
}

/// Number input component renderer.
Widget buildNumber(FormioRenderContext ctx) {
  final comp = ctx.state.schema;
  final isReadOnly = ctx.manager.options.readOnly || ctx.state.disabled;

  return FormioFieldWrapper(
    state: ctx.state,
    child: _FormioTextInput(
      initialValue: ctx.value?.toString() ?? '',
      placeholder: comp.placeholder != null
          ? ctx.manager.translate(comp.placeholder!)
          : null,
      prefix: comp.prefix,
      suffix: comp.suffix,
      readOnly: isReadOnly,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true, signed: true),
      onChanged: (val) {
        if (val.trim().isEmpty) {
          ctx.setValue(null);
        } else {
          final n = num.tryParse(val.trim());
          ctx.setValue(n ?? val);
        }
      },
    ),
  );
}

/// Password input component renderer.
Widget buildPassword(FormioRenderContext ctx) {
  final comp = ctx.state.schema;
  final isReadOnly = ctx.manager.options.readOnly || ctx.state.disabled;

  return FormioFieldWrapper(
    state: ctx.state,
    child: _FormioPasswordInput(
      initialValue: ctx.value?.toString() ?? '',
      placeholder: comp.placeholder != null
          ? ctx.manager.translate(comp.placeholder!)
          : null,
      prefix: comp.prefix,
      readOnly: isReadOnly,
      onChanged: (val) => ctx.setValue(val),
    ),
  );
}

/// Email component renderer.
Widget buildEmail(FormioRenderContext ctx) {
  final comp = ctx.state.schema;
  final isReadOnly = ctx.manager.options.readOnly || ctx.state.disabled;

  return FormioFieldWrapper(
    state: ctx.state,
    child: _FormioTextInput(
      initialValue: ctx.value?.toString() ?? '',
      placeholder: comp.placeholder != null
          ? ctx.manager.translate(comp.placeholder!)
          : 'name@example.com',
      prefix: comp.prefix,
      suffix: comp.suffix,
      readOnly: isReadOnly,
      keyboardType: TextInputType.emailAddress,
      onChanged: (val) => ctx.setValue(val),
    ),
  );
}

/// URL component renderer.
Widget buildUrl(FormioRenderContext ctx) {
  final comp = ctx.state.schema;
  final isReadOnly = ctx.manager.options.readOnly || ctx.state.disabled;

  return FormioFieldWrapper(
    state: ctx.state,
    child: _FormioTextInput(
      initialValue: ctx.value?.toString() ?? '',
      placeholder: comp.placeholder != null
          ? ctx.manager.translate(comp.placeholder!)
          : 'https://example.com',
      prefix: comp.prefix,
      suffix: comp.suffix,
      readOnly: isReadOnly,
      keyboardType: TextInputType.url,
      onChanged: (val) => ctx.setValue(val),
    ),
  );
}

/// Phone number component renderer.
Widget buildPhoneNumber(FormioRenderContext ctx) {
  final comp = ctx.state.schema;
  final isReadOnly = ctx.manager.options.readOnly || ctx.state.disabled;

  return FormioFieldWrapper(
    state: ctx.state,
    child: _FormioTextInput(
      initialValue: ctx.value?.toString() ?? '',
      placeholder: comp.placeholder != null
          ? ctx.manager.translate(comp.placeholder!)
          : null,
      prefix: comp.prefix,
      suffix: comp.suffix,
      readOnly: isReadOnly,
      keyboardType: TextInputType.phone,
      onChanged: (val) => ctx.setValue(val),
    ),
  );
}

/// Checkbox component renderer.
Widget buildCheckbox(FormioRenderContext ctx) {
  final comp = ctx.state.schema;
  final isReadOnly = ctx.manager.options.readOnly || ctx.state.disabled;
  final currentVal = ctx.value == true;

  return FormioFieldWrapper(
    state: ctx.state,
    showLabel: false, // Checkbox has its own label in ListTile
    child: CheckboxListTile(
      value: currentVal,
      onChanged: isReadOnly
          ? null
          : (val) {
              ctx.setValue(val ?? false);
            },
      title: Text.rich(
        TextSpan(
          text: ctx.state.label,
          children: [
            if (ctx.state.required)
              TextSpan(
                text: ' *',
                style:
                    TextStyle(color: Theme.of(ctx.context).colorScheme.error),
              ),
          ],
        ),
      ),
      subtitle: comp.description != null ? Text(comp.description!) : null,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    ),
  );
}

/// SelectBoxes component renderer (group of checkboxes stored as map of boolean flags).
Widget buildSelectBoxes(FormioRenderContext ctx) {
  final comp = ctx.state.schema;
  final isReadOnly = ctx.manager.options.readOnly || ctx.state.disabled;
  final currentMap = ctx.value is Map
      ? Map<String, dynamic>.from(ctx.value as Map)
      : <String, dynamic>{};

  return FormioFieldWrapper(
    state: ctx.state,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final opt in comp.options)
          CheckboxListTile(
            value: currentMap[opt.value.toString()] == true,
            onChanged: (isReadOnly || opt.disabled)
                ? null
                : (checked) {
                    final updated = Map<String, dynamic>.from(currentMap);
                    updated[opt.value.toString()] = checked ?? false;
                    ctx.setValue(updated);
                  },
            title: Text(ctx.manager.translate(opt.label)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
      ],
    ),
  );
}

/// Radio buttons component renderer.
Widget buildRadio(FormioRenderContext ctx) {
  final comp = ctx.state.schema;
  final isReadOnly = ctx.manager.options.readOnly || ctx.state.disabled;
  final currentVal = ctx.value?.toString();

  return FormioFieldWrapper(
    state: ctx.state,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final opt in comp.options)
          RadioListTile<String>(
            value: opt.value.toString(),
            groupValue: currentVal,
            onChanged: (isReadOnly || opt.disabled)
                ? null
                : (val) {
                    ctx.setValue(opt.value);
                  },
            title: Text(ctx.manager.translate(opt.label)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
      ],
    ),
  );
}

/// Select component renderer supporting local values, remote URL adapter, and multi-selection.
Widget buildSelect(FormioRenderContext ctx) {
  return FormioFieldWrapper(
    state: ctx.state,
    child: _FormioSelectWidget(ctx: ctx),
  );
}

/// Date / Time component renderer.
Widget buildDateTime(FormioRenderContext ctx) {
  final comp = ctx.state.schema;
  final isReadOnly = ctx.manager.options.readOnly || ctx.state.disabled;
  final enableDate = comp.rawJson['enableDate'] != false;
  final enableTime = comp.rawJson['enableTime'] == true;

  DateTime? parsedDate;
  if (ctx.value != null) {
    if (ctx.value is DateTime) {
      parsedDate = ctx.value as DateTime;
    } else {
      parsedDate = DateTime.tryParse(ctx.value.toString());
    }
  }

  String displayStr = '';
  if (parsedDate != null) {
    if (enableDate && enableTime) {
      displayStr = DateFormat('yyyy-MM-dd HH:mm').format(parsedDate);
    } else if (enableDate) {
      displayStr = DateFormat('yyyy-MM-dd').format(parsedDate);
    } else if (enableTime) {
      displayStr = DateFormat('HH:mm').format(parsedDate);
    }
  }

  return FormioFieldWrapper(
    state: ctx.state,
    child: InkWell(
      onTap: isReadOnly
          ? null
          : () async {
              DateTime selected = parsedDate ?? DateTime.now();
              if (enableDate) {
                final pickedDate = await showDatePicker(
                  context: ctx.context,
                  initialDate: selected,
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                );
                if (pickedDate == null) return;
                selected = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  selected.hour,
                  selected.minute,
                );
              }
              if (enableTime) {
                if (!ctx.context.mounted) return;
                final pickedTime = await showTimePicker(
                  context: ctx.context,
                  initialTime: TimeOfDay.fromDateTime(selected),
                );
                if (pickedTime != null) {
                  selected = DateTime(
                    selected.year,
                    selected.month,
                    selected.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );
                }
              }
              // Format ISO string according to Form.io standard
              final iso = enableTime
                  ? selected.toIso8601String()
                  : DateFormat('yyyy-MM-dd').format(selected);
              ctx.setValue(iso);
            },
      child: InputDecorator(
        decoration: InputDecoration(
          hintText: comp.placeholder ??
              (enableTime ? 'YYYY-MM-DD HH:mm' : 'YYYY-MM-DD'),
          suffixIcon: Icon(
              enableTime ? Icons.access_time : Icons.calendar_today,
              size: 20),
          border: const OutlineInputBorder(),
        ),
        child: Text(
          displayStr.isNotEmpty
              ? displayStr
              : (comp.placeholder ?? 'Select date...'),
          style: TextStyle(
            color:
                displayStr.isNotEmpty ? null : Theme.of(ctx.context).hintColor,
          ),
        ),
      ),
    ),
  );
}

/// Day component renderer (Day / Month / Year fields).
Widget buildDay(FormioRenderContext ctx) {
  final isReadOnly = ctx.manager.options.readOnly || ctx.state.disabled;
  final currentVal = ctx.value?.toString() ?? '';
  final parts = currentVal.split('/');
  final currentDay = parts.isNotEmpty ? parts[0] : '';
  final currentMonth = parts.length > 1 ? parts[1] : '';
  final currentYear = parts.length > 2 ? parts[2] : '';

  return FormioFieldWrapper(
    state: ctx.state,
    child: Row(
      children: [
        Expanded(
          flex: 2,
          child: TextFormField(
            initialValue: currentDay,
            keyboardType: TextInputType.number,
            readOnly: isReadOnly,
            decoration: const InputDecoration(
                labelText: 'Day', border: OutlineInputBorder()),
            onChanged: (d) {
              final newStr = '$d/$currentMonth/$currentYear';
              ctx.setValue(newStr);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextFormField(
            initialValue: currentMonth,
            keyboardType: TextInputType.number,
            readOnly: isReadOnly,
            decoration: const InputDecoration(
                labelText: 'Month', border: OutlineInputBorder()),
            onChanged: (m) {
              final newStr = '$currentDay/$m/$currentYear';
              ctx.setValue(newStr);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: TextFormField(
            initialValue: currentYear,
            keyboardType: TextInputType.number,
            readOnly: isReadOnly,
            decoration: const InputDecoration(
                labelText: 'Year', border: OutlineInputBorder()),
            onChanged: (y) {
              final newStr = '$currentDay/$currentMonth/$y';
              ctx.setValue(newStr);
            },
          ),
        ),
      ],
    ),
  );
}

/// Time component renderer.
Widget buildTime(FormioRenderContext ctx) {
  final comp = ctx.state.schema;
  final isReadOnly = ctx.manager.options.readOnly || ctx.state.disabled;
  final currentVal = ctx.value?.toString() ?? '';

  return FormioFieldWrapper(
    state: ctx.state,
    child: InkWell(
      onTap: isReadOnly
          ? null
          : () async {
              final initial = currentVal.isNotEmpty
                  ? TimeOfDay(
                      hour: int.tryParse(currentVal.split(':').first) ?? 12,
                      minute: int.tryParse(currentVal.split(':').length > 1
                              ? currentVal.split(':')[1]
                              : '0') ??
                          0,
                    )
                  : TimeOfDay.now();
              final picked = await showTimePicker(
                  context: ctx.context, initialTime: initial);
              if (picked != null) {
                final h = picked.hour.toString().padLeft(2, '0');
                final m = picked.minute.toString().padLeft(2, '0');
                ctx.setValue('$h:$m:00');
              }
            },
      child: InputDecorator(
        decoration: InputDecoration(
          hintText: comp.placeholder ?? 'HH:mm:ss',
          suffixIcon: const Icon(Icons.access_time, size: 20),
          border: const OutlineInputBorder(),
        ),
        child: Text(
          currentVal.isNotEmpty
              ? currentVal
              : (comp.placeholder ?? 'Select time...'),
          style: TextStyle(
            color:
                currentVal.isNotEmpty ? null : Theme.of(ctx.context).hintColor,
          ),
        ),
      ),
    ),
  );
}

/// Hidden field component renderer.
Widget buildHidden(FormioRenderContext ctx) {
  return const SizedBox.shrink();
}

/// Button component renderer with action handling.
Widget buildButton(FormioRenderContext ctx) {
  final comp = ctx.state.schema;
  final isReadOnly = ctx.manager.options.readOnly || ctx.state.disabled;
  final action = comp.rawJson['action']?.toString().toLowerCase() ?? 'submit';
  final themeName =
      comp.rawJson['theme']?.toString().toLowerCase() ?? 'primary';

  Color? btnColor;
  if (themeName == 'danger') btnColor = Colors.red;
  if (themeName == 'secondary') btnColor = Colors.grey.shade700;
  if (themeName == 'success') btnColor = Colors.green;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: ElevatedButton(
      style: btnColor != null
          ? ElevatedButton.styleFrom(
              backgroundColor: btnColor, foregroundColor: Colors.white)
          : null,
      onPressed: isReadOnly
          ? null
          : () {
              switch (action) {
                case 'submit':
                  final res = ctx.manager.validate();
                  if (res.isValid) {
                    // Trigger submission callback via form
                  }
                  break;
                case 'reset':
                  ctx.manager.reset();
                  break;
                case 'next':
                  ctx.manager.nextPage();
                  break;
                case 'previous':
                  ctx.manager.previousPage();
                  break;
                case 'event':
                  // Fire custom event
                  break;
              }
            },
      child: Text(ctx.state.label.isNotEmpty
          ? ctx.state.label
          : ctx.manager.translate('Submit')),
    ),
  );
}

// ---------------- Helper Widgets ----------------

class _FormioTextInput extends StatefulWidget {
  final String initialValue;
  final String? placeholder;
  final String? prefix;
  final String? suffix;
  final bool readOnly;
  final int maxLines;
  final int minLines;
  final TextInputType keyboardType;
  final ValueChanged<String> onChanged;

  const _FormioTextInput({
    required this.initialValue,
    this.placeholder,
    this.prefix,
    this.suffix,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines = 1,
    this.keyboardType = TextInputType.text,
    required this.onChanged,
  });

  @override
  State<_FormioTextInput> createState() => _FormioTextInputState();
}

class _FormioTextInputState extends State<_FormioTextInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _FormioTextInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: widget.readOnly,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      keyboardType: widget.keyboardType,
      decoration: InputDecoration(
        hintText: widget.placeholder,
        prefixText: widget.prefix != null ? '${widget.prefix} ' : null,
        suffixText: widget.suffix != null ? ' ${widget.suffix}' : null,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onChanged: widget.onChanged,
    );
  }
}

class _FormioPasswordInput extends StatefulWidget {
  final String initialValue;
  final String? placeholder;
  final String? prefix;
  final bool readOnly;
  final ValueChanged<String> onChanged;

  const _FormioPasswordInput({
    required this.initialValue,
    this.placeholder,
    this.prefix,
    this.readOnly = false,
    required this.onChanged,
  });

  @override
  State<_FormioPasswordInput> createState() => _FormioPasswordInputState();
}

class _FormioPasswordInputState extends State<_FormioPasswordInput> {
  late final TextEditingController _controller;
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _FormioPasswordInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: widget.readOnly,
      obscureText: _obscured,
      decoration: InputDecoration(
        hintText: widget.placeholder,
        prefixText: widget.prefix != null ? '${widget.prefix} ' : null,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(_obscured ? Icons.visibility_off : Icons.visibility,
              size: 20),
          onPressed: () => setState(() => _obscured = !_obscured),
        ),
      ),
      onChanged: widget.onChanged,
    );
  }
}

class _FormioSelectWidget extends StatefulWidget {
  final FormioRenderContext ctx;

  const _FormioSelectWidget({required this.ctx});

  @override
  State<_FormioSelectWidget> createState() => _FormioSelectWidgetState();
}

class _FormioSelectWidgetState extends State<_FormioSelectWidget> {
  List<SelectOption> _options = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final comp = widget.ctx.state.schema;
    final dataSrc =
        comp.rawJson['dataSrc']?.toString().toLowerCase() ?? 'values';

    if (dataSrc == 'url') {
      final url = comp.rawJson['data']?['url']?.toString() ??
          comp.rawJson['url']?.toString() ??
          '';
      final adapter = widget.ctx.manager.options.remoteOptionsAdapter ??
          const FormioHttpRemoteOptionsAdapter();

      if (url.isNotEmpty) {
        setState(() {
          _isLoading = true;
          _error = null;
        });

        try {
          final res = await adapter.fetchOptions(
            RemoteOptionsRequest(
              url: url,
              formData: widget.ctx.manager.dataTree.rawData,
              valueProperty: comp.rawJson['valueProperty']?.toString(),
              template: comp.rawJson['template']?.toString(),
            ),
          );
          if (mounted) {
            setState(() {
              _options = res.options;
              _isLoading = false;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _error = e.toString();
              _isLoading = false;
            });
          }
        }
        return;
      }
    }

    // Default static values
    _options = comp.options;
  }

  @override
  Widget build(BuildContext context) {
    final comp = widget.ctx.state.schema;
    final isReadOnly =
        widget.ctx.manager.options.readOnly || widget.ctx.state.disabled;
    final isMultiple = comp.multiple;

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: LinearProgressIndicator(),
      );
    }

    if (_error != null) {
      return Row(
        children: [
          Expanded(
              child: Text('Error loading options: $_error',
                  style: const TextStyle(color: Colors.red))),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOptions),
        ],
      );
    }

    if (isMultiple) {
      final selectedValues = widget.ctx.value is List
          ? List<dynamic>.from(widget.ctx.value as List)
          : <dynamic>[];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final opt in _options)
            CheckboxListTile(
              value: selectedValues.contains(opt.value),
              onChanged: isReadOnly || opt.disabled
                  ? null
                  : (checked) {
                      final updated = List<dynamic>.from(selectedValues);
                      if (checked == true) {
                        updated.add(opt.value);
                      } else {
                        updated.remove(opt.value);
                      }
                      widget.ctx.setValue(updated);
                    },
              title: Text(widget.ctx.manager.translate(opt.label)),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
        ],
      );
    }

    final currentVal = widget.ctx.value;
    final validValue =
        _options.any((o) => o.value == currentVal) ? currentVal : null;

    return DropdownButtonFormField<dynamic>(
      value: validValue,
      isExpanded: true,
      decoration: InputDecoration(
        hintText: comp.placeholder != null
            ? widget.ctx.manager.translate(comp.placeholder!)
            : 'Select an option...',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        for (final opt in _options)
          DropdownMenuItem<dynamic>(
            value: opt.value,
            enabled: !opt.disabled && !isReadOnly,
            child: Text(widget.ctx.manager.translate(opt.label)),
          ),
      ],
      onChanged: isReadOnly ? null : (val) => widget.ctx.setValue(val),
    );
  }
}

Widget _buildMultipleTextField(FormioRenderContext ctx) {
  final isReadOnly = ctx.manager.options.readOnly || ctx.state.disabled;
  final list =
      ctx.value is List ? List<dynamic>.from(ctx.value as List) : <dynamic>[];

  return FormioFieldWrapper(
    state: ctx.state,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < list.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: list[i]?.toString() ?? '',
                    readOnly: isReadOnly,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      hintText: ctx.state.schema.placeholder,
                    ),
                    onChanged: (val) {
                      list[i] = val;
                      ctx.setValue(list);
                    },
                  ),
                ),
                if (!isReadOnly)
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () {
                      list.removeAt(i);
                      ctx.setValue(list);
                    },
                  ),
              ],
            ),
          ),
        if (!isReadOnly)
          TextButton.icon(
            onPressed: () {
              list.add('');
              ctx.setValue(list);
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Item'),
          ),
      ],
    ),
  );
}
