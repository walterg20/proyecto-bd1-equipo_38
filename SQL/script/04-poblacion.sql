/*  SISTEMA DE VENTAS MATIENSOS - Setup 04: Poblacion de datos y seguridad */
USE sistema_matiensos;
GO

/* ===================== PERSONAS ===================== */
INSERT INTO Persona (nombre, apellido, dni, telefono, correo) VALUES
 ('Lucas','Martinez',38111222,'3794112233','lmartinez@matiensos.com'),
 ('Sofia','Gomez',39333444,'3794223344','sgomez@matiensos.com'),
 ('Mateo','Benitez',40555666,'3794334455','mbenitez@matiensos.com'),
 ('Juan','Perez',30123456,'3794445566','juan.perez@gmail.com'),
 ('Maria','Lopez',32456789,'3794556677','maria.lopez@gmail.com'),
 ('Carlos','Rodriguez',34789123,'3794667788','carlos.rodriguez@hotmail.com'),
 ('Valeria','Acosta',36123987,'3794778899','valeria.acosta@gmail.com'),
 ('Nicolas','Sosa',41654321,'3794889900','nico.sosa@yahoo.com');
GO

/* ===================== ROLES ===================== */
INSERT INTO Rol (id_rol, nombre, descripcion) VALUES
 (1,'Administrador','Control total y reportes del sistema'),
 (2,'Vendedor','Atencion en punto de venta y cobranza');
GO

/* ===================== MEDIOS DE PAGO ===================== */
INSERT INTO MedioPago (id_medio_pago, tipo) VALUES
 (1,'Efectivo'),
 (2,'Transferencia / Debito'),
 (3,'Tarjeta de Credito');
GO

/* ===================== USUARIOS ===================== */
INSERT INTO Usuario (id_persona_usuario, nombre_usuario, contrasenia, id_rol) VALUES
 (1,'lmartinez','1234',1),
 (2,'sgomez','1234',2),
 (3,'mbenitez','1234',2);
GO

/* ===================== CLIENTES ===================== */
INSERT INTO Cliente (id_persona_cliente, categoria, direccion) VALUES
 (4,'Minorista','Av. 3 de Abril 1234'),
 (5,'Minorista','Junin 567'),
 (6,'Minorista','San Martin 890'),
 (7,'Minorista','Pellegrini 432'),
 (8,'Minorista','9 de Julio 101');
GO

/* ===================== PROVEEDORES ===================== */
INSERT INTO Proveedor (cuit, razon_social, telefono) VALUES
 ('30-71123456-8','Maderas & Calabazas del Litoral S.A.','3794112233'),
 ('30-68954123-4','Acero & Alpaca Argentina S.R.L.','1145896321'),
 ('30-75412896-1','Termolares Industriales S.A.','3414859632'),
 ('30-64789521-9','Artesanias Guarani Cuero y Madera','3794556677'),
 ('30-70125489-3','Metales del Plata Inoxidable S.A.','1147852369'),
 ('30-69852147-2','Distribuidora Taragui Mayorista','3794998877'),
 ('30-71458963-5','Industrias Termicas Stanley & Cia','1156987412'),
 ('30-63258741-6','Talleres Metalurgicos Corrientes S.R.L.','3794223344'),
 ('30-72589631-7','Orfebreria Criolla El Palmar','3434125896'),
 ('30-66987452-8','Importadora & Exportadora del Plata S.A.','1141236547');
GO

/* ===================== CATEGORIAS ===================== */
INSERT INTO Categoria (id_categoria, nombre, descripcion) VALUES
 (1,'Mates','Mates de calabaza, madera, acero y cuero'),
 (2,'Bombillas','Bombillas de alpaca, acero inoxidable y resorte'),
 (3,'Termos','Termos de acero inoxidable y termicos');
GO

/* ===================== PRODUCTOS ===================== */
INSERT INTO Producto (nombre, stock_actual, precio, esta_activo, id_categoria) VALUES
 ('Mate Imperial Calabaza Cuero Cincelado',25,45000.00,'1',1),
 ('Mate Torpedo Vaqueta Uruguayo',35,38000.00,'1',1),
 ('Mate Camionero Cuero Negro Base Reforzada',40,35000.00,'1',1),
 ('Mate Algarrobo Clasico Tallado',50,15000.00,'1',1),
 ('Bombilla Pico de Loro Alpaca Cincelada',60,12000.00,'1',2),
 ('Bombilla Chata Acero Inoxidable Desarmable',80,8500.00,'1',2),
 ('Bombilla Cuchara Alpaca con Dije Dorado',45,14500.00,'1',2),
 ('Termo Media Manija Acero 1 Litro',30,65000.00,'1',3),
 ('Termo Bala Inoxidable 1 Litro Doble Capa',40,48000.00,'1',3),
 ('Termo Manija Movil Clasico 1.2 Litros',20,58000.00,'1',3);
GO

/* ===================== PRODUCTO-PROVEEDOR ===================== */
INSERT INTO ProductoProveedor (id_producto, id_proveedor, fecha, cantidad) VALUES
 (2,4,'2026-08-12',40),
 (3,1,'2026-08-15',50),
 (4,4,'2026-08-20',60),
 (5,2,'2026-08-22',70),
 (6,5,'2026-08-25',100),
 (7,9,'2026-09-02',50),
 (8,3,'2026-09-05',35),
 (9,1,'2026-08-10',30);
GO

INSERT INTO ProductoProveedor (id_producto, id_proveedor, cantidad) VALUES
 (9,7,45),
 (10,10,25);
GO

/* ===================== VENTAS INICIALES (ids deterministas) ===================== */
SET IDENTITY_INSERT dbo.Venta ON;
GO

INSERT INTO Venta (id_venta, fecha_hora, total_venta, id_medio_pago, id_persona_usuario, id_persona_cliente) VALUES
 (1,'2026-09-25 10:15:00',169000.00,1,3,4),
 (2,'2026-09-25 15:30:00',38000.00,2,1,5),
 (3,'2026-09-26 11:00:00',113000.00,1,2,6),
 (4,'2026-09-26 18:45:00',15000.00,3,3,7),
 (5,'2026-09-27 09:20:00',211000.00,1,1,8),
 (6,'2026-09-28 14:10:00',8500.00,2,2,4),
 (7,'2026-09-29 16:05:00',104000.00,3,1,5),
 (8,'2026-09-30 12:35:00',60500.00,1,3,6);
GO

SET IDENTITY_INSERT dbo.Venta OFF;
GO

INSERT INTO DetalleVenta (id_venta, id_producto, precio_congelado, cantidad) VALUES
 (1,1,45000.00,1),
 (1,6,8500.00,2),
 (1,8,65000.00,1),
 (2,2,38000.00,1),
 (3,3,35000.00,1),
 (3,7,14500.00,2),
 (3,9,48000.00,1),
 (4,4,15000.00,1),
 (5,1,45000.00,2),
 (5,5,12000.00,1),
 (5,10,58000.00,2),
 (6,6,8500.00,1),
 (7,2,38000.00,1),
 (7,8,65000.00,1),
 (8,3,35000.00,1),
 (8,7,14500.00,1),
 (8,5,12000.00,1);
GO

/* ===================== 50 VENTAS ALEATORIAS ===================== */
SET NOCOUNT ON;
GO

DECLARE @VentaId INT = 1;
DECLARE @id_venta_generada INT;
DECLARE @id_medio_pago INT;
DECLARE @id_persona_usuario INT;
DECLARE @id_persona_cliente INT;
DECLARE @fecha_hora DATETIME;

DECLARE @Productos TABLE (id_producto INT, precio DECIMAL(18,2));
INSERT INTO @Productos (id_producto, precio)
SELECT id_producto, precio FROM Producto WHERE id_producto BETWEEN 2 AND 10;

WHILE @VentaId <= 50
BEGIN
    SET @id_medio_pago = ABS(CHECKSUM(NEWID())) % 3 + 1;
    SET @id_persona_usuario = ABS(CHECKSUM(NEWID())) % 3 + 1;

    IF (ABS(CHECKSUM(NEWID())) % 10) < 7
        SET @id_persona_cliente = ABS(CHECKSUM(NEWID())) % 5 + 4;
    ELSE
        SET @id_persona_cliente = NULL;

    SET @fecha_hora = DATEADD(MINUTE, (ABS(CHECKSUM(NEWID())) % 86400) * -1, GETDATE());

    INSERT INTO Venta (fecha_hora, total_venta, id_medio_pago, id_persona_usuario, id_persona_cliente)
    VALUES (@fecha_hora, 1.00, @id_medio_pago, @id_persona_usuario, @id_persona_cliente);

    SELECT @id_venta_generada = SCOPE_IDENTITY();

    DECLARE @CantProductos INT = ABS(CHECKSUM(NEWID())) % 8 + 3;
    DECLARE @ProdSeleccionados TABLE (id_producto INT, precio DECIMAL(18,2), cantidad INT);

    INSERT INTO @ProdSeleccionados
    SELECT TOP (@CantProductos) id_producto, precio, (ABS(CHECKSUM(NEWID())) % 3 + 1)
    FROM @Productos
    ORDER BY NEWID();

    INSERT INTO DetalleVenta (id_venta, id_producto, precio_congelado, cantidad)
    SELECT @id_venta_generada, id_producto, precio, cantidad
    FROM @ProdSeleccionados;

    DELETE FROM @ProdSeleccionados;

    SET @VentaId = @VentaId + 1;
END;
GO

PRINT '50 ventas aleatorias insertadas.';
GO

/* ===================== SEGURIDAD ===================== */
USE master;
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'usuario_admin')
    CREATE LOGIN usuario_admin WITH PASSWORD = 'PassAdmin2026*', CHECK_POLICY = OFF;
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'usuario_lector')
    CREATE LOGIN usuario_lector WITH PASSWORD = 'Ventas2026#', CHECK_POLICY = OFF;
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'usuario_vendedor')
    CREATE LOGIN usuario_vendedor WITH PASSWORD = 'Ventas2026#', CHECK_POLICY = OFF;
GO

USE sistema_matiensos;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usuario_admin')
    CREATE USER usuario_admin FOR LOGIN usuario_admin;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usuario_lector')
    CREATE USER usuario_lector FOR LOGIN usuario_lector;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usuario_vendedor')
    CREATE USER usuario_vendedor FOR LOGIN usuario_vendedor;
GO

ALTER ROLE db_owner ADD MEMBER usuario_admin;
GO

GRANT SELECT ON SCHEMA :: dbo TO usuario_lector;
DENY SELECT ON dbo.Usuario (contrasenia) TO usuario_lector;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'rol_vendedor' AND type = 'R')
    CREATE ROLE rol_vendedor;
GO

GRANT SELECT ON dbo.Producto TO rol_vendedor;
GRANT SELECT ON dbo.Categoria TO rol_vendedor;
GRANT SELECT ON dbo.MedioPago TO rol_vendedor;
GRANT SELECT ON dbo.Cliente TO rol_vendedor;
GRANT SELECT ON dbo.Persona TO rol_vendedor;
GRANT SELECT ON dbo.Venta TO rol_vendedor;
GRANT SELECT ON dbo.DetalleVenta TO rol_vendedor;

DENY SELECT ON dbo.Usuario TO rol_vendedor;
DENY SELECT ON dbo.Rol TO rol_vendedor;
DENY SELECT ON dbo.Proveedor TO rol_vendedor;
DENY SELECT ON dbo.ProductoProveedor TO rol_vendedor;

GRANT EXECUTE ON OBJECT :: dbo.sp_RegistrarVenta TO rol_vendedor;
GRANT EXECUTE ON OBJECT :: dbo.sp_RegistrarVentaCompleta TO rol_vendedor;
GO

ALTER ROLE rol_vendedor ADD MEMBER usuario_vendedor;
GO

PRINT '04-poblacion.sql: datos y seguridad cargados.';
GO
