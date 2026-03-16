import 'package:flutter/material.dart';

/// 선 따라 그리기 히트존.
/// SVG Path를 [segmentCount]개로 샘플링한 포인트 목록과
/// 각 포인트가 커버됐는지 추적하는 bool 배열을 갖는다.
class HitZone {
  static const segmentCount = 400;

  final List<Offset> segments;
  final double hitRadius;
  final List<bool> segmentCovered;

  /// 클리핑 Path 캐시 — 최초 접근 시 한 번만 생성 (히트존 형태 불변).
  Path? _clipPathCache;

  HitZone._({
    required this.segments,
    required this.hitRadius,
    required this.segmentCovered,
  });

  /// Path와 캔버스 크기, hitRadius로 히트존 생성.
  factory HitZone.fromPath(Path path, double hitRadius) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) {
      return HitZone._(
        segments: [],
        hitRadius: hitRadius,
        segmentCovered: [],
      );
    }

    // 전체 경로 길이
    final totalLength = metrics.fold(0.0, (sum, m) => sum + m.length);
    final step = totalLength / segmentCount;

    final segments = <Offset>[];

    for (int i = 0; i < segmentCount; i++) {
      final targetDist = step * i;
      // 어느 metric 구간인지 찾기
      double localDist = targetDist;
      int mi = 0;
      while (mi < metrics.length - 1 && localDist > metrics[mi].length) {
        localDist -= metrics[mi].length;
        mi++;
      }
      localDist = localDist.clamp(0.0, metrics[mi].length);
      final tangent = metrics[mi].getTangentForOffset(localDist);
      if (tangent != null) {
        segments.add(tangent.position);
      }
    }

    // 마지막 포인트 보정 (정확히 segmentCount개)
    while (segments.length < segmentCount) {
      segments.add(segments.last);
    }

    return HitZone._(
      segments: segments,
      hitRadius: hitRadius,
      segmentCovered: List.filled(segments.length, false),
    );
  }

  /// 점이 히트존 내부인지 판정.
  bool isInZone(Offset point) {
    for (final seg in segments) {
      if ((point - seg).distance <= hitRadius) return true;
    }
    return false;
  }

  /// 점 근처 세그먼트들을 커버됨으로 표시하고 변경된 인덱스 반환.
  List<int> coverNear(Offset point) {
    final changed = <int>[];
    for (int i = 0; i < segments.length; i++) {
      if (!segmentCovered[i] && (point - segments[i]).distance <= hitRadius) {
        segmentCovered[i] = true;
        changed.add(i);
      }
    }
    return changed;
  }

  /// 커버된 세그먼트 비율 (0.0 ~ 1.0).
  double get coverage {
    if (segments.isEmpty) return 0.0;
    final count = segmentCovered.where((v) => v).length;
    return count / segments.length;
  }

  /// 커버리지 초기화.
  void reset() {
    for (int i = 0; i < segmentCovered.length; i++) {
      segmentCovered[i] = false;
    }
  }

  /// 히트존 클리핑 Path — 최초 접근 시 한 번만 생성 후 캐시.
  Path get clipPath {
    return _clipPathCache ??= _buildClipPath();
  }

  Path _buildClipPath() {
    final path = Path();
    for (final seg in segments) {
      path.addOval(Rect.fromCircle(center: seg, radius: hitRadius));
    }
    return path;
  }
}
