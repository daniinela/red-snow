shader_type canvas_item;

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
    COLOR = vec4(gray, gray, gray, col.a);
}