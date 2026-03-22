## Context

현재 선 따라 그리기는 6개 코드 내장 Path를 점선으로 표시하고 자유롭게 그릴 수 있는 수준이다.
완성 개념이 없어 유아가 "잘 했다"는 피드백을 받지 못하고, 도안이 코드에 하드코딩되어 있어 확장이 어렵다.
Flutter `Path.computeMetrics()` API로 경로를 샘플링하면 히트존과 커버리지를 순수 Dart로 계산할 수 있다.

## Goals / Non-Goals

**Goals:**
- SVG 파일 기반 도안 레지스트리 (추가 시 파일만 넣으면 됨)
- 히트존 내부에서만 그려지는 가이드 그리기
- 세그먼트 커버리지 90% → 완료 판정 + confetti
- 완료 후 "다음" 버튼으로 다음 도안 순환

**Non-Goals:**
- 컬러 완성형 SVG로의 전환 (추후 개선)
- 네트워크 도안 다운로드
- 점수/스타 시스템

## Decisions

### 1. 히트존 표현: 세그먼트 샘플링

Path 위에 N개(기본 200개) 포인트를 균등 간격으로 샘플링한다.
각 포인트는 반지름 `hitRadius = selectedSize * 1.5`의 원으로 히트존을 구성한다.

**대안 고려**: 비트맵 마스크로 히트존 그리기 → 매 stroke마다 pixel-test가 필요해 복잡
**선택 이유**: 세그먼트 리스트로 관리하면 커버리지 추적이 O(N)으로 단순하다.

### 2. 커버리지 추적: `List<bool> covered`

`TraceDrawingState`에 `List<bool> segmentCovered`(길이 N) 추가.
`onPanUpdate` 시 현재 점과 각 세그먼트 거리가 `hitRadius` 이내이면 `covered[i] = true`.
`coveredCount / N >= 0.9` → `isCompleted = true`.

**대안 고려**: 연속 경로 길이로 커버리지 측정 → 역방향 그리기 시 중복 카운팅 복잡
**선택 이유**: bool 배열은 재방문 커버를 자연스럽게 처리한다.

### 3. SVG 파싱: polygon points 직접 파싱

`line-star.svg`는 `<polygon points="...">` 하나이므로 `path_parsing` 없이 직접 파싱한다.
향후 `<path d="...">` SVG 추가 시 `path_parsing` 패키지(이미 의존성에 있음)로 확장.
파싱 결과를 `Path Function(Size)` 형태로 정규화해 `TraceTemplate`에 저장.

### 4. 도안 레지스트리: 코드 등록 방식 (sync 스크립트 패턴 동일)

`assets/templates/trace/` 폴더에 SVG + `name.txt` 저장.
`lib/features/trace_drawing/data/trace_template_registry.dart`를 coloring의 `svg_template_registry.dart`와 같은 방식으로 관리.
지금은 수동 등록(파일 1개), 추후 `sync_trace_assets.dart` 스크립트로 자동화 가능.

### 5. 완료 흐름: 순환 인덱스

`TraceDrawingScreen`이 `currentIndex`를 상태로 갖고,
완료 후 "다음" 탭 시 `(currentIndex + 1) % registry.length`로 다음 도안 진입.
도안이 1개일 때는 "다음" = "다시 하기"와 동일하게 동작.

### 6. 히트존 시각화

가이드선(점선) 아래 레이어에 히트존을 `fillColor`(노란색 반투명 `0x33FFD700`)으로 채워 그린다.
커버된 세그먼트는 초록색(`0x4400C853`)으로 표시 → 진행 상황 시각 피드백.

## Risks / Trade-offs

- [성능] 세그먼트 200개 × pan update 60fps = 초당 12,000회 거리 계산 → 충분히 가벼움 (단순 sqrt)
- [히트존 밀도] 별 꼭짓점 부근은 경로 밀도가 높아 세그먼트 겹침 발생 → 커버리지 오차 ±2~3%, 허용 범위
- [선 굵기 변경] 도중에 도구 크기 바꾸면 hitRadius가 달라져 커버 판정이 달라질 수 있음 → hitRadius는 그리기 시작 시 고정하지 않고 현재 selectedSize 사용 (단순 유지)

## Migration Plan

1. `assets/templates/trace/line-star/` 폴더 생성, SVG 복사, `name.txt` 생성
2. `pubspec.yaml`에 에셋 경로 추가
3. `TraceTemplate` 모델 변경 (pathBuilder 유지, svgAsset 필드 추가)
4. `trace_template_registry.dart` 신규 파일로 레지스트리 정의
5. provider/state에 히트존·커버리지 로직 추가
6. canvas painter에 히트존 렌더링 추가
7. screen에 완료 오버레이 + "다음" 버튼 추가
8. 기존 `template_list_screen.dart` SVG 썸네일 방식으로 교체
9. 기존 코드 내장 6개 경로 + `models/trace_template.dart`의 static registry 제거

롤백: 브랜치 단위로 분리되어 있으므로 merge 전까지 기존 동작 유지 가능.

## Open Questions

- `path_parsing` 기반 일반 SVG `<path>` 지원은 이번 스코프에서 제외; 향후 도안 추가 시 필요하면 도입
- 완성된 도안의 "컬러 버전 SVG 전환"은 추후 개선으로 명시, 현재는 흑백 가이드선 그대로 유지
