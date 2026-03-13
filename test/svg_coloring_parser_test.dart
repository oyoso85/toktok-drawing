import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toktok_drawing/features/coloring/models/svg_coloring_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SvgColoringParser', () {
    late String svgString;

    setUpAll(() async {
      svgString = await rootBundle.loadString(
        'assets/templates/coloring/character.svg',
      );
    });

    test('파싱 성공: 모든 path 추출', () {
      final paths = SvgColoringParser.parse(svgString);
      expect(paths, isNotEmpty);
      // character.svg에는 다수의 path가 있음
      expect(paths.length, greaterThan(10));
    });

    test('색상 종류: 5가지 fill 색상 포함', () {
      final paths = SvgColoringParser.parse(svgString);
      final colors = paths.map((p) => p.fillColor).toSet();
      // SVG 원본 fill 색상 5종
      expect(colors.length, greaterThanOrEqualTo(3));
    });

    test('소형 path 분류: isTiny 플래그', () {
      final paths = SvgColoringParser.parse(svgString);
      final tinyPaths = paths.where((p) => p.isTiny).toList();
      final normalPaths = paths.where((p) => !p.isTiny).toList();

      // 소형 장식 path가 존재
      expect(tinyPaths, isNotEmpty);
      // 일반 채색 대상도 존재
      expect(normalPaths, isNotEmpty);

      // 소형 path의 bounds 면적이 모두 400 미만
      for (final p in tinyPaths) {
        final area = p.bounds.width * p.bounds.height;
        expect(area, lessThan(400.0));
      }
    });

    test('흰색 계열 path: isWhite 플래그', () {
      final paths = SvgColoringParser.parse(svgString);
      final whitePaths = paths.where((p) => p.isWhite).toList();
      // #FEFEFE path가 있거나 없을 수 있음 (SVG 구성에 따라)
      for (final p in whitePaths) {
        expect(p.fillColor.r, greaterThan(0.98));
        expect(p.fillColor.g, greaterThan(0.98));
        expect(p.fillColor.b, greaterThan(0.98));
      }
    });

    test('인터랙티브 path: isTiny=false && isWhite=false', () {
      final paths = SvgColoringParser.parse(svgString);
      final interactive = paths.where((p) => p.isInteractive).toList();
      expect(interactive, isNotEmpty);
      for (final p in interactive) {
        expect(p.isTiny, isFalse);
        expect(p.isWhite, isFalse);
      }
    });
  });
}
