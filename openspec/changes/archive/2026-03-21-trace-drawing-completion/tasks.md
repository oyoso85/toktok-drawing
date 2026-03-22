## 1. 에셋 준비

- [x] 1.1 `assets/templates/trace/line-star/` 폴더 생성 후 루트의 `line-star.svg` 복사
- [x] 1.2 `assets/templates/trace/line-star/name.txt` 생성 (내용: `별`)
- [x] 1.3 `pubspec.yaml`에 `assets/templates/trace/line-star/` 에셋 경로 추가

## 2. SVG 파싱 및 템플릿 모델

- [x] 2.1 `lib/features/trace_drawing/models/trace_template.dart`에서 6개 static Path 빌더 및 `registry` 제거; `svgAsset`, `name`, `id` 필드만 남기고 `pathBuilder`는 런타임 계산용으로 nullable로 변경
- [x] 2.2 `lib/features/trace_drawing/data/trace_template_registry.dart` 신규 파일 생성 — `line-star` 1개 등록, SVG polygon 파싱 함수(`_polygonToPath`) 포함, aspect-fit + 10% 패딩 스케일링 적용
- [x] 2.3 `line-star.svg` polygon points를 파싱해 `Path Function(Size)` 반환하는 로직 구현 및 테스트 (viewBox: `0 0 544.595 512.163`)

## 3. 히트존 로직

- [x] 3.1 `lib/features/trace_drawing/models/trace_hitzone.dart` 신규 파일 생성
  - `HitZone` 클래스: `segments` (List\<Offset\>), `hitRadius`, `segmentCovered` (List\<bool\>)
  - `factory HitZone.fromPath(Path path, Size size, double hitRadius)` — 200개 균등 샘플링
  - `bool isInZone(Offset point)` — 하나라도 hitRadius 이내이면 true
  - `List<int> coverNear(Offset point)` — hitRadius 이내 세그먼트 인덱스 반환 + covered 표시
  - `double get coverage` — coveredCount / segments.length
  - `void reset()` — segmentCovered 전체 false로 초기화

## 4. 상태 및 Provider 업데이트

- [x] 4.1 `TraceDrawingState`에 `HitZone? hitZone`, `bool isCompleted` 필드 추가, `copyWith` 업데이트
- [x] 4.2 `TraceDrawingProvider.resetForTemplate(Size canvasSize)` — 새 도안/캔버스 크기로 `HitZone` 생성 + 상태 초기화
- [x] 4.3 `addPoint(Offset point)` 수정 — `hitZone.isInZone(point)` false이면 early return; true이면 기존 stroke 추가 로직 + `hitZone.coverNear(point)` + coverage >= 0.9이면 `isCompleted = true` 설정
- [x] 4.4 완료 상태에서 `startStroke`, `addPoint`, `endStroke` 모두 무시하도록 guard 추가

## 5. 캔버스 히트존 렌더링

- [x] 5.1 `TraceCanvas`에 `HitZone? hitZone` 파라미터 추가
- [x] 5.2 `_TracePainter`에 히트존 렌더링 추가:
  - 미커버 세그먼트: 반지름 `hitRadius`의 원, fill `#FFD700` alpha 0.20
  - 커버된 세그먼트: 반지름 `hitRadius`의 원, fill `#00C853` alpha 0.27
  - 히트존은 가이드 점선보다 아래(먼저) 그림
- [x] 5.3 `TraceCanvas`가 레이아웃 크기를 알 수 있도록 `LayoutBuilder` 또는 콜백으로 `canvasSize`를 provider에 전달

## 6. 완성 흐름 — Screen 업데이트

- [x] 6.1 `TraceDrawingScreen`에서 `_selectedTemplate` + `_currentIndex` 관리; 시작 시 index 0 자동 선택
- [x] 6.2 `template_list_screen.dart` — 도안 1개일 때 선택 화면 스킵, 2개 이상이면 그리드 표시; 썸네일은 SVG `polygon` 미리보기로 교체
- [x] 6.3 `ref.listen`으로 `isCompleted` 변화 감지 → `CompletionOverlay` 표시
- [x] 6.4 `CompletionOverlay.onDone` 콜백 후 "다음" 버튼 위젯 표시 (AnimatedPressable 스타일, 화면 하단 중앙)
- [x] 6.5 "다음" 버튼 탭 시 `(currentIndex + 1) % registry.length`로 다음 도안 전환 + provider 초기화
- [x] 6.6 `isCompleted == true`일 때 AppBar 지우기 버튼 비활성화

## 7. 정리

- [x] 7.1 `trace_drawing_screen.dart`에서 기존 `TemplateListScreen` 분기 로직 업데이트 (단일 도안 시 바로 진입)
- [x] 7.2 루트의 `line-star.svg` 파일은 이동 완료 후 삭제 (또는 `.gitignore`에 추가)
- [x] 7.3 `pubspec.yaml` `flutter run`으로 앱 정상 빌드 및 실행 확인
