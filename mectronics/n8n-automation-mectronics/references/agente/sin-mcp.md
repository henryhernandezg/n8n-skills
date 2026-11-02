# Si el MCP de n8n no responde: cargar el flujo a mano

El camino normal es el MCP. Este plan B se usa cuando las herramientas de n8n no aparecen, dan error de conexión o no permiten crear o publicar. La persona termina con el mismo flujo funcionando, cargándolo ella en la pantalla de n8n.

## 1. Detectar y decirlo con claridad

- Las herramientas de n8n no están disponibles, o fallan con error de conexión, de permisos o de tiempo.
- Reintentar **una sola vez**. Antes de reintentar una creación, buscar por nombre si el flujo ya quedó creado, para no duplicarlo.
- Si sigue fallando, decirlo sin rodeos: *"No puedo crear el flujo directamente en n8n ahora. Te lo preparo en un archivo y te explico cómo cargarlo; son unos pocos clics."*
- No inventar que el flujo quedó creado ni publicado.

## 2. Entregar el flujo como archivo importable

Claude escribe el flujo en el formato de importación de n8n y lo entrega como archivo `.json` (si no hay herramienta de archivos, en un bloque de código para copiar). Estructura mínima:

```json
{
  "name": "USR-<área>-<persona>-<qué hace>",
  "nodes": [
    { "id": "…", "name": "…", "type": "n8n-nodes-base.…", "typeVersion": 1,
      "position": [0, 0], "parameters": { } }
  ],
  "connections": { "Nodo A": { "main": [[ { "node": "Nodo B", "type": "main", "index": 0 } ]] } },
  "settings": {}
}
```

Reglas para este JSON, que Claude escribe sin apoyo del MCP:

- Es **más propenso a errores** que el flujo creado por MCP, porque no se puede validar contra la instancia. Decirlo.
- No incluir credenciales ni secretos: los nodos quedan con la credencial por asignar.
- Usar nombres de tipo y versiones de nodo que se conozcan con seguridad; si hay duda sobre un parámetro, simplificar el nodo y avisar cuál hay que revisar.
- Mantener las mismas reglas de la skill (ramas de error, dedup en Data Table, una escritura por ejecución en Excel con sesión, guardas anti-loop).
- El flujo se entrega **sin publicar**: la persona lo publica al final.

## 3. Pasos para la persona (copiarlos tal cual)

1. Abrir n8n y entrar a **Workflows**. Crear un flujo nuevo.
2. Cargar el archivo: menú de los tres puntos (⋯) → **Import from file…** y elegir el `.json`. Alternativa: abrir el archivo, copiar todo el contenido y pegarlo en el lienzo con **Ctrl+V**.
3. Abrir **cada nodo que tenga un candado o pida credencial**, elegir **tu** cuenta de Microsoft (o crearla con *Sign in with Microsoft*) y guardar. Si un nodo sale en rojo, abrirlo y revisar el campo marcado.
4. Pulsar **Execute workflow** (o **Test**) para probar. Revisar que no haya nodos en rojo.
5. Pulsar **Publish** (Publicar) para dejarlo funcionando solo. Confirmar que quedó publicado.
6. Provocar un caso real (por ejemplo enviarte un correo de prueba) y comprobar el resultado en tu Excel. Contarle el resultado a Claude.

## 4. Si algo falla al importar

- Pedir a la persona el texto del error o una captura del nodo en rojo. Claude corrige el JSON y lo entrega de nuevo.
- Nodo desconocido o parámetro rechazado: simplificar ese nodo o sustituirlo por un HTTP Request a Graph, que es el patrón validado en Mectronics.
- Si tras dos intentos sigue sin cargar, derivar a DDS con la ficha de `solicitud-y-revision.md` y el archivo.

## 5. Cuando el MCP vuelva

Pedir a la persona que abra el flujo ya cargado y que Claude lo revise con `get_workflow_details` (conexiones y credenciales) antes de darlo por bueno.
