#include <flutter/runtime_effect.glsl>

// uniforms
uniform float uStrokeWidth;   // 획 굵기 (픽셀)
uniform vec4  uColor;         // 색연필 색상 (RGBA, premultiplied)

out vec4 fragColor;

// ── Value Noise (2D) ──────────────────────────────────────────────────────────
// 격자 기반 해시 → 부드러운 노이즈. Perlin보다 가볍고 GLSL에서 의존성 없음.

float hash(vec2 p) {
  p = fract(p * vec2(127.1, 311.7));
  p += dot(p, p + 19.19);
  return fract(p.x * p.y);
}

float valueNoise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  // 부드러운 보간 (smoothstep)
  vec2 u = f * f * (3.0 - 2.0 * f);

  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));

  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// FBM (Fractal Brownian Motion): 여러 옥타브 noise 합산 → 자연스러운 결 느낌
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

void main() {
  // FlutterFragCoord(): 현재 픽셀의 로컬 좌표 (획 path bounding box 기준)
  vec2 uv = FlutterFragCoord().xy;

  // 노이즈 스케일: 획 굵기에 비례해 결 밀도 조정
  // 굵을수록 결이 성기고(낮은 freq), 가늘수록 촘촘함(높은 freq)
  float scale = 8.0 / max(uStrokeWidth, 1.0);
  float n = fbm(uv * scale);

  // 색연필 특성:
  // - 중심부는 진하고 가장자리로 갈수록 흐릿하게 (종이 질감)
  // - 노이즈로 군데군데 투명 → 종이가 비침
  // opacity: 기본 0.55 + noise 가중치 (0.0~0.45 범위)
  float opacity = 0.50 + n * 0.45;

  // 결 방향성: 수평 방향 sine파로 미세한 줄 결 추가 (색연필 특유의 가로 결)
  float streak = sin(uv.y * scale * 3.14 * 2.0) * 0.06;
  opacity = clamp(opacity + streak, 0.0, 1.0);

  // 최종 색상: 입력 색상에 opacity 적용
  fragColor = uColor * opacity;
}
