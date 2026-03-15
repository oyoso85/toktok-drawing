import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toktok_drawing/features/coloring/widgets/completion_overlay.dart';
import 'package:toktok_drawing/features/trace_drawing/data/trace_template_registry.dart';
import 'package:toktok_drawing/features/trace_drawing/models/trace_template.dart';
import 'package:toktok_drawing/features/trace_drawing/providers/trace_drawing_provider.dart';
import 'package:toktok_drawing/features/trace_drawing/providers/trace_drawing_state.dart';
import 'package:toktok_drawing/features/trace_drawing/widgets/template_list_screen.dart';
import 'package:toktok_drawing/features/trace_drawing/widgets/trace_canvas.dart';
import 'package:toktok_drawing/shared/models/sparkle_element.dart';
import 'package:toktok_drawing/shared/widgets/animated_pressable.dart';
import 'package:toktok_drawing/shared/widgets/drawing_toolbar.dart';
import 'package:toktok_drawing/shared/widgets/sparkle_object_widget.dart';

class TraceDrawingScreen extends ConsumerStatefulWidget {
  const TraceDrawingScreen({super.key});

  @override
  ConsumerState<TraceDrawingScreen> createState() => _TraceDrawingScreenState();
}

class _TraceDrawingScreenState extends ConsumerState<TraceDrawingScreen>
    with TickerProviderStateMixin {
  List<TraceTemplate> _registry = [];
  bool _loading = true;

  int _currentIndex = 0;
  bool _showingList = true;

  ui.FragmentProgram? _pencilProgram;
  final List<SparkleObject> _animatingObjects = [];

  bool _showCompletionOverlay = false;
  bool _showNextButton = false;

  Size? _lastInitializedSize;
  int _lastInitializedIndex = -1;

  // 완성 애니메이션: 일러스트 opacity 0.1→1.0, 스트로크 opacity 1.0→0.0
  late final AnimationController _completionCtrl;
  late final Animation<double> _illAnim;
  late final Animation<double> _strokeAnim;

  TraceTemplate get _currentTemplate => _registry[_currentIndex];

  @override
  void initState() {
    super.initState();
    _completionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..addListener(() => setState(() {}));

    _illAnim = Tween<double>(begin: 0.1, end: 1.0).animate(
      CurvedAnimation(parent: _completionCtrl, curve: Curves.easeIn),
    );
    _strokeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _completionCtrl, curve: Curves.easeOut),
    );

    _loadAll();
    _loadPencilShader();
  }

  @override
  void dispose() {
    _completionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final templates = await TraceTemplateRegistry.loadAll();
    if (mounted) setState(() { _registry = templates; _loading = false; });
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
    final idx = _registry.indexOf(tmpl);
    _completionCtrl.reset();
    setState(() {
      _currentIndex = idx < 0 ? 0 : idx;
      _showingList = false;
      _showCompletionOverlay = false;
      _showNextButton = false;
      _lastInitializedSize = null;
      _lastInitializedIndex = -1;
    });
  }

  void _onCanvasSizeChanged(Size size) {
    if (_lastInitializedSize == size && _lastInitializedIndex == _currentIndex) return;
    _lastInitializedSize = size;
    _lastInitializedIndex = _currentIndex;
    ref.read(traceDrawingProvider.notifier).resetForTemplate(_currentTemplate, size);
  }

  void _backToList() {
    _completionCtrl.reset();
    setState(() {
      _showingList = true;
      _showCompletionOverlay = false;
      _showNextButton = false;
    });
  }

  void _confirmClear(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('전체 지우기'),
        content: const Text('그린 선을 모두 지울까요?'),
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

  void _goNextTemplate() {
    final nextIndex = (_currentIndex + 1) % _registry.length;
    _completionCtrl.reset();
    setState(() {
      _currentIndex = nextIndex;
      _showCompletionOverlay = false;
      _showNextButton = false;
      _animatingObjects.clear();
      _lastInitializedSize = null;
      _lastInitializedIndex = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_showingList) {
      return TemplateListScreen(
        templates: _registry,
        onSelected: _selectTemplate,
      );
    }

    // 꽃씨 붓 파티클 + 완성 감지
    ref.listen<TraceDrawingState>(traceDrawingProvider, (prev, next) {
      final prevCurrent = prev?.currentElement;
      final nextCurrent = next.currentElement;
      if (nextCurrent is SparkleElement) {
        final prevCount = prevCurrent is SparkleElement ? prevCurrent.objects.length : 0;
        final newObjects = nextCurrent.objects.skip(prevCount).toList();
        if (newObjects.isNotEmpty) setState(() => _animatingObjects.addAll(newObjects));
      }
      if (!(prev?.isCompleted ?? false) && next.isCompleted) {
        // 완성: confetti + 일러스트 reveal + 스트로크 fade-out 동시 시작
        setState(() { _showCompletionOverlay = true; _showNextButton = false; });
        _completionCtrl.forward();
      }
    });

    final state = ref.watch(traceDrawingProvider);
    final notifier = ref.read(traceDrawingProvider.notifier);
    final isCompleted = state.isCompleted;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) async {},
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(_currentTemplate.name),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _backToList,
          ),
          actions: [
            IconButton(
              tooltip: '전체 지우기',
              icon: Icon(
                Icons.delete_outline_rounded,
                color: isCompleted ? Colors.grey.shade300 : null,
              ),
              onPressed: isCompleted ? null : () => _confirmClear(context),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  TraceCanvas(
                    template: _currentTemplate,
                    elements: state.elements,
                    currentElement: state.currentElement,
                    hitZone: state.hitZone,
                    coverageVersion: state.coverageVersion,
                    onPanStart: notifier.startStroke,
                    onPanUpdate: notifier.addPoint,
                    onPanEnd: notifier.endStroke,
                    onSizeChanged: _onCanvasSizeChanged,
                    pencilProgram: _pencilProgram,
                    illustrationOpacity: _illAnim.value,
                    strokesOpacity: _strokeAnim.value,
                  ),
                  ..._animatingObjects.map((obj) => SparkleObjectWidget(
                        key: ValueKey(identityHashCode(obj)),
                        object: obj,
                        onComplete: () {
                          if (mounted) setState(() => _animatingObjects.remove(obj));
                        },
                      )),
                  if (_showCompletionOverlay)
                    CompletionOverlay(
                      onDone: () {
                        if (mounted) {
                          setState(() {
                            _showCompletionOverlay = false;
                            _showNextButton = true;
                          });
                        }
                      },
                    ),
                  if (_showNextButton)
                    Positioned(
                      bottom: 24,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: AnimatedPressable(
                          onTap: _goNextTemplate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                                  offset: const Offset(0, 6),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: const Text(
                              '다음 ➜',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
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
