import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:toktok_drawing/shared/models/drawing_element.dart';
import 'package:toktok_drawing/shared/models/drawing_tool.dart';
import 'package:toktok_drawing/shared/models/rainbow_stroke.dart';
import 'package:toktok_drawing/shared/painters/stroke_painter_mixin.dart';

/// 터치 제스처를 받아 DrawingElement 목록을 그리는 캔버스 위젯.
/// 두 손가락 핀치로 최대 2배까지 확대/이동 가능.
///
/// 성능 최적화:
/// - 완성된 strokes → ui.Picture로 굽기(O(1) 재렌더)
/// - 현재 무지개 stroke → 새 세그먼트만 누적 캐시, 끝 캡만 재렌더
class DrawingCanvas extends StatefulWidget {
  final List<DrawingElement> elements;
  final DrawingElement? currentElement;
  final Color backgroundColor;
  final void Function(Offset) onPanStart;
  final void Function(Offset) onPanUpdate;
  final VoidCallback onPanEnd;
  final ui.FragmentProgram? pencilProgram;

  const DrawingCanvas({
    super.key,
    required this.elements,
    this.currentElement,
    required this.backgroundColor,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    this.pencilProgram,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  static const double _maxScale = 2.0;

  // ── 줌 상태 ────────────────────────────────────────────
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  double _scaleOnStart = 1.0;
  Offset _offsetOnStart = Offset.zero;
  Offset _focalOnStart = Offset.zero;
  bool _isDrawing = false;

  // ── 렌더링 캐시 ────────────────────────────────────────
  /// 완성된 elements 전체를 구운 Picture. endStroke/undo/redo 시에만 재빌드.
  ui.Picture? _completedPicture;
  int _completedCount = 0; // _completedPicture에 포함된 elements 수

  /// 무지개 stroke 누적 세그먼트를 GPU 텍스처로 구운 이미지.
  /// 매 [_kCheckpointInterval] 세그먼트마다 toImageSync()로 평탄화 → O(1) drawImage.
  ui.Image? _rainbowImage;
  int _checkpointSegCount = 0; // _rainbowImage에 구워진 세그먼트 수
  Size? _canvasSize; // toImageSync 해상도 결정용
  static const int _kCheckpointInterval = 10;

  // ── 라이프사이클 ────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _updateCompletedPicture();
  }

  @override
  void didUpdateWidget(DrawingCanvas old) {
    super.didUpdateWidget(old);
    // elements가 바뀌었을 때만 completed picture 재빌드
    if (!identical(widget.elements, old.elements) ||
        widget.pencilProgram != old.pencilProgram ||
        widget.backgroundColor != old.backgroundColor) {
      _updateCompletedPicture();
    }
    // currentElement가 바뀌었을 때 rainbow cache 업데이트
    if (!identical(widget.currentElement, old.currentElement)) {
      _updateRainbowCache();
    }
  }

  @override
  void dispose() {
    _completedPicture?.dispose();
    _rainbowImage?.dispose();
    super.dispose();
  }

  // ── 캐시 빌드 ──────────────────────────────────────────

  /// 완성된 elements를 Picture로 굽는다.
  /// - elements 추가(endStroke): 기존 Picture에 새 element만 그려 incremental 빌드
  /// - elements 감소(undo/clear): 처음부터 전체 재빌드
  void _updateCompletedPicture() {
    final elements = widget.elements;
    if (elements.length == _completedCount && _completedPicture != null) return;

    if (elements.isEmpty) {
      _completedPicture?.dispose();
      _completedPicture = null;
      _completedCount = 0;
      return;
    }

    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    final renderer = _Renderer(widget.pencilProgram);

    if (elements.length > _completedCount && _completedPicture != null) {
      // Incremental: 기존 그림 위에 새 element만 추가
      c.drawPicture(_completedPicture!);
      for (int i = _completedCount; i < elements.length; i++) {
        renderer.drawElement(c, elements[i]);
      }
    } else {
      // Full rebuild (undo/redo/clear 등)
      for (final el in elements) {
        renderer.drawElement(c, el);
      }
    }

    _completedPicture?.dispose();
    _completedPicture = recorder.endRecording();
    _completedCount = elements.length;
  }

  /// 무지개 캐시 초기화.
  void _resetRainbowCache() {
    _rainbowImage?.dispose();
    _rainbowImage = null;
    _checkpointSegCount = 0;
  }

  /// 현재 무지개 stroke의 세그먼트를 [_kCheckpointInterval]마다 GPU 이미지로 평탄화.
  /// 붓(brush) 변형은 속도 기반 굵기 계산 때문에 캐시 불가 → painter에 위임.
  void _updateRainbowCache() {
    final current = widget.currentElement;

    if (current is! RainbowStroke || current.tool == DrawingTool.brush) {
      _resetRainbowCache();
      return;
    }

    final totalSeg = current.points.length - 1;

    // 세그먼트 수가 줄었다 = 새 stroke 시작
    if (totalSeg < _checkpointSegCount) _resetRainbowCache();

    // 체크포인트 조건: 미구운 세그먼트가 임계치 이상이고 캔버스 크기를 알 때
    final pending = totalSeg - _checkpointSegCount;
    if (pending >= _kCheckpointInterval && _canvasSize != null) {
      _buildCheckpoint(current, totalSeg);
    }
  }

  /// 현재 stroke의 세그먼트 [0, upToSeg)를 GPU 텍스처로 평탄화.
  /// 이후 drawImage 한 번으로 O(1) 재생.
  void _buildCheckpoint(RainbowStroke stroke, int upToSeg) {
    final size = _canvasSize!;
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    final renderer = _Renderer(widget.pencilProgram);

    if (_rainbowImage != null) {
      // 기존 이미지 위에 새 세그먼트 추가
      c.drawImage(_rainbowImage!, Offset.zero, Paint());
    } else {
      // 첫 체크포인트: 시작 캡 포함 (blur 없이 — painter 레이어에서 적용)
      final startColor = stroke.colors.isNotEmpty ? stroke.colors[0] : const Color(0xFFFF0000);
      c.drawCircle(stroke.points.first, stroke.size / 2,
          Paint()..color = startColor..style = PaintingStyle.fill);
    }

    // 펜/색연필: drawLine + StrokeCap.round, 기타: drawVertices
    if (stroke.tool == DrawingTool.pen || stroke.tool == DrawingTool.pencil) {
      renderer.drawRainbowPenSegmentRange(c, stroke, _checkpointSegCount, upToSeg);
    } else {
      renderer.drawRainbowSegmentRange(c, stroke, _checkpointSegCount, upToSeg);
    }

    final picture = recorder.endRecording();
    final oldImage = _rainbowImage;
    // toImageSync: 동기적으로 GPU 텍스처 생성 (Flutter 3.7+)
    _rainbowImage = picture.toImageSync(size.width.round(), size.height.round());
    picture.dispose();
    oldImage?.dispose();
    _checkpointSegCount = upToSeg;
  }

  // ── 좌표 변환 ──────────────────────────────────────────
  Offset _toCanvas(Offset screenPt) => (screenPt - _offset) / _scale;

  void _clampOffset(Size size) {
    if (_scale <= 1.0) {
      _scale = 1.0;
      _offset = Offset.zero;
      return;
    }
    _offset = Offset(
      _offset.dx.clamp(size.width * (1.0 - _scale), 0.0),
      _offset.dy.clamp(size.height * (1.0 - _scale), 0.0),
    );
  }

  // ── 제스처 핸들러 ──────────────────────────────────────
  void _onScaleStart(ScaleStartDetails d) {
    _scaleOnStart = _scale;
    _offsetOnStart = _offset;
    _focalOnStart = d.localFocalPoint;

    if (d.pointerCount >= 2) {
      _isDrawing = false;
    } else {
      _isDrawing = true;
      widget.onPanStart(_toCanvas(d.localFocalPoint));
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails d, Size size) {
    if (d.pointerCount >= 2) {
      if (_isDrawing) {
        widget.onPanEnd();
        _isDrawing = false;
      }
      setState(() {
        final newScale = (_scaleOnStart * d.scale).clamp(1.0, _maxScale);
        final focalInCanvas = (_focalOnStart - _offsetOnStart) / _scaleOnStart;
        _scale = newScale;
        _offset = d.localFocalPoint - focalInCanvas * newScale;
        _clampOffset(size);
      });
    } else if (_isDrawing) {
      widget.onPanUpdate(_toCanvas(d.localFocalPoint));
    }
  }

  void _onScaleEnd(ScaleEndDetails d) {
    if (_isDrawing) widget.onPanEnd();
    _isDrawing = false;
  }

  // ── 빌드 ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _canvasSize = size;
        return GestureDetector(
          onScaleStart: _onScaleStart,
          onScaleUpdate: (d) => _onScaleUpdate(d, size),
          onScaleEnd: _onScaleEnd,
          child: ClipRect(
            child: Transform.translate(
              offset: _offset,
              child: Transform.scale(
                scale: _scale,
                alignment: Alignment.topLeft,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _CanvasPainter(
                      completedPicture: _completedPicture,
                      currentElement: widget.currentElement,
                      rainbowImage: _rainbowImage,
                      checkpointSegCount: _checkpointSegCount,
                      backgroundColor: widget.backgroundColor,
                      pencilProgram: widget.pencilProgram,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── StrokePainterMixin을 standalone으로 사용하기 위한 헬퍼 ──
class _Renderer with StrokePainterMixin {
  @override
  final ui.FragmentProgram? pencilProgram;
  _Renderer(this.pencilProgram);
}

// ── CustomPainter ──────────────────────────────────────
class _CanvasPainter extends CustomPainter with StrokePainterMixin {
  /// 완성된 모든 strokes를 구운 Picture (null = 아직 없음)
  final ui.Picture? completedPicture;
  final DrawingElement? currentElement;
  /// 무지개 stroke의 GPU 텍스처 체크포인트
  final ui.Image? rainbowImage;
  /// rainbowImage에 이미 구워진 세그먼트 수 (painter가 그 이후만 직접 그림)
  final int checkpointSegCount;
  final Color backgroundColor;
  @override
  final ui.FragmentProgram? pencilProgram;

  const _CanvasPainter({
    required this.completedPicture,
    required this.currentElement,
    required this.rainbowImage,
    required this.checkpointSegCount,
    required this.backgroundColor,
    this.pencilProgram,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = backgroundColor);

    // 완성된 strokes: saveLayer 밖 → GPU 텍스처 캐시 유지, O(1)
    if (completedPicture != null) canvas.drawPicture(completedPicture!);

    // 현재 그리는 element
    final current = currentElement;
    if (current != null) {
      if (current is RainbowStroke && current.tool != DrawingTool.brush) {
        // 무지개 pen: saveLayer 불필요 (BlendMode.clear 없음)
        // blur는 전체 레이어에 ImageFilter로 1회 적용
        final hasBlur = current.blurSigma > 0;
        if (hasBlur) {
          canvas.saveLayer(rect,
              Paint()..imageFilter = ui.ImageFilter.blur(
                  sigmaX: current.blurSigma, sigmaY: current.blurSigma));
        }
        // 1) 체크포인트 이미지: O(1) GPU blit
        if (rainbowImage != null) {
          canvas.drawImage(rainbowImage!, Offset.zero, Paint());
        } else if (current.points.isNotEmpty) {
          final startColor = current.colors.isNotEmpty ? current.colors[0] : const Color(0xFFFF0000);
          canvas.drawCircle(current.points.first, current.size / 2,
              Paint()..color = startColor..style = PaintingStyle.fill);
        }
        // 2) pending 세그먼트: drawVertices 1 call
        _drawPendingSegments(canvas, current);
        // 3) 끝 캡
        _drawEndCap(canvas, current);
        if (hasBlur) canvas.restore();
      } else {
        // 지우개 포함 다른 도구: saveLayer 유지 (BlendMode.clear 지원)
        canvas.saveLayer(rect, Paint());
        drawElement(canvas, current);
        canvas.restore();
      }
    }
  }

  /// 체크포인트 이후 미구운 세그먼트를 렌더.
  /// 펜/색연필: drawLine + StrokeCap.round (꺾임 부위 끊김 없음)
  /// 기타(무지개붓 기본값): drawVertices 삼각형 스트립
  void _drawPendingSegments(Canvas canvas, RainbowStroke stroke) {
    final totalSeg = stroke.points.length - 1;
    if (totalSeg <= checkpointSegCount) return;
    if (stroke.tool == DrawingTool.pen || stroke.tool == DrawingTool.pencil) {
      drawRainbowPenSegmentRange(canvas, stroke, checkpointSegCount, totalSeg);
    } else {
      drawRainbowSegmentRange(canvas, stroke, checkpointSegCount, totalSeg);
    }
  }

  /// 끝 캡: 매 프레임 마지막 포인트 색상으로 재렌더
  void _drawEndCap(Canvas canvas, RainbowStroke stroke) {
    if (stroke.points.isEmpty) return;
    final color = stroke.colors.isNotEmpty ? stroke.colors.last : const Color(0xFFFF0000);
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    if (stroke.blurSigma > 0) paint.maskFilter = MaskFilter.blur(BlurStyle.normal, stroke.blurSigma);
    canvas.drawCircle(stroke.points.last, stroke.size / 2, paint);
  }

  @override
  bool shouldRepaint(_CanvasPainter old) =>
      !identical(old.completedPicture, completedPicture) ||
      !identical(old.currentElement, currentElement) ||
      !identical(old.rainbowImage, rainbowImage) ||
      old.checkpointSegCount != checkpointSegCount ||
      old.backgroundColor != backgroundColor ||
      old.pencilProgram != pencilProgram;
}
