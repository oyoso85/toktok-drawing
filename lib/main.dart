import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toktok_drawing/app.dart';
import 'package:toktok_drawing/features/trace_drawing/data/trace_template_registry.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 앱 시작 시 도안 캐시 미리 로드 (백그라운드)
  TraceTemplateRegistry.loadAll();
  runApp(const ProviderScope(child: TokTokDrawingApp()));
}
