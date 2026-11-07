extends CharacterBody2D

const SPEED: float = 220.0
var health: int = 100
var knockback_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	if knockback_velocity.length() > 5.0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	else:
		var input_dir := Vector2(
			Input.get_axis("ui_left", "ui_right"),
			Input.get_axis("ui_up", "ui_down")
		)
		if Input.is_key_pressed(KEY_A): input_dir.x -= 1.0
		if Input.is_key_pressed(KEY_D): input_dir.x += 1.0
		if Input.is_key_pressed(KEY_W): input_dir.y -= 1.0
		if Input.is_key_pressed(KEY_S): input_dir.y += 1.0
		velocity = input_dir.limit_length(1.0) * SPEED

	move_and_slide()

func aplicar_rebote_muro(centro_arena: Vector2, dano: int) -> void:
	health = max(0, health - dano)
	var dir_al_centro := (centro_arena - global_position).normalized()
	knockback_velocity = dir_al_centro * 420.0
	modulate = Color(1.0, 0.3, 0.3)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.35)
