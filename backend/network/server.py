"""Servidor TCP local para el cliente Godot."""

import logging
import socketserver

from backend.game.combat import CombatController
from .protocol import encode_response, error_response, process_request

LOGGER = logging.getLogger(__name__)


class _RequestHandler(socketserver.StreamRequestHandler):
    def handle(self) -> None:
        controller: CombatController = self.server.controller  # type: ignore[attr-defined]
        try:
            for raw_line in self.rfile:
                line = raw_line.decode("utf-8").strip()
                if not line:
                    continue
                try:
                    response = process_request(line, controller)
                except (UnicodeDecodeError, ValueError) as exc:
                    LOGGER.warning("Petición rechazada: %s", exc)
                    response = error_response(str(exc))
                self.wfile.write(encode_response(response))
                self.wfile.flush()
        except ConnectionResetError:
            LOGGER.info("Cliente desconectado")


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


def serve(host: str = "127.0.0.1", port: int = 8765) -> None:
    server = GameServer(host, port)
    LOGGER.info("Servidor TCP escuchando en %s:%s", host, port)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        LOGGER.info("Servidor detenido por el usuario")
    finally:
        server.server_close()


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    serve()
