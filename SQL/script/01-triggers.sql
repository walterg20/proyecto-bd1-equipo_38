/*  SISTEMA DE VENTAS MATIENSOS - Setup 01: Disparadores */
USE sistema_matiensos;
GO

/* 1. Auditoria automatica de Producto (AFTER UPDATE, DELETE) */
IF OBJECT_ID('dbo.tr_auditoria_producto', 'TR') IS NOT NULL
    DROP TRIGGER dbo.tr_auditoria_producto;
GO

CREATE TRIGGER dbo.tr_auditoria_producto
ON dbo.Producto
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @operacion VARCHAR(10);
    IF EXISTS (SELECT 1 FROM inserted)
        SET @operacion = 'UPDATE';
    ELSE
        SET @operacion = 'DELETE';

    INSERT INTO dbo.auditoria_producto (
        id_producto, nombre_ant, stock_actual_ant, precio_ant, esta_activo_ant,
        id_categoria_ant, operacion, usuario_bd
    )
    SELECT d.id_producto, d.nombre, d.stock_actual, d.precio, d.esta_activo,
           d.id_categoria, @operacion, SUSER_SNAME()
    FROM deleted d;
END;
GO

/* 2. Proteccion de borrado de categorias (INSTEAD OF DELETE) */
IF OBJECT_ID('dbo.tr_control_delete_categoria', 'TR') IS NOT NULL
    DROP TRIGGER dbo.tr_control_delete_categoria;
GO

CREATE TRIGGER dbo.tr_control_delete_categoria
ON dbo.Categoria
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM dbo.Producto p
        INNER JOIN deleted d ON p.id_categoria = d.id_categoria
    )
    BEGIN
        RAISERROR('Operacion cancelada: No es posible eliminar una categoria que tenga productos asociados.', 16, 1);
        RETURN;
    END;

    DELETE FROM dbo.Categoria
    WHERE id_categoria IN (SELECT id_categoria FROM deleted);
END;
GO

/* 3. Recalculo de total_venta al insertar en DetalleVenta */
CREATE OR ALTER TRIGGER dbo.tr_DetalleVenta_Insert
ON dbo.DetalleVenta
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH VentasAfectadas AS (
        SELECT DISTINCT id_venta FROM inserted
    ),
    TotalesCalculados AS (
        SELECT va.id_venta,
               ISNULL(SUM(dv.cantidad * dv.precio_congelado), 0.00) AS nuevo_total
        FROM VentasAfectadas va
        INNER JOIN dbo.DetalleVenta dv ON va.id_venta = dv.id_venta
        GROUP BY va.id_venta
    )
    UPDATE v
    SET v.total_venta = tc.nuevo_total
    FROM dbo.Venta v
    INNER JOIN TotalesCalculados tc ON v.id_venta = tc.id_venta;
END;
GO

/* 4. Recalculo de total_venta al actualizar DetalleVenta */
CREATE OR ALTER TRIGGER dbo.tr_DetalleVenta_Update
ON dbo.DetalleVenta
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(cantidad) OR UPDATE(precio_congelado) OR UPDATE(id_venta)
    BEGIN
        ;WITH VentasAfectadas AS (
            SELECT id_venta FROM inserted
            UNION
            SELECT id_venta FROM deleted
        ),
        TotalesCalculados AS (
            SELECT va.id_venta,
                   ISNULL(SUM(dv.cantidad * dv.precio_congelado), 0.00) AS nuevo_total
            FROM VentasAfectadas va
            LEFT JOIN dbo.DetalleVenta dv ON va.id_venta = dv.id_venta
            GROUP BY va.id_venta
        )
        UPDATE v
        SET v.total_venta = tc.nuevo_total
        FROM dbo.Venta v
        INNER JOIN TotalesCalculados tc ON v.id_venta = tc.id_venta
        WHERE tc.nuevo_total > 0;
    END
END;
GO

/* 5. Recalculo de total_venta al eliminar de DetalleVenta */
CREATE OR ALTER TRIGGER dbo.tr_DetalleVenta_Delete
ON dbo.DetalleVenta
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH VentasAfectadas AS (
        SELECT DISTINCT id_venta FROM deleted
    ),
    TotalesCalculados AS (
        SELECT va.id_venta,
               ISNULL(SUM(dv.cantidad * dv.precio_congelado), 0.00) AS nuevo_total
        FROM VentasAfectadas va
        LEFT JOIN dbo.DetalleVenta dv ON va.id_venta = dv.id_venta
        GROUP BY va.id_venta
    )
    UPDATE v
    SET v.total_venta = tc.nuevo_total
    FROM dbo.Venta v
    INNER JOIN TotalesCalculados tc ON v.id_venta = tc.id_venta
    WHERE tc.nuevo_total > 0;
END;
GO

PRINT '01-triggers.sql: disparadores creados correctamente.';
GO
