/*  SISTEMA DE VENTAS MATIENSOS - Setup 00: Base de datos, esquema, restricciones e indices
    SQL Server 2019+ (compatibilidad 150). Ejecutar primero. */

IF DB_ID('sistema_matiensos') IS NOT NULL
BEGIN
    ALTER DATABASE sistema_matiensos SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE sistema_matiensos;
END;
GO

CREATE DATABASE sistema_matiensos;
GO

USE sistema_matiensos;
GO

/* ===================== TABLAS ===================== */

CREATE TABLE Persona (
    id_persona  INT IDENTITY(1,1) NOT NULL,
    nombre      VARCHAR(100)       NOT NULL,
    apellido    VARCHAR(100)       NOT NULL,
    dni         INT               NOT NULL,
    telefono    VARCHAR(20)       NULL,
    correo      VARCHAR(100)      NULL,
    CONSTRAINT PK_Persona PRIMARY KEY (id_persona),
    CONSTRAINT UQ_Persona_dni UNIQUE (dni),
    CONSTRAINT CK_Persona_dni CHECK (dni > 0)
);
GO

CREATE TABLE Categoria (
    id_categoria INT          NOT NULL,
    nombre       VARCHAR(100) NOT NULL,
    descripcion  VARCHAR(100) NOT NULL,
    CONSTRAINT PK_Categoria PRIMARY KEY (id_categoria),
    CONSTRAINT UQ_Categoria_nombre UNIQUE (nombre)
);
GO

CREATE TABLE Rol (
    id_rol       INT          NOT NULL,
    nombre       VARCHAR(50)  NOT NULL,
    descripcion  VARCHAR(255) NULL,
    CONSTRAINT PK_Rol PRIMARY KEY (id_rol),
    CONSTRAINT UQ_Rol_nombre UNIQUE (nombre)
);
GO

CREATE TABLE MedioPago (
    id_medio_pago INT         NOT NULL,
    tipo          VARCHAR(50) NOT NULL,
    CONSTRAINT PK_MedioPago PRIMARY KEY (id_medio_pago),
    CONSTRAINT UQ_MedioPago_tipo UNIQUE (tipo)
);
GO

CREATE TABLE Usuario (
    id_persona_usuario INT         NOT NULL,
    nombre_usuario     VARCHAR(50) NOT NULL,
    contrasenia        VARCHAR(255) NOT NULL,
    id_rol             INT         NOT NULL,
    CONSTRAINT PK_Usuario PRIMARY KEY (id_persona_usuario),
    CONSTRAINT FK_Usuario_Persona FOREIGN KEY (id_persona_usuario) REFERENCES Persona (id_persona),
    CONSTRAINT FK_Usuario_Rol FOREIGN KEY (id_rol) REFERENCES Rol (id_rol),
    CONSTRAINT UQ_Usuario_nombre UNIQUE (nombre_usuario)
);
GO

CREATE TABLE Cliente (
    id_persona_cliente INT         NOT NULL,
    categoria          VARCHAR(30) NOT NULL DEFAULT 'Minorista',
    direccion          VARCHAR(200) NULL,
    CONSTRAINT PK_Cliente PRIMARY KEY (id_persona_cliente),
    CONSTRAINT FK_Cliente_Persona FOREIGN KEY (id_persona_cliente) REFERENCES Persona (id_persona)
);
GO

CREATE TABLE Proveedor (
    id_proveedor  INT IDENTITY(1,1) NOT NULL,
    cuit          VARCHAR(13)       NOT NULL,
    razon_social  VARCHAR(150)      NOT NULL,
    telefono      VARCHAR(12)       NULL,
    CONSTRAINT PK_Proveedor PRIMARY KEY (id_proveedor),
    CONSTRAINT UQ_Proveedor_cuit UNIQUE (cuit),
    CONSTRAINT CK_Proveedor_cuit CHECK (cuit LIKE '[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9]')
);
GO

CREATE TABLE Producto (
    id_producto  INT IDENTITY(1,1) NOT NULL,
    nombre       VARCHAR(150)      NOT NULL,
    stock_actual INT               NOT NULL,
    precio       DECIMAL(10,2)     NOT NULL,
    esta_activo  CHAR(1)           NOT NULL DEFAULT '1',
    id_categoria INT               NOT NULL,
    CONSTRAINT PK_Producto PRIMARY KEY (id_producto),
    CONSTRAINT FK_Producto_Categoria FOREIGN KEY (id_categoria) REFERENCES Categoria (id_categoria),
    CONSTRAINT CK_Producto_precio CHECK (precio > 0),
    CONSTRAINT CK_Producto_stock CHECK (stock_actual >= 0),
    CONSTRAINT CK_Producto_activo CHECK (esta_activo IN ('0','1'))
);
GO

CREATE TABLE ProductoProveedor (
    id_producto  INT  NOT NULL,
    id_proveedor INT  NOT NULL,
    fecha        DATE NOT NULL DEFAULT GETDATE(),
    cantidad     INT  NOT NULL,
    CONSTRAINT PK_ProductoProveedor PRIMARY KEY (id_producto, id_proveedor),
    CONSTRAINT FK_PP_Producto FOREIGN KEY (id_producto) REFERENCES Producto (id_producto),
    CONSTRAINT FK_PP_Proveedor FOREIGN KEY (id_proveedor) REFERENCES Proveedor (id_proveedor),
    CONSTRAINT CK_PP_cantidad CHECK (cantidad > 0)
);
GO

CREATE TABLE Venta (
    id_venta            INT IDENTITY(1,1) NOT NULL,
    fecha_hora          DATETIME          NOT NULL DEFAULT GETDATE(),
    total_venta         DECIMAL(10,2)     NOT NULL,
    id_medio_pago       INT               NOT NULL,
    id_persona_usuario  INT               NOT NULL,
    id_persona_cliente  INT               NULL,
    CONSTRAINT PK_Venta PRIMARY KEY (id_venta),
    CONSTRAINT FK_Venta_MedioPago FOREIGN KEY (id_medio_pago) REFERENCES MedioPago (id_medio_pago),
    CONSTRAINT FK_Venta_Usuario FOREIGN KEY (id_persona_usuario) REFERENCES Usuario (id_persona_usuario),
    CONSTRAINT FK_Venta_Cliente FOREIGN KEY (id_persona_cliente) REFERENCES Cliente (id_persona_cliente),
    CONSTRAINT CK_Venta_total CHECK (total_venta > 0)
);
GO

CREATE TABLE DetalleVenta (
    id_venta          INT            NOT NULL,
    id_producto       INT            NOT NULL,
    precio_congelado  DECIMAL(10,2)  NOT NULL,
    cantidad          INT            NOT NULL,
    CONSTRAINT PK_DetalleVenta PRIMARY KEY (id_venta, id_producto),
    CONSTRAINT FK_DV_Venta FOREIGN KEY (id_venta) REFERENCES Venta (id_venta),
    CONSTRAINT FK_DV_Producto FOREIGN KEY (id_producto) REFERENCES Producto (id_producto),
    CONSTRAINT CK_DV_cantidad CHECK (cantidad > 0),
    CONSTRAINT CK_DV_precio CHECK (precio_congelado > 0)
);
GO

CREATE TABLE auditoria_producto (
    id_auditoria     INT IDENTITY(1,1) NOT NULL,
    id_producto      INT              NOT NULL,
    nombre_ant       VARCHAR(150)     NOT NULL,
    stock_actual_ant INT              NOT NULL,
    precio_ant       DECIMAL(10,2)    NOT NULL,
    esta_activo_ant  CHAR(1)          NOT NULL,
    id_categoria_ant INT              NOT NULL,
    operacion        VARCHAR(10)      NOT NULL,
    usuario_bd       VARCHAR(128)     NOT NULL,
    fecha_hora       DATETIME2        NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_auditoria_producto PRIMARY KEY (id_auditoria)
);
GO

/* ===================== INDICES ===================== */

CREATE INDEX IX_Producto_Categoria      ON Producto (id_categoria);
CREATE INDEX IX_ProductoProveedor_Prod  ON ProductoProveedor (id_producto);
CREATE INDEX IX_ProductoProveedor_Prov  ON ProductoProveedor (id_proveedor);
CREATE INDEX IX_Venta_Fecha             ON Venta (fecha_hora);
CREATE INDEX IX_Venta_Usuario           ON Venta (id_persona_usuario);
CREATE INDEX IX_Venta_Cliente           ON Venta (id_persona_cliente);
CREATE INDEX IX_Venta_MedioPago         ON Venta (id_medio_pago);
CREATE INDEX IX_DetalleVenta_Producto  ON DetalleVenta (id_producto);
CREATE INDEX IX_Auditoria_Producto      ON auditoria_producto (id_producto);
CREATE INDEX IX_Auditoria_Fecha         ON auditoria_producto (fecha_hora);
GO
PRINT '00-crear-bd.sql: esquema creado correctamente.';
GO
