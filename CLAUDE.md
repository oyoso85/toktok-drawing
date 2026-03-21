# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

3~7세 유아용 그림그리기 앱. Flutter (iOS/Android), 완전 오프라인. **가로 모드 고정 + ImmersiveSticky** (`main.dart`에서 앱 시작 시 설정).

---

## 빌드 / 실행 명령어

```bash
# 개발 실행
flutter run

# Android APK 빌드
flutter build apk --release

# iOS 빌드
flutter build ios --release

# SVG 템플릿 레지스트리 + pubspec.yaml 자동 갱신
dart run tool/sync_coloring_assets.dart

# SVG 정규화 (style= 형식으로 저장된 경우)
dart run tool/normalize_svg.dart assets/templates/coloring/{폴더명}/{파일명}.svg

# 테스트
flutter test
flutter test test/specific_test.dart   # 단일 파일
```

---

## 프로젝트 현황

### 완료된 기능

| 기능 | 설명 |
|------|------|
| 자유 그리기 | 펜, 붓, 색연필(GLSL 셰이더), 지우개, 무지개붓, 꽃씨붓 |
| 선 따라 그리기 | SVG 가이드 위에 따라 그리기 |
| 색칠하기 (SVG) | SVG path 탭 → 마법 애니메이션 채우기 (4가지 효과) |
| UI 크롬 | bounce 애니메이션, 도구별 컬러, glow 효과 |

### 미완성

- 대칭 그리기 — 폴더/클래스는 있으나 미구현
- 갤러리/저장/공유 — 서비스 코드만 있고 UI 미연결
- 숫자/ABC 색칠 (`color_by_symbol`) — 레거시, 현재 사용 안 함

---

## 향후 방향

### 수익 모델 — 인앱 결제 (로컬 잠금 해제 방식)

- 앱 설치 시 모든 도안 포함, 결제 후 잠금 해제 (서버 불필요, 오프라인 유지)
- 패키지: `in_app_purchase`로 구글 플레이 / 앱스토어 동시 지원
- 결제 상태는 `restorePurchases()`로 복원 (앱 재설치 대응)
- 환불 시 `PurchaseStatus.refunded` 감지 → 잠금 재적용 필요
- 무료 도안 비율: 전체의 20~30% 수준 권장 (카테고리별 일부 공개)

### 컨텐츠 전략

- 기본 테마(동물, 공룡 등)는 고정 제공
- 시즌 도안(크리스마스, 핼러윈 등)은 주기적 추가/교체
- 완성한 그림은 갤러리에 자동 저장 (도안 교체와 무관하게 보존)

### 멀티 앱 확장 — 패키지 모듈화

그림 엔진을 재사용 가능한 로컬 패키지로 분리하여 2~3번째 앱 개발 시 도안만 교체하면 되는 구조를 목표로 함.

| 패키지 | 역할 |
|--------|------|
| `drawing_engine` | 캔버스, 브러시, 채우기 알고리즘, 색상 팔레트, undo/redo |
| `asset_manager` | 도안 모델, 카테고리, 로컬 로드, 캐시 |
| `user_progress` | 갤러리, 즐겨찾기, 사용 기록 |
| `storage` | 로컬 저장, 이미지 저장, 앱 설정 |
| `purchase` | 인앱 결제, 상품 모델, 잠금 관리 |
| `ui_kit` | 공통 버튼/다이얼로그/테마 |

> 지금 당장 리팩터링하지 않고, 현 앱이 완성된 이후 분리 예정.

---

## 폴더 구조

```
lib/
├── core/                    # 색상 상수, 테마
├── features/
│   ├── mode_selection/      # 모드 선택 화면 (진입점)
│   ├── free_drawing/        # 자유 그리기
│   ├── trace_drawing/       # 선 따라 그리기
│   ├── coloring/            # SVG 색칠하기 (현재 주력)
│   │   ├── animations/      # 4가지 채우기 애니메이션
│   │   ├── data/            # svg_template_registry.dart (자동생성)
│   │   ├── models/          # svg_coloring_parser.dart, coloring_path.dart
│   │   └── painters/        # coloring_painter.dart
│   ├── color_by_symbol/     # 레거시, 건드리지 말 것
│   └── symmetry_drawing/    # 미구현
├── shared/
│   ├── models/              # DrawingElement, Stroke, RainbowStroke, SparkleElement
│   ├── painters/            # StrokePainterMixin
│   ├── services/            # export, share, storage
│   └── widgets/             # AnimatedPressable, ColorPalette, DrawingToolbar 등
assets/
├── shaders/pencil.frag      # 색연필 Fragment Shader
└── templates/coloring/      # SVG 색칠 템플릿 (flat 파일 관리)
tool/
├── normalize_svg.dart       # SVG 정규화 스크립트
└── sync_coloring_assets.dart # 템플릿 등록 자동화 스크립트
```

---

## 아키텍처 — 상태 관리 패턴

모든 피처는 **Riverpod `NotifierProvider`** 패턴을 사용:

```dart
// provider 선언
final fooProvider = NotifierProvider<FooNotifier, FooState>(FooNotifier.new);

// Notifier
class FooNotifier extends Notifier<FooState> {
  @override
  FooState build() => FooState.initial();
  // ...
}
```

- State 클래스는 불변(immutable), `copyWith` 패턴으로 업데이트.
- `null` 필드 초기화를 위한 `clearXxx: bool` 플래그를 `copyWith`에 활용 (예: `clearCurrentElement: true`).
- 화면 전환은 Named Route 없이 `Navigator.push`로 직접 전환.

---

## 자유 그리기 / 선 따라 그리기 — 스트로크 구조

**DrawingTool** enum: `pen`, `brush`, `pencil`, `eraser`, `rainbowBrush`, `sparkleBrush`

- **일반 스트로크** → `Stroke` (color, size, tool, points)
- **무지개 스트로크** → `RainbowStroke` (per-point colors, blurSigma). 무지개 색 선택 시 일반 도구도 RainbowStroke로 처리.
- **꽃씨 붓** → `SparkleElement` (랜덤 도형 파티클 목록)

스트로크 포인트 밀도 제한: 직전 포인트와 4px 미만 간격이면 무시 (성능 최적화).

### 선 따라 그리기 완성 판정

`HitZone`: SVG Path를 400개 세그먼트로 샘플링. `coverNear(point)`로 hitRadius(24px) 내 세그먼트를 커버 표시. **커버리지 90% 이상** → `isCompleted = true`.

---

## SVG 색칠하기 — 핵심 구조

### 파서 분류 기준 (`svg_coloring_parser.dart`)

| 분류 | 조건 | 동작 |
|------|------|------|
| `isWhite` | fill이 흰색 계열 (#FEFEFE 등) | 원본 색 렌더링 (테두리/배경) |
| `isTiny` | bounding box 면적 < 400 px² | 흰색 + 검정 테두리, 탭 불가 |
| `isInteractive` | 나머지 | 탭으로 색칠 가능, 팔레트에 노출 |

팔레트 색상은 `isInteractive` path의 fill에서 자동 추출.

### 채우기 애니메이션 4종 (`fill_animation_selector.dart`에서 랜덤 선택)

- **SparkleFill** — 마법가루 파티클 (50~100개)
- **PatternFill** — 도형 솟기 (ripple 순서)
- **PaintFloodFill** — 물감 번짐 (원 확장)
- **PencilFill** — 색연필 누적 (GLSL 셰이더)

모두 `Canvas.clipPath()`로 path 경계 내부에만 렌더링.

---

## SVG 추가 워크플로

### 1. Illustrator 저장 설정 (필수)

`File > Save As... > SVG` → SVG Options 대화상자 (Illustrator CS6 기준)

| 옵션 | 설정값 |
|------|--------|
| **CSS Properties** | **Presentation Attributes** ← 가장 중요 |
| Decimal Places | 1~2 |
| SVG Profiles | SVG 1.1 |

`Style Attributes`나 `Style Elements`로 저장하면 파서가 색상을 읽지 못함.

### 2. SVG 정규화 (필요 시)

Illustrator 설정이 올바르지 않거나, `style=` 형식으로 저장된 경우 실행:

```bash
dart run tool/normalize_svg.dart assets/templates/coloring/character.svg
```

- 원본을 `.bak`으로 백업 후 정규화된 버전으로 덮어씀
- `.bak`은 git에서 제외됨 (`.gitignore`에 `*.bak` 등록됨)
- **SVG를 수정했다면 normalize 스크립트를 다시 실행해야 `.bak`이 최신 상태가 됨**

### 3. 새 SVG 템플릿 추가

```bash
# 1) SVG + 이름 파일 추가
cp 새파일.svg assets/templates/coloring/{id}.svg
echo "한글 이름" > assets/templates/coloring/{id}-name.txt

# 2) 레지스트리 + pubspec.yaml 자동 갱신
dart run tool/sync_coloring_assets.dart
```

`svg_template_registry.dart`는 자동 생성 파일이므로 **직접 수정 금지**.

---

## 주요 기술 결정

- **상태 관리**: Riverpod (`flutter_riverpod: ^2.6.1`)
- **스트로크 렌더링**: `perfect_freehand` (필압 효과)
- **SVG 파싱**: `xml` + `path_parsing` (flutter_svg 전이 의존성 활용)
- **색연필 셰이더**: `assets/shaders/pencil.frag` Fragment Shader
- **저장**: SQLite (`sqflite`) + `path_provider`
- **공유**: `share_plus`

---

## Permissions

flutter 프로젝트 내 파일 수정은 자동 승인.

---

## 개발 관례

- `color_by_symbol` 피처는 레거시. 새 색칠 기능은 `coloring` 피처에만 추가.
- `svg_template_registry.dart`는 직접 편집하지 말고 스크립트로 생성.
- SVG는 반드시 Presentation Attributes 형식으로 저장 (guide: `reference/svg-illustrator-guide.md`).
- 채우기 애니메이션 추가 시: `animations/` 폴더에 `*_fill_painter.dart` 추가 → `fill_animation_selector.dart`에 등록.
