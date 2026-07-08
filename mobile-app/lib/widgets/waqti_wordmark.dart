import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Logo WaQti : le "Q" est une horloge, comme sur l'identité ConnectSoft.
/// Utilisation : WaqtiWordmark(size: 36, color: Colors.white)
/// En arabe, affiche simplement "وقتي".
class WaqtiWordmark extends StatelessWidget {
  final double size;
  final Color color;
  final bool isArabic;

  const WaqtiWordmark({
    super.key,
    this.size = 36,
    this.color = Colors.white,
    this.isArabic = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w800,
      color: color,
      letterSpacing: 0.5,
      height: 1.0,
    );

    if (isArabic) {
      return Text('وقتي', style: style);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Wa', style: style),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: size * 0.03),
          child: CustomPaint(
            size: Size(size * 0.78, size * 0.86),
            painter: _QClockPainter(color: color),
          ),
        ),
        Text('ti', style: style),
      ],
    );
  }
}

class _QClockPainter extends CustomPainter {
  final Color color;
  _QClockPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.13;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height * 0.46);
    final radius = size.width / 2 - stroke / 2;

    // Cercle du Q (horloge)
    canvas.drawCircle(center, radius, paint);

    // Aiguille des minutes (vers 10h30 comme le logo)
    final minuteAngle = -math.pi * 0.75;
    canvas.drawLine(
      center,
      center + Offset(math.cos(minuteAngle), math.sin(minuteAngle)) * radius * 0.62,
      paint,
    );

    // Aiguille des heures (vers 15h)
    canvas.drawLine(
      center,
      center + Offset(radius * 0.42, radius * 0.10),
      paint,
    );

    // Queue du Q (petit trait en bas à droite)
    final tailStart = center + Offset(radius * 0.55, radius * 0.55);
    final tailEnd = center + Offset(radius * 1.05, radius * 1.05);
    canvas.drawLine(tailStart, tailEnd, paint);
  }

  @override
  bool shouldRepaint(covariant _QClockPainter old) => old.color != color;
}
