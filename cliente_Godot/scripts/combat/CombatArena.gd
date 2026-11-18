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

const CONFIG_ATAQUE_JUGADOR := {
	"Golpe de Gaban": {
		"angulos_deg": [0.0],
		"intervalo": 0.0,
		"velocidad": 620.0,
		"escala": 2.1,
		"hitbox": 22.0,
	},
	"Contrapunteo Libre": {
		"angulos_deg": [0.0, 0.0, 0.0],
		"intervalo": 0.09,
		"velocidad": 640.0,
		"escala": 2.0,
		"hitbox": 22.0,
	},
	"Golpe de Pajarillo": {
		"angulos_deg": [-12.0, 0.0, 12.0],
		"intervalo": 0.0,
		"velocidad": 600.0,
		"escala": 2.5,
		"hitbox": 26.0,
	},
}

const CONFIG_ATAQUE_ENEMIGO := {
	"ATAQUE_RAPIDO": {
		"tipo": "corte",
		"color": Color(1.0, 0.35, 0.32),
		"velocidad": 520.0,
		"escala": 2.2,
		"hitbox": 20.0,
		"angulos_deg": [0.0, 0.0],
		"intervalo": 0.13,
		"retraso": 0.15,
		"cono_duracion": 0.0,
		"cono_apertura": 0.2,
		"etiqueta": "⚡ SILBIDO CORTANTE",
		"sacudida": 0.0,
	},
	"ATAQUE_PESADO": {
		"tipo": "calavera",
		"color": Color(0.95, 0.18, 0.42),
		"velocidad": 420.0,
		"escala": 2.6,
		"hitbox": 26.0,
		"angulos_deg": [-22.0, 0.0, 22.0],
		"intervalo": 0.0,
		"retraso": 0.38,
		"cono_duracion": 0.38,
		"cono_apertura": 0.44,
		"etiqueta": "💀 RÁFAGA PESADA",
		"sacudida": 6.0,
	},
	"CASTIGO": {
		"tipo": "castigo",
		"color": Color(0.84, 0.25, 1.0),
		"velocidad": 580.0,
		"escala": 2.8,
		"hitbox": 28.0,
		"angulos_deg": [-12.0, 0.0, 12.0],
		"intervalo": 0.08,
		"retraso": 0.34,
		"cono_duracion": 0.34,
		"cono_apertura": 0.26,
		"etiqueta": "☠️ CASTIGO",
		"sacudida": 10.0,
	},
}

@onready var camera_2d: Camera2D = $Camera2D
@onready var llanero: CharacterBody2D = $Llanero
@onready var el_silbon: CharacterBody2D = $ElSilbon
@onready var muro_espectral: TileMapLayer = $MuroEspectral
@onready var cuatro_controller: CuatroControllerScript = $CuatroController
@onready var network_client: NetworkClientScript = $NetworkClient
@onready var musica_ambiente: AudioStreamPlayer = $MusicaAmbiente
@onready var label_estado: Label = $UI/LabelEstado
@onready var panel_fin_combate: Control = $UI/PanelFinCombate
@onready var borde_caja_fin: ColorRect = $UI/PanelFinCombate/BordeCaja
@onready var label_titulo_fin: Label = $UI/PanelFinCombate/BordeCaja/FondoCaja/LabelTituloFin
@onready var label_detalle_fin: Label = $UI/PanelFinCombate/BordeCaja/FondoCaja/LabelDetalleFin
@onready var boton_reiniciar: Button = $UI/PanelFinCombate/BordeCaja/FondoCaja/BotonReiniciar

var time_passed: float = 0.0
var _esperando_respuesta_red: bool = false
var _combate_terminado: bool = false


func _ready() -> void:
	if panel_fin_combate:
		panel_fin_combate.visible = false
	if boton_reiniciar:
		boton_reiniciar.pressed.connect(_on_reiniciar_presionado)
	if musica_ambiente and not musica_ambiente.finished.is_connected(musica_ambiente.play):
		musica_ambiente.finished.connect(musica_ambiente.play)
	if cuatro_controller:
		cuatro_controller.acorde_tocado.connect(_on_cuatro_acorde_tocado)
		cuatro_controller.secuencia_enviada.connect(_on_cuatro_secuencia_enviada)
		cuatro_controller.secuencia_limpiada.connect(_on_cuatro_secuencia_limpiada)
		cuatro_controller.input_bloqueado_cambiado.connect(_on_cuatro_bloqueo_cambiado)
	if llanero and not llanero.derrotado.is_connected(_on_llanero_derrotado):
		llanero.derrotado.connect(_on_llanero_derrotado)
	if el_silbon:
		if not el_silbon.ataque_cuerpo_a_cuerpo.is_connected(_on_silbon_ataque_cuerpo_a_cuerpo):
			el_silbon.ataque_cuerpo_a_cuerpo.connect(_on_silbon_ataque_cuerpo_a_cuerpo)
		if not el_silbon.derrotado.is_connected(_on_silbon_derrotado):
			el_silbon.derrotado.connect(_on_silbon_derrotado)
	if network_client:
		network_client.combate_resuelto.connect(_on_combate_resuelto)
		network_client.advertencia.connect(_on_network_advertencia)
		network_client.conexion_establecida.connect(_on_network_conectado)


func _unhandled_input(event: InputEvent) -> void:
	if not _combate_terminado:
		return
	if event is InputEventKey and event.pressed and not event.is_echo():
		var tecla := event as InputEventKey
		var code: int = tecla.physical_keycode if tecla.physical_keycode != 0 else tecla.keycode
		if code == KEY_R or code == KEY_ENTER or code == KEY_KP_ENTER:
			_on_reiniciar_presionado()
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	time_passed += delta

	# Pulso luminoso del muro espectral morado
	if muro_espectral:
		var brillo := 0.88 + 0.12 * sin(time_passed * 4.0)
		muro_espectral.modulate = Color(brillo, 0.82 + 0.14 * sin(time_passed * 3.0), 1.0, 1.0)

	if _combate_terminado:
		return

	# Verificar si el Llanero toca el Muro Espectral en cualquiera de los 4 bordes
	if llanero and not ARENA_RECT.has_point(llanero.global_position):
		var centro := ARENA_RECT.get_center()
		llanero.aplicar_rebote_muro(centro, 5)
		if not _combate_terminado and label_estado:
			label_estado.text = "⚡ ¡El Muro Espectral te quema! (-5 HP) | Vida Llanero: %d" % llanero.health
			label_estado.modulate = Color(1.0, 0.45, 0.85)


func _on_cuatro_acorde_tocado(_token: String, _secuencia_actual: String) -> void:
	if _combate_terminado:
		return
	if label_estado and not cuatro_controller.input_bloqueado:
		label_estado.text = "🎵 Cadena: %s  (Espacio = Frenao | Backspace = Borrar) | Vida Llanero: %d" % [
			cuatro_controller.obtener_cadena_teclas(),
			llanero.health if llanero else 100,
		]
		label_estado.modulate = Color(0.75, 0.95, 1.0)


func _on_cuatro_secuencia_enviada(secuencia: String) -> void:
	if _combate_terminado:
		return
	_esperando_respuesta_red = network_client != null
	if label_estado:
		label_estado.text = "🚀 Enviado: %s [Espacio] (%s) | Esperando turno..." % [
			cuatro_controller.ultima_cadena_teclas_enviada,
			secuencia,
		]
		label_estado.modulate = Color(1.0, 0.9, 0.45)
	if network_client:
		network_client.enviar_secuencia(
			secuencia,
			llanero.health if llanero else -1,
			el_silbon.health if el_silbon else -1
		)


func _on_cuatro_secuencia_limpiada() -> void:
	if _combate_terminado:
		return
	if label_estado:
		label_estado.text = "Cuatro limpio: toca J, K, L, I para acordes y Espacio para Frenao | Vida Llanero: %d" % (
			llanero.health if llanero else 100
		)
		label_estado.modulate = Color.WHITE


func _on_cuatro_bloqueo_cambiado(bloqueado: bool) -> void:
	if _combate_terminado:
		return
	if not bloqueado and not _esperando_respuesta_red and label_estado and cuatro_controller:
		if not label_estado.text.begins_with("⚔️") and not label_estado.text.begins_with("🎸✖") and not label_estado.text.begins_with("⚠️") and not label_estado.text.begins_with("🏆") and not label_estado.text.begins_with("💀") and not label_estado.text.begins_with("💨") and not label_estado.text.begins_with("💥") and not label_estado.text.begins_with("🛡️"):
			label_estado.text = "✅ Listo | Última cadena: %s [Espacio] | Vida Llanero: %d" % [
				cuatro_controller.ultima_cadena_teclas_enviada,
				llanero.health if llanero else 100,
			]
			label_estado.modulate = Color(0.7, 1.0, 0.75)


func _on_silbon_ataque_cuerpo_a_cuerpo(dano: int) -> void:
	_sacudir_camara(4.0)
	if not label_estado or not llanero:
		return
	var vida_ene: int = int(el_silbon.health) if el_silbon else 100
	if llanero.health <= 0:
		label_estado.text = "💀 DERROTA... El Silbón te alcanzó cuerpo a cuerpo | Llanero: 0 HP"
		label_estado.modulate = Color(1.0, 0.4, 0.4)
	else:
		label_estado.text = "💥 ¡El Silbón te golpeó cuerpo a cuerpo! (-%d HP) | Llanero: %d HP | Silbón: %d HP" % [
			dano, llanero.health, vida_ene
		]
		label_estado.modulate = Color(1.0, 0.45, 0.45)


func _on_combate_resuelto(data: Dictionary) -> void:
	_esperando_respuesta_red = false
	if _combate_terminado:
		return
	if cuatro_controller:
		cuatro_controller.desbloquear_input()

	if not data.has("vida_jugador"):
		if label_estado:
			label_estado.text = "❌ %s" % data.get("error", "El servidor rechazó la secuencia.")
			label_estado.modulate = Color(1.0, 0.55, 0.55)
		return

	var vida_jug_actual: int = int(llanero.health) if llanero else int(data.get("vida_jugador", 100))
	var vida_ene_actual: int = int(el_silbon.health) if el_silbon else int(data.get("vida_enemigo", 100))

	_reproducir_accion_jugador(data)
	_reproducir_respuesta_enemigo(data)

	if not label_estado:
		return

	if data.get("valido", false):
		label_estado.text = "⚔️ %s | Silbón: %s | Llanero: %d HP | Silbón: %d HP" % [
			data.get("golpe", "Turno resuelto"),
			data.get("enemigo_accion", "-"),
			vida_jug_actual,
			vida_ene_actual,
		]
		label_estado.modulate = Color(0.7, 1.0, 0.75)
	else:
		if llanero:
			llanero.inmovilizar(1.0)
			llanero.mostrar_desafinacion()
		label_estado.text = "🎸✖ Desafinado | ¡Inmovilizado 1s! (0 daño) | Llanero: %d HP | Silbón: %d HP" % [
			vida_jug_actual,
			vida_ene_actual,
		]
		label_estado.modulate = Color(1.0, 0.45, 0.45)


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

	var dir_base: Vector2 = llanero.obtener_vector_direccion()
	var limites_disparo := ARENA_RECT.grow(50.0)

	if accion == "C":
		ProyectilMagicoScript.crear_texto_flotante(self, llanero.global_position, "🎵 Furia -1", color)
		_lanzar_proyectil({
			"origen": llanero.global_position + Vector2(0, -8),
			"objetivo": el_silbon,
			"direccion": dir_base,
			"color": color,
			"velocidad": 480.0,
			"escala": 1.8,
			"hitbox": 18.0,
			"tipo": "nota",
			"teledirigido": false,
			"limites": limites_disparo,
		}, func(_obj: Node2D, pos: Vector2) -> void:
			ProyectilMagicoScript.generar_chispas(self, pos, color, 10)
		)
		return

	if not el_silbon:
		return

	var cfg: Dictionary = CONFIG_ATAQUE_JUGADOR.get(golpe, CONFIG_ATAQUE_JUGADOR["Golpe de Gaban"])
	_disparar_salva_jugador(golpe, cfg, color, dano_ene, dir_base, limites_disparo)


func _disparar_salva_jugador(golpe: String, cfg: Dictionary, color: Color, dano_ene: int, dir_base: Vector2, limites_disparo: Rect2) -> void:
	var angulos: Array = cfg["angulos_deg"]
	var intervalo := float(cfg["intervalo"])
	var perp := Vector2(-dir_base.y, dir_base.x)
	var estado_salva := {"pendientes": angulos.size(), "resuelta": false}

	for i in range(angulos.size()):
		var idx := i
		var ang_rad := deg_to_rad(float(angulos[idx]))
		var dir_disparo := dir_base.rotated(ang_rad)
		var lateral := (float(idx) - 1.0) * 10.0 if intervalo > 0.0 else 0.0
		var disparo := func() -> void:
			if not is_instance_valid(self) or not is_inside_tree() or not is_instance_valid(llanero) or not is_instance_valid(el_silbon):
				return
			var proj := _lanzar_proyectil({
				"origen": llanero.global_position + Vector2(0, -6) + perp * lateral,
				"objetivo": el_silbon,
				"direccion": dir_disparo,
				"color": color,
				"velocidad": float(cfg["velocidad"]),
				"escala": float(cfg["escala"]) if idx == 0 or angulos.size() != 3 or intervalo > 0.0 else 1.8,
				"hitbox": float(cfg["hitbox"]) if idx == 0 or angulos.size() != 3 or intervalo > 0.0 else 18.0,
				"tipo": "nota",
				"teledirigido": false,
				"limites": limites_disparo,
			}, func(_obj: Node2D, _pos: Vector2) -> void:
				estado_salva["pendientes"] = int(estado_salva["pendientes"]) - 1
				var es_primer_impacto := not bool(estado_salva["resuelta"])
				if es_primer_impacto:
					estado_salva["resuelta"] = true
					el_silbon.health = max(0, int(el_silbon.health) - dano_ene)
				el_silbon.recibir_impacto_visual(color, dano_ene if es_primer_impacto else 0)
				if es_primer_impacto and label_estado and is_instance_valid(llanero):
					if int(el_silbon.health) <= 0:
						label_estado.text = "🏆 ¡VICTORIA! Venciste a El Silbón con %s | Llanero: %d HP" % [golpe, llanero.health]
						label_estado.modulate = Color(1.0, 0.92, 0.45)
					else:
						label_estado.text = "🎯 ¡%s acertó! (-%d HP) | Llanero: %d HP | Silbón: %d HP" % [
							golpe, dano_ene, llanero.health, int(el_silbon.health)
						]
						label_estado.modulate = Color(0.7, 1.0, 0.75)
			)
			proj.expirado.connect(func() -> void:
				estado_salva["pendientes"] = int(estado_salva["pendientes"]) - 1
				if int(estado_salva["pendientes"]) <= 0 and not bool(estado_salva["resuelta"]) and is_instance_valid(llanero):
					estado_salva["resuelta"] = true
					ProyectilMagicoScript.crear_texto_flotante(self, llanero.global_position, "💨 ¡Fallaste!", Color(0.85, 0.85, 0.95))
					if label_estado and int(el_silbon.health) > 0:
						label_estado.text = "💨 ¡Fallaste %s! Apunta hacia El Silbón | Llanero: %d HP | Silbón: %d HP" % [
							golpe, llanero.health, int(el_silbon.health)
						]
						label_estado.modulate = Color(0.95, 0.85, 0.55)
			)
		if idx == 0 or intervalo <= 0.0:
			disparo.call()
		else:
			_programar_evento(intervalo * float(idx), disparo)


func _reproducir_respuesta_enemigo(data: Dictionary) -> void:
	if not el_silbon or not llanero or int(el_silbon.health) <= 0:
		return

	var accion_jugador := str(data.get("accion", ""))
	var enemigo_accion := str(data.get("enemigo_accion", ""))
	var dano_jugador := int(data.get("dano_jugador", 0))
	var fue_parry := (accion_jugador == "D")

	if enemigo_accion == "BLOQUEO":
		el_silbon.mostrar_bloqueo_espectral()
		return

	if enemigo_accion == "CASTIGO" and accion_jugador == "E":
		el_silbon.anunciar_ataque(Color(0.88, 0.35, 1.0), "🔥 FURIA +2")
		return

	if not CONFIG_ATAQUE_ENEMIGO.has(enemigo_accion):
		return

	_disparar_salva_enemiga(CONFIG_ATAQUE_ENEMIGO[enemigo_accion], dano_jugador, fue_parry)


func _disparar_salva_enemiga(cfg: Dictionary, dano_jugador: int, fue_parry: bool) -> void:
	var color_ene: Color = cfg["color"]
	var dir_base := (llanero.global_position - el_silbon.global_position).normalized()
	if dir_base.length() < 0.1:
		dir_base = Vector2.LEFT

	el_silbon.anunciar_ataque(
		color_ene,
		str(cfg["etiqueta"]),
		dir_base,
		float(cfg["cono_duracion"]),
		float(cfg["cono_apertura"])
	)

	var angulos: Array = cfg["angulos_deg"]
	var intervalo := float(cfg["intervalo"])
	var retraso_base := float(cfg["retraso"])
	var sacudida := float(cfg["sacudida"])
	var estado_salva := {"pendientes": angulos.size(), "resuelta": false}
	var limites_disparo := ARENA_RECT.grow(50.0)

	for i in range(angulos.size()):
		var ang_rad := deg_to_rad(float(angulos[i]))
		var dir_disparo := dir_base.rotated(ang_rad)
		var espera := retraso_base + intervalo * float(i)
		_programar_evento(espera, func() -> void:
			if not is_instance_valid(self) or not is_inside_tree() or not is_instance_valid(el_silbon) or not is_instance_valid(llanero):
				return
			if _combate_terminado or int(el_silbon.health) <= 0:
				return
			var proj := _lanzar_proyectil({
				"origen": el_silbon.global_position + Vector2(0, -6),
				"objetivo": llanero,
				"direccion": dir_disparo,
				"color": color_ene,
				"velocidad": float(cfg["velocidad"]),
				"escala": float(cfg["escala"]),
				"hitbox": float(cfg["hitbox"]),
				"tipo": str(cfg["tipo"]),
				"teledirigido": false,
				"limites": limites_disparo,
			}, func(_obj: Node2D, _pos: Vector2) -> void:
				estado_salva["pendientes"] = int(estado_salva["pendientes"]) - 1
				if _combate_terminado or estado_salva["resuelta"]:
					return
				estado_salva["resuelta"] = true
				var dano_aplicado := 0 if fue_parry else dano_jugador
				llanero.recibir_impacto_visual(color_ene, dano_aplicado, fue_parry)
				if not fue_parry and sacudida > 0.0:
					_sacudir_camara(sacudida)
				_actualizar_estado_tras_impacto_enemigo(dano_aplicado, fue_parry)
			)
			proj.expirado.connect(func() -> void:
				estado_salva["pendientes"] = int(estado_salva["pendientes"]) - 1
				if not _combate_terminado and int(estado_salva["pendientes"]) <= 0 and not estado_salva["resuelta"] and is_instance_valid(llanero):
					estado_salva["resuelta"] = true
					llanero.mostrar_esquive()
					if label_estado and not label_estado.text.begins_with("🏆"):
						label_estado.text = "💨 ¡Esquivaste el ataque! | Llanero: %d HP | Silbón: %d HP" % [
							llanero.health,
							int(el_silbon.health) if el_silbon else 100,
						]
						label_estado.modulate = Color(0.65, 0.95, 1.0)
			)
		)


func _programar_evento(espera: float, cb: Callable) -> void:
	if espera <= 0.0:
		cb.call()
		return
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = espera
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(func() -> void:
		timer.queue_free()
		if _combate_terminado:
			return
		cb.call()
	)


func _actualizar_estado_tras_impacto_enemigo(dano_aplicado: int, fue_parry: bool) -> void:
	if not label_estado or not llanero:
		return
	var vida_ene: int = int(el_silbon.health) if el_silbon else 100
	if llanero.health <= 0:
		label_estado.text = "💀 DERROTA... El Silbón te venció | Llanero: 0 HP"
		label_estado.modulate = Color(1.0, 0.4, 0.4)
	elif fue_parry:
		label_estado.text = "🛡️ ¡Ataque bloqueado! | Llanero: %d HP | Silbón: %d HP" % [llanero.health, vida_ene]
		label_estado.modulate = Color(0.55, 0.95, 1.0)
	elif dano_aplicado > 0:
		label_estado.text = "💥 ¡Impacto! (-%d HP) | Llanero: %d HP | Silbón: %d HP" % [dano_aplicado, llanero.health, vida_ene]
		label_estado.modulate = Color(1.0, 0.55, 0.45)


func _sacudir_camara(intensidad: float) -> void:
	if not is_instance_valid(camera_2d):
		return
	var tween := create_tween()
	for _i in range(4):
		var offset_rnd := Vector2(randf_range(-intensidad, intensidad), randf_range(-intensidad, intensidad))
		tween.tween_property(camera_2d, "offset", offset_rnd, 0.04)
	tween.tween_property(camera_2d, "offset", Vector2.ZERO, 0.05)


func _lanzar_proyectil(opts: Dictionary, on_impacto: Callable) -> ProyectilMagicoScript:
	var proyectil := ProyectilMagicoScript.new()
	proyectil.configurar(opts)
	proyectil.z_index = 15
	proyectil.impactado.connect(on_impacto)
	add_child(proyectil)
	return proyectil


func _on_llanero_derrotado() -> void:
	_finalizar_combate(
		false,
		"El espanto llanero acabó contigo.\nPresiona R o el botón para intentarlo otra vez."
	)


func _on_silbon_derrotado() -> void:
	_finalizar_combate(
		true,
		"Venciste a El Silbón al son del cuatro llanero (Llanero: %d HP)." % (llanero.health if llanero else 0)
	)


func _finalizar_combate(victoria: bool, detalle: String) -> void:
	if _combate_terminado:
		return
	_combate_terminado = true
	_esperando_respuesta_red = false
	if cuatro_controller:
		cuatro_controller.finalizar_combate()
	for child in get_children():
		if child is ProyectilMagicoScript:
			child.queue_free()

	if victoria:
		if el_silbon:
			el_silbon.morir()
		if llanero:
			llanero.detener_por_fin_combate()
	else:
		if llanero:
			llanero.morir()
		if el_silbon:
			el_silbon.detener_por_fin_combate()

	if label_estado:
		label_estado.text = "🏆 ¡VICTORIA!" if victoria else "💀 DERROTA"
		label_estado.modulate = Color(1.0, 0.92, 0.45) if victoria else Color(1.0, 0.4, 0.4)

	if panel_fin_combate:
		panel_fin_combate.visible = true
	if borde_caja_fin:
		borde_caja_fin.color = Color(0.95, 0.82, 0.32, 0.96) if victoria else Color(0.92, 0.25, 0.35, 0.96)
	if label_titulo_fin:
		label_titulo_fin.text = "🏆 ¡VICTORIA!" if victoria else "💀 DERROTA"
		label_titulo_fin.modulate = Color(1.0, 0.92, 0.45) if victoria else Color(1.0, 0.42, 0.42)
	if label_detalle_fin:
		label_detalle_fin.text = detalle
	if boton_reiniciar:
		boton_reiniciar.grab_focus()


func _on_reiniciar_presionado() -> void:
	if network_client:
		network_client.reiniciar_servidor_y_recargar()
	get_tree().reload_current_scene()


func _on_network_advertencia(mensaje: String) -> void:
	if _combate_terminado:
		return
	_esperando_respuesta_red = false
	if cuatro_controller:
		cuatro_controller.desbloquear_input()
	if label_estado:
		label_estado.text = "⚠️ %s" % mensaje
		label_estado.modulate = Color(1.0, 0.65, 0.35)


func _on_network_conectado() -> void:
	if _combate_terminado:
		return
	if label_estado:
		label_estado.text = "🔌 Servidor lógico conectado (127.0.0.1:8765)."
		label_estado.modulate = Color(0.7, 1.0, 0.75)
