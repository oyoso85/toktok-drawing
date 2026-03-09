## ADDED Requirements

### Requirement: DrawingElement 추상 타입 정의
시스템은 캔버스에 그려지는 모든 요소를 `DrawingElement` 추상 타입으로 표현해야 한다. `Stroke`, `RainbowStroke`, `SparkleElement`는 모두 `DrawingElement`를 구현한다. `DrawingData`는 `List<DrawingElement>`를 보유한다.

#### Scenario: 다양한 요소 타입을 하나의 목록으로 관리
- **WHEN** 사용자가 펜, 무지개 붓, 꽃씨 붓을 순서대로 사용하여 그림을 그리면
- **THEN** `DrawingData.elements`에 `Stroke`, `RainbowStroke`, `SparkleElement`가 순서대로 저장된다

### Requirement: JSON 타입 디스크리미네이터를 통한 역직렬화
시스템은 JSON에 `type` 필드를 포함하여 직렬화하고, 역직렬화 시 `type` 필드로 올바른 구현 클래스를 생성해야 한다.

#### Scenario: 혼합 요소 저장 및 불러오기
- **WHEN** `Stroke`, `RainbowStroke`, `SparkleElement`가 섞인 `DrawingData`를 저장하고 다시 불러오면
- **THEN** 각 요소가 원래 타입으로 복원되어 동일하게 렌더링된다

#### Scenario: type 필드 없는 구 데이터 호환
- **WHEN** `type` 필드가 없는 구 형식 JSON을 불러오면
- **THEN** 해당 요소를 `Stroke`로 처리하며 앱이 크래시 없이 동작한다

### Requirement: DrawingTool 열거형에 새 도구 추가
시스템은 `DrawingTool` 열거형에 `rainbowBrush`와 `sparkleBrush`를 추가해야 한다. 기존 열거값(pen, brush, pencil, eraser)은 변경하지 않는다.

#### Scenario: 새 도구 선택
- **WHEN** 사용자가 도구 선택 UI에서 무지개 붓 또는 꽃씨 붓을 탭하면
- **THEN** 해당 도구가 활성화되고 이후 그리기에 적용된다
