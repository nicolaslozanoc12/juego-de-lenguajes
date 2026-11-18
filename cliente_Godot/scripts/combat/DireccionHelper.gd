extends RefCounted

## Utilidades para convertir vectores 2D y nombres de las 8 direcciones cardinales.

const DIRECCIONES := [
	"right",
	"down_right",
	"down",
	"down_left",
	"left",
	"up_left",
	"up",
	"up_right",
]

const VECTORES := {
	"right": Vector2(1.0, 0.0),
	"down_right": Vector2(1.0, 1.0),
	"down": Vector2(0.0, 1.0),
	"down_left": Vector2(-1.0, 1.0),
	"left": Vector2(-1.0, 0.0),
	"up_left": Vector2(-1.0, -1.0),
	"up": Vector2(0.0, -1.0),
	"up_right": Vector2(1.0, -1.0),
}


static func vector_a_nombre(dir: Vector2) -> String:
	var sector := wrapi(int(round(dir.angle() / (TAU / 8.0))), 0, 8)
	return DIRECCIONES[sector]


static func nombre_a_vector(nombre: String) -> Vector2:
	return Vector2(VECTORES.get(nombre, Vector2.RIGHT)).normalized()
