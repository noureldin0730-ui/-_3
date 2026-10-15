import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../data/iso_helper.dart';
import '../data/palette.dart';

/// ============================================================
/// BUILDING — مبنى واحد بـ 3D effect isometric
/// بياخد موقعه في الـ grid، وبيرسم:
///   - وش يمين (داكن)
///   - وش شمال (فاتح)
///   - سطح (أفتح)
///   - لافتة باسم المكان
/// ============================================================
class Building extends PositionComponent {
  final int gx;
  final int gy;
  final int gw; // عرض المبنى بالـ tiles
  final int gh; // ارتفاع المبنى بالـ tiles
  final double height; // ارتفاع المبنى بالبكسل
  final Color topColor;
  final Color leftColor;
  final Color rightColor;
  final String? label;

  Building({
    required this.gx,
    required this.gy,
    this.gw = 1,
    this.gh = 1,
    this.height = 60,
    required this.topColor,
    required this.leftColor,
    required this.rightColor,
    this.label,
  }) : super(priority: (gx + gy) * 10);

  @override
  void render(Canvas canvas) {
    // نحسب موقع القاعدة (نص المبنى)
    final centerX = gx + (gw - 1) / 2;
    final centerY = gy + (gh - 1) / 2;
    final base = Iso.gridToScreen(centerX, centerY);

    // عرض المبنى = عرض الـ tile × عرضه بالـ tiles
    final w = Iso.tileW * gw;
    final h = Iso.tileH * gh;

    canvas.save();
    canvas.translate(base.x, base.y);

    // ظل المبنى على الأرض
    final shadowPath = Iso.diamondPath(w * 1.05, h * 1.05);
    canvas.drawPath(
      shadowPath,
      Paint()..color = Palette.shadow,
    );

    // نرسم المبنى (وش يمين + وش شمال + سطح)
    Iso.drawIsoBox(
      canvas,
      Vector2(w / 2, 0),
      w / 2,
      h / 2,
      height,
      topColor,
      leftColor,
      rightColor,
    );

    // لافتة باسم المكان
    if (label != null && label!.isNotEmpty) {
      _drawLabel(canvas, w / 2, -height - 8);
    }

    canvas.restore();
  }

  void _drawLabel(Canvas canvas, double cx, double cy) {
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Palette.signText,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // خلفية اللافتة
    final padX = 6.0;
    final padY = 3.0;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        cx - tp.width / 2 - padX,
        cy - tp.height / 2 - padY,
        tp.width + padX * 2,
        tp.height + padY * 2,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(rect, Paint()..color = Palette.signboard);
    canvas.drawRRect(
      rect,
      Paint()
        ..color = Palette.signText
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    tp.paint(
      canvas,
      Offset(cx - tp.width / 2, cy - tp.height / 2),
    );
  }
}