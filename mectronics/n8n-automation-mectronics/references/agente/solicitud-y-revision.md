# Registro de la automatización y autoverificación

## 1. Autoverificación antes de publicar (Nivel 1 y 2)

La hace Claude con la persona. Ninguna casilla se da por buena sin evidencia.

- [ ] El flujo hace lo que dice el plan y nada más.
- [ ] Cada nodo con credencial usa una credencial **propia de la persona** (confirmado por ella en la UI, nodo por nodo).
- [ ] Ningún destinatario ni carpeta distinto del acordado.
- [ ] Hay filtro claro para los correos (carpeta, remitente o asunto); no se copia toda la bandeja.
- [ ] Rama de error con aviso; el flujo no cierra en `success` sin haber hecho nada (`ok: false` y `motivo` cuando algo no se pudo).
- [ ] El nodo que decide "no hay nada que hacer" **no** lleva `alwaysOutputData` (patrón del item vacío).
- [ ] Estado entre ejecuciones en Data Table, no en `staticData`; se marca "procesado" solo después de que la escritura salió bien.
- [ ] Escrituras solo en las columnas o archivos del propio flujo; nada de borrar trabajo humano.
- [ ] Si el flujo escribe en Excel: tabla de Excel existente, ruta por nombre (no por `itemId`) y una sola petición de escritura por ejecución, con sesión de libro.
- [ ] Si el flujo lee un buzón y avisa por correo: guardas anti-loop (asunto con prefijo propio, remitente propio, ya procesado).
- [ ] `validate_workflow` limpio y `get_workflow_details` con las conexiones revisadas.
- [ ] Prueba con `pinData` hecha y sus efectos reales (Data Table) limpiados.

**Después de publicar:** caso real verificado en el sistema de la persona (ver paso 9 de `guiado.md`).

## 2. Ficha de registro (la genera Claude al final)

Entregarla en el chat para que la persona la guarde o la envíe a DDS. Sin identificadores internos ni secretos.

```
FICHA DE AUTOMATIZACIÓN
Nombre del flujo: USR-<área>-<persona>-<qué hace>
Fecha de publicación:
Responsable: nombre, área, correo
Nivel de riesgo: 1 | 2  (por qué)

1. Qué hacía a mano antes y cuánto tiempo tomaba
2. Qué hace ahora (pasos en lenguaje de negocio)
3. Cuándo se ejecuta y volumen esperado
4. Qué lee y qué escribe, y dónde (ruta del archivo)
5. Qué pasa si falla y a quién avisa
6. Cómo se apaga
7. Verificación: qué caso real se probó y cuál fue el resultado
```

## 3. Solicitud a DDS (solo Nivel 3, o si la persona necesita ayuda)

Misma ficha, agregando: problema y beneficio esperado, sistemas que toca, si hay datos sensibles (personas, nómina, financieros, disciplinarios, clientes) y pendientes (accesos, aprobaciones). Entregarla en el chat para copiar y enviar a DDS.

## 4. Revisión de DDS para Nivel 3

- [ ] Credenciales asignadas y verificadas nodo por nodo en la UI (hay 3 de Outlook y 3 de WhatsApp; n8n asigna la más reciente del tipo).
- [ ] Destinatarios y volumen revisados; sin envíos masivos accidentales.
- [ ] Dedup o idempotencia si puede ejecutarse dos veces; estado en Postgres o Data Table, no en `staticData`.
- [ ] Límite de seguridad si hay borrado; no se borra trabajo humano.
- [ ] Rutas locales dentro de `N8N_RESTRICT_FILE_ACCESS_TO`; sin Execute Command (deshabilitado).
- [ ] Ventana de disponibilidad de las dependencias (por ejemplo Sie7e preproducción).
- [ ] Prueba controlada y resultado visto en la ejecución real, no solo en `status: success`.
- [ ] Webhook, WhatsApp o formulario: se crea y se edita a mano; `update_workflow` prohibido sobre él.

## 5. Trazabilidad (propuesta, no ejecutada)

Para saber qué automatizaciones de usuario existen y en qué estado están, se propone una tabla en `dds_director`, siguiendo el patrón de `ejecucion_n8n` y `alerta`. **Es solo una propuesta: no se ha creado.**

```sql
CREATE TABLE dds_director.automatizacion_usuario (
  automatizacion_id BIGSERIAL PRIMARY KEY,
  nombre_flujo      TEXT        NOT NULL,
  solicitante       TEXT        NOT NULL,
  area              TEXT        NOT NULL,
  nivel_riesgo      SMALLINT    NOT NULL CHECK (nivel_riesgo IN (1,2,3)),
  estado            TEXT        NOT NULL CHECK (estado IN
                    ('borrador','publicada','pausada','retirada')),
  ficha             JSONB,
  creado_en         TIMESTAMPTZ NOT NULL DEFAULT now(),
  actualizado_en    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX ux_automatizacion_usuario_nombre
  ON dds_director.automatizacion_usuario (nombre_flujo)
  WHERE estado <> 'retirada';
```
