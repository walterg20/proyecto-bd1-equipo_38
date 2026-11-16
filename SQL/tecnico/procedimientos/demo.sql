-- 2. Demostración del PROCEDIMIENTO Almacenado:

-- Consulta el stock actual
SELECT id_producto, nombre, stock_actual, precio 
FROM Producto 
WHERE id_producto = 5;

DECLARE @NuevaVenta INT;

-- Ejecuta el SP vendiendo el producto 5 al cliente 5 (con 10% de descuento) atendido por el vendedor 2:
EXEC dbo.sp_RegistrarVentaCompleta
    @id_persona_usuario = 2,
    @id_persona_cliente = 5,
    @id_medio_pago = 1,
    @id_producto = 5,
    @cantidad = 1,
    @id_venta_generada = @NuevaVenta OUTPUT;

-- Verifica la venta y el stock final:
SELECT * 
FROM Venta 
WHERE id_venta = @NuevaVenta;

SELECT * 
FROM DetalleVenta 
WHERE id_venta = @NuevaVenta;

SELECT id_producto, nombre, stock_actual
FROM Producto 
WHERE id_producto = 5;