---
name: "n8n-automation-mectronics"
description: "Usar siempre que se trabaje con n8n en Mectronics S.A. / Grupo Express (https://n8n.mectronics.com.co): crear, modificar, validar, probar, depurar o desplegar workflows; diagnosticar un flujo que falla o que cierra en success sin hacer nada; o decidir cómo automatizar un proceso interno. Cubre infraestructura del servidor, credenciales, IDs de flujos y patrones validados contra WhatsApp Business, Outlook, Microsoft Graph (SharePoint/Excel/PDF), Azure Blob Storage, Azure AI Search, Postgres, TFS y Azure AI Foundry."
---

# n8n Automation — Mectronics

## Propósito

Crear, depurar y desplegar workflows de n8n para Mectronics S.A. / Grupo Express con conocimiento de la
infraestructura, APIs, credenciales y patrones validados en producción. Todo lo que está aquí fue medido,
no supuesto; donde algo no está confirmado, se dice explícitamente.

## Infraestructura n8n Mectronics

- **URL n8n**: https://n8n.mectronics.com.co
- **Versión**: 2.18.7 (Self Hosted)
- **Proyecto personal**: ID `j4OCl6Q7guPAT1pL`
- **Carpetas**: `HSEQ` (`XsHPemowRHsptSoI`), dentro del proyecto personal.
- **SO servidor**: Windows Server (Administrador.MECTRONICS). El servicio corre con **NSSM** (`E:\nssm-2.24\win64\nssm.exe`) bajo la cuenta **LocalSystem**.
- **Consecuencia de LocalSystem**: n8n **no ve shares UNC** (`\\servidor\recurso`). Para procesar archivos de un share hay que dejar un espejo o un índice en disco local con una tarea programada de Windows que corra bajo una cuenta de dominio.
- **Zona horaria del servidor**: America/Bogota (UTC-5). Los cron y `scheduleTrigger` se interpretan ahí.
- **Execute Command node**: DESHABILITADO. Procesos locales = tarea programada de Windows + nodo Read/Write Files from Disk. `n8n-nodes-base.writeBinaryFile` tampoco existe ("Unrecognized node type").
- **Acceso a disco**: `N8N_RESTRICT_FILE_ACCESS_TO` (rutas separadas por `;`). Hoy (13/10/2026): `E:\Scripts\ScriptsDirectorIA`, `E:\AnexosN8N\`, `C:\Windows\System32\config\systemprofile\.n8n`. Agregar una ruta **exige reiniciar n8n**.
- **Carpeta de scripts del servidor**: `E:\Scripts\ScriptsDirectorIA` (y `E:\Scripts\ScriptsSGI` para los del SGI).
- **La licencia actual NO permite variables de entorno de n8n**: la configuración de un flujo va en un nodo Code o Set inicial, no en `$env`. Por la misma razón, **tampoco hay estado fiable entre ejecuciones vía variables de entorno o `$env`** — cualquier bandera, bloqueo o contador que deba persistir entre corridas va en una tabla (Data Table o Postgres, ver más abajo), nunca en configuración de instancia.
- **Retención de ejecuciones**: ~10 días. Cualquier análisis histórico más largo se apoya en `dds_director.ejecucion_n8n`, no en la lista de ejecuciones.

### Credenciales disponibles

| Nombre | Tipo | Uso |
|--------|------|-----|
| WhatsApp OAuth account | WhatsApp OAuth API | Trigger de WhatsApp |
| WhatsApp account | WhatsApp API | HTTP a Graph de Meta (número DDS, app chatWhastappMSA) |
| WhatsApp account Gestion Humana | WhatsApp API | HTTP a Graph de Meta (número Gestión Humana, app GestionHumanaMectronics) |
| Microsoft Outlook DDS | Microsoft Outlook OAuth2 | Envío de correo vía `/me/sendMail` |
| Microsoft Outlook Correo Disciplinarios | Microsoft Outlook OAuth2 | Buzón disciplinarios (flujos TFS) |
| Microsoft Outlook Correo Infraestructura Mectronics | Microsoft Outlook OAuth2 | Buzón infraestructura (trigger y envío de los flujos SGI) |
| Microsoft Graph DDS | Microsoft Excel OAuth2 | Excel online, SharePoint/OneDrive y conversión a PDF |
| Azure Storage SGI | Azure Storage (Shared Key, key2) | Subida y borrado de blobs en `almacenamientomectronics` |
| Postgres account n8n | Postgres | Base `dds_director` y tablas propias de n8n |

**La API de n8n no expone a qué credencial apunta cada nodo** desde `get_workflow_details`. Sí aparece dentro de los datos de una ejecución (`runData[].error.node.credentials`). Para saberlo sin ejecutar, mirar la UI.

### Registros de aplicación en Entra (tenant f23a7c84-3d12-4082-a572-13781571a4e7)

- **n8n-graph-dds** — registro dedicado, creado 28/08/2026. Usar este para todo lo de Graph.
  Delegados: `openid`, `profile`, `email`, `offline_access`, `User.Read`, `Files.ReadWrite`, `Files.ReadWrite.All`, `Sites.ReadWrite.All`.
- **n8n-mail** (App ID 64713252-11c5-4fda-bda6-bd3a0b0b7ab304) — registro compartido histórico, 40+ permisos.
  **Quedó en mal estado el 28/08/2026**: dejó de emitir tokens válidos para `/workbook` mientras la API de archivos seguía funcionando. NO usarlo. Pendiente verificar si `Microsoft Outlook DDS` sigue apuntando ahí — de esa credencial cuelgan DIR-20, DIR-31, DIR-32, DIR-36, DIR-37, REC-AI-03, Novedades de Nómina y ProcesosJudiciales.

### Data Tables y tablas de apoyo

| Tabla | Propósito |
|-------|-----------|
| WhatsApp Sessions (LOdGpEYoNLVz1jC0) | Estado de sesiones de chatbot |
| WhatsApp Calificaciones (9zvZJFJzvu5J2B2S) | Encuestas de satisfacción |
| `dds_director.dim_persona` | Directorio de desarrollo: 25 personas, `celular`, `activo`, `rol`, `equipo`. Fuente de verdad para autorizar el canal de WhatsApp |
| `public.directorio_personal_dds` | Directorio paralelo que usan los subflujos de líder técnico. Comparte 24 de 25 números con `dim_persona` — conviene consolidar |
| `dds_director.ejecucion_n8n` | Bitácora de negocio de los flujos DIR-* |
| `dds_director.alerta` | Alertas deduplicadas. Índice `ux_alerta_dedup` UNIQUE sobre `(hash_dedup) WHERE estado IN ('abierta','reconocida','en_curso')` |
| `dds_director.whatsapp_acceso_denegado` | Auditoría de intentos no autorizados contra el DevBot |
| `dds_director.nomina_bonificacion_envio` / `dds_director.nomina_bonificacion_paso` | Dedup a nivel período + bitácora de pasos del flujo "Novedades de Nómina DDS" — ver *Dedupe y bitácora de pasos* |

### Azure Storage y Azure AI Search

- **Cuenta de almacenamiento**: `almacenamientomectronics`. Acceso desde n8n con **Shared Key (key2)**, reservada para n8n (credencial `Azure Storage SGI`).
- **Contenedores en uso**: `conocimientomsaapp-pro` (base de conocimiento MSA; los documentos del SGI van bajo `DOCUMENTOS APROBADOS DEL SGI/<jerarquía>`) y `conocimientogestionhumana` (solo `Matrices/...` y `Manual de Funciones/...`).
- **Servicio de búsqueda**: `mectronics-default-srch`. Indexadores: `ks-conocimientomsaapp-pro-indexer` (HSEQ) y `ks-rh-reclutamiento-blob-indexer` (Gestión Humana). **Subir o borrar blobs no actualiza el índice**: hay que pedir reindexación (hoy, por correo a `soportemsa@mectronics.co`, tarea del DBA Jhon Arenas, `dba@mectronics.co`). El indexador también debe procesar las **eliminaciones**, no solo las altas.

### WhatsApp Business

- **Phone Number ID (chatWhastappMSA / DevBot DDS)**: 1178638038656642 · **Número visible**: +57 312 4168040 · **Graph API**: v21.0
- **CORRECCIÓN 25/09/2026** — el Business Account ID documentado antes (2069786850283064) no coincide con lo que devuelven hoy las herramientas MCP de WhatsApp Business Tools. La WABA real que agrupa los números de Mectronics es **Soporte Mectronics**, id **2223352705132091** — verificar ahí, no reusar el valor anterior.
- **Phone Number ID (GestionHumanaMectronics)**: 1417448521441787 · **Número visible**: +57 310 2074827
- Los dos números viven en la MISMA WABA (2223352705132091), repartidos en dos apps de Meta distintas: chatWhastappMSA (1328773685776532, DDS) y GestionHumanaMectronics (1404150305249313, Gestión Humana).
- **Formato de número Colombia**: `573003830851` — 12 dígitos (57 + móvil de 10), sin `+`, sin espacios.

### Suscribir una segunda app a una WABA que ya tiene un bot en producción

La suscripción de webhooks (`subscribed_apps`) es ADITIVA y es por CUENTA (WABA), no por número: si dos apps quedan suscritas a la misma WABA, AMBAS reciben eventos de TODOS los números de esa WABA, no solo del suyo. No existe forma de excluir una app por número sin un *webhook override* a nivel de número de teléfono (`https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/override/`), que este servidor MCP no expone — hay que llamarlo por fuera (ej. Postman).

Consecuencia real medida el 25/09/2026: el DevBot v3 captura `metadata.phone_number_id` en el nodo "Extraer telefono" pero nunca lo valida — solo lo usa para saber desde qué número responder. Sin guarda, al suscribir una segunda app a la misma WABA, el DevBot procesa también los mensajes del número de la otra app y contesta con SU menú desde el número equivocado.

**Mitigación aplicada**: antes de suscribir la segunda app, se agregó a mano en la UI (nunca por `update_workflow`) una condición AND al Filter "Es mensaje entrante?" del flujo con webhook en producción: `{{ $json.metadata.phone_number_id }}` Equals `<phone_number_id propio de ese flujo>`. El flujo de Gestión Humana lleva el mismo filtro desde el diseño inicial.

**Checklist real de entrega de webhooks** — confirmar con `whatsapp_biz_onboarding_status` del MCP de WhatsApp Business Tools, nunca por lo que muestra la pantalla "Personalizar caso de uso" de Meta: (1) suscripción de la cuenta a la app, (2) callback URL configurado, (3) app PUBLICADA. Los tres son obligatorios; con cualquiera pendiente no llega tráfico real, ni siquiera a admins/testers. El aviso "Falta un método de pago válido" en esa pantalla puede ser un falso negativo — verificar el método de pago real contra el Billing Hub de la cuenta (vía el MCP).

**Credencial WhatsApp API por app**: con dos apps conviene una credencial de n8n dedicada por app (ej. "WhatsApp account Gestion Humana"). El token permanente se genera con el MISMO System User del negocio (los permisos de envío son por WABA vía Assign Assets, no por app en n8n) — pero hay que asignarle también la app nueva en Assign Assets → Apps → Full control antes de generar el token, o el token no queda atribuido a ella. El "Business Account ID" que pide n8n en esa credencial es el id de la **WABA** (2223352705132091), no el del Business Manager.

### Azure AI Foundry

- **Endpoint Responses**: `https://IA-Foundry-Mectronics.services.ai.azure.com/api/projects/mectronics-default/agents/<agente>/endpoint/protocols/openai/v1/responses`
- **Header**: `api-key` (no Bearer)
- **Response path**: `$json.output.find(o => o.type === 'message').content.find(c => c.type === 'output_text').text`

## Flujos de referencia

| Flujo | ID | Notas |
|-------|-----|-------|
| DevBot DDS WhatsApp (v2/v3) | `FmF8cpGMiR5Wbne5` | Webhook en producción: **editar solo en la UI** |
| WhatsApp Notificacion Microservicios V2 | `gfzy4AbedtfZk7oT` | Plantilla aprobada `alerta_error_microservicio` |
| Monitoreo buzón disciplinarios → TFS | `HdIXcBcPX9wJEmco` | Outlook trigger + AI Foundry; requiere guardas anti-loop |
| DIAG - Credencial Microsoft Graph DDS | `9rjLMmF5SI7F5Ojq` | Diagnóstico por capas reutilizable |
| Actualización documentos SGI (por correo) | `AsWgVjQYykkZRywt` | Carpeta HSEQ, 24 nodos, **inactivo / en pruebas** |
| Migración única SGI a PDF en Azure | `Uv4GRV2J6IZQVQHC` | Carpeta HSEQ, 23 nodos, disparador manual, por lotes |
| Novedades de Nómina DDS | `WqwA7LKd7YtmmNg9` | 23 nodos. Dedup/bitácora por Postgres (ver *Dedupe y bitácora de pasos*) reemplazando `$getWorkflowStaticData`. HTTP Request con Microsoft Graph DDS / Outlook DDS: reasignar credencial tras cada `update_workflow` |

Los flujos `REC-AI-02`, `REC-03` y `REC-AI-03` dependen de Sie7e **preproducción** (ver *Dependencias con ventana de disponibilidad*).

## Restricciones al editar workflows existentes

**`update_workflow` reemplaza el workflow COMPLETO.** Consecuencias, todas medidas:

1. **Regenera el `webhookId` de los nodos trigger.** Verificado el 29/08/2026 con un flujo desechable: el `id` del nodo se conserva, el `webhookId` cambia. En un flujo con **WhatsApp Trigger, Webhook o Form**, el proveedor sigue enviando a la URL vieja y **el flujo enmudece sin producir un solo error**. Es el peor modo de fallo posible. Esos flujos **se editan a mano en la UI**, sin excepción.
2. **Los nodos HTTP Request pierden la credencial** en cada actualización; la respuesta del tool los lista explícitamente. Caso recurrente confirmado de nuevo el 14/10/2026 en los flujos SGI y el 26/10/2026 en Novedades de Nómina: tras cada `update_workflow` hay que **reasignar a mano la credencial en los nodos HTTP**. Incluirlo siempre en el aviso al usuario.
3. **Los nodos con credencial tipada sí se autoasignan** (Postgres, Excel OAuth2, WhatsApp, Azure Storage) cuando existe una sola credencial de ese tipo, tanto al crear como al actualizar. En un update, los nodos cuyo nombre no cambió conservan la suya.
4. **Si un nodo Code contiene datos grandes embebidos** (imágenes base64, plantillas HTML largas), reescribir obliga a reemitirlos íntegros, con riesgo de corromperlos. Dar al usuario las cadenas exactas para pegar.
5. **Las notas del canvas se pierden si no se reproducen.** Son documentación: transcribirlas literales.

Antes de cualquier `update_workflow`: `get_workflow_details` para capturar nombres, posiciones y parámetros exactos, y luego `validate_workflow`. **Los nodos que funcionan no cambian de nombre ni de parámetros** — renombrarlos rompe todas las referencias `$('Nombre')` y pierde credenciales.

### Cómo entregar un cambio en un flujo que no se puede reescribir

Crear un **flujo auxiliar** con los nodos nuevos ya configurados y conectados entre sí, y que el usuario los **copie y pegue** (Ctrl+C / Ctrl+V entre flujos, n8n conserva parámetros y credenciales). Así no transcribe SQL ni expresiones a mano; solo conecta. Nombrarlo `AUX - ...` e incluir una nota con los pasos de cableado.

### get_workflow_details en flujos grandes

Un flujo de 45 nodos supera el límite de tokens del tool. La respuesta se guarda en un archivo; usar `jq` sobre él para extraer solo lo necesario (lista de nodos con flags, conexiones de un nodo, el `jsCode` de uno solo). Nunca leer el archivo completo.

## Microsoft Graph — SharePoint, Excel, PDF y correo

### Las dos APIs son distintas y fallan distinto

| Ruta | Servicio real | Qué necesita |
|------|---------------|--------------|
| `/drives/{drive}/items/{item}` y `/content` | SharePoint / OneDrive | Files/Sites |
| `/drives/{drive}/items/{item}/workbook/...` | **Office para la web (WAC)** | Además, un token WAC válido |

Que `/content` funcione **no implica** que `/workbook` funcione.

### Escribir celdas sin chocar con el bloqueo de edición

Varios PATCH seguidos sobre el mismo libro producen `429 EditModeCannotAcquireLockTooManyRequests`: no es throttling por volumen, es contención del candado de edición.

**CORRECCIÓN 29/08/2026 — la receta anterior de este skill era insuficiente.** Se documentaba `batchSize 1 / batchInterval 2000` más Retry On Fail. Medido en DIR-09:

- El batching del nodo HTTP **no se aplicó**: 140 peticiones salieron en 17 segundos cuando `batchSize 1 / batchInterval 3000` debería haber tardado 7 minutos.
- El `Retry On Fail` es **código muerto** cuando el nodo tiene `neverError: true`, porque un 429 no cuenta como error y el reintento nunca dispara.
- Resultado real: 10 de 140 bloques escritos, y otras corridas colgadas 11 y 15 horas.

**Lo que sí funciona: una sesión de libro persistente.**

1. `POST .../workbook/createSession` con `{"persistChanges": true}` → devuelve un `id`.
2. Ese `id` como encabezado **`workbook-session-id`** en cada PATCH.
3. `POST .../workbook/closeSession` al final, con el mismo encabezado.

El candado se toma una vez, no una vez por petición. Con eso DIR-09 pasó de 10/140 bloques a **9/9 en 37 segundos**, y luego 8/8 en 25 s. Combinarlo con menos peticiones: subir `filas_por_bloque` (400 → 2000 bajó de 140 bloques a 28). Si fallan los bloques anchos (`C:P`), es tamaño de payload: bajar a 1000.

### Convertir Office a PDF con Graph

Patrón validado en los flujos SGI (14/10/2026). Graph convierte a PDF al **descargar**, no in situ: el archivo debe estar primero en un drive accesible.

1. **Subir temporal**: `PUT /me/drive/root:/_sgi_temp/{executionId}/{archivo}:/content` con la credencial `Microsoft Graph DDS` (el archivo queda en el OneDrive de esa cuenta).
2. **Descargar convertido**: `GET /me/drive/root:/_sgi_temp/{executionId}/{archivo}:/content?format=pdf`.
3. **Limpiar**: `DELETE` de la carpeta `_sgi_temp/{executionId}` al final del flujo, en un nodo que corra aunque haya errores. Si la corrida se aborta, la carpeta queda huérfana — revisarla periódicamente.

Qué se convierte: `.doc`, `.docx`, `.ppt`, `.pptx`. **Excel y PDF se copian tal cual** (convertir Excel pierde formato y no aporta a la indexación).

**Fallo determinístico `PPTCannotOpenDocumentSigned`**: `HttpCode=UnsupportedMediaType ErrorCategory=NotSupported` = presentación **firmada digitalmente**; el servicio de Office no la abre. Los reintentos no ayudan. Separar estos casos en una lista aparte del informe (`requierenConversionManual`) y exportarlos a PDF a mano. El original queda intacto.

### Identificadores de archivo

El `itemId` cambia si el archivo se mueve entre sitios. Preferir resolver por ruta: `/drives/{drive}/root:/ruta/archivo.xlsx:/workbook`.

### Adjuntos y descarga de correo

- **NUNCA usar `$select` con `contentBytes`** en `/messages/{id}/attachments`: Graph devuelve 400 BadRequest porque `contentBytes` no es seleccionable en OData. Llamar sin `$select` y Graph lo devuelve por defecto.
- Descarga EML completo (`/messages/{id}/$value`) requiere `responseFormat: 'text'`.

### Correo con firma corporativa

`POST /me/sendMail` con `attachments[].isInline: true` y `contentId`, referenciando desde el HTML como `cid:identificador`. `toRecipients` y `ccRecipients` son **arreglos**.

## Azure Blob Storage desde n8n

### `InvalidMetadata` al subir archivos con tildes en el nombre

Causa confirmada leyendo el código del nodo Azure Storage de n8n (14/10/2026): en **Create Blob con origen binario** envía `Content-Disposition: attachment; filename="<binary.fileName>"`. Un nombre con tildes (Inspección, Programación, Rotación…) **no es un header HTTP válido** y Azure responde `InvalidMetadata`.

Síntoma engañoso: los PDF convertidos no fallan, porque Graph los entrega como `content.pdf`. Solo revientan las **copias directas** de archivos cuyo nombre original tiene caracteres no ASCII — 9 de 25 en el primer piloto.

**Corrección**: en el nodo Code que prepara la subida, fijar `binary.data.fileName` a una versión ASCII del nombre de destino:

```js
const safeName = destino.split('/').pop().replace(/["\\]/g, '_').replace(/[^\x20-\x7e]/g, '_');
item.binary.data.fileName = safeName;
```

El nombre del **blob** (la ruta de destino) sí puede llevar tildes; lo que no puede es el `fileName` del binario, porque solo alimenta ese header.

### Borrado de blobs: el 404 no siempre dice "404"

Borrar un blob inexistente devuelve el texto **"The required blob doesn't match any existing one"**. Cualquier lógica que clasifique errores de borrado tiene que reconocerlo como *no existía* y no como error. Regex mínima:

```js
/not\s*found|404|doesn.?t match any existing|match any existing/i
```

Omitirlo infla el informe con errores falsos. Verificado en el flujo de migración; **pendiente** aplicarlo en el flujo de correo `AsWgVjQYykkZRywt`.

### Reemplazar originales por su PDF

Regla de oro: **borrar solo después de que la subida del reemplazo confirmó éxito**, en el mismo contenedor y la misma ruta, y solo las extensiones que el PDF reemplaza (`.doc`, `.docx`, `.ppt`, `.pptx`). Un borrado que no encuentra nada se cuenta en silencio; cualquier otro error se reporta. Reprocesar queda seguro: el PDF se sobrescribe y los borrados inexistentes se ignoran (idempotencia).

## Datos binarios en n8n 2.18.7

El `JsTaskRunnerSandbox` **no soporta datos binarios en los inputs de un nodo Code**: `this.helpers.httpRequest` con cuerpos Buffer los corrompe siempre, independientemente de `json: true/false`.

- **Única vía confiable para subir binarios**: `this.helpers.prepareBinaryData(buf, fileName, mimeType)` dentro del Code node + un **nodo HTTP Request nativo** con `contentType: 'binaryData'` e `inputDataFieldName: 'data'` para la subida real.
- Al **descargar** contenido que luego entra a un Code node, usar `responseFormat: 'text'`, nunca `'file'`.
- **No usar Merge para combinar JSON + binario.**
- En fan-in (después de ramas paralelas) referenciar con `.first()`; `.item` falla con *"Paired item data unavailable"*.

## Procesamiento masivo por lotes

Patrón validado en la migración SGI (2 049 archivos) el 14/10/2026. Sirve para cualquier corrida grande contra APIs externas.

**Nodo `Configuracion` al inicio**, con tres perillas:

| Parámetro | Para qué |
|-----------|----------|
| `SIMULAR` (true por defecto) | Corrida en seco: planifica y entrega el informe sin tocar ninguna API de escritura. **Siempre simular primero.** |
| `INICIO` / `CANTIDAD` | Piloto acotado (25) antes de la corrida real; `CANTIDAD: 0` = todo desde `INICIO` |
| Filtro de alcance (`MIGRAR_EXTENSIONES`, etc.) | Reducir el universo sin tocar la lógica |

**Bucle**: `splitInBatches` (10–25 por lote) con `.onEachBatch(...)` → `nextBatch(...)` y `.onDone(resumen)`. Dentro del lote, referenciar el ítem del lote con `$('Procesar por lotes').item`, no `$json`, porque los nodos HTTP y Postgres reemplazan el item.

**El `Resumen final` devuelve `proximoInicio` y `restantes`** para encadenar tandas a mano. Medido: ~5 s por archivo (conversión + subida); tandas de ~300 ≈ 25 minutos. Tandas largas sin punto de reanudación son una mala idea.

**Merge en modo `append` continúa con entradas vacías** (confirmado): sirve para consolidar resultados de ramas que a veces no producen nada (p. ej. "no hubo nada que borrar"). Es lo contrario del Merge `combine`, que sí necesita *Include Any Unpaired Items*.

**Reintentos solo donde el fallo es transitorio.** 3 reintentos en los nodos HTTP de red (subir, descargar, subir a Azure). En errores determinísticos (documento firmado, formato no soportado) los reintentos solo gastan tiempo: detectarlos y clasificarlos aparte.

**Serializar bien los errores.** Un `[object Object]` en el informe no es un error de la API: es el error del nodo anterior mal serializado. Usar `e.message ?? JSON.stringify(e)`.

## Método de diagnóstico por capas

Cuando un flujo falla contra una API con autenticación, **no teorizar: medir**. Un nodo Code que genere la lista de URLs y un solo HTTP Request con `fullResponse: true` y `neverError: true`, escalando de lo básico a lo que falla: identidad (`/me`), archivos (`/me/drive`), sitios (`/sites/root`), metadatos del recurso, la operación que falla, y **la misma operación sobre un recurso propio y trivial** — esa última decide si el recurso original es inocente.

**Segundo eje: cambiar de aplicación, no de recurso.** La misma llamada desde Graph Explorer con el mismo usuario. Si ahí funciona, el problema es el registro de la aplicación. Nunca pedir que peguen el token; solo los nombres de los scopes.

**Un registro en mal estado no se repara: se reemplaza.**

Flujo reutilizable: **DIAG - Credencial Microsoft Graph DDS** (`9rjLMmF5SI7F5Ojq`).

## Forense sobre la propia base de n8n

La instancia guarda sus ejecuciones en Postgres, accesibles con la credencial `Postgres account n8n`. Es la vía más rápida para auditar toda la instancia sin hacer clic en la UI. Construir un flujo `DIAG` desechable con nodos Postgres y un Code que formatee.

**Fallos por flujo:**
```sql
SELECT w.name, e.status, count(*), min(e."startedAt"), max(e."startedAt")
FROM execution_entity e JOIN workflow_entity w ON w.id = e."workflowId"
WHERE e."startedAt" > now() - interval '10 days' AND e.status <> 'success'
GROUP BY 1,2 ORDER BY 3 DESC;
```

**Nodo y mensaje del último fallo de cada flujo.** `execution_data.data` está en formato *flatted*: el elemento 0 es la raíz y cada valor no primitivo es un índice en texto hacia otra posición del arreglo. Se navega con saltos:
```sql
WITH j AS (SELECT e.id, d.data::jsonb AS a FROM execution_data d JOIN execution_entity e ON e.id = d."executionId" WHERE ...),
r AS (SELECT id, a, (a->0->>'resultData') AS i_rd FROM j),
r2 AS (SELECT id, a, CASE WHEN i_rd ~ '^[0-9]+$' THEN a->(i_rd::int) END AS rd FROM r),
r3 AS (SELECT id, a, (rd->>'lastNodeExecuted') AS i_node, (rd->>'error') AS i_err FROM r2)
SELECT CASE WHEN i_node ~ '^[0-9]+$' THEN a->>(i_node::int) END AS nodo, ... FROM r3;
```
Para clasificar el payload basta un `LIKE` sobre el texto crudo (`data LIKE '%"statuses"%'`), porque las claves sí quedan literales.

## El estado de n8n no es el estado del negocio

Un flujo puede cerrar en **success** sin haber hecho nada. Ocurre cuando la rama de fallo termina en un nodo que registra y no lanza error, y los nodos HTTP llevan `neverError: true` con `onError: continueRegularOutput`.

Caso real: DIR-09 llevaba **once días** sin escribir el Excel (`hoja_inaccesible`, 0 filas), y la lista de ejecuciones mostraba `success` en 2 segundos cada día. La verdad estaba en `dds_director.ejecucion_n8n`.

**Al diagnosticar, cruzar siempre las dos fuentes.** Y al diseñar: si el flujo hace algo que una persona debería mirar, que lo diga en los dos lados — `ok: false` y un `motivo` explícito que llegue a la bitácora.

**Límites de `get_execution` (MCP de n8n):**
- Metadata-only por defecto (`status`, timestamps). Con `includeData: true` sí trae el detalle por nodo (`runData`), y acepta `nodeNames` para filtrar y `truncateData` para acotar items — usarlo para leer el resultado de un nodo Postgres/Code puntual en vez de pedir todo el `runData`.
- Un `success` en ~15 ms para un flujo que debería llamar a Graph API es sospechoso (una llamada HTTP real tarda cientos de ms): lo más probable es que un Filter haya descartado el item antes de llegar al HTTP Request.
- **En ejecuciones con binarios grandes, `get_execution` cierra el stream y no se puede leer** (confirmado 14/10/2026), incluso con `includeData`. Los metadatos (inicio/fin) sí se leen. Por eso los flujos de procesamiento masivo deben dejar un nodo **`Resumen final` con un JSON consolidado**: es la única salida legible.
- Este servidor MCP no expone un tool de listado de ejecuciones — para confirmar de verdad hay que revisar la ejecución en la UI o probar con un caso real, no confiar en el `status: success` aislado.

**`execute_workflow` con `inputs.type: "webhook"` contra un WhatsApp Trigger — sin verificar (25/09/2026).** No quedó confirmado si el body simulado pasa por la lógica interna del nodo que desempaqueta el sobre de Meta (`entry[0].changes[0].value` → `$json` plano) o si se inyecta ya aplanado. Hasta confirmarlo, tratar esa simulación como **no concluyente** y validar con un mensaje real entrante.

**`execute_workflow` exige que el flujo esté publicado (activo)** — contra un workflow sin publicar devuelve `"has no published (active) version to execute"`. Para un flujo DIAG desechable de disparador manual, usar `test_workflow` con `executionMode: "manual"` en su lugar (requiere el parámetro `pinData`, aunque sea `{}`).

## El patrón del item vacío

Causa raíz de tres incidentes distintos en una sola sesión. `alwaysOutputData: true` hace que un nodo que devuelve cero resultados emita **un item vacío `{}`**, y la cadena sigue como si hubiera trabajo real.

- **Vencimientos de Solicitudes**: `Filtrar Vencidas` devolvía `[]` correctamente, pero la casilla resucitaba un item vacío; el HTTP siguiente armaba `https://graph.facebook.com/v21.0//messages` → 400. **342 ejecuciones en rojo en 4 días por no tener nada que hacer.**
- **DevBot v3**: un acuse de WhatsApp producía `phone: null` y reventaba contra un `NOT NULL`.
- **DIR-05**: la lectura vacía hacía estallar el informe con `Cannot read properties of undefined`.

**Regla:** el nodo que decide *"no hay nada que hacer"* NO debe llevar `alwaysOutputData`. Cero items detiene la cadena, y eso es la salida normal, no un error. Documentarlo dentro del propio nodo Code, que es donde alguien iría a marcar la casilla. (La guía genérica del SDK recomienda lo contrario: aquí no aplica.)

El reverso sigue vigente: sí ponerlo en nodos cuyo vacío es información que un nodo posterior debe evaluar. Un `SELECT EXISTS(...)` de Postgres siempre devuelve exactamente 1 fila, así que nunca necesita `alwaysOutputData`.

## WhatsApp: acuses de recibo vs mensajes

El WhatsApp Trigger suscrito a `messages` recibe **también los acuses** (`sent`, `delivered`, `read`). Meta los manda con `field: "messages"` pero el payload trae `statuses[]` y **no** `messages[]`.

Medido en el DevBot: **1 623 de 1 623 fallos eran acuses**, y el 80 % de todas las ejecuciones del bot. Cada mensaje que el bot envía genera entre 3 y 4 acuses, y cada uno ejecutaba el bot entero.

**Guarda obligatoria** justo después del trigger — nodo **Filter** (no IF: descarta sin dejar rama falsa):
```
{{ $json.messages?.[0]?.from }}   String → is not empty
```
Sin `alwaysOutputData`. `typeValidation: strict` no da problema: el operador `notEmpty` maneja bien el valor ausente.

## Guarda de autorización del canal de WhatsApp

Patrón para que un bot de WhatsApp solo atienda a personal de la empresa, validado en el DevBot el 29/08/2026.

**Dónde va:** después del nodo que clasifica la entrada (ya se conoce la ruta) y antes del switch que reparte (todavía no se ha escrito nada).

**Dos poblaciones.** El DevBot atiende empleados **y** candidatos de reclutamiento, que nunca estarán en `dim_persona`. Una lista blanca aplicada a todo rompe el flujo de reclutamiento en silencio. La ruta `reclutamiento` queda exenta: su autorización es el payload `rec_` que la empresa envió y que el subflujo valida contra Sie7e — autorización por payload, no por número.

**Normalización.** Los teléfonos llegan en formatos distintos. Misma regla que `normPhone`: 10 dígitos que empiezan en `3` → anteponer `57`; 13 dígitos que empiezan en `521` (México) → `52` + los últimos 10. Aplicarla **a los dos lados** de la comparación, dentro del SQL.

**El Merge es obligatorio.** Un nodo Postgres **reemplaza** `$json`, y el switch posterior lee `{{ $json.ruta }}`. Encadenar la autorización en línea deja sin contexto al switch y a todos sus subflujos. La solución es rama paralela + Merge `combine` / `combineByPosition`:
```
Clasificar Entrada ─┬───────────────────────→ Merge entrada 0
                    └→ Autorizar remitente ─→ Merge entrada 1
                                                 ↓
                                           ¿Autorizado?  →  switch / registrar
```
Prefijar **todas** las columnas del SQL con `auth_` para que el Merge no pise ningún campo del bot. Activar **Include Any Unpaired Items**: sin eso, si la consulta devolviera cero filas el bot muere en silencio en el Merge.

**Trampa de cableado:** el nodo clasificador necesita **dos** conexiones saliendo del mismo punto de salida (una al Merge, otra al nodo Postgres). Es fácil poner solo una; el síntoma es que el Merge devuelve `[]`, la ejecución cierra en `success` y n8n deja la pista `"source": [null, {...}]` más el hint de *Include Any Unpaired Items*.

**Modo sombra con un solo interruptor.** Conectar la salida *false* del IF **tanto** al nodo que registra **como** al switch. Mientras exista esa segunda conexión, registra sin bloquear. Para cerrar la llave, borrar esa única conexión. Antes de cerrarla, verificar la cobertura del directorio: en el DevBot, 20 de 25 números que ya usaban el bot estaban en `dim_persona`; los que faltaban eran personas reales de México.

**Silencio, no respuesta.** A un número no autorizado no se le contesta nada: responder confirma a un desconocido que hay un bot vivo. La visibilidad la da la tabla de auditoría, con `ON CONFLICT` que sube un contador en vez de crear filas.

## Anti-loop en flujos que monitorean un buzón y además envían correo

Si un flujo lee un buzón **y** manda notificaciones desde ese mismo buzón, se produce un loop infinito. Cuatro guardas obligatorias, todas:

1. `isReply` — el asunto empieza por RE/RV/FW.
2. `isNotification` — prefijo conocido que pone el propio flujo en el asunto.
3. `isSelfSent` — el remitente es el buzón monitoreado.
4. `alreadyProcessed` — deduplicación por `internetMessageId` en `staticData` (los flujos SGI guardan los últimos 200).

**Ojo con `staticData`: no persiste en ejecuciones manuales, solo en producción.** Durante las pruebas la deduplicación parecerá no funcionar. Y para dedup de **negocio** (no de auditoría de correo) no usar `staticData` en absoluto — ver *Dedupe y bitácora de pasos: cuándo Data Table y cuándo Postgres*.

Validar también el **dominio del remitente** contra una lista autorizada (`mectronics.co`, `grupoexpress.co` y relacionados), y cuando varios flujos escuchan el mismo buzón, que cada uno **excluya explícitamente los asuntos de los otros** (es lo que hace "Validar correo nuevo de hilo" del flujo de Infraestructura con el asunto del control de cambios SGI).

## Nunca dejar que un flujo borre trabajo humano

DIR-09 tenía un bloque de limpieza que vaciaba las filas sobrantes en el rango completo `A:Y`, columnas manuales incluidas. Al reducir la ventana del `WHERE` de 90 a 30 días, el sobrante saltó a **10 255 filas** y se llevó por delante los comentarios de los líderes y la columna con la única trazabilidad hacia el backlog. Hubo que restaurar el libro desde el historial de versiones de SharePoint.

Y no avisó, por un bug de una palabra: `limpieza.filas` no existía (la propiedad se creaba después, en el `.map()` final), así que `_limpio_sobrantes` salía `undefined` y el `if (... > 0)` del informe nunca se cumplía. **Cuanto más grande el borrado, más silencioso.**

Dos reglas que quedaron en el flujo:

1. La limpieza toca **solo las columnas que el flujo escribe**. Lo que llenan las personas no lo borra un robot, ni siquiera en filas fuera de alcance. Una nota huérfana confunde; una nota borrada no se recupera.
2. **Límite de seguridad.** Si el sobrante supera un umbral (1000 filas en DIR-09), no se borra nada y se reporta a gritos. Un sobrante así no significa que se cerraron mil ítems: significa que cambió el alcance de la consulta, y esa decisión es de una persona.

Corolario: si una restricción de la base (`NOT NULL`, `FK`) está frenando un flujo mal diseñado, **no relajarla**. En el DevBot, el `NOT NULL` de `phone_number` era lo único que impedía que el bot intentara enviar un menú a un destinatario nulo en cada acuse de recibo.

En almacenamiento productivo (Azure Blob) la versión equivalente de la regla: borrar solo lo que el flujo mismo reemplazó, en la misma ruta y solo con las extensiones previstas, y nunca antes de confirmar la escritura del reemplazo.

## Dependencias con ventana de disponibilidad

No todo fallo es un defecto. **Sie7e preproducción** (`programacionpre.mectronics.com.co`) solo está arriba **L-V, aproximadamente 07:50–19:15 hora de Bogotá**; entre 10:00 y 18:00 responde 36/36 sin un solo fallo. Medido con el histograma horario de REC-AI-02.

Consecuencia: un cron cada 5 minutos las 24 horas generó **717 de 1 107 ejecuciones fallidas** sin que nada estuviera roto. La corrección es la ventana en el cron (`*/5 8-18 * * 1-5`), no tocar la lógica.

**Y al revés:** un flujo agendado en el filo de la ventana falla de verdad. REC-03 corría a las 08:00 — la hora más inestable — y **3 de 4 recordatorios de entrevista no se enviaron**. Eso estaba enterrado entre miles de fallos de ruido. Al agendar contra una dependencia con ventana, apuntar al centro del horario, no al borde.

**Regla general:** antes de silenciar fallos repetitivos, medir el patrón por día y por hora. Si el flujo funciona perfecto cuando debe funcionar, el problema es el calendario. Y dentro de la ventana, dejar que falle en rojo: ahí un error sí significa algo.

## ON CONFLICT con predicado

`ON CONFLICT (columna) WHERE <predicado> DO UPDATE` exige un **índice único parcial** cuyo predicado esté implicado por el que se declara. Si no existe, Postgres devuelve `42P10`. Verificarlo contra el catálogo antes de acusar a la consulta:

```sql
SELECT i.relname, x.indisunique, (x.indpred IS NOT NULL) AS parcial, pg_get_indexdef(x.indexrelid)
FROM pg_index x JOIN pg_class i ON i.oid = x.indexrelid
WHERE x.indrelid = 'dds_director.alerta'::regclass;
```

En `dds_director.alerta` el índice **sí existe** (`ux_alerta_dedup`), así que ese INSERT no es sospechoso: un `veces_repetida` alto prueba que lleva corridas exitosas. Cuando un flujo reporta su propia alerta, **la alerta es el mensajero, no el muerto** — buscar el primer nodo que falla, no el último que informa.

## Dedupe y bitácora de pasos: Data Table de n8n vs Postgres

Pregunta recurrente al diseñar un flujo con estado entre ejecuciones ("¿ya se envió esto?", "¿en qué paso quedó?", sesión de un chatbot): ¿Data Table de n8n o una tabla en `dds_director`? Decidir esto **antes** de construir, no después de que `staticData` falle.

### Criterio de decisión

| Necesidad | Data Table de n8n | Postgres (`dds_director`) |
|---|---|---|
| Sesión de chatbot (TTL corto, un solo flujo la lee/escribe) | Preferir | — |
| Dedup o bitácora que debe sobrevivir a `update_workflow`, consultarse desde BI/Fabric, o cruzarse con otras tablas de negocio | — | Preferir |
| Ya existe una tabla o convención de Mectronics para ese dominio (`dds_director.*`) | — | Usar esa misma base; no crear un silo nuevo |
| Volumen alto, consultas con JOIN/agregación, o retención mayor a los ~10 días de ejecuciones de n8n | — | Preferir |
| Prototipo rápido sin esquema definido todavía | Preferir | — |

Regla práctica: si el estado solo le importa a un flujo y es efímero (sesión, caché corto) → Data Table. Si el estado es evidencia de que algo pasó en el negocio (ya se envió, ya se procesó, bitácora de pasos) → Postgres, siguiendo el patrón ya existente (`dds_director.alerta`, `dds_director.ejecucion_n8n`), no una Data Table aislada.

### Nunca usar `$getWorkflowStaticData` para dedup de negocio

Confirmado dos veces (28/08 y 26/10/2026): `$getWorkflowStaticData('global')` **no persiste de forma fiable en ejecuciones manuales**, solo en producción (disparador real) — y aun en producción, es memoria de instancia, no una fuente que un humano pueda auditar ni corregir si algo salió mal. Causó un **envío duplicado real** en "Novedades de Nómina DDS" (`WqwA7LKd7YtmmNg9`), detectado y corregido el 26/10/2026.

**Patrón de reemplazo validado**: dos tablas Postgres, una por nivel —

```sql
-- nivel período: "¿ya se completó este envío?"
CREATE TABLE dds_director.<proceso>_envio (
  envio_id BIGSERIAL PRIMARY KEY,
  periodo TEXT NOT NULL,
  estado TEXT NOT NULL CHECK (estado IN ('exitoso','error')),
  execution_id TEXT NOT NULL,
  detalle JSONB,
  creado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX ux_<proceso>_envio_periodo ON dds_director.<proceso>_envio (periodo) WHERE estado = 'exitoso';

-- nivel paso: bitácora de auditoría, una fila por paso ejecutado
CREATE TABLE dds_director.<proceso>_paso (
  paso_id BIGSERIAL PRIMARY KEY,
  execution_id TEXT NOT NULL,
  paso TEXT NOT NULL,
  resultado TEXT NOT NULL CHECK (resultado IN ('ok','error','omitido')),
  detalle JSONB,
  creado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

Verificación al inicio del flujo: `SELECT EXISTS (SELECT 1 FROM ..._envio WHERE periodo = $1 AND estado = 'exitoso')`. Registro al final: `INSERT ... ON CONFLICT (periodo) WHERE estado = 'exitoso' DO NOTHING RETURNING envio_id`. Ver *ON CONFLICT con predicado* para el índice único parcial que esto exige.

### No agregar una columna que el orden del flujo no puede poblar

La primera versión de `..._paso` incluía una columna `envio_id` con FK hacia `..._envio(envio_id)`, pensando en un join "más normalizado" que por texto. Pero los pasos intermedios del flujo (descarga, envío, marcado) se registran en nodos que corren **antes** de que exista ese `envio_id` — ese valor solo nace en el último nodo del flujo, el que inserta en `..._envio`. La columna quedó siempre NULL: una FK muerta, detectada y eliminada el 26/10/2026 (`ALTER TABLE ... DROP COLUMN envio_id`).

**Regla:** `execution_id` (NOT NULL en ambas tablas) ya resuelve el join entre pasos y envío sin depender del orden de ejecución. Antes de añadir una FK entre tablas de pasos/bitácora de un mismo proceso, preguntar en qué nodo exacto se va a poblar ese valor — si la respuesta es "en un nodo que corre después y aún no existe", esa columna no va.

### `options.queryReplacement` con más de un parámetro

**Error real**: `there is no parameter $3` en un INSERT con `$1, $2, $3`, en un nodo con `executeOnce: true`.

**Causa**: `queryReplacement` escrito como una mezcla de expresiones sueltas unidas por texto literal —
```
="{{ $execution.id }}", 'marcar_enviado', ={{ JSON.stringify($json) }}
```
— el nodo Postgres v2.6 no separa esto en 3 parámetros posicionales correctos.

**Formato correcto**: UNA sola expresión n8n que evalúe a un arreglo JS; cada elemento mapea a `$1, $2, $3...` en orden:
```
={{ [$execution.id, 'marcar_enviado', JSON.stringify($json)] }}
```
Validado con una inserción real exitosa (fila devuelta por `RETURNING`). Aplica a cualquier `executeQuery` de Postgres con más de un `$n` en `options.queryReplacement` — con un solo parámetro, `={{ [$json.campo] }}` también funciona y es más consistente que mezclar formatos.

## Autenticación NTLM (TFS / SSRS)

SSRS usa autenticación integrada de Windows (NTLM), confirmable por el encabezado `www-authenticate: NTLM` del 401. El nodo HTTP Request **no soporta NTLM**. Solución validada: script PowerShell con `Invoke-WebRequest -UseDefaultCredentials` en tarea programada bajo la cuenta de dominio, y n8n lee el archivo con Read/Write Files from Disk.

Exportar un reporte SSRS: `&rs:Format=EXCELOPENXML` más los parámetros; un parámetro nulo es `&Parametro:isnull=true`. Validar la descarga por tamaño y firma ZIP (`PK`).

## TFS REST API

- Autenticación **Basic Auth** (TFS on-prem en servidores propios de Azure, no Azure DevOps Services).
- **Crear work item**: `Content-Type: application/json-patch+json`, cuerpo en formato array PATCH.
- **Subir adjunto**: `Content-Type: application/octet-stream` con `bodyContentType: binaryData`.
- **Vincular adjunto**: PATCH separado al endpoint del work item con `rel: "AttachedFile"`.
- **Detección de duplicados en hilos de respuesta**: etiquetar los work items con `disciplinarios-{conversationId}`.

## Patrones de diseño validados

### 1. Referencia de nodos por nombre
`$('NombreNodo').item.json.campo`. El nodo más confiable está en la CADENA PRINCIPAL. Nunca confiar en `$json` después de un DataTable — ni después de un Postgres o un HTTP, que también reemplazan el item. En fan-in, `.first()`.

### 2. JSON.stringify para bodies dinámicos
Siempre `{{ JSON.stringify({...}) }}`. Nunca construir el JSON como string interpolado: los `\n` lo rompen. Lo mismo aplica a `queryReplacement` de Postgres con varios parámetros — ver *Dedupe y bitácora de pasos*.

### 3. WhatsApp mensajes interactivos
`list` (hasta 10 opciones), `button` (máximo 3), `text`. Requieren HTTP Request directo a Graph API de Meta.

### 4. Máquina de estados con Data Table
Una fila por usuario, `session_state`, `last_activity` para timeout, upsert por `phone_number`, delete al finalizar. Ver *Dedupe y bitácora de pasos* para cuándo esto es Data Table y cuándo debe ser Postgres.

### 5. raw_message pattern
Guardar `JSON.stringify($json.messages[0])` en un Set temprano. Ojo: sobre un acuse de recibo eso produce `{}` — ver la sección de acuses.

### 6. alwaysOutputData solo donde el vacío es información
Ver *El patrón del item vacío*. En el nodo que decide que no hay trabajo, apagado.

### 7. Normalizador de filas de Extract from File
El nodo entrega un item por fila con una sola clave `row`. Usar normalizador defensivo:
```js
const filasDe = (nombre) => $(nombre).all().map(i => {
  const v = i.json;
  if (Array.isArray(v)) return v;
  if (Array.isArray(v.row)) return v.row;
  const ks = Object.keys(v);
  if (ks.length === 1 && Array.isArray(v[ks[0]])) return v[ks[0]];
  return ks.map(k => v[k]);
});
```

### 8. Guarda de encabezados antes de escribir por índice de fila
Verificar que el encabezado esperado esté donde debe. Lanzar excepción explícita es preferible a corromper datos.

### 9. Reportar anomalías en vez de propagarlas
Acumular los datos sospechosos en un arreglo `alertas` de la salida en vez de incluirlos en el entregable. En corridas masivas, separar por tipo (`errores`, `requierenConversionManual`, `omitidos`) y **acotar cada lista** (100–200 elementos) para que el resumen siga siendo legible.

### 10. Colores y formatos de Excel
Los porcentajes con formato `[$-010409]0"\\"%` se leen como `3500` en vez de `35`. Verde de "enviado": `#A9D08E`.

### 11. Merge para conservar el contexto
Cuando haga falta consultar la base a mitad de una cadena sin perder el item original: rama paralela + Merge `combineByPosition`, con las columnas nuevas prefijadas. Ver *Guarda de autorización*.

### 12. Índice en disco en vez de recorrer un share
n8n corre como LocalSystem y no ve rutas UNC. Patrón: una tarea programada de Windows bajo cuenta de dominio hace `robocopy` del share a un espejo local **sin purge** y genera un `indice.json` (campos por archivo: `nombre, extension, rutaRelativa, rutaCompleta, rutaLocal, enEspejo, tamanoBytes, modificadoUtc`; raíz con `generadoUtc` y `archivos`). El flujo lee solo el JSON. Verificar siempre que la tarea esté corriendo: un índice viejo produce `no_encontrado` sin que nada falle.

### 13. Coincidencia por código de documento
Normalizar (sin tildes, mayúsculas, `_` y espacios → `-`) y exigir que el nombre **sea** el código o **empiece por el código seguido de un carácter no alfanumérico** — así `MF-153` no arrastra `MF-1530`. Poner un techo de coincidencias (40) que corta y reporta en vez de copiar de más. Limitación conocida: la regex `^[A-Z]{1,4}(?:-[A-Z]{1,4})?-\d{1,4}` no reconoce códigos sin número (`C-GFN`).

### 14. Diseño de columnas de dedup/bitácora: poblar en el momento correcto
Antes de añadir una columna o FK a una tabla de dedup/bitácora, trazar en qué nodo exacto del flujo se va a conocer ese valor. Si el valor nace en un nodo que corre **después** del que necesita escribirlo, esa columna no se puede poblar y queda muerta (ver *Dedupe y bitácora de pasos*, caso `envio_id`). El join entre niveles (paso ↔ envío) se resuelve con un campo que **sí** existe desde el primer nodo — típicamente `execution_id` — no con la clave generada al final.

## Errores comunes y soluciones

| Error | Causa | Solución |
|-------|-------|----------|
| `Bad control character in string literal in JSON` | `\n` en texto interpolado | `JSON.stringify()` del body completo |
| `The parameter to is required` / `to: null` | Referencia a nodo que perdió contexto | Referenciar un nodo de la cadena principal |
| URL con doble barra (`/v21.0//messages`) → 400 | Item vacío por `alwaysOutputData` | Quitar la casilla del nodo que decide |
| `null value in column ... violates not-null` en un bot de WhatsApp | Acuse de recibo tratado como mensaje | Filter `messages?.[0]?.from` tras el trigger |
| `Resource not found` (404) en AI Foundry | URL de endpoint incorrecta | Usar el Endpoint (Responses) del agente |
| `API version not supported` | api-version en la URL | El endpoint v1 no lo lleva |
| `Access to the file is not allowed. Allowed paths: ...` | Ruta fuera de `N8N_RESTRICT_FILE_ACCESS_TO` | Agregar la ruta y **reiniciar n8n** |
| Ruta UNC inaccesible | n8n corre como LocalSystem | Espejo/índice local por tarea programada |
| `items is not defined` en nodo Code | El task-runner aislado no expone la variable legacy | Usar `$input.all()` |
| Binario corrupto al subir desde un nodo Code | El sandbox no soporta Buffers en `httpRequest` | `prepareBinaryData` + nodo HTTP nativo con `binaryData` |
| `FileOpenUserUnauthorized` (401) en `/workbook` | Token sin capacidad WAC — el registro de la app | Diagnóstico por capas; registro nuevo |
| `EditModeCannotAcquireLockTooManyRequests` (429) | Contención del candado de edición | **Sesión de libro persistente**; el batching del nodo no basta |
| `Open navigation properties are not supported on OpenTypes` | `/workbook/...` sobre una URL que no es de driveItem | Revisar que sea `/drives/{drive}/items/{item}/workbook/...` |
| 400 BadRequest en `/messages/{id}/attachments` | `$select` con `contentBytes` | Llamar sin `$select` |
| `InvalidMetadata` al subir a Azure Blob | Tildes en `binary.data.fileName` → header `Content-Disposition` inválido | Forzar `fileName` ASCII en el Code que prepara la subida |
| `The required blob doesn't match any existing one` | El blob a borrar no existía | Es un 404: clasificarlo como *no existía*, no como error |
| `PPTCannotOpenDocumentSigned` / `UnsupportedMediaType` en Graph | Presentación firmada digitalmente | Determinístico: no reintentar, exportar a PDF a mano |
| `[object Object]` en un informe | Error del nodo anterior mal serializado | `e.message ?? JSON.stringify(e)` |
| `42P10` en `ON CONFLICT ... WHERE` | Falta el índice único parcial | Verificar `pg_index` antes de tocar la consulta |
| `there is no parameter $N` en un nodo Postgres | `queryReplacement` con expresiones sueltas y texto literal en vez de un arreglo | Una sola expresión `={{ [v1, v2, ...] }}` — ver *Dedupe y bitácora de pasos* |
| Merge devuelve `[]` y la ejecución cierra en success | Una entrada del Merge sin conexión | Revisar `source: [null, ...]` en la ejecución |
| Un flujo con webhook deja de recibir tras un cambio | `update_workflow` regeneró el `webhookId` | Editar esos flujos a mano |
| Nodos HTTP sin credencial tras un cambio | `update_workflow` las borra | Reasignar a mano (p. ej. "Microsoft Graph DDS" en los 3 nodos) |
| `get_execution` no devuelve detalle / corta | Ejecución con binarios grandes, o se llamó sin `includeData` | Pasar `includeData: true` (y `nodeNames`/`truncateData` si aplica); con binarios grandes, leer el JSON del nodo `Resumen final` |
| Deduplicación por `staticData` que no deduplica | Ejecución manual, o dedup de negocio mal resuelta | `staticData` solo persiste en producción; para dedup de negocio usar tablas Postgres, no `staticData` |
| `invalid_grant` contra Sie7e | Preproducción fuera de su ventana | Ajustar el cron, no la lógica |
| `$execution.mode === 'manual'` nunca es cierto | Los valores reales son `'test'` y `'production'` | Usar `$execution.mode !== 'production'` |
| `execute_workflow` responde "has no published (active) version" | El flujo no está publicado | Usar `test_workflow` (`executionMode: "manual"`, con `pinData`) para flujos DIAG desechables |

## SDK Reference

Fuente autoritativa: `get_sdk_reference` del MCP de n8n (o el recurso `n8n://workflow-sdk/reference`). Resumen local en `references/sdk-reference.md`. Notas prácticas:

- `sticky('contenido', nodos?, config?)` — el contenido va como primer argumento, no dentro de `config.parameters`.
- Los avisos `INVALID_EXPRESSION_PATH` de `validate_workflow` son **falsos positivos** cuando las expresiones referencian campos que solo existen en tiempo de ejecución.
- `expr()` con comillas simples o dobles, **nunca** backticks; todo lo dinámico (`$json`, `$()`, `$now`) va **dentro** de `{{ }}`. Esto incluye `options.queryReplacement` de Postgres: va como una sola expresión de arreglo, nunca como texto con comas literales entre fragmentos `{{ }}` — ver *Dedupe y bitácora de pasos*.
- `workflow(id, name)` exige ambos como string — un `create_workflow_from_code` sin `id` definido falla con *"requires (id: string, name: string)"*; para un flujo nuevo pasar un id de texto corto (ej. `'diag-mi-caso'`), n8n lo usa solo como hint.
- Bucles: `splitInBatches(...).onEachBatch(x.to(nextBatch(sib))).onDone(resumen)`.
- **La recomendación genérica del SDK de poner `alwaysOutputData: true` en nodos que pueden devolver 0 items no aplica aquí**: ver *El patrón del item vacío*.

## Flujo de trabajo para nuevas automatizaciones

1. **Entender el requerimiento** y no asumir. Confirmar de dónde sale cada dato.
2. **Simplificar el proceso antes de automatizarlo.** No automatizar una ineficiencia.
3. **Diseñar la arquitectura** y validarla con el usuario antes de construir. Si el diseño incluye estado entre ejecuciones (dedup, sesión, bitácora de pasos), decidir Data Table vs Postgres con el criterio de *Dedupe y bitácora de pasos* — nunca `staticData` para algo que importa al negocio.
4. `search_nodes` + `get_node_types` con TODOS los nodos previstos. No adivinar nombres de parámetros.
5. **Validar con `validate_workflow`** antes de crear o actualizar.
6. **Crear** con `create_workflow_from_code`, con `description` corta.
7. **Avisar qué credenciales hay que asignar** — y si el flujo tiene un trigger con webhook, no reescribirlo.
8. **Probar por partes**, deshabilitando los nodos con efectos irreversibles; en corridas masivas, simular primero y luego un piloto acotado.
9. **Publicar** con `publish_workflow`. Un flujo que toca producción no se publica hasta cerrar las pruebas.

## Cómo depurar cuando algo "que funcionaba" deja de funcionar

1. Preguntar **qué más se rompió**. Si varios flujos cayeron el mismo día, el problema es compartido.
2. Preguntar **qué cambió**, incluyendo los cambios propios de la sesión anterior.
3. **Medir antes de teorizar.** Barrido SQL sobre `execution_entity` y `execution_data`, y flujo de diagnóstico por capas.
4. **Descartar con evidencia, no con razonamiento.** Cada hipótesis necesita una prueba que la mate.
5. Cuando una hipótesis se cae, **decirlo explícitamente** y no arrastrarla. En la sesión del 29/08 se cayeron las dos hipótesis iniciales — el `ON CONFLICT` y la credencial sin migrar — y la causa real era otra.
6. **Distinguir el mensajero del muerto.** El nodo que reporta la alerta rara vez es el que falla.
7. **Leer el código del nodo de n8n cuando el error no tiene sentido.** El `InvalidMetadata` de Azure se resolvió así: el nodo armaba un header HTTP con el nombre del archivo.
8. **No pedir cambios de seguridad para restaurar algo que funcionaba.**
9. Si la corrida está en riesgo, **entregar el resultado parcial** mientras se resuelve la causa raíz.
10. **Probar lo que se entrega.** Correr el SQL en un banco de pruebas antes de pegarlo en un flujo de producción, y verificar el cambio con datos pineados o con la ejecución real antes de darlo por bueno.

## Historial de cambios del skill

- **26/10/2026** — Nueva sección *Dedupe y bitácora de pasos: Data Table de n8n vs Postgres*, con criterio de decisión, patrón de dos tablas (`_envio` + `_paso`) que reemplaza `$getWorkflowStaticData` para dedup de negocio (caso real: envío duplicado en "Novedades de Nómina DDS"), la corrección de `options.queryReplacement` con varios parámetros (`={{ [v1, v2, ...] }}`, no expresiones sueltas con comas), y la regla de no añadir columnas/FK que el orden del flujo no puede poblar (caso `envio_id`). Añadido también: `get_execution` requiere `includeData: true` para el detalle por nodo; `execute_workflow` exige flujo publicado (usar `test_workflow` con `pinData` para DIAG); `workflow(id, name)` del SDK exige ambos argumentos como string.
- **21/10/2026** — Descripción reescrita como criterio de activación (antes era un changelog). Añadido: Azure Blob Storage (`InvalidMetadata` por tildes, texto real del 404 de borrado, reemplazo seguro de originales), conversión Office→PDF con Graph y `PPTCannotOpenDocumentSigned`, procesamiento masivo por lotes (simulación/piloto/tandas), manejo de binarios en el sandbox de n8n, anti-loop en flujos de correo, TFS REST API, índice en disco por LocalSystem, límites de `get_execution` con binarios, tabla de flujos de referencia.
- **14/10/2026** — Flujos SGI (`AsWgVjQYykkZRywt`, `Uv4GRV2J6IZQVQHC`) y los hallazgos de sus pilotos.
- **25/09/2026** — WABA real, suscripción aditiva de apps, guarda por `phone_number_id`.
- **29/08/2026** — Sesión de libro persistente (sustituye la receta de batching), `webhookId` regenerado por `update_workflow`, guarda de autorización.