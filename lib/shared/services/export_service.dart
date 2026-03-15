import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

class ExportService {
  /// RenderRepaintBoundary에서 PNG 바이트를 추출
  Future<Uint8List?> capturePng(RenderRepaintBoundary boundary, {double pixelRatio = 3.0}) async {
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  /// TODO: 갤러리 저장 미구현 (image_gallery_saver 호환성 문제로 임시 제거)
  Future<bool> saveToGallery(Uint8List pngBytes, {String name = 'toktok_drawing'}) async {
    return false;
  }
}
