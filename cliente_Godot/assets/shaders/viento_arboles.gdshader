shader_type canvas_item;

uniform float speed = 2.8;
uniform float strength = 5.5;
uniform float phase = 0.0;

void vertex() {
	// La base del tronco (UV.y = 1.0) queda anclada; la copa (UV.y = 0.0) oscila a ambos lados.
	float sway = pow(1.0 - UV.y, 1.6);
	float gust = sin(TIME * speed + phase) + 0.35 * sin(TIME * speed * 2.1 + phase * 1.7);
	VERTEX.x += gust * strength * sway;
}
