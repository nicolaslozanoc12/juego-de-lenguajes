"""Máquina de Turing multicinta determinista para la decisión táctica del enemigo."""

from dataclasses import dataclass
import logging
from typing import Dict, List, Tuple

LOGGER = logging.getLogger(__name__)

_FURIA_DELTA: Dict[str, int] = {
    "A": 1,
    "D": -1,
    "C": -1,
    "E": 2,
}

_DECISION_POR_ESTADO: Dict[str, str] = {
    "qAtaqueRapido": "ATAQUE_RAPIDO",
    "qAtaquePesado": "ATAQUE_PESADO",
    "qBloqueo": "BLOQUEO",
    "qCastigo": "CASTIGO",
}


@dataclass(frozen=True)
class TuringStep:
    """Snapshot de las tres cintas, cabezales y decisión táctica tras un paso."""

    cintas: Dict[str, List[str]]
    cabezales: Dict[str, int]
    decision: str


def _format_tape(tape: List[str], head: int) -> str:
    """Formatea una cinta resaltando entre corchetes la celda bajo el cabezal."""
    if not tape:
        return "[_]"
    return " ".join(f"[{cell}]" if idx == head else cell for idx, cell in enumerate(tape))


def _transicion_delta(
    accion: str,
    prev_accion: str,
    furia_actual: int,
    rep_actual: int,
) -> Tuple[str, int, int, str]:
    """Función de transición determinista δ: retorna (estado, furia, repetición, decisión)."""
    repeticion = min(rep_actual + 1, 3) if accion == prev_accion else 1
    furia = max(0, min(furia_actual + _FURIA_DELTA[accion], 3))

    if accion == "E" or repeticion >= 3:
        siguiente_estado = "qCastigo"
    elif accion == "D":
        siguiente_estado = "qBloqueo"
    elif furia >= 2:
        siguiente_estado = "qAtaquePesado"
    else:
        siguiente_estado = "qAtaqueRapido"

    return siguiente_estado, furia, repeticion, _DECISION_POR_ESTADO[siguiente_estado]


class MultiTapeTuringMachine:
    """Autómata determinista de tres cintas con estados explícitos y cabezales L, R y S.

    - Cinta 1 (cabezal ``L``): historial de acciones validadas del jugador (A, D, C, E).
    - Cinta 2 (cabezal ``R``): memoria interna ``[furia, repeticion]`` entre ``0`` y ``3``.
    - Cinta 3 (cabezal ``S``): historial de decisiones tácticas del enemigo.
    """

    def __init__(self) -> None:
        self.estado: str = "qObservacion"
        self.tape1: List[str] = []
        self.tape2: List[str] = ["0", "0"]
        self.tape3: List[str] = []
        self.heads: Dict[str, int] = {"L": 0, "R": 0, "S": 0}
        self.ultima_transicion: str = ""

    @property
    def furia(self) -> int:
        return int(self.tape2[0])

    @property
    def repeticion(self) -> int:
        return int(self.tape2[1])

    def step(self, accion_jugador: str) -> TuringStep:
        """Lee las cintas actuales, aplica δ y avanza los cabezales para un turno."""
        if accion_jugador not in _FURIA_DELTA:
            raise ValueError("accion_jugador debe ser A, D, C o E")

        prev_accion = self.tape1[self.heads["L"]] if self.tape1 else ""
        furia_actual = int(self.tape2[self.heads["R"]])
        rep_actual = int(self.tape2[1])

        estado_previo = self.estado
        nuevo_estado, furia, repeticion, decision = _transicion_delta(
            accion_jugador,
            prev_accion,
            furia_actual,
            rep_actual,
        )

        mov1 = "R" if self.tape1 else "S"
        mov3 = "R" if self.tape3 else "S"
        self.tape1.append(accion_jugador)
        self.tape2 = [str(furia), str(repeticion)]
        self.tape3.append(decision)
        self.heads = {
            "L": len(self.tape1) - 1,
            "R": 0,
            "S": len(self.tape3) - 1,
        }
        self.estado = nuevo_estado
        self.ultima_transicion = (
            f"δ({estado_previo}, ({prev_accion or '_'}, {furia_actual}|{rep_actual}, _), "
            f"in='{accion_jugador}') -> ({nuevo_estado}, ({accion_jugador}, "
            f"{furia}|{repeticion}, {decision}), mov=({mov1}, R->L, {mov3}))"
        )
        LOGGER.info("\n%s", self.format_trace())
        return self.snapshot(decision)

    def format_trace(self) -> str:
        """Genera una vista legible de δ, los cabezales y las tres cintas."""
        lineas = [
            "=== Máquina de Turing Multicinta ===",
            f"Estado actual: {self.estado}",
        ]
        if self.ultima_transicion:
            lineas.append(f"Transición   : {self.ultima_transicion}")
        lineas.extend([
            f"Cinta 1 [cab L={self.heads['L']}]: {_format_tape(self.tape1, self.heads['L'])}",
            f"Cinta 2 [cab R={self.heads['R']}]: {_format_tape(self.tape2, self.heads['R'])}",
            f"Cinta 3 [cab S={self.heads['S']}]: {_format_tape(self.tape3, self.heads['S'])}",
            "====================================",
        ])
        return "\n".join(lineas)

    def snapshot(self, decision: str = "") -> TuringStep:
        return TuringStep(
            cintas={
                "cinta1": list(self.tape1),
                "cinta2": list(self.tape2),
                "cinta3": list(self.tape3),
            },
            cabezales=dict(self.heads),
            decision=decision or (self.tape3[-1] if self.tape3 else ""),
        )
