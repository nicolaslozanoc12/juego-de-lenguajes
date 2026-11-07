# Máquina de Turing para JFLAP

El archivo [maquina_turing_enemigo.jff](./maquina_turing_enemigo.jff) permite
probar en JFLAP la transición de un turno de la máquina implementada en
[`backend/turing.py`](../turing.py).

## Cintas

| Cinta | Entrada | Salida |
|---|---|---|
| 1 | `A`, `D`, `C` o `E` | Conserva la acción |
| 2 | Furia actual: `0`, `1`, `2` o `3` | Furia nueva |
| 3 | Vacía | Código de una letra: `R`, `P`, `B` o `C` |

JFLAP solo permite un carácter por celda. La equivalencia con Python es:

| Código JFLAP | Decisión Python |
|---|---|
| `R` | `ATAQUE_RAPIDO` |
| `P` | `ATAQUE_PESADO` |
| `B` | `BLOQUEO` |
| `C` | `CASTIGO` |

En **Input > Multiple Run**, selecciona tres cintas. Para probar el primer
turno con furia inicial cero:

```text
Cinta 1: A
Cinta 2: 0
Cinta 3: (vacía)
```

El resultado esperado es `cinta2=1` y `cinta3=R` (`ATAQUE_RAPIDO`). Otros ejemplos:

```text
A / 1 / vacía  -> 2 / P
D / 2 / vacía  -> 1 / B
E / 0 / vacía  -> 2 / C
```

Este archivo reproduce la transición de furia y decisión de un turno. El
contador de repetición del anti-spam (`tape2[1]` en Python) permanece en el
estado de la clase `MultiTapeTuringMachine`, porque JFLAP no conserva el estado
de una ejecución al iniciar otra. La prueba completa del historial y del
castigo en la tercera repetición está en `backend/tests/test_backend.py`.
