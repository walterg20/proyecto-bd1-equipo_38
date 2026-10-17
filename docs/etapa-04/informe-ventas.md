# Etapa IV: Consultas y Casos de Uso
## Caso 2: Reporte Agregado de Ventas en Rango de Fechas

### 1. Descripción de la Necesidad de Negocio
Para la administración de la tienda comercial **"Matiensos"**, conocer el volumen global de facturación no es suficiente; resulta estratégico identificar qué familias de productos materos (Mates, Bombillas, Termos) impulsan las ventas y generan mayor rentabilidad en períodos determinados.

Este reporte permite al equipo directivo:
- Conocer la recaudación total en pesos generada por cada categoría.
- Medir la rotación física de mercadería.
- Detectar la presencia de cada categoría en las órdenes de compra.

---

### 2. Estructura de la Consulta y Tablas Involucradas

La consulta recorre la jerarquía del modelo relacional vinculando 4 entidades:
[Categoria] (1) ──── (N) [Producto] (1) ──── (N) [DetalleVenta] (N) ──── (1) [Venta]