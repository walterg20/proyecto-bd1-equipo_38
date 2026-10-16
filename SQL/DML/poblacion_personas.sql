USE sistema_matiensos;
GO

--Carga de datos faltantes:  Persona, Usuario,Cliente 

--Cargo la tabla Personas
INSERT INTO Persona(nombre,apellido,dni,telefono,correo)
     VALUES ('Lucas', 'Martínez', 38111222, '3794112233', 'lmartinez@matiensos.com'),
            ('Sofía', 'Gómez', 39333444, '3794223344', 'sgomez@matiensos.com'),
            ('Mateo', 'Benítez', 40555666, '3794334455', 'mbenitez@matiensos.com'),
            ('Juan', 'Pérez', 30123456, '3794445566', 'juan.perez@gmail.com'),
            ('María', 'López', 32456789, '3794556677', 'maria.lopez@gmail.com'),
            ('Carlos', 'Rodríguez', 34789123, '3794667788', 'carlos.rodriguez@hotmail.com'),
            ('Valeria', 'Acosta', 36123987, '3794778899', 'valeria.acosta@gmail.com'),
            ('Nicolás', 'Sosa', 41654321, '3794889900', 'nico.sosa@yahoo.com');

--Cargo la tabla Usuarios
INSERT INTO Usuario (id_persona_usuario, nombre_usuario, contraseña, id_rol)     
      VALUES(1, 'lmartinez', '1234', 1),
            (2, 'sgomez', '1234', 2),
            (3, 'mbenitez', '1234', 2);


--Cargo la tabla Clientes
INSERT INTO Cliente(id_persona_cliente, direccion)
      VALUES(4, 'Av. 3 de Abril 1234'),
            (5, 'Junín 567'),
            (6, 'San Martín 890'),
            (7, 'Pellegrini 432'),
            (8, '9 de Julio 101');