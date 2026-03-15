import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toktok_drawing/core/constants/app_colors.dart';
import 'package:toktok_drawing/features/color_by_symbol/models/coloring_template.dart';
import 'package:toktok_drawing/features/color_by_symbol/providers/color_by_symbol_provider.dart';
import 'package:toktok_drawing/features/color_by_symbol/widgets/coloring_canvas.dart';
import 'package:toktok_drawing/features/color_by_symbol/widgets/coloring_template_list_screen.dart';
import 'package:toktok_drawing/shared/widgets/color_palette.dart';

/// 7.1~7.9 숫자/ABC 색칠 모드 최상위 화면.
/// 템플릿 선택 → 색칠 화면 흐름을 관리.
class ColorBySymbolScreen extends ConsumerStatefulWidget {
  const ColorBySymbolScreen({super.key});

  @override
  ConsumerState<ColorBySymbolScreen> createState() =>
      _ColorBySymbolScreenState();
}

class _ColorBySymbolScreenState extends ConsumerState<ColorBySymbolScreen> {
  ColoringTemplate? _selectedTemplate;
  bool _completionShown = false;

  void _selectTemplate(ColoringTemplate tmpl) {
    ref.read(colorBySymbolProvider.notifier).initForTemplate(tmpl);
    setState(() {
      _selectedTemplate = tmpl;
      _completionShown = false;
    });
  }

  void _backToList() {
    setState(() => _selectedTemplate = null);
  }

  // 7.7 완료 축하 다이얼로그
  void _showCompletion(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🎉 완성!', textAlign: TextAlign.center),
        content: const Text(
          '모든 영역을 색칠했어요!\n정말 잘했어요! ⭐',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _backToList();
            },
            child: const Text('다른 그림'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(colorBySymbolProvider.notifier).reset();
              setState(() => _completionShown = false);
            },
            child: const Text('다시 색칠'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedTemplate == null) {
      return ColoringTemplateListScreen(onSelected: _selectTemplate);
    }

    final state = ref.watch(colorBySymbolProvider);

    // 7.7 완료 감지 → 다음 프레임에 다이얼로그 표시
    if (state.isComplete && !_completionShown) {
      _completionShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showCompletion(context);
      });
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_selectedTemplate!.name),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _backToList,
        ),
        actions: [
          // 7.8 초기화
          IconButton(
            tooltip: '처음부터',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(colorBySymbolProvider.notifier).reset();
              setState(() => _completionShown = false);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 7.3 + 7.6 색칠 캔버스
          Expanded(
            child: ColoringCanvas(
              template: _selectedTemplate!,
              filledRegions: state.filledRegions,
              onTap: (i) => ref.read(colorBySymbolProvider.notifier).fillRegion(i),
            ),
          ),
          // 7.5 기호-색상 매핑 팔레트 + 색상 선택
          _ColoringPalette(
            template: _selectedTemplate!,
            selectedColor: state.selectedColor,
            onColorChanged: (c) =>
                ref.read(colorBySymbolProvider.notifier).changeColor(c),
          ),
        ],
      ),
    );
  }
}

/// 7.5 기호-색상 매핑 팔레트.
/// 상단: 기호-힌트 색상 안내 칩 / 하단: 색상 선택 팔레트
class _ColoringPalette extends StatelessWidget {
  final ColoringTemplate template;
  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;

  const _ColoringPalette({
    required this.template,
    required this.selectedColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 기호-힌트 안내 행
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: template.regions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final region = template.regions[i];
                  return GestureDetector(
                    onTap: () => onColorChanged(region.hintColor),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: region.hintColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: region.hintColor,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            region.symbol,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: region.hintColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // 색상 선택 팔레트
            ColorPalette(
              selectedColor: selectedColor,
              onColorSelected: onColorChanged,
              colors: AppColors.palette
                  .where((c) => c != Colors.white)
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
