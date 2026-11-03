USE master;
GO
--CREACIÓN DE INICIOS DE SESIÓN (LOGINS A NIVEL SERVIDOR)


IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'usuario_admin')
BEGIN
    CREATE LOGIN usuario_admin 
    WITH PASSWORD = 'PassAdmin2026*', CHECK_POLICY = OFF;
END;

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'usuario_lector')
BEGIN
    CREATE LOGIN usuario_lector 
    WITH PASSWORD = 'Ventas2026#', CHECK_POLICY = OFF;
END;

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'usuario_vendedor')
BEGIN
    CREATE LOGIN usuario_vendedor 
    WITH PASSWORD = 'Ventas2026#', CHECK_POLICY = OFF;
END;
GO

USE sistema_matiensos;
GO

-- CREACIÓN DE USUARIOS EN LA BASE DE DATOS (USERS)

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usuario_admin')
    CREATE USER usuario_admin FOR LOGIN usuario_admin;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usuario_lector')
    CREATE USER usuario_lector FOR LOGIN usuario_lector;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usuario_vendedor')
    CREATE USER usuario_vendedor FOR LOGIN usuario_vendedor;
GO


-- ASIGNACIÓN DE PERMISOS A NIVEL DE USUARIO 


-- 1. Usuario Administrador: Control total mediante el rol fijo db_owner
ALTER ROLE db_owner ADD MEMBER usuario_admin;
GO

-- 2. Usuario Lector: Permiso directo de solo lectura sobre el esquema dbo
GRANT SELECT ON SCHEMA :: dbo TO usuario_lector;

-- Protección de datos sensibles: se deniega explícitamente la lectura de la columna contraseña
DENY SELECT ON dbo.Usuario (contraseña) TO usuario_lector;
GO

-- CREACIÓN Y CONFIGURACIÓN DE ROLES PERSONALIZADOS


-- 1. Crear el rol para el perfil de atención en mostrador / ventas
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'rol_vendedor' AND type = 'R')
BEGIN
    CREATE ROLE rol_vendedor;
END;
GO

-- 2. Otorgar permisos de lectura únicamente sobre tablas operativas del mostrador
GRANT SELECT ON dbo.Producto    TO rol_vendedor;
GRANT SELECT ON dbo.Categoria   TO rol_vendedor;
GRANT SELECT ON dbo.MedioPago   TO rol_vendedor;
GRANT SELECT ON dbo.Cliente     TO rol_vendedor;
GRANT SELECT ON dbo.Persona     TO rol_vendedor;
GRANT SELECT ON dbo.Venta       TO rol_vendedor;
GRANT SELECT ON dbo.DetalleVenta TO rol_vendedor;

-- 3. Denegar explícitamente la lectura de tablas administrativas/sensibles
DENY SELECT ON dbo.Usuario           TO rol_vendedor;
DENY SELECT ON dbo.Rol               TO rol_vendedor;
DENY SELECT ON dbo.Proveedor         TO rol_vendedor;
DENY SELECT ON dbo.ProductoProveedor TO rol_vendedor;

-- 4. Otorgar permiso de EJECUCIÓN sobre el Procedimiento Almacenado de Ventas
--    NOTA: NO se otorgan permisos INSERT, UPDATE ni DELETE sobre Venta, DetalleVenta ni Producto.
--    La escritura ocurrirá exclusivamente de forma controlada a través del Stored Procedure.
GRANT EXECUTE ON OBJECT :: dbo.sp_RegistrarVenta TO rol_vendedor;
GO

-- 5. Asignar el usuario vendedor al rol personalizado
ALTER ROLE rol_vendedor ADD MEMBER usuario_vendedor;
GO

