import 'package:flutter/material.dart';
import 'package:toktok_drawing/shared/models/drawing_mode.dart';

/// 그리기 화면 플레이스홀더.
/// 태스크 5~8에서 각 모드별 실제 화면으로 교체될 예정.
///
/// [onAutoSave]: 화면 이탈(뒤로/홈) 시 자동 저장을 트리거하는 콜백.
/// 각 모드별 실제 화면 구현 시 이 시그니처를 그대로 유지해야 함.
class PlaceholderDrawingScreen extends StatelessWidget {
  final DrawingMode mode;
  final String title;
  final Future<void> Function()? onAutoSave;

  const PlaceholderDrawingScreen({
    super.key,
    required this.mode,
    required this.title,
    this.onAutoSave,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 뒤로 나가기 전 자동 저장 실행 (4.5)
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop && onAutoSave != null) {
          await onAutoSave!();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.construction_rounded, size: 80),
              const SizedBox(height: 16),
              Text(
                '$title 화면',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '구현 예정',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
