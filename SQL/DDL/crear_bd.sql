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

/* TABLA: Categoria
*/
CREATE TABLE Categoria
(
id_categoria INT NOT NULL,
nombre VARCHAR(100) NOT NULL,
descripcion VARCHAR (100) NOT NULL,
CONSTRAINT Pk_Categoria PRIMARY KEY (id_categoria),
CONSTRAINT UQ_Categoria_nombre UNIQUE (nombre),
);

/* TABLA: Rol
*/
CREATE TABLE Rol
(
id_rol INT NOT NULL,
nombre VARCHAR(50) NOT NULL,
descripcion VARCHAR(255) NULL,
CONSTRAINT PK_Rol PRIMARY KEY (id_rol),
CONSTRAINT UQ_Rol_nombre UNIQUE (nombre),
);

/* TABLA: medio_pago
*/
CREATE TABLE medio_pago (
    id_medio_pago INT NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    CONSTRAINT PK_medio_pago PRIMARY KEY (id_medio_pago),
    CONSTRAINT UQ_medio_pago_tipo UNIQUE (tipo),
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

