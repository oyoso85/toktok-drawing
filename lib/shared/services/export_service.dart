import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class ExportService {
  /// RenderRepaintBoundary에서 PNG 바이트를 추출
  Future<Uint8List?> capturePng(RenderRepaintBoundary boundary, {double pixelRatio = 3.0}) async {
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  /// PNG 바이트를 기기 갤러리에 저장
  Future<bool> saveToGallery(Uint8List pngBytes, {String name = 'toktok_drawing'}) async {
    final result = await ImageGallerySaver.saveImage(
      pngBytes,
      name: '${name}_${DateTime.now().millisecondsSinceEpoch}',
      quality: 100,
    );
    return result['isSuccess'] == true;
  }
}
