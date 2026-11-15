/* ============================================================================
   SISTEMA DE VENTAS MATIENSOS - PRUEBA DE EXPOSICION
   TEMA 3: TRIGGERS (DISPARADORES) DE AUDITORIA E INTEGRIDAD PREVENTIVA

   EXPLICACION TEORICA:
   - Un trigger es codigo T-SQL que se ejecuta automaticamente ante INSERT,
     UPDATE o DELETE sobre una tabla.
   - AFTER UPDATE/DELETE permite auditoria: usa la pseudo-tabla deleted para
     guardar la foto anterior del registro.
   - INSTEAD OF DELETE intercepta el borrado antes de ejecutarlo, permitiendo
     validar reglas de negocio y cancelar la operacion con RAISERROR.
   - inserted y deleted son tablas virtuales que contienen las filas afectadas.

   CASO PRACTICO EN MATIENSOS:
   - tr_auditoria_producto: ante UPDATE o DELETE en Producto, registra el estado
     anterior en auditoria_producto con usuario (SUSER_SNAME) y fecha/hora.
   - tr_control_delete_categoria: impide borrar una categoria que tenga
     productos asociados; si no tiene productos, permite el borrado.

   RESULTADO ESPERADO:
   - Se ve una fila nueva en auditoria_producto con el precio anterior.
   - El intento de borrar la categoria 1 (Mates) se bloquea.
   - Una categoria demo sin productos se borra sin error.
   ============================================================================ */
USE sistema_matiensos;
GO
SET NOCOUNT ON;
GO

PRINT '=========================================================================';
PRINT 'TEMA 3: TRIGGERS DE AUDITORIA E INTEGRIDAD PREVENTIVA';
PRINT '=========================================================================';

PRINT '';
PRINT '--- 3.1 Trigger AFTER UPDATE: auditoria de Producto ---';

DECLARE @PrecioOriginal DECIMAL(10,2);
SELECT @PrecioOriginal = precio FROM dbo.Producto WHERE id_producto = 1;
PRINT 'Precio original del producto 1: ' + CAST(@PrecioOriginal AS VARCHAR(20));

-- Cambio controlado de precio: el trigger guarda el valor anterior.
UPDATE dbo.Producto
SET precio = precio + 1000.00
WHERE id_producto = 1;
PRINT 'Se actualizo el precio (+1000). El trigger registro el valor anterior.';

PRINT '';
PRINT 'Ultima fila de auditoria generada:';
SELECT TOP 1
    id_auditoria,
    id_producto,
    nombre_ant,
    stock_actual_ant,
    precio_ant AS precio_anterior,
    operacion,
    usuario_bd,
    fecha_hora
FROM dbo.auditoria_producto
WHERE id_producto = 1
ORDER BY id_auditoria DESC;

-- Restauracion del precio original (genera otra fila de auditoria).
UPDATE dbo.Producto
SET precio = @PrecioOriginal
WHERE id_producto = 1;
PRINT '';
PRINT 'Precio restaurado a su valor original.';
GO

PRINT '';
PRINT '--- 3.2 Trigger INSTEAD OF DELETE: proteccion de Categoria ---';

PRINT 'Intento 1: borrar categoria 1 (tiene productos asociados).';
BEGIN TRY
    DELETE FROM dbo.Categoria WHERE id_categoria = 1;
    PRINT 'ERROR: la operacion no debio permitirse.';
END TRY
BEGIN CATCH
    PRINT 'Bloqueo esperado: ' + ERROR_MESSAGE();
END CATCH;

PRINT '';
PRINT 'Intento 2: borrar una categoria sin productos asociados.';
IF NOT EXISTS (SELECT 1 FROM dbo.Categoria WHERE id_categoria = 99)
    INSERT INTO dbo.Categoria (id_categoria, nombre, descripcion)
    VALUES (99, 'Categoria Demo', 'Solo para prueba de trigger');

DELETE FROM dbo.Categoria WHERE id_categoria = 99;
PRINT 'Borrado permitido: la categoria demo no tenia productos vinculados.';
GO

/* PREGUNTA PROBABLE DEL PROFESOR:
   "¿Que diferencia hay entre AFTER y INSTEAD OF?"
   Respuesta: AFTER se ejecuta despues de la operacion y sirve para auditoria;
   INSTEAD OF reemplaza la operacion, permitiendo validar o cancelarla antes
   de que impacte en la tabla. */
GO