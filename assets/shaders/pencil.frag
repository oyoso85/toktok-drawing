#include <flutter/runtime_effect.glsl>

// uniforms
uniform float uStrokeWidth;   // 획 굵기 (픽셀)
uniform vec4  uColor;         // 색상 (RGBA, premultiplied)
uniform float uStyle;         // 0=색연필, 1=건조(dry/charcoal), 2=수채화(watercolor)

out vec4 fragColor;

// ── Value Noise (2D) ──────────────────────────────────────────────────────────

float hash(vec2 p) {
  p = fract(p * vec2(127.1, 311.7));
  p += dot(p, p + 19.19);
  return fract(p.x * p.y);
}

float valueNoise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));
  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// 4-octave FBM (기본 색연필용)
float fbm(vec2 p) {
  float v = 0.0;
  float amp = 0.5;
  float freq = 1.0;
  for (int i = 0; i < 4; i++) {
    v += amp * valueNoise(p * freq);
    amp  *= 0.5;
    freq *= 2.1;
  }
  return v;
}

// 6-octave FBM (건조 텍스쳐용 — 더 거친 결)
float fbmRough(vec2 p) {
  float v = 0.0;
  float amp = 0.5;
  float freq = 1.0;
  for (int i = 0; i < 6; i++) {
    v += amp * valueNoise(p * freq);
    amp  *= 0.5;
    freq *= 2.2;
  }
  return v;
}

void main() {
  vec2 uv = FlutterFragCoord().xy;
  float sw = max(uStrokeWidth, 1.0);
  float opacity = 1.0;

  int style = int(uStyle + 0.5);

  if (style == 1) {
    // ── 건조한 텍스쳐 (Dry / Charcoal) ──────────────────────────────────────
    // 강한 방향성 줄 결 + 고대비 노이즈 + 종이가 비치는 틈새
    float scale = 14.0 / sw;
    float n = fbmRough(uv * scale);

    // 주 결 방향 (수평 계열 줄) — 진폭을 크게 해서 뚜렷한 선 질감
    float streak1 = sin(uv.y * scale * 3.14 * 3.5) * 0.22;
    // 보조 결 (약간 비스듬, 결의 불균일함 표현)
    float streak2 = sin(uv.y * scale * 3.14 * 7.0 + uv.x * scale * 0.5) * 0.09;

    float raw = n + streak1 + streak2;

    // 임계값 이하 → 완전 투명 (종이 노출), 이상 → 불투명도 급상승
    opacity = raw < 0.28 ? 0.0 : clamp((raw - 0.28) * 1.45, 0.0, 0.93);

  } else if (style == 2) {
    // ── 수채화 (Watercolor) ──────────────────────────────────────────────────
    // 낮은 주파수 FBM → 부드러운 색 풀(pool) + 미세한 표면 텍스쳐
    float scale = 3.0 / sw;
    float n = fbm(uv * scale);

    // 낮고 부드러운 베이스 opacity
    opacity = 0.23 + n * 0.47;

    // 미세 텍스쳐 (고주파 약한 오버레이) — 물감 표면의 입자감
    float fine = fbm(uv * scale * 4.5) * 0.13;
    opacity = clamp(opacity + fine, 0.0, 0.78);

  } else {
    // ── 기본 색연필 (Pencil) ─────────────────────────────────────────────────
    float scale = 8.0 / sw;
    float n = fbm(uv * scale);
    opacity = 0.50 + n * 0.45;
    float streak = sin(uv.y * scale * 3.14 * 2.0) * 0.06;
    opacity = clamp(opacity + streak, 0.0, 1.0);
  }

  fragColor = uColor * opacity;
}
