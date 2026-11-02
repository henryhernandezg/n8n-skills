# Modo guiado — automatizar tareas del puesto de trabajo

Para personas que conocen su trabajo pero no n8n y tienen su propio usuario de n8n conectado por MCP. El objetivo es dejarles la automatización **construida, probada, publicada y verificada**, sin que tengan que aprender la herramienta.

Antes de empezar leer `riesgo.md`. Ejemplo completo: `ejemplo-correo-a-excel.md`. Si el MCP no responde: `sin-mcp.md`.

## Principios

- **Habla del trabajo de la persona, no de nodos.** Nada de "Webhook", "expresión" o "JSON" salvo que ella los use. Si hace falta un término técnico, explicarlo en una frase.
- **Máximo 3 preguntas por mensaje.** Si algo se puede asumir con seguridad, asumirlo y decirlo.
- **Primero simplificar, luego automatizar.** Si un paso del proceso actual sobra, decirlo antes de construir.
- **No prometer lo que no está confirmado.** Si no se sabe si es posible, decirlo.
- **Terminar de verdad:** el trabajo no está hecho cuando el flujo se publica, sino cuando se vio funcionar con un caso real.

## Los pasos

### 0. Comprobar la conexión
Confirmar que las herramientas del MCP de n8n responden (por ejemplo `search_workflows`). Si no están o fallan, seguir `sin-mcp.md`. **Antes de reintentar una creación que falló, buscar por nombre si el flujo ya quedó creado** (para no duplicarlo).

### 1. Entender el trabajo
Qué tarea es, cada cuánto, qué hace hoy paso a paso, qué datos, archivos o sistemas toca y qué pasa si falla. Pregunta guía: *"¿Qué haces hoy a mano, y qué quieres dejar de hacer?"* Cuando la tarea toca correo, pedir **cuáles correos** (carpeta, remitente o asunto): nunca copiar toda la bandeja.

### 2. Simplificar
Revisar si algún paso se puede eliminar, unir o estandarizar antes de automatizar. Decir en una frase qué se simplificó.

### 3. Clasificar el riesgo
Aplicar `riesgo.md` y decirlo en llano. Nivel 1 y 2: Claude lo construye y lo publica con la persona. Nivel 3: lo construye DDS; pasar a la ficha de `solicitud-y-revision.md`.

### 4. Mostrar el plan y pedir confirmación
En lenguaje de negocio, antes de construir nada:

> **Cuándo empieza:** cuando llegue un correo a la carpeta X.
> **Qué hace:** 1) …  2) …  3) …
> **Dónde deja el resultado:** …
> **Si algo falla:** te llega un aviso; no se repite solo.
> **Qué necesito de ti:** …

Preguntar: *"¿Es esto lo que quieres?"* No construir hasta que diga que sí.

### 5. Credenciales propias (antes de construir)
Una credencial es el permiso de acceso al correo, SharePoint, etc. **El flujo debe usar credenciales de la propia persona**:

- Revisar las credenciales disponibles (`list_credentials`). Usar solo las que sean de ella.
- **No atar nunca un flujo de usuario a las credenciales compartidas de DDS** (`Microsoft Outlook DDS`, `Microsoft Outlook Correo Disciplinarios`, `Microsoft Outlook Correo Infraestructura Mectronics`, `Microsoft Graph DDS`, WhatsApp, Azure, Postgres, TFS): leerían buzones o archivos que no son suyos. Si alguna aparece visible para la persona, no usarla y avisar a DDS.
- Si falta su credencial de Microsoft, se la crea ella en n8n (Credentials → Create → tipo "Microsoft Outlook OAuth2" o "Microsoft Excel OAuth2" → Sign in with Microsoft). Si el formulario pide Client ID y Client Secret, los entrega DDS; **nunca** pedírselos ni pegarlos en el chat.
- Claude no crea credenciales ni recibe secretos.

### 6. Construir
Flujo **nuevo** con nombre `USR-<área>-<persona>-<qué hace>`. Por dentro se siguen las guías oficiales (ciclo de vida, expresiones, configuración de nodos, manejo de errores) y `infraestructura-y-patrones.md` si toca sistemas de Mectronics. Reglas fijas:

- Carpeta `USR-Borradores` si hay herramientas de carpeta; si no, solo el prefijo.
- Descripción del flujo que cuente el porqué y quién es la responsable.
- **Ramas de error** en cada paso que pueda fallar, con aviso a la persona.
- Estado que debe sobrevivir entre ejecuciones (por ejemplo "este correo ya se procesó"): Data Table propia del flujo; **nunca** `staticData`.
- Después de crear: `validate_workflow` y además `get_workflow_details` para revisar las conexiones.

### 7. Probar
`prepare_workflow_pin_data` y `test_workflow` con datos de ejemplo. Recordar que **Data Tables, sub-workflows y archivos locales corren de verdad** en la prueba: usar identificadores de prueba (`TEST-…`) y limpiarlos después. Contar el resultado en llano.

### 8. Publicar
Solo cuando se cumplan las tres condiciones:
1. La persona abrió **cada nodo con credencial en la UI** y confirmó que es su cuenta (n8n asigna por defecto la credencial más reciente del tipo; la API no dice cuál quedó).
2. Validación limpia y conexiones verificadas.
3. La persona dijo expresamente que sí: *"¿Lo dejo funcionando solo?"*

Entonces `publish_workflow`. No se usa `update_workflow` sobre un flujo ya publicado con webhook, WhatsApp o formulario (ver reglas de la skill).

### 9. Verificar con un caso real
Pedirle a la persona que provoque un caso real (por ejemplo, enviarse un correo de prueba). Esperar el ciclo del disparador, revisar la ejecución (`search_workflow_executions` / `get_workflow_execution`) y **que la persona confirme el resultado en su sistema** (la fila en el Excel). Un `success` en n8n no basta. Si no aparece, depurar con la guía de depuración y la tabla de errores comunes antes de dar el trabajo por terminado.

### 10. Cerrar
Resumen en tres líneas: qué hace, que ya está funcionando y cómo se apaga (`unpublish_workflow` o pedírselo a Claude), y a quién acudir (DDS). Dejar la ficha de `solicitud-y-revision.md` como registro.

## Qué no hacer nunca en modo guiado

- No pedir, aceptar ni reutilizar contraseñas, claves o tokens. Si la persona los pega: decirle que no los comparta y que avise a DDS si eran reales para rotarlos.
- No editar, mover, archivar ni publicar flujos que no sean los suyos `USR-`.
- No atar flujos a credenciales compartidas de DDS.
- No mostrar identificadores internos, nombres de credenciales compartidas ni detalles de infraestructura, salvo que DDS los pida.
- No construir Nivel 3 (ver `riesgo.md`).
- No inventar integraciones. Si no hay conector o no se sabe, se consulta a DDS.

## Traducciones útiles

| Término técnico | Cómo decirlo |
|-----------------|--------------|
| Disparador / trigger | Lo que lo pone en marcha |
| Nodo | Un paso |
| Credencial | El permiso de acceso a tu correo / tu SharePoint |
| Publicar | Dejarlo funcionando solo |
| Simulación | Prueba sin enviar ni guardar nada de verdad |
| Rama de error | Qué pasa si algo falla |
| Flujo / workflow | La automatización |

## Si la persona quiere cambiar un flujo suyo ya publicado
Cambios que no tocan el disparador: se hacen sobre su propio flujo `USR-` y se verifican como en los pasos 6 a 9. Si el flujo tiene webhook, WhatsApp o formulario, no usar `update_workflow` (regenera el `webhookId`): se edita a mano en la UI.
