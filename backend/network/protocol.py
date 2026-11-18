"""Procesamiento y serialización de mensajes JSON del servidor."""

import json
from typing import Any, Dict

from backend.game.combat import CombatController


def process_request(payload: str, controller: CombatController) -> Dict[str, Any]:
    try:
        request = json.loads(payload)
    except json.JSONDecodeError as exc:
        raise ValueError("JSON inválido") from exc
    if not isinstance(request, dict):
        raise ValueError("La petición debe ser un objeto JSON")
    if request.get("reiniciar") is True:
        controller.reset()
        return {
            "valido": True,
            "reiniciado": True,
            "vida_jugador": controller.state.vida_jugador,
            "vida_enemigo": controller.state.vida_enemigo,
            "estado": "JUGANDO",
        }
    if "secuencia" not in request or not isinstance(request["secuencia"], str):
        raise ValueError("La petición requiere el campo secuencia como texto")
    vida_jugador = request.get("vida_jugador")
    if isinstance(vida_jugador, (int, float)) and not isinstance(vida_jugador, bool):
        controller.state.vida_jugador = max(0, min(100, int(vida_jugador)))
    vida_enemigo = request.get("vida_enemigo")
    if isinstance(vida_enemigo, (int, float)) and not isinstance(vida_enemigo, bool):
        controller.state.vida_enemigo = max(0, min(100, int(vida_enemigo)))
    response = controller.process(request["secuencia"])
    return response


def error_response(message: str) -> Dict[str, Any]:
    return {
        "valido": False,
        "error": message,
    }


def encode_response(response: Dict[str, Any]) -> bytes:
    return (json.dumps(response, ensure_ascii=False, separators=(",", ":")) + "\n").encode("utf-8")
