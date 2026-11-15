/* ============================================================================
   SISTEMA DE VENTAS MATIENSOS - PRUEBA DE EXPOSICION
   TEMA 1: PROCEDIMIENTOS ALMACENADOS Y FUNCIONES ESCALARES

   EXPLICACION TEORICA:
   - Un procedimiento almacenado (Stored Procedure) es un programa T-SQL guardado
     en el catalogo de la base de datos. Recibe parametros, ejecuta DML
     (INSERT/UPDATE/DELETE), gestiona transacciones y centraliza reglas de
     negocio en el motor.
   - Una funcion escalar (UDF) es una rutina de solo lectura que calcula y
     retorna un unico valor. Se integra en SELECT, WHERE o JOIN.

   CASO PRACTICO EN MATIENSOS:
   - fn_CalcularDescuentoCliente: calcula el descuento del cliente segun su
     gasto historico acumulado (10% si supera $500.000; 5% si supera $200.000).
   - sp_RegistrarVentaCompleta: registra una venta de mostrador validando stock,
     aplicando el descuento, congelando el precio en DetalleVenta y descontando
     stock en Producto.

   RESULTADO ESPERADO:
   - Se ve el descuento por cliente.
   - La venta queda registrada con total con descuento.
   - DetalleVenta conserva el precio de lista (precio_congelado).
   - El stock del producto disminuye.
   ============================================================================ */
USE sistema_matiensos;
GO
SET NOCOUNT ON;
GO

PRINT '=========================================================================';
PRINT 'TEMA 1: PROCEDIMIENTOS ALMACENADOS Y FUNCIONES ESCALARES';
PRINT '=========================================================================';

PRINT '';
PRINT '--- 1.1 Funcion escalar: descuento por cliente ---';
SELECT
    c.id_persona_cliente AS id_cliente,
    p.nombre + ' ' + p.apellido AS cliente,
    ISNULL(SUM(dv.cantidad * dv.precio_congelado), 0.00) AS total_gastado_historico,
    dbo.fn_CalcularDescuentoCliente(c.id_persona_cliente) AS descuento_aplicable
FROM dbo.Cliente c
INNER JOIN dbo.Persona p ON c.id_persona_cliente = p.id_persona
LEFT JOIN dbo.Venta v ON c.id_persona_cliente = v.id_persona_cliente
LEFT JOIN dbo.DetalleVenta dv ON v.id_venta = dv.id_venta
GROUP BY c.id_persona_cliente, p.nombre, p.apellido
ORDER BY c.id_persona_cliente;
GO

PRINT '';
PRINT '--- 1.2 Procedimiento almacenado: venta de mostrador ---';
DECLARE @IdVentaGenerada INT;

EXEC dbo.sp_RegistrarVentaCompleta
    @id_persona_usuario = 2,
    @id_persona_cliente = 4,
    @id_medio_pago     = 1,
    @id_producto       = 1,
    @cantidad          = 1,
    @id_venta_generada = @IdVentaGenerada OUTPUT;

PRINT 'Venta registrada. ID de comprobante: ' + CAST(@IdVentaGenerada AS VARCHAR(10));
GO

-- La variable @IdVentaGenerada no persiste entre GO; se recupera la ultima venta.
PRINT '';
PRINT '--- 1.3 Verificacion de la venta generada ---';
SELECT TOP 1
    v.id_venta,
    v.fecha_hora,
    v.total_venta AS total_con_descuento,
    v.id_persona_cliente
FROM dbo.Venta v
ORDER BY v.id_venta DESC;

PRINT '';
PRINT '--- 1.4 Detalle con precio congelado (precio de lista) ---';
SELECT TOP 1
    dv.id_venta,
    dv.id_producto,
    dv.precio_congelado AS precio_lista_congelado,
    dv.cantidad,
    dv.cantidad * dv.precio_congelado AS subtotal_a_precio_lista
FROM dbo.DetalleVenta dv
ORDER BY dv.id_venta DESC;

PRINT '';
PRINT '--- 1.5 Stock descontado del producto vendido ---';
SELECT id_producto, nombre, stock_actual
FROM dbo.Producto
WHERE id_producto = 1;
GO

/* PREGUNTA PROBABLE DEL PROFESOR:
   "¿Por que el total de Venta no coincide con cantidad * precio_congelado?"
   Respuesta: porque sp_RegistrarVentaCompleta aplica el descuento al total_venta,
   mientras que precio_congelado guarda el precio de lista historico para
   auditoria contable. El trigger de DetalleVenta recalcula el total a precio
   de lista y el procedimiento lo restaura al total con descuento. */
GO