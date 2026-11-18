extends Node2D

const CuatroControllerScript := preload("res://scripts/combat/CuatroController.gd")

## Área interior segura delimitada por el muro espectral cerrado (arriba, abajo, izq, der).
const ARENA_RECT := Rect2(96, 250, 1088, 392)

@onready var llanero: CharacterBody2D = $Llanero
@onready var muro_espectral: TileMapLayer = $MuroEspectral
@onready var cuatro_controller: CuatroControllerScript = $CuatroController
@onready var musica_ambiente: AudioStreamPlayer = $MusicaAmbiente
@onready var label_estado: Label = $UI/LabelEstado

var time_passed: float = 0.0


func _ready() -> void:
	if musica_ambiente and not musica_ambiente.finished.is_connected(musica_ambiente.play):
		musica_ambiente.finished.connect(musica_ambiente.play)
	if cuatro_controller:
		cuatro_controller.acorde_tocado.connect(_on_cuatro_acorde_tocado)
		cuatro_controller.secuencia_enviada.connect(_on_cuatro_secuencia_enviada)
		cuatro_controller.secuencia_limpiada.connect(_on_cuatro_secuencia_limpiada)
		cuatro_controller.input_bloqueado_cambiado.connect(_on_cuatro_bloqueo_cambiado)


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
	if not bloqueado and label_estado:
		label_estado.text = "✅ Listo | Última cadena: %s [Espacio] | Vida Llanero: %d" % [
			cuatro_controller.ultima_cadena_teclas_enviada,
			llanero.health if llanero else 100,
		]
		label_estado.modulate = Color(0.7, 1.0, 0.75)
