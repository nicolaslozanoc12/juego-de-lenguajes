# Contratos JSON del backend

Estos esquemas son la frontera entre Godot y el servidor. El transporte TCP
local usa `127.0.0.1:8765`, con un objeto JSON por linea. Para pruebas y
clientes HTTP, el mismo backend expone `http://127.0.0.1:8766`.

## Rutas HTTP

- `GET /health`: confirma que el servidor esta disponible.
- `POST /turn`: recibe una peticion de turno y devuelve la respuesta de combate.
- `POST /reset`: reinicia vidas y cintas de la partida.

Ejemplo:

```text
curl -X POST http://127.0.0.1:8766/turn -H "Content-Type: application/json" -d "{\"secuencia\":\"TDDTF\"}"
```

## Flujo del cliente

1. El cliente acumula tokens `T`, `S`, `D`, `M`.
2. `F` cierra la secuencia y el cliente envia una peticion que cumple
   [request.schema.json](./request.schema.json).
3. El servidor responde una linea que cumple
   [response.schema.json](./response.schema.json).
4. Si el JSON no tiene la forma esperada, responde con
   [error.schema.json](./error.schema.json).

`cintas.cinta1` es el historial de acciones (`A`, `D`, `C`, `E`), `cinta2`
contiene `[furia, repeticion]` como simbolos de texto entre `0` y `3`, y
`cinta3` contiene las decisiones tacticas. `cabezales` permite que el HUD
resalte la celda actual.

El campo `contrato_version` permite evolucionar el protocolo sin que el
frontend tenga que adivinar cambios de formato.
