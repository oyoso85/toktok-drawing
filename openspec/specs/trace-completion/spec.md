## ADDED Requirements

### Requirement: 완료 판정
시스템은 커버리지가 0.9 이상이 되면 즉시 완료 상태(`isCompleted = true`)로 전환해야 한다(SHALL).
완료 판정 이후에는 추가 터치 입력을 무시한다.

#### Scenario: 90% 커버리지 도달 시 완료
- **WHEN** `coveredCount / totalSegments >= 0.9`가 된다
- **THEN** `isCompleted`가 true로 설정되고 이후 pan 이벤트가 무시된다

#### Scenario: 완료 전 터치는 정상 처리
- **WHEN** 커버리지가 0.9 미만인 상태에서 히트존 내부를 터치한다
- **THEN** stroke가 정상적으로 그려지고 커버리지가 업데이트된다

### Requirement: 완료 축하 오버레이
완료 판정 즉시 confetti 축하 이벤트가 전체 화면에 재생되어야 한다(SHALL).
기존 `CompletionOverlay` 위젯을 재활용한다.

#### Scenario: 완료 시 confetti 재생
- **WHEN** `isCompleted`가 true가 된다
- **THEN** `CompletionOverlay`가 전체 화면에 오버레이되어 2.5초간 confetti 애니메이션이 재생된다

#### Scenario: confetti 종료 후 다음 버튼 표시
- **WHEN** `CompletionOverlay`의 `onDone` 콜백이 호출된다 (2.5초 후)
- **THEN** "다음" 버튼이 화면 중앙 하단에 표시된다

### Requirement: 다음 도안 진행
완료 후 "다음" 버튼을 탭하면 다음 도안으로 진입해야 한다(SHALL).
도안 순서는 레지스트리 인덱스 순서를 따르며 마지막 도안에서 "다음"은 첫 도안으로 순환한다.

#### Scenario: 다음 도안으로 이동
- **WHEN** 완료 후 "다음" 버튼을 탭한다
- **THEN** `(currentIndex + 1) % registry.length` 인덱스의 도안으로 전환되고, 커버리지·스트로크가 초기화된다

#### Scenario: 마지막 도안에서 순환
- **WHEN** 마지막 도안 완료 후 "다음"을 탭한다
- **THEN** 첫 번째 도안(index 0)으로 돌아간다

#### Scenario: 도안이 1개일 때
- **WHEN** 레지스트리에 도안이 1개이고 완료 후 "다음"을 탭한다
- **THEN** 같은 도안이 초기화되어 다시 시작된다

### Requirement: 완료 전 지우기 가능
완료 전에는 기존 "전체 지우기" 기능이 동작해야 한다(SHALL).

#### Scenario: 완료 전 지우기
- **WHEN** `isCompleted`가 false인 상태에서 지우기 버튼을 탭한다
- **THEN** 모든 스트로크와 커버리지가 초기화된다

#### Scenario: 완료 후 지우기 비활성
- **WHEN** `isCompleted`가 true인 상태일 때
- **THEN** 지우기 버튼이 비활성화(disabled) 또는 숨겨진다
