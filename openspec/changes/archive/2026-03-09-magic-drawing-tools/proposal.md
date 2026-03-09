## Why

toktok-drawing은 완성된 그림보다 **터치 순간의 재미**가 핵심 가치다. 현재 도구(펜, 붓, 색연필)는 색선만 그려지는 단순한 형태로, 아이들이 화면을 건드릴 때 느끼는 경험이 평범하다. 마법처럼 반짝이고 화려한 이펙트 도구를 추가하여 앱 자체를 인터랙티브 이펙트 플레이그라운드로 전환한다.

## What Changes

- 새 도구 **무지개 붓** 추가: 시간 기반으로 색이 천천히 무지개 순환하는 붓. 포인트별 색상 저장으로 저장/불러오기 일관성 보장. 소프트 브러시(외곽 흐림) 렌더링.
- 새 도구 **꽃씨 붓** 추가: 손가락이 지나간 자리에 파티클 오브젝트가 씨앗처럼 커지며 피어남. 입장 시 랜덤 팔레트 결정, 오브젝트는 캔버스에 영구 잔류.
- 데이터 모델 **BREAKING** 변경: `List<Stroke>` → `List<DrawingElement>` 추상화. `Stroke`, `RainbowStroke`, `SparkleElement`가 `DrawingElement`를 구현.
- 기존 도구(펜, 붓, 색연필)는 유지.

## Capabilities

### New Capabilities

- `rainbow-brush`: 시간 기반 무지개 색상 순환 붓 도구 — 포인트별 색상, 소프트 브러시 렌더링, 10초 주기 색상 사이클
- `sparkle-brush`: 파티클 오브젝트 붓 도구 — 획을 그으면 별/하트 등 오브젝트가 피어남, 랜덤 팔레트, 영구 잔류
- `drawing-element-model`: `DrawingElement` 추상 모델 — `Stroke`, `RainbowStroke`, `SparkleElement`를 포함하는 통합 캔버스 요소 타입 시스템

### Modified Capabilities

(없음 — 기존 Stroke 모델을 대체하는 신규 모델로 처리)

## Impact

- `lib/shared/models/stroke.dart`: `DrawingElement` 추상 클래스로 리팩토링, 기존 Stroke 유지
- `lib/shared/models/drawing_data.dart`: `List<Stroke>` → `List<DrawingElement>`
- `lib/shared/widgets/tool_selector.dart`: 무지개 붓, 꽃씨 붓 도구 항목 추가
- `lib/features/free_drawing/`: 새 도구 렌더링 CustomPainter, Provider 연동
- 나머지 모드(trace-drawing, color-by-symbol)는 DrawingElement 타입 변경 영향 최소화 필요
- 의존성 추가 없음 (Flutter 기본 Canvas API로 구현 가능)
