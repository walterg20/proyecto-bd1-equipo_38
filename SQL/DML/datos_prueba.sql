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
VALUES  (1, 1, '2026-08-10', 30),
        (2, 4, '2026-08-12', 40),
        (3, 1, '2026-08-15', 50),
        (4, 4, '2026-08-20', 60),
        (5, 2, '2026-08-22', 70),
        (6, 5, '2026-08-25', 100),
        (7, 9, '2026-09-02', 50),
        (8, 3, '2026-09-05', 35);

/*INSERCION TABLA producto_proveedor
  omitiendo la columna fecha */
INSERT INTO producto_proveedor (id_producto, id_proveedor, cantidad)
VALUES   (9, 7, 45),
         (10, 10, 25);
