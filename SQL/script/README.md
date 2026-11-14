# SCRIPT SQL consolidado — Matiensos

Ejecutar los scripts en este orden (SQL Server 2019+):

1. `00-crear-bd.sql` — crea la base `sistema_matiensos`, tablas, restricciones e índices.
2. `01-triggers.sql` — disparadores de auditoría, protección de categorías y recálculo de totales.
3. `03-procedimientos.sql` — función de descuento y procedimientos de venta.
4. `04-poblacion.sql` — datos semilla y seguridad (logins/usuarios/roles).

## Notas
- Scripts no idempotentes: `00-crear-bd.sql` elimina y recrea la base de datos.
- Nombres finales (post-`Mejoras`): `DetalleVenta`, `MedioPago`, `Producto`, `Proveedor`, `ProductoProveedor`.
- `Venta.id_venta` es `IDENTITY`; no se asignan IDs manuales.
- `Cliente` incluye `categoria` y `direccion`.
- `sp_RegistrarVenta` (multi-ítem, usa `#DetalleTemp`) es el procedimiento canónico; `sp_RegistrarVentaCompleta` (unitario con descuento) se mantiene por compatibilidad.
- `tr_Venta_AutoIncremento` se omitió: innecesario con `IDENTITY`.
- Verificación: `SQL/DML/test_trigger_total.sql`.
