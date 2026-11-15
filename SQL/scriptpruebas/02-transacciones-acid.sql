/* ============================================================================
   SISTEMA DE VENTAS MATIENSOS - PRUEBA DE EXPOSICION
   TEMA 2: MANEJO DE TRANSACCIONES Y PROPIEDADES ACID

   EXPLICACION TEORICA:
   - Una transaccion es una unidad logica de trabajo indivisible.
   - ACID: Atomicidad (todo o nada), Consistencia (estados validos),
     Aislamiento (cambios no visibles hasta COMMIT) y Durabilidad
     (COMMIT persiste ante fallos).
   - BEGIN TRANSACTION inicia, COMMIT confirma, ROLLBACK revierte.
   - TRY/CATCH captura errores y permite revertir de forma controlada.

   CASO PRACTICO EN MATIENSOS:
   - Vender 2 unidades de un producto con stock suficiente: se inserta Venta,
     DetalleVenta y se descuenta stock; si todo va bien, COMMIT.
   - Intentar vender 99.999 unidades con stock insuficiente: RAISERROR y
     ROLLBACK, dejando stock y tablas intactas.

   RESULTADO ESPERADO:
   - Demo 1: stock baja en 2 y se crea la venta.
   - Demo 2: stock no cambia y no queda venta huérfana.
   ============================================================================ */
USE sistema_matiensos;
GO
SET NOCOUNT ON;
GO

-- Estandariza el stock del producto demo para que la salida sea reproducible.
UPDATE dbo.Producto SET stock_actual = 25 WHERE id_producto = 1;
GO

PRINT '=========================================================================';
PRINT 'TEMA 2: MANEJO DE TRANSACCIONES Y PROPIEDADES ACID';
PRINT '=========================================================================';

-- =============================================================================
-- DEMO 1: Transaccion exitosa (COMMIT)
-- =============================================================================
PRINT '';
PRINT '>>> DEMO 1: VENTA CON STOCK SUFICIENTE (COMMIT) <<<';

DECLARE @ProductoId INT = 1;
DECLARE @Cantidad INT = 2;
DECLARE @StockPrevio INT;
DECLARE @StockPosterior INT;
DECLARE @IdVenta INT;

SELECT @StockPrevio = stock_actual FROM dbo.Producto WHERE id_producto = @ProductoId;
PRINT 'Stock inicial del producto ' + CAST(@ProductoId AS VARCHAR(10)) + ': ' + CAST(@StockPrevio AS VARCHAR(10));

BEGIN TRY
    BEGIN TRANSACTION;

    IF (SELECT stock_actual FROM dbo.Producto WHERE id_producto = @ProductoId) < @Cantidad
        RAISERROR('Stock insuficiente para concretar la venta.', 16, 1);

    INSERT INTO dbo.Venta (fecha_hora, total_venta, id_medio_pago, id_persona_usuario, id_persona_cliente)
    VALUES (GETDATE(), 90000.00, 1, 2, 4);

    SET @IdVenta = SCOPE_IDENTITY();

    INSERT INTO dbo.DetalleVenta (id_venta, id_producto, precio_congelado, cantidad)
    VALUES (@IdVenta, @ProductoId, 45000.00, @Cantidad);

    UPDATE dbo.Producto
    SET stock_actual = stock_actual - @Cantidad
    WHERE id_producto = @ProductoId;

    COMMIT TRANSACTION;
    PRINT 'Transaccion confirmada con COMMIT. ID Venta: ' + CAST(@IdVenta AS VARCHAR(10));
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    PRINT 'Error en la transaccion: ' + ERROR_MESSAGE();
END CATCH;

SELECT @StockPosterior = stock_actual FROM dbo.Producto WHERE id_producto = @ProductoId;
PRINT 'Stock final del producto: ' + CAST(@StockPosterior AS VARCHAR(10)) + ' (disminuyo en ' + CAST(@Cantidad AS VARCHAR(10)) + ')';
GO

-- =============================================================================
-- DEMO 2: Transaccion fallida (ROLLBACK)
-- =============================================================================
PRINT '';
PRINT '>>> DEMO 2: VENTA CON STOCK INSUFICIENTE (ROLLBACK) <<<';

DECLARE @ProductoId INT = 1;
DECLARE @CantidadExcesiva INT = 99999;
DECLARE @StockPrevio INT;
DECLARE @StockPosterior INT;
DECLARE @IdVentaFallida INT;

SELECT @StockPrevio = stock_actual FROM dbo.Producto WHERE id_producto = @ProductoId;
PRINT 'Stock inicial antes del intento: ' + CAST(@StockPrevio AS VARCHAR(10));

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO dbo.Venta (fecha_hora, total_venta, id_medio_pago, id_persona_usuario, id_persona_cliente)
    VALUES (GETDATE(), 9999999.00, 1, 2, 4);

    SET @IdVentaFallida = SCOPE_IDENTITY();

    IF (SELECT stock_actual FROM dbo.Producto WHERE id_producto = @ProductoId) < @CantidadExcesiva
        RAISERROR('Falta de existencias: stock insuficiente para cubrir la demanda solicitada.', 16, 1);

    INSERT INTO dbo.DetalleVenta (id_venta, id_producto, precio_congelado, cantidad)
    VALUES (@IdVentaFallida, @ProductoId, 45000.00, @CantidadExcesiva);

    UPDATE dbo.Producto
    SET stock_actual = stock_actual - @CantidadExcesiva
    WHERE id_producto = @ProductoId;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    PRINT 'Se capturo la excepcion: ' + ERROR_MESSAGE();
    IF @@TRANCOUNT > 0
    BEGIN
        ROLLBACK TRANSACTION;
        PRINT 'Se ejecuto ROLLBACK TRANSACTION con exito.';
    END;
END CATCH;

SELECT @StockPosterior = stock_actual FROM dbo.Producto WHERE id_producto = @ProductoId;
PRINT 'Stock verificado tras el rollback: ' + CAST(@StockPosterior AS VARCHAR(10)) + ' (INTACTO)';

IF NOT EXISTS (SELECT 1 FROM dbo.Venta WHERE id_venta = @IdVentaFallida)
    PRINT 'Comprobacion exitosa: no quedo ningun registro huerfano en Venta.';
GO

/* PREGUNTA PROBABLE DEL PROFESOR:
   "¿Que pasaria si no usaran TRY/CATCH?"
   Respuesta: el error abortaria la sentencia, pero sin control explicito podria
   quedar la transaccion abierta o aplicarse parcialmente; con TRY/CATCH se
   garantiza ROLLBACK y atomicidad. */
GO