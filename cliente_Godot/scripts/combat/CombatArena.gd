extends Node2D

const CuatroControllerScript := preload("res://scripts/combat/CuatroController.gd")
const NetworkClientScript := preload("res://scripts/network/NetworkClient.gd")

## Área interior segura delimitada por el muro espectral cerrado (arriba, abajo, izq, der).
const ARENA_RECT := Rect2(96, 250, 1088, 392)

@onready var llanero: CharacterBody2D = $Llanero
@onready var muro_espectral: TileMapLayer = $MuroEspectral
@onready var cuatro_controller: CuatroControllerScript = $CuatroController
@onready var network_client: NetworkClientScript = $NetworkClient
@onready var musica_ambiente: AudioStreamPlayer = $MusicaAmbiente
@onready var label_estado: Label = $UI/LabelEstado

var time_passed: float = 0.0
var _esperando_respuesta_red: bool = false


func _ready() -> void:
	if musica_ambiente and not musica_ambiente.finished.is_connected(musica_ambiente.play):
		musica_ambiente.finished.connect(musica_ambiente.play)
	if cuatro_controller:
		cuatro_controller.acorde_tocado.connect(_on_cuatro_acorde_tocado)
		cuatro_controller.secuencia_enviada.connect(_on_cuatro_secuencia_enviada)
		cuatro_controller.secuencia_limpiada.connect(_on_cuatro_secuencia_limpiada)
		cuatro_controller.input_bloqueado_cambiado.connect(_on_cuatro_bloqueo_cambiado)
	if network_client:
		if cuatro_controller:
			cuatro_controller.secuencia_enviada.connect(network_client.enviar_secuencia)
		network_client.combate_resuelto.connect(_on_combate_resuelto)
		network_client.advertencia.connect(_on_network_advertencia)
		network_client.conexion_establecida.connect(_on_network_conectado)


func _process(delta: float) -> void:
	time_passed += delta

	# Pulso luminoso del muro espectral morado
	if muro_espectral:
		var brillo := 0.88 + 0.12 * sin(time_passed * 4.0)
		muro_espectral.modulate = Color(brillo, 0.82 + 0.14 * sin(time_passed * 3.0), 1.0, 1.0)

	# Verificar si el Llanero toca el Muro Espectral en cualquiera de los 4 bordes
	if llanero and not ARENA_RECT.has_point(llanero.global_position):
		var centro := ARENA_RECT.get_center()
		llanero.aplicar_rebote_muro(centro, 5)
		if label_estado:
			label_estado.text = "⚡ ¡El Muro Espectral te quema! (-5 HP) | Vida Llanero: %d" % llanero.health
			label_estado.modulate = Color(1.0, 0.45, 0.85)


func _on_cuatro_acorde_tocado(_token: String, _secuencia_actual: String) -> void:
	if label_estado and not cuatro_controller.input_bloqueado:
		label_estado.text = "🎵 Cadena: %s  (Espacio = Frenao | Backspace = Borrar) | Vida Llanero: %d" % [
			cuatro_controller.obtener_cadena_teclas(),
			llanero.health if llanero else 100,
		]
		label_estado.modulate = Color(0.75, 0.95, 1.0)


func _on_cuatro_secuencia_enviada(secuencia: String) -> void:
	_esperando_respuesta_red = network_client != null
	if label_estado:
		label_estado.text = "🚀 Enviado: %s [Espacio] (%s) | Esperando turno..." % [
			cuatro_controller.ultima_cadena_teclas_enviada,
			secuencia,
		]
		label_estado.modulate = Color(1.0, 0.9, 0.45)


func _on_cuatro_secuencia_limpiada() -> void:
	if label_estado:
		label_estado.text = "Cuatro limpio: toca J, K, L, I para acordes y Espacio para Frenao | Vida Llanero: %d" % (
			llanero.health if llanero else 100
		)
		label_estado.modulate = Color.WHITE


func _on_cuatro_bloqueo_cambiado(bloqueado: bool) -> void:
	if not bloqueado and not _esperando_respuesta_red and label_estado and cuatro_controller:
		if not label_estado.text.begins_with("⚔️") and not label_estado.text.begins_with("🎸✖") and not label_estado.text.begins_with("⚠️") and not label_estado.text.begins_with("🏆") and not label_estado.text.begins_with("💀"):
			label_estado.text = "✅ Listo | Última cadena: %s [Espacio] | Vida Llanero: %d" % [
				cuatro_controller.ultima_cadena_teclas_enviada,
				llanero.health if llanero else 100,
			]
			label_estado.modulate = Color(0.7, 1.0, 0.75)


func _on_combate_resuelto(data: Dictionary) -> void:
	_esperando_respuesta_red = false
	if llanero and data.has("vida_jugador"):
		llanero.health = int(data["vida_jugador"])
	if cuatro_controller:
		cuatro_controller.desbloquear_input()
	if not label_estado:
		return

	var estado_partida := str(data.get("estado", "JUGANDO"))
	var vida_jug := int(data.get("vida_jugador", llanero.health if llanero else 100))
	var vida_ene := int(data.get("vida_enemigo", 100))
	if data.get("valido", false):
		if estado_partida == "VICTORIA":
			label_estado.text = "🏆 ¡VICTORIA! Venciste a El Silbón con %s | Llanero: %d HP" % [
				data.get("golpe", "tu música"),
				vida_jug,
			]
			label_estado.modulate = Color(1.0, 0.92, 0.45)
		elif estado_partida == "DERROTA":
			label_estado.text = "💀 DERROTA... El Silbón te venció (%s) | Llanero: 0 HP" % data.get("enemigo_accion", "")
			label_estado.modulate = Color(1.0, 0.4, 0.4)
		else:
			label_estado.text = "⚔️ %s | Silbón: %s | Llanero: %d HP | Silbón: %d HP" % [
				data.get("golpe", "Turno resuelto"),
				data.get("enemigo_accion", "-"),
				vida_jug,
				vida_ene,
			]
			label_estado.modulate = Color(0.7, 1.0, 0.75)
	elif data.has("vida_jugador"):
		if llanero:
			llanero.inmovilizar(1.0)
		if estado_partida == "DERROTA":
			label_estado.text = "💀 DERROTA... (%s) | Llanero: 0 HP" % data.get("enemigo_accion", "")
		else:
			label_estado.text = "🎸✖ Desafinado | ¡Inmovilizado 1s! (0 daño) | Llanero: %d HP | Silbón: %d HP" % [
				vida_jug,
				vida_ene,
			]
		label_estado.modulate = Color(1.0, 0.45, 0.45)
	else:
		label_estado.text = "❌ %s" % data.get("error", "El servidor rechazó la secuencia.")
		label_estado.modulate = Color(1.0, 0.55, 0.55)


func _on_network_advertencia(mensaje: String) -> void:
	_esperando_respuesta_red = false
	if cuatro_controller:
		cuatro_controller.desbloquear_input()
	if label_estado:
		label_estado.text = "⚠️ %s" % mensaje
		label_estado.modulate = Color(1.0, 0.65, 0.35)


func _on_network_conectado() -> void:
	if label_estado:
		label_estado.text = "🔌 Servidor lógico conectado (127.0.0.1:8765)."
		label_estado.modulate = Color(0.7, 1.0, 0.75)
