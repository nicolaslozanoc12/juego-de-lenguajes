# Revisión de arquitectura del backend

## Resultado

La implementación respeta la arquitectura documentada de dos capas:

| Capa | Responsabilidad | Implementación |
|---|---|---|
| Conectividad | Aceptar TCP, separar mensajes JSON y devolver respuestas | `backend/server.py`, `backend/protocol.py` |
| Lógica formal y juego | Validar la gramática, actualizar cintas y resolver combate | `backend/parser.py`, `backend/turing.py`, `backend/combat.py` |

El servidor no lee ni ejecuta los archivos JFLAP. La gramática ejecutable está
representada por `CuatroLlanero.g4` y su validador Python conserva las mismas
reglas para que el backend sea autónomo.

## GRASP

- **Controller:** `_RequestHandler` recibe la petición y delega; no calcula
  daño ni interpreta la gramática.
- **Information Expert:** `MultiTapeTuringMachine` conoce sus cintas y
  cabezales; `CombatController` conoce la resolución de daño y vidas.
- **Low Coupling:** el protocolo solo depende de la interfaz `process` del
  controlador y no de detalles de sockets.
- **High Cohesion:** parser, máquina, combate y serialización tienen módulos
  separados.
- **Pure Fabrication:** `protocol.py` concentra validación/serialización JSON,
  evitando contaminar las reglas del dominio.

## SOLID

- **SRP:** cada módulo tiene un motivo de cambio único: red, protocolo,
  validación formal, IA o combate.
- **OCP:** los golpes se pueden ampliar en `parser.py` y las decisiones en la
  máquina sin modificar el transporte.
- **LSP:** las respuestas de error y de combate mantienen JSON con campos
  predecibles y versión explícita para el cliente.
- **ISP:** el cliente solo necesita el contrato JSON; no conoce clases internas
  ni estados de Python.
- **DIP:** la capa de red depende de las funciones de protocolo y del método
  `process`, no de la implementación de parser o de la máquina.

## Contrato de integración

Los esquemas consumibles por Godot están en [`contracts/`](../../contracts/).
La versión actual es `1.0`; todo mensaje viaja como JSON UTF-8 terminado en
salto de línea.
