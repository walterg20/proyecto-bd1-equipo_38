--Cambio de nombre
EXEC sp_rename 'Detalle_Venta', 'DetalleVenta';

EXEC sp_rename 'medio_pago', 'MedioPago';

--se agrego relacion entre tabla DetalleVenta y producto (tiene muchos productos)

ALTER TABLE DetalleVenta ADD CONSTRAINT fk_producto FOREIGN KEY (id_producto) REFERENCES producto(id_producto);
