import 'package:flutter/material.dart';
import 'package:toktok_drawing/features/drawing/placeholder_drawing_screen.dart';
import 'package:toktok_drawing/features/free_drawing/free_drawing_screen.dart';
import 'package:toktok_drawing/features/mode_selection/models/mode_info.dart';
import 'package:toktok_drawing/features/mode_selection/widgets/mode_card.dart';
import 'package:toktok_drawing/shared/models/drawing_mode.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  /// 모드별 드로잉 화면으로 이동 (4.4).
  /// 태스크 5~8 구현 시 각 case를 실제 화면 위젯으로 교체.
  void _navigateToDrawing(BuildContext context, ModeInfo info) {
    final Widget screen = _buildDrawingScreen(info.mode, info.title);

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Widget _buildDrawingScreen(DrawingMode mode, String title) {
    // 각 모드별 실제 화면은 태스크 5~8에서 이 switch를 교체함
    switch (mode) {
      case DrawingMode.free:
        return const FreeDrawingScreen();
      case DrawingMode.trace:
        return PlaceholderDrawingScreen(
          mode: mode,
          title: title,
          onAutoSave: () async {
            // 태스크 6에서 TraceDrawingProvider.save() 연결
          },
        );
      case DrawingMode.colorBySymbol:
        return PlaceholderDrawingScreen(
          mode: mode,
          title: title,
          onAutoSave: () async {
            // 태스크 7에서 ColorBySymbolProvider.save() 연결
          },
        );
      case DrawingMode.symmetry:
        return PlaceholderDrawingScreen(
          mode: mode,
          title: title,
          onAutoSave: () async {
            // 태스크 8에서 SymmetryDrawingProvider.save() 연결
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _AppHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: ModeInfo.registry.length,
                  itemBuilder: (context, index) {
                    final info = ModeInfo.registry[index];
                    return ModeCard(
                      modeInfo: info,
                      index: index,
                      onTap: () => _navigateToDrawing(context, info),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          Text(
            '톡톡 그림판',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '어떤 그림을 그려볼까요?',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.black54,
                ),
          ),
        ],
      ),
    );
  }
}
