void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 terminal = texture(iChannel0, uv);

    float scanline = 0.035 * sin(fragCoord.y * 3.14159);
    float phosphor = 0.018 * sin((fragCoord.x + fragCoord.y) * 0.75);

    vec2 centered = uv - 0.5;
    float vignette = 1.0 - dot(centered, centered) * 0.32;

    vec3 color = terminal.rgb;
    color += vec3(phosphor * 0.6, phosphor, phosphor * 0.8);
    color *= vignette - scanline;

    fragColor = vec4(clamp(color, 0.0, 1.0), terminal.a);
}
