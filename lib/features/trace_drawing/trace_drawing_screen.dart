import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toktok_drawing/features/trace_drawing/models/trace_template.dart';
import 'package:toktok_drawing/features/trace_drawing/providers/trace_drawing_provider.dart';
import 'package:toktok_drawing/features/trace_drawing/widgets/template_list_screen.dart';
import 'package:toktok_drawing/features/trace_drawing/widgets/trace_canvas.dart';
import 'package:toktok_drawing/shared/widgets/drawing_toolbar.dart';

/// 6.1 템플릿 선택 → 6.3~6.6 드로잉 흐름을 관리하는 최상위 화면.
class TraceDrawingScreen extends ConsumerStatefulWidget {
  const TraceDrawingScreen({super.key});

  @override
  ConsumerState<TraceDrawingScreen> createState() => _TraceDrawingScreenState();
}

class _TraceDrawingScreenState extends ConsumerState<TraceDrawingScreen> {
  TraceTemplate? _selectedTemplate;

  void _selectTemplate(TraceTemplate tmpl) {
    ref.read(traceDrawingProvider.notifier).resetForTemplate();
    setState(() => _selectedTemplate = tmpl);
  }

  void _backToList() {
    setState(() => _selectedTemplate = null);
  }

  // 6.6 전체 지우기 확인 다이얼로그
  void _confirmClear(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('전체 지우기'),
        content: const Text('그린 선을 모두 지울까요?\n가이드 선은 그대로 남아요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(traceDrawingProvider.notifier).clearStrokes();
              Navigator.of(ctx).pop();
            },
            child: const Text('지우기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedTemplate == null) {
      // 6.1 템플릿 목록 화면
      return TemplateListScreen(onSelected: _selectTemplate);
    }

    // 6.3~6.6 드로잉 화면
    final state = ref.watch(traceDrawingProvider);
    final notifier = ref.read(traceDrawingProvider.notifier);

    return PopScope(
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) return;
        // TODO(task-9): 자동 저장 연동
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_selectedTemplate!.name),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _backToList,
          ),
          actions: [
            // 6.6 전체 지우기
            IconButton(
              tooltip: '전체 지우기',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _confirmClear(context),
            ),
          ],
        ),
        body: Column(
          children: [
            // 6.3+6.4 캔버스
            Expanded(
              child: TraceCanvas(
                template: _selectedTemplate!,
                strokes: state.strokes,
                currentStroke: state.currentStroke,
                onPanStart: notifier.startStroke,
                onPanUpdate: notifier.addPoint,
                onPanEnd: notifier.endStroke,
              ),
            ),
            // 6.5 색상 + 도구 선택 툴바 (기존 공통 위젯 재사용)
            DrawingToolbar(
              selectedColor: state.selectedColor,
              selectedSize: state.selectedSize,
              selectedTool: state.selectedTool,
              canUndo: state.canUndo,
              canRedo: state.canRedo,
              onColorChanged: notifier.changeColor,
              onSizeChanged: notifier.changeSize,
              onToolChanged: notifier.changeTool,
              onUndo: notifier.undo,
              onRedo: notifier.redo,
            ),
          ],
        ),
      ),
    );
  }
}
