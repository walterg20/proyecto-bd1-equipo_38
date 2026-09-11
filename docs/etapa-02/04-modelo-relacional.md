--- Modelo relacional en 'Notación Textual Estándar'

* persona (id_persona, nombre, apellido, dni, telefono, correo)
	* Clave Primaria (PK): id_persona
	* Clave Única (UQ): dni

* cliente (id_persona_cliente, categoria)
	* Clave Primaria (PK): id_persona_cliente
	* Clave Foránea (FK): id_persona_cliente referencias persona(id_persona)

* rol (id_rol, nombre, descripcion)
	* Clave Primaria (PK): id_rol
	* Clave Única (UQ): nombre

* usuario (id_persona_usuario, nombre_usuario, contraseña, id_rol)
	* Clave Primaria (PK): id_persona_usuario
	* Clave Única (UQ): nombre_usuario
	* Claves Foráneas (FK):
		* id_persona_usuario referencias persona(id_persona)
		* id_rol referencias rol(id_rol)

* categoria (id_categoria, nombre, descripcion)
	* Clave Primaria (PK): id_categoria
	* Clave Única (UQ): nombre

* producto (id_producto, nombre, stock_actual, precio, id_categoria)
	* Clave Primaria (PK): id_producto
	* Clave Foránea (FK): id_categoria referencias categoria(id_categoria)

* proveedor (id_proveedor, cuit, razon_social, telefono)
	* Clave Primaria (PK): id_proveedor
	* Clave Única (UQ): cuit

* producto_proveedor (id_producto, id_proveedor)
	* Clave Primaria (PK compuesta): (id_producto, id_proveedor)
	* Claves Foráneas (FK):
		* id_producto referencias producto(id_producto)
		* id_proveedor referencias proveedor(id_proveedor)

* medio_pago (id_medio_pago, tipo)
	* Clave Primaria (PK): id_medio_pago
	* Clave Única (UQ): tipo

* venta (id_venta, fecha_hora, total_venta, id_medio_pago, id_persona_usuario, id_persona_cliente)
	* Clave Primaria (PK): id_venta
	* Claves Foráneas (FK):
		* id_medio_pago referencias medio_pago(id_medio_pago)
		* id_persona_usuario referencias usuario(id_persona_usuario)
		* id_persona_cliente referencias cliente(id_persona_cliente)

* detalle_venta (id_venta, id_producto, precio_congelado, cantidad)
	* Clave Primaria (PK compuesta): (id_venta, id_producto)
	* Claves Foráneas (FK):
		* id_venta referencias venta(id_venta)
		* id_producto referencias producto(id_producto)