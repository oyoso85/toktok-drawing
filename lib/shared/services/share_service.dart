import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  /// PNG 바이트를 임시 파일로 저장 후 OS 공유 시트 실행
  Future<void> shareImage(Uint8List pngBytes, {String fileName = 'drawing.png'}) async {
    final tempDir = await getTemporaryDirectory();
    final file = File(p.join(tempDir.path, fileName));
    await file.writeAsBytes(pngBytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'TokTok Drawing',
    );
  }
}
