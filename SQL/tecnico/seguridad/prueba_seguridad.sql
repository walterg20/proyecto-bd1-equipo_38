USE sistema_matiensos;
GO

PRINT '=========================================================================';
PRINT 'PRUEBA 1: PERFIL LECTOR (usuario_lector) - Permisos asignados directamente';
PRINT '=========================================================================';

EXECUTE AS USER = 'usuario_lector';
PRINT '-> Contexto actual de ejecución: ' + USER_NAME();

-- 1.A. Consulta permitida sobre catálogo de productos
PRINT '--- [1.A] Intentando consultar el catálogo de Productos (SELECT permitido)...';
SELECT TOP 3 id_producto, nombre, precio, stock_actual 
FROM dbo.Producto;

-- 1.B. Intento de leer columna sensible (contraseña) bloqueada con DENY
PRINT '--- [1.B] Intentando leer contraseñas de la tabla Usuario (DENY a nivel columna)...';
BEGIN TRY
    SELECT nombre_usuario, contraseña FROM dbo.Usuario;
    PRINT 'ERROR DE SEGURIDAD: La consulta no debió permitirse.';
END TRY
BEGIN CATCH
    PRINT 'BLOQUEO EXITOSO (Esperado): ' + ERROR_MESSAGE();
END CATCH;

-- 1.C. Intento de modificar un precio con usuario de solo lectura
PRINT '--- [1.C] Intentando alterar precios directamente (UPDATE no otorgado)...';
BEGIN TRY
    UPDATE dbo.Producto SET precio = 1.00 WHERE id_producto = 1;
    PRINT 'ERROR DE SEGURIDAD: El UPDATE no debió permitirse.';
END TRY
BEGIN CATCH
    PRINT 'BLOQUEO EXITOSO (Esperado): ' + ERROR_MESSAGE();
END CATCH;

-- 1.D. Intento de ejecutar el procedimiento almacenado de ventas
PRINT '--- [1.D] Intentando ejecutar sp_RegistrarVenta (EXECUTE no otorgado)...';
BEGIN TRY
    DECLARE @IdVentaLector INT;
    EXEC dbo.sp_RegistrarVenta 
        @id_medio_pago = 1, 
        @id_persona_usuario = 2, 
        @id_persona_cliente = 10, 
        @id_venta_generada = @IdVentaLector OUTPUT;
END TRY
BEGIN CATCH
    PRINT 'BLOQUEO EXITOSO (Esperado): ' + ERROR_MESSAGE();
END CATCH;

REVERT;
PRINT '-> Contexto restaurado a: ' + USER_NAME();
GO

PRINT '';
PRINT '=========================================================================';
PRINT 'PRUEBA 2: PERFIL VENDEDOR (usuario_vendedor / rol_vendedor)';
PRINT '          Diferencia entre Sentencia Directa vs. Procedimiento Almacenado';
PRINT '=========================================================================';

EXECUTE AS USER = 'usuario_vendedor';
PRINT '-> Contexto actual de ejecución: ' + USER_NAME();

-- 2.A. Intento de lectura de tabla administrativa restringida (Proveedor)
PRINT '--- [2.A] Intentando leer tabla confidencial Proveedor (DENY en rol_vendedor)...';
BEGIN TRY
    SELECT * FROM dbo.Proveedor;
    PRINT 'ERROR DE SEGURIDAD: El vendedor no debería ver proveedores.';
END TRY
BEGIN CATCH
    PRINT 'BLOQUEO EXITOSO (Esperado): ' + ERROR_MESSAGE();
END CATCH;

-- 2.B. Intento de INSERT directo en la tabla Venta (Salteando reglas de negocio)
PRINT '--- [2.B] Intentando INSERT directo en la tabla Venta sin usar el SP...';
BEGIN TRY
    INSERT INTO dbo.Venta (id_venta, fecha_hora, total_venta, id_medio_pago, id_persona_usuario, id_persona_cliente)
    VALUES (9999, GETDATE(), 10.00, 1, 2, 10);
    PRINT 'ERROR DE SEGURIDAD: No se debe permitir insertar ventas por fuera del procedimiento.';
END TRY
BEGIN CATCH
    PRINT 'BLOQUEO EXITOSO (Esperado): ' + ERROR_MESSAGE();
END CATCH;

-- 2.C. Intento de UPDATE directo en Producto (Alteración maliciosa o accidental de stock/precio)
PRINT '--- [2.C] Intentando UPDATE directo sobre stock/precio en tabla Producto...';
BEGIN TRY
    UPDATE dbo.Producto SET stock_actual = 999, precio = 100.00 WHERE id_producto = 2;
    PRINT 'ERROR DE SEGURIDAD: El vendedor no puede modificar la tabla Producto directamente.';
END TRY
BEGIN CATCH
    PRINT 'BLOQUEO EXITOSO (Esperado): ' + ERROR_MESSAGE();
END CATCH;

-- 2.D. Operación VÁLIDA: Registro de venta mediante el Stored Procedure sp_RegistrarVenta
PRINT '--- [2.D] Registrando venta mediante EXEC dbo.sp_RegistrarVenta (Encadenamiento de Propiedad)...';
BEGIN TRY
    -- Consultar stock antes de la venta
    SELECT id_producto, nombre, stock_actual AS stock_antes_de_venta, precio
    FROM dbo.Producto
    WHERE id_producto = 2;

    -- 1. Crear carrito temporal en la sesión del vendedor
    IF OBJECT_ID('tempdb..#DetalleTemp') IS NOT NULL DROP TABLE #DetalleTemp;
    CREATE TABLE #DetalleTemp (
        id_producto INT NOT NULL,
        cantidad    INT NOT NULL
    );

    -- Agregar 1 unidad del producto 2 (Mate Torpedo Vaqueta Uruguayo)
    INSERT INTO #DetalleTemp (id_producto, cantidad) VALUES (2, 1);

    -- 2. Ejecutar el procedimiento autorizado para rol_vendedor
    DECLARE @IdNuevaVenta INT;
    EXEC dbo.sp_RegistrarVenta
        @id_medio_pago      = 1,
        @id_persona_usuario = 2, -- (Vendedora)
        @id_persona_cliente = 10, -- (Cliente)
        @id_venta_generada  = @IdNuevaVenta OUTPUT;

    PRINT 'ÉXITO: Venta registrada correctamente a través del SP. ID Venta Generado: ' + CAST(@IdNuevaVenta AS VARCHAR(10));

    -- 3. Verificar que la venta se insertó y el stock se descontó aunque el vendedor no tenga permisos directos
    SELECT id_venta, fecha_hora, total_venta, id_medio_pago, id_persona_usuario, id_persona_cliente
    FROM dbo.Venta
    WHERE id_venta = @IdNuevaVenta;

    SELECT id_producto, nombre, stock_actual AS stock_despues_de_venta, precio
    FROM dbo.Producto
    WHERE id_producto = 2;

    DROP TABLE #DetalleTemp;
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO EN VENTA CON SP: ' + ERROR_MESSAGE();
END CATCH;

REVERT;
PRINT '-> Contexto restaurado a: ' + USER_NAME();
GO
