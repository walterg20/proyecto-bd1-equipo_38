-- Script de población de datos: 50 Ventas con sus DetalleVenta
USE [sistema_matiensos];
GO

SET NOCOUNT ON;

DECLARE @VentaId INT = 1;
DECLARE @id_venta_generada INT;
DECLARE @id_medio_pago INT;
DECLARE @id_persona_usuario INT;
DECLARE @id_persona_cliente INT;
DECLARE @fecha_hora DATETIME;

-- 1. Cargamos el catálogo real de productos y precios
DECLARE @Productos TABLE (
    id_producto INT,
    precio DECIMAL(18,2)
);

INSERT INTO @Productos (id_producto, precio)
SELECT id_producto, precio 
FROM producto 
WHERE id_producto BETWEEN 2 AND 11;

-- 2. Bucle para generar exactamente 50 ventas
WHILE @VentaId <= 50
BEGIN
    -- Asignación aleatoria basada en tus datos reales
    SET @id_medio_pago = ABS(CHECKSUM(NEWID())) % 3 + 1;         -- IDs: 1, 2, 3
    SET @id_persona_usuario = ABS(CHECKSUM(NEWID())) % 3 + 1;   -- IDs: 1, 2, 3
    SET @id_persona_cliente = ABS(CHECKSUM(NEWID())) % 7 + 10;  -- IDs: 10 al 16
    
    -- Fecha aleatoria dentro de los últimos 60 días
    SET @fecha_hora = DATEADD(MINUTE, (ABS(CHECKSUM(NEWID())) % 86400) * -1, GETDATE());

    -- Insertamos la cabecera (el trigger 'tr_Venta_AutoIncremento' le asignará el ID real)
    INSERT INTO Venta (fecha_hora, total_venta, id_medio_pago, id_persona_usuario, id_persona_cliente)
    VALUES (@fecha_hora, 1.00, @id_medio_pago, @id_persona_usuario, @id_persona_cliente);

    -- CORRECCIÓN: Buscamos el ID que el trigger acaba de generar para esta venta
    SELECT @id_venta_generada = MAX(id_venta) FROM Venta;

    -- Determinar cuántos productos tendrá esta venta (entre 3 y 10)
    DECLARE @CantProductos INT = ABS(CHECKSUM(NEWID())) % 8 + 3; 

    -- Tabla temporal interna para seleccionar productos únicos por venta
    DECLARE @ProdSeleccionados TABLE (id_producto INT, precio DECIMAL(18,2), cantidad INT);
    DELETE FROM @ProdSeleccionados;

    -- Selecciona N productos al azar sin repetirse
    INSERT INTO @ProdSeleccionados
    SELECT TOP (@CantProductos) id_producto, precio, (ABS(CHECKSUM(NEWID())) % 3 + 1)
    FROM @Productos
    ORDER BY NEWID();

    -- Insertar en DetalleVenta usando el ID recuperado de forma segura
    INSERT INTO DetalleVenta (id_venta, id_producto, precio_congelado, cantidad)
    SELECT @id_venta_generada, id_producto, precio, cantidad
    FROM @ProdSeleccionados;

    -- NOTA: Si implementaste el segundo trigger (tr_DetalleVenta_ActualizarTotal), 
    -- el total_venta se actualizará solo automáticamente aquí. 
    -- Si no lo pusiste, puedes descomentar las siguientes líneas:
    /*
    DECLARE @TotalVenta DECIMAL(18,2);
    SELECT @TotalVenta = SUM(precio * cantidad) FROM @ProdSeleccionados;
    UPDATE Venta SET total_venta = @TotalVenta WHERE id_venta = @id_venta_generada;
    */

    SET @VentaId = @VentaId + 1;
END;

PRINT 'Se han insertado con éxito 50 ventas con sus correspondientes detalles utilizando la lógica de triggers.';

