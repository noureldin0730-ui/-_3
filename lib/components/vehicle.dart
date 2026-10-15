import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

import '../data/iso_helper.dart';
import '../data/level_data.dart';
import '../data/palette.dart';

enum VehicleType { tuktuk, microbus }

/// ============================================================
/// VEHICLE — التوك توك أو الميكروباص (بصور AI)
/// ============================================================
class Vehicle extends PositionComponent {
  final VehicleType type;

  double gx;
  double gy;
  Vector2? target;
  int facing = 2;

  final List<String> passengers = [];
  int maxPassengers;

  int totalEarned = 0;
  int totalDelivered = 0;

  double engineShake = 0;

  Sprite? _sprite;

  // حجم العرض على الشاشة
  static const double renderW = 96.0;
  static const double renderH = 96.0;

  Vehicle({
    required this.type,
    required this.gx,
    required this.gy,
  })  : maxPassengers = type == VehicleType.tuktuk ? 1 : 7,
        super(priority: 500);

  @override
  Future<void> onLoad() async {
    final path = type == VehicleType.tuktuk
        ? 'assets/images/vehicles/tuktuk.png'
        : 'assets/images/vehicles/microbus.png';

    final image = await Flame.images.load(path, key: path);

    _sprite = Sprite(image);
  }

  @override
  void update(double dt) {
    engineShake += dt * 20;
    if (target == null) return;

    final dx = target!.x - gx;
    final dy = target!.y - gy;
    final dist = math.sqrt(dx * dx + dy * dy);

    if (dist < 0.05) {
      gx = target!.x;
      gy = target!.y;
      target = null;
      return;
    }

    final speed = type == VehicleType.tuktuk ? 4.0 : 3.0;
    final step = speed * dt;

    gx += (dx / dist) * step;
    gy += (dy / dist) * step;

    if (dx.abs() > dy.abs()) {
      facing = dx > 0 ? 1 : 3;
    } else {
      facing = dy > 0 ? 2 : 0;
    }
  }

  void moveTo(int tx, int ty) {
    if (tx < 0 || tx >= LevelData.cols) return;
    if (ty < 0 || ty >= LevelData.rows) return;
    if (LevelData.bitashMap[ty][tx] == 'B') return;
    target = Vector2(tx.toDouble(), ty.toDouble());
  }

  bool get isIdle => target == null;
  bool get hasSpace => passengers.length < maxPassengers;

  bool pickUp(String id) {
    if (!hasSpace) return false;
    passengers.add(id);
    return true;
  }

  bool dropOff(String id) {
    final removed = passengers.remove(id);
    if (removed) totalDelivered++;
    return removed;
  }

  @override
  void render(Canvas canvas) {
    final base = Iso.gridToScreen(gx, gy);
    canvas.save();
    canvas.translate(base.x + Iso.tileW / 2, base.y + Iso.tileH / 2);

    // اهتزاز المحرك
    final shakeX = math.sin(engineShake) * 0.8;
    final shakeY = math.cos(engineShake * 1.3) * 0.5;
    canvas.translate(shakeX, shakeY);

    // ظل
    final shadowW = type == VehicleType.tuktuk ? 30.0 : 48.0;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, renderH / 2 - 8),
        width: shadowW,
        height: shadowW * 0.4,
      ),
      Paint()..color = Palette.shadow,
    );

    // الصورة
    if (_sprite != null) {
      _sprite!.render(
        canvas,
        position: Vector2(-renderW / 2, -renderH / 2),
        size: Vector2(renderW, renderH),
      );
    } else {
      // fallback — مستطيل صغير لحد ما الصورة تتحمل
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: 40,
          height: 30,
        ),
        Paint()..color = type == VehicleType.tuktuk
            ? Palette.tuktukYellow
            : Palette.microbusWhite,
      );
    }

    canvas.restore();
  }
}