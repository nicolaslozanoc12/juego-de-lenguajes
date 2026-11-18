extends RefCounted

## Utilidad para convertir un vector 2D en uno de los 8 nombres cardinales de animación.

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


static func vector_a_nombre(dir: Vector2) -> String:
	var sector := wrapi(int(round(dir.angle() / (TAU / 8.0))), 0, 8)
	return DIRECCIONES[sector]
