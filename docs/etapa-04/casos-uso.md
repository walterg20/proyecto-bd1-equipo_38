# Etapa IV: Consultas y Casos de Uso
## Documentación General de Casos de Uso

**Asignatura:** Base de Datos I  
**Equipo:** 38  
**Proyecto:** Matiensos 
**Año:** 2026  

---

### Introducción
En esta etapa se implementan y documentan las consultas SQL diseñadas para responder a los principales requerimientos analíticos y operativos de la tienda física **Matiensos**.

Las necesidades de información abordadas se estructuran en tres casos de uso:

1. **[Comprobante de Venta](comprobante-venta.md):**
   - **Objetivo:** Consolidar encabezado y detalle de una operación en mostrador, calculando subtotales por producto y total acumulado.
   - **Script SQL:** `sql/consultas/comprobante-venta.sql`

2. **[Informe de Ventas Agregado](informe-ventas.md):**
   - **Objetivo:** Analizar el rendimiento comercial agrupado por categorías de artículos materos en un rango de fechas mediante `GROUP BY`, `SUM` y `COUNT`.
   - **Script SQL:** `sql/consultas/informe-ventas.sql`

3. **[Consultas de Negocio Avanzadas](consulta-avanzada.md):**
   - **Objetivo:** Explotación analítica de datos combinando más de 3 tablas con filtros condicionales avanzados (`HAVING` y subconsultas correlacionadas/escalares).
   - **Script SQL:** `sql/consultas/consulta-avanzada.sql`