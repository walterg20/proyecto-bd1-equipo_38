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
	precio_congelado DECIMAL(10.2) NOT NULL,
	cantidad int NOT NULL
)

--Restricciones
--Venta 
ALTER TABLE Venta ADD CONSTRAINT pk_id_venta PRIMARY KEY (id_venta);
ALTER TABLE Venta ADD CONSTRAINT fk_medio_pago FOREIGN  KEY (id_medio_pago) REFERENCES Medio_Pago (id_medio_pago);
ALTER TABLE Venta ADD CONSTRAINT fk_usuario FOREIGN KEY (id_persona_usuario) REFERENCES Usuario(id_persona_usuario);
ALTER TABLE Venta ADD CONSTRAINT pk_cliente FOREIGN KEY(id_persona_cliente) REFERENCES Cliente (id_persona_cliente)

ALTER TABLE Venta ADD CONSTRAINT df_fecha_hora DEFAULT GETDATE() FOR fecha_hora;
ALTER TABLE Venta ADD CONSTRAINT total_venta CHECK(total_venta>0)

--Detalle_Venta
ALTER TABLE Detalle_Venta ADD CONSTRAINT fk_detalle_pedido FOREIGN KEY (id_venta, id_producto);
ALTER TABLE Detalle_Venta ADD CONSTRAINT cantidad CHECK(cantidad>0); 

