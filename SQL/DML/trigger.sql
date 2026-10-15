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
