# Ejemplo completo: correos de mi bandeja → fila en un Excel de SharePoint

**Pedido típico:** *"Quiero que los correos que me llegan de X queden registrados en un Excel que tengo en SharePoint."*

Esto es un **diseño de referencia**, no un flujo validado en producción. Los nombres exactos de nodos y parámetros se obtienen con `search_nodes` y `get_node_types`, nunca de memoria.

**Nivel de riesgo:** 2 (escribe en un archivo). La persona construye y publica con Claude. Sube a Nivel 3 si la bandeja incluye correos de nómina, disciplinarios o financieros.

## Preguntas iniciales (máximo 3)

1. ¿Cuáles correos? Carpeta, remitente o asunto. **No se copia toda la bandeja.**
2. ¿Qué datos van a cada fila? Por defecto: fecha de recibido, remitente, asunto, resumen del cuerpo e identificador del mensaje. Si quiere extraer algo del cuerpo (por ejemplo un número), pedir un correo de ejemplo.
3. ¿Dónde está el Excel (sitio y ruta) y ya tiene los datos dentro de una **Tabla de Excel**? Si no, la persona crea la tabla (Insertar → Tabla) con los encabezados acordados.

## Requisitos previos

| Requisito | Detalle |
|-----------|---------|
| Credencial de Outlook propia | Tipo "Microsoft Outlook OAuth2", con permiso de lectura de correo |
| Credencial de Excel/SharePoint propia | Tipo "Microsoft Excel OAuth2", con permiso de archivos y sitios |
| Registro de aplicación en Entra con esos permisos delegados | **Pendiente de confirmar por DDS** (ver abajo) |
| El Excel con una Tabla | Sin tabla no se puede agregar filas |

**Permisos de Entra.** En la infraestructura documentada, el registro `n8n-graph-dds` tiene permisos de archivos y sitios (`Files.ReadWrite`, `Files.ReadWrite.All`, `Sites.ReadWrite.All`) pero **no incluye permisos de correo**, y `n8n-mail` está marcado como "no usar" desde el 28/08/2026. Para que un usuario lea su propio buzón, DDS debe confirmar qué registro entrega el Client ID y el Client Secret para correo delegado. Si falta, el síntoma es que la persona no puede conectar la credencial o que el disparador falla con `AADSTS65001` (falta consentimiento) o con 403.

## Diseño

```
Outlook Trigger (correo recibido, carpeta o filtro, cada 5 min)
  → Filter (remitente / asunto)                    [sin alwaysOutputData]
  → Edit Fields (arma las columnas de la fila)
  → Data Table: ¿ya procesado? (por internetMessageId)
  → If nuevo ──no──► fin
        └─sí─► Aggregate (todas las filas de esta ejecución en una lista)
              → HTTP Graph: createSession      (por ruta del archivo)
              → HTTP Graph: POST …/workbook/tables/{tabla}/rows/add
                     header workbook-session-id, body JSON.stringify({values: [[…],[…]]})
              → HTTP Graph: closeSession
              → Data Table: marcar como procesados  (solo si la escritura salió bien)
  Rama de error de cada HTTP → aviso a la persona (correo con prefijo "[Automatización]")
```

## Reglas de Mectronics aplicadas (y por qué)

| Regla | Aplicación |
|-------|------------|
| Excel: un solo candado por sesión de libro; muchas peticiones seguidas dan 429 | Una sola petición `rows/add` con todas las filas de la ejecución, dentro de `createSession` / `closeSession` |
| Resolver el archivo por ruta, no por `itemId` | `/drives/{drive}/root:/ruta/archivo.xlsx:/workbook` |
| Nunca `staticData` para dedup de negocio | Data Table propia (`USR-…-procesados`) con `internetMessageId` |
| Marcar procesado solo tras confirmar la escritura | El nodo de marcado va después de `rows/add`; si falla, el correo se reintenta en la siguiente ejecución |
| Patrón del item vacío | El Filter y el If que deciden "no hay nada" no llevan `alwaysOutputData` |
| Anti-loop si se avisa desde el mismo buzón | El aviso lleva prefijo `[Automatización]` en el asunto y el Filter inicial lo excluye; además se descartan los enviados por la propia persona |
| Un `success` no prueba que hubo resultado | Los HTTP llevan salida de error; el flujo devuelve `ok` y `motivo`; se verifica la fila con un caso real |
| Credenciales propias | Nodos de Outlook y Graph con las credenciales de la persona; verificadas nodo por nodo antes de publicar |
| Retención de ejecuciones de ~10 días | El historial real es el Excel; no depender de la lista de ejecuciones |
| Zona horaria del servidor America/Bogota | Las fechas se guardan en la zona de la persona y se indica en el encabezado de la columna |

## Pruebas

- `test_workflow` con `pinData`: el disparador y los nodos con credencial se simulan. **La Data Table sí escribe de verdad**: usar un `internetMessageId` que empiece por `TEST-` y borrar esa fila al terminar.
- No marcar nada como probado en producción hasta el caso real.

## Publicar y verificar

1. La persona confirma en la UI que Outlook y Graph usan **su** cuenta.
2. `publish_workflow` con su confirmación.
3. La persona se envía un correo que cumpla el filtro. Esperar el ciclo del disparador.
4. Revisar la ejecución con `get_workflow_execution` y pedir a la persona que confirme **la fila nueva en su Excel**.
5. Entregar la ficha de `solicitud-y-revision.md`.

## Fallos típicos

| Síntoma | Causa probable | Qué hacer |
|---------|----------------|-----------|
| No se puede conectar la credencial de Outlook o `AADSTS65001` | El registro de Entra no tiene el permiso de correo o falta consentimiento | Avisar a DDS: es el requisito pendiente de arriba |
| `429 EditModeCannotAcquireLockTooManyRequests` | Varias escrituras seguidas al mismo libro | Una sola petición con todas las filas y sesión de libro |
| 401 `FileOpenUserUnauthorized` en `/workbook` | Registro de aplicación sin capacidad de Office para la web | Diagnóstico por capas; derivar a DDS |
| El flujo cierra en `success` y no hay fila | Falló una rama sin error, o el Filter descartó todo | Revisar `ok` y `motivo`, y qué dejó pasar el Filter |
| `rows/add` rechazado | El Excel no tiene Tabla o el nombre de la tabla no coincide | La persona crea o corrige la Tabla |
| Filas duplicadas | Dedup mal conectado o se marcó antes de escribir | Revisar el orden: marcar solo después de la escritura |
| El disparador no dispara | Flujo sin publicar o credencial vencida | Verificar publicación y reconectar la credencial |
