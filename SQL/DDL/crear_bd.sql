/*  SISTEMA DE VENTAS MATIENSOS - Implementación física del modelo relacional
    T-SQL (Microsoft SQL Server)    */

CREATE DATABASE sistema_matiensos;

USE sistema_matiensos;

/*  TABLA: Persona
Entidad fuerte, superclase de la especialización cliente/usuario.*/
CREATE TABLE Persona
(
    id_persona  INT IDENTITY(1,1) NOT NULL,
    nombre      VARCHAR(100)       NOT NULL,
    apellido    VARCHAR(100)       NOT NULL,
    dni         INT               NOT NULL,
    telefono    VARCHAR(20)       NULL,
    correo      VARCHAR(100)      NULL,
    CONSTRAINT PK_persona PRIMARY KEY (id_persona),
    CONSTRAINT UQ_persona_dni UNIQUE (dni),
    CONSTRAINT CK_persona_dni CHECK (dni > 0)
);

/*  TABLA: Usuario. 
Subtipo de Persona. */
CREATE TABLE Usuario
(
    id_persona_usuario  INT           NOT NULL,
    nombre_usuario      VARCHAR(50)   NOT NULL,
    contraseña          VARCHAR(255)  NOT NULL,
    id_rol              INT           NOT NULL,
    CONSTRAINT PK_usuario PRIMARY KEY (id_persona_usuario),
    CONSTRAINT FK_usuario_persona FOREIGN KEY (id_persona_usuario)
        REFERENCES Persona (id_persona),
    CONSTRAINT FK_usuario_rol FOREIGN KEY (id_rol)
        REFERENCES Rol (id_rol),
    CONSTRAINT UQ_usuario_nombre_usuario UNIQUE (nombre_usuario)
);

/*TABLA: Cliente
Subtipo de Persona.*/
CREATE TABLE Cliente
(
    id_persona_cliente  INT           NOT NULL,
    categoria           VARCHAR(30)   NOT NULL,
    CONSTRAINT PK_cliente PRIMARY KEY (id_persona_cliente),
    CONSTRAINT FK_cliente_persona FOREIGN KEY (id_persona_cliente)
        REFERENCES Persona (id_persona)
);

