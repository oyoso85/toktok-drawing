## ADDED Requirements

### Requirement: SVG 기반 TraceTemplate
시스템은 `assets/templates/trace/` 폴더 내 SVG 파일로부터 TraceTemplate을 로드해야 한다(SHALL).
각 도안은 `assets/templates/trace/<name>/<name>.svg`와 `assets/templates/trace/<name>/name.txt`로 구성된다.

#### Scenario: 템플릿 로드
- **WHEN** 앱이 시작되거나 선 따라 그리기 화면이 초기화된다
- **THEN** 레지스트리에 등록된 모든 도안의 이름과 SVG 에셋 경로가 로드된다

#### Scenario: name.txt에서 표시 이름 읽기
- **WHEN** 도안 목록 또는 AppBar 제목을 표시한다
- **THEN** `name.txt`의 내용(한글 이름)이 표시된다

### Requirement: polygon SVG 파싱
시스템은 `<polygon points="...">` 형식의 SVG를 파싱하여 Flutter `Path`로 변환해야 한다(SHALL).
viewBox 크기와 캔버스 크기를 비교하여 aspect-fit 스케일링을 적용한다.

#### Scenario: polygon → Path 변환
- **WHEN** SVG에 `<polygon points="x1,y1 x2,y2 ...">` 요소가 있다
- **THEN** 해당 포인트를 순서대로 연결한 닫힌 Path로 변환된다

#### Scenario: aspect-fit 스케일링
- **WHEN** 캔버스 크기가 SVG viewBox와 다르다
- **THEN** 가로세로 비율을 유지하며 캔버스 중앙에 배치된다

#### Scenario: 패딩 적용
- **WHEN** Path를 캔버스에 배치할 때
- **THEN** 캔버스 짧은 변의 10% 패딩이 사방에 적용된다

### Requirement: 도안 레지스트리
`lib/features/trace_drawing/data/trace_template_registry.dart`에 사용 가능한 도안 목록이 정의되어야 한다(SHALL).
현재는 `line-star` 1개이며 파일 추가 + 레지스트리 등록으로 확장한다.

#### Scenario: 레지스트리에서 도안 목록 제공
- **WHEN** 선 따라 그리기 화면이 열린다
- **THEN** 레지스트리에 등록된 도안 수만큼 항목이 표시된다

#### Scenario: 첫 번째 도안 자동 선택
- **WHEN** 선 따라 그리기 화면이 처음 열린다
- **THEN** 레지스트리의 첫 번째 도안(index 0)이 자동으로 선택되어 바로 그리기가 시작된다

### Requirement: 도안 선택 화면 (확장 대비)
도안이 2개 이상일 때 선택 화면이 제공되어야 한다(SHALL).
도안이 1개일 때는 선택 화면 없이 바로 그리기로 진입한다.

#### Scenario: 도안 1개일 때 바로 진입
- **WHEN** 레지스트리에 도안이 1개이다
- **THEN** 선택 화면 없이 즉시 그리기 캔버스가 표시된다

#### Scenario: 도안 2개 이상일 때 선택 화면
- **WHEN** 레지스트리에 도안이 2개 이상이다
- **THEN** 도안 썸네일 그리드 선택 화면이 표시된다
