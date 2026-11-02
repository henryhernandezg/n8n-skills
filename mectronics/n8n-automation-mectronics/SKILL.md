---
name: "n8n-automation-mectronics"
description: "Usar siempre que se trabaje con n8n en Mectronics S.A. / Grupo Express (https://n8n.mectronics.com.co): crear, modificar, validar, probar, depurar o desplegar workflows; diagnosticar un flujo que falla o que cierra en success sin hacer nada; o ayudar a una persona de cualquier área a automatizar una tarea de su trabajo sin saber de n8n (modo guiado: Claude construye, publica y verifica el flujo con la persona; si el MCP falla, guía la carga manual). Incluye infraestructura, credenciales y patrones validados (WhatsApp, Outlook, Graph, Azure Blob/AI Search, Postgres, TFS, AI Foundry) más las guías oficiales de n8n."
---

# n8n — Mectronics

Una sola skill para todo lo de n8n en Mectronics. Tiene tres capas:

1. **Conocimiento propio** (`references/mectronics/`): infraestructura, credenciales, restricciones y patrones medidos en producción.
2. **Guías oficiales de n8n** (`references/oficial/`): buenas prácticas genéricas del equipo de n8n, copiadas sin modificar.
3. **Modo guiado** (`references/agente/`): protocolo para que personas sin conocimiento técnico automaticen tareas de su puesto: Claude lo construye, lo publica y lo verifica con ellas. Incluye plan B si el MCP no responde.

## 1. Elegir el modo (primer paso, siempre)

| Modo | Cuándo | Qué hace Claude |
|------|--------|-----------------|
| **Técnico (DDS/TI)** | La persona es del equipo de desarrollo o TI, o pide algo técnico explícito (IDs de flujo, SDK, depurar, infraestructura, credenciales) | Trabaja como siempre: lee `references/mectronics/infraestructura-y-patrones.md` y las guías oficiales que apliquen. Puede publicar con confirmación. |
| **Guiado (usuario final)** | La persona describe una tarea de su trabajo en lenguaje de negocio, o dice que no sabe de n8n | Sigue `references/agente/guiado.md`. Lenguaje simple. Construye, prueba, **publica con la confirmación de la persona** (Nivel 1 y 2) y verifica con un caso real. Nivel 3 lo hace DDS. Si el MCP falla: `sin-mcp.md`. |

Si hay duda, preguntar una sola vez: *"¿Eres del equipo de desarrollo/TI, o es una tarea de tu área que quieres automatizar?"*

El modo lo declara la persona. Lo que Claude puede tocar en n8n lo define el usuario de n8n de cada persona; la skill añade reglas de conducta encima (ver `references/agente/riesgo.md`).

## 2. Orden de prioridad cuando hay conflicto

1. Lo que la persona pide en el chat (salvo que viole las reglas no negociables o su nivel de riesgo).
2. Esta skill y `references/mectronics/` — medido en producción en Mectronics.
3. Guías oficiales en `references/oficial/`.
4. Herramientas MCP en vivo (`get_node_types`, `get_workflow_sdk_reference`) para nombres y formas de parámetros: si contradicen una guía, manda la herramienta.
5. Lo que el modelo "recuerda" de n8n: último; está desactualizado con frecuencia.

## 3. Mapa de archivos

| Archivo | Cuándo leerlo |
|---------|---------------|
| `references/mectronics/infraestructura-y-patrones.md` | **Antes de construir o modificar cualquier flujo** que toque servidor, credenciales, WhatsApp, Outlook, Graph, Azure, Postgres, TFS o AI Foundry. Incluye restricciones de `update_workflow`, patrones y tabla de errores. |
| `references/sdk-reference.md` | Escribir código del SDK de workflows |
| `references/agente/guiado.md` | Modo guiado: pasos, de entender la tarea a publicar y verificar |
| `references/agente/riesgo.md` | Clasificar la tarea en Nivel 1/2/3 y saber quién la construye y publica |
| `references/agente/solicitud-y-revision.md` | Autoverificación antes de publicar, ficha de registro y revisión de DDS para Nivel 3 |
| `references/agente/ejemplo-correo-a-excel.md` | Caso completo: correos de la bandeja de la persona → filas en un Excel de SharePoint |
| `references/agente/sin-mcp.md` | El MCP no responde: entregar el flujo como archivo y guiar la carga y publicación en la UI |
| `references/agente/casos.md` | Ejemplos de tareas frecuentes y su nivel de riesgo |
| `references/oficial/UPSTREAM.md` | Origen, commit y fecha de las guías oficiales |

## 4. Guías oficiales: dónde está cada una

Los textos oficiales dicen "invoca la skill X con la herramienta Skill". Aquí no hay skills separadas: **leer el archivo indicado** (misma regla: leerlo antes de actuar, aunque ya se haya leído antes en la sesión).

| Nombre oficial | Archivo | Leer cuando |
|----------------|---------|-------------|
| `using-n8n-skills-official` | `references/oficial/using-n8n-skills-official/GUIA.md` | Al empezar: reglas transversales y resumen de todas las herramientas MCP |
| `n8n-workflow-lifecycle-official` | `references/oficial/n8n-workflow-lifecycle-official/GUIA.md` | Diseñar, organizar, validar, probar y publicar un flujo |
| `n8n-node-configuration-official` | `references/oficial/n8n-node-configuration-official/GUIA.md` | Configurar cualquier nodo |
| `n8n-expressions-official` | `references/oficial/n8n-expressions-official/GUIA.md` | Expresiones `{{ }}`, fechas, errores de expresión |
| `n8n-code-nodes-official` | `references/oficial/n8n-code-nodes-official/GUIA.md` | Antes de usar un nodo Code |
| `n8n-loops-official` | `references/oficial/n8n-loops-official/GUIA.md` | Lotes, paginación, "para cada" |
| `n8n-subworkflows-official` | `references/oficial/n8n-subworkflows-official/GUIA.md` | Reutilizar lógica, flujos de más de ~10 nodos |
| `n8n-error-handling-official` | `references/oficial/n8n-error-handling-official/GUIA.md` | Webhooks, producción, fallos que no deben ser silenciosos |
| `n8n-credentials-and-security-official` | `references/oficial/n8n-credentials-and-security-official/GUIA.md` | Cualquier autenticación o secreto |
| `n8n-binary-and-data-official` | `references/oficial/n8n-binary-and-data-official/GUIA.md` | Archivos, imágenes, adjuntos |
| `n8n-data-tables-official` | `references/oficial/n8n-data-tables-official/GUIA.md` | Data Tables, deduplicación, estado |
| `n8n-debugging-official` | `references/oficial/n8n-debugging-official/GUIA.md` | Algo no funciona |
| `n8n-ai-nodes-official` | `references/oficial/n8n-ai-nodes-official/GUIA.md` | IA dentro de un flujo: AI Agent node, clasificadores, RAG, chatbots |
| `n8n-agents-official` | `references/oficial/n8n-agents-official/GUIA.md` | Agentes de n8n (primero comprobar que la instancia los ofrezca) |
| `n8n-extending-mcp-official` | `references/oficial/n8n-extending-mcp-official/GUIA.md` | Exponer un flujo como herramienta del agente |

## 5. Reglas que prevalecen sobre las guías oficiales

Las guías oficiales asumen n8n Cloud o planes de pago. Mectronics es Community autoalojado (2.18.7, Windows, LocalSystem). Donde choquen, gana esta tabla:

| La guía oficial dice | En Mectronics |
|----------------------|---------------|
| Preferir "Gateway credits" si no hay preferencia de credencial | **No aplica** (solo n8n Cloud). Usar las credenciales de la tabla de infraestructura. |
| Configuración con `$vars` (planes de pago) | No hay `$env` ni `$vars` con la licencia actual. Configuración en un nodo Set/Code inicial `Configuracion`; estado entre ejecuciones en Postgres o Data Table según el criterio de *Dedupe y bitácora de pasos*. |
| Un Set que alimenta 0 o 1 consumidor es antipatrón | El nodo `Configuracion` inicial **sí se permite**: alimenta a varios y sustituye a `$vars`. |
| Corregir un flujo publicado con `update_workflow` y luego `publish_workflow` | `update_workflow` reemplaza el flujo completo y **regenera el `webhookId`**: los flujos con WhatsApp Trigger, Webhook o Form se editan **solo a mano en la UI**. Los nodos HTTP pierden la credencial: reasignarla tras cada update. |
| `newCredential('Etiqueta')` es cosmético; n8n asigna la credencial más reciente del tipo | Correcto, y aquí es un riesgo real: hay 3 credenciales de Outlook y 3 de WhatsApp. Verificar nodo por nodo en la UI cuál quedó asignada (la API no lo dice). |
| `alwaysOutputData` en un Get seguido de IF | Solo donde el vacío es información. El nodo que decide "no hay nada que hacer" **no** lo lleva (*patrón del item vacío*). |
| Execute Command y File Read/Write como I/O sin credencial | Execute Command está **deshabilitado**. Archivos locales: tarea programada de Windows + Read/Write Files from Disk, dentro de `N8N_RESTRICT_FILE_ACCESS_TO`. |
| Crear carpetas por MCP | Requiere instancia registrada (gratis, en Ajustes). Si faltan las herramientas de carpeta, pedir a DDS que registre la instancia o usar un prefijo en el nombre del flujo. |
| `save_user_preference`, Agents de n8n y otras herramientas "tras bandera" | No confirmado en esta instancia. Comprobar que la herramienta exista antes de planear sobre ella; si no existe, seguir sin ella. |
| El Code node es último recurso | Se mantiene. Excepciones validadas aquí: binarios (`prepareBinaryData`), diagnóstico, agregación multi-fuente. |

## 6. Reglas no negociables (ambos modos)

1. **Leer la guía antes de actuar**, no solo antes de llamar al MCP: antes de escribir código del SDK, configurar un nodo, diseñar o conectar.
2. **Validar y además verificar**: `validate_workflow` y luego `get_workflow_details` tras cada create/update para revisar `connections`.
3. **Ningún secreto en campos de texto ni en el chat.** Siempre credenciales de n8n.
4. **No usar `update_workflow` sobre flujos con webhook/WhatsApp/Form** (ver sección 5).
5. **Probar es ejecutar**: `test_workflow` fija disparadores, nodos con credencial y HTTP, pero **Data Tables, sub-workflows (Execute Workflow), File Read/Write y Code que toque estado externo corren de verdad**. Avisar y pedir confirmación antes si alguno aplica.
6. **Un robot no borra trabajo humano**: la limpieza toca solo las columnas que el flujo escribe, con límite de seguridad.
7. **Hecho vs supuesto**: si algo no está confirmado en esta instancia, decirlo.
8. **Un flujo que cierra en success no prueba que hizo algo**: diseñar `ok: false` y `motivo` visibles en la bitácora, y verificar el resultado en el sistema de destino con un caso real.
9. **Los flujos de usuarios usan credenciales de la propia persona.** Nunca las compartidas de DDS (Outlook DDS, Disciplinarios, Infraestructura, Graph DDS, WhatsApp, Azure, Postgres, TFS).
10. **Si el MCP falla, no inventar**: reintentar una vez (buscando antes si ya se creó), decirlo y seguir `references/agente/sin-mcp.md`.

## 7. Mantenimiento

- Las guías oficiales se regeneran con `mectronics/sync-oficial.sh` (rama `mectronics/skill-unica` del fork `henryhernandezg/n8n-skills`) tras traer cambios de `n8n-io/skills`. Revisar el diff antes de aceptar; revisión sugerida: trimestral.
- `references/mectronics/infraestructura-y-patrones.md` es el contenido anterior de esta skill, **sin cambios** (mismo hash). Todo aprendizaje nuevo de producción se agrega ahí, con fecha, y debe ir en su "Historial de cambios".
- Licencia de las guías oficiales: Apache 2.0 (`references/oficial/LICENSE`).

## Historial de cambios de esta skill

- **01/11/2026 (2)** — El modo guiado pasa a publicar: Claude construye, prueba, publica con confirmación de la persona y verifica con un caso real (Nivel 1 y 2); Nivel 3 sigue en DDS. Nuevas guías: `ejemplo-correo-a-excel.md` (con el requisito de permisos de correo en Entra, que no figura en la infraestructura documentada) y `sin-mcp.md` (carga manual del flujo si el MCP falla). Credenciales de usuario siempre propias.
- **01/11/2026** — Skill única: se incorporan las 14 guías oficiales de n8n-io/skills (commit `ba099d8`, 17/10/2026) como referencias, se añade el modo guiado para usuarios finales (niveles de riesgo, solicitud y revisión por DDS) y la tabla de reglas Mectronics que prevalecen. El contenido anterior se conserva íntegro en `references/mectronics/`.
