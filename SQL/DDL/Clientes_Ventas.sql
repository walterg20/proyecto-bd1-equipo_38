USE sistema_matiensos;
GO

/*siguiendo la estructura refleajada en la documentación: en la tabla clientes 
elimino la columna de categorias y agrego la de direccion*/ 

--Elimino la columna categoria
ALTER TABLE Cliente 
DROP COLUMN categoria;

--Agrego la columna dirección
ALTER TABLE Cliente
ADD direccion VARCHAR(255) NULL;

/* Hago que la columna de id_persona_cliente acepte nulos 
para poder registrar clientes como consumidor final */
ALTER TABLE Venta 
ALTER COLUMN id_persona_cliente INT NULL;