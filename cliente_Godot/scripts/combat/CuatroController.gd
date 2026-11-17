class_name CuatroController
extends Node

## Controlador Fast-Path de entrada musical y audio inmediato del Cuatro Llanero.
##
## Reproduce cada acorde en local sin esperar al servidor Python y acumula
## los tokens ("T", "S", "D", "M") hasta cerrar el compás con Frenao ("F").

signal acorde_tocado(token: String, secuencia_actual: String)
signal secuencia_enviada(secuencia: String)
signal secuencia_limpiada
signal input_bloqueado_cambiado(bloqueado: bool)

## Tiempo máximo de bloqueo de respaldo mientras el cliente de red (Issue #7) no responde.
@export var timeout_desbloqueo_seg: float = 0.8

const TOKEN_POR_ACCION := {
	"cuatro_tonica": "T",
	"cuatro_subdom": "S",
	"cuatro_dominante": "D",
	"cuatro_menor": "M",
}

const TECLA_POR_TOKEN := {
	"T": "J",
	"S": "K",
	"D": "L",
	"M": "I",
	"F": "Espacio",
}

const STREAM_POR_TOKEN := {
	"T": preload("res://assets/audio/tonica_re.wav"),
	"S": preload("res://assets/audio/subdom_sol.wav"),
	"D": preload("res://assets/audio/dominante_la7.wav"),
	"M": preload("res://assets/audio/menor_sim.wav"),
	"F": preload("res://assets/audio/frenao.wav"),
}

var tokens_actuales: PackedStringArray = PackedStringArray()
var input_bloqueado: bool = false
var ultima_secuencia_enviada: String = ""
var ultima_cadena_teclas_enviada: String = ""

var _reproductores: Dictionary = {}
var _timer_desbloqueo: Timer


func _ready() -> void:
	_inicializar_reproductores()
	_timer_desbloqueo = Timer.new()
	_timer_desbloqueo.one_shot = true
	_timer_desbloqueo.timeout.connect(desbloquear_input)
	add_child(_timer_desbloqueo)


func _inicializar_reproductores() -> void:
	# Un AudioStreamPlayer dedicado por acorde permite rasgueos rápidos sin cortes bruscos.
	for token: String in STREAM_POR_TOKEN.keys():
		var player := AudioStreamPlayer.new()
		player.name = "Audio_%s" % token
		player.stream = STREAM_POR_TOKEN[token]
		add_child(player)
		_reproductores[token] = player


func _unhandled_input(event: InputEvent) -> void:
	if input_bloqueado or event.is_echo():
		return

	for accion: String in TOKEN_POR_ACCION.keys():
		if event.is_action_pressed(accion):
			registrar_acorde(TOKEN_POR_ACCION[accion])
			get_viewport().set_input_as_handled()
			return

	if event.is_action_pressed("cuatro_limpiar"):
		limpiar_secuencia()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("cuatro_frenao"):
		cerrar_y_enviar_secuencia()
		get_viewport().set_input_as_handled()


## Reproduce de inmediato el sonido asociado al token y lo acumula en el buffer local.
func registrar_acorde(token: String) -> void:
	if input_bloqueado or not STREAM_POR_TOKEN.has(token) or token == "F":
		return
	_reproducir_sonido(token)
	tokens_actuales.append(token)
	acorde_tocado.emit(token, obtener_secuencia_actual())


## Cierra la secuencia con "F" (Frenao), bloquea el input y emite la secuencia completa.
func cerrar_y_enviar_secuencia() -> void:
	if input_bloqueado or tokens_actuales.is_empty():
		return
	_reproducir_sonido("F")
	ultima_cadena_teclas_enviada = obtener_cadena_teclas()
	tokens_actuales.append("F")
	var secuencia := obtener_secuencia_actual()
	ultima_secuencia_enviada = secuencia
	tokens_actuales.clear()

	_establecer_bloqueo(true)
	if timeout_desbloqueo_seg > 0.0:
		_timer_desbloqueo.start(timeout_desbloqueo_seg)

	acorde_tocado.emit("F", secuencia)
	secuencia_enviada.emit(secuencia)


## Limpia la secuencia en progreso antes de presionar Frenao.
func limpiar_secuencia() -> void:
	if tokens_actuales.is_empty():
		return
	tokens_actuales.clear()
	secuencia_limpiada.emit()


## Libera el bloqueo de entrada cuando el servidor responde (invocado desde Issue #7).
func desbloquear_input() -> void:
	_timer_desbloqueo.stop()
	_establecer_bloqueo(false)


func obtener_secuencia_actual() -> String:
	return "".join(tokens_actuales)


## Devuelve la cadena legible usando las letras del teclado (J, K, L, I) para el HUD.
func obtener_cadena_teclas() -> String:
	var teclas := PackedStringArray()
	for token: String in tokens_actuales:
		teclas.append(TECLA_POR_TOKEN.get(token, token))
	return " ".join(teclas)


func _reproducir_sonido(token: String) -> void:
	var player: AudioStreamPlayer = _reproductores.get(token)
	if player:
		player.play()


func _establecer_bloqueo(bloqueado: bool) -> void:
	if input_bloqueado == bloqueado:
		return
	input_bloqueado = bloqueado
	input_bloqueado_cambiado.emit(bloqueado)
