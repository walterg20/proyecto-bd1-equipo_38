USE sistema_matiensos;
GO

/* =============================================================================
    TEMA: TRIGGERS (DISPARADORES)
    Script: dbo.tr_auditoria_producto
    Objetivo: Disparador AFTER UPDATE, DELETE sobre la tabla Producto.
              Registra automáticamente los valores previos al cambio o borrado 
              en la tabla auxiliar auditoria_producto para trazabilidad histórica.
   ============================================================================= */

-- 1. Asegurar existencia de la tabla de auditoría auxiliar
IF OBJECT_ID('dbo.auditoria_producto', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.auditoria_producto (
        id_auditoria      INT IDENTITY(1,1) NOT NULL,
        id_producto       INT           NOT NULL,
        nombre_ant        VARCHAR(150)  NOT NULL,
        stock_actual_ant  INT           NOT NULL,
        precio_ant        DECIMAL(10,2) NOT NULL,
        esta_activo_ant   CHAR(1)       NOT NULL,
        id_categoria_ant  INT           NOT NULL,
        operacion         VARCHAR(10)   NOT NULL, -- 'UPDATE' o 'DELETE'
        usuario_bd        VARCHAR(128)  NOT NULL, -- Usuario autenticado en SQL Server
        fecha_hora        DATETIME2     NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT PK_auditoria_producto PRIMARY KEY (id_auditoria)
    );
END;
GO

-- 2. Eliminar el trigger si ya existe para recrearlo de forma limpia
IF OBJECT_ID('dbo.tr_auditoria_producto', 'TR') IS NOT NULL
    DROP TRIGGER dbo.tr_auditoria_producto;
GO

-- 3. Creación del Trigger
CREATE TRIGGER dbo.tr_auditoria_producto
ON dbo.producto
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @operacion VARCHAR(10);

    -- Si existen filas en inserted, es un UPDATE; si no, es un DELETE
    IF EXISTS (SELECT 1 FROM inserted)
        SET @operacion = 'UPDATE';
    ELSE
        SET @operacion = 'DELETE';

    -- Registrar la foto anterior tomando los datos de la tabla virtual 'deleted'
    INSERT INTO dbo.auditoria_producto (
        id_producto,
        nombre_ant,
        stock_actual_ant,
        precio_ant,
        esta_activo_ant,
        id_categoria_ant,
        operacion,
        usuario_bd
    )
    SELECT 
        d.id_producto,
        d.nombre,
        d.stock_actual,
        d.precio,
        d.esta_activo,
        d.id_categoria,
        @operacion,
        SUSER_SNAME()
    FROM deleted d;
END;
GO