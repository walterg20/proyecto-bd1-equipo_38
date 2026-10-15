--Cambio de nombre
EXEC sp_rename 'Detalle_Venta', 'DetalleVenta';

EXEC sp_rename 'medio_pago', 'MedioPago';

EXEC sp_rename 'producto_proveedor', 'ProductoProveedor';

EXEC sp_rename 'producto', 'Producto';

EXEC sp_rename 'proveedor', 'Proveedor';

EXEC sp_rename 'producto_proveedor', 'ProductoProveedor';

--se agrego relacion entre tabla DetalleVenta y producto (tiene muchos productos)

ALTER TABLE DetalleVenta ADD CONSTRAINT fk_producto FOREIGN KEY (id_producto) REFERENCES producto(id_producto);
