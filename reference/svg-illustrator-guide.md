# Illustrator SVG 저장 가이드

색칠하기 기능에서 사용할 SVG를 Adobe Illustrator에서 올바르게 저장하기 위한 가이드.

---

## SVG 파서 동작 방식

앱은 SVG의 `<path>` 요소만 파싱하며, 각 path를 아래 기준으로 분류한다.

| 분류 | 조건 | 동작 |
|------|------|------|
| **isWhite** | fill이 흰색 계열 (#FEFEFE 등) | 원본 색으로 렌더링 (배경/아웃라인) |
| **isTiny** | bounding box 면적 < 400 px² | 흰색 + 검정 테두리 (탭 불가) |
| **isInteractive** | 위 두 경우에 해당하지 않는 나머지 | 색칠 대상 (팔레트 색 선택 후 탭) |

팔레트 색상은 `isInteractive` path의 fill 색상에서 자동 추출한다.

---

## Illustrator 저장 설정

`File > Export > Export As...` → 형식: **SVG**

| 옵션 | 설정값 | 이유 |
|------|--------|------|
| **Styling** | **Presentation Attributes** | `fill="#e6a032"` 형식으로 export (필수) |
| Decimal Places | 1~2 | 파일 크기 최적화 |
| Minify | 체크 안 함 | 디버그 편의 |
| Responsive | 체크 안 함 | viewBox 고정 필요 |

> **Styling이 가장 중요하다.** `Internal CSS`나 `Inline Style`로 저장하면
> `<path style="fill:#e6a032">` 형식이 되어 파서가 색상을 읽지 못한다.

---

## 올바른 SVG 구조 예시

```xml
<!-- ✅ 올바른 형식 -->
<path fill="#e6a032" d="M 10 20 L 30 40 Z"/>
<path fill="#21808a" fill-rule="evenodd" d="M ..."/>

<!-- ❌ 파서 미지원 (Styling 옵션 오설정) -->
<path style="fill:#e6a032" d="..."/>

<!-- ⚠️ 채색 불가 (fill 없음, stroke만 있음) -->
<path fill="none" stroke="#000000" d="..."/>
```

---

## 아트워크 제작 규칙

### 색상
- 모든 채색 면에 **Solid Color Fill** 사용 (`#RRGGBB` 형식)
- Gradient, Pattern 사용 금지 (파서가 인식 못함)
- 아웃라인용 path는 fill을 흰색(`#FFFFFF` 또는 `#FEFEFE`)으로 설정

### 레이어 구조
- 같은 도형을 여러 레이어에 **중복 배치 금지**
  - Illustrator가 동일한 `d` 속성의 path를 두 번 export하는 아티팩트 발생
  - 앱은 중복 path를 자동으로 제거하지만, 의도치 않은 누락이 생길 수 있음
- Layers 패널에서 객체가 한 번씩만 존재하는지 확인

### 피해야 할 작업
- 복사 후 다른 레이어에 쌓기 → 중복 path
- Clipping Mask 사용 → path bounds 계산 오류
- Compound Path 안에 여러 색 혼용 → 단일 fill만 인식

---

## 저장 후 확인 방법

텍스트 에디터로 SVG 파일을 열어 `<path>` 요소 확인:

```bash
# path 수 및 fill 색상 목록 확인 (Python)
python -c "
import xml.etree.ElementTree as ET
root = ET.parse('character.svg').getroot()
ns = '{http://www.w3.org/2000/svg}'
paths = root.findall(f'.//{ns}path')
print(f'Total paths: {len(paths)}')
from collections import Counter
fills = Counter(p.get('fill','none').lower() for p in paths)
for color, count in fills.most_common():
    print(f'  {color}: {count}개')
"
```

---

## 트러블슈팅

| 증상 | 원인 | 해결 |
|------|------|------|
| 팔레트 색상이 누락됨 | `isTiny` 판정 (면적 < 400 px²) | Illustrator에서 해당 면 확대 |
| 특정 영역 탭해도 반응 없음 | fill 색상 불일치 또는 `isWhite` 판정 | fill 색상 확인, 흰색 계열 여부 확인 |
| 모두 칠해도 완성 안 됨 | 중복 path 존재 | Layers 패널에서 중복 객체 제거 후 재export |
| 처음부터 색칠된 면이 있음 | `isWhite` path가 아닌데 원본 색 렌더링 | fill이 흰색에 가깝지만 정확히 흰색이 아닌 path 확인 |
