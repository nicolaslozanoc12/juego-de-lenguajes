class_name SfxController
extends Node

## Gestor central de efectos de sonido de combate (impactos, voces, silbidos y fanfarrias).

const RETRASO_RISA_TRAS_DANO := 0.28

const CONFIG_SFX := {
	"llanero_dano": {
		"stream": preload("res://assets/audio/sfx/llanero_dano.wav"),
		"volume_db": 1.0,
		"cooldown": 0.22,
		"jitter": 0.06,
		"voces": 2,
	},
	"silbon_risa": {
		"stream": preload("res://assets/audio/sfx/silbon_risa.wav"),
		"volume_db": -0.5,
		"cooldown": 2.2,
		"jitter": 0.04,
		"voces": 1,
	},
	"silbon_silbido": {
		"stream": preload("res://assets/audio/sfx/silbon_silbido.wav"),
		"volume_db": -1.5,
		"cooldown": 0.45,
		"jitter": 0.04,
		"voces": 1,
	},
	"silbon_melee": {
		"stream": preload("res://assets/audio/sfx/silbon_melee.wav"),
		"volume_db": -1.0,
		"cooldown": 0.2,
		"jitter": 0.06,
		"voces": 2,
	},
	"silbon_furia": {
		"stream": preload("res://assets/audio/sfx/silbon_furia.wav"),
		"volume_db": -1.0,
		"cooldown": 0.45,
		"jitter": 0.03,
		"voces": 1,
	},
	"silbon_bloqueo": {
		"stream": preload("res://assets/audio/sfx/silbon_bloqueo.wav"),
		"volume_db": -2.0,
		"cooldown": 0.3,
		"jitter": 0.0,
		"voces": 1,
	},
	"silbon_impacto": {
		"stream": preload("res://assets/audio/sfx/silbon_impacto.wav"),
		"volume_db": 0.0,
		"cooldown": 0.07,
		"jitter": 0.06,
		"voces": 3,
	},
	"llanero_disparo": {
		"stream": preload("res://assets/audio/sfx/llanero_disparo.wav"),
		"volume_db": -2.5,
		"cooldown": 0.08,
		"jitter": 0.04,
		"voces": 2,
	},
	"llanero_parry": {
		"stream": preload("res://assets/audio/sfx/llanero_parry.wav"),
		"volume_db": -1.5,
		"cooldown": 0.12,
		"jitter": 0.0,
		"voces": 2,
	},
	"llanero_esquive": {
		"stream": preload("res://assets/audio/sfx/llanero_esquive.wav"),
		"volume_db": -3.0,
		"cooldown": 0.18,
		"jitter": 0.05,
		"voces": 2,
	},
	"llanero_calma": {
		"stream": preload("res://assets/audio/sfx/llanero_calma.wav"),
		"volume_db": -1.5,
		"cooldown": 0.35,
		"jitter": 0.0,
		"voces": 1,
	},
	"desafinacion": {
		"stream": preload("res://assets/audio/sfx/desafinacion.wav"),
		"volume_db": -1.0,
		"cooldown": 0.3,
		"jitter": 0.0,
		"voces": 1,
	},
	"muro_choque": {
		"stream": preload("res://assets/audio/sfx/muro_choque.wav"),
		"volume_db": -1.5,
		"cooldown": 0.35,
		"jitter": 0.05,
		"voces": 1,
	},
	"disparo_fallo": {
		"stream": preload("res://assets/audio/sfx/disparo_fallo.wav"),
		"volume_db": -6.5,
		"cooldown": 0.15,
		"jitter": 0.05,
		"voces": 1,
	},
	"victoria": {
		"stream": preload("res://assets/audio/sfx/victoria.wav"),
		"volume_db": 0.5,
		"cooldown": 0.5,
		"jitter": 0.0,
		"voces": 1,
	},
	"derrota": {
		"stream": preload("res://assets/audio/sfx/derrota.wav"),
		"volume_db": 0.5,
		"cooldown": 0.5,
		"jitter": 0.0,
		"voces": 1,
	},
}

var _pools: Dictionary = {}
var _indices: Dictionary = {}
var _ultimo_uso_ms: Dictionary = {}
var _timer_risa: Timer
var _combate_terminado: bool = false


func _ready() -> void:
	_inicializar_reproductores()
	_timer_risa = Timer.new()
	_timer_risa.one_shot = true
	_timer_risa.wait_time = RETRASO_RISA_TRAS_DANO
	_timer_risa.timeout.connect(_on_timer_risa_timeout)
	add_child(_timer_risa)


func _inicializar_reproductores() -> void:
	for clave: String in CONFIG_SFX.keys():
		var cfg: Dictionary = CONFIG_SFX[clave]
		var cantidad: int = int(cfg.get("voces", 1))
		var lista: Array[AudioStreamPlayer] = []
		for i in range(cantidad):
			var player := AudioStreamPlayer.new()
			player.name = "Sfx_%s_%d" % [clave, i]
			player.stream = cfg["stream"]
			player.volume_db = float(cfg.get("volume_db", 0.0))
			add_child(player)
			lista.append(player)
		_pools[clave] = lista
		_indices[clave] = 0
		_ultimo_uso_ms[clave] = -100000


func reproducir(clave: String) -> bool:
	if not CONFIG_SFX.has(clave):
		return false
	var cfg: Dictionary = CONFIG_SFX[clave]
	var ahora_ms := Time.get_ticks_msec()
	var cooldown_ms := int(float(cfg.get("cooldown", 0.0)) * 1000.0)
	var previo_ms := int(_ultimo_uso_ms.get(clave, -100000))
	if ahora_ms - previo_ms < cooldown_ms:
		return false

	var pool: Array = _pools.get(clave, [])
	if pool.is_empty():
		return false

	var idx: int = int(_indices.get(clave, 0)) % pool.size()
	_indices[clave] = (idx + 1) % pool.size()
	var player: AudioStreamPlayer = pool[idx]
	var jitter := float(cfg.get("jitter", 0.0))
	player.pitch_scale = randf_range(1.0 - jitter, 1.0 + jitter) if jitter > 0.0 else 1.0
	player.play()
	_ultimo_uso_ms[clave] = ahora_ms
	return true


## Reproduce el gemido/impacto del Llanero y programa la risa burlona de El Silbón.
func reproducir_dano_jugador(es_golpe_mortal: bool = false, silbon_vivo: bool = true) -> void:
	var sono := reproducir("llanero_dano")
	if not sono or _combate_terminado or es_golpe_mortal or not silbon_vivo:
		return
	if _timer_risa and _timer_risa.is_stopped():
		_timer_risa.start(RETRASO_RISA_TRAS_DANO)


func detener_pendientes() -> void:
	_combate_terminado = true
	if _timer_risa and not _timer_risa.is_stopped():
		_timer_risa.stop()


func _on_timer_risa_timeout() -> void:
	if not _combate_terminado:
		reproducir("silbon_risa")
