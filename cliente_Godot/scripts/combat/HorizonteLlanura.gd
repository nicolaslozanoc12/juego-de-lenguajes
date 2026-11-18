extends CanvasLayer

## Controla la franja fija del horizonte llanero (cielo, luna, nubes y árboles al ventarrón).
## Al vivir en un CanvasLayer de fondo, permanece siempre visible arriba aunque la cámara se mueva.

@export var velocidad_nubes: float = 16.0
@export var amplitud_luna: Vector2 = Vector2(3.5, 4.0)

@onready var luna: Sprite2D = $LunaLlanera
@onready var nubes_a: Sprite2D = $NubesA
@onready var nubes_b: Sprite2D = $NubesB

var _tiempo: float = 0.0
var _luna_origen: Vector2 = Vector2.ZERO
var _ancho_nubes: float = 1280.0


func _ready() -> void:
	if luna:
		_luna_origen = luna.position
	if nubes_a and nubes_a.texture:
		_ancho_nubes = nubes_a.texture.get_width() * nubes_a.scale.x
		if nubes_b:
			nubes_b.position.x = nubes_a.position.x - _ancho_nubes


func _process(delta: float) -> void:
	_tiempo += delta

	# La luna se mueve muy poquito flotando en la noche
	if luna:
		luna.position = _luna_origen + Vector2(
			sin(_tiempo * 0.35) * amplitud_luna.x,
			cos(_tiempo * 0.6) * amplitud_luna.y
		)

	# Las nubes avanzan de forma continua hacia un lado (bucle infinito)
	if nubes_a and nubes_b:
		var dx := velocidad_nubes * delta
		nubes_a.position.x += dx
		nubes_b.position.x += dx
		if nubes_a.position.x >= _ancho_nubes:
			nubes_a.position.x = nubes_b.position.x - _ancho_nubes
		if nubes_b.position.x >= _ancho_nubes:
			nubes_b.position.x = nubes_a.position.x - _ancho_nubes
