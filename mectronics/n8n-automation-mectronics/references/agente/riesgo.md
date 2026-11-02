# Niveles de riesgo

Clasificar **antes de construir**, decirlo a la persona y volver a clasificar si la tarea cambia. Ante la duda, el nivel más alto.

## Quién puede publicar

| Parámetro | Valor |
|-----------|-------|
| `PUBLICA_USUARIO_FINAL` | `true` para Nivel 1 y 2 |
| Nivel 3 | Lo construye y publica DDS |
| `CARPETA_BORRADORES` | `USR-Borradores` (si no hay herramientas de carpeta, solo el prefijo `USR-`) |

Publicar requiere siempre la confirmación expresa de la persona y los pasos 8 y 9 de `guiado.md`.

## Niveles

| Nivel | Qué hace la automatización | Ejemplos | Quién construye y publica |
|-------|----------------------------|----------|---------------------------|
| **1 — Bajo** | Solo lee o calcula y avisa a la propia persona. No escribe en ningún sistema. | Recordatorio semanal por correo a sí misma; resumen de un Excel propio enviado a su correo | La persona con Claude |
| **2 — Medio** | Escribe en archivos o tablas de su área, envía correos a otras personas, corre con frecuencia alta o usa nodos de IA. | Pasar datos de correos de su bandeja a un Excel de SharePoint; avisar a un equipo de pendientes | La persona con Claude |
| **3 — Alto** | Puede afectar sistemas compartidos o producción, a clientes o a datos personales. | WhatsApp (plantillas, clientes, webhooks); borrar o reemplazar archivos o datos; Azure Blob / AI Search; TFS; escritura en SIEF / Sie7e / bases productivas; nómina, RR. HH., disciplinarios, financieros; cualquier flujo con webhook o trigger externo | **DDS** |

Por qué el Nivel 3 queda en DDS: WhatsApp comparte una misma cuenta entre varios bots, los índices y blobs de Azure los consumen otros sistemas, y `update_workflow` sobre un flujo con webhook lo deja mudo sin error. Son riesgos técnicos de la plataforma, no de confianza en la persona.

Señales que suben a Nivel 3 sin discutir: datos de personas o de dinero, mensajes a clientes o externos, borrado, webhook, o una credencial de WhatsApp, Azure o TFS. Si la bandeja de la persona contiene correos de nómina, disciplinarios o financieros, filtrarlos fuera o pasar a Nivel 3.

## Qué puede y qué no puede hacer Claude en modo guiado

| Puede | No puede |
|-------|----------|
| Buscar nodos y leer guías | Tocar flujos que no sean los `USR-` de esa persona |
| Crear, validar, probar y **publicar** flujos Nivel 1 y 2 de la persona (con su confirmación) | Construir ni publicar Nivel 3 |
| Revisar ejecuciones de sus propios flujos | Usar credenciales compartidas de DDS |
| Despublicar sus propios flujos si la persona lo pide | Crear credenciales ni recibir secretos |
| Preparar la ficha de registro o de solicitud | `update_workflow` sobre flujos con webhook / WhatsApp / formulario |

## Límite real

Lo que Claude puede tocar en n8n lo define el usuario de n8n de cada persona. La skill añade reglas de conducta encima, pero no las sustituye. Si al listar flujos o credenciales aparecen elementos de otras personas o de DDS, no usarlos ni modificarlos y avisar a DDS.
