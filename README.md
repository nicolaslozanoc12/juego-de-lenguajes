# juego-de-lenguajes

## Servidor backend

El servidor local implementa el flujo documentado: valida la secuencia del
cuatro, actualiza la maquina de Turing multicinta de tres cintas y resuelve el
turno de combate.

Desde la raiz del repositorio:

```text
python -m unittest discover -s backend/tests
python -m backend.main
```

El servidor escucha en `127.0.0.1:8765` y usa mensajes JSON delimitados por
salto de linea:

```json
{"secuencia":"TDDTF"}
```

La respuesta incluye `valido`, el golpe identificado, dano, vidas, la decision
enemiga y los snapshots de `cinta1`, `cinta2`, `cinta3` y sus `cabezales`.

## Ejecutar solo el servidor con Docker

```text
docker compose up -d --build
docker compose ps
docker compose down
```

El socket TCP para Godot queda en `127.0.0.1:8765`. Para pruebas HTTP con
`curl`, el servidor expone `127.0.0.1:8766`:

```text
curl.exe http://127.0.0.1:8766/health
curl.exe -X POST http://127.0.0.1:8766/reset
```

Las rutas y sus cuerpos JSON están documentados en
[contracts/README.md](contracts/README.md).
