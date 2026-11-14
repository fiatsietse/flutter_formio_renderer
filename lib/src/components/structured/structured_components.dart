import 'package:flutter/material.dart';
import '../../registry/component_renderer_builder.dart';
import '../../registry/component_registry.dart';
import '../../widgets/formio_field_wrapper.dart';
import '../../localization/formio_localizations.dart';
import '../../models/schema/component_schema.dart';
import '../../models/submission/data_path.dart';
import '../../state/component_state.dart';

/// Container component renderer (creates nested map in submission data).
Widget buildContainer(FormioRenderContext ctx) {
  final comp = ctx.state.schema;
  if (ctx.state.hidden) return const SizedBox.shrink();

  return FormioFieldWrapper(
    state: ctx.state,
    child: Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(ctx.context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.2),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final child in comp.components)
            _renderScopedChild(ctx, child, ctx.state.dataPath),
        ],
      ),
    ),
  );
}

/// DataGrid component renderer (repeating table/list of objects).
Widget buildDataGrid(FormioRenderContext ctx) {
  return FormioFieldWrapper(
    state: ctx.state,
    child: _FormioDataGridWidget(ctx: ctx),
  );
}

/// EditGrid component renderer (repeating array with collapsible/inline row editing).
Widget buildEditGrid(FormioRenderContext ctx) {
  return FormioFieldWrapper(
    state: ctx.state,
    child: _FormioEditGridWidget(ctx: ctx),
  );
}

// ---------------- Helpers & Grid Implementations ----------------

Widget _renderScopedChild(FormioRenderContext ctx,
    FormioComponentSchema childComp, DataPath parentPath) {
  final childPath = parentPath.child(childComp.key);
  final instanceId = childPath.toDotString();

  final state = ctx.manager.getState(instanceId) ??
      ctx.manager.getState(childComp.key) ??
      FormioComponentState(
        schema: childComp,
        dataPath: childPath,
        instanceId: instanceId,
        pageIndex: ctx.state.pageIndex,
      );

  if (state.hidden) return const SizedBox.shrink();

  final childCtx = FormioRenderContext(
    context: ctx.context,
    state: state,
    manager: ctx.manager,
  );
  final builder = FormioComponentRegistry.defaultRegistry.get(childComp.type);
  return builder(childCtx);
}

class _FormioDataGridWidget extends StatelessWidget {
  final FormioRenderContext ctx;

  const _FormioDataGridWidget({required this.ctx});

  @override
  Widget build(BuildContext context) {
    final comp = ctx.state.schema;
    final isReadOnly = ctx.manager.options.readOnly || ctx.state.disabled;
    final strings =
        FormioLocalizations.forLocale(ctx.manager.options.locale).strings;

    final rawVal = ctx.manager.getValue(ctx.state.dataPath);
    final rows = rawVal is List ? rawVal : <dynamic>[];

    final minRows = comp.validate.minRows ?? 0;
    final maxRows = comp.validate.maxRows ?? 999;
    final canAdd = !isReadOnly && rows.length < maxRows;
    final addLabel =
        comp.rawJson['addAnother']?.toString() ?? strings.addAnother;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              strings.noRows,
              style: TextStyle(
                  fontStyle: FontStyle.italic, color: Colors.grey.shade600),
            ),
          ),
        for (var i = 0; i < rows.length; i++)
          Card(
            key: ValueKey('${comp.key}_row_$i'),
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '#${i + 1}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      if (!isReadOnly && rows.length > minRows)
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red, size: 20),
                          tooltip: strings.removeRow,
                          onPressed: () {
                            ctx.manager
                                .removeGridRow(ctx.state.dataPath, i, comp);
                          },
                        ),
                    ],
                  ),
                  const Divider(),
                  for (final col in comp.components)
                    _renderGridRowColumn(ctx, col, i),
                ],
              ),
            ),
          ),
        if (canAdd) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: () {
                ctx.manager.addGridRow(ctx.state.dataPath, comp);
              },
              icon: const Icon(Icons.add, size: 18),
              label: Text(addLabel),
            ),
          ),
        ],
      ],
    );
  }

  Widget _renderGridRowColumn(FormioRenderContext gridCtx,
      FormioComponentSchema colComp, int rowIndex) {
    final colPath = gridCtx.state.dataPath.child(rowIndex).child(colComp.key);
    final instanceId = '${gridCtx.state.schema.key}:$rowIndex:${colComp.key}';

    final state = gridCtx.manager.getState(instanceId) ??
        FormioComponentState(
          schema: colComp,
          dataPath: colPath,
          instanceId: instanceId,
          pageIndex: gridCtx.state.pageIndex,
        );

    if (state.hidden) return const SizedBox.shrink();

    final colCtx = FormioRenderContext(
      context: gridCtx.context,
      state: state,
      manager: gridCtx.manager,
    );
    final builder = FormioComponentRegistry.defaultRegistry.get(colComp.type);
    return builder(colCtx);
  }
}

class _FormioEditGridWidget extends StatefulWidget {
  final FormioRenderContext ctx;

  const _FormioEditGridWidget({required this.ctx});

  @override
  State<_FormioEditGridWidget> createState() => _FormioEditGridWidgetState();
}

class _FormioEditGridWidgetState extends State<_FormioEditGridWidget> {
  int? _editingRowIndex;

  @override
  Widget build(BuildContext context) {
    final comp = widget.ctx.state.schema;
    final isReadOnly =
        widget.ctx.manager.options.readOnly || widget.ctx.state.disabled;
    final strings =
        FormioLocalizations.forLocale(widget.ctx.manager.options.locale)
            .strings;

    final rawVal = widget.ctx.manager.getValue(widget.ctx.state.dataPath);
    final rows = rawVal is List ? rawVal : <dynamic>[];

    final minRows = comp.validate.minRows ?? 0;
    final maxRows = comp.validate.maxRows ?? 999;
    final canAdd = !isReadOnly && rows.length < maxRows;
    final addLabel =
        comp.rawJson['addAnother']?.toString() ?? strings.addAnother;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(strings.noRows,
                style: const TextStyle(fontStyle: FontStyle.italic)),
          ),
        for (var i = 0; i < rows.length; i++)
          Card(
            key: ValueKey('${comp.key}_editrow_$i'),
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: _editingRowIndex == i
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Editing Row #${i + 1}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const Divider(),
                        for (final col in comp.components)
                          _renderEditGridColumn(col, i),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  setState(() => _editingRowIndex = null),
                              child: Text(strings.saveRow),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Row #${i + 1}: ${_summarizeRow(rows[i])}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        if (!isReadOnly) ...[
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            tooltip: strings.edit,
                            onPressed: () =>
                                setState(() => _editingRowIndex = i),
                          ),
                          if (rows.length > minRows)
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  size: 18, color: Colors.red),
                              tooltip: strings.removeRow,
                              onPressed: () {
                                widget.ctx.manager.removeGridRow(
                                    widget.ctx.state.dataPath, i, comp);
                                if (_editingRowIndex == i) {
                                  setState(() => _editingRowIndex = null);
                                }
                              },
                            ),
                        ],
                      ],
                    ),
            ),
          ),
        if (canAdd) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: () {
                widget.ctx.manager.addGridRow(widget.ctx.state.dataPath, comp);
                setState(() => _editingRowIndex = rows.length);
              },
              icon: const Icon(Icons.add, size: 18),
              label: Text(addLabel),
            ),
          ),
        ],
      ],
    );
  }

  Widget _renderEditGridColumn(FormioComponentSchema colComp, int rowIndex) {
    final colPath =
        widget.ctx.state.dataPath.child(rowIndex).child(colComp.key);
    final instanceId =
        '${widget.ctx.state.schema.key}:$rowIndex:${colComp.key}';

    final state = widget.ctx.manager.getState(instanceId) ??
        FormioComponentState(
          schema: colComp,
          dataPath: colPath,
          instanceId: instanceId,
          pageIndex: widget.ctx.state.pageIndex,
        );

    final colCtx = FormioRenderContext(
      context: widget.ctx.context,
      state: state,
      manager: widget.ctx.manager,
    );
    final builder = FormioComponentRegistry.defaultRegistry.get(colComp.type);
    return builder(colCtx);
  }

  String _summarizeRow(dynamic rowData) {
    if (rowData is Map) {
      final entries = rowData.entries
          .where((e) => e.value != null && e.value.toString().isNotEmpty)
          .take(3)
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
      return entries.isNotEmpty ? entries : '(empty)';
    }
    return rowData?.toString() ?? '(empty)';
  }
}
