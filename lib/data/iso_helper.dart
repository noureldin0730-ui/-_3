import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// ============================================================
/// ISO HELPER — أساس الـ 2.5D
/// بيحول الـ grid العادي (مربعات) لـ isometric (معينات)
/// ============================================================
class Iso {
  // أبعاد الـ tile الـ isometric
  static const double tileW = 64.0; // عرض المعين
  static const double tileH = 32.0; // ارتفاع المعين (نص العرض)

  /// من grid (x, y) لـ screen (x, y)
  /// القاعدة: كل ما تروح يمين في الـ grid، تطلع يمين فوق
  ///          كل ما تروح تحت في الـ grid، تنزل يمين تحت
  static Vector2 gridToScreen(double gx, double gy) {
    final sx = (gx - gy) * (tileW / 2);
    final sy = (gx + gy) * (tileH / 2);
    return Vector2(sx, sy);
  }

  /// من screen لـ grid (لما نحتاج نترجم لمسة)
  static Vector2 screenToGrid(double sx, double sy) {
    final gx = (sx / (tileW / 2) + sy / (tileH / 2)) / 2;
    final gy = (sy / (tileH / 2) - sx / (tileW / 2)) / 2;
    return Vector2(gx, gy);
  }

  /// بيرسم شكل المعين (البلاطة)
  static Path diamondPath(double w, double h) {
    return Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w, h / 2)
      ..lineTo(w / 2, h)
      ..lineTo(0, h / 2)
      ..close();
  }

  /// بيرسم صندوق isometric (وش يمين + وش شمال + سطح)
  /// بيستخدم للمباني والعربيات
  static void drawIsoBox(
    Canvas canvas,
    Vector2 base,
    double w,
    double h,
    double height,
    Color topColor,
    Color leftColor,
    Color rightColor,
  ) {
    final halfW = w / 2;
    final halfH = h / 2;

    // الوش اليمين
    final right = Path()
      ..moveTo(base.x + halfW, base.y)
      ..lineTo(base.x + halfW, base.y - height)
      ..lineTo(base.x + w, base.y + halfH - height)
      ..lineTo(base.x + w, base.y + halfH)
      ..close();
    canvas.drawPath(right, Paint()..color = rightColor);

    // الوش الشمال
    final left = Path()
      ..moveTo(base.x - halfW, base.y)
      ..lineTo(base.x - halfW, base.y - height)
      ..lineTo(base.x - w, base.y + halfH - height)
      ..lineTo(base.x - w, base.y + halfH)
      ..close();
    canvas.drawPath(left, Paint()..color = leftColor);

    // السطح
    final top = Path()
      ..moveTo(base.x, base.y - height)
      ..lineTo(base.x + w, base.y + halfH - height)
      ..lineTo(base.x, base.y + h - height)
      ..lineTo(base.x - w, base.y + halfH - height)
      ..close();
    canvas.drawPath(top, Paint()..color = topColor);
  }
}