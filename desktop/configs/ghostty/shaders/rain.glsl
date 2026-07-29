float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float drop(vec2 uv, float speed, float scale, float size) {
    uv *= scale;

    vec2 cell = floor(uv);
    vec2 local = fract(uv);
    float seed = hash12(cell);

    float y = fract(local.y + iTime * speed + seed);
    float x = 0.5 + (seed - 0.5) * 0.55;
    float wobble = sin((uv.y + seed * 6.28318) * 7.0) * 0.045;

    vec2 head = vec2(x + wobble, y);
    vec2 delta = (local - head) * vec2(1.0, 2.7);
    float bead = smoothstep(size, 0.0, length(delta));

    float trailWidth = size * 0.42;
    float behind = smoothstep(0.0, 0.55, head.y - local.y);
    float trail = smoothstep(trailWidth, 0.0, abs(local.x - head.x - wobble)) * behind;
    trail *= smoothstep(0.9, 0.15, head.y - local.y);

    return bead + trail * 0.35;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 terminal = texture(iChannel0, uv);

    float rain =
        drop(uv + vec2(0.00, 0.00), 0.31, 18.0, 0.085) +
        drop(uv + vec2(0.37, 0.19), 0.22, 28.0, 0.060) +
        drop(uv + vec2(0.11, 0.43), 0.42, 11.0, 0.110);

    rain = clamp(rain, 0.0, 1.0);

    vec2 refractUv = uv + vec2(rain * 0.0025, -rain * 0.006);
    vec3 color = texture(iChannel0, refractUv).rgb;

    vec3 highlight = vec3(0.62, 0.78, 1.0) * rain * 0.18;
    color = mix(color, color * 0.82, rain * 0.18) + highlight;

    fragColor = vec4(clamp(color, 0.0, 1.0), terminal.a);
}
