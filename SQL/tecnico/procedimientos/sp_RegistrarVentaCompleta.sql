USE sistema_matiensos;
GO

/* =============================================================================
    TEMA 1: PROCEDIMIENTOS ALMACENADOS
    Objeto: dbo.sp_RegistrarVentaCompleta
    Procedimiento almacenado que encapsula la emisión integral de una
    venta en mostrador, calculando descuentos y congelando precios.
   ============================================================================= */

IF OBJECT_ID('dbo.sp_RegistrarVentaCompleta', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_RegistrarVentaCompleta;
GO

CREATE PROCEDURE dbo.sp_RegistrarVentaCompleta
    @id_persona_usuario INT,       -- Vendedor
    @id_persona_cliente INT,       -- Cliente (o NULL para Consumidor Final)
    @id_medio_pago INT,            -- Efectivo, Tarjeta, etc.
    @id_producto INT,              -- Producto
    @cantidad INT,                 -- Unidades solicitadas
    @id_venta_generada INT OUTPUT  -- ID asignado a la nueva venta
AS
BEGIN
    SET NOCOUNT ON;

    -- Validaciones iniciales
    IF @cantidad <= 0
    BEGIN
        RAISERROR('La cantidad solicitada debe ser mayor a cero.', 16, 1);
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM Producto WHERE id_producto = @id_producto AND esta_activo = '1')
    BEGIN
        RAISERROR('El producto especificado no existe o no se encuentra activo.', 16, 1);
        RETURN;
    END;

    -- Variables de calculo
    DECLARE @PrecioLista DECIMAL(10,2);
    DECLARE @StockDisponible INT;
    DECLARE @PorcentajeDescuento DECIMAL(4,2);
    DECLARE @SubtotalBruto DECIMAL(10,2);
    DECLARE @TotalConDescuento DECIMAL(10,2);
    DECLARE @NuevoIdVenta INT;

    -- Obtiene el precio de lista y stock actual
    SELECT @PrecioLista = precio, @StockDisponible = stock_actual
    FROM Producto
    WHERE id_producto = @id_producto;

    -- Verifica existencia de stock
    IF @StockDisponible < @cantidad
    BEGIN
        RAISERROR('Stock insuficiente para concretar la venta.', 16, 1);
        RETURN;
    END;

    -- Invoca la función de descuento según fidelidad del cliente
    SET @PorcentajeDescuento = dbo.fn_CalcularDescuentoCliente(@id_persona_cliente);
    -- Cálculos económicos
    SET @SubtotalBruto = @PrecioLista * @cantidad;
    SET @TotalConDescuento = @SubtotalBruto * (1.00 - @PorcentajeDescuento);

    -- Inserta encabezado
    INSERT INTO Venta (fecha_hora, total_venta, id_medio_pago, id_persona_usuario, id_persona_cliente)
    VALUES (GETDATE(), @TotalConDescuento, @id_medio_pago, @id_persona_usuario, @id_persona_cliente);
    
    -- Próximo ID de venta
    SELECT @NuevoIdVenta = SCOPE_IDENTITY();

    -- Inserta renglón de detalle
    INSERT INTO DetalleVenta (id_venta, id_producto, precio_congelado, cantidad)
    VALUES (@NuevoIdVenta, @id_producto, @PrecioLista, @cantidad);
    
    -- Se descuenta el stock del inventario
    UPDATE Producto
    SET stock_actual = stock_actual - @cantidad
    WHERE id_producto = @id_producto;

    -- Devuelve el ID de la venta creada
    SET @id_venta_generada = @NuevoIdVenta;
    PRINT 'Venta registrada con éxito. ID Comprobante: ' + CAST(@NuevoIdVenta AS VARCHAR(10));
END;
GO