USE sistema_matiensos;
GO

/* =============================================================================
    TEMA: TRIGGERS (DISPARADORES)
    Script: dbo.tr_control_delete_categoria
    Objetivo: Disparador INSTEAD OF DELETE sobre la tabla Categoria.
              Intercepta el intento de eliminación y cancela la operación 
              emitiendo un mensaje controlado si la categoría tiene productos.
   ============================================================================= */

IF OBJECT_ID('dbo.tr_control_delete_categoria', 'TR') IS NOT NULL
    DROP TRIGGER dbo.tr_control_delete_categoria;
GO

CREATE TRIGGER dbo.tr_control_delete_categoria
ON dbo.categoria
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar si alguna categoría que se intenta eliminar posee productos asociados
    IF EXISTS (
        SELECT 1
        FROM dbo.producto p
        INNER JOIN deleted d ON p.id_categoria = d.id_categoria
    )
    BEGIN
        RAISERROR('Operación cancelada: No es posible eliminar una categoría que tenga productos asociados.', 16, 1);
        RETURN;
    END;

    -- Si no tiene productos vinculados, permite el borrado físico de la categoría
    DELETE FROM dbo.categoria
    WHERE id_categoria IN (SELECT id_categoria FROM deleted);
END;
GO