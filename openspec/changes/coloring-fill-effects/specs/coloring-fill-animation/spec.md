## ADDED Requirements

### Requirement: 채우기 효과 랜덤 선택
단면이 탭될 때마다 4가지 채우기 효과(Sparkle, Pattern, Paint Flood, Pencil) 중 하나를 랜덤으로 선택하여 재생해야 한다.

#### Scenario: 탭 시 랜덤 효과 선택
- **WHEN** 사용자가 미채움 단면을 탭하면
- **THEN** Sparkle / Pattern / Paint Flood / Pencil 중 하나가 랜덤으로 선택되어 해당 path 영역에서 애니메이션이 시작된다

---

### Requirement: 모든 효과의 클리핑 — path 경계 준수
모든 채우기 애니메이션은 반드시 탭된 path의 경계 안에서만 렌더링되어야 한다. path 외부로 넘쳐흐르는 픽셀이 없어야 한다.

#### Scenario: 클리핑 경계 준수
- **WHEN** 어떤 효과의 채우기 애니메이션이 재생될 때
- **THEN** 모든 그래픽 요소가 탭된 path 경계를 벗어나지 않는다

---

### Requirement: Sparkle Fill — 마법가루 채우기
탭 시 반짝이 파티클들이 path 내에 흩어지며 등장하고, 이후 SVG 원본 색상의 solid fill이 fade-in된다. 총 애니메이션 시간은 900ms 내외여야 한다.

#### Scenario: 파티클 생성 및 등장
- **WHEN** Sparkle Fill 효과가 선택되어 시작되면
- **THEN** path bounding box 내 50~100개의 파티클이 랜덤 위치에 생성되며, 각 파티클이 크기 0에서 최종 크기로 200ms 동안 scale-up된다

#### Scenario: 파티클 반짝임
- **WHEN** 파티클이 최종 크기에 도달한 후
- **THEN** 파티클의 opacity가 oscillation하며 반짝이는 효과가 재생된다

#### Scenario: Solid fill fade-in
- **WHEN** 애니메이션 시작 후 600ms가 경과하면
- **THEN** SVG 원본 fill 색상의 solid fill이 path 위에 fade-in되어 파티클과 합성되며, 900ms에 완전히 불투명해진다

#### Scenario: 파티클 도형
- **WHEN** 파티클이 생성될 때
- **THEN** star / heart / circle 중 하나가 랜덤으로 선택되어 랜덤 회전각으로 렌더링된다

---

### Requirement: Pattern Fill — 패턴 솟기 채우기
탭 지점에서 가까운 순서로 귀여운 도형들이 격자 위치에 순차적으로 솟아나며 path를 채우고, 이후 solid fill로 합쳐진다.

#### Scenario: 격자 분할 및 도형 배치
- **WHEN** Pattern Fill 효과가 시작되면
- **THEN** path bounding box가 격자로 분할되고, 각 셀 중심에 star / heart / circle 중 하나의 도형이 배치 예정으로 등록된다

#### Scenario: 탭 지점에서 ripple 순서 등장
- **WHEN** 도형들이 등장하기 시작하면
- **THEN** 탭 지점과 가장 가까운 셀부터 순서대로 scale-up 애니메이션이 재생되며, 멀어질수록 delay가 증가한다

#### Scenario: 도형 → Solid fill 합성
- **WHEN** 모든 셀의 도형 등장 애니메이션이 완료되면
- **THEN** SVG 원본 fill 색상의 solid fill이 fade-in되며 도형들과 합성되어 단면이 완전히 채워진다

---

### Requirement: Paint Flood Fill — 물감 번짐 채우기
탭 지점에서 원이 확장되며 물감이 퍼지듯 path를 채운다. 총 애니메이션 시간은 700ms 내외여야 한다.

#### Scenario: 원형 확장 시작
- **WHEN** Paint Flood Fill 효과가 시작되면
- **THEN** 탭 지점을 중심으로 반경 0의 원에서 시작하여, path 대각선 길이 이상의 반경까지 700ms 동안 확장된다

#### Scenario: 색상 및 불투명도
- **WHEN** 원이 확장되는 동안
- **THEN** SVG 원본 fill 색상으로 채워지며, 초기에는 약간의 투명도(opacity 0.85)로 시작하여 완료 시 완전 불투명(opacity 1.0)이 된다

#### Scenario: path 경계에서의 클리핑
- **WHEN** 확장 원이 path 경계를 초과하면
- **THEN** clipPath에 의해 path 외부는 렌더링되지 않으며, path 경계에서 자연스럽게 채워진 형태가 된다

---

### Requirement: Pencil Fill — 색연필 슥슥 채우기
path 영역 내에 색연필 선분들이 랜덤하게 누적되어 그려지며 단면이 채워진다. 총 애니메이션 시간은 1000ms 내외여야 한다.

#### Scenario: 선분 누적 생성
- **WHEN** Pencil Fill 효과가 시작되면
- **THEN** path bounding box 내 랜덤 위치와 방향의 짧은 선분들이 시간에 따라 순차적으로 추가되며, 선 밀도가 증가하면서 단면이 채워지는 느낌을 준다

#### Scenario: 연필 셰이더 적용
- **WHEN** 선분이 렌더링될 때
- **THEN** `assets/shaders/pencil.frag` 셰이더가 적용되어 색연필 질감이 표현된다. 셰이더 로드 실패 시 일반 `Paint`로 fallback한다

#### Scenario: Solid fill 마무리
- **WHEN** 애니메이션이 1000ms에 도달하면
- **THEN** SVG 원본 fill 색상의 solid fill이 fade-in되어 선분 위를 덮으며 단면이 완전히 채워진 상태로 마무리된다

---

### Requirement: 애니메이션 완료 후 path 채움 상태 영구 저장
애니메이션이 완료되면 해당 path는 영구적으로 "채워진" 상태로 전환되어, 이후 SVG 원본 색상의 solid fill로만 렌더링된다.

#### Scenario: 애니메이션 완료 후 상태 전환
- **WHEN** 채우기 애니메이션이 완전히 종료되면
- **THEN** 해당 path가 `filledPaths` 집합에 추가되고, 이후 별도의 애니메이션 없이 SVG 원본 색상으로 정적 렌더링된다
