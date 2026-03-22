## ADDED Requirements

### Requirement: 히트존 세그먼트 생성
시스템은 TraceTemplate의 Path를 캔버스 크기에 맞게 스케일한 뒤, 경로 전체 길이를 N개(200개) 균등 간격으로 샘플링하여 세그먼트 포인트 목록을 생성해야 한다(SHALL).
히트 반지름(hitRadius)은 현재 selectedSize × 1.5로 계산된다.

#### Scenario: 캔버스 크기 변경 시 세그먼트 재계산
- **WHEN** 캔버스 레이아웃이 결정되거나 도안이 변경된다
- **THEN** 세그먼트 포인트는 새 캔버스 크기에 맞게 재계산된다

#### Scenario: 세그먼트 개수
- **WHEN** 경로 길이에 관계없이 히트존을 생성할 때
- **THEN** 세그먼트 수는 정확히 200개여야 한다

### Requirement: 히트존 포함 판정
시스템은 사용자 터치 포인트가 히트존 내부에 있는지 판정해야 한다(SHALL).
임의의 세그먼트 포인트와의 거리가 hitRadius 이하이면 히트존 내부로 판정한다.

#### Scenario: 히트존 내부 터치
- **WHEN** 사용자가 어떤 세그먼트 포인트로부터 hitRadius 이내 지점을 터치한다
- **THEN** 해당 점은 히트존 내부로 판정되어 stroke가 추가된다

#### Scenario: 히트존 외부 터치
- **WHEN** 사용자가 모든 세그먼트 포인트로부터 hitRadius 초과 거리에서 터치한다
- **THEN** 해당 pan 이벤트는 무시되고 stroke가 추가되지 않는다

### Requirement: 커버리지 추적
시스템은 각 세그먼트가 커버되었는지를 `List<bool>` 배열로 추적해야 한다(SHALL).
사용자 터치가 세그먼트 포인트의 hitRadius 이내를 지날 때 해당 세그먼트를 커버됨으로 표시한다.

#### Scenario: 세그먼트 커버 표시
- **WHEN** 사용자 터치 포인트가 세그먼트 i의 hitRadius 이내에 있다
- **THEN** `segmentCovered[i]`가 true로 설정된다

#### Scenario: 커버리지 비율 계산
- **WHEN** 커버리지를 계산할 때
- **THEN** `coveredCount / totalSegments`를 반환한다 (0.0 ~ 1.0)

#### Scenario: 도안 변경 시 커버리지 초기화
- **WHEN** 새 도안으로 전환된다
- **THEN** `segmentCovered` 배열이 모두 false로 초기화된다

### Requirement: 히트존 시각 피드백
캔버스는 히트존과 커버리지 진행 상황을 시각적으로 표시해야 한다(SHALL).

#### Scenario: 미커버 히트존 표시
- **WHEN** 도안이 표시될 때
- **THEN** 미커버 세그먼트 영역이 노란색 반투명(#FFD700, alpha 0.2)으로 가이드선 아래에 그려진다

#### Scenario: 커버된 히트존 표시
- **WHEN** 세그먼트가 커버됨으로 표시된다
- **THEN** 해당 영역이 초록색 반투명(#00C853, alpha 0.27)으로 변경된다
