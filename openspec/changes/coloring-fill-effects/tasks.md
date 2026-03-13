## 1. 준비 및 에셋 설정

- [x] 1.1 `character.svg`를 `assets/templates/coloring/character.svg`로 복사
- [x] 1.2 `pubspec.yaml`에 `xml` 패키지 추가 (`xml: ^6.x`)
- [x] 1.3 `lib/features/coloring/` 디렉토리 구조 생성 (`screen/`, `widgets/`, `providers/`, `models/`, `painters/`, `animations/`)

## 2. SVG 파싱 — ColoringPath 모델

- [x] 2.1 `ColoringPath` 모델 정의: `{ index, path: ui.Path, fillColor: Color, bounds: Rect }`
- [x] 2.2 `SvgColoringParser` 클래스 구현: `xml` 패키지로 SVG DOM 파싱 → `<path>` 요소 추출
- [x] 2.3 `path_parsing.parseSvgPathData()`로 `d` 속성을 `ui.Path`로 변환, 실패 시 bounding box rect fallback
- [x] 2.4 `#FEFEFE` fill path를 채색 대상에서 제외하는 필터 로직 구현
- [x] 2.5 소형 path 분류: bounding box 면적 < 400px²(SVG 좌표계)인 path를 `isTiny = true`로 마킹, 탭 후보에서 제외
- [x] 2.6 소형 path 초기 렌더링: `isTiny` path는 처음부터 SVG 원본 fill 색상으로 solid fill 표시
- [x] 2.7 viewBox(`630×648`) → 캔버스 uniform scale 변환 행렬(`Matrix4`) 계산 유틸리티 구현
- [x] 2.8 파서 단위 테스트: character.svg 전체 파싱 결과 검증 (path 수, 색상 종류, tiny 분류 수)

## 3. 상태 관리 — ColoringProvider

- [x] 3.1 `ColoringState` 정의: `{ parsedPaths, filledPaths: Set<int>, isAnimating: bool }`
- [x] 3.2 `ColoringNotifier` (`StateNotifier`) 구현: `initPaths()`, `fillPath(index)`, `setAnimating(bool)` 메서드
- [x] 3.3 Riverpod Provider 등록: `coloringProvider`

## 4. 색칠 캔버스 위젯 — ColoringCanvas

- [x] 4.1 `ColoringCanvas` StatefulWidget 생성: `AnimationController` 보유, `GestureDetector` + `CustomPaint` 구조
- [x] 4.2 `ColoringPainter` (`CustomPainter`) 구현: 미채움 path → 흰색 fill + 검정 stroke, 채움 path → solid fill
- [x] 4.3 탭 hit detection 구현: bounding box 선필터 → `Path.contains()`, 역행렬 좌표 변환 적용
- [x] 4.4 겹치는 path 처리: SVG 소스 역순(z-order 상위) 우선 선택
- [x] 4.5 애니메이션 진행 중 탭 차단: `isAnimating` 상태 체크 후 입력 무시

## 5. 채우기 애니메이션 엔진

- [x] 5.1 `FillAnimationPainter` 추상 클래스 정의: `paint(Canvas, Size, ui.Path targetPath, Color fillColor, double t)` 인터페이스
- [x] 5.2 **Sparkle Fill** 구현: 파티클 생성(50~100개, 랜덤 위치), scale-up(0→200ms), opacity oscillation, solid fill fade-in(600~900ms)
- [x] 5.3 **Pattern Fill** 구현: bounding box 격자 분할, 탭 지점 기준 ripple 순서 delay 계산, 도형 scale-up, solid fill fade-in
- [x] 5.4 **Paint Flood Fill** 구현: 탭 지점 중심 원 확장(0→path 대각선, 700ms), opacity 0.85→1.0
- [x] 5.5 **Pencil Fill** 구현: 랜덤 선분 누적(1000ms), `pencil.frag` 셰이더 적용, 셰이더 로드 실패 시 일반 Paint fallback, solid fill fade-in 마무리
- [x] 5.6 모든 효과에 `Canvas.clipPath(targetPath)` 클리핑 적용 확인
- [x] 5.7 `FillAnimationSelector`: 4가지 효과 중 랜덤 선택 로직 구현

## 6. 애니메이션 통합 — ColoringCanvas에 연결

- [x] 6.1 탭 이벤트 → `FillAnimationSelector`로 효과 선택 → `AnimationController` 시작
- [x] 6.2 애니메이션 완료 콜백: `coloringProvider.fillPath(index)` 호출 → solid fill 상태 전환
- [x] 6.3 `AnimationController` dispose 처리

## 7. 완성 감지 및 축하 연출

- [x] 7.1 `ColoringNotifier`에 완성 감지 로직 추가: `filledPaths.length == 채색대상총수` 체크
- [x] 7.2 완성 시 `OverlayEntry`로 전체 화면 Sparkle 파티클 오버레이 표시 (2초)
- [x] 7.3 오버레이 2초 후 자동 제거

## 8. 색칠하기 화면 — ColoringScreen

- [x] 8.1 `ColoringScreen` 위젯 생성: `ColoringCanvas` + 상단 앱바(뒤로가기)
- [x] 8.2 화면 진입 시 `coloringProvider.initPaths()` 호출 및 로딩 처리
- [x] 8.3 완성 이벤트 구독 및 `ColoringCompletionOverlay` 트리거

## 9. 모드 선택 화면 연동

- [x] 9.1 `mode_selection` 화면에 색칠하기 모드 버튼 추가 (기존 버튼 스타일 준수)
- [x] 9.2 버튼 탭 시 `ColoringScreen`으로 라우팅 연결

## 10. 통합 테스트 및 검증

- [x] 10.1 hit detection 정확도 검증: 각 path 내부/외부/경계 탭 케이스
- [x] 10.2 4가지 애니메이션 효과 시각 확인 (클리핑 경계 누수 없음)
- [x] 10.3 애니메이션 중 탭 차단 동작 확인
- [x] 10.4 모든 단면 채움 → 완성 오버레이 트리거 확인
- [x] 10.5 `#FEFEFE` path 및 소형 path 제외, 완성 조건 정확성 확인
- [x] 10.6 소형 path가 처음부터 원본 색상으로 표시되는지 확인
- [x] 10.7 완성 시점에 소형 path 즉시 채움 후 축하 연출 순서 확인
- [x] 10.6 Pencil Fill 셰이더 로드 실패 fallback 동작 확인
