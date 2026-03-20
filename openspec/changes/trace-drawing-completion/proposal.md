## Why

선 따라 그리기 기능이 단순 자유 그리기와 차별점 없이 "그냥 그리기"로만 동작하고 있어, 유아가 목표 달성 경험(완성 → 축하 → 다음 도안)을 얻지 못한다. 히트존 기반 가이드 + 완성 판정 시스템을 추가해 학습 게임성을 부여한다.

## What Changes

- **BREAKING** 기존 6개 코드 내장 템플릿(직선·물결·지그재그·원·별·하트) 제거
- SVG 파일 기반 템플릿 시스템으로 교체 (`assets/templates/trace/` 폴더 관리)
- 현재는 `line-star.svg` 1개로 시작, 추후 도안 파일만 추가하면 자동 등록
- 선택 화면은 유지(단일 항목에서 시작), 도안 추가 시 자연스럽게 확장
- 그리기 캔버스에 히트존 시각화 추가 (반투명 영역)
- 히트존 내부에서만 stroke 그려짐 (히트존 외부 pan 입력 무시)
- 히트존 90% 커버 시 완료 판정
- 완료 시 `CompletionOverlay` 재활용하여 confetti 축하 이벤트
- 축하 이벤트 후 "다음" 버튼 표시 → 다음 도안으로 순서 진행 (마지막이면 처음으로 순환)

## Capabilities

### New Capabilities
- `trace-hitzone`: SVG path에서 히트존을 생성하고, 사용자 터치가 히트존 내부인지 판정하며, 세그먼트 커버리지를 추적하는 로직
- `trace-completion`: 히트존 커버리지 90% 도달 시 완료 판정, confetti 오버레이, "다음" 버튼으로 다음 도안 진행하는 완성 흐름
- `trace-svg-template`: SVG 파일에서 Path를 파싱하여 TraceTemplate을 생성하는 로직 및 `assets/templates/trace/` 폴더 기반 레지스트리

### Modified Capabilities
- (없음 — 기존 스펙과 요구사항 수준의 겹침 없음)

## Impact

- `lib/features/trace_drawing/models/trace_template.dart` — 코드 내장 path 제거, SVG 기반으로 교체
- `lib/features/trace_drawing/widgets/template_list_screen.dart` — SVG 템플릿 목록으로 변경
- `lib/features/trace_drawing/widgets/trace_canvas.dart` — 히트존 시각화 + 입력 필터링 추가
- `lib/features/trace_drawing/providers/trace_drawing_state.dart` — 커버리지 상태, 완료 플래그 추가
- `lib/features/trace_drawing/providers/trace_drawing_provider.dart` — 히트존 계산, 커버리지 업데이트 로직 추가
- `lib/features/trace_drawing/trace_drawing_screen.dart` — 완성 오버레이, "다음" 버튼 흐름 추가
- `assets/templates/trace/` — 새 에셋 폴더 (line-star.svg 이동)
- `pubspec.yaml` — 새 에셋 경로 등록
- 신규 파일: `lib/features/trace_drawing/models/trace_hitzone.dart`
- 신규 파일: `lib/features/trace_drawing/widgets/trace_completion_overlay.dart` (또는 coloring의 CompletionOverlay 공유)
