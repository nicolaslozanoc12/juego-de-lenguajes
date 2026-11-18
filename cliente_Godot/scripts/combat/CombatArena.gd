extends Node2D

const CuatroControllerScript := preload("res://scripts/combat/CuatroController.gd")
const NetworkClientScript := preload("res://scripts/network/NetworkClient.gd")
const ProyectilMagicoScript := preload("res://scripts/combat/ProyectilMagico.gd")

## Área interior segura delimitada por el muro espectral cerrado (arriba, abajo, izq, der).
const ARENA_RECT := Rect2(96, 250, 1088, 392)

const COLOR_POR_ACCION_JUGADOR := {
	"Golpe de Gaban": Color(1.0, 0.85, 0.25),
	"Contrapunteo Libre": Color(0.75, 0.45, 1.0),
	"Golpe de Pajarillo": Color(0.25, 0.95, 0.62),
	"Seis por Derecho": Color(0.35, 0.92, 1.0),
	"Zumbe y Zumbe": Color(0.75, 0.55, 1.0),
	"Tonada de Sabana": Color(0.35, 0.95, 0.78),
}

const CONFIG_ATAQUE_ENEMIGO := {
	"ATAQUE_RAPIDO": {
		"color": Color(1.0, 0.32, 0.32),
		"velocidad": 480.0,
		"escala": 2.1,
		"hitbox": 20.0,
		"etiqueta": "⚡ ATAQUE RÁPIDO",
		"retraso": 0.16,
	},
	"ATAQUE_PESADO": {
		"color": Color(0.95, 0.16, 0.42),
		"velocidad": 430.0,
		"escala": 2.8,
		"hitbox": 28.0,
		"etiqueta": "💥 ATAQUE PESADO",
		"retraso": 0.24,
	},
	"CASTIGO": {
		"color": Color(0.82, 0.25, 1.0),
		"velocidad": 560.0,
		"escala": 3.0,
		"hitbox": 30.0,
		"etiqueta": "☠️ CASTIGO",
		"retraso": 0.2,
	},
}

@onready var llanero: CharacterBody2D = $Llanero
@onready var el_silbon: CharacterBody2D = $ElSilbon
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
	if el_silbon and data.has("vida_enemigo"):
		el_silbon.health = int(data["vida_enemigo"])
	if cuatro_controller:
		cuatro_controller.desbloquear_input()

	if data.has("vida_jugador"):
		_reproducir_accion_jugador(data)
		_reproducir_respuesta_enemigo(data)

	if not label_estado:
		return

	var estado_partida := str(data.get("estado", "JUGANDO"))
	var vida_jug := int(data.get("vida_jugador", llanero.health if llanero else 100))
	var vida_ene := int(data.get("vida_enemigo", el_silbon.health if el_silbon else 100))
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
			llanero.mostrar_desafinacion()
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


func _reproducir_accion_jugador(data: Dictionary) -> void:
	if not llanero or not data.get("valido", false):
		return

	var golpe := str(data.get("golpe", ""))
	var accion := str(data.get("accion", ""))
	var dano_ene := int(data.get("dano_enemigo", 0))
	var color: Color = COLOR_POR_ACCION_JUGADOR.get(golpe, Color(1.0, 0.9, 0.4))
	llanero.mostrar_destello_cuatro(color)

	if accion == "D":
		var etiqueta := "🌀 ESQUIVE" if golpe == "Zumbe y Zumbe" else "🛡️ PARRY"
		llanero.mostrar_escudo_armonico(color, 0.95, etiqueta)
		return

	if not el_silbon:
		return

	if accion == "C":
		_lanzar_proyectil({
			"origen": llanero.global_position + Vector2(0, -8),
			"objetivo": el_silbon,
			"color": color,
			"velocidad": 480.0,
			"escala": 1.9,
			"hitbox": 20.0,
			"tipo": "nota",
		}, func(_obj: Node2D, pos: Vector2) -> void:
			ProyectilMagicoScript.crear_texto_flotante(self, pos, "🎵 Furia -1", color)
		)
		return

	if golpe == "Contrapunteo Libre":
		for i in range(3):
			var indice := i
			var disparo := func() -> void:
				if not is_instance_valid(self) or not is_inside_tree() or not is_instance_valid(llanero) or not is_instance_valid(el_silbon):
					return
				_lanzar_proyectil({
					"origen": llanero.global_position + Vector2(0, -10 + (indice - 1) * 12),
					"objetivo": el_silbon,
					"color": color,
					"velocidad": 640.0,
					"escala": 2.0,
					"hitbox": 22.0,
					"tipo": "nota",
				}, func(_obj: Node2D, _pos: Vector2) -> void:
					el_silbon.recibir_impacto_visual(color, dano_ene if indice == 0 else 0)
				)
			if i == 0:
				disparo.call()
			else:
				get_tree().create_timer(0.09 * float(i)).timeout.connect(disparo)
		return

	if golpe == "Golpe de Pajarillo":
		for offset_y in [0.0, -18.0, 18.0]:
			var es_principal := is_zero_approx(offset_y)
			_lanzar_proyectil({
				"origen": llanero.global_position + Vector2(0, -6 + offset_y),
				"objetivo": el_silbon,
				"color": color,
				"velocidad": 600.0 if es_principal else 570.0,
				"escala": 2.7 if es_principal else 1.8,
				"hitbox": 28.0 if es_principal else 18.0,
				"tipo": "nota",
			}, func(_obj: Node2D, _pos: Vector2) -> void:
				el_silbon.recibir_impacto_visual(color, dano_ene if es_principal else 0)
			)
		return

	# Golpe de Gabán (u otros ataques simples)
	_lanzar_proyectil({
		"origen": llanero.global_position + Vector2(0, -6),
		"objetivo": el_silbon,
		"color": color,
		"velocidad": 620.0,
		"escala": 2.1,
		"hitbox": 22.0,
		"tipo": "nota",
	}, func(_obj: Node2D, _pos: Vector2) -> void:
		el_silbon.recibir_impacto_visual(color, dano_ene)
	)


func _reproducir_respuesta_enemigo(data: Dictionary) -> void:
	if not el_silbon or not llanero:
		return

	var estado_partida := str(data.get("estado", "JUGANDO"))
	if estado_partida == "VICTORIA":
		return

	var accion_jugador := str(data.get("accion", ""))
	var enemigo_accion := str(data.get("enemigo_accion", ""))
	var dano_jugador := int(data.get("dano_jugador", 0))
	var fue_parry := (accion_jugador == "D")

	if enemigo_accion == "BLOQUEO":
		el_silbon.mostrar_bloqueo_espectral()
		return

	# El error gramatical ("E") no dispara daño directo: solo sube furia e inmoviliza al jugador.
	if enemigo_accion == "CASTIGO" and accion_jugador == "E":
		el_silbon.anunciar_ataque(Color(0.88, 0.35, 1.0), "🔥 Furia +2")
		return

	if not CONFIG_ATAQUE_ENEMIGO.has(enemigo_accion):
		return

	var cfg: Dictionary = CONFIG_ATAQUE_ENEMIGO[enemigo_accion]
	var color_ene: Color = cfg["color"]
	el_silbon.anunciar_ataque(color_ene, str(cfg["etiqueta"]))

	var retraso := float(cfg["retraso"])
	get_tree().create_timer(retraso).timeout.connect(func() -> void:
		if not is_instance_valid(self) or not is_inside_tree() or not is_instance_valid(el_silbon) or not is_instance_valid(llanero):
			return
		_lanzar_proyectil({
			"origen": el_silbon.global_position + Vector2(0, -6),
			"objetivo": llanero,
			"color": color_ene,
			"velocidad": float(cfg["velocidad"]),
			"escala": float(cfg["escala"]),
			"hitbox": float(cfg["hitbox"]),
			"tipo": "espanto",
			"teledirigido": false,
		}, func(_obj: Node2D, _pos: Vector2) -> void:
			llanero.recibir_impacto_visual(color_ene, dano_jugador, fue_parry)
		)
	)


func _lanzar_proyectil(opts: Dictionary, on_impacto: Callable) -> ProyectilMagicoScript:
	var proyectil := ProyectilMagicoScript.new()
	proyectil.configurar(opts)
	proyectil.z_index = 15
	proyectil.impactado.connect(on_impacto)
	add_child(proyectil)
	return proyectil


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
