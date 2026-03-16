import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toktok_drawing/app.dart';
import 'package:toktok_drawing/features/trace_drawing/data/trace_template_registry.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 가로 모드 고정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  // 상태바·내비게이션 바 숨김 (캔버스 최대 확보)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  // 앱 시작 시 도안 캐시 미리 로드 (백그라운드)
  TraceTemplateRegistry.loadAll();
  runApp(const ProviderScope(child: TokTokDrawingApp()));
}
