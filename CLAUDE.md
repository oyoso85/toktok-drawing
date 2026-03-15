# CLAUDE.md — toktok-drawing 프로젝트 가이드

3~7세 유아용 그림그리기 앱. Flutter (iOS/Android), 완전 오프라인.

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

## 폴더 구조

```
lib/
├── core/                    # 색상 상수, 테마
├── features/
│   ├── mode_selection/      # 모드 선택 화면
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
└── templates/coloring/      # SVG 색칠 템플릿 (폴더 단위 관리)
tool/
├── normalize_svg.dart       # SVG 정규화 스크립트
└── sync_coloring_assets.dart # 템플릿 등록 자동화 스크립트
```

---

## SVG 색칠하기 — 핵심 구조

### 파서 분류 기준 (`svg_coloring_parser.dart`)

| 분류 | 조건 | 동작 |
|------|------|------|
| `isWhite` | fill이 흰색 계열 (#FEFEFE 등) | 원본 색 렌더링 (테두리/배경) |
| `isTiny` | bounding box 면적 < 400 px² | 흰색 + 검정 테두리, 탭 불가 |
| `isInteractive` | 나머지 | 탭으로 색칠 가능, 팔레트에 노출 |

팔레트 색상은 `isInteractive` path의 fill에서 자동 추출.

### 채우기 애니메이션 4종

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
dart run tool/normalize_svg.dart assets/templates/coloring/character/character.svg
```

- 원본을 `.bak`으로 백업 후 정규화된 버전으로 덮어씀
- `.bak`은 git에서 제외됨 (`.gitignore`에 `*.bak` 등록됨)
- **SVG를 수정했다면 normalize 스크립트를 다시 실행해야 `.bak`이 최신 상태가 됨**

### 3. 새 SVG 템플릿 추가

```bash
# 1) 폴더 + 파일 생성
mkdir assets/templates/coloring/{폴더명}/
cp 새파일.svg assets/templates/coloring/{폴더명}/{폴더명}.svg
echo "한글 이름" > assets/templates/coloring/{폴더명}/name.txt

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
- **공유**: `share_plus` + `image_gallery_saver`

---

## 주요 의존성

```yaml
flutter_riverpod: ^2.6.1
perfect_freehand: ^2.5.2+1
flutter_svg: ^2.0.16
sqflite: ^2.4.1
xml: ^6.0.0
path_parsing: ^1.1.0
share_plus: ^10.1.4
image_gallery_saver: ^2.0.3
```

---

## 개발 관례

- `color_by_symbol` 피처는 레거시. 새 색칠 기능은 `coloring` 피처에만 추가.
- `svg_template_registry.dart`는 직접 편집하지 말고 스크립트로 생성.
- SVG는 반드시 Presentation Attributes 형식으로 저장 (guide: `reference/svg-illustrator-guide.md`).
- 채우기 애니메이션 추가 시: `animations/` 폴더에 `*_fill_painter.dart` 추가 → `fill_animation_selector.dart`에 등록.
