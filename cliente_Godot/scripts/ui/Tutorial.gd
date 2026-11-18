extends Node2D

const SCENE_MENU := "res://scenes/ui/MainMenu.tscn"
const SCENE_COMBATE := "res://scenes/combat/CombatArena.tscn"

const STREAM_POR_TOKEN := {
	"T": preload("res://assets/audio/tonica_re.wav"),
	"S": preload("res://assets/audio/subdom_sol.wav"),
	"D": preload("res://assets/audio/dominante_la7.wav"),
	"M": preload("res://assets/audio/menor_sim.wav"),
	"F": preload("res://assets/audio/frenao.wav"),
	"ERR": preload("res://assets/audio/sfx/desafinacion.wav"),
}

const TECLA_POR_TOKEN := {
	"T": "J",
	"S": "K",
	"D": "L",
	"M": "I",
}

const TOKEN_POR_TECLA := {
	KEY_J: "T",
	KEY_K: "S",
	KEY_L: "D",
	KEY_I: "M",
}

const GOLPES_EXACTOS := {
	"TDDTF": "✅ ¡Golpe de Gabán! (15 daño · Ataque rápido)",
	"MSDMF": "✅ ¡Golpe de Pajarillo! (30 daño · Abanico triple)",
	"TSDTF": "🛡️ ¡Seis por Derecho! (Parry · Anula daño de proyectiles)",
	"SDSDF": "🌀 ¡Zumbe y Zumbe! (Esquive · Postura defensiva)",
	"TMSTF": "🎵 ¡Tonada de Sabana! (Calma · Baja la Furia -1)",
}

@onready var musica_tutorial: AudioStreamPlayer = $MusicaTutorial
@onready var tab_1: Button = $UI/PanelBorde/PanelFondo/Tab1
@onready var tab_2: Button = $UI/PanelBorde/PanelFondo/Tab2
@onready var tab_3: Button = $UI/PanelBorde/PanelFondo/Tab3
@onready var paginas: Array[Control] = [
	$UI/PanelBorde/PanelFondo/Contenido/Pagina1,
	$UI/PanelBorde/PanelFondo/Contenido/Pagina2,
	$UI/PanelBorde/PanelFondo/Contenido/Pagina3,
]
@onready var llanero_demo: AnimatedSprite2D = $UI/PanelBorde/PanelFondo/Contenido/Pagina1/SpriteLlaneroDemo
@onready var silbon_demo: AnimatedSprite2D = $UI/PanelBorde/PanelFondo/Contenido/Pagina3/SpriteSilbonDemo
@onready var label_practica: Label = $UI/PanelBorde/PanelFondo/Contenido/Pagina1/CajaPractica/LabelPractica
@onready var label_pagina: Label = $UI/PanelBorde/PanelFondo/LabelPagina
@onready var boton_menu: Button = $UI/PanelBorde/PanelFondo/BotonMenu
@onready var boton_anterior: Button = $UI/PanelBorde/PanelFondo/BotonAnterior
@onready var boton_siguiente: Button = $UI/PanelBorde/PanelFondo/BotonSiguiente
@onready var boton_jugar: Button = $UI/PanelBorde/PanelFondo/BotonJugar

var pagina_actual: int = 0
var _tokens_practica: PackedStringArray = PackedStringArray()
var _reproductores: Dictionary = {}
var _regex_contrapunteo := RegEx.new()


func _ready() -> void:
	_regex_contrapunteo.compile("^TD(SDT)+F$")
	_inicializar_reproductores()
	if musica_tutorial and not musica_tutorial.finished.is_connected(musica_tutorial.play):
		musica_tutorial.finished.connect(musica_tutorial.play)
	if llanero_demo:
		llanero_demo.play("walk_right")
	if silbon_demo:
		silbon_demo.play("idle_left")

	UiEstiloHelper.estilizar_boton(boton_menu, Color(0.18, 0.14, 0.25), Color(0.65, 0.50, 0.85))
	UiEstiloHelper.estilizar_boton(boton_anterior, Color(0.14, 0.16, 0.26), Color(0.55, 0.65, 0.90))
	UiEstiloHelper.estilizar_boton(boton_siguiente, Color(0.14, 0.16, 0.26), Color(0.55, 0.65, 0.90))
	UiEstiloHelper.estilizar_boton(boton_jugar, Color(0.18, 0.28, 0.16), Color(0.95, 0.82, 0.34))

	tab_1.pressed.connect(func() -> void: mostrar_pagina(0))
	tab_2.pressed.connect(func() -> void: mostrar_pagina(1))
	tab_3.pressed.connect(func() -> void: mostrar_pagina(2))
	boton_menu.pressed.connect(_on_menu_presionado)
	boton_anterior.pressed.connect(func() -> void: mostrar_pagina(pagina_actual - 1))
	boton_siguiente.pressed.connect(func() -> void: mostrar_pagina(pagina_actual + 1))
	boton_jugar.pressed.connect(_on_jugar_presionado)

	mostrar_pagina(0)
	if boton_siguiente:
		boton_siguiente.grab_focus()


func _inicializar_reproductores() -> void:
	for clave: String in STREAM_POR_TOKEN.keys():
		var player := AudioStreamPlayer.new()
		player.name = "Practica_%s" % clave
		player.stream = STREAM_POR_TOKEN[clave]
		add_child(player)
		_reproductores[clave] = player


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.is_echo()):
		return
	var tecla := event as InputEventKey
	var code: int = tecla.physical_keycode if tecla.physical_keycode != 0 else tecla.keycode
	if code == KEY_ESCAPE:
		_on_menu_presionado()
		get_viewport().set_input_as_handled()
		return

	if pagina_actual != 0:
		return

	if TOKEN_POR_TECLA.has(code):
		_tocar_acorde_practica(TOKEN_POR_TECLA[code])
		get_viewport().set_input_as_handled()
	elif code == KEY_BACKSPACE and not _tokens_practica.is_empty():
		_tokens_practica.clear()
		if label_practica:
			label_practica.text = "Secuencia limpia. Prueba J L L J + Espacio (Golpe de Gabán)."
			label_practica.modulate = Color(0.84, 0.92, 1.0)
		get_viewport().set_input_as_handled()
	elif code == KEY_SPACE and not _tokens_practica.is_empty():
		_evaluar_practica()
		get_viewport().set_input_as_handled()


func _tocar_acorde_practica(token: String) -> void:
	_reproducir(token)
	_tokens_practica.append(token)
	var teclas := PackedStringArray()
	for tk: String in _tokens_practica:
		teclas.append(TECLA_POR_TOKEN.get(tk, tk))
	if label_practica:
		label_practica.text = "🎵 Cadena: %s   (Espacio = Frenao | Backspace = Borrar)" % " ".join(teclas)
		label_practica.modulate = Color(0.75, 0.95, 1.0)


func _evaluar_practica() -> void:
	_reproducir("F")
	var seq := "".join(_tokens_practica) + "F"
	_tokens_practica.clear()
	if not label_practica:
		return
	if GOLPES_EXACTOS.has(seq):
		label_practica.text = GOLPES_EXACTOS[seq]
		label_practica.modulate = Color(0.55, 1.0, 0.72)
	elif _regex_contrapunteo.search(seq) != null:
		label_practica.text = "✅ ¡Contrapunteo Libre! (25 daño · Ráfaga de 3 notas)"
		label_practica.modulate = Color(0.82, 0.65, 1.0)
	else:
		_reproducir("ERR")
		label_practica.text = "🎸✖ Desafinado (%s). En combate inmoviliza 1s. Revisa la página 2." % seq
		label_practica.modulate = Color(1.0, 0.55, 0.50)


func _reproducir(clave: String) -> void:
	var p: AudioStreamPlayer = _reproductores.get(clave)
	if p:
		p.play()


func mostrar_pagina(indice: int) -> void:
	pagina_actual = clampi(indice, 0, paginas.size() - 1)
	for i in range(paginas.size()):
		paginas[i].visible = (i == pagina_actual)

	var tabs: Array[Button] = [tab_1, tab_2, tab_3]
	for i in range(tabs.size()):
		var activo := (i == pagina_actual)
		UiEstiloHelper.estilizar_boton(
			tabs[i],
			Color(0.24, 0.18, 0.38) if activo else Color(0.11, 0.11, 0.20),
			Color(1.0, 0.86, 0.36) if activo else Color(0.42, 0.38, 0.62)
		)

	if label_pagina:
		label_pagina.text = "Página %d / %d" % [pagina_actual + 1, paginas.size()]
	if boton_anterior:
		boton_anterior.disabled = (pagina_actual == 0)
	if boton_siguiente:
		boton_siguiente.disabled = (pagina_actual == paginas.size() - 1)
	if pagina_actual == paginas.size() - 1 and boton_jugar:
		boton_jugar.grab_focus()


func _on_menu_presionado() -> void:
	get_tree().change_scene_to_file(SCENE_MENU)


func _on_jugar_presionado() -> void:
	get_tree().change_scene_to_file(SCENE_COMBATE)
