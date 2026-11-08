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
    if "secuencia" not in request or not isinstance(request["secuencia"], str):
        raise ValueError("La petición requiere el campo secuencia como texto")
    response = controller.process(request["secuencia"])
    return response


def error_response(message: str) -> Dict[str, Any]:
    return {
        "valido": False,
        "error": message,
    }


def encode_response(response: Dict[str, Any]) -> bytes:
    return (json.dumps(response, ensure_ascii=False, separators=(",", ":")) + "\n").encode("utf-8")
