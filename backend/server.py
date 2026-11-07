"""Servidores TCP y HTTP locales para el cliente Godot."""

import json
import logging
import socketserver
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from threading import Thread

from .combat import CombatController
from .protocol import encode_response, error_response, process_request

LOGGER = logging.getLogger(__name__)


class _RequestHandler(socketserver.StreamRequestHandler):
    def handle(self) -> None:
        controller: CombatController = self.server.controller  # type: ignore[attr-defined]
        try:
            for raw_line in self.rfile:
                try:
                    response = process_request(raw_line.decode("utf-8").strip(), controller)
                except (UnicodeDecodeError, ValueError) as exc:
                    LOGGER.warning("Peticion rechazada: %s", exc)
                    response = error_response(str(exc))
                self.wfile.write(encode_response(response))
                self.wfile.flush()
        except ConnectionResetError:
            LOGGER.info("Cliente desconectado antes de terminar la peticion")


class GameServer(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True

    def __init__(
        self,
        host: str = "127.0.0.1",
        port: int = 8765,
        controller: CombatController | None = None,
    ) -> None:
        self.controller = controller or CombatController()
        super().__init__((host, port), _RequestHandler)


class _HttpRequestHandler(BaseHTTPRequestHandler):
    server_version = "JuegoLenguajes/1.0"

    def _send_json(self, status: int, payload: dict) -> None:
        body = json.dumps(payload, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:
        if self.path == "/health":
            self._send_json(200, {"estado": "ok", "contrato_version": "1.0"})
            return
        self._send_json(404, error_response("Ruta no encontrada"))

    def do_POST(self) -> None:
        if self.path == "/reset":
            self.server.controller.reset()  # type: ignore[attr-defined]
            self._send_json(200, {"estado": "reiniciado", "contrato_version": "1.0"})
            return
        if self.path != "/turn":
            self._send_json(404, error_response("Ruta no encontrada"))
            return
        try:
            length = int(self.headers.get("Content-Length", "0"))
            payload = self.rfile.read(length).decode("utf-8")
            response = process_request(payload, self.server.controller)  # type: ignore[attr-defined]
            self._send_json(200, response)
        except (UnicodeDecodeError, ValueError) as exc:
            LOGGER.warning("Peticion HTTP rechazada: %s", exc)
            self._send_json(400, error_response(str(exc)))

    def log_message(self, format: str, *args: object) -> None:
        LOGGER.info("HTTP %s", format % args)


class GameHttpServer(ThreadingHTTPServer):
    daemon_threads = True

    def __init__(
        self,
        host: str = "127.0.0.1",
        port: int = 8766,
        controller: CombatController | None = None,
    ) -> None:
        self.controller = controller or CombatController()
        super().__init__((host, port), _HttpRequestHandler)


def serve(host: str = "0.0.0.0", port: int = 8765, http_port: int = 8766) -> None:
    controller = CombatController()
    tcp_server = GameServer(host, port, controller)
    http_server = GameHttpServer(host, http_port, controller)
    http_thread = Thread(target=http_server.serve_forever, daemon=True)
    http_thread.start()
    LOGGER.info("Servidor TCP escuchando en %s:%s", host, port)
    LOGGER.info("Servidor HTTP escuchando en %s:%s", host, http_port)
    try:
        tcp_server.serve_forever()
    finally:
        tcp_server.server_close()
        http_server.shutdown()
        http_server.server_close()


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    serve()
