extends Node

signal combate_resuelto(data: Dictionary)
signal advertencia(mensaje: String)
signal conexion_establecida

const HOST := "127.0.0.1"
const PORT := 8765
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


func _ready() -> void:
	_intentar_conexion()


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


func enviar_secuencia(secuencia: String) -> void:
	if _peer == null:
		advertencia.emit(SERVER_WARNING)
		return

	_peer.poll()
	var status := _peer.get_status()
	if status != StreamPeerTCP.STATUS_CONNECTED and status != StreamPeerTCP.STATUS_CONNECTING:
		_marcar_desconectado()
		advertencia.emit(SERVER_WARNING)
		return

	var request := {"secuencia": secuencia}
	var line := JSON.stringify(request) + "\n"
	if status == StreamPeerTCP.STATUS_CONNECTING:
		# Conserva solo la última petición si la conexión acaba de iniciar en este frame
		_requests_pending = [line.to_utf8_buffer()]
		return

	_requests_pending.append(line.to_utf8_buffer())
	_enviar_pendientes()


func _intentar_conexion() -> void:
	_peer = StreamPeerTCP.new()
	var error := _peer.connect_to_host(HOST, PORT)
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
		combate_resuelto.emit(data)
