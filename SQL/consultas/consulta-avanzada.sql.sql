/* =============================================================================
   Caso 3: Consultas de Negocios Avanzadas
   ============================================================================= */

USE sistema_matiensos;
GO

/* ==========================================================================================
   CONSULTA 1: Clientes con Gasto Acumulado Superior al Promedio General
   ------------------------------------------------------------------------------------------
   Identificar a aquellos clientes  cuyo gasto total acumulado en compras 
   supere el promedio general de facturación por cliente de todo el sistema, y que además 
   cuenten con al menos 2 ventas registradas.

   ========================================================================================== */

SELECT 
    c.id_persona_cliente AS id_cliente,
    CONCAT(p.apellido, ', ', p.nombre) AS cliente_nombre_completo,
    p.dni AS documento,
    c.categoria AS segmento_cliente,
    COUNT(DISTINCT v.id_venta) AS cantidad_compras,
    SUM(dv.cantidad) AS unidades_totales_compradas,
    SUM(dv.cantidad * dv.precio_congelado) AS gasto_total_acumulado,
    CAST(AVG(dv.cantidad * dv.precio_congelado) AS DECIMAL(10,2)) AS promedio_por_item
FROM Cliente c
INNER JOIN Persona p 
    ON c.id_persona_cliente = p.id_persona
INNER JOIN Venta v 
    ON c.id_persona_cliente = v.id_persona_cliente
INNER JOIN DetalleVenta dv 
    ON v.id_venta = dv.id_venta
INNER JOIN Producto pr 
    ON dv.id_producto = pr.id_producto
GROUP BY 
    c.id_persona_cliente, 
    p.apellido, 
    p.nombre, 
    p.dni, 
    c.categoria
HAVING 
    COUNT(DISTINCT v.id_venta) >= 2
    AND SUM(dv.cantidad * dv.precio_congelado) > (
        -- Subconsulta: Calcula el gasto promedio histórico por cliente
        SELECT AVG(total_por_cliente)
        FROM (
            SELECT SUM(dv_sub.cantidad * dv_sub.precio_congelado) AS total_por_cliente
            FROM Venta v_sub
            INNER JOIN DetalleVenta dv_sub 
                ON v_sub.id_venta = dv_sub.id_venta
            GROUP BY v_sub.id_persona_cliente
        ) AS ResumenClientes
    )
ORDER BY gasto_total_acumulado DESC;
GO

/* ==========================================================================================
   CONSULTA 2: Clientes con Compras en Productos de precios elevados (Sobre Precio Promedio de Catálogo)
   ------------------------------------------------------------------------------------------
   Analizar el comportamiento de los clientes que compran artículos cuyo precio supera el precio promedio 
   de todos los artículos activos del catálogo de la tienda
   y que han acumulado más de $50.000 en estas líneas exclusivas.
   ========================================================================================== */
SELECT 
    c.id_persona_cliente AS id_cliente,
    CONCAT(p.apellido, ', ', p.nombre) AS cliente,
    c.categoria AS tipo_cliente,
    COUNT(DISTINCT pr.id_producto) AS variedad_articulos_premium,
    SUM(dv.cantidad) AS unidades_premium_compradas,
    SUM(dv.cantidad * dv.precio_congelado) AS facturacion_total_premium
FROM Cliente c
INNER JOIN Persona p 
    ON c.id_persona_cliente = p.id_persona
INNER JOIN Venta v 
    ON c.id_persona_cliente = v.id_persona_cliente
INNER JOIN DetalleVenta dv 
    ON v.id_venta = dv.id_venta
INNER JOIN Producto pr 
    ON dv.id_producto = pr.id_producto
WHERE pr.precio > (
    -- Subconsulta: Precio promedio del catálogo de productos activos
    SELECT AVG(precio) 
    FROM Producto 
    WHERE esta_activo = '1'
)
GROUP BY 
    c.id_persona_cliente, 
    p.apellido, 
    p.nombre, 
    c.categoria
HAVING 
    COUNT(DISTINCT v.id_venta) >= 1
    AND SUM(dv.cantidad * dv.precio_congelado) > 50000.00
ORDER BY facturacion_total_premium DESC;
GO


/* ==========================================================================================
   CONSULTA 3: Análisis de Penetración del Producto Más Vendido 
  
   Determinar qué clientes compraron el producto más vendido en unidades físicas en la historia 
   de Matiensos.
   ========================================================================================== */

SELECT 
    c.id_persona_cliente AS id_cliente,
    CONCAT(p.apellido, ', ', p.nombre) AS cliente,
    p.correo AS correo_contacto,
    pr.nombre AS producto_estrella,
    SUM(dv.cantidad) AS unidades_adquiridas,
    SUM(dv.cantidad * dv.precio_congelado) AS total_invertido_en_producto
FROM Cliente c
INNER JOIN Persona p 
    ON c.id_persona_cliente = p.id_persona
INNER JOIN Venta v 
    ON c.id_persona_cliente = v.id_persona_cliente
INNER JOIN DetalleVenta dv 
    ON v.id_venta = dv.id_venta
INNER JOIN Producto pr 
    ON dv.id_producto = pr.id_producto
WHERE pr.id_producto = (
    -- Subconsulta: Obtiene el ID del producto con mayor volumen histórico vendido
    SELECT TOP 1 dv_top.id_producto
    FROM DetalleVenta dv_top
    GROUP BY dv_top.id_producto
    ORDER BY SUM(dv_top.cantidad) DESC
)
GROUP BY 
    c.id_persona_cliente, 
    p.apellido, 
    p.nombre, 
    p.correo, 
    pr.nombre
HAVING SUM(dv.cantidad) >= 1
ORDER BY unidades_adquiridas DESC, total_invertido_en_producto DESC;
GO

/* ==========================================================================================
   CONSULTA 4: Desempeño Comercial por Rol, Categoría y Medio de Pago
   ------------------------------------------------------------------------------------------
   Analizar la recaudación y el volumen de ventas cruzando el Rol del empleado que facturó, 
   la Categoría del artículo matero vendido y el Medio de Pago utilizado por el cliente. 
   Se filtran únicamente aquellas combinaciones cuya recaudación total supere el 
   ticket promedio general histórico de la tienda, identificando así los flujos de 
   ingreso más fuertes del negocio.
   ========================================================================================== */

SELECT 
    r.nombre AS rol_empleado,
    CONCAT(p.apellido, ', ', p.nombre) AS empleado,
    c.nombre AS categoria_producto,
    mp.tipo AS medio_pago,
    COUNT(DISTINCT v.id_venta) AS cantidad_operaciones,
    SUM(dv.cantidad) AS articulos_vendidos,
    SUM(dv.cantidad * dv.precio_congelado) AS recaudacion_total
FROM Venta v
-- Unimos con Usuario, Persona y Rol para saber quién lo vendió y qué cargo tiene
INNER JOIN Usuario u 
    ON v.id_persona_usuario = u.id_persona_usuario
INNER JOIN Persona p 
    ON u.id_persona_usuario = p.id_persona
INNER JOIN Rol r 
    ON u.id_rol = r.id_rol
-- Unimos con Medio de Pago
INNER JOIN MedioPago mp 
    ON v.id_medio_pago = mp.id_medio_pago
-- Unimos el Detalle, Producto y Categoría para saber qué se vendió
INNER JOIN DetalleVenta dv 
    ON v.id_venta = dv.id_venta
INNER JOIN Producto pr 
    ON dv.id_producto = pr.id_producto
INNER JOIN Categoria c 
    ON pr.id_categoria = c.id_categoria
GROUP BY 
    r.nombre,
    p.apellido,
    p.nombre,
    c.nombre,
    mp.tipo
HAVING 
    SUM(dv.cantidad * dv.precio_congelado) > (
        -- Subconsulta: Calcula el valor del ticket promedio general de la tienda
        SELECT AVG(total_venta) FROM Venta
    )
ORDER BY 
    recaudacion_total DESC;
GO
