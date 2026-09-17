# Diagrama Entidad-Relación: BDI-Grupo38

## 1. Entidades y Atributos

### Persona (Superclase)

* **id_persona** (PK)
* nombre
* apellido
* dni
* telefono
* correo

### Cliente (Subclase de Persona)

* *Hereda los atributos de Persona*
* tipo

### Usuario (Subclase de Persona)

* *Hereda los atributos de Persona*
* nombre_usuario
* contraseña

### Rol

* **id_rol** (PK)
* nombre
* descripcion

### Medio_Pago

* **id_medio_pago** (PK)
* tipo

### Categoria

* **id_categoria** (PK)
* nombre
* descripcion

### Producto

* **id_producto** (PK)
* nombre
* precio
* stock_actual

### Proveedor

* **id_proveedor** (PK)
* cuit
* razon_social
* telefono

### Venta

* **id_venta** (PK)
* fecha_hora
* total_venta

### Detalle_venta (Entidad Débil / Intermedia)

* precio_congelado
* cantidad

---

## 2. Jerarquía de Especialización / Generalización

* **Persona (d)**: Disjunta
  * Subclases: **Cliente** y **Usuario**

---

## 3. Relaciones

* **Usuario — Rol** (`tiene`)
  * Cardinalidad: N a 1 (Un rol puede pertenecer a varios usuarios; un usuario tiene un rol).

* **Cliente — Venta** (`compra`)
  * Cardinalidad: 1 a N (Un cliente realiza múltiples compras/ventas).

* **Usuario — Venta** (`genera`)
  * Cardinalidad: 1 a N (Un usuario genera múltiples ventas).

* **Venta — Medio_Pago** (`tiene`)
  * Cardinalidad: N a 1 (Una venta tiene un medio de pago asignado).

* **Venta — Detalle_venta** (`contiene`)
  * Relación identificadora / débil: Una venta contiene múltiples detalles de venta.

* **Detalle_venta — Producto** (`esta`)
  * Cardinalidad: N a 1 (Cada detalle de venta corresponde a un producto específico).

* **Producto — Categoria** (`tiene`)
  * Cardinalidad: N a 1 (Varios productos pertenecen a una categoría).

* **Proveedor — Producto** (`provee`)
  * Cardinalidad: N a M (Muchos a Muchos).
  * **Atributos de la relación:**
    * Fecha
    * Cantidad
