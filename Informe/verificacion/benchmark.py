"""Reproduce la tabla de latencia del informe.

Uso, desde cualquier directorio:
    python Informe/verificacion/benchmark.py
"""

import json
import socket
import statistics
import sys
import threading
import time
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(RAIZ))

from backend.combat import CombatController  # noqa: E402
from backend.server import GameServer  # noqa: E402


def resumen(muestras):
    muestras.sort()
    return {
        "n": len(muestras),
        "media_ms": round(statistics.mean(muestras), 3),
        "p50_ms": round(muestras[len(muestras) // 2], 3),
        "p95_ms": round(muestras[int(len(muestras) * 0.95)], 3),
        "p99_ms": round(muestras[int(len(muestras) * 0.99)], 3),
        "max_ms": round(muestras[-1], 3),
    }


def en_proceso(n=20000):
    controlador = CombatController()
    secuencias = ["TDDTF", "TDSDTSDTF", "TTDF"]
    muestras = []
    for i in range(n):
        t0 = time.perf_counter_ns()
        controlador.process(secuencias[i % len(secuencias)])
        muestras.append((time.perf_counter_ns() - t0) / 1e6)
    return resumen(muestras)


def por_tcp(n=2000):
    servidor = GameServer("127.0.0.1", 0)
    puerto = servidor.server_address[1]
    hilo = threading.Thread(target=servidor.serve_forever, daemon=True)
    hilo.start()
    muestras = []
    try:
        with socket.create_connection(("127.0.0.1", puerto), timeout=5) as sock:
            lector = sock.makefile("rb")
            for i in range(n):
                secuencia = "TDSDTSDTF" if i % 2 else "TDDTF"
                peticion = (json.dumps({"secuencia": secuencia}) + "\n").encode()
                t0 = time.perf_counter_ns()
                sock.sendall(peticion)
                if not lector.readline():
                    raise RuntimeError("El servidor no respondio")
                muestras.append((time.perf_counter_ns() - t0) / 1e6)
    finally:
        servidor.shutdown()
        servidor.server_close()
        hilo.join(timeout=5)
    return resumen(muestras)


if __name__ == "__main__":
    print(json.dumps({"en_proceso": en_proceso(), "tcp_local": por_tcp()}, indent=2))
