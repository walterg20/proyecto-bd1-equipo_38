CREATE TRIGGER tr_Venta_AutoIncremento
ON Venta
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UltimoId INT;
    SELECT @UltimoId = ISNULL(MAX(id_venta), 0) FROM Venta;

    -- Inserta las filas asignando un valor inicial de 1.00 para evitar el CHECK de total_venta > 0
    INSERT INTO Venta (id_venta, fecha_hora, total_venta, id_medio_pago, id_persona_usuario, id_persona_cliente)
    SELECT 
        @UltimoId + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)),
        fecha_hora,
        1.00, 
        id_medio_pago,
        id_persona_usuario,
        id_persona_cliente
    FROM inserted;
END;
GO

-- =========================================================================
-- TRIGGER AFTER INSERT en DetalleVenta
-- Descripción: Recalcula total_venta al insertar nuevos productos en una venta.
-- =========================================================================
CREATE OR ALTER TRIGGER tr_DetalleVenta_Insert
ON DetalleVenta
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH VentasAfectadas AS (
        SELECT DISTINCT id_venta FROM inserted
    ),
    TotalesCalculados AS (
        SELECT 
            va.id_venta,
            ISNULL(SUM(dv.cantidad * dv.precio_congelado), 0.00) AS nuevo_total
        FROM VentasAfectadas va
        INNER JOIN DetalleVenta dv ON va.id_venta = dv.id_venta
        GROUP BY va.id_venta
    )
    UPDATE v
    SET v.total_venta = tc.nuevo_total
    FROM Venta v
    INNER JOIN TotalesCalculados tc ON v.id_venta = tc.id_venta;
END;
GO

-- =========================================================================
-- TRIGGER AFTER UPDATE en DetalleVenta
-- Descripción: Recalcula total_venta al modificar cantidad o precio congelado.
-- =========================================================================
CREATE OR ALTER TRIGGER tr_DetalleVenta_Update
ON DetalleVenta
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Solo actuar si cambiaron columnas que afectan el cálculo del total
    IF UPDATE(cantidad) OR UPDATE(precio_congelado) OR UPDATE(id_venta)
    BEGIN
        ;WITH VentasAfectadas AS (
            SELECT id_venta FROM inserted
            UNION
            SELECT id_venta FROM deleted
        ),
        TotalesCalculados AS (
            SELECT 
                va.id_venta,
                ISNULL(SUM(dv.cantidad * dv.precio_congelado), 0.00) AS nuevo_total
            FROM VentasAfectadas va
            LEFT JOIN DetalleVenta dv ON va.id_venta = dv.id_venta
            GROUP BY va.id_venta
        )
        UPDATE v
        SET v.total_venta = tc.nuevo_total
        FROM Venta v
        INNER JOIN TotalesCalculados tc ON v.id_venta = tc.id_venta
        WHERE tc.nuevo_total > 0; -- Respeta el CHECK (total_venta > 0)
    END
END;
GO

-- =========================================================================
-- TRIGGER AFTER DELETE en DetalleVenta
-- Descripción: Recalcula total_venta al eliminar productos de una venta.
-- =========================================================================
CREATE OR ALTER TRIGGER tr_DetalleVenta_Delete
ON DetalleVenta
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH VentasAfectadas AS (
        SELECT DISTINCT id_venta FROM deleted
    ),
    TotalesCalculados AS (
        SELECT 
            va.id_venta,
            ISNULL(SUM(dv.cantidad * dv.precio_congelado), 0.00) AS nuevo_total
        FROM VentasAfectadas va
        LEFT JOIN DetalleVenta dv ON va.id_venta = dv.id_venta
        GROUP BY va.id_venta
    )
    UPDATE v
    SET v.total_venta = tc.nuevo_total
    FROM Venta v
    INNER JOIN TotalesCalculados tc ON v.id_venta = tc.id_venta
    WHERE tc.nuevo_total > 0; -- Respeta el CHECK (total_venta > 0)
END;
GO


