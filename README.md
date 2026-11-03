# Proyecto BD1 - Equipo 38

Repositorio correspondiente al proyecto de Base de Datos 1.

### Matiensos

**Año:** 2026  

**Profesores:**

* Lic. Villegas O. Dario
* Mgtr. Alfonzo Pedro

**Grupo:** 38  

**Integrantes:**

* Romero Ingrid Luana – 44089664
* Torres Jemina Cesia – 42790791
* Velazco Walter – 31294048
* Ristovich Mauro Ezequiel Alejandro – 41380447

## Documentación

### Etapa 01 — Análisis

* [Descripción del caso](docs/etapa-01/01-Descripcion-Caso.md)
* [Alcance](docs/etapa-01/02-alcance.md)
* [Reglas de negocio](docs/etapa-01/03-reglas-negocio.md)
* [Decisiones](docs/etapa-01/04-decisiones.md)

### Etapa 02 — Diseño

#### DER

* [Modelo conceptual](docs/etapa-02/der/modelo_conceptual.md)

* [Modelo relacional](docs/etapa-02/der/modelo_relacional.png)

* [Normalización](docs/etapa-02/02-Normalizacion.md)

* [Decisiones de diseño](docs/etapa-02/03-decisiones-diseño.md)

* [Modelo relacional](docs/etapa-02/04-modelo-relacional.md)


### Etapa 03 — Implementación

* [Implementación](docs/etapa-03/implementacion.md)

### Etapa 04 — Consultas y Casos de Uso

* [Casos de Uso](docs/etapa-04/casos-uso.md)
* [Comprobante de Venta](docs/etapa-04/comprobante-venta.md)
* [Consultas Avanzadas de Negocio](docs/etapa-04/consulta-avanzada.md)
* [Informe de Ventas](docs/etapa-04/informe-ventas.md)
* [Diagrama UML - Caso de Uso 03](docs/etapa-04/Caso%20de%20uso/Consulta-Caso-Uso-03.drawio)

### Etapa 05 — Temas Técnicos (Transacciones, Procedimientos, Triggers y Seguridad)

* [Seguridad: Usuarios, Roles y Permisos](docs/etapa-05/seguridad.md)

---

## Scripts SQL

### DDL (Definición de Datos, Procedimientos, Triggers y Seguridad)

* [Creación de Base de Datos y Tablas](sql/ddl/crear_bd.sql)
* [Mejoras, Claves Foráneas y Procedimiento `sp_RegistrarVenta`](sql/ddl/Mejoras.sql)
* [Triggers del Sistema](sql/ddl/Trigger.sql)
* [Ajustes en Cliente y Venta](sql/ddl/ajusted_cliente_ventas.sql)
* [Seguridad: Creación de Logins, Usuarios, Roles y Permisos](sql/ddl/Seguridad.sql)

### DML (Población y Pruebas)

* [Datos de Prueba Iniciales](sql/dml/datos_prueba.sql)
* [Población de Personas, Clientes y Usuarios](sql/dml/poblacion_personas.sql)
* [Población Automatizada de Ventas y Detalles](sql/dml/poblacion_ventas.sql)
* [Prueba Transaccional de `sp_RegistrarVenta`](sql/dml/registrar_venta.sql)
* [Prueba de Triggers de DetalleVenta](sql/dml/test_trigger_total.sql)
* [Prueba y Demostración de Seguridad (Usuarios y Roles)](sql/dml/test_seguridad.sql)

### Consultas de Negocio

* [Consulta de Comprobante de Venta](sql/consultas/comprobante-venta.sql)
* [Consultas Avanzadas](sql/consultas/consulta-avanzada.sql.sql)
* [Informe de Ventas](sql/consultas/informe-ventas.sql)
