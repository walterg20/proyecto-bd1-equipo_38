# Scripts de prueba para exposición - Sistema Matiensos

Carpeta para preparar y ensayar la exposición del proyecto. Cada archivo cubre un tema técnico con explicación teórica, caso práctico en Matiensos, demostración SQL y resultado esperado.

## Prerrequisitos

1. Levantar SQL Server (Docker): `docker compose up -d`.
2. Ejecutar el setup consolidado en este orden:
   - `SQL/script/00-crear-bd.sql`
   - `SQL/script/01-triggers.sql`
   - `SQL/script/03-procedimientos.sql`
   - `SQL/script/04-poblacion.sql`
3. Abrir los scripts en SSMS sobre la base `sistema_matiensos`.

## Orden de ejecución de las pruebas

1. `01-procedimientos-funciones.sql` — funciones escalares y procedimientos almacenados.
2. `02-transacciones-acid.sql` — transacciones, COMMIT y ROLLBACK.
3. `03-triggers-auditoria-integridad.sql` — auditoría e integridad preventiva.
4. `04-seguridad-roles.sql` — permisos, roles y encadenamiento de propiedad.
5. `05-optimizacion-indices.sql` — optimización con índices (script pesado).

## Notas importantes

- Los scripts modifican datos de prueba; ejecutar sobre una base recién poblada.
- `05-optimizacion-indices.sql` crea y carga 1.000.000 de registros; puede demorar.
- `04-seguridad-roles.sql` usa `EXECUTE AS USER`; ejecutar conectado como `sa` o un usuario con permisos suficientes.
- Al final de cada script hay una "pregunta probable del profesor" con respuesta corta para ensayo oral.