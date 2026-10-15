import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../components/iso_world.dart';
import '../components/station.dart';
import '../components/vehicle.dart';
import '../data/level_data.dart';

enum GameStatus { playing, finished }

class BitashGame extends FlameGame with DragCallbacks, TapCallbacks {
  final VehicleType vehicleType;
  final void Function(GameStatus status) onStatusChange;

  late Vehicle vehicle;
  final List<Station> stations = [];

  int money = 0;
  int delivered = 0;
  int totalStations = 0;

  GameStatus _status = GameStatus.playing;

  BitashGame({
    required this.vehicleType,
    required this.onStatusChange,
  });

  @override
  Color backgroundColor() => const Color(0xFF7AC0E8);

  @override
  Future<void> onLoad() async {
    // 1. العالم (الأرضيات والمباني)
    add(IsoWorld());

    // 2. المحطات والزباين
    for (final s in LevelData.stations) {
      final station = Station(
        gx: s['x'] as int,
        gy: s['y'] as int,
        name: s['name'] as String,
        color: Color(s['color'] as int),
      );
      stations.add(station);
      add(station);
    }
    totalStations = stations.length;

    // 3. العربية
    vehicle = Vehicle(
      type: vehicleType,
      gx: LevelData.playerStartX.toDouble(),
      gy: LevelData.playerStartY.toDouble(),
    );
    add(vehicle);

    // 4. الكاميرا تتبع العربية
    camera.follow(vehicle);
    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.zoom = 1.0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_status != GameStatus.playing) return;

    // ====== استقبال الزبون ======
    if (vehicle.isIdle && vehicle.hasSpace) {
      for (final station in stations) {
        final p = station.passenger;
        if (p == null) continue;
        if (p.state.name != 'waiting') continue;

        // لو العربية واقفة على المحطة
        final dx = station.gx - vehicle.gx;
        final dy = station.gy - vehicle.gy;
        if (dx.abs() < 0.5 && dy.abs() < 0.5) {
          // الزبون يركب
          vehicle.pickUp('p_${station.gx}_${station.gy}');
          p.ride();
        }
      }
    }

    // ====== توصيل الزبون ======
    if (vehicle.passengers.isNotEmpty) {
      for (final station in stations) {
        final p = station.passenger;
        if (p == null) continue;
        if (p.state.name == 'waiting') continue;
        if (p.state.name == 'delivered') continue;

        // لو الزبون ده راكب، ووصلنا لمحطة تانية
        final id = 'p_${station.gx}_${station.gy}';
        if (vehicle.passengers.contains(id)) {
          final dx = station.gx - vehicle.gx;
          final dy = station.gy - vehicle.gy;
          if (dx.abs() < 0.5 && dy.abs() < 0.5) {
            // الزبون ينزل — يدفع
            vehicle.dropOff(id);
            money += vehicleType == VehicleType.tuktuk ? 20 : 10;
            delivered++;
            p.deliver();
          }
        }
      }
    }

    // ====== نهاية المرحلة ======
    if (delivered >= totalStations) {
      _finish();
    }
  }

  void _finish() {
    if (_status == GameStatus.finished) return;
    _status = GameStatus.finished;
    onStatusChange(GameStatus.finished);
  }

  // ============================================================
  // التحكم — Swipe
  // ============================================================
  Vector2? _dragStart;

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _dragStart = event.localPosition.clone();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (_dragStart == null) return;

    final current = event.localEndPosition;
    final dx = current.x - _dragStart!.x;
    final dy = current.y - _dragStart!.y;

    // محتاجين سحبة أكبر من 40 بكسل
    if (dx.abs() < 40 && dy.abs() < 40) return;

    // نحدد الاتجاه حسب الـ isometric:
    // swipe يمين → العربية تروح يمين-فوق (x+, y-)
    // swipe شمال → العربية تروح شمال-تحت (x-, y+)
    // swipe فوق → العربية تروح شمال-فوق (x-, y-)
    // swipe تحت → العربية تروح يمين-تحت (x+, y+)

    int tx = vehicle.gx.floor();
    int ty = vehicle.gy.floor();

    if (dx.abs() > dy.abs()) {
      // حركة أفقية
      if (dx > 0) {
        // يمين → يروح على x +1
        tx += 1;
      } else {
        // شمال → يروح على x -1
        tx -= 1;
      }
    } else {
      // حركة رأسية
      if (dy > 0) {
        // تحت → يروح على y +1
        ty += 1;
      } else {
        // فوق → يروح على y -1
        ty -= 1;
      }
    }

    // نحاول نحرك العربية
    vehicle.moveTo(tx, ty);
    _dragStart = current.clone();
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _dragStart = null;
  }

  // ============================================================
  // التحكم — Tap (لو حبيت نستخدم مكان مباشر)
  // ============================================================
  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    // نترجم اللمسة لـ grid، والكاميرا في نص الشاشة
    final screenPos = event.localPosition;

    // نستخدم الكاميرا لترجم الشاشة لـ world
    final worldPos = camera.viewfinder.position + 
        (screenPos - Vector2(size.x / 2, size.y / 2)) / camera.viewfinder.zoom;

    // نحوّل world لـ grid
    // (تقديري — بنستخدم iso_helper)
    // نستخدم النسبة العكسية
    // screen x = (gx - gy) * tileW/2
    // screen y = (gx + gy) * tileH/2
    // يعني: gx = (sx / (tileW/2) + sy / (tileH/2)) / 2
    //        gy = (sy / (tileH/2) - sx / (tileW/2)) / 2
    final sx = worldPos.x;
    final sy = worldPos.y;
    final gx = (sx / 32 + sy / 16) / 2;
    final gy = (sy / 16 - sx / 32) / 2;

    if (gx >= 0 && gy >= 0 && gx < LevelData.cols && gy < LevelData.rows) {
      vehicle.moveTo(gx.floor(), gy.floor());
    }
  }
}