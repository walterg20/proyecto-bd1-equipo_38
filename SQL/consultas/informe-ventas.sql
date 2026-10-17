/* =============================================================================
   Caso 2: Reporte Agregado de Ventas en Rango de Fechas
   ============================================================================= */

USE sistema_matiensos;
GO

-- Rango de análisis: [@FechaDesde, @FechaHasta)
DECLARE @FechaDesde DATETIME = '2026-09-01 00:00:00';
DECLARE @FechaHasta DATETIME = '2026-10-01 00:00:00';
/* ó
SET @FechaDesde = DATEADD(DAY, -60, GETDATE());
SET @FechaHasta = DATEADD(DAY, 1, GETDATE());*/


-- =============================================================================
-- CONSULTA PRINCIPAL: Rendimiento de Ventas por Categoría de Producto
-- =============================================================================
SELECT 
    c.id_categoria,
    c.nombre AS categoria,
    COUNT(DISTINCT v.id_venta) AS cantidad_ventas,
    ISNULL(SUM(dv.cantidad), 0) AS unidades_vendidas,
    ISNULL(SUM(dv.cantidad * dv.precio_congelado), 0.00) AS total_recaudado,
    CASE 
        WHEN COUNT(DISTINCT v.id_venta) > 0 
        THEN CAST(ISNULL(SUM(dv.cantidad * dv.precio_congelado), 0.00) / COUNT(DISTINCT v.id_venta) AS DECIMAL(10,2))
        ELSE 0.00 
    END AS ticket_promedio_categoria
FROM Categoria c
    INNER JOIN Producto p 
        ON c.id_categoria = p.id_categoria
    INNER JOIN DetalleVenta dv 
        ON p.id_producto = dv.id_producto
    INNER JOIN Venta v 
        ON dv.id_venta = v.id_venta
WHERE 
    v.fecha_hora >= @FechaDesde 
    AND v.fecha_hora < @FechaHasta
GROUP BY 
    c.id_categoria,
    c.nombre
ORDER BY 
    total_recaudado DESC;
GO


-- =============================================================================
-- CONSULTA COMPLEMENTARIA: Rendimiento de Ventas por Vendedor
-- =============================================================================
-- Muestra la productividad comercial de cada usuario con rol vendedor en el período.

DECLARE @FechaDesdeVendedor DATETIME = '2026-09-01 00:00:00';
DECLARE @FechaHastaVendedor DATETIME = '2026-10-01 00:00:00';

SELECT 
    u.id_persona_usuario,
    p.nombre + ' ' + p.apellido AS vendedor,
    COUNT(DISTINCT v.id_venta) AS cantidad_ventas_realizadas,
    ISNULL(SUM(dv.cantidad), 0) AS unidades_totales_despachadas,
    ISNULL(SUM(dv.cantidad * dv.precio_congelado), 0.00) AS total_facturado,
    CASE 
        WHEN COUNT(DISTINCT v.id_venta) > 0 
        THEN CAST(ISNULL(SUM(dv.cantidad * dv.precio_congelado), 0.00) / COUNT(DISTINCT v.id_venta) AS DECIMAL(10,2))
        ELSE 0.00 
    END AS ticket_promedio_vendedor
FROM Usuario u
    INNER JOIN Persona p 
        ON u.id_persona_usuario = p.id_persona
    INNER JOIN Venta v 
        ON u.id_persona_usuario = v.id_persona_usuario
    INNER JOIN DetalleVenta dv 
        ON v.id_venta = dv.id_venta
WHERE 
    v.fecha_hora >= @FechaDesdeVendedor 
    AND v.fecha_hora < @FechaHastaVendedor
GROUP BY 
    u.id_persona_usuario,
    p.nombre,
    p.apellido
ORDER BY 
    total_facturado DESC;
GO