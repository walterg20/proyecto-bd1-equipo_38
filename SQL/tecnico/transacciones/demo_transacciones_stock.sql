USE sistema_matiensos;
GO

/* =============================================================================
    TEMA 2: MANEJO DE TRANSACCIONES
    Script: demo_transacciones_stock.sql
    Demostración práctica de las propiedades ACID (especialmente Atomicidad)
    mediante bloques transaccionales explícitos BEGIN TRANSACTION, 
    COMMIT y ROLLBACK aplicados a ventas con control de inventario.
   ============================================================================= */

-- =============================================================================
-- DEMO 1: Transacción Exitosa con Stock Suficiente (COMMIT)
-- =============================================================================
PRINT '>>> INICIANDO PRUEBA 1: VENTA CON STOCK SUFICIENTE (COMMIT) <<<';

DECLARE @ProductoId INT = 1;      -- Mate Imperial
DECLARE @CantidadComprar INT = 2;  -- Compra de 2 unidades
DECLARE @StockPrevio INT;
DECLARE @StockPosterior INT;
DECLARE @IdVentaGenerada INT;

-- Verifica el stock antes de operar
SELECT @StockPrevio = stock_actual FROM Producto WHERE id_producto = @ProductoId;
PRINT 'Stock inicial del producto ' + CAST(@ProductoId AS VARCHAR) + ': ' + CAST(@StockPrevio AS VARCHAR);

BEGIN TRY
    BEGIN TRANSACTION;
    -- Valida disponibilidad dentro de la transacción
    IF (SELECT stock_actual FROM Producto WHERE id_producto = @ProductoId) < @CantidadComprar
    BEGIN
        RAISERROR('Stock insuficiente.', 16, 1);
    END;
    -- Inserta cabecera
    INSERT INTO Venta (fecha_hora, total_venta, id_medio_pago, id_persona_usuario, id_persona_cliente)
    VALUES (GETDATE(), 90000.00, 1, 2, 4);
    -- Recupera el ID autoincremental
    SELECT @IdVentaGenerada = SCOPE_IDENTITY();
    -- Inserta detalle vinculando el ID generado
    INSERT INTO DetalleVenta (id_venta, id_producto, precio_congelado, cantidad)
    VALUES (@IdVentaGenerada, @ProductoId, 45000.00, @CantidadComprar);
    -- Descuenta el stock
    UPDATE Producto
    SET stock_actual = stock_actual - @CantidadComprar
    WHERE id_producto = @ProductoId;
    -- Si no hubo errores, confirma
    COMMIT TRANSACTION;
    PRINT '>> Transacción confirmada exitosamente con COMMIT. ID Venta: ' + CAST(@IdVentaGenerada AS VARCHAR);
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    PRINT '>> Error en la transacción: ' + ERROR_MESSAGE();
END CATCH;

-- Verifica el stock posterior
SELECT @StockPosterior = stock_actual FROM Producto WHERE id_producto = @ProductoId;
PRINT 'Stock final del producto: ' + CAST(@StockPosterior AS VARCHAR) + ' (Disminuyó en ' + CAST(@CantidadComprar AS VARCHAR) + ')';
PRINT '';
GO


-- =============================================================================
-- DEMO 2: Transacción Fallida por Stock Insuficiente (ROLLBACK)
-- =============================================================================
PRINT '>>> INICIANDO PRUEBA 2: VENTA CON STOCK INSUFICIENTE (ROLLBACK) <<<';

DECLARE @ProductoId INT = 1;
DECLARE @CantidadExcesiva INT = 99999; -- Cantidad imposible
DECLARE @StockPrevio INT;
DECLARE @StockPosterior INT;
DECLARE @IdVentaFallida INT;

-- Consulta el stock actual
SELECT @StockPrevio = stock_actual FROM Producto WHERE id_producto = @ProductoId;
PRINT 'Stock inicial antes del intento: ' + CAST(@StockPrevio AS VARCHAR);

BEGIN TRY
    BEGIN TRANSACTION;

    -- Intenta registrar la cabecera
    INSERT INTO Venta (fecha_hora, total_venta, id_medio_pago, id_persona_usuario, id_persona_cliente)
    VALUES (GETDATE(), 9999999.00, 1, 2, 4);

    -- Captura el ID asignado
    SELECT @IdVentaFallida = SCOPE_IDENTITY();
    -- Verifica si hay stock suficiente
    IF (SELECT stock_actual FROM Producto WHERE id_producto = @ProductoId) < @CantidadExcesiva
    BEGIN
        RAISERROR('Falta de existencias: Stock insuficiente para cubrir la demanda solicitada.', 16, 1);
    END;
    -- Si llegara a haber stock, continuaría
    INSERT INTO DetalleVenta (id_venta, id_producto, precio_congelado, cantidad)
    VALUES (@IdVentaFallida, @ProductoId, 45000.00, @CantidadExcesiva);

    UPDATE Producto
    SET stock_actual = stock_actual - @CantidadExcesiva
    WHERE id_producto = @ProductoId;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    PRINT '>> SE CAPTURÓ LA EXCEPCIÓN: ' + ERROR_MESSAGE();
    -- Deshace todo
    IF @@TRANCOUNT > 0
    BEGIN
        ROLLBACK TRANSACTION;
        PRINT '>> Se ejecutó ROLLBACK TRANSACTION con éxito.';
    END;
END CATCH;

-- Verificación de Atomicidad: Comprueba que el stock no cambió y no se creó la venta
SELECT @StockPosterior = stock_actual FROM Producto WHERE id_producto = @ProductoId;
PRINT 'Stock verificado tras el Rollback: ' + CAST(@StockPosterior AS VARCHAR) + ' (INTACTO)';

IF NOT EXISTS (SELECT 1 FROM Venta WHERE id_venta = @IdVentaFallida)
    PRINT '>> COMPROBACIÓN EXITOSA: No quedó ningún registro huérfano en la tabla Venta (Se revirtió el INSERT).';
GO