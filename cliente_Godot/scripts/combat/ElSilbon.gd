extends CharacterBody2D

## Controla el movimiento en 8 direcciones y acecho de El Silbón dentro de la arena.

const DireccionHelper := preload("res://scripts/combat/DireccionHelper.gd")

@export var velocidad_acecho: float = 55.0
@export var centro_patrulla: Vector2 = Vector2(640, 415)
@export var radio_patrulla: Vector2 = Vector2(125, 58)

@onready var sprite_animado: AnimatedSprite2D = $AnimatedSprite2D
@onready var jugador: Node2D = get_tree().get_first_node_in_group("player")

var ultima_direccion: String = "down"
var _tiempo: float = 0.0
var _pausa_timer: float = 0.0


func _ready() -> void:
	if sprite_animado and sprite_animado.sprite_frames:
		sprite_animado.play("idle_" + ultima_direccion)


func _physics_process(delta: float) -> void:
	if not jugador:
		jugador = get_tree().get_first_node_in_group("player")

	_tiempo += delta
	# Alterna caminatas lentas en óvalo y pausas breves mirando hacia el llanero
	var ciclo := fmod(_tiempo, 5.2)
	var en_movimiento := ciclo < 3.8

	if en_movimiento:
		var objetivo := centro_patrulla + Vector2(
			cos(_tiempo * 0.72) * radio_patrulla.x,
			sin(_tiempo * 1.44) * radio_patrulla.y
		)
		var delta_pos := objetivo - global_position
		if delta_pos.length() > 4.0:
			var dir := delta_pos.normalized()
			velocity = dir * velocidad_acecho
			move_and_slide()
			ultima_direccion = DireccionHelper.vector_a_nombre(dir)
			_reproducir("walk_" + ultima_direccion)
			return

	velocity = Vector2.ZERO
	if jugador:
		var hacia_jugador := jugador.global_position - global_position
		if hacia_jugador.length() > 4.0:
			ultima_direccion = DireccionHelper.vector_a_nombre(hacia_jugador.normalized())
	_reproducir("idle_" + ultima_direccion)


func _reproducir(anim_name: String) -> void:
	if sprite_animado and sprite_animado.sprite_frames and sprite_animado.sprite_frames.has_animation(anim_name):
		if sprite_animado.animation != anim_name:
			sprite_animado.play(anim_name)
