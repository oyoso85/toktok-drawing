## Why

아이들이 SVG 캐릭터의 각 단면을 탭하면 마법 같은 시각 효과와 함께 색이 채워지는 색칠하기 기능이 필요하다. 기존 drawing/free_drawing 모드와 차별화되는 "색칠하기" 특화 모드로, 아이들의 성취감과 즐거움을 극대화한다.

## What Changes

- `character.svg`의 각 색상 단면을 인터랙티브 색칠 영역으로 변환 (초기 상태: 테두리만 검정, 단면은 흰색)
- 단면 탭 시 해당 경로에 정의된 원래 색상으로 채워지되, 4가지 마법 효과 중 하나(또는 선택 가능)로 애니메이션 처리
- 4가지 채우기 애니메이션 효과 구현:
  - **Sparkle Fill**: 뾰로롱 마법가루/반짝이가 흩날리며 색이 채워지는 효과
  - **Pattern Fill**: 작고 귀여운 패턴(별, 하트, 점)이 솟아나며 색면을 채우는 효과
  - **Paint Flood Fill**: 탭 지점에서 물감이 번지듯 퍼져나가는 효과
  - **Pencil Fill**: 색연필로 슥슥 그리듯 선들이 누적되며 색면을 채우는 효과
- 모든 단면이 채워졌을 때 완성 축하 애니메이션 표시

## Capabilities

### New Capabilities

- `coloring-canvas`: SVG의 각 path를 클리핑 마스크 영역으로 파싱하여 Flutter CustomPaint로 렌더링하는 색칠 캔버스. 테두리는 검정 stroke, 내부는 흰색으로 초기화. 탭 이벤트로 해당 path 식별.
- `coloring-fill-animation`: 탭된 path 클리핑 영역 내에서 동작하는 4가지 채우기 애니메이션 엔진. 각 애니메이션은 SVG path에 정의된 원본 fill color를 사용.
- `coloring-completion`: 모든 단면이 채워졌을 때 감지하고 축하 연출을 수행하는 완성 상태 관리자.

### Modified Capabilities

- `mode-selection`: 색칠하기 모드 진입점을 mode_selection 화면에 추가 (기존 모드 선택 UI에 아이콘/버튼 추가).

## Impact

- **새 파일**: `lib/features/coloring/` 디렉토리 전체 (화면, 캔버스 위젯, 애니메이션 컨트롤러, SVG 파서)
- **수정 파일**: `lib/features/mode_selection/` (색칠하기 모드 진입 버튼 추가)
- **에셋**: `character.svg` (파싱 대상, 수정 없음)
- **의존성 추가 가능성**: `xml` 패키지 (SVG path 파싱), `vector_math` (path 내부 판정)
- **기존 sparkle-brush spec 참고**: 파티클 시스템 구현 시 기존 sparkle-brush 구현체 재활용 검토
