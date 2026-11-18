# Diseño Formal del Juego: Gramática del Cuatro Llanero y Máquina de Turing Multicinta

Este documento define la base teórica y práctica para el proyecto final de **Lenguajes de Programación**, integrando una **Gramática Libre de Contexto (ANTLR)** para el sistema de combate musical del jugador y una **Máquina de Turing Multicinta** para la Inteligencia Artificial adaptativa de los enemigos.

---

## 1. El Cuatro Llanero como Lenguaje Formal (Jugador)

En lugar de exigir conocimientos musicales reales, abstraemos la ejecución del cuatro llanero en un **alfabeto de tokens** (acordes y golpes de mano derecha) y **reglas sintácticas** basadas en los "golpes" tradicionales del joropo.

### 1.1. Análisis Léxico (Alfabeto / Tokens)

El jugador cuenta con **5 entradas básicas** (mapeadas a teclas del teclado):

| Token | Nombre Musical (Simplificado) | Tecla en Juego | Función en la Gramática |
| :--- | :--- | :---: | :--- |
| **`T`** | **Tónica** (Re Mayor) | `J` | Acorde base de inicio o reposo armónico. |
| **`S`** | **Subdominante** (Sol Mayor) | `K` | Acorde de transición o preparación defensiva/utilidad. |
| **`D`** | **Dominante** (La 7ma) | `L` | Acorde de tensión máxima (impulsa ataques y combos). |
| **`M`** | **Menor Relativo** (Si menor) | `I` | Acorde menor para el *Golpe de Pajarillo* y la *Tonada*. |
| **`F`** | **Frenao / Chasquido** (Remate) | `Espacio` | **Delimitador de fin de cadena (`F`).** Cierra el compás y envía la secuencia al parser. |

*(El movimiento del llanero utiliza `WASD` / Flechas y `Backspace` limpia los acordes acumulados antes de presionar `Espacio`.)*

---

### 1.2. Análisis Sintáctico (Las 6 Secuencias / Golpes Llaneros)

El lenguaje reconoce **6 estructuras gramaticales principales** (divididas en Ataque, Defensa y Utilidad/Combo), incluyendo **reglas recursivas** para demostrar el poder de una Gramática Libre de Contexto frente a una simple lista estática.

#### Resumen de las 6 Secuencias:

1. **Golpe de Gabán (Ataque Básico Rápido):**
   - **Secuencia:** `T -> D -> D -> T -> F`
   - **Efecto en juego:** Lanza una onda acústica corta de daño directo.
2. **Golpe de Pajarillo (Ataque Recio / Daño en Área):**
   - **Secuencia:** `M -> S -> D -> M -> F`
   - **Efecto en juego:** Ataque pesado en tonos menores que rompe guardias.
3. **Seis por Derecho (Defensa / Escudo Armónico):**
   - **Secuencia:** `T -> S -> D -> T -> F`
   - **Efecto en juego:** Crea una barrera o ejecuta un *Parry* contra el ataque enemigo.
4. **Zumbe y Zumbe (Esquive / Aturdimiento):**
   - **Secuencia:** `S -> D -> S -> D -> F`
   - **Efecto en juego:** Desorienta al enemigo e interrumpe su carga de ataque.
5. **Tonada de Sabana (Reducción de Furia / Utilidad `C`):**
   - **Secuencia:** `T -> M -> S -> T -> F`
   - **Efecto en juego:** Reduce en `1` la furia del enemigo en la Cinta 2 (`_FURIA_DELTA["C"] = -1`) sin infligir daño directo.
6. **Contrapunteo Libre (Combo Recursivo):**
   - **Secuencia:** `T -> D -> [Ciclo Recursivo (S -> D -> T)]+ -> F`
   - **Efecto en juego:** Ataque de `25` puntos de daño que acepta cualquier número $\ge 1$ de repeticiones de `S D T` antes de cerrar con *Frenao (`F`)*.

---

### 1.3. Especificación de la Gramática en ANTLR4 (`CuatroLlanero.g4`)

```antlr
grammar CuatroLlanero;

// Regla inicial: Una ejecución válida debe ser uno de los 6 golpes y terminar en EOF
ejecucion
    : golpe EOF
    ;

golpe
    : gaban
    | pajarillo
    | seisPorDerecho
    | zumbeYZumbe
    | tonada
    | contrapunteo
    ;

// 1. Golpe de Gabán (Ataque básico)
gaban
    : TONICA DOMINANTE DOMINANTE TONICA FRENAO
    ;

// 2. Golpe de Pajarillo (Ataque fuerte en tono menor)
pajarillo
    : MENOR SUBDOM DOMINANTE MENOR FRENAO
    ;

// 3. Seis por Derecho (Defensa / Parry)
seisPorDerecho
    : TONICA SUBDOM DOMINANTE TONICA FRENAO
    ;

// 4. Zumbe y Zumbe (Control / Interrupción)
zumbeYZumbe
    : SUBDOM DOMINANTE SUBDOM DOMINANTE FRENAO
    ;

// 5. Tonada (Curación)
tonada
    : TONICA MENOR SUBDOM TONICA FRENAO
    ;

// 6. Contrapunteo (Regla recursiva para combos de longitud variable)
contrapunteo
    : TONICA DOMINANTE bordoneo FRENAO
    ;

bordoneo
    : SUBDOM DOMINANTE TONICA
    | SUBDOM DOMINANTE TONICA bordoneo
    ;

// --- TOKENS (LEXER) ---
TONICA    : 'T' ;
SUBDOM    : 'S' ;
DOMINANTE : 'D' ;
MENOR     : 'M' ;
FRENAO    : 'F' ;

WS        : [ \t\r\n]+ -> skip ;
```

### 1.4. Manejo de Errores Sintácticos en el Gameplay
- **Cadena Válida:** Si ANTLR parsea la entrada sin errores, `_GolpeListener` identifica la regla alcanzada (`gaban`, `pajarillo`, `seisPorDerecho`, `zumbeYZumbe`, `tonada` o `contrapunteo`), clasifica la acción (`A`, `D` o `C`) y el controlador aplica el efecto del turno.
- **Error Léxico/Sintáctico:** Si el jugador presiona `Espacio` (`F`) con una combinación inválida (ej. `T T D F`), el `CuatroErrorListener` de ANTLR captura el fallo (`ERROR_SINTACTICO`), la Máquina de Turing recibe `E` en Cinta 1, **no quita vida al jugador (`dano_jugador = 0`)** e **inmoviliza al Llanero durante `1.0` segundo** en Godot.

---

 ### 2. Dinámica implementada en tiempo real

  1. **Movimiento y Posicionamiento (Top-Down 2D en 8 direcciones):** El Llanero se desplaza con `WASD` / Flechas dentro de una arena rectangular rodeada por el `MuroEspectral` (tocar sus bordes rebota al centro y resta `5` de vida).
  2. **Ejecución musical inmediata (Fast-Path):** Mientras te mueves o posicionas, tocas los acordes con `J, K, L, I` (sonido instantáneo en local) y envías la cadena al presionar `Espacio` (`Frenao`). Si te equivocas antes de enviar, `Backspace` limpia la secuencia.
  3. **Resolución Formal en Python:** Cada secuencia enviada con `Espacio` atraviesa el parser ANTLR4 y actualiza las 3 cintas de la Máquina de Turing del jefe (`El Silbón`), devolviendo el resultado completo del turno por TCP (`127.0.0.1:8765`).