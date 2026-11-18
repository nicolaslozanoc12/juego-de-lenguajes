import ctypes
import logging
import sys

from backend.network.server import serve


def _configurar_consola() -> None:
    if sys.platform == "win32":
        try:
            ctypes.windll.kernel32.SetConsoleOutputCP(65001)
        except OSError:
            pass
    for stream in (sys.stdout, sys.stderr):
        if stream is not None and hasattr(stream, "reconfigure"):
            stream.reconfigure(encoding="utf-8", errors="replace")


if __name__ == "__main__":
    _configurar_consola()
    logging.basicConfig(level=logging.INFO, format="%(levelname)s:%(name)s:%(message)s")
    print("=== Servidor El Cuatro Llanero (ANTLR4 + Máquina de Turing) ===", flush=True)
    serve()
