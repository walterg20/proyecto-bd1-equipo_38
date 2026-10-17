/* =============================================================================
   Caso 1: ---
   ============================================================================= */

--Ticket Perteneciente al cliente con id 1.
SELECT  v.id_venta AS Ticket,
       fecha_hora AS FechaHora,
       CONCAT(pv.nombre, ' ' , pv.apellido) AS Nom_Ape_Vendedor,
       mp.tipo AS MedioPago,
       CASE
           WHEN v.id_persona_cliente IS NULL THEN 'Consumidor Final'
           ELSE CONCAT(p.nombre,' ' ,p.apellido)
       END AS Nom_Ape_Cliente ,
       pr.nombre AS Producto,
       dv.cantidad AS Cantidad,
       dv.precio_congelado AS PrecioUnitario,
       (dv.cantidad * dv.precio_congelado) AS Subtotal,
       v.total_venta AS Total

FROM Venta v 
INNER JOIN MedioPago mp ON v.id_medio_pago = mp.id_medio_pago
LEFT JOIN Persona p ON v.id_persona_cliente = p.id_persona
INNER JOIN Persona pv ON v.id_persona_usuario = pv.id_persona 

INNER JOIN DetalleVenta dv ON dv.id_venta = v.id_venta
INNER JOIN Producto pr ON dv.id_producto = pr.id_producto
WHERE v.id_venta = 1; 


--Ticket perteneciente al ultimo cliente 'consumidor final'
SELECT 
    v.id_venta AS Ticket,
    v.fecha_hora AS FechaHora,
    mp.tipo AS MedioPago,
    CONCAT(pv.nombre, ' ', pv.apellido) AS Nom_Ape_Vendedor,
    'Consumidor Final' AS Nom_Ape_Cliente,
    pr.nombre AS Producto,
    dv.cantidad AS Cantidad,
    dv.precio_congelado AS PrecioUnitario,
    (dv.cantidad * dv.precio_congelado) AS Subtotal,
    v.total_venta AS TotalFinal
FROM Venta v 
INNER JOIN MedioPago mp ON v.id_medio_pago = mp.id_medio_pago
INNER JOIN Persona pv ON v.id_persona_usuario = pv.id_persona 
INNER JOIN DetalleVenta dv ON dv.id_venta = v.id_venta
INNER JOIN Producto pr ON dv.id_producto = pr.id_producto
WHERE v.id_venta = (
    SELECT MAX(id_venta) 
    FROM Venta 
    WHERE id_persona_cliente IS NULL
);