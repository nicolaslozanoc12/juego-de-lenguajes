class_name ProyectilMagico
extends Area2D

## Proyectil mágico pixel-art con detección física de impacto y expiración por esquive.

signal impactado(objetivo: Node2D, posicion: Vector2)
signal expirado

const PLANTILLAS := {
	"nota": [
		"........oo......",
		"........ooo.....",
		"........oooo....",
		"........oo.oo...",
		"........oo..o...",
		"........oo......",
		"..oooo..oo......",
		".oooooo.oo......",
		"oooooooooo......",
		"oooooooooo......",
		".oooooooo.......",
		"..oooooo........",
		"....oo..........",
		"................",
		"................",
		"................",
	],
	"corte": [
		"................",
		"....ooo.........",
		".....ooooo......",
		"......oooooo....",
		".......ooXXXoo..",
		"........ooXXXXo.",
		".........ooXXXXo",
		"..........ooXXXo",
		"..........ooXXXo",
		".........ooXXXXo",
		"........ooXXXXo.",
		".......ooXXXoo..",
		"......oooooo....",
		".....ooooo......",
		"....ooo.........",
		"................",
	],
	"calavera": [
		"................",
		"....oooooooo....",
		"..oooooooooooo..",
		".ooooXXXXXXoooo.",
		".oooXXXXXXXXooo.",
		"oooXXooXXooXXooo",
		"oooXXooXXooXXooo",
		"oooXXXXXXXXXXooo",
		".oooXXXooXXXooo.",
		".ooooXXXXXXoooo.",
		"..oooooXXooooo..",
		"...oo.o..o.oo...",
		"...oo.o..o.oo...",
		"................",
		"................",
		"................",
	],
	"castigo": [
		"................",
		"......oo........",
		".......ooo......",
		"..ooo....ooo....",
		"...ooooXXoooo...",
		"....ooooXXXooo..",
		"ooXXXXXoooooXXo.",
		".oXXXXXXXXXXooo.",
		".oXXXXXXXXXXooo.",
		"ooXXXXXoooooXXo.",
		"....ooooXXXooo..",
		"...ooooXXoooo...",
		"..ooo....ooo....",
		".......ooo......",
		"......oo........",
		"................",
	],
}

var objetivo: Node2D = null
var velocidad: float = 560.0
var direccion: Vector2 = Vector2.RIGHT
var color_magia: Color = Color(1.0, 0.88, 0.35)
var escala_sprite: float = 2.0
var tamano_hitbox: float = 22.0
var tipo_sprite: String = "nota"
var teledirigido: bool = true
var vida_maxima: float = 1.6
var limites: Rect2 = Rect2()

var _tiempo: float = 0.0
var _terminado: bool = false
var _sprite: Sprite2D
var _estela: CPUParticles2D


func configurar(opts: Dictionary) -> void:
	objetivo = opts.get("objetivo", null)
	velocidad = float(opts.get("velocidad", 560.0))
	color_magia = opts.get("color", Color(1.0, 0.88, 0.35))
	escala_sprite = float(opts.get("escala", 2.0))
	tamano_hitbox = float(opts.get("hitbox", 22.0))
	tipo_sprite = str(opts.get("tipo", "nota"))
	teledirigido = bool(opts.get("teledirigido", true))
	vida_maxima = float(opts.get("vida", 1.6))
	limites = opts.get("limites", Rect2())

	var pos_inicial: Vector2 = opts.get("origen", Vector2.ZERO)
	global_position = pos_inicial
	if opts.has("direccion"):
		direccion = Vector2(opts["direccion"]).normalized()
	elif is_instance_valid(objetivo):
		var delta_obj := objetivo.global_position - pos_inicial
		if delta_obj.length() > 1.0:
			direccion = delta_obj.normalized()


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false

	var shape := RectangleShape2D.new()
	shape.size = Vector2(tamano_hitbox, tamano_hitbox)
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)

	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.texture = _crear_textura_pixel(tipo_sprite)
	_sprite.modulate = color_magia
	_sprite.scale = Vector2(escala_sprite, escala_sprite)
	add_child(_sprite)

	_estela = CPUParticles2D.new()
	_estela.amount = 14
	_estela.lifetime = 0.25
	_estela.local_coords = false
	_estela.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_estela.emission_sphere_radius = 4.0
	_estela.direction = -direccion
	_estela.spread = 30.0
	_estela.initial_velocity_min = 18.0
	_estela.initial_velocity_max = 52.0
	_estela.scale_amount_min = 2.0
	_estela.scale_amount_max = 4.0
	_estela.color = color_magia
	add_child(_estela)

	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _terminado:
		return

	_tiempo += delta
	if _tiempo >= vida_maxima or (limites.has_area() and not limites.has_point(global_position)):
		_terminado = true
		expirado.emit()
		queue_free()
		return

	if teledirigido and is_instance_valid(objetivo):
		var hacia_obj := objetivo.global_position - global_position
		if hacia_obj.length() > 2.0:
			direccion = direccion.lerp(hacia_obj.normalized(), minf(1.0, delta * 9.0)).normalized()

	global_position += direccion * velocidad * delta
	if _sprite:
		if tipo_sprite in ["corte", "castigo"]:
			_sprite.rotation = direccion.angle()
		elif tipo_sprite == "calavera":
			_sprite.rotation = sin(_tiempo * 10.0) * 0.16
		else:
			_sprite.rotation = sin(_tiempo * 14.0) * 0.22


func _on_body_entered(body: Node2D) -> void:
	if _terminado or not is_instance_valid(objetivo):
		return
	if body != objetivo:
		return

	_terminado = true
	_estela.emitting = false
	generar_chispas(get_parent(), global_position, color_magia, 14)
	impactado.emit(objetivo, global_position)
	queue_free()


static func _crear_textura_pixel(tipo: String) -> ImageTexture:
	var plantilla: Array = PLANTILLAS.get(tipo, PLANTILLAS["nota"])
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in range(16):
		var fila: String = plantilla[y]
		for x in range(16):
			var ch := fila[x]
			if ch == "o":
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, 0.96))
			elif ch == "X":
				img.set_pixel(x, y, Color(0.28, 0.08, 0.22, 0.95))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)


## Genera un estallido breve de chispas cuadradas estilo pixel-art.
static func generar_chispas(contenedor: Node, pos: Vector2, color: Color, cantidad: int = 12) -> void:
	if not is_instance_valid(contenedor) or not contenedor.is_inside_tree():
		return
	var particulas := CPUParticles2D.new()
	particulas.global_position = pos
	particulas.one_shot = true
	particulas.explosiveness = 1.0
	particulas.amount = cantidad
	particulas.lifetime = 0.35
	particulas.spread = 180.0
	particulas.initial_velocity_min = 45.0
	particulas.initial_velocity_max = 140.0
	particulas.scale_amount_min = 2.5
	particulas.scale_amount_max = 5.0
	particulas.color = color
	contenedor.add_child(particulas)
	particulas.emitting = true

	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = 0.55
	timer.autostart = true
	particulas.add_child(timer)
	timer.timeout.connect(particulas.queue_free)


## Crea texto flotante ascendente para daño, parry o esquive en la arena.
static func crear_texto_flotante(contenedor: Node, pos: Vector2, texto: String, color: Color) -> void:
	if not is_instance_valid(contenedor):
		return
	var lbl := Label.new()
	lbl.text = texto
	lbl.position = pos + Vector2(-70, -68)
	lbl.size = Vector2(160, 28)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.1, 0.95))
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.z_index = 25
	contenedor.add_child(lbl)

	var tween := lbl.create_tween()
	tween.set_parallel(true)
	tween.tween_property(lbl, "position:y", lbl.position.y - 28.0, 0.85)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.85)
	tween.chain().tween_callback(func() -> void:
		if is_instance_valid(lbl):
			lbl.queue_free()
	)
