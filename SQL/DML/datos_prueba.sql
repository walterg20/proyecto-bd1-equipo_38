/*  SISTEMA DE VENTAS MATIENSOS - Poblado inicial de datos de prueba (DML)
    T-SQL (Microsoft SQL Server)    */

USE sistema_matiensos;
GO

/*INSERCION TABLA proveedor*/
INSERT INTO proveedor (cuit, razon_social, telefono) 
VALUES ('30-71123456-8', 'Maderas & Calabazas del Litoral S.A.', '3794112233'),
	   ('30-68954123-4', 'Acero & Alpaca Argentina S.R.L.',       '1145896321'),
	   ('30-75412896-1', 'Termolares Industriales S.A.',          '3414859632'),
	   ('30-64789521-9', 'Artesanías Guaraní Cuero y Madera',     '3794556677'),
	   ('30-70125489-3', 'Metales del Plata Inoxidable S.A.',     '1147852369'),
	   ('30-69852147-2', 'Distribuidora Taragüí Mayorista',       '3794998877'),
	   ('30-71458963-5', 'Industrias Térmicas Stanley & Cía',     '1156987412'),
	   ('30-63258741-6', 'Talleres Metalúrgicos Corrientes S.R.L','3794223344'),
	   ('30-72589631-7', 'Orfebrería Criolla El Palmar',          '3434125896'),
	   ('30-66987452-8', 'Importadora & Exportadora del Plata S.A','1141236547');

-- INSERCIÓN EN LA TABLA categoria
INSERT INTO Categoria (id_categoria, nombre, descripcion) VALUES
(1, 'Mates', 'Mates de calabaza, madera, acero y cuero'),
(2, 'Bombillas', 'Bombillas de alpaca, acero inoxidable y resorte'),
(3, 'Termos', 'Termos de acero inoxidable y térmicos');

/*INSERCION TABLA producto
   Asume la existencia previa de las siguientes categorias:
   1 = Mates, 2 = Bombillas, 3 = Termos */
INSERT INTO producto (nombre, stock_actual, precio, esta_activo, id_categoria) 
VALUES  ('Mate Imperial Calabaza Cuero Cincelado', 25, 45000.00, '1', 1),
		('Mate Torpedo Vaqueta Uruguayo',          35, 38000.00, '1', 1),
		('Mate Camionero Cuero Negro Base Reforzada', 40, 35000.00, '1', 1),
		('Mate Algarrobo Clásico Tallado',          50, 15000.00, '1', 1),
		('Bombilla Pico de Loro Alpaca Cincelada',  60, 12000.00, '1', 2),
		('Bombilla Chata Acero Inoxidable Desarmable', 80, 8500.00, '1', 2),
		('Bombilla Cuchara Alpaca con Dije Dorado', 45, 14500.00, '1', 2),
		('Termo Media Manija Acero 1 Litro',        30, 65000.00, '1', 3),
		('Termo Bala Inoxidable 1 Litro Doble Capa',40, 48000.00, '1', 3),
		('Termo Manija Móvil Clásico 1.2 Litros',   20, 58000.00, '1', 3);

/*INSERCION TABLA producto_proveedor
   con fecha explícita */
INSERT INTO producto_proveedor (id_producto, id_proveedor, fecha, cantidad)
VALUES  
        (2, 4, '2026-08-12', 40),
        (3, 1, '2026-08-15', 50),
        (4, 4, '2026-08-20', 60),
        (5, 2, '2026-08-22', 70),
        (6, 5, '2026-08-25', 100),
        (7, 9, '2026-09-02', 50),
        (8, 3, '2026-09-05', 35),
		(9, 1, '2026-08-10', 30);

/*INSERCION TABLA producto_proveedor
  omitiendo la columna fecha */
INSERT INTO producto_proveedor (id_producto, id_proveedor, cantidad)
VALUES   (9, 7, 45),
         (10, 10, 25);

-- INSERCIÓN EN TABLA Rol
INSERT INTO Rol (id_rol, nombre, descripcion) VALUES
(1, 'Administrador', 'Control total y reportes del sistema'),
(2, 'Vendedor', 'Atención en punto de venta y cobranza');

-- INSERCIÓN EN TABLA medio_pago (requeridas por la tabla Venta)
INSERT INTO medio_pago (id_medio_pago, tipo) VALUES
(1, 'Efectivo'),
(2, 'Transferencia / Débito'),
(3, 'Tarjeta de Crédito');
		 
-- INSERCIÓN EN LA TABLA Venta

INSERT INTO Venta (id_venta, fecha_hora, total_venta, id_medio_pago, id_persona_usuario, id_persona_cliente) VALUES 
(1, '2026-09-25 10:15:00', 169000.00, 1, 3, 10),
(2, '2026-09-25 15:30:00', 38000.00,  2, 1, 12),
(3, '2026-09-26 11:00:00', 113000.00, 1, 2, 15),
(4, '2026-09-26 18:45:00', 15000.00,  3, 3, 11),
(5, '2026-09-27 09:20:00', 211000.00, 1, 1, 14),
(6, '2026-09-28 14:10:00', 8500.00,   2, 2, 13),
(7, '2026-09-29 16:05:00', 104000.00, 3, 1, 16),
(8, '2026-09-30 12:35:00', 60500.00,  1, 3, 10);

-- INSERCIÓN EN LA TABLA Detalle_Venta
INSERT INTO Detalle_Venta (id_venta, id_producto, precio_congelado, cantidad) VALUES 
-- Detalles Venta 1 
(1, 1, 45000.00, 1), 
(1, 6, 8500.00,  2), 
(1, 8, 65000.00, 1), 

-- Detalles Venta 2 
(2, 2, 38000.00, 1), 

-- Detalles Venta 3 
(3, 3, 35000.00, 1), 
(3, 7, 14500.00, 2), 
(3, 9, 48000.00, 1), 

-- Detalles Venta 4 
(4, 4, 15000.00, 1), 

-- Detalles Venta 5 
(5, 1, 45000.00, 2), 
(5, 5, 12000.00, 1), 
(5, 10, 58000.00, 2),

-- Detalles Venta 6 
(6, 6, 8500.00,  1),

-- Detalles Venta 7 
(7, 2, 38000.00, 1),
(7, 8, 65000.00, 1),

-- Detalles Venta 8 
(8, 3, 35000.00, 1),
(8, 7, 14500.00, 1), 
(8, 5, 12000.00, 1); 