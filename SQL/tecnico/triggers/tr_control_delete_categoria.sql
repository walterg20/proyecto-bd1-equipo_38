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


---- DEMO -----
PRINT 'Intento 1: borrar categoria 1 (tiene productos asociados).';
BEGIN TRY
    DELETE FROM dbo.Categoria WHERE id_categoria = 1;
    PRINT 'ERROR: la operacion no debio permitirse.';
END TRY
BEGIN CATCH
    PRINT 'Bloqueo esperado: ' + ERROR_MESSAGE();
END CATCH;


PRINT 'Intento 2: borrar una categoria sin productos asociados.';
IF NOT EXISTS (SELECT 1 FROM dbo.Categoria WHERE id_categoria = 99)
    INSERT INTO dbo.Categoria (id_categoria, nombre, descripcion)
    VALUES (99, 'Categoria Demo', 'Solo para prueba de trigger');

DELETE FROM dbo.Categoria WHERE id_categoria = 99;
PRINT 'Borrado permitido: la categoria demo no tenia productos vinculados.';
GO