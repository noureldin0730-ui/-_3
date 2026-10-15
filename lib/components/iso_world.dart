import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../data/iso_helper.dart';
import '../data/level_data.dart';
import '../data/palette.dart';
import 'building.dart';

/// ============================================================
/// ISO WORLD — العالم كله
/// بيرسم:
///   - الأرضيات (شوارع + رصيف + نجيل) — isometric diamonds
///   - المباني — من ورا لقدام (depth sort)
///   - النخل وأعمدة النور
/// ============================================================
class IsoWorld extends PositionComponent {
  final List<Building> buildings = [];

  IsoWorld() : super(priority: -100);

  @override
  Future<void> onLoad() async {
    // نبني قائمة المباني من البيانات
    for (final b in LevelData.buildings) {
      final type = b['type'] as String;
      final colors = _colorsForType(type);
      buildings.add(Building(
        gx: b['x'] as int,
        gy: b['y'] as int,
        gw: b['w'] as int,
        gh: b['h'] as int,
        height: _heightForType(type),
        topColor: colors[0],
        leftColor: colors[1],
        rightColor: colors[2],
        label: b['label'] as String?,
      ));
    }

    // نضيفهم للعالم
    for (final b in buildings) {
      add(b);
    }
  }

  List<Color> _colorsForType(String type) {
    switch (type) {
      case 'cafe':
        return [
          Palette.buildingTopRed,
          Palette.buildingLeftRed,
          Palette.buildingRightRed,
        ];
      case 'market':
        return [
          Palette.buildingTopBlue,
          Palette.buildingLeftBlue,
          Palette.buildingRightBlue,
        ];
      case 'house':
        return [
          Palette.buildingTop,
          Palette.buildingLeft,
          Palette.buildingRight,
        ];
      case 'shop':
      default:
        return [
          Palette.buildingTop,
          Palette.buildingLeft,
          Palette.buildingRight,
        ];
    }
  }

  double _heightForType(String type) {
    switch (type) {
      case 'market':
        return 55;
      case 'cafe':
        return 45;
      case 'house':
        return 70;
      case 'shop':
      default:
        return 50;
    }
  }

  @override
  void render(Canvas canvas) {
    // ============= الأرضيات =============
    // نرسم من ورا لقدام عشان الترتيب يبقى صح
    final total = LevelData.cols + LevelData.rows;
    for (int sum = 0; sum <= total; sum++) {
      for (int gx = 0; gx < LevelData.cols; gx++) {
        final gy = sum - gx;
        if (gy < 0 || gy >= LevelData.rows) continue;

        final code = LevelData.bitashMap[gy][gx];
        if (code == 'B') continue; // المباني ليها رسمة خاصة

        final pos = Iso.gridToScreen(gx.toDouble(), gy.toDouble());
        final color = LevelData.tileColor(code);

        final path = Iso.diamondPath(Iso.tileW, Iso.tileH);
        canvas.save();
        canvas.translate(pos.x, pos.y);
        canvas.drawPath(path, Paint()..color = color);

        // خطوط خفيفة بين البلاطات
        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.black.withOpacity(0.10)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );

        // تفاصيل على الأسفلت (بقع، خطوط)
        if (code == 'R' && (gx + gy) % 7 == 0) {
          canvas.drawCircle(
            Offset(Iso.tileW / 2, Iso.tileH / 2),
            2,
            Paint()..color = Colors.black.withOpacity(0.15),
          );
        }

        canvas.restore();
      }
    }

    // ============= النخل =============
    for (final p in LevelData.palms) {
      _drawPalm(canvas, p[0], p[1]);
    }

    // ============= أعمدة النور =============
    for (final l in LevelData.lamps) {
      _drawLamp(canvas, l[0], l[1]);
    }
  }

  void _drawPalm(Canvas canvas, int gx, int gy) {
    final pos = Iso.gridToScreen(gx.toDouble(), gy.toDouble());
    canvas.save();
    canvas.translate(pos.x + Iso.tileW / 2, pos.y + Iso.tileH / 2);

    // ظل
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 20, height: 8),
      Paint()..color = Palette.shadow,
    );

    // الجزع
    canvas.drawRect(
      Rect.fromLTWH(-2, -30, 4, 30),
      Paint()..color = Palette.palmTrunk,
    );

    // السعف (5 أوراق)
    final leaf = Paint()..color = Palette.palmGreen;
    for (int i = 0; i < 5; i++) {
      final angle = (i - 2) * 0.5;
      canvas.save();
      canvas.translate(0, -30);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, -10), width: 6, height: 20),
        leaf,
      );
      canvas.restore();
    }

    canvas.restore();
  }

  void _drawLamp(Canvas canvas, int gx, int gy) {
    final pos = Iso.gridToScreen(gx.toDouble(), gy.toDouble());
    canvas.save();
    canvas.translate(pos.x + Iso.tileW / 2, pos.y + Iso.tileH / 2);

    // ظل
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 10, height: 4),
      Paint()..color = Palette.shadow,
    );

    // العمود
    canvas.drawRect(
      Rect.fromLTWH(-1, -28, 2, 28),
      Paint()..color = Palette.lampPost,
    );

    // اللمبة (دايرة صفرا)
    canvas.drawCircle(
      const Offset(0, -30),
      4,
      Paint()..color = const Color(0xFFFFE88A),
    );
    canvas.drawCircle(
      const Offset(0, -30),
      6,
      Paint()
        ..color = const Color(0xFFFFE88A).withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.restore();
  }
}