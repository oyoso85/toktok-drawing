import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:toktok_drawing/shared/models/sparkle_element.dart';

/// 단일 SparkleObject를 Canvas에 그리는 유틸 함수 모음.
/// CustomPainter와 애니메이션 위젯 양쪽에서 공유 사용.
void drawSparkleObject(Canvas canvas, SparkleObject obj, {double scale = 1.0}) {
  canvas.save();
  canvas.translate(obj.position.dx, obj.position.dy);
  canvas.rotate(obj.rotation);
  canvas.scale(scale);

  final paint = Paint()
    ..color = obj.color
    ..style = PaintingStyle.fill;

  final r = obj.finalSize / 2;
  switch (obj.shape) {
    case SparkleShape.star:
      _drawStar(canvas, r, paint);
    case SparkleShape.heart:
      _drawHeart(canvas, r, paint);
    case SparkleShape.circle:
      canvas.drawCircle(Offset.zero, r, paint);
  }

  canvas.restore();
}

void _drawStar(Canvas canvas, double radius, Paint paint) {
  const numPoints = 5;
  final innerRadius = radius * 0.42;
  final path = Path();

  for (int i = 0; i < numPoints * 2; i++) {
    final r = i.isEven ? radius : innerRadius;
    final angle = (i * math.pi / numPoints) - math.pi / 2;
    final x = r * math.cos(angle);
    final y = r * math.sin(angle);
    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }
  path.close();
  canvas.drawPath(path, paint);
}

void _drawHeart(Canvas canvas, double radius, Paint paint) {
  final s = radius;
  final path = Path();
  path.moveTo(0, s * 0.4);
  path.cubicTo(-s * 1.0, -s * 0.1, -s * 1.0, s * 0.6, 0, s * 1.0);
  path.cubicTo(s * 1.0, s * 0.6, s * 1.0, -s * 0.1, 0, s * 0.4);
  path.close();
  canvas.drawPath(path, paint);
}

/// 좌표계가 오브젝트 중심(0,0) 기준인 CustomPainter용 static painter.
class SparkleObjectPainter extends CustomPainter {
  final SparkleObject object;
  final double scale;

  const SparkleObjectPainter(this.object, {this.scale = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final centered = SparkleObject(
      position: Offset(size.width / 2, size.height / 2),
      shape: object.shape,
      color: object.color,
      finalSize: object.finalSize,
      rotation: object.rotation,
    );
    drawSparkleObject(canvas, centered, scale: scale);
  }

  @override
  bool shouldRepaint(SparkleObjectPainter old) =>
      old.object != object || old.scale != scale;
}
