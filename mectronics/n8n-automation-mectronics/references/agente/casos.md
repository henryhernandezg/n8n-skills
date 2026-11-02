# Casos frecuentes y su nivel de riesgo

Ejemplos de diseño para orientar la conversación en modo guiado. **No son flujos validados en producción**: cada uno se diseña y se prueba desde cero. El nivel indicado es el de partida; si aparece una señal de `riesgo.md`, sube.

| Tarea del puesto | Idea de automatización | Nivel | Observaciones |
|------------------|------------------------|-------|---------------|
| "Cada lunes se me olvida revisar X" | Recordatorio programado por correo a la propia persona | 1 | El caso más simple. Correo desde una credencial de Outlook que asigna DDS. |
| "Reviso un Excel de SharePoint y mando un resumen" | Leer el libro con Graph, calcular y enviar un resumen a la propia persona | 1 | Leer no es escribir. Si el libro es de otra área, confirmar permisos con DDS. |
| "Aviso a mi equipo cuando hay pendientes" | Revisar una fuente y enviar un correo a un grupo | 2 | Destinatarios múltiples: revisar volumen y evitar repeticiones (dedup). |
| "Consolido archivos que me llegan por correo" | Guardar adjuntos en una carpeta del área y registrar qué llegó | 2 | Usar solo columnas o carpetas propias; no borrar nada. Cuidado con bucles si el flujo responde desde el mismo buzón. |
| "Clasifico correos o solicitudes" | Nodo de IA que etiqueta o resume y entrega el resultado a la persona | 2 | Revisar la calidad con ejemplos reales antes de confiar. Costo por uso de IA. |
| "Genero un reporte con datos de SIEF" | Consulta a base de datos y reporte | 3 | Acceso a sistemas productivos: lo construye DDS. |
| "Aviso a clientes por WhatsApp" | Mensajes con plantilla aprobada | 3 | Clientes y WhatsApp: DDS. Considerar costos y aprobaciones de plantillas. |
| "Actualizo el Excel de nómina / novedades" | Cualquier flujo con datos de nómina o personas | 3 | Datos sensibles. DDS lo construye y lo audita. |

## Cómo usarlos en la conversación

- Nombrar el caso parecido para que la persona se reconozca ("esto se parece a un recordatorio con resumen"), pero **no asumir** que es igual: preguntar lo que cambia.
- Si no hay caso parecido, no inventarlo: diseñar desde el paso 1 de `guiado.md`.
- Si la persona describe varios casos a la vez, trabajar de uno en uno y empezar por el de menor riesgo.
