extends Node2D

const TILE_SIZE: int = 32
const ARENA_RECT := Rect2(96, 224, 1088, 448)

@onready var ground_root: Node2D = $TerrenoSabana
@onready var llanero: CharacterBody2D = $Llanero
@onready var demonio: Sprite2D = $DemonioEspanto/Sprite2D
@onready var label_estado: Label = $UI/LabelEstado

var tileset_tex: Texture2D = preload("res://assets/sprites/tiles/tileset_sabana.png")
var time_passed: float = 0.0

func _ready() -> void:
	_generar_suelo_sabana()

func _generar_suelo_sabana() -> void:
	# Llenar el suelo del ruedo (desde Y=192 hasta Y=720) con las 4 baldosas de 32x32
	var cols := int(1280.0 / 64.0)
	var start_y := 192
	var rows := int((720.0 - start_y) / 64.0) + 1

	var rng := RandomNumberGenerator.new()
	rng.seed = 202611

	for r in range(rows):
		for c in range(cols):
			var tile_spr := Sprite2D.new()
			tile_spr.texture = tileset_tex
			tile_spr.centered = false
			tile_spr.region_enabled = true

			# Elegir tipo de baldosa: 0=pasto, 1=pasto seco, 2=tierra (centro), 3=roca (esquinas del boceto)
			var tile_idx := 0
			var dist_centro := Vector2(c - cols / 2.0, r - rows / 2.0).length()
			if (c == 3 and r == 2) or (c == 16 and r == 5) or (c == 15 and r == 2):
				tile_idx = 3 # Rocas del boceto
			elif dist_centro < 3.8:
				tile_idx = 2 # Ruedo central de tierra
			elif rng.randf() < 0.28:
				tile_idx = 1 # Pajonal seco

			tile_spr.region_rect = Rect2(tile_idx * TILE_SIZE, 0, TILE_SIZE, TILE_SIZE)
			tile_spr.scale = Vector2(2, 2) # Escala pixel-art 64x64 en pantalla
			tile_spr.position = Vector2(c * 64, start_y + r * 64)
			ground_root.add_child(tile_spr)

func _process(delta: float) -> void:
	time_passed += delta
	# Animación amenazante del Demonio / Espanto en el centro
	if demonio:
		demonio.position.y = sin(time_passed * 3.2) * 5.0
		demonio.scale = Vector2(3.5, 3.5) + Vector2(sin(time_passed * 1.8) * 0.08, -sin(time_passed * 1.8) * 0.08)

	# Verificar si el Llanero toca el Muro Mágico / Cerco Espectral del borde
	if llanero:
		if not ARENA_RECT.has_point(llanero.global_position):
			var centro := ARENA_RECT.get_center()
			llanero.aplicar_rebote_muro(centro, 5)
			if label_estado:
				label_estado.text = "⚡ ¡El Muro Espectral te quema! (-5 HP) | Vida Llanero: %d" % llanero.health
				label_estado.modulate = Color(1.0, 0.45, 0.45)
