/*  SISTEMA DE VENTAS MATIENSOS - Setup 03: Funciones y procedimientos almacenados */
USE sistema_matiensos;
GO

/* ===================== FUNCION ===================== */

IF OBJECT_ID('dbo.fn_CalcularDescuentoCliente', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_CalcularDescuentoCliente;
GO

CREATE FUNCTION dbo.fn_CalcularDescuentoCliente (@id_persona_cliente INT)
RETURNS DECIMAL(4,2)
AS
BEGIN
    DECLARE @TotalAcumulado DECIMAL(12,2) = 0.00;
    DECLARE @PorcentajeDescuento DECIMAL(4,2) = 0.00;

    IF @id_persona_cliente IS NULL
        RETURN 0.00;

    SELECT @TotalAcumulado = ISNULL(SUM(dv.cantidad * dv.precio_congelado), 0.00)
    FROM dbo.Venta v
    INNER JOIN dbo.DetalleVenta dv ON v.id_venta = dv.id_venta
    WHERE v.id_persona_cliente = @id_persona_cliente;

    IF @TotalAcumulado > 500000.00
        SET @PorcentajeDescuento = 0.10;
    ELSE IF @TotalAcumulado > 200000.00
        SET @PorcentajeDescuento = 0.05;
    ELSE
        SET @PorcentajeDescuento = 0.00;

    RETURN @PorcentajeDescuento;
END;
GO

/* ===================== PROCEDIMIENTO: VENTA MULTI-ITEM ===================== */

IF OBJECT_ID('dbo.sp_RegistrarVenta', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_RegistrarVenta;
GO

CREATE PROCEDURE dbo.sp_RegistrarVenta
    @id_medio_pago      INT,
    @id_persona_usuario INT,
    @id_persona_cliente INT = NULL,
    @id_venta_generada  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF OBJECT_ID('tempdb..#DetalleTemp') IS NULL
            THROW 50001, 'Error: No se definio la tabla temporal #DetalleTemp con los productos a vender.', 1;

        IF NOT EXISTS (SELECT 1 FROM #DetalleTemp)
            THROW 50002, 'Error: La tabla #DetalleTemp esta vacia.', 1;

        IF EXISTS (SELECT 1 FROM #DetalleTemp WHERE cantidad <= 0)
            THROW 50003, 'Error: La cantidad de cada producto debe ser mayor a cero.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.Usuario WHERE id_persona_usuario = @id_persona_usuario)
            THROW 50004, 'Error: El usuario vendedor especificado no existe.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.MedioPago WHERE id_medio_pago = @id_medio_pago)
            THROW 50005, 'Error: El medio de pago especificado no existe.', 1;

        IF @id_persona_cliente IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM dbo.Cliente WHERE id_persona_cliente = @id_persona_cliente)
            THROW 50006, 'Error: El cliente especificado no existe.', 1;

        IF EXISTS (
            SELECT 1
            FROM #DetalleTemp t
            LEFT JOIN dbo.Producto p ON t.id_producto = p.id_producto
            WHERE p.id_producto IS NULL OR p.esta_activo <> '1'
        )
            THROW 50007, 'Error: Uno o mas productos no existen o estan inactivos.', 1;

        IF EXISTS (
            SELECT 1
            FROM #DetalleTemp t
            INNER JOIN dbo.Producto p ON t.id_producto = p.id_producto
            WHERE p.stock_actual < t.cantidad
        )
            THROW 50008, 'Error: Stock insuficiente para uno o mas articulos.', 1;

        DECLARE @TotalCalculado DECIMAL(10,2);
        SELECT @TotalCalculado = SUM(t.cantidad * p.precio)
        FROM #DetalleTemp t
        INNER JOIN dbo.Producto p ON t.id_producto = p.id_producto;

        BEGIN TRANSACTION;

        INSERT INTO dbo.Venta (fecha_hora, total_venta, id_medio_pago, id_persona_usuario, id_persona_cliente)
        VALUES (GETDATE(), @TotalCalculado, @id_medio_pago, @id_persona_usuario, @id_persona_cliente);

        SET @id_venta_generada = SCOPE_IDENTITY();

        INSERT INTO dbo.DetalleVenta (id_venta, id_producto, precio_congelado, cantidad)
        SELECT @id_venta_generada, t.id_producto, p.precio, t.cantidad
        FROM #DetalleTemp t
        INNER JOIN dbo.Producto p ON t.id_producto = p.id_producto;

        UPDATE p
        SET p.stock_actual = p.stock_actual - t.cantidad
        FROM dbo.Producto p
        INNER JOIN #DetalleTemp t ON p.id_producto = t.id_producto;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

/* ===================== PROCEDIMIENTO: VENTA UNITARIA CON DESCUENTO ===================== */

IF OBJECT_ID('dbo.sp_RegistrarVentaCompleta', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_RegistrarVentaCompleta;
GO

CREATE PROCEDURE dbo.sp_RegistrarVentaCompleta
    @id_persona_usuario  INT,
    @id_persona_cliente  INT = NULL,
    @id_medio_pago       INT,
    @id_producto         INT,
    @cantidad            INT,
    @id_venta_generada   INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @cantidad <= 0
        BEGIN
            RAISERROR('La cantidad solicitada debe ser mayor a cero.', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.Producto WHERE id_producto = @id_producto AND esta_activo = '1')
        BEGIN
            RAISERROR('El producto especificado no existe o no se encuentra activo.', 16, 1);
            RETURN;
        END;

        DECLARE @PrecioLista DECIMAL(10,2);
        DECLARE @StockDisponible INT;
        DECLARE @PorcentajeDescuento DECIMAL(4,2);
        DECLARE @SubtotalBruto DECIMAL(10,2);
        DECLARE @TotalConDescuento DECIMAL(10,2);

        SELECT @PrecioLista = precio, @StockDisponible = stock_actual
        FROM dbo.Producto
        WHERE id_producto = @id_producto;

        IF @StockDisponible < @cantidad
        BEGIN
            RAISERROR('Stock insuficiente para concretar la venta.', 16, 1);
            RETURN;
        END;

        SET @PorcentajeDescuento = dbo.fn_CalcularDescuentoCliente(@id_persona_cliente);
        SET @SubtotalBruto = @PrecioLista * @cantidad;
        SET @TotalConDescuento = @SubtotalBruto * (1.00 - @PorcentajeDescuento);

        BEGIN TRANSACTION;

        INSERT INTO dbo.Venta (fecha_hora, total_venta, id_medio_pago, id_persona_usuario, id_persona_cliente)
        VALUES (GETDATE(), @TotalConDescuento, @id_medio_pago, @id_persona_usuario, @id_persona_cliente);

        SET @id_venta_generada = SCOPE_IDENTITY();

        INSERT INTO dbo.DetalleVenta (id_venta, id_producto, precio_congelado, cantidad)
        VALUES (@id_venta_generada, @id_producto, @PrecioLista, @cantidad);

        -- El trigger recalcula total a precio de lista; restauramos el total con descuento.
        UPDATE dbo.Venta
        SET total_venta = @TotalConDescuento
        WHERE id_venta = @id_venta_generada;

        UPDATE dbo.Producto
        SET stock_actual = stock_actual - @cantidad
        WHERE id_producto = @id_producto;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

PRINT '03-procedimientos.sql: funciones y procedimientos creados.';
GO
