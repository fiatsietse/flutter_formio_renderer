import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Interactive vector signature pad for Form.io Signature components.
class FormioSignaturePad extends StatefulWidget {
  final String? initialDataUrl;
  final bool readOnly;
  final ValueChanged<String?>? onChanged;
  final double height;
  final Color penColor;
  final Color backgroundColor;

  const FormioSignaturePad({
    super.key,
    this.initialDataUrl,
    this.readOnly = false,
    this.onChanged,
    this.height = 180.0,
    this.penColor = Colors.black,
    this.backgroundColor = const Color(0xFFF9F9F9),
  });

  @override
  State<FormioSignaturePad> createState() => _FormioSignaturePadState();
}

class _FormioSignaturePadState extends State<FormioSignaturePad> {
  final List<List<Offset>> _strokes = [];
  List<Offset>? _currentStroke;

  @override
  Widget build(BuildContext context) {
    // If readOnly and has an existing base64 PNG data URL
    if (widget.readOnly &&
        widget.initialDataUrl != null &&
        widget.initialDataUrl!.startsWith('data:image/')) {
      final base64Str = widget.initialDataUrl!.split(',').last;
      try {
        final bytes = base64Decode(base64Str);
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Image.memory(bytes, fit: BoxFit.contain),
        );
      } catch (_) {
        // Fallback to empty container
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: GestureDetector(
              onPanStart: widget.readOnly
                  ? null
                  : (details) {
                      setState(() {
                        _currentStroke = [details.localPosition];
                        _strokes.add(_currentStroke!);
                      });
                    },
              onPanUpdate: widget.readOnly
                  ? null
                  : (details) {
                      setState(() {
                        _currentStroke?.add(details.localPosition);
                      });
                    },
              onPanEnd: widget.readOnly
                  ? null
                  : (details) {
                      _currentStroke = null;
                      _exportSignature();
                    },
              child: CustomPaint(
                painter: _SignaturePainter(
                  strokes: _strokes,
                  penColor: widget.penColor,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        ),
        if (!widget.readOnly) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _strokes.isEmpty ? null : _clear,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear Signature'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = null;
    });
    widget.onChanged?.call(null);
  }

  Future<void> _exportSignature() async {
    if (_strokes.isEmpty) {
      widget.onChanged?.call(null);
      return;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(400, 180);

    // Fill transparent or white background
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final painter =
        _SignaturePainter(strokes: _strokes, penColor: widget.penColor);
    painter.paint(canvas, size);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    if (byteData != null) {
      final base64 = base64Encode(byteData.buffer.asUint8List());
      final dataUrl = 'data:image/png;base64,$base64';
      widget.onChanged?.call(dataUrl);
    }
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final Color penColor;

  _SignaturePainter({required this.strokes, required this.penColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = penColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
