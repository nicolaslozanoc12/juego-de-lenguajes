extends CharacterBody2D

## Controla el movimiento en 8 direcciones, acecho y respuestas visuales de El Silbón.

const DireccionHelper := preload("res://scripts/combat/DireccionHelper.gd")
const ProyectilMagicoScript := preload("res://scripts/combat/ProyectilMagico.gd")

const MAX_HEALTH: int = 100

@export var velocidad_acecho: float = 55.0
@export var centro_patrulla: Vector2 = Vector2(640, 415)
@export var radio_patrulla: Vector2 = Vector2(125, 58)

var health: int = MAX_HEALTH:
	set(value):
		health = maxi(0, value)
		queue_redraw()

@onready var sprite_animado: AnimatedSprite2D = $AnimatedSprite2D
@onready var jugador: Node2D = get_tree().get_first_node_in_group("player")

var ultima_direccion: String = "down"
var _tiempo: float = 0.0
var _escudo_restante: float = 0.0


func _ready() -> void:
	if sprite_animado and sprite_animado.sprite_frames:
		sprite_animado.play("idle_" + ultima_direccion)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _escudo_restante > 0.0:
		_escudo_restante = maxf(0.0, _escudo_restante - delta)
		queue_redraw()

	if health <= 0:
		velocity = Vector2.ZERO
		_reproducir("idle_" + ultima_direccion)
		return

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


func _draw() -> void:
	var barra_fondo := Rect2(-32, -64, 64, 6)
	draw_rect(Rect2(-33, -65, 66, 8), Color(0.04, 0.04, 0.08, 0.9))
	draw_rect(barra_fondo, Color(0.18, 0.1, 0.16, 0.9))
	var ratio := clampf(float(health) / float(MAX_HEALTH), 0.0, 1.0)
	if ratio > 0.0:
		draw_rect(Rect2(-32, -64, 64.0 * ratio, 6), Color(0.86, 0.25, 0.45))

	if _escudo_restante > 0.0:
		var alpha := clampf(_escudo_restante * 1.4, 0.15, 0.85)
		var medio := 58.0
		draw_rect(Rect2(-medio, -medio, medio * 2.0, medio * 2.0), Color(0.68, 0.35, 1.0, alpha * 0.16))
		draw_rect(Rect2(-medio, -medio, medio * 2.0, medio * 2.0), Color(0.75, 0.45, 1.0, alpha), false, 2.5)


func _reproducir(anim_name: String) -> void:
	if sprite_animado and sprite_animado.sprite_frames and sprite_animado.sprite_frames.has_animation(anim_name):
		if sprite_animado.animation != anim_name:
			sprite_animado.play(anim_name)


## Telegrafía breve antes de ejecutar la decisión de la Máquina de Turing.
func anunciar_ataque(color: Color, etiqueta: String = "") -> void:
	if sprite_animado:
		var tween := create_tween()
		tween.tween_property(sprite_animado, "scale", Vector2(2.48, 2.48), 0.1)
		tween.tween_property(sprite_animado, "scale", Vector2(2.3, 2.3), 0.14)
	modulate = color
	var mod_tween := create_tween()
	mod_tween.tween_property(self, "modulate", Color.WHITE, 0.28)
	if not etiqueta.is_empty():
		ProyectilMagicoScript.crear_texto_flotante(get_parent(), global_position, etiqueta, color)


## Muestra el aura espectral defensiva cuando la Máquina de Turing elige BLOQUEO.
func mostrar_bloqueo_espectral() -> void:
	_escudo_restante = 0.95
	queue_redraw()
	ProyectilMagicoScript.crear_texto_flotante(get_parent(), global_position, "🛡️ BLOQUEO", Color(0.78, 0.55, 1.0))


## Reacción visual al recibir la magia del Cuatro dentro de su hitbox cuadrada.
func recibir_impacto_visual(color: Color, dano: int) -> void:
	if dano > 0:
		var texto := "-%d HP" % dano if health > 0 else "💀 DERROTADO"
		ProyectilMagicoScript.crear_texto_flotante(get_parent(), global_position, texto, color)
	if sprite_animado:
		var dir_retro := Vector2.RIGHT
		if is_instance_valid(jugador):
			var d := global_position - jugador.global_position
			if d.length() > 1.0:
				dir_retro = d.normalized()
		var sacudida := create_tween()
		sacudida.tween_property(sprite_animado, "position", dir_retro * 7.0, 0.06)
		sacudida.tween_property(sprite_animado, "position", Vector2.ZERO, 0.14)

	modulate = color.lightened(0.35)
	var color_final := Color(0.55, 0.55, 0.65, 0.6) if health <= 0 else Color.WHITE
	var mod_tween := create_tween()
	mod_tween.tween_property(self, "modulate", color_final, 0.24)
