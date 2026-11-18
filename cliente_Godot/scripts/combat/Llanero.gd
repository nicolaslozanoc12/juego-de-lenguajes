extends CharacterBody2D

signal derrotado

const DireccionHelper := preload("res://scripts/combat/DireccionHelper.gd")
const ProyectilMagicoScript := preload("res://scripts/combat/ProyectilMagico.gd")

const SPEED: float = 220.0
const MAX_HEALTH: int = 100

var health: int = MAX_HEALTH:
	set(value):
		var prev := health
		health = maxi(0, value)
		queue_redraw()
		if prev > 0 and health == 0 and not _muerto:
			morir()
			derrotado.emit()

var knockback_velocity: Vector2 = Vector2.ZERO
var ultima_direccion: String = "right"
var inmovilizado_restante: float = 0.0
var combate_terminado: bool = false
var _muerto: bool = false
var _estaba_inmovilizado: bool = false
var _escudo_restante: float = 0.0
var _escudo_color: Color = Color(0.35, 0.92, 1.0)

@onready var sprite_animado: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("player")
	_actualizar_animacion(Vector2.ZERO)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _muerto or combate_terminado:
		velocity = Vector2.ZERO
		if _muerto:
			_reproducir("dead")
		else:
			_reproducir("idle_" + ultima_direccion)
		return

	if _escudo_restante > 0.0:
		_escudo_restante = maxf(0.0, _escudo_restante - delta)
		queue_redraw()

	if inmovilizado_restante > 0.0:
		inmovilizado_restante = maxf(0.0, inmovilizado_restante - delta)
		if inmovilizado_restante == 0.0 and _estaba_inmovilizado:
			_estaba_inmovilizado = false
			modulate = Color.WHITE
	elif _estaba_inmovilizado:
		_estaba_inmovilizado = false
		modulate = Color.WHITE

	var input_dir := Vector2.ZERO
	if knockback_velocity.length() > 5.0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	elif inmovilizado_restante > 0.0:
		velocity = Vector2.ZERO
	else:
		input_dir = Vector2(
			Input.get_axis("ui_left", "ui_right"),
			Input.get_axis("ui_up", "ui_down")
		)
		if Input.is_key_pressed(KEY_A): input_dir.x -= 1.0
		if Input.is_key_pressed(KEY_D): input_dir.x += 1.0
		if Input.is_key_pressed(KEY_W): input_dir.y -= 1.0
		if Input.is_key_pressed(KEY_S): input_dir.y += 1.0
		input_dir = input_dir.limit_length(1.0)
		velocity = input_dir * SPEED

	move_and_slide()
	_actualizar_animacion(input_dir)


func _draw() -> void:
	var barra_fondo := Rect2(-24, -48, 48, 6)
	draw_rect(Rect2(-25, -49, 50, 8), Color(0.04, 0.04, 0.08, 0.9))
	draw_rect(barra_fondo, Color(0.18, 0.14, 0.2, 0.9))
	var ratio := clampf(float(health) / float(MAX_HEALTH), 0.0, 1.0)
	if ratio > 0.0:
		var color_vida := Color(0.32, 0.9, 0.48) if ratio > 0.35 else Color(0.95, 0.32, 0.32)
		draw_rect(Rect2(-24, -48, 48.0 * ratio, 6), color_vida)

	if _escudo_restante > 0.0 and not _muerto:
		var alpha := clampf(_escudo_restante * 1.4, 0.15, 0.85)
		var pulso := 1.0 + 0.08 * sin(_escudo_restante * 24.0)
		var medio := 32.0 * pulso
		var col_borde := Color(_escudo_color.r, _escudo_color.g, _escudo_color.b, alpha)
		draw_rect(Rect2(-medio, -medio + 4.0, medio * 2.0, medio * 2.0), Color(_escudo_color.r, _escudo_color.g, _escudo_color.b, alpha * 0.18))
		draw_rect(Rect2(-medio, -medio + 4.0, medio * 2.0, medio * 2.0), col_borde, false, 2.5)


func _actualizar_animacion(input_dir: Vector2) -> void:
	if not sprite_animado or _muerto:
		return
	if input_dir.length() > 0.1:
		ultima_direccion = DireccionHelper.vector_a_nombre(input_dir)
		_reproducir("walk_" + ultima_direccion)
	else:
		_reproducir("idle_" + ultima_direccion)


func _reproducir(anim_name: String) -> void:
	if sprite_animado and sprite_animado.sprite_frames and sprite_animado.sprite_frames.has_animation(anim_name):
		if sprite_animado.animation != anim_name:
			sprite_animado.play(anim_name)


func obtener_vector_direccion() -> Vector2:
	return DireccionHelper.nombre_a_vector(ultima_direccion)


func morir() -> void:
	_muerto = true
	combate_terminado = true
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	inmovilizado_restante = 0.0
	_estaba_inmovilizado = false
	_escudo_restante = 0.0
	modulate = Color.WHITE
	if sprite_animado:
		sprite_animado.scale = Vector2(2.3, 2.3)
		_reproducir("dead")
	ProyectilMagicoScript.generar_chispas(get_parent(), global_position, Color(1.0, 0.35, 0.35), 18)


func detener_por_fin_combate() -> void:
	combate_terminado = true
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	inmovilizado_restante = 0.0
	_estaba_inmovilizado = false
	_escudo_restante = 0.0
	modulate = Color.WHITE
	if not _muerto:
		_reproducir("idle_" + ultima_direccion)


func _aplicar_empuje(dir: Vector2, dano: int, fuerza: float, tinte: Color) -> void:
	if _muerto or combate_terminado:
		return
	self.health = max(0, health - dano)
	if _muerto:
		return
	knockback_velocity = (dir if dir.length() > 0.05 else Vector2.LEFT).normalized() * fuerza
	modulate = tinte
	var color_objetivo := Color(1.0, 0.72, 0.45) if esta_inmovilizado() else Color.WHITE
	var tween := create_tween()
	tween.tween_property(self, "modulate", color_objetivo, 0.32)


func aplicar_rebote_muro(centro_arena: Vector2, dano: int) -> void:
	_aplicar_empuje(centro_arena - global_position, dano, 420.0, Color(1.0, 0.35, 0.55))


## Daño físico cuerpo a cuerpo directo en arena (como el muro, sin pasar por la Máquina de Turing).
func recibir_golpe_cuerpo_a_cuerpo(origen_enemigo: Vector2, dano: int) -> void:
	if _muerto or combate_terminado:
		return
	_aplicar_empuje(global_position - origen_enemigo, dano, 360.0, Color(1.0, 0.25, 0.38))
	ProyectilMagicoScript.generar_chispas(get_parent(), global_position, Color(1.0, 0.28, 0.45), 14)
	ProyectilMagicoScript.crear_texto_flotante(get_parent(), global_position, "-%d HP ⚡" % dano, Color(1.0, 0.35, 0.45))


## Inmoviliza al Llanero durante `duracion` segundos (p. ej. al errar la gramática).
func inmovilizar(duracion: float = 1.0) -> void:
	if _muerto or combate_terminado:
		return
	inmovilizado_restante = maxf(inmovilizado_restante, duracion)
	if inmovilizado_restante > 0.0:
		_estaba_inmovilizado = true
		velocity = Vector2.ZERO
		modulate = Color(1.0, 0.72, 0.45)


func esta_inmovilizado() -> bool:
	return inmovilizado_restante > 0.0


## Pulso visual breve al conjurar un acorde válido con el Cuatro.
func mostrar_destello_cuatro(color: Color) -> void:
	if _muerto or combate_terminado:
		return
	if sprite_animado:
		var tween := create_tween()
		tween.tween_property(sprite_animado, "scale", Vector2(2.55, 2.55), 0.08)
		tween.tween_property(sprite_animado, "scale", Vector2(2.3, 2.3), 0.12)
	ProyectilMagicoScript.generar_chispas(get_parent(), global_position + Vector2(0, -8), color, 8)


## Muestra una barrera cuadrada armónica para golpes defensivos (Parry / Esquive).
func mostrar_escudo_armonico(color: Color, duracion: float = 0.95, etiqueta: String = "🛡️ PARRY") -> void:
	if _muerto or combate_terminado:
		return
	_escudo_color = color
	_escudo_restante = maxf(_escudo_restante, duracion)
	queue_redraw()
	ProyectilMagicoScript.crear_texto_flotante(get_parent(), global_position, etiqueta, color)


## Reacción visual y descuento real de vida cuando un proyectil enemigo impacta al Llanero.
func recibir_impacto_visual(color: Color, dano: int, bloqueado: bool = false) -> void:
	if _muerto or combate_terminado:
		return
	if bloqueado:
		ProyectilMagicoScript.crear_texto_flotante(get_parent(), global_position, "🛡️ BLOQUEADO", Color(0.45, 0.95, 1.0))
		ProyectilMagicoScript.generar_chispas(get_parent(), global_position, Color(0.45, 0.95, 1.0), 12)
		return

	if dano > 0:
		self.health = max(0, health - dano)
		ProyectilMagicoScript.crear_texto_flotante(get_parent(), global_position, "-%d HP" % dano, Color(1.0, 0.42, 0.42))
	if _muerto:
		return
	var color_objetivo := Color(1.0, 0.72, 0.45) if esta_inmovilizado() else Color.WHITE
	modulate = color
	var tween := create_tween()
	tween.tween_property(self, "modulate", color_objetivo, 0.25)


func mostrar_esquive() -> void:
	if _muerto or combate_terminado:
		return
	ProyectilMagicoScript.crear_texto_flotante(get_parent(), global_position, "💨 ¡ESQUIVADO!", Color(0.65, 0.95, 1.0))


## Retroalimentación de cuerda desafinada e inmovilización sobre el jugador.
func mostrar_desafinacion() -> void:
	if _muerto or combate_terminado:
		return
	ProyectilMagicoScript.generar_chispas(get_parent(), global_position, Color(1.0, 0.35, 0.35), 14)
	ProyectilMagicoScript.crear_texto_flotante(get_parent(), global_position, "✖ INMOVILIZADO 1s", Color(1.0, 0.55, 0.45))
