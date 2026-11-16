/* ============================================================================
   SISTEMA DE VENTAS MATIENSOS - PRUEBA DE EXPOSICION
   TEMA 4: SEGURIDAD, ROLES Y ENCADENAMIENTO DE PROPIEDAD

   EXPLICACION TEORICA:
   - SQL Server separa autenticacion (Logins a nivel servidor) de autorizacion
     (Users y Roles a nivel base de datos).
   - GRANT otorga permisos, DENY los deniega explicitamente, REVOKE los quita.
   - Los roles agrupan permisos para administrarlos de forma escalable.
   - Encadenamiento de propiedad: si un SP y las tablas que usa tienen el mismo
     owner (dbo), SQL Server solo verifica EXECUTE sobre el SP, sin requerir
     permisos directos INSERT/UPDATE/DELETE sobre las tablas.

   CASO PRACTICO EN MATIENSOS:
   - usuario_lector: solo lectura, con DENY sobre Usuario(contrasenia).
   - rol_vendedor / usuario_vendedor: lectura de catalogos y comprobantes,
     DENY en tablas sensibles, EXECUTE sobre sp_RegistrarVenta.
   - El vendedor no puede modificar Producto ni Venta directamente, pero si
     puede vender a traves del procedimiento almacenado.

   RESULTADO ESPERADO:
   - Lectura permitida y bloqueos esperados en cada prueba.
   - Venta registrada exitosamente mediante el SP, con stock descontado.
   ============================================================================ */
USE sistema_matiensos;
GO
SET NOCOUNT ON;
GO

PRINT '=========================================================================';
PRINT 'TEMA 4: SEGURIDAD, ROLES Y ENCADENAMIENTO DE PROPIEDAD';
PRINT '=========================================================================';




PRINT '';
PRINT '=========================================================================';
PRINT 'PRUEBA 1: PERFIL LECTOR (usuario_lector)';
PRINT '=========================================================================';

EXECUTE AS USER = 'usuario_lector';
PRINT 'Contexto actual: ' + USER_NAME();


PRINT '';
PRINT '--- 1.A SELECT permitido sobre Producto ---';
SELECT TOP 3 id_producto, nombre, precio, stock_actual FROM dbo.Producto;


PRINT '';
PRINT '--- 1.B SELECT sobre columna contrasenia (debe fallar) ---';
BEGIN TRY
    SELECT nombre_usuario, contrasenia FROM dbo.Usuario;
    PRINT 'ERROR: la consulta no debio permitirse.';
END TRY
BEGIN CATCH
    PRINT 'Bloqueo esperado: ' + ERROR_MESSAGE();
END CATCH;


PRINT '';
PRINT '--- 1.C UPDATE directo sobre Producto (debe fallar) ---';
BEGIN TRY
    UPDATE dbo.Producto SET precio = 1.00 WHERE id_producto = 1;
    PRINT 'ERROR: el UPDATE no debio permitirse.';
END TRY
BEGIN CATCH
    PRINT 'Bloqueo esperado: ' + ERROR_MESSAGE();
END CATCH;


PRINT '';
PRINT '--- 1.D EXECUTE sobre sp_RegistrarVenta (debe fallar) ---';
BEGIN TRY
    DECLARE @IdVentaLector INT;
    EXEC dbo.sp_RegistrarVenta
        @id_medio_pago = 1,
        @id_persona_usuario = 2,
        @id_persona_cliente = 4,
        @id_venta_generada = @IdVentaLector OUTPUT;
    PRINT 'ERROR: el EXECUTE no debio permitirse.';
END TRY
BEGIN CATCH
    PRINT 'Bloqueo esperado: ' + ERROR_MESSAGE();
END CATCH;

REVERT;
PRINT '';
PRINT 'Contexto restaurado: ' + USER_NAME();
GO







PRINT '';
PRINT '=========================================================================';
PRINT 'PRUEBA 2: PERFIL VENDEDOR (usuario_vendedor / rol_vendedor)';
PRINT '=========================================================================';

EXECUTE AS USER = 'usuario_vendedor';
PRINT 'Contexto actual: ' + USER_NAME();

PRINT '';
PRINT '--- 2.A SELECT sobre tabla sensible Proveedor (debe fallar) ---';
BEGIN TRY
    SELECT * FROM dbo.Proveedor;
    PRINT 'ERROR: el vendedor no deberia ver proveedores.';
END TRY
BEGIN CATCH
    PRINT 'Bloqueo esperado: ' + ERROR_MESSAGE();
END CATCH;


PRINT '';
PRINT '--- 2.B INSERT directo en Venta (debe fallar) ---';
BEGIN TRY
    INSERT INTO dbo.Venta (fecha_hora, total_venta, id_medio_pago, id_persona_usuario, id_persona_cliente)
    VALUES (GETDATE(), 10.00, 1, 2, 4);
    PRINT 'ERROR: no se debe permitir insertar ventas por fuera del SP.';
END TRY
BEGIN CATCH
    PRINT 'Bloqueo esperado: ' + ERROR_MESSAGE();
END CATCH;


PRINT '';
PRINT '--- 2.C UPDATE directo sobre Producto (debe fallar) ---';
BEGIN TRY
    UPDATE dbo.Producto SET stock_actual = 999, precio = 100.00 WHERE id_producto = 2;
    PRINT 'ERROR: el vendedor no puede modificar la tabla Producto directamente.';
END TRY
BEGIN CATCH
    PRINT 'Bloqueo esperado: ' + ERROR_MESSAGE();
END CATCH;

PRINT '';
PRINT '--- 2.D Venta valida mediante EXEC dbo.sp_RegistrarVenta (encadenamiento) ---';
BEGIN TRY
    SELECT id_producto, nombre, stock_actual AS stock_antes, precio
    FROM dbo.Producto
    WHERE id_producto = 2;

    IF OBJECT_ID('tempdb..#DetalleTemp') IS NOT NULL
        DROP TABLE #DetalleTemp;

    CREATE TABLE #DetalleTemp (
        id_producto INT NOT NULL,
        cantidad    INT NOT NULL
    );

    INSERT INTO #DetalleTemp (id_producto, cantidad) VALUES (2, 1);

    DECLARE @IdNuevaVenta INT;
    EXEC dbo.sp_RegistrarVenta
        @id_medio_pago      = 1,
        @id_persona_usuario = 2,
        @id_persona_cliente = 4,
        @id_venta_generada  = @IdNuevaVenta OUTPUT;

    PRINT 'Exito: venta registrada a traves del SP. ID Venta: ' + CAST(@IdNuevaVenta AS VARCHAR(10));

    SELECT id_venta, fecha_hora, total_venta
    FROM dbo.Venta
    WHERE id_venta = @IdNuevaVenta;

    SELECT id_producto, nombre, stock_actual AS stock_despues
    FROM dbo.Producto
    WHERE id_producto = 2;

    DROP TABLE #DetalleTemp;
END TRY
BEGIN CATCH
    PRINT 'Error inesperado en la venta con SP: ' + ERROR_MESSAGE();
END CATCH;

REVERT;
PRINT '';
PRINT 'Contexto restaurado: ' + USER_NAME();
GO

/* PREGUNTA PROBABLE DEL PROFESOR:
   "¿Por que el vendedor puede insertar en Venta si no tiene permiso INSERT?"
   Respuesta: por encadenamiento de propiedad; el SP y las tablas pertenecen a
   dbo, por lo que SQL Server solo verifica EXECUTE sobre el SP. */
GO