# juego-de-lenguajes

Videojuego 2D en **Godot 4.7.2** conectado por sockets TCP locales a un servidor lógico en **Python 3** con **ANTLR4** (Gramática Libre de Contexto del Cuatro Llanero) y una **Máquina de Turing Multicinta** determinista para la IA de *El Silbón*.

## Arquitectura del proyecto

```text
├── backend/                     # Servidor lógico en Python (TCP + ANTLR4 + Turing)
│   ├── formal/grammar/          # CuatroLlanero.g4 y parser generado con ANTLR4
│   ├── formal/turing/           # MultiTapeTuringMachine (3 cintas) y modelo JFLAP
│   ├── game/                    # CombatController: cálculo de daño, parry y estado
│   ├── network/                 # Servidor TCP (127.0.0.1:8765) y protocolo JSON
│   ├── tests/                   # 20 pruebas unitarias y de integración TCP
│   └── main.py                  # Punto de entrada del servidor
├── cliente_Godot/               # Cliente visual 2D Top-Down en Godot 4.7.2
│   ├── scenes/combat/           # CombatArena.tscn (escena principal de combate)
│   └── scripts/                 # CuatroController, NetworkClient, Llanero, ElSilbon
└── Documentacion/               # Documentación técnica y prototipos JFLAP
```

## Requisitos y ejecución local

1. **Instalar dependencia de Python** (desde la raíz del repositorio):
   ```powershell
   python -m pip install -r backend/formal/grammar/requirements.txt
   ```
   *(En Windows, si el comando `python` apunta a otro intérprete como Inkscape en el `PATH`, usa `py` en su lugar: `py -m pip ...`.)*

2. **Ejecutar pruebas unitarias del backend:**
   ```powershell
   py -m unittest discover -s backend/tests -v
   ```

3. **Iniciar el servidor lógico TCP (`127.0.0.1:8765`):**
   ```powershell
   py -m backend.main
   ```

4. **Abrir y ejecutar el juego en Godot 4.7.2:**
   - Abre el proyecto [cliente_Godot/project.godot](cliente_Godot/project.godot) y ejecuta la escena principal [cliente_Godot/scenes/combat/CombatArena.tscn](cliente_Godot/scenes/combat/CombatArena.tscn) (`F5`).
   - Al conectar verás `🔌 Servidor lógico conectado (127.0.0.1:8765).`.

## Controles y gramática del Cuatro (`CuatroLlanero.g4`)

- **Movimiento del Llanero (8 direcciones):** `WASD` o Flechas. *(Tocar el muro espectral morado aplica rebote al centro y `-5 HP`.)*
- **Acordes del Cuatro (audio inmediato en local):** el jugador pulsa `J`, `K`, `L`, `I` y `Espacio`; Godot los normaliza a los tokens de gramática `T`, `S`, `D`, `M`, `F`. Después de validar, la máquina de Turing recibe únicamente `A`, `D`, `C` o `E`. `Backspace` limpia la secuencia.

| Golpe | Combinación en teclado | Tokens | Efecto |
| :--- | :--- | :--- | :--- |
| **Golpe de Pajarillo** | `I K L I` + `Espacio` | `M S D M F` | Ataque (`30` daño al Silbón) |
| **Contrapunteo Libre** | `J L` + (`K L J`)+ + `Espacio` | `T D (S D T)+ F` | Ataque recursivo (`25` daño al Silbón) |
| **Golpe de Gabán** | `J L L J` + `Espacio` | `T D D T F` | Ataque (`15` daño al Silbón) |
| **Seis por Derecho** | `J K L J` + `Espacio` | `T S D T F` | Defensa/Parry (`0` daño recibido) |
| **Zumbe y Zumbe** | `K L K L` + `Espacio` | `S D S D F` | Defensa/Parry (`0` daño recibido) |
| **Tonada de Sabana** | `J I K J` + `Espacio` | `T M S T F` | Carga (`C`: reduce en `1` la furia enemiga) |
| **Error sintáctico** | Cualquier otra secuencia | `E` | `0` daño directo, pero **inmoviliza al jugador 1.0 s** |

## Protocolo rápido y documentación

- El servidor procesa peticiones TCP delimitadas por `\n` (`{"secuencia":"TDDTF"}`) y responde JSON con `valido`, `golpe`, `accion`, `error`, `dano_enemigo`, `dano_jugador`, `enemigo_accion`, `vida_jugador`, `vida_enemigo`, `estado`, `cintas` (`cinta1`, `cinta2`, `cinta3`) y `cabezales`.
- Documentación técnica completa en [Documentacion/Documentacion_tecnica/](Documentacion/Documentacion_tecnica/).
- Modelos JFLAP en [backend/formal/turing/](backend/formal/turing/) y [Documentacion/MaquinaTuring/](Documentacion/MaquinaTuring/).
