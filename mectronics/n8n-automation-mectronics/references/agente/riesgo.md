# Niveles de riesgo — autonomía proporcional al riesgo

Clasificar **antes de construir**, decirlo a la persona y volver a clasificar si la tarea cambia. Ante la duda, el nivel más alto.

## Parámetros que decide DDS

| Parámetro | Valor | Significado |
|-----------|-------|-------------|
| `PUBLICA_USUARIO_FINAL` | `false` | Solo DDS publica. Cambiarlo es una decisión de gobierno de DDS; esta skill no lo cambia por su cuenta. |
| `SIMULAR_POR_DEFECTO` | `true` | Todo borrador nace con `SIMULAR = true`. |
| `CARPETA_BORRADORES` | `USR-Borradores` | Si no hay herramientas de carpeta, usar solo el prefijo `USR-` en el nombre. |

## Niveles

| Nivel | Qué hace la automatización | Ejemplos | Quién construye | Quién revisa y publica |
|-------|----------------------------|----------|-----------------|------------------------|
| **1 — Bajo** | Solo lee o calcula y avisa a la propia persona. No escribe en ningún sistema. Sin datos sensibles. | Recordatorio semanal por correo a sí misma; resumen de una hoja de Excel propia enviado a su correo | Agente en modo guiado (borrador) | DDS con la lista corta; publica DDS |
| **2 — Medio** | Escribe en archivos o tablas del área, envía correos a otras personas o a un grupo, corre con frecuencia alta o usa nodos de IA. | Consolidar archivos de un área en una carpeta; avisar a un equipo de pendientes; clasificar correos con IA | Agente en modo guiado (borrador) | DDS con la lista completa y una prueba controlada; publica DDS |
| **3 — Alto** | Toca clientes, datos personales o sistemas productivos, borra o reemplaza información, o recibe llamadas desde fuera. | WhatsApp (plantillas, clientes, webhooks); borrar o reemplazar archivos o datos; Azure Blob / AI Search; TFS; escritura en SIEF / Sie7e / bases productivas; nómina, RR. HH., disciplinarios, financieros; cualquier flujo con webhook o trigger externo | **DDS** (el agente solo documenta la solicitud) | DDS |

Regla de escalamiento: si aparece cualquiera de estas señales, sube a Nivel 3 sin discutir — datos de personas o de dinero, mensajes a clientes o externos, borrado, webhook, o una credencial de WhatsApp, Azure o TFS.

## Qué puede y qué no puede hacer el agente en modo guiado

| Puede | No puede |
|-------|----------|
| Buscar nodos y leer guías | `publish_workflow`, `unpublish_workflow`, `archive_workflow` |
| Crear flujos **nuevos** con prefijo `USR-` en borrador | Editar, mover o archivar flujos que no creó esa misma persona |
| `validate_workflow` y `get_workflow_details` de sus propios flujos | `execute_workflow` en real |
| `test_workflow` con `pinData` en flujos sin efectos reales | Crear o editar credenciales; pedir o recibir secretos |
| Preparar la ficha de solicitud para DDS | Construir Nivel 3 |

## Advertencia de gobierno (para DDS)

Las restricciones de esta tabla son una norma de conducta de la skill. **No sustituyen un control de acceso.** Mientras la conexión MCP de un usuario final tenga permisos amplios en n8n, un uso incorrecto o una instrucción maliciosa podría tocar más de lo debido. Antes de abrir el modo guiado a más personas, DDS debería decidir una de estas dos opciones:

1. **Modo asistido** (más seguro, sin cambios de infraestructura): el usuario final no conecta n8n; Claude solo diseña, genera el código del flujo y la ficha, y DDS lo carga y lo prueba.
2. **Modo directo**: cada usuario conecta con un usuario/token de n8n de permisos reducidos. Verificar qué permite realmente la edición Community con roles limitados antes de confiar en esto.

Esta skill funciona igual en ambos; la diferencia es quién ejecuta las llamadas al MCP.
