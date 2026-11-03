# Diseño Formal del Juego: Gramática del Cuatro Llanero y Máquina de Turing Multicinta

Este documento define la base teórica y práctica para el proyecto final de **Lenguajes de Programación**, integrando una **Gramática Libre de Contexto (ANTLR)** para el sistema de combate musical del jugador y una **Máquina de Turing Multicinta** para la Inteligencia Artificial adaptativa de los enemigos.

---

## 1. El Cuatro Llanero como Lenguaje Formal (Jugador)

En lugar de exigir conocimientos musicales reales, abstraemos la ejecución del cuatro llanero en un **alfabeto de tokens** (acordes y golpes de mano derecha) y **reglas sintácticas** basadas en los "golpes" tradicionales del joropo.

### 1.1. Análisis Léxico (Alfabeto / Tokens)

El jugador cuenta con **5 entradas básicas** (mapeadas a teclas del teclado):

| Token | Nombre Musical (Simplificado) | Tecla Sugerida | Función en la Gramática |
| :--- | :--- | :---: | :--- |
| **`T`** | **Tónica** (ej. Re Mayor) | `A` / `J` | Acorde base de inicio o reposo armónico. |
| **`S`** | **Subdominante** (ej. Sol Mayor) | `S` / `K` | Acorde de transición o preparación defensiva/curativa. |
| **`D`** | **Dominante** (ej. La 7ma) | `D` / `L` | Acorde de tensión máxima (impulsa ataques y combos). |
| **`M`** | **Menor Relativo** (ej. Si menor) | `W` / `U` | Acorde melancólico/recio para estados alterados o críticos. |
| **`F`** | **Frenao / Chasquido** (Remate) | `Espacio` | **Delimitador de fin de cadena (EOF).** Envía la secuencia al parser. |

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
5. **Tonada de Sabana (Curación / Buff):**
   - **Secuencia:** `T -> M -> S -> T -> F`
   - **Efecto en juego:** El llanero recupera vida o calma el ambiente.
6. **Contrapunteo Libre (Combo Recursivo / Ultimate):**
   - **Secuencia:** `T -> D -> [Ciclo Recursivo (S -> D -> T)]+ -> F`
   - **Efecto en juego:** Mientras el jugador repita el patrón recursivo antes de presionar el *Frenao (`F`)*, el multiplicador de daño aumenta. Si se equivoca en un acorde antes de cerrar con `F`, pierde todo el combo.

---

### 1.3. Especificación de la Gramática en ANTLR4 (`CuatroLlanero.g4`)

```antlr
grammar CuatroLlanero;

// Regla inicial: Una ejecución válida debe ser uno de los 6 golpes y terminar en EOF
ejecucion
    : golpe EOF
    ;

golpe
    : gaban          # AtaqueBasico
    | pajarillo      # AtaqueFuerte
    | seisPorDerecho # DefensaEscudo
    | zumbeYZumbe    # DefensaAturdir
    | tonada         # UtilidadCuracion
    | contrapunteo   # AtaqueRecursivo
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
- **Cadena Válida:** Si ANTLR parsea la entrada sin errores, devuelve el nodo semántico (`#AtaqueBasico`, `#DefensaEscudo`, etc.) y el personaje ejecuta la animación y el sonido real del acorde.
- **Error Léxico/Sintáctico:** Si el jugador presiona `F` con una combinación inválida (ej. `T T D F`), el `ErrorListener` de ANTLR captura el fallo, reproduce el sonido de una cuerda desafinada y aplica una penalización breve (enfriamiento de 1 segundo).

---

 ### 2. Dinámica: Acción en Tiempo Real "con Ventanas de Reacción" (El punto medio ideal)

  Tienes toda la razón: un combate por turnos estático le quita la gracia de tocar el cuatro, pero un juego de acción frenético puede hacer muy difícil tocar secuencias de 4 o 5 acordes sin equivocarse.

  La solución ideal es un Combate en Tiempo Real con Telegrafía (estilo Dark Souls / Monster Hunter mezclado con Magicka):

  1. Movimiento y Posicionamiento (Isométrico): Puedes mover a tu llanero por el escenario isométrico.
  2. El Enemigo anuncia su intención (Telegrafía): El enemigo (por ejemplo, El Silbón) empieza a cargar un ataque durante 3 o 4 segundos (se ve un área roja en el suelo o un icono sobre su cabeza).
  3. Tu respuesta con el Cuatro:
      • Mientras estás parado o esquivando, presionas las teclas de los acordes (ej. J, K, L, U para los acordes y Espacio para el "Frenao" que envía la cadena a ANTLR).
      • Si el enemigo va a lanzar un ataque rápido, tocas la gramática de Defensa / Contrapunteo antes de que te golpee para hacerle un Parry musical.
      • Si el enemigo está vulnerable, tocas una gramática ofensiva larga (Pajarillo o Gabán) para hacerle daño en área.