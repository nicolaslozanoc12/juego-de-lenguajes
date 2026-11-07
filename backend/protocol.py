"""Procesamiento de mensajes JSON del servidor."""

import json
from typing import Any, Dict

from .combat import CombatController

CONTRACT_VERSION = "1.0"


def process_request(payload: str, controller: CombatController) -> Dict[str, Any]:
    try:
        request = json.loads(payload)
    except json.JSONDecodeError as exc:
        raise ValueError("JSON invalido") from exc
    if not isinstance(request, dict):
        raise ValueError("La peticion debe ser un objeto JSON")
    if "secuencia" not in request or not isinstance(request["secuencia"], str):
        raise ValueError("La peticion requiere el campo secuencia como texto")
    response = controller.process(request["secuencia"])
    return {"contrato_version": CONTRACT_VERSION, **response}


def error_response(message: str) -> Dict[str, Any]:
    return {
        "contrato_version": CONTRACT_VERSION,
        "valido": False,
        "error": message,
    }


def encode_response(response: Dict[str, Any]) -> bytes:
    return (json.dumps(response, ensure_ascii=False, separators=(",", ":")) + "\n").encode("utf-8")
