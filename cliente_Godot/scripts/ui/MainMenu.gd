extends Node2D

const SCENE_TUTORIAL := "res://scenes/ui/Tutorial.tscn"
const SCENE_COMBATE := "res://scenes/combat/CombatArena.tscn"

@onready var sprite_llanero: AnimatedSprite2D = $SpriteLlanero
@onready var sprite_silbon: AnimatedSprite2D = $SpriteSilbon
@onready var musica_menu: AudioStreamPlayer = $MusicaMenu
@onready var sfx_foco: AudioStreamPlayer = $SfxFoco
@onready var boton_tutorial: Button = $UI/TarjetaBorde/TarjetaFondo/BotonTutorial
@onready var boton_jugar: Button = $UI/TarjetaBorde/TarjetaFondo/BotonJugar
@onready var boton_salir: Button = $UI/TarjetaBorde/TarjetaFondo/BotonSalir

var _permitir_sfx_foco: bool = false


func _ready() -> void:
	if sprite_llanero:
		sprite_llanero.play("idle_right")
	if sprite_silbon:
		sprite_silbon.play("idle_left")
	if musica_menu and not musica_menu.finished.is_connected(musica_menu.play):
		musica_menu.finished.connect(musica_menu.play)

	UiEstiloHelper.estilizar_boton(boton_tutorial, Color(0.18, 0.25, 0.16), Color(0.95, 0.80, 0.34))
	UiEstiloHelper.estilizar_boton(boton_jugar, Color(0.19, 0.14, 0.30), Color(0.72, 0.50, 0.96))
	UiEstiloHelper.estilizar_boton(boton_salir, Color(0.22, 0.11, 0.15), Color(0.72, 0.35, 0.42))

	if boton_tutorial:
		boton_tutorial.pressed.connect(_on_tutorial_presionado)
		boton_tutorial.focus_entered.connect(_reproducir_sfx_foco)
		boton_tutorial.grab_focus()
	if boton_jugar:
		boton_jugar.pressed.connect(_on_jugar_presionado)
		boton_jugar.focus_entered.connect(_reproducir_sfx_foco)
	if boton_salir:
		boton_salir.pressed.connect(_on_salir_presionado)
		boton_salir.focus_entered.connect(_reproducir_sfx_foco)

	_permitir_sfx_foco = true


func _reproducir_sfx_foco() -> void:
	if _permitir_sfx_foco and sfx_foco:
		sfx_foco.pitch_scale = randf_range(0.98, 1.03)
		sfx_foco.play()


func _on_tutorial_presionado() -> void:
	get_tree().change_scene_to_file(SCENE_TUTORIAL)


func _on_jugar_presionado() -> void:
	get_tree().change_scene_to_file(SCENE_COMBATE)


func _on_salir_presionado() -> void:
	get_tree().quit()
