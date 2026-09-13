import 'package:flutter/material.dart';
import 'dart:math';

class AdvancedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final int styleIndex;

  AdvancedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.styleIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Rect baseRect = (Offset.zero & size).deflate(strokeWidth / 2);

    int type = styleIndex % 5; 
    double varVal = (styleIndex ~/ 5).toDouble() * 3.0;

    switch (type) {
      case 0:
        final double offset = varVal;
        final Rect innerRect = baseRect.deflate(offset);
        canvas.drawRRect(RRect.fromRectAndRadius(innerRect, Radius.circular(radius)), paint);
        break;

      case 1:
        canvas.drawRRect(RRect.fromRectAndRadius(baseRect, Radius.circular(radius)), paint);
        if (varVal >= 0) {
          paint.strokeWidth = strokeWidth * 0.5;
          canvas.drawRRect(RRect.fromRectAndRadius(baseRect.deflate(6 + varVal), Radius.circular(max(0, radius - 2))), paint);
        }
        if (varVal > 10) {
          canvas.drawRRect(RRect.fromRectAndRadius(baseRect.deflate(12 + varVal), Radius.circular(max(0, radius - 4))), paint);
        }
        break;

      case 2:
        double lineLen = 20.0 + varVal;
        if (lineLen > size.width / 2) lineLen = size.width / 2;
        
        canvas.drawLine(baseRect.topLeft, baseRect.topLeft + Offset(lineLen, 0), paint);
        canvas.drawLine(baseRect.topLeft, baseRect.topLeft + Offset(0, lineLen), paint);
        
        canvas.drawLine(baseRect.topRight, baseRect.topRight + Offset(-lineLen, 0), paint);
        canvas.drawLine(baseRect.topRight, baseRect.topRight + Offset(0, lineLen), paint);
        
        canvas.drawLine(baseRect.bottomLeft, baseRect.bottomLeft + Offset(lineLen, 0), paint);
        canvas.drawLine(baseRect.bottomLeft, baseRect.bottomLeft + Offset(0, -lineLen), paint);
        
        canvas.drawLine(baseRect.bottomRight, baseRect.bottomRight + Offset(-lineLen, 0), paint);
        canvas.drawLine(baseRect.bottomRight, baseRect.bottomRight + Offset(0, -lineLen), paint);
        break;

      case 3:
        double gap = 15.0 + varVal;
        if (gap > size.width / 3) gap = size.width / 3;
        Path path = Path();
        
        path.moveTo(baseRect.left + gap, baseRect.top);
        path.lineTo(baseRect.right - gap, baseRect.top);
        
        path.moveTo(baseRect.left + gap, baseRect.bottom);
        path.lineTo(baseRect.right - gap, baseRect.bottom);
        
        path.moveTo(baseRect.left, baseRect.top + gap);
        path.lineTo(baseRect.left, baseRect.bottom - gap);
        
        path.moveTo(baseRect.right, baseRect.top + gap);
        path.lineTo(baseRect.right, baseRect.bottom - gap);
        
        canvas.drawPath(path, paint);

        if (varVal > 5) {
          paint.style = PaintingStyle.fill;
          canvas.drawCircle(baseRect.topLeft + const Offset(5, 5), strokeWidth, paint);
          canvas.drawCircle(baseRect.topRight + const Offset(-5, 5), strokeWidth, paint);
          canvas.drawCircle(baseRect.bottomLeft + const Offset(5, -5), strokeWidth, paint);
          canvas.drawCircle(baseRect.bottomRight + const Offset(-5, -5), strokeWidth, paint);
        }
        break;

      case 4:
        double dashW = varVal < 10 ? 6.0 : 2.0;
        double spaceW = dashW + strokeWidth + 2.0;
        
        for (double i = 0; i < baseRect.width; i += dashW + spaceW) {
          double endX = (i + dashW > baseRect.width) ? baseRect.width : i + dashW;
          canvas.drawLine(Offset(baseRect.left + i, baseRect.top), Offset(baseRect.left + endX, baseRect.top), paint);
          canvas.drawLine(Offset(baseRect.left + i, baseRect.bottom), Offset(baseRect.left + endX, baseRect.bottom), paint);
        }
        for (double i = 0; i < baseRect.height; i += dashW + spaceW) {
          double endY = (i + dashW > baseRect.height) ? baseRect.height : i + dashW;
          canvas.drawLine(Offset(baseRect.left, baseRect.top + i), Offset(baseRect.left, baseRect.top + endY), paint);
          canvas.drawLine(Offset(baseRect.right, baseRect.top + i), Offset(baseRect.right, baseRect.top + endY), paint);
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant AdvancedBorderPainter oldDelegate) {
    return color != oldDelegate.color ||
           strokeWidth != oldDelegate.strokeWidth ||
           radius != oldDelegate.radius ||
           styleIndex != oldDelegate.styleIndex;
  }
}
