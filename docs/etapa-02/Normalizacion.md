# Normalización

## 1FN (Primera Forma Normal)

Para cumplir con la 1FN, se debe garantizar que cada atributo sea atómico y eliminar los grupos repetitivos.

Atomicidad de campos: Se asegura que los atributos (nombre, apellido y teléfono) contengan un único valor, evitando campos compuestos.

## 2FN (Segunda Forma Normal)

Para alcanzar la 2FN, el modelo debe estar en 1FN y se deben eliminar las dependencias funcionales parciales en tablas con claves primarias compuestas.

**Resolución de relaciones Muchos a Muchos:**

Tabla Detalle_Venta: Su clave primaria es compuesta (id_venta, id_producto). Los atributos cantidad y precio_congelado dependen de toda la clave compuesta.

Tabla Producto-Proveedor: Se aplicó la misma regla al crear la tabla intermedia PRODUCTO_PROVEDOR para resolver la relación muchos a muchos, dejando que los datos específicos del proveedor como el cuit y razon_social queden en la tabla PROVEDOR.

## 3FN (Tercera Forma Normal)

Una relación está en 3FN si cumple con la 2FN y se eliminan todas las dependencias transitivas, Es decir que todos los atributos no clave deben depender únicamente de la clave primaria.

Categorías de Productos: El nombre y descripción de la categoría no dependen del id_producto, sino de la categoría en sí. Se extrajeron a la tabla CATEGORIA, dejando solo la clave foránea id_categoria en PRODUCTO.

Rol de Usuario: En lugar de guardar el texto del rol dentro del USUARIO, se creó la tabla ROL CON id_rol, nombre Y descripción y se vinculó mediante id_rol en la tabla USUARIO.

Medios de Pago: El tipo de pago se aisló en la tabla MEDIO_PAGO relacionándola con VENTA mediante una clave foránea, evitando repetir textos como Efectivo o Transferencia en cada registro de venta.

Generalización de Personas: Se aplicó una abstracción avanzada al separar los datos comunes nombre, dni y correo en la tabla PERSONA, evitando la redundancia de datos entre los roles de CLIENTE y USUARIO.
