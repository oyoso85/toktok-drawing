## ADDED Requirements

### Requirement: 완성 조건 감지
채워야 할 모든 인터랙티브 단면이 채워졌을 때 완성 상태를 감지해야 한다. `#FEFEFE`(흰색에 가까운) fill path와 소형(tiny) path는 완성 조건 계산에서 제외한다.

#### Scenario: 모든 인터랙티브 단면 완료
- **WHEN** 소형 path와 `#FEFEFE` path를 제외한 모든 채색 대상 단면이 채워지면
- **THEN** 완성 이벤트가 발행되고 소형 path 자동 완료 처리 후 축하 연출이 시작된다

#### Scenario: 흰색 계열 path 제외
- **WHEN** SVG 파싱 시 fill 색상이 `#FEFEFE`인 path가 발견되면
- **THEN** 해당 path는 채색 대상 목록에서 제외되며 완성 조건 계산에 포함되지 않는다

#### Scenario: 소형 path 완성 시점 자동 채움
- **WHEN** 마지막 인터랙티브 단면이 채워져 완성 이벤트가 발행되면
- **THEN** 아직 SVG 원본 색상으로 표시되지 않은 소형 path가 있다면 즉시 SVG 원본 fill 색상으로 채워지며(별도 애니메이션 없음), 이후 축하 연출이 시작된다

---

### Requirement: 완성 축하 연출 — 전체 화면 Sparkle 오버레이
모든 단면 완성 시 전체 화면에 반짝이 파티클 애니메이션이 2초간 재생된다.

#### Scenario: 축하 오버레이 표시
- **WHEN** 완성 이벤트가 발행되면
- **THEN** 전체 화면을 덮는 Sparkle 파티클 오버레이가 즉시 표시되며 2초간 재생된다

#### Scenario: 축하 연출 완료 후 처리
- **WHEN** 축하 오버레이 애니메이션이 2초 후 완료되면
- **THEN** 오버레이가 사라지고 완성된 색칠 결과가 화면에 남는다
