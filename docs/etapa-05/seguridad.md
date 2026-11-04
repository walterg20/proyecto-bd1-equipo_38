# Etapa V — Tema Técnico: Seguridad (Manejo de Permisos a Nivel de Usuarios y Roles en SQL Server)

**Asignatura:** Base de Datos I — Licenciatura en Sistemas de Información (UNNE)  
**Proyecto:** Sistema de Ventas **Matiensos** (Equipo 38)  
**Base de Datos:** `sistema_matiensos`  

---

## 1. Definición y Objetivo

### ¿Qué es?
La **seguridad en una base de datos** comprende los mecanismos de autenticación (quién puede conectarse al servidor) y autorización (qué objetos puede ver o manipular cada identidad dentro de una base de datos). En **SQL Server**, este esquema se estructura en dos niveles jerárquicos:
1. **Inicios de sesión (*Logins*):** Entidades de seguridad a nivel de la instancia del servidor que autentican al usuario.
2. **Usuarios de base de datos (*Users*) y Roles (*Roles*):** Entidades dentro de `sistema_matiensos` mapeadas a un *Login*, sobre las cuales se otorgan (`GRANT`), deniegan (`DENY`) o revocan (`REVOKE`) permisos específicos (lenguaje **DCL** — *Data Control Language*).

### Objetivo en el proyecto Matiensos
Implementar el **Principio de Mínimo Privilegio** sobre la base de datos `sistema_matiensos`, garantizando que:
* Los administradores posean control estructural y operativo total.
* Los perfiles de auditoría/consulta solo puedan leer información autorizada sin exponer credenciales sensibles (`Usuario.contraseña`).
* Los vendedores de mostrador puedan facturar y descontar stock **exclusivamente a través del procedimiento transaccional `dbo.sp_RegistrarVenta`**, bloqueando cualquier intento de insertar ventas falsas o modificar precios y existencias directamente mediante sentencias `INSERT`, `UPDATE` o `DELETE` sobre las tablas.

---

## 2. Ventajas y Aplicaciones

### ¿Por qué utilizar permisos y roles?
* **Protección de información sensible:** Impide que terceros o empleados sin autorización lean datos críticos como contraseñas en `dbo.Usuario` o condiciones comerciales en `dbo.Proveedor`.
* **Integridad de las reglas de negocio (Encapsulamiento):** Al obligar al vendedor a operar mediante `dbo.sp_RegistrarVenta` y bloquear el acceso directo a las tablas, ningún usuario puede registrar una venta sin descontar stock o forzando precios arbitrarios.
* **Prevención de modificaciones accidentales o maliciosas:** Evita que un usuario de consulta o un cajero ejecute un `DELETE` o `UPDATE` masivo por error sobre `Producto` o `Venta`.
* **Administración escalable mediante roles reutilizables:** En lugar de asignar decenas de permisos tabla por tabla a cada nuevo vendedor que ingresa a **Matiensos**, se asignan los permisos una sola vez al rol `rol_vendedor` y simplemente se agregan o quitan miembros (`ALTER ROLE rol_vendedor ADD MEMBER ...`).

---

## 3. Caso de Aplicación en el Sistema de Ventas `sistema_matiensos`

### Escenario
En el sistema de ventas **Matiensos**, toda operación de cobro en mostrador se procesa mediante el procedimiento almacenado transaccional:
```sql
dbo.sp_RegistrarVenta
```
Este procedimiento valida el carrito cargado en `#DetalleTemp`, verifica que los productos estén activos y con stock suficiente, calcula el total real con el precio vigente de catálogo, inserta la cabecera en `Venta`, registra los renglones en `DetalleVenta` con su `precio_congelado` y descuenta las unidades en `Producto`.

Se demuestra en tres partes:
1. **Permisos asignados directamente a usuarios** (`usuario_admin` y `usuario_lector`).
2. **Permisos asignados mediante roles personalizados** (`rol_vendedor` y `usuario_vendedor`).
3. **Diferencia práctica entre ejecutar una sentencia SQL directa (`INSERT`/`UPDATE`) y utilizar un procedimiento almacenado (`EXEC dbo.sp_RegistrarVenta`)** aprovechando el mecanismo de **Encadenamiento de Propiedad** de SQL Server.

### Matriz de Diseño de Seguridad

| Entidad de Seguridad   | Tipo / Nivel                      | Asignación         | Permisos Efectivos en `sistema_matiensos`                   |
| **`usuario_admin`**    | Usuario (Rol fijo `db_owner`)     | Rol de BD          | Control total (DDL, DML y DCL) sobre toda la base de datos. |
| **`usuario_lector`**   | Usuario (Permiso directo)         | Directa al usuario | `GRANT SELECT` en esquema `dbo`, con `DENY SELECT` explícito sobre la columna `Usuario(contraseña)`. Sin permisos de escritura ni ejecución de SP.  |
| **`rol_vendedor`**     | Rol personalizado de BD           | Rol propio         | `GRANT SELECT` en catálogos y comprobantes (`Producto`, `Categoria`, `MedioPago`, `Cliente`, `Persona`, `Venta`, `DetalleVenta`). `DENY SELECT` en tablas internas (`Usuario`, `Rol`, `Proveedor`, `ProductoProveedor`). `GRANT EXECUTE` sobre `dbo.sp_RegistrarVenta`. **Sin permisos `INSERT`/`UPDATE`/`DELETE` directos.** |
| **`usuario_vendedor`** | Usuario miembro de `rol_vendedor` | Heredado del rol   | Hereda todos los permisos y restricciones de `rol_vendedor`. |


## 4. Implementación en SQL Server Express

> **Script completo en el repositorio:** [`sql/tecnico/seguridad/Seguridad.sql`](../../sql/tecnico/seguridad/Seguridad.sql)

### Parte 1 — Permisos a nivel de usuarios

#### 1.1. Creación de inicios de sesión (Logins) y usuarios (Users)
Se crean los inicios de sesión a nivel del servidor y sus respectivos usuarios dentro de la base de datos `sistema_matiensos`:

```sql
USE master;
GO
-- CREACIÓN DE INICIOS DE SESIÓN (LOGINS A NIVEL SERVIDOR)

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'usuario_admin')
BEGIN
    CREATE LOGIN usuario_admin 
    WITH PASSWORD = 'PassAdmin2026*', CHECK_POLICY = OFF;
END;

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'usuario_lector')
BEGIN
    CREATE LOGIN usuario_lector 
    WITH PASSWORD = 'Ventas2026#', CHECK_POLICY = OFF;
END;

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'usuario_vendedor')
BEGIN
    CREATE LOGIN usuario_vendedor 
    WITH PASSWORD = 'Ventas2026#', CHECK_POLICY = OFF;
END;
GO

USE sistema_matiensos;
GO
-- CREACIÓN DE USUARIOS EN LA BASE DE DATOS (USERS)

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usuario_admin')
    CREATE USER usuario_admin FOR LOGIN usuario_admin;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usuario_lector')
    CREATE USER usuario_lector FOR LOGIN usuario_lector;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usuario_vendedor')
    CREATE USER usuario_vendedor FOR LOGIN usuario_vendedor;
GO
```

> **Nota de idempotencia:** Las guardas `IF NOT EXISTS` sobre los catálogos del motor (`sys.server_principals` y `sys.database_principals`) hacen que el script sea **re-ejecutable**: puede aplicarse reiteradamente sobre una base ya configurada sin fallar por objetos duplicados.

#### 1.2. Asignación de permisos al usuario administrador
Se incorpora `usuario_admin` al rol fijo de base de datos `db_owner` para otorgarle control administrativo total:

```sql
ALTER ROLE db_owner 
ADD MEMBER usuario_admin;
GO
```

#### 1.3. Asignación directa de permisos al usuario con permisos limitados (`usuario_lector`)
Se le asigna directamente el permiso de lectura sobre todo el esquema `dbo`, pero aplicando una denegación explícita a nivel de columna sobre `contraseña` en la tabla `Usuario` para resguardar las credenciales:

```sql
GRANT SELECT ON SCHEMA :: dbo TO usuario_lector;

-- Protección de columna sensible
DENY SELECT ON dbo.Usuario (contraseña) TO usuario_lector;
GO
```

---

### Parte 2 — Permisos a nivel de roles personalizados (`rol_vendedor`)

En un entorno real, una tienda cuenta con varios cajeros/vendedores. Administrar permisos individualmente es propenso a errores; por ello, se crea el rol `rol_vendedor`.

#### 2.1. Creación del rol y el usuario vendedor
El inicio de sesión `usuario_vendedor` ya fue creado junto a los demás en el bloque de la sección 1.1 (todos los *logins* se registran en una única sentencia idempotente a nivel de servidor). Lo que se define aquí es el **rol de base de datos** y su usuario asociado:

```sql
USE sistema_matiensos;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'rol_vendedor' AND type = 'R')
BEGIN
    CREATE ROLE rol_vendedor;
END;
GO
```

#### 2.2. Asignación de permisos al rol `rol_vendedor`
El vendedor necesita consultar el catálogo de producto, medios de pago, clientes y comprobantes emitidos, y necesita **ejecutar** el procedimiento de registro de ventas, pero **no debe tener permisos para modificar tablas directamente**:

```sql
-- 1. Lectura habilitada únicamente sobre tablas operativas de mostrador
GRANT SELECT ON dbo.Producto     TO rol_vendedor;
GRANT SELECT ON dbo.Categoria    TO rol_vendedor;
GRANT SELECT ON dbo.MedioPago    TO rol_vendedor;
GRANT SELECT ON dbo.Cliente      TO rol_vendedor;
GRANT SELECT ON dbo.Persona      TO rol_vendedor;
GRANT SELECT ON dbo.Venta        TO rol_vendedor;
GRANT SELECT ON dbo.DetalleVenta TO rol_vendedor;

-- 2. Denegación de lectura sobre tablas administrativas y de proveedores
DENY SELECT ON dbo.Usuario           TO rol_vendedor;
DENY SELECT ON dbo.Rol               TO rol_vendedor;
DENY SELECT ON dbo.Proveedor         TO rol_vendedor;
DENY SELECT ON dbo.ProductoProveedor TO rol_vendedor;

-- 3. Permiso exclusivo de ejecución sobre el Stored Procedure transaccional
GRANT EXECUTE ON OBJECT :: dbo.sp_RegistrarVenta TO rol_vendedor;
GO
```

#### 2.3. Asociación del usuario vendedor al rol
```sql
ALTER ROLE rol_vendedor 
ADD MEMBER usuario_vendedor;
GO
```

---

### Parte 3 — Diferencia entre Sentencia SQL Directa y Procedimiento Almacenado

#### ¿Cómo funciona el Encadenamiento de Propiedad?
Una duda técnica frecuente es:
> *"Si `usuario_vendedor` NO tiene permiso `INSERT` en `Venta` ni `UPDATE` en `Producto`, ¿por qué cuando ejecuta `EXEC dbo.sp_RegistrarVenta` la venta se inserta y el stock se descuenta sin dar error de permisos?"*

**Explicación:**
1. Tanto el procedimiento `dbo.sp_RegistrarVenta` como las tablas `dbo.Venta`, `dbo.DetalleVenta` y `dbo.Producto` pertenecen al mismo esquema y propietario (`dbo`).
2. Cuando `usuario_vendedor` invoca `EXEC dbo.sp_RegistrarVenta`, SQL Server verifica el permiso `EXECUTE` sobre el procedimiento.
3. Al existir una **cadena de propiedad intacta** (mismo dueño `dbo`), SQL Server **no vuelve a evaluar** los permisos `INSERT` o `UPDATE` del usuario sobre las tablas internas mientras la ejecución ocurra dentro del Stored Procedure.
4. De esta manera, el usuario solo puede modificar los datos respetando todas las validaciones de negocio programadas dentro de `sp_RegistrarVenta` (stock suficiente, productos activos, cálculo automático del total y bloqueo `UPDLOCK, HOLDLOCK`).

---

## 5. Script de Demostración y Resultados Obtenidos

> **Script ejecutable de pruebas:** [`sql/tecnico/seguridad/prueba_seguridad.sql`](../../sql/tecnico/seguridad/prueba_seguridad.sql)
>
> **Evidencia de ejecución (captura de consola):** [`Pruebas de Seguridad.pdf`](./Pruebas/Pruebas%20de%20Seguridad.pdf) — registro de la salida real de SSMS con los bloqueos esperados (`Msg 229`) y la venta registrada mediante el procedimiento almacenado.

Mediante la instrucción `EXECUTE AS USER = '...'` de SQL Server, podemos simular la sesión de cada usuario y verificar el comportamiento del motor ante operaciones autorizadas y no autorizadas:

### Prueba A: Comportamiento de `usuario_lector`
```sql
EXECUTE AS USER = 'usuario_lector';

-- 1. Lectura de catálogo (PERMITIDO)
SELECT TOP 3 id_producto, nombre, precio, stock_actual FROM dbo.Producto;

-- 2. Intento de leer la columna contraseña (BLOQUEADO POR DENY)
BEGIN TRY
    SELECT nombre_usuario, contraseña FROM dbo.Usuario;
END TRY
BEGIN CATCH
    PRINT 'BLOQUEO EXITOSO (Esperado): ' + ERROR_MESSAGE();
END CATCH;

-- 3. Intento de modificar precios (BLOQUEADO)
BEGIN TRY
    UPDATE dbo.Producto SET precio = 1.00 WHERE id_producto = 1;
END TRY
BEGIN CATCH
    PRINT 'BLOQUEO EXITOSO (Esperado): ' + ERROR_MESSAGE();
END CATCH;

-- 4. Intento de ejecutar el procedimiento almacenado de ventas (BLOQUEADO)
BEGIN TRY
    EXEC dbo.sp_RegistrarVenta
        @id_medio_pago = 1,
        @id_persona_usuario = 2,
        @id_persona_cliente = 10,
        @id_venta_generada = @IdVentaLector OUTPUT;
END TRY
BEGIN CATCH
    PRINT 'BLOQUEO EXITOSO (Esperado): ' + ERROR_MESSAGE();
END CATCH;

REVERT;
```

**Resultados obtenidos en consola:**
* La consulta `SELECT` sobre `Producto` devuelve las filas correctamente.
* Al intentar leer `contraseña` en `Usuario`:
  `BLOQUEO EXITOSO (Esperado): The SELECT permission was denied on the column 'contraseña' of the object 'Usuario', database 'sistema_matiensos', schema 'dbo'.`
* Al intentar ejecutar `UPDATE` sobre `Producto`:
  `BLOQUEO EXITOSO (Esperado): The UPDATE permission was denied on the object 'Producto', database 'sistema_matiensos', schema 'dbo'.`
* Al intentar ejecutar `sp_RegistrarVenta` sin permiso `EXECUTE`:
  `BLOQUEO EXITOSO (Esperado): The EXECUTE permission was denied on the object 'sp_RegistrarVenta', database 'sistema_matiensos', schema 'dbo'.`

---

### Prueba B: Comportamiento de `usuario_vendedor` (Sentencia Directa vs. Stored Procedure)

#### Caso B.1 — Intento de manipulación directa de tablas (Rechazado)
```sql
EXECUTE AS USER = 'usuario_vendedor';

-- Intento 1: Leer una tabla administrativa restringida
BEGIN TRY
    SELECT * FROM dbo.Proveedor;
END TRY
BEGIN CATCH
    PRINT 'BLOQUEO EXITOSO (Esperado): ' + ERROR_MESSAGE();
END CATCH;

-- Intento 2: Insertar una venta directa salteando el procedimiento
BEGIN TRY
    INSERT INTO dbo.Venta (id_venta, fecha_hora, total_venta, id_medio_pago, id_persona_usuario, id_persona_cliente)
    VALUES (9999, GETDATE(), 10.00, 1, 2, 10);
END TRY
BEGIN CATCH
    PRINT 'BLOQUEO EXITOSO (Esperado): ' + ERROR_MESSAGE();
END CATCH;

-- Intento 3: Modificar directamente el precio o stock de un producto
BEGIN TRY
    UPDATE dbo.Producto SET stock_actual = 999, precio = 100.00 WHERE id_producto = 2;
END TRY
BEGIN CATCH
    PRINT 'BLOQUEO EXITOSO (Esperado): ' + ERROR_MESSAGE();
END CATCH;

REVERT;
```

**Resultados obtenidos en consola:**
* `BLOQUEO EXITOSO (Esperado): The SELECT permission was denied on the object 'Proveedor', database 'sistema_matiensos', schema 'dbo'.`
* `BLOQUEO EXITOSO (Esperado): The INSERT permission was denied on the object 'Venta', database 'sistema_matiensos', schema 'dbo'.`
* `BLOQUEO EXITOSO (Esperado): The UPDATE permission was denied on the object 'Producto', database 'sistema_matiensos', schema 'dbo'.`

> Estos errores corresponden al `Msg 229` (*permission denied*) del motor de SQL Server, interceptado por el bloque `CATCH` del script para reportar el bloqueo como un resultado esperado y no como una falla de ejecución.

#### Caso B.2 — Registro de venta mediante `dbo.sp_RegistrarVenta` (Exitoso)
```sql
EXECUTE AS USER = 'usuario_vendedor';

-- 0. Se registra el stock antes de la venta (para contrastar el descuento)
SELECT id_producto, nombre, stock_actual AS stock_antes_de_venta, precio
FROM dbo.Producto
WHERE id_producto = 2;

-- 1. El vendedor prepara el carrito en su tabla temporal de sesión
IF OBJECT_ID('tempdb..#DetalleTemp') IS NOT NULL DROP TABLE #DetalleTemp;
CREATE TABLE #DetalleTemp (
    id_producto INT NOT NULL,
    cantidad    INT NOT NULL
);
INSERT INTO #DetalleTemp (id_producto, cantidad) VALUES (2, 1);

-- 2. Ejecuta el procedimiento almacenado autorizado para su rol
DECLARE @IdNuevaVenta INT;
EXEC dbo.sp_RegistrarVenta
    @id_medio_pago      = 1,
    @id_persona_usuario = 2,   -- (Vendedora)
    @id_persona_cliente = 10,  -- (Cliente)
    @id_venta_generada  = @IdNuevaVenta OUTPUT;

PRINT 'ÉXITO: Venta registrada correctamente a través del SP. ID Venta Generado: ' + CAST(@IdNuevaVenta AS VARCHAR(10));

-- 3. Verificación posterior: la cabecera y el stock se actualizaron igual
SELECT id_venta, fecha_hora, total_venta, id_medio_pago, id_persona_usuario, id_persona_cliente
FROM dbo.Venta
WHERE id_venta = @IdNuevaVenta;

SELECT id_producto, nombre, stock_actual AS stock_despues_de_venta, precio
FROM dbo.Producto
WHERE id_producto = 2;

DROP TABLE #DetalleTemp;
REVERT;
```

**Resultados obtenidos en consola:**
```text
ÉXITO: Venta registrada correctamente a través del SP. ID Venta Generado: 59
```

| Tabla afectada internamente por el SP | Operación realizada | Permiso directo del vendedor | Resultado vía `sp_RegistrarVenta` |
| :--- | :--- | :---: | :---: |
| `dbo.Venta` | `INSERT` de cabecera (`total_venta = 38000.00`) | **Denegado** | **Ejecutado con éxito** |
| `dbo.DetalleVenta` | `INSERT` del ítem (`id_producto = 2`, `cantidad = 1`) | **Denegado** | **Ejecutado con éxito** |
| `dbo.Producto` | `UPDATE` descontando 1 unidad de `stock_actual` | **Denegado** | **Ejecutado con éxito** |

> **Nota de trazabilidad del `@id_persona_cliente`:** El procedimiento valida la existencia del cliente (`THROW 50006`) y del usuario (`THROW 50004`) antes de operar, por lo que el valor utilizado debe corresponder a un registro existente en `dbo.Cliente` y `dbo.Usuario` de la base donde se ejecuta la demostración. La población de referencia del proyecto (`sql/dml/poblacion_personas.sql`) carga los clientes con identificadores **4 a 8**, por lo que, al ejecutar la prueba sobre una base recién poblada, el valor debe ajustarse a uno de esos identificadores (por ejemplo `4`) o bien extenderse la población de clientes con el identificador utilizado por el script.

---

## 6. Conclusión Técnica
La combinación de **roles personalizados (`rol_vendedor`)** y **procedimientos almacenados (`dbo.sp_RegistrarVenta`)** permite implementar una capa de seguridad robusta en SQL Server: los usuarios finales nunca interactúan con las tablas críticas de manera directa, sino a través de contratos transaccionales controlados que garantizan simultáneamente la **seguridad de acceso (DCL)** y la **integridad transaccional (ACID)**.
