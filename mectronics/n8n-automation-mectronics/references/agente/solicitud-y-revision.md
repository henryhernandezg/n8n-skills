# Solicitud a DDS y revisión antes de publicar

## 1. Ficha de solicitud (la genera Claude al final del modo guiado)

Entregarla en el chat, en español claro, lista para copiar y enviar a DDS. Sin identificadores internos ni secretos.

```
FICHA DE AUTOMATIZACIÓN
Tipo: Nueva | Cambio de flujo existente (nombre: ______)
Fecha:
Solicitante: nombre, área, correo
Nombre del borrador: USR-<área>-<persona>-<qué hace>
Nivel de riesgo: 1 | 2 | 3  (por qué)

1. Problema y beneficio
   - Qué se hace hoy a mano, cada cuánto y cuánto tiempo toma
   - Qué se espera ganar (tiempo, errores evitados)
2. Qué hará la automatización (pasos en lenguaje de negocio)
3. Cuándo se ejecuta (horario / evento) y volumen esperado
4. Sistemas y datos que toca (lee / escribe / envía) y a quién avisa
5. Qué pasa si falla y quién debe enterarse
6. Datos sensibles: ¿personas, nómina, financieros, disciplinarios, clientes? Sí/No
7. Qué se simuló y con qué resultado
8. Pendientes para DDS (credenciales por asignar, accesos, aprobaciones)
9. Responsable funcional de la automatización (quién responde si algo cambia en el proceso)
```

## 2. Lista de revisión de DDS

**Nivel 1 (lista corta)**
- [ ] El flujo hace lo que dice la ficha y nada más.
- [ ] Destinatario correcto (solo la persona solicitante).
- [ ] Credencial verificada **nodo por nodo en la UI** (hay 3 Outlook y 3 WhatsApp; n8n asigna la más reciente del tipo).
- [ ] Rama de error con aviso; el flujo no cierra en success sin haber hecho nada.
- [ ] Horario y zona horaria (America/Bogota, UTC-5).
- [ ] Nombre y descripción claros; responsable funcional anotado.

**Nivel 2 (además de lo anterior)**
- [ ] Destinatarios y volumen revisados (sin envíos masivos accidentales).
- [ ] Patrón del item vacío: el nodo que decide "no hay nada que hacer" **sin** `alwaysOutputData`.
- [ ] Dedup o idempotencia si puede ejecutarse dos veces; estado en Postgres o Data Table, no en `staticData`.
- [ ] Escrituras solo en las columnas o archivos del propio flujo (no borrar trabajo humano; límite de seguridad si hay borrado).
- [ ] Rutas locales dentro de `N8N_RESTRICT_FILE_ACCESS_TO`; sin Execute Command (deshabilitado).
- [ ] Ventana de disponibilidad de las dependencias (por ejemplo Sie7e preproducción) y reintentos solo en fallos transitorios.
- [ ] Prueba controlada con datos reales y efectos acotados; resultado visto en la ejecución real, no solo en `status: success`.
- [ ] Revisar el guion de errores con la tabla de *Errores comunes* de `infraestructura-y-patrones.md`.

**Antes de publicar (ambos niveles)**
- [ ] `validate_workflow` limpio **y** `get_workflow_details` con las conexiones verificadas.
- [ ] Si el flujo tiene WhatsApp Trigger, Webhook o Form: se crea y edita a mano, y se anota que `update_workflow` está prohibido sobre él.
- [ ] Entrega al solicitante: cómo se dispara, qué hace, a quién avisa, a quién acudir.
- [ ] Alta en la bitácora de automatizaciones de usuario (ver abajo).

## 3. Trazabilidad (propuesta, no ejecutada)

Para saber qué automatizaciones existen, quién las pidió y en qué estado están, se propone una tabla en `dds_director`, siguiendo el patrón de `ejecucion_n8n` y `alerta`. **Es una propuesta: no se ha creado ni se debe ejecutar sin revisión de DDS.**

```sql
CREATE TABLE dds_director.automatizacion_usuario (
  automatizacion_id BIGSERIAL PRIMARY KEY,
  nombre_flujo      TEXT        NOT NULL,
  solicitante       TEXT        NOT NULL,
  area              TEXT        NOT NULL,
  nivel_riesgo      SMALLINT    NOT NULL CHECK (nivel_riesgo IN (1,2,3)),
  estado            TEXT        NOT NULL CHECK (estado IN
                    ('borrador','simulado','en_revision','publicada','rechazada','retirada')),
  revisor_dds       TEXT,
  ficha             JSONB,
  creado_en         TIMESTAMPTZ NOT NULL DEFAULT now(),
  actualizado_en    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX ux_automatizacion_usuario_nombre
  ON dds_director.automatizacion_usuario (nombre_flujo)
  WHERE estado <> 'retirada';
```

Mientras la tabla no exista, la ficha en el chat (copiada a la herramienta de seguimiento de DDS) es el registro.
