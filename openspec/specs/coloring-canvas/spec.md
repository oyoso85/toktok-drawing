## ADDED Requirements

### Requirement: SVG 파싱 및 Path 객체 변환
앱 시작 또는 색칠 화면 진입 시, `assets/templates/coloring/character.svg`의 모든 `<path>` 요소를 파싱하여 Flutter `ui.Path` 객체 배열로 변환해야 한다. 각 path는 원본 `fill` 색상, bounding box, 그리고 소형 path 여부 플래그를 함께 보관한다.

#### Scenario: SVG 로드 및 파싱 성공
- **WHEN** 색칠 화면이 초기화되면
- **THEN** character.svg의 모든 `<path>` 요소가 `ui.Path` 객체로 변환되고, 각각의 원본 fill 색상(Color), bounding Rect, `isTiny` 플래그가 추출된다

#### Scenario: 파싱 실패한 path 처리
- **WHEN** 특정 `<path>`의 `d` 속성을 `ui.Path`로 변환하는 데 실패하면
- **THEN** 해당 path는 bounding box를 기반으로 한 `Rect` path로 대체되며, 앱은 계속 동작한다

---

### Requirement: 소형 path 분류 — 최소 면적 임계값
bounding box 면적이 `400px²`(SVG 좌표계 기준 약 20×20px) 미만인 path는 소형(tiny) path로 분류해야 한다. 소형 path는 인터랙티브 채색 대상에서 제외된다.

#### Scenario: 소형 path 분류
- **WHEN** SVG 파싱 시 bounding box 면적이 400px² 미만인 path가 발견되면
- **THEN** 해당 path의 `isTiny` 플래그가 `true`로 설정되고, 탭 hit detection 후보 목록에서 제외된다

#### Scenario: 소형 path 초기 렌더링
- **WHEN** 색칠 화면이 처음 표시될 때 소형 path가 존재하면
- **THEN** 소형 path는 흰색/테두리가 아닌 SVG 원본 fill 색상으로 처음부터 solid fill 렌더링된다

---

### Requirement: 초기 렌더링 — 흰색 단면 + 검정 테두리
색칠 캔버스는 모든 단면을 흰색 fill과 검정 stroke으로 렌더링해야 한다. 아직 채워지지 않은 단면은 테두리만 보이는 상태를 유지한다.

#### Scenario: 미채움 단면 렌더링
- **WHEN** 색칠 화면이 처음 표시되면
- **THEN** 모든 path가 흰색(`#FFFFFF`) 배경 위에 stroke width 1.5px의 검정(`#000000`) 테두리로만 그려진다

#### Scenario: 채워진 단면 렌더링
- **WHEN** 특정 단면이 채워진 상태로 전환되면
- **THEN** 해당 path가 SVG 원본 fill 색상으로 solid fill 렌더링되며 테두리는 유지된다

---

### Requirement: 캔버스 좌표 변환 — viewBox 스케일
SVG viewBox(`0 0 630 648`)를 디바이스 캔버스 크기에 맞게 uniform scale로 렌더링해야 한다. 가로세로 비율을 유지하며 캔버스 중앙에 배치한다.

#### Scenario: 화면 크기에 따른 스케일 적용
- **WHEN** 색칠 캔버스가 임의의 화면 크기에서 렌더링되면
- **THEN** SVG 전체가 잘리지 않고, 가로세로 비율을 유지하며, 캔버스 영역 안에 중앙 정렬된다

---

### Requirement: 탭 hit detection — path 식별
사용자가 캔버스를 탭하면, 탭 좌표를 SVG 좌표계로 역변환하여 해당 지점이 속한 path를 식별해야 한다.

#### Scenario: 유효한 단면 탭
- **WHEN** 사용자가 특정 path 내부를 탭하면
- **THEN** 소형 path를 제외한 후보 중 bounding box 필터링 → `Path.contains()`로 해당 path가 식별되고, 채우기 애니메이션이 시작된다

#### Scenario: 소형 path 영역 탭
- **WHEN** 사용자가 소형 path 영역을 탭하면
- **THEN** 소형 path는 hit detection 후보에서 제외되므로 아무 동작도 발생하지 않는다

#### Scenario: 이미 채워진 단면 탭
- **WHEN** 사용자가 이미 채워진 단면을 탭하면
- **THEN** 아무 동작도 발생하지 않는다

#### Scenario: 단면 외부(빈 공간) 탭
- **WHEN** 사용자가 어떤 path에도 속하지 않는 영역을 탭하면
- **THEN** 아무 동작도 발생하지 않는다

#### Scenario: 겹치는 path 탭
- **WHEN** 탭 지점이 여러 path에 속할 때
- **THEN** SVG 소스 순서상 마지막(z-order 상위) path가 선택된다

---

### Requirement: 애니메이션 중 탭 입력 차단
채우기 애니메이션이 진행 중일 때는 다른 단면의 탭 입력을 무시해야 한다.

#### Scenario: 애니메이션 진행 중 다른 단면 탭
- **WHEN** 채우기 애니메이션이 재생 중에 사용자가 다른 단면을 탭하면
- **THEN** 해당 탭 입력이 무시되고 현재 애니메이션이 중단 없이 완료된다

#### Scenario: 애니메이션 완료 후 탭 가능
- **WHEN** 채우기 애니메이션이 완전히 종료되면
- **THEN** 캔버스가 다시 탭 입력을 받을 수 있는 상태가 된다
