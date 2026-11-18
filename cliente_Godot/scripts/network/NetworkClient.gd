extends Node

signal combate_resuelto(data: Dictionary)
signal advertencia(mensaje: String)
signal conexion_establecida

@export var host: String = "127.0.0.1"
@export var port: int = 8765
const CONNECT_TIMEOUT_SEC := 1.5
const RETRY_INTERVAL_SEC := 2.0
const SERVER_WARNING := "Servidor lógico desconectado. Inicie python -m backend.main"

var _peer: StreamPeerTCP
var _connecting_elapsed: float = 0.0
var _retry_timer: float = 0.0
var _response_buffer: PackedByteArray = PackedByteArray()
var _requests_pending: Array[PackedByteArray] = []
var _is_connected: bool = false
var _warning_shown: bool = false

static var _pid_global_servidor: int = -1
static var _reiniciando_escena: bool = false


func _ready() -> void:
	_reiniciando_escena = false
	if _iniciar_servidor_empaquetado():
		# Espera breve para que backend_server.exe abra el socket antes del primer intento
		_retry_timer = 0.45
	else:
		_intentar_conexion()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_detener_servidor_empaquetado()


func _exit_tree() -> void:
	if _peer != null:
		_peer.disconnect_from_host()
	if not _reiniciando_escena:
		_detener_servidor_empaquetado()


func reiniciar_servidor_y_recargar() -> void:
	_reiniciando_escena = true
	if _peer != null and _peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		_peer.put_data((JSON.stringify({"reiniciar": true}) + "\n").to_utf8_buffer())


func _iniciar_servidor_empaquetado() -> bool:
	if OS.has_feature("editor"):
		return false
	if _pid_global_servidor > 0 and OS.is_process_running(_pid_global_servidor):
		return false
	var base_dir := OS.get_executable_path().get_base_dir()
	for rel_path in ["backend_server/backend_server.exe", "backend_server.exe"]:
		var ruta := base_dir.path_join(rel_path)
		if FileAccess.file_exists(ruta):
			var pid := OS.create_process(ruta, PackedStringArray(), true)
			if pid > 0:
				_pid_global_servidor = pid
				return true
			return false
	return false


func _detener_servidor_empaquetado() -> void:
	if _peer != null:
		_peer.disconnect_from_host()
	if _pid_global_servidor > 0:
		OS.kill(_pid_global_servidor)
		_pid_global_servidor = -1


func _process(delta: float) -> void:
	if _peer == null:
		_reintentar_si_corresponde(delta)
		return

	_peer.poll()
	match _peer.get_status():
		StreamPeerTCP.STATUS_CONNECTED:
			_connecting_elapsed = 0.0
			if not _is_connected:
				_is_connected = true
				_warning_shown = false
				conexion_establecida.emit()
				_enviar_pendientes()
			_leer_respuestas()
		StreamPeerTCP.STATUS_CONNECTING:
			_connecting_elapsed += delta
			if _connecting_elapsed >= CONNECT_TIMEOUT_SEC:
				_peer.disconnect_from_host()
				_marcar_desconectado()
		StreamPeerTCP.STATUS_ERROR, StreamPeerTCP.STATUS_NONE:
			_connecting_elapsed = 0.0
			_marcar_desconectado()
			_reintentar_si_corresponde(delta)


func enviar_secuencia(secuencia: String, vida_jugador: int = -1, vida_enemigo: int = -1) -> void:
	if _peer == null:
		advertencia.emit(SERVER_WARNING)
		return

	_peer.poll()
	var status := _peer.get_status()
	if status != StreamPeerTCP.STATUS_CONNECTED and status != StreamPeerTCP.STATUS_CONNECTING:
		_marcar_desconectado()
		advertencia.emit(SERVER_WARNING)
		return

	var request: Dictionary = {"secuencia": secuencia}
	if vida_jugador >= 0:
		request["vida_jugador"] = vida_jugador
	if vida_enemigo >= 0:
		request["vida_enemigo"] = vida_enemigo
	var line := JSON.stringify(request) + "\n"
	if status == StreamPeerTCP.STATUS_CONNECTING:
		# Conserva solo la última petición si la conexión acaba de iniciar en este frame
		_requests_pending = [line.to_utf8_buffer()]
		return

	_requests_pending.append(line.to_utf8_buffer())
	_enviar_pendientes()


func _intentar_conexion() -> void:
	_peer = StreamPeerTCP.new()
	var error := _peer.connect_to_host(host, port)
	_connecting_elapsed = 0.0
	_retry_timer = RETRY_INTERVAL_SEC
	if error != OK:
		_marcar_desconectado()


func _reintentar_si_corresponde(delta: float) -> void:
	_retry_timer -= delta
	if _retry_timer <= 0.0:
		_intentar_conexion()


func _marcar_desconectado() -> void:
	_is_connected = false
	_requests_pending.clear()
	_response_buffer.clear()
	if not _warning_shown:
		_warning_shown = true
		advertencia.emit(SERVER_WARNING)


func _enviar_pendientes() -> void:
	if _peer == null or _peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		return

	while not _requests_pending.is_empty():
		var error := _peer.put_data(_requests_pending[0])
		if error != OK:
			_marcar_desconectado()
			return
		_requests_pending.pop_front()


func _leer_respuestas() -> void:
	var available_bytes := _peer.get_available_bytes()
	if available_bytes == 0:
		return

	var packet := _peer.get_data(available_bytes)
	if packet[0] != OK:
		_marcar_desconectado()
		return

	_response_buffer.append_array(packet[1])
	while true:
		var newline_index := _response_buffer.find(10)
		if newline_index < 0:
			return

		var line := _response_buffer.slice(0, newline_index).get_string_from_utf8().strip_edges()
		_response_buffer = _response_buffer.slice(newline_index + 1)
		if line.is_empty():
			continue

		var parser := JSON.new()
		var error := parser.parse(line)
		if error != OK:
			advertencia.emit("Respuesta JSON inválida del servidor: %s" % parser.get_error_message())
			continue
		if typeof(parser.data) != TYPE_DICTIONARY:
			advertencia.emit("La respuesta del servidor debe ser un objeto JSON.")
			continue

		var data: Dictionary = parser.data
		if bool(data.get("reiniciado", false)):
			continue
		combate_resuelto.emit(data)
