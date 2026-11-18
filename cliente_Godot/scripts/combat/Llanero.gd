extends CharacterBody2D

const DireccionHelper := preload("res://scripts/combat/DireccionHelper.gd")

const SPEED: float = 220.0
var health: int = 100
var knockback_velocity: Vector2 = Vector2.ZERO
var ultima_direccion: String = "down_right"
var inmovilizado_restante: float = 0.0
var _estaba_inmovilizado: bool = false

@onready var sprite_animado: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("player")
	_actualizar_animacion(Vector2.ZERO)


func _physics_process(delta: float) -> void:
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


func _actualizar_animacion(input_dir: Vector2) -> void:
	if not sprite_animado:
		return
	if input_dir.length() > 0.1:
		ultima_direccion = DireccionHelper.vector_a_nombre(input_dir)
		_reproducir("walk_" + ultima_direccion)
	else:
		_reproducir("idle_" + ultima_direccion)


func _reproducir(anim_name: String) -> void:
	if sprite_animado.sprite_frames and sprite_animado.sprite_frames.has_animation(anim_name):
		if sprite_animado.animation != anim_name:
			sprite_animado.play(anim_name)


func aplicar_rebote_muro(centro_arena: Vector2, dano: int) -> void:
	health = max(0, health - dano)
	var dir_al_centro := (centro_arena - global_position).normalized()
	knockback_velocity = dir_al_centro * 420.0
	modulate = Color(1.0, 0.35, 0.55)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.35)


## Inmoviliza al Llanero durante `duracion` segundos (p. ej. al errar la gramática).
func inmovilizar(duracion: float = 1.0) -> void:
	inmovilizado_restante = maxf(inmovilizado_restante, duracion)
	if inmovilizado_restante > 0.0:
		_estaba_inmovilizado = true
		velocity = Vector2.ZERO
		modulate = Color(1.0, 0.72, 0.45)


func esta_inmovilizado() -> bool:
	return inmovilizado_restante > 0.0
