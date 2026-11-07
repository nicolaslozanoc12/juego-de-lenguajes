"""Maquina de Turing multicinta para la decision tactica del enemigo."""

from dataclasses import dataclass
from typing import Dict, List


@dataclass(frozen=True)
class TuringStep:
    cintas: Dict[str, List[str]]
    cabezales: Dict[str, int]
    decision: str


class MultiTapeTuringMachine:
    """Modelo determinista de tres cintas con cabezales L, R y S.

    Cinta 1 conserva las acciones del jugador, cinta 2 conserva furia y
    repeticion, y cinta 3 conserva la decision tactica de cada turno.
    """

    def __init__(self) -> None:
        self.tape1: List[str] = []
        self.tape2: List[str] = ["0", "0"]
        self.tape3: List[str] = []
        self.heads = {"L": 0, "R": 0, "S": 0}
        self._last_action = ""

    @property
    def furia(self) -> int:
        return int(self.tape2[0])

    @property
    def repeticion(self) -> int:
        return int(self.tape2[1])

    def step(self, accion_jugador: str) -> TuringStep:
        if accion_jugador not in {"A", "D", "C", "E"}:
            raise ValueError("accion_jugador debe ser A, D, C o E")

        self.tape1.append(accion_jugador)
        if accion_jugador == self._last_action:
            repeticion = min(self.repeticion + 1, 3)
        else:
            repeticion = 1
        if accion_jugador == "E":
            furia = min(self.furia + 2, 3)
        elif accion_jugador == "A":
            furia = min(self.furia + 1, 3)
        else:
            furia = max(self.furia - 1, 0)

        if accion_jugador == "E":
            decision = "CASTIGO"
        elif repeticion >= 3:
            decision = "CASTIGO"
        elif accion_jugador == "D":
            decision = "BLOQUEO"
        elif furia >= 2:
            decision = "ATAQUE_PESADO"
        else:
            decision = "ATAQUE_RAPIDO"

        self.tape2 = [str(furia), str(repeticion)]
        self.tape3.append(decision)
        self.heads = {
            "L": len(self.tape1) - 1,
            "R": 0,
            "S": len(self.tape3) - 1,
        }
        self._last_action = accion_jugador
        return self.snapshot(decision)

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
