# Reglas de negocio

RN01. Cada USUARIO del sistema debe tener asignado obligatoriamente un único rol, mientras que un mismo ROL puede estar asignado a múltiples usuario simultáneamente.

RN02. Todo CLIENTE registrado y USUARIO del sistema es una PERSONA.

RN03. Una VENTA debe tener asociado un cliente registrado. Un CLIENTE puede tener más de una compra a lo largo del tiempo.

RN04. Todo PRODUCTO debe pertenecer obligatoriamente a una única CATEGORÍA. Una CATEGORÍA puede agrupar varios PRODUCTOS, pero puede existir sin tener productos asociados.

RN05. Todo PRODUCTO tiene asociado uno o varios proveedores. Un PROVEEDOR puede tener uno o varios productos.

RN06. Toda VENTA debe ser registrada por un único USUARIO (vendedor) responsable de la operación.

RN07. Toda VENTA debe tener asociado un único MEDIO DE PAGO.
