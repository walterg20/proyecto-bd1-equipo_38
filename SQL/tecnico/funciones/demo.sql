-- 1. Demostración de la FUNCION Escalar

SELECT 
    c.id_persona_cliente AS id_cliente,
    p.nombre + ' ' + p.apellido AS cliente,
    ISNULL(SUM(dv.cantidad * dv.precio_congelado), 0.00) AS total_gastado,
    dbo.fn_CalcularDescuentoCliente(c.id_persona_cliente) AS descuento_otorgado
FROM Cliente c
INNER JOIN Persona p ON c.id_persona_cliente = p.id_persona
LEFT JOIN Venta v ON c.id_persona_cliente = v.id_persona_cliente
LEFT JOIN DetalleVenta dv ON v.id_venta = dv.id_venta
GROUP BY c.id_persona_cliente, p.nombre, p.apellido;