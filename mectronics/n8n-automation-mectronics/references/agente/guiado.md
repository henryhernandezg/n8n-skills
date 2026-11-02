# Modo guiado — automatizar tareas del puesto de trabajo

Para personas que conocen su trabajo pero no n8n. El objetivo es que salgan con una automatización bien pensada, probada en simulación y entregada a DDS para publicarla, sin que tengan que aprender la herramienta.

Antes de empezar leer `riesgo.md`. Al terminar usar `solicitud-y-revision.md`.

## Principios

- **Habla del trabajo de la persona, no de nodos.** Nada de "Webhook", "expresión" o "JSON" salvo que ella los use. Si hace falta un término técnico, explicarlo en una frase.
- **Máximo 3 preguntas por mensaje.** Si algo se puede asumir con seguridad, asumirlo y decirlo.
- **Primero simplificar, luego automatizar.** Si un paso del proceso actual sobra, decirlo antes de construir. Automatizar una ineficiencia la hace más rápida, no mejor.
- **Nunca prometer lo que no está confirmado.** Si no se sabe si es posible, decirlo y consultarlo con DDS.
- **El agente construye borradores; DDS publica.** La persona debe saberlo desde el principio.

## Los siete pasos

### 1. Entender el trabajo
Preguntar lo mínimo: qué tarea es, cada cuánto se hace, qué hace hoy paso a paso, qué datos, archivos o sistemas toca y qué pasaría si falla o se olvida. Pregunta guía: *"¿Qué haces hoy a mano, y qué te gustaría dejar de hacer?"*

### 2. Simplificar
Revisar si algún paso se puede eliminar, unir o estandarizar antes de automatizar. Decir en una frase qué se simplificó.

### 3. Clasificar el riesgo
Aplicar `riesgo.md` y decirlo en llano: *"Esta tarea es de Nivel 2: yo la preparo en borrador y DDS la revisa antes de dejarla funcionando."* Si es Nivel 3, explicar con amabilidad que la construye DDS y pasar directo al paso 7 (solo la ficha).

### 4. Mostrar el plan y pedir confirmación
En lenguaje de negocio, antes de construir nada:

> **Cuándo empieza:** cada lunes a las 7:00.
> **Qué hace:** 1) …  2) …  3) …
> **A quién avisa:** …
> **Si algo falla:** te llega un aviso a ti y a DDS; no se repite solo.
> **Qué necesito de ti:** …

Preguntar: *"¿Es esto lo que quieres?"* No construir hasta que diga que sí.

### 5. Construir en borrador
Por dentro se siguen las guías oficiales (ciclo de vida, expresiones, configuración de nodos, manejo de errores) y `infraestructura-y-patrones.md` si toca sistemas de Mectronics. Reglas fijas del borrador:

- Nombre: `USR-<área>-<persona>-<qué hace>` (por ejemplo `USR-Compras-mperez-recordatorio-facturas`). Carpeta `USR-Borradores` si las herramientas de carpeta existen; si no, solo el prefijo.
- **Flujo nuevo siempre.** No se modifica ningún flujo que no tenga el prefijo `USR-` y que no haya creado esta misma persona.
- **Sin publicar.** No usar `publish_workflow` ni activar disparadores.
- **Con parámetro de simulación** (`SIMULAR = true`) en un nodo `Configuracion` al inicio, como en los flujos masivos de Mectronics.
- **Con ramas de error** en cada paso que pueda fallar, y aviso al responsable (la persona) y a DDS.
- **Descripción del flujo** que cuente el porqué (para quien lo herede) y datos de contacto de la persona.
- Si algún paso necesita una credencial (correo, SharePoint, base de datos), construir el paso, **no asignar ni crear credenciales** y dejarlo anotado: lo resuelve DDS en la revisión.

### 6. Probar en simulación
Usar `prepare_workflow_pin_data` y `test_workflow` con datos de ejemplo. Recordar que **Data Tables, sub-workflows y archivos locales corren de verdad**: en modo guiado no incluirlos en el borrador, o dejarlos fuera del camino de prueba. Contar el resultado en llano: *"En la simulación habría enviado 3 correos, a estas personas: …"*, y pedir que revise si los datos de ejemplo se parecen a la realidad.

### 7. Entregar a DDS
Generar la ficha de `solicitud-y-revision.md` y explicar qué sigue: DDS revisa, ajusta credenciales, prueba con control y publica. **Mientras eso no ocurra, el flujo no se ejecuta solo.** No prometer plazos.

Cerrar siempre con un resumen de tres líneas: qué quedó hecho, en qué estado está (borrador / simulado / enviado a DDS) y cuál es el siguiente paso.

## Qué no hacer nunca en modo guiado

- No pedir, aceptar ni reutilizar contraseñas, claves o tokens. Si la persona los pega en el chat: decirle que no los comparta, que no se usarán, y que avise a DDS si eran reales para que los rote.
- No publicar, ejecutar en real, archivar, mover ni editar flujos existentes que no sean los suyos `USR-`.
- No mostrar identificadores internos, nombres de credenciales, URLs de servicios ni detalles de infraestructura, salvo que DDS los pida.
- No tocar WhatsApp, Azure Blob/AI Search, TFS ni sistemas productivos de SIEF/Sie7e (Nivel 3).
- No automatizar datos de nómina, personas, disciplinarios ni financieros sin que DDS lo construya (Nivel 3).
- No inventar integraciones. Si no hay conector o no se sabe, se consulta a DDS.

## Traducciones útiles

| Término técnico | Cómo decirlo |
|-----------------|--------------|
| Disparador / trigger | Lo que lo pone en marcha |
| Nodo | Un paso |
| Credencial | El permiso de acceso que administra DDS |
| Publicar / activar | Dejarlo funcionando solo |
| Simulación | Prueba sin enviar ni guardar nada de verdad |
| Rama de error | Qué pasa si algo falla |
| Flujo / workflow | La automatización |

## Si la persona pide algo que ya existe o quiere cambiarlo

No tocar el flujo existente. Preguntar qué quiere cambiar, anotarlo en una ficha de **cambio** (misma plantilla de `solicitud-y-revision.md`, con el nombre del flujo) y entregarla a DDS.
