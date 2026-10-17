# Caso 2: Reporte Agregado de Ventas en Rango de Fechas

### 1. Necesidad de Información
La administración de **Matiensos** requiere evaluar el rendimiento comercial y la rotación de sus artículos en períodos de tiempo determinados. La consulta debe consolidar el total de ventas agrupadas por cada categoría de producto (Mates, Bombillas, Termos), permitiendo conocer tanto la recaudación monetaria total como el volumen físico de mercadería vendida y la cantidad de operaciones en las que participó cada categoría.

### 2. Estrategia SQL Utilizada
- **Combinación de entidades:** Se conectan las tablas `Categoria`, `Producto`, `DetalleVenta` y `Venta` a través de sus respectivas claves foráneas mediante `INNER JOIN`.
- **Agrupamiento (GROUP BY):** Se agrupan los registros por `id_categoria` y `nombre` de la categoría, garantizando una fila por cada rubro comercial.
- **Agregaciones requeridas (SUM y COUNT):**
  - `COUNT(DISTINCT v.id_venta)` para contabilizar la cantidad de ventas únicas donde intervino la categoría, evitando duplicaciones por múltiples productos en un mismo comprobante.
  - `SUM(dv.cantidad)` para totalizar las piezas físicas despachadas.
  - `SUM(dv.cantidad * dv.precio_congelado)` para calcular la facturación monetaria histórica real, respetando el precio pactado al momento de cada venta.
  - Cálculo de ticket promedio por categoría mediante división protegida ante posibles divisiones por cero.
- **Filtrado temporal sargable:** Se parametriza el período (`@FechaDesde` y `@FechaHasta`) con un intervalo semicerrado (`>=` y `<`) sobre `v.fecha_hora` para no omitir ventas con horas/minutos y permitir el uso de índices.

### 3. Resultado Esperado
La consulta devuelve una fila por cada categoría de producto que registró operaciones en el período, ordenada descendentemente por su facturación total:
- Identificador de la Categoría (`id_categoria`).
- Nombre de la Categoría (`categoria`).
- Cantidad de transacciones únicas donde participó (`cantidad_ventas`).
- Total de unidades físicas despachadas (`unidades_vendidas`).
- Facturación total recaudada en pesos (`total_recaudado`).
- Monto promedio facturado por venta (`ticket_promedio_categoria`).