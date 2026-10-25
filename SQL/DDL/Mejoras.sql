USE sistema_matiensos;
GO
--Cambio de nombre
EXEC sp_rename 'Detalle_Venta', 'DetalleVenta';

EXEC sp_rename 'medio_pago', 'MedioPago';

EXEC sp_rename 'producto', 'Producto';

EXEC sp_rename 'proveedor', 'Proveedor';

EXEC sp_rename 'producto_proveedor', 'ProductoProveedor';

--se agrego relacion entre tabla DetalleVenta y producto (tiene muchos productos)

ALTER TABLE DetalleVenta ADD CONSTRAINT fk_producto FOREIGN KEY (id_producto) REFERENCES producto(id_producto);

--  Eliminamos el trigger tr_Venta_AutoIncremento para evitar interferencias
IF OBJECT_ID('tr_Venta_AutoIncremento', 'TR') IS NOT NULL
BEGIN
    DROP TRIGGER tr_Venta_AutoIncremento;
    PRINT 'Trigger [tr_Venta_AutoIncremento] eliminado correctamente (reemplazado por sp_RegistrarVenta).';
END;
GO

--  Creación / Actualización del Stored Procedure
CREATE OR ALTER PROCEDURE sp_RegistrarVenta
    @id_medio_pago        INT,
    @id_persona_usuario   INT,
    @id_persona_cliente   INT = NULL, -- Acepta NULL para Consumidor Final
    @id_venta_generada    INT OUTPUT  -- Retorna el ID asignado
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY

        --  Validar existencia de la tabla temporal de sesión
        IF OBJECT_ID('tempdb..#DetalleTemp') IS NULL
        BEGIN
            THROW 50001, 'Error: No se definió la tabla temporal #DetalleTemp con los productos a vender.', 1;
        END;

        -- B Validar que contenga renglones
        IF NOT EXISTS (SELECT 1 FROM #DetalleTemp)
        BEGIN
            THROW 50002, 'Error: La tabla #DetalleTemp está vacía. Ingrese al menos un artículo para la venta.', 1;
        END;

        --  Validar cantidades positivas
        IF EXISTS (SELECT 1 FROM #DetalleTemp WHERE cantidad <= 0)
        BEGIN
            THROW 50003, 'Error: La cantidad de cada producto debe ser estrictamente mayor a cero.', 1;
        END;

        --  Validar claves foráneas de cabecera
        IF NOT EXISTS (SELECT 1 FROM Usuario WHERE id_persona_usuario = @id_persona_usuario)
        BEGIN
            THROW 50004, 'Error: El usuario vendedor especificado no existe.', 1;
        END;

        IF NOT EXISTS (SELECT 1 FROM MedioPago WHERE id_medio_pago = @id_medio_pago)
        BEGIN
            THROW 50005, 'Error: El medio de pago especificado no existe.', 1;
        END;

        IF @id_persona_cliente IS NOT NULL 
           AND NOT EXISTS (SELECT 1 FROM Cliente WHERE id_persona_cliente = @id_persona_cliente)
        BEGIN
            THROW 50006, 'Error: El cliente especificado no existe.', 1;
        END;

        -- Validar existencia y estado activo de todos los productos del carrito
        IF EXISTS (
            SELECT 1 
            FROM #DetalleTemp t 
            LEFT JOIN Producto p ON t.id_producto = p.id_producto
            WHERE p.id_producto IS NULL OR p.esta_activo <> '1'
        )
        BEGIN
            THROW 50007, 'Error: Uno o más productos seleccionados no existen o están inactivos (baja lógica).', 1;
        END;

        --  Validar disponibilidad de stock en inventario
        IF EXISTS (
            SELECT 1
            FROM #DetalleTemp t
            INNER JOIN Producto p ON t.id_producto = p.id_producto
            WHERE p.stock_actual < t.cantidad
        )
        BEGIN
            THROW 50008, 'Error: Stock insuficiente para uno o más artículos seleccionados.', 1;
        END;

        BEGIN TRANSACTION;

        --  Generar id_venta seguro protegiendo contra condiciones de carrera
        --    UPDLOCK: Bloquea intentos simultáneos de lectura para actualización.
        --    HOLDLOCK: Mantiene el bloqueo exclusivo hasta el COMMIT/ROLLBACK final.
        SELECT @id_venta_generada = ISNULL(MAX(id_venta), 0) + 1
        FROM Venta WITH (UPDLOCK, HOLDLOCK);

        --  Calcular el total monetario real según el precio vigente de catálogo
        DECLARE @TotalCalculado DECIMAL(10,2);
        SELECT @TotalCalculado = SUM(t.cantidad * p.precio)
        FROM #DetalleTemp t
        INNER JOIN Producto p ON t.id_producto = p.id_producto;

        --  Insertar la cabecera en Venta con su total real (respeta CHECK total_venta > 0)
        INSERT INTO Venta (id_venta, fecha_hora, total_venta, id_medio_pago, id_persona_usuario, id_persona_cliente)
        VALUES (
            @id_venta_generada,
            GETDATE(),
            @TotalCalculado,
            @id_medio_pago,
            @id_persona_usuario,
            @id_persona_cliente
        );

        -- 4. Insertar los ítems en DetalleVenta congelando el precio histórico
        INSERT INTO DetalleVenta (id_venta, id_producto, precio_congelado, cantidad)
        SELECT 
            @id_venta_generada,
            t.id_producto,
            p.precio,
            t.cantidad
        FROM #DetalleTemp t
        INNER JOIN Producto p ON t.id_producto = p.id_producto;

        -- 5. Descontar las existencias vendidas del stock de Producto
        UPDATE p
        SET p.stock_actual = p.stock_actual - t.cantidad
        FROM Producto p
        INNER JOIN #DetalleTemp t ON p.id_producto = t.id_producto;

        -- 6. Confirmar la transacción
        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        -- Si ocurrió cualquier excepción y la transacción quedó abierta, revertir
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Propagar el error original a la aplicación / cliente SQL
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO