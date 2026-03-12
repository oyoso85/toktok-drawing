import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toktok_drawing/features/trace_drawing/models/trace_template.dart';
import 'package:toktok_drawing/features/trace_drawing/providers/trace_drawing_provider.dart';
import 'package:toktok_drawing/features/trace_drawing/providers/trace_drawing_state.dart';
import 'package:toktok_drawing/features/trace_drawing/widgets/template_list_screen.dart';
import 'package:toktok_drawing/features/trace_drawing/widgets/trace_canvas.dart';
import 'package:toktok_drawing/shared/models/sparkle_element.dart';
import 'package:toktok_drawing/shared/widgets/drawing_toolbar.dart';
import 'package:toktok_drawing/shared/widgets/sparkle_object_widget.dart';

class TraceDrawingScreen extends ConsumerStatefulWidget {
  const TraceDrawingScreen({super.key});

  @override
  ConsumerState<TraceDrawingScreen> createState() => _TraceDrawingScreenState();
}

class _TraceDrawingScreenState extends ConsumerState<TraceDrawingScreen> {
  TraceTemplate? _selectedTemplate;
  ui.FragmentProgram? _pencilProgram;
  final List<SparkleObject> _animatingObjects = [];

  @override
  void initState() {
    super.initState();
    _loadPencilShader();
  }

  Future<void> _loadPencilShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset('assets/shaders/pencil.frag');
      if (mounted) setState(() => _pencilProgram = program);
    } catch (e) {
      debugPrint('trace pencil shader load FAILED: $e');
    }
  }

  void _selectTemplate(TraceTemplate tmpl) {
    ref.read(traceDrawingProvider.notifier).resetForTemplate();
    setState(() => _selectedTemplate = tmpl);
  }

  void _backToList() {
    setState(() => _selectedTemplate = null);
  }

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
              setState(() => _animatingObjects.clear());
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
      return TemplateListScreen(onSelected: _selectTemplate);
    }

    // 꽃씨 붓 새 파티클 감지 → 애니메이션 큐에 추가
    ref.listen<TraceDrawingState>(traceDrawingProvider, (prev, next) {
      final prevCurrent = prev?.currentElement;
      final nextCurrent = next.currentElement;
      if (nextCurrent is SparkleElement) {
        final prevCount = prevCurrent is SparkleElement ? prevCurrent.objects.length : 0;
        final newObjects = nextCurrent.objects.skip(prevCount).toList();
        if (newObjects.isNotEmpty) {
          setState(() => _animatingObjects.addAll(newObjects));
        }
      }
    });

    final state = ref.watch(traceDrawingProvider);
    final notifier = ref.read(traceDrawingProvider.notifier);

    return PopScope(
      onPopInvokedWithResult: (didPop, _) async {},
      child: Scaffold(
        appBar: AppBar(
          title: Text(_selectedTemplate!.name),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _backToList,
          ),
          actions: [
            IconButton(
              tooltip: '전체 지우기',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _confirmClear(context),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  TraceCanvas(
                    template: _selectedTemplate!,
                    elements: state.elements,
                    currentElement: state.currentElement,
                    onPanStart: notifier.startStroke,
                    onPanUpdate: notifier.addPoint,
                    onPanEnd: notifier.endStroke,
                    pencilProgram: _pencilProgram,
                  ),
                  // 꽃씨 붓 피어나는 애니메이션 오버레이
                  ..._animatingObjects.map((obj) => SparkleObjectWidget(
                        key: ValueKey(identityHashCode(obj)),
                        object: obj,
                        onComplete: () {
                          if (mounted) setState(() => _animatingObjects.remove(obj));
                        },
                      )),
                ],
              ),
            ),
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
