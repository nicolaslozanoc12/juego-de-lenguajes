extends CharacterBody2D

## Controla persecución con pausas, ataque cuerpo a cuerpo en 8 direcciones y muerte de El Silbón.

signal ataque_cuerpo_a_cuerpo(dano: int)
signal derrotado

const DireccionHelper := preload("res://scripts/combat/DireccionHelper.gd")
const ProyectilMagicoScript := preload("res://scripts/combat/ProyectilMagico.gd")

const MAX_HEALTH: int = 100

@export var velocidad_persecucion: float = 105.0
@export var rango_cuerpo_a_cuerpo: float = 104.0
@export var dano_cuerpo_a_cuerpo: int = 8
@export var duracion_persecucion: float = 2.4
@export var duracion_descanso: float = 1.1
@export var cooldown_cuerpo_a_cuerpo: float = 1.2

var health: int = MAX_HEALTH:
	set(value):
		var prev := health
		health = maxi(0, value)
		queue_redraw()
		if prev > 0 and health == 0 and not _muerto:
			morir()
			derrotado.emit()

@onready var sprite_animado: AnimatedSprite2D = $AnimatedSprite2D
@onready var jugador: Node2D = get_tree().get_first_node_in_group("player")

var ultima_direccion: String = "left"
var combate_terminado: bool = false
var _muerto: bool = false
var _tiempo: float = 0.0
var _escudo_restante: float = 0.0
var _telegrafia_restante: float = 0.0
var _telegrafia_dir: Vector2 = Vector2.RIGHT
var _telegrafia_apertura: float = 0.35
var _telegrafia_largo: float = 340.0
var _telegrafia_color: Color = Color(1.0, 0.2, 0.35)
var _cd_melee_restante: float = 0.0
var _ataque_anim_restante: float = 0.0


func _ready() -> void:
	if sprite_animado and sprite_animado.sprite_frames:
		sprite_animado.play("idle_" + ultima_direccion)
	queue_redraw()


func _physics_process(delta: float) -> void:
	var necesita_redibujo := false
	if _escudo_restante > 0.0:
		_escudo_restante = maxf(0.0, _escudo_restante - delta)
		necesita_redibujo = true
	if _telegrafia_restante > 0.0:
		_telegrafia_restante = maxf(0.0, _telegrafia_restante - delta)
		necesita_redibujo = true
	if necesita_redibujo:
		queue_redraw()

	if _cd_melee_restante > 0.0:
		_cd_melee_restante = maxf(0.0, _cd_melee_restante - delta)

	if _muerto or combate_terminado or health <= 0:
		velocity = Vector2.ZERO
		if _muerto:
			_reproducir("dead")
		else:
			_reproducir("idle_" + ultima_direccion)
		return

	if _ataque_anim_restante > 0.0:
		_ataque_anim_restante = maxf(0.0, _ataque_anim_restante - delta)
		velocity = Vector2.ZERO
		_reproducir("attack_" + ultima_direccion)
		return

	if not jugador:
		jugador = get_tree().get_first_node_in_group("player")

	_tiempo += delta
	if _telegrafia_restante > 0.0:
		velocity = Vector2.ZERO
		if is_instance_valid(jugador):
			var hacia := jugador.global_position - global_position
			if hacia.length() > 4.0:
				ultima_direccion = DireccionHelper.vector_a_nombre(hacia.normalized())
		_reproducir("idle_" + ultima_direccion)
		return

	if is_instance_valid(jugador) and int(jugador.health) > 0:
		var hacia_jugador := jugador.global_position - global_position
		var dist := hacia_jugador.length()
		var dir := hacia_jugador.normalized() if dist > 1.0 else Vector2.LEFT

		if dist <= rango_cuerpo_a_cuerpo and _cd_melee_restante <= 0.0:
			_ejecutar_ataque_cuerpo_a_cuerpo(dir)
			return

		var duracion_ciclo := duracion_persecucion + duracion_descanso
		var en_persecucion := fmod(_tiempo, duracion_ciclo) < duracion_persecucion
		if dist > 4.0:
			ultima_direccion = DireccionHelper.vector_a_nombre(dir)

		if en_persecucion and dist > rango_cuerpo_a_cuerpo - 12.0:
			velocity = dir * velocidad_persecucion
			move_and_slide()
			_reproducir("walk_" + ultima_direccion)
			return

	velocity = Vector2.ZERO
	_reproducir("idle_" + ultima_direccion)


func morir() -> void:
	_muerto = true
	combate_terminado = true
	velocity = Vector2.ZERO
	_telegrafia_restante = 0.0
	_escudo_restante = 0.0
	_ataque_anim_restante = 0.0
	modulate = Color.WHITE
	if sprite_animado:
		sprite_animado.position = Vector2.ZERO
		sprite_animado.scale = Vector2(2.3, 2.3)
		_reproducir("dead")
	ProyectilMagicoScript.generar_chispas(get_parent(), global_position, Color(0.75, 0.45, 1.0), 22)
	queue_redraw()


func detener_por_fin_combate() -> void:
	combate_terminado = true
	velocity = Vector2.ZERO
	_telegrafia_restante = 0.0
	_escudo_restante = 0.0
	_ataque_anim_restante = 0.0
	modulate = Color.WHITE
	if not _muerto:
		_reproducir("idle_" + ultima_direccion)
	queue_redraw()


func _ejecutar_ataque_cuerpo_a_cuerpo(dir: Vector2) -> void:
	ultima_direccion = DireccionHelper.vector_a_nombre(dir)
	_ataque_anim_restante = 0.36
	_cd_melee_restante = cooldown_cuerpo_a_cuerpo
	velocity = Vector2.ZERO
	if sprite_animado:
		sprite_animado.frame = 0
		sprite_animado.play("attack_" + ultima_direccion)
	if is_instance_valid(jugador) and jugador.has_method("recibir_golpe_cuerpo_a_cuerpo"):
		jugador.recibir_golpe_cuerpo_a_cuerpo(global_position, dano_cuerpo_a_cuerpo)
	ataque_cuerpo_a_cuerpo.emit(dano_cuerpo_a_cuerpo)


func _draw() -> void:
	if _telegrafia_restante > 0.0 and not _muerto and not combate_terminado:
		var pulso := 0.22 + 0.14 * sin(_telegrafia_restante * 28.0)
		var ang_base := _telegrafia_dir.angle()
		var p1 := Vector2.from_angle(ang_base - _telegrafia_apertura) * _telegrafia_largo
		var p2 := Vector2.from_angle(ang_base + _telegrafia_apertura) * _telegrafia_largo
		var col_fill := Color(_telegrafia_color.r, _telegrafia_color.g, _telegrafia_color.b, pulso)
		var col_edge := Color(_telegrafia_color.r, _telegrafia_color.g, _telegrafia_color.b, 0.75)
		draw_colored_polygon(PackedVector2Array([Vector2.ZERO, p1, p2]), col_fill)
		draw_line(Vector2.ZERO, p1, col_edge, 2.0)
		draw_line(Vector2.ZERO, p2, col_edge, 2.0)

	var barra_fondo := Rect2(-32, -64, 64, 6)
	draw_rect(Rect2(-33, -65, 66, 8), Color(0.04, 0.04, 0.08, 0.9))
	draw_rect(barra_fondo, Color(0.18, 0.1, 0.16, 0.9))
	var ratio := clampf(float(health) / float(MAX_HEALTH), 0.0, 1.0)
	if ratio > 0.0:
		draw_rect(Rect2(-32, -64, 64.0 * ratio, 6), Color(0.86, 0.25, 0.45))

	if _escudo_restante > 0.0 and not _muerto:
		var alpha := clampf(_escudo_restante * 1.4, 0.15, 0.9)
		var onda := 1.0 + 0.08 * sin(_escudo_restante * 22.0)
		var m_ext := 58.0 * onda
		var m_int := 46.0 * (2.0 - onda)
		draw_rect(Rect2(-m_ext, -m_ext, m_ext * 2.0, m_ext * 2.0), Color(0.55, 0.25, 0.9, alpha * 0.2))
		draw_rect(Rect2(-m_ext, -m_ext, m_ext * 2.0, m_ext * 2.0), Color(0.78, 0.48, 1.0, alpha), false, 3.0)
		draw_rect(Rect2(-m_int, -m_int, m_int * 2.0, m_int * 2.0), Color(0.45, 0.9, 1.0, alpha * 0.7), false, 2.0)


func _reproducir(anim_name: String) -> void:
	if sprite_animado and sprite_animado.sprite_frames and sprite_animado.sprite_frames.has_animation(anim_name):
		if sprite_animado.animation != anim_name:
			sprite_animado.play(anim_name)


## Telegrafía visual (cono de peligro en el suelo y destello) antes de disparar.
func anunciar_ataque(color: Color, etiqueta: String = "", dir_objetivo: Vector2 = Vector2.ZERO, duracion_cono: float = 0.0, apertura: float = 0.35) -> void:
	if _muerto or combate_terminado:
		return
	if sprite_animado:
		var tween := create_tween()
		tween.tween_property(sprite_animado, "scale", Vector2(2.5, 2.5), 0.1)
		tween.tween_property(sprite_animado, "scale", Vector2(2.3, 2.3), 0.14)
	modulate = color
	var mod_tween := create_tween()
	mod_tween.tween_property(self, "modulate", Color.WHITE, 0.3)

	if duracion_cono > 0.0 and dir_objetivo.length() > 1.0:
		_telegrafia_dir = dir_objetivo.normalized()
		_telegrafia_apertura = apertura
		_telegrafia_color = color
		_telegrafia_restante = duracion_cono
		queue_redraw()

	if not etiqueta.is_empty():
		ProyectilMagicoScript.crear_texto_flotante(get_parent(), global_position, etiqueta, color)


## Muestra el manto de niebla espectral cuando la Máquina de Turing elige BLOQUEO.
func mostrar_bloqueo_espectral() -> void:
	if _muerto or combate_terminado:
		return
	_escudo_restante = 1.05
	queue_redraw()
	ProyectilMagicoScript.generar_chispas(get_parent(), global_position, Color(0.72, 0.42, 1.0), 16)
	ProyectilMagicoScript.crear_texto_flotante(get_parent(), global_position, "🛡️ BLOQUEO", Color(0.78, 0.55, 1.0))


## Reacción visual al recibir la magia del Cuatro dentro de su hitbox cuadrada.
func recibir_impacto_visual(color: Color, dano: int) -> void:
	if _escudo_restante > 0.0:
		ProyectilMagicoScript.generar_chispas(get_parent(), global_position, Color(0.72, 0.42, 1.0), 10)
	if dano > 0:
		var texto := "-%d HP" % dano if health > 0 else "💀 DERROTADO"
		ProyectilMagicoScript.crear_texto_flotante(get_parent(), global_position, texto, color)
	if _muerto:
		return
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
	var mod_tween := create_tween()
	mod_tween.tween_property(self, "modulate", Color.WHITE, 0.24)
