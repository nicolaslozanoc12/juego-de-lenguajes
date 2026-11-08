# juego-de-lenguajes

## Servidor backend

El servidor local implementa el flujo documentado: valida la secuencia del
cuatro, actualiza la maquina de Turing multicinta de tres cintas y resuelve el
turno de combate.

## Pruebas locales y ejecución

Desde la raíz del repositorio:

```bash
# Ejecutar pruebas unitarias
python -m unittest discover -s backend/tests

# Iniciar el servidor TCP (escucha en 127.0.0.1:8765)
python -m backend.main
```

El servidor escucha directamente peticiones TCP delimitadas por salto de línea:
```json
{"secuencia":"TDDTF"}
```

La respuesta incluye `valido`, el golpe identificado, daño, vidas, la decisión enemiga y los snapshots de las tres cintas de Turing (`cinta1`, `cinta2`, `cinta3`) y sus `cabezales`.

La representación JFLAP de la máquina de decisión del enemigo está en
[backend/turing_jff/](backend/turing_jff/).
