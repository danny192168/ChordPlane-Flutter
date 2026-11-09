import 'package:flutter/material.dart';

import '../../core/chord_shapes.dart';

class ChordDiagram extends StatelessWidget {
  const ChordDiagram({required this.shape, super.key});

  final ChordShape shape;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.86,
      child: CustomPaint(
        painter: _ChordDiagramPainter(
          shape: shape,
          color: Theme.of(context).colorScheme.onSurface,
          accent: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _ChordDiagramPainter extends CustomPainter {
  const _ChordDiagramPainter({
    required this.shape,
    required this.color,
    required this.accent,
  });

  final ChordShape shape;
  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final left = size.width * 0.17;
    final top = size.height * 0.14;
    final width = size.width * 0.70;
    final height = size.height * 0.68;
    final stringSpacing = width / 5;
    final fretSpacing = height / 5;
    final lineWidth = (size.shortestSide / 100).clamp(1.0, 2.0);
    final dotRadius = (size.shortestSide / 18).clamp(6.0, 10.0);
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = lineWidth;
    final boldPaint = Paint()
      ..color = color
      ..strokeWidth = lineWidth * 2.5;
    final dotPaint = Paint()..color = accent;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    if (shape.baseFret > 1) {
      textPainter.text = TextSpan(
        text: '${shape.baseFret}fr',
        style: TextStyle(color: color, fontSize: size.shortestSide * 0.075),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, top + fretSpacing - 8));
    }

    for (var string = 0; string < 6; string++) {
      final x = left + string * stringSpacing;
      canvas.drawLine(Offset(x, top), Offset(x, top + height), linePaint);
      final fret = shape.frets[string];
      final marker = fret == -1
          ? 'x'
          : fret == 0
          ? 'o'
          : '';
      if (marker.isNotEmpty) {
        textPainter.text = TextSpan(
          text: marker,
          style: TextStyle(color: color, fontSize: size.shortestSide * 0.09),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, top - textPainter.height - 4),
        );
      }
    }
    for (var fret = 0; fret <= 5; fret++) {
      final y = top + fret * fretSpacing;
      canvas.drawLine(
        Offset(left, y),
        Offset(left + width, y),
        fret == 0 && shape.baseFret == 1 ? boldPaint : linePaint,
      );
    }

    for (var string = 0; string < 6; string++) {
      final fret = shape.frets[string];
      if (fret <= 0) continue;
      final x = left + string * stringSpacing;
      final y = top + (fret - shape.baseFret + 0.5) * fretSpacing;
      canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
      final finger = shape.fingers[string];
      if (finger > 0) {
        textPainter.text = TextSpan(
          text: '$finger',
          style: TextStyle(
            color: Colors.white,
            fontSize: size.shortestSide * 0.07,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, y - textPainter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChordDiagramPainter oldDelegate) {
    return oldDelegate.shape != shape ||
        oldDelegate.color != color ||
        oldDelegate.accent != accent;
  }
}

Future<void> showChordSheet(BuildContext context, String chord) {
  final shape = chordShapeFor(chord);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: shape == null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(chord, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  const Text('No common guitar shape is available yet.'),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'How to play $chord',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 260,
                    height: 300,
                    child: ChordDiagram(shape: shape),
                  ),
                  const SizedBox(height: 8),
                  const Text('Numbers show suggested finger positions.'),
                ],
              ),
      ),
    ),
  );
}
