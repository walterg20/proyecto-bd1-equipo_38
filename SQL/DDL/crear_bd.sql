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

/* TABLA: proveedor */
CREATE TABLE proveedor(
id_proveedor INT IDENTITY (1,1) NOT NULL,
cuit VARCHAR(13) NOT NULL,
razon_social VARCHAR(150) NOT NULL,
telefono VARCHAR(12) NULL,
CONSTRAINT PK_PROVEEDOR PRIMARY KEY (id_proveedor),
CONSTRAINT UQ_PROVEEDOR_CUIT UNIQUE (cuit)
);

/* TABLA: producto */
CREATE TABLE producto(
id_producto INT IDENTITY(1,1) NOT NULL,
nombre VARCHAR(150) NOT NULL,
stock_actual INT NOT NULL,
precio DECIMAL(10,2) NOT NULL,
esta_activo CHAR(1) NOT NULL DEFAULT '1',
id_categoria INT NOT NULL,
CONSTRAINT PK_PRODUCTO PRIMARY KEY (id_producto),
CONSTRAINT FK_PRODUCTO_CATEGORIA FOREIGN KEY (id_categoria) REFERENCES categoria(id_categoria)
);

/* TABLA: producto_proveedor */
CREATE TABLE producto_proveedor(
id_producto INT NOT NULL,
id_proveedor INT NOT NULL,
fecha DATE NOT NULL DEFAULT GETDATE(),
cantidad INT NOT NULL,
CONSTRAINT PK_PRODUCTO_PROVEEDOR PRIMARY KEY (id_producto, id_proveedor),
CONSTRAINT FK_PRODPROV_PRODUCTO FOREIGN KEY (id_producto) REFERENCES producto(id_producto),
CONSTRAINT FK_PRODPROV_PROVEEDOR FOREIGN KEY (id_proveedor) REFERENCES proveedor(id_proveedor)
);

--Crear TABLE Venta

CREATE TABLE Venta (
	id_venta int NOT NULL,
	fecha_hora DATETIME NOT NULL,
	total_venta DECIMAL(10,2)  NOT NULL,
	id_medio_pago int NOT NULL,
	id_persona_usuario int NOT NULL,
	id_persona_cliente int NOT NULL
)
--Crear TABLE Detalle_Venta

CREATE TABLE Detalle_Venta(
	id_venta int NOT NULL,
	id_producto int NOT NULL,
	precio_congelado DECIMAL(10,2) NOT NULL,
	cantidad int NOT NULL
)

--Restricciones
--Venta 
ALTER TABLE Venta ADD CONSTRAINT pk_id_venta PRIMARY KEY (id_venta);
ALTER TABLE Venta ADD CONSTRAINT fk_medio_pago FOREIGN  KEY (id_medio_pago) REFERENCES Medio_Pago (id_medio_pago);
ALTER TABLE Venta ADD CONSTRAINT fk_usuario FOREIGN KEY (id_persona_usuario) REFERENCES Usuario(id_persona_usuario);
ALTER TABLE Venta ADD CONSTRAINT fk_cliente FOREIGN KEY(id_persona_cliente) REFERENCES Cliente (id_persona_cliente)

ALTER TABLE Venta ADD CONSTRAINT df_fecha_hora DEFAULT GETDATE() FOR fecha_hora;
ALTER TABLE Venta ADD CONSTRAINT total_venta CHECK(total_venta>0)

--Detalle_Venta
ALTER TABLE Detalle_Venta ADD CONSTRAINT fk_detalle_pedido PRIMARY KEY (id_venta, id_producto);
ALTER TABLE Detalle_Venta ADD CONSTRAINT cantidad CHECK(cantidad>0); 
