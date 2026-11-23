import 'package:flutter/material.dart';
import '../../registry/component_renderer_builder.dart';
import '../../registry/component_registry.dart';
import '../../widgets/html_renderer.dart';
import '../../models/schema/component_schema.dart';
import '../../state/component_state.dart';

/// Panel component renderer.
Widget buildPanel(FormioRenderContext ctx) {
  final comp = ctx.state.schema;
  if (ctx.state.hidden) return const SizedBox.shrink();

  return _FormioPanelWidget(ctx: ctx, comp: comp);
}

/// Fieldset component renderer.
Widget buildFieldset(FormioRenderContext ctx) {
  final comp = ctx.state.schema;
  if (ctx.state.hidden) return const SizedBox.shrink();
  final rawLegend = comp.rawJson['legend']?.toString() ?? comp.label;
  final legend = ctx.manager.translate(rawLegend);

  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8.0),
    padding: const EdgeInsets.all(12.0),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade400),
      borderRadius: BorderRadius.circular(6.0),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (legend.isNotEmpty) ...[
          Text(
            legend,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Divider(),
        ],
        for (final child in comp.components) _renderChildComponent(ctx, child),
      ],
    ),
  );
}

/// Columns component renderer (responsive grid).
Widget buildColumns(FormioRenderContext ctx) {
  final comp = ctx.state.schema;
  if (ctx.state.hidden) return const SizedBox.shrink();

  return LayoutBuilder(
    builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 600;

      if (isNarrow) {
        // Stack columns vertically on narrow mobile screens
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final col in comp.columns)
              for (final child in col.components)
                _renderChildComponent(ctx, child),
          ],
        );
      }

      // Render horizontal row with flex based on width
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final col in comp.columns)
            Expanded(
              flex: col.width > 0 ? col.width : 6,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final child in col.components)
                      _renderChildComponent(ctx, child),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}

/// Table component renderer.
Widget buildTable(FormioRenderContext ctx) {
  final comp = ctx.state.schema;
  if (ctx.state.hidden) return const SizedBox.shrink();

  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      border: TableBorder.all(color: Colors.grey.shade300),
      children: [
        for (final row in comp.tableRows)
          TableRow(
            children: [
              for (final cell in row)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final child in cell)
                        _renderChildComponent(ctx, child),
                    ],
                  ),
                ),
            ],
          ),
      ],
    ),
  );
}

/// Tabs component renderer.
Widget buildTabs(FormioRenderContext ctx) {
  final comp = ctx.state.schema;
  if (ctx.state.hidden) return const SizedBox.shrink();

  final tabComponents = comp.components;
  if (tabComponents.isEmpty) return const SizedBox.shrink();

  return DefaultTabController(
    length: tabComponents.length,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabBar(
          isScrollable: true,
          labelColor: Theme.of(ctx.context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: [
            for (final tab in tabComponents)
              Tab(
                  text: ctx.manager.translate(
                      tab.label.isNotEmpty ? tab.label : tab.key)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 350,
          child: TabBarView(
            children: [
              for (final tab in tabComponents)
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final child in tab.components)
                        _renderChildComponent(ctx, child),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Content (HTML) component renderer.
Widget buildContent(FormioRenderContext ctx) {
  final comp = ctx.state.schema;
  if (ctx.state.hidden) return const SizedBox.shrink();
  final html = comp.rawJson['html']?.toString() ?? '';

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: FormioHtmlRenderer(
      html: html,
      translate: (k) => ctx.manager.translate(k),
      data: ctx.manager.dataTree.rawData,
    ),
  );
}

/// HTMLElement component renderer.
Widget buildHtmlElement(FormioRenderContext ctx) {
  final comp = ctx.state.schema;
  if (ctx.state.hidden) return const SizedBox.shrink();

  final tag = comp.rawJson['tag']?.toString().toLowerCase();
  if (tag == 'style' || tag == 'script') {
    return const SizedBox.shrink();
  }

  final content = comp.rawJson['content']?.toString() ?? '';
  final trimmed = content.trim();
  if (trimmed.startsWith('@media') ||
      trimmed.startsWith('/*') ||
      (trimmed.contains('{') &&
          trimmed.contains('}') &&
          !trimmed.contains('<'))) {
    return const SizedBox.shrink();
  }

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: FormioHtmlRenderer(
      html: content,
      tag: tag,
      translate: (k) => ctx.manager.translate(k),
      data: ctx.manager.dataTree.rawData,
    ),
  );
}

// ---------------- Helpers ----------------

class _FormioPanelWidget extends StatefulWidget {
  final FormioRenderContext ctx;
  final FormioComponentSchema comp;

  const _FormioPanelWidget({required this.ctx, required this.comp});

  @override
  State<_FormioPanelWidget> createState() => _FormioPanelWidgetState();
}

class _FormioPanelWidgetState extends State<_FormioPanelWidget> {
  late bool _collapsed;

  @override
  void initState() {
    super.initState();
    _collapsed = widget.comp.rawJson['collapsed'] == true;
  }

  @override
  Widget build(BuildContext context) {
    final rawTitle =
        widget.comp.rawJson['title']?.toString() ?? widget.comp.label;
    final title = widget.ctx.manager.translate(rawTitle);
    final collapsible = widget.comp.rawJson['collapsible'] == true;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title.isNotEmpty)
            InkWell(
              onTap: collapsible
                  ? () => setState(() => _collapsed = !_collapsed)
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withOpacity(0.4),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8.0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    if (collapsible)
                      Icon(_collapsed
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up),
                  ],
                ),
              ),
            ),
          if (!_collapsed)
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final child in widget.comp.components)
                    _renderChildComponent(widget.ctx, child),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

Widget _renderChildComponent(
    FormioRenderContext parentCtx, FormioComponentSchema child) {
  final state = parentCtx.manager.getState(child.key);
  if (state == null) {
    // If state doesn't exist (e.g. display-only layout), create transient state
    final childContext = FormioRenderContext(
      context: parentCtx.context,
      state: FormioComponentState(
        schema: child,
        dataPath: parentCtx.state.dataPath,
        instanceId: child.key,
      ),
      manager: parentCtx.manager,
    );
    final builder = FormioComponentRegistry.defaultRegistry.get(child.type);
    return builder(childContext);
  }

  if (state.hidden) return const SizedBox.shrink();

  final childCtx = FormioRenderContext(
    context: parentCtx.context,
    state: state,
    manager: parentCtx.manager,
  );
  final builder = FormioComponentRegistry.defaultRegistry.get(child.type);
  return builder(childCtx);
}
