
-- 4. Demo AFTER ante algun cambio de precio

-- Consulta el precio actual del Mate Torpedo (id_producto = 2)
SELECT id_producto, nombre, precio, stock_actual 
FROM Producto 
WHERE id_producto = 2;

-- Modifica el precio (actualización de $44.000 a $43.000)
UPDATE Producto
SET precio = 40000.00
WHERE id_producto = 2;

-- Verifica la tabla de auditoría:
SELECT TOP 1 
    id_auditoria,
    id_producto,
    nombre_ant,
    precio_ant,
    operacion,
    usuario_bd,
    fecha_hora
FROM auditoria_producto
ORDER BY id_auditoria DESC;

-- Muestra el estado del producto actualmente
SELECT id_producto, nombre, precio, stock_actual 
FROM Producto 
WHERE id_producto = 2;


---------------------------------------------------------------------------------------------------------------------------------------


-- DEMO INSTEAD OF ---
PRINT 'INTENTO 1: borrar categoria 1 (tiene productos asociados).';
BEGIN TRY
    DELETE FROM dbo.Categoria WHERE id_categoria = 1;
    PRINT 'ERROR: la operacion no debio permitirse.';
END TRY
BEGIN CATCH
    PRINT 'Bloqueo esperado: ' + ERROR_MESSAGE();
END CATCH;


PRINT '';
PRINT 'INTENTO 2: borrar una categoria sin productos asociados.';
IF NOT EXISTS (SELECT 1 FROM dbo.Categoria WHERE id_categoria = 99)
    INSERT INTO dbo.Categoria (id_categoria, nombre, descripcion)
    VALUES (99, 'Categoria Demo', 'Solo para prueba de trigger');

DELETE FROM dbo.Categoria WHERE id_categoria = 99;
PRINT 'Borrado permitido: la categoria demo no tenia productos vinculados.';
GO