/*
    Aquí simplemente se explica en palabras lo que hicimos.
    Ej.:
    "En esta etapa creamos los scripts físicos de la base de datos. El script de creación de tablas se encuentra en sql/ddl/crear_bd.sql y la carga de datos iniciales en sql/dml/datos_prueba.sql."
*/

Se implementaron las tablas base, catálogos y relaciones del sistema incorporando, además de las restricciones básicas de PRIMARY KEY, FOREIGN KEY y NOT NULL, restricciones adicionales como UNIQUE, CHECK, IDENTITY y DEFAULT:

Jerarquía Persona, Usuario y Cliente: Se implementó Persona como superclase mediante clave primaria autoincremental (IDENTITY). 
Para garantizar la consistencia en la identificación, se agregaron las restricciones UNIQUE (dni) y una regla de validación de negocio CHECK (dni > 0). 
Las entidades hijas Usuario y Cliente heredan su clave primaria y mantienen integridad referencial contra Persona, sumando en Usuario una restricción UNIQUE (nombre_usuario) para impedir credenciales duplicadas.

Catálogos (Rol, Categoria, medio_pago): Se implementaron para clasificar accesos, artículos y transacciones. Cuentan con restricciones UNIQUE sobre sus nombres o tipos (UQ_Rol_nombre, UQ_Categoria_nombre, UQ_medio_pago_tipo) para evitar redundancia o duplicación de categorías y medios.

Proveedores y Productos: La tabla proveedor utiliza clave autoincremental (IDENTITY) e incorpora UNIQUE (cuit) para asegurar la validez fiscal. En producto, además de asociarse a su categoría y ser autoincremental, se definió un valor por defecto mediante DEFAULT '1' en la columna esta_activo para el alta lógica.

Relación Muchos a Muchos (producto_proveedor): Modela el abastecimiento con clave primaria compuesta (id_producto, id_proveedor) y claves foráneas hacia ambas entidades. Incorpora la restricción DEFAULT GETDATE() en el campo fecha para registrar automáticamente el momento del ingreso de stock sin requerir carga manual.