# toktok-drawing

<!-- flutter clean && flutter run -d web-server --web-port 8080 -->
<!-- {"name":"pencil","transport":"stdio","command":"c:\\Users\\jaebu\\.vscode\\extensions\\highagency.pencildev-0.6.32\\out\\mcp-server-windows-x64.exe","args":["--app","visual_studio_code"],"env":{}} -->

3~7세 유아를 위한 그림그리기 앱. Flutter 기반 iOS/Android 앱으로 완전 오프라인 동작.

---

## 주요 기능

| 기능 | 설명 |
|------|------|
| 자유 그리기 | 펜, 붓, 색연필, 지우개, 무지개붓, 꽃씨붓 |
| 선 따라 그리기 | SVG 가이드 위에 손가락으로 따라 그리기 |
| SVG 색칠하기 | 도안 영역 탭 → 마법 애니메이션으로 색 채우기 |

---

## 기술 스택

- **Flutter** (iOS / Android, 가로 모드 고정)
- **Riverpod** — 상태 관리
- **perfect_freehand** — 필압 스트로크 렌더링
- **GLSL Fragment Shader** — 색연필 효과
- **xml + path_parsing** — SVG 파싱 및 색칠

---

## 빌드

```bash
# 개발 실행
flutter run

# Android APK
flutter build apk --release

# iOS
flutter build ios --release

# SVG 도안 추가 후 레지스트리 갱신
dart run tool/sync_coloring_assets.dart
```

---

## SVG 도안 추가

1. Illustrator에서 **Presentation Attributes** 형식으로 저장 (`style=` 형식 사용 금지)
2. `assets/templates/coloring/{폴더명}/` 에 SVG 파일과 `name.txt` 배치
3. `dart run tool/sync_coloring_assets.dart` 실행

자세한 내용은 `reference/svg-illustrator-guide.md` 참고.
