USE sistema_matiensos;
GO

-- =========================================================================
-- SCRIPT DE PRUEBA: Procedimiento sp_RegistrarVenta
-- Demuestra el comportamiento transaccional ACID ante operaciones válidas
-- y ante intentos de violación de reglas de negocio (Stock insuficiente).
-- =========================================================================

PRINT '==================================================';
PRINT 'CASO 1: VENTA EXITOSA CON CLIENTE NOMINADO';
PRINT '==================================================';

-- Consultamos stock previo del producto 2
SELECT id_producto, nombre, stock_actual, precio 
FROM Producto 
WHERE id_producto = 2;

-- 1. Preparamos el carrito en la tabla temporal en memoria
IF OBJECT_ID('tempdb..#DetalleTemp') IS NOT NULL DROP TABLE #DetalleTemp;

CREATE TABLE #DetalleTemp (
    id_producto INT NOT NULL,
    cantidad    INT NOT NULL
);

-- Cargamos 2 unidades del producto 2
INSERT INTO #DetalleTemp (id_producto, cantidad) 
VALUES (2, 2);

-- 2. Ejecutamos el Stored Procedure
DECLARE @IdVentaGenerada INT;

EXEC sp_RegistrarVenta
    @id_medio_pago      = 1,
    @id_persona_usuario = 1,
    @id_persona_cliente = 10,
    @id_venta_generada  = @IdVentaGenerada OUTPUT;

PRINT 'Venta registrada con éxito. ID generado: ' + CAST(@IdVentaGenerada AS VARCHAR(10));

-- 3. Verificamos que se haya registrado la venta y el stock se haya descontado en 2
SELECT * FROM Venta WHERE id_venta = @IdVentaGenerada;
SELECT * FROM DetalleVenta WHERE id_venta = @IdVentaGenerada;
SELECT id_producto, nombre, stock_actual FROM Producto WHERE id_producto = 2;

DROP TABLE #DetalleTemp;
GO

PRINT '==================================================';
PRINT 'CASO 2: FALLA Y ROLLBACK AUTOMÁTICO (STOCK INSUFICIENTE)';
PRINT '==================================================';

-- Preparamos un intento de compra con cantidad excesiva (ej. 9999 unidades)
IF OBJECT_ID('tempdb..#DetalleTemp') IS NOT NULL DROP TABLE #DetalleTemp;

CREATE TABLE #DetalleTemp (
    id_producto INT NOT NULL,
    cantidad    INT NOT NULL
);

INSERT INTO #DetalleTemp (id_producto, cantidad) 
VALUES (2, 9999);

BEGIN TRY
    DECLARE @IdVentaFallida INT;

    EXEC sp_RegistrarVenta
        @id_medio_pago      = 1,
        @id_persona_usuario = 1,
        @id_persona_cliente = 4,
        @id_venta_generada  = @IdVentaFallida OUTPUT;

    PRINT 'ERROR: La venta no debió procesarse.';
END TRY
BEGIN CATCH
    PRINT 'ÉXITO DEL CONTROL TRANSACCIONAL: La transacción fue abortada correctamente.';
    PRINT 'Mensaje capturado: ' + ERROR_MESSAGE();
END CATCH;

DROP TABLE #DetalleTemp;
GO
