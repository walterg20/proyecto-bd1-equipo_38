# 2. Triggers (Disparadores)

---

## 1. Definición y Objetivo

**Triggers (*Disparadores*):** Son bloques especializados de código T-SQL asociados a una tabla que no se invocan de forma manual (`EXEC`/`SELECT`), sino que el motor relacional los ejecuta automáticamente ante eventos de manipulación de datos (`INSERT`, `UPDATE`, `DELETE`). Su objetivo es garantizar reglas de integridad complejas, aplicar políticas de seguridad preventiva y mantener pistas de auditoría transparentes e inalterables desde la propia capa de persistencia.

---

## 2. Ventajas y Aplicaciones

**Trazabilidad Automática:** Registra de forma transparente el historial de modificaciones y bajas sin requerir que la aplicación web o el usuario final envíe parámetros extra ni recuerde invocar procedimientos.

**Garantía de No Repudio:** Captura de manera nativa la identidad del usuario de base de datos (`SUSER_SNAME()`) y la marca de tiempo exacta (`SYSDATETIME()`), impidiendo la manipulación encubierta de datos.

**Protección Preventiva:** Mediante disparadores `INSTEAD OF`, intercepta operaciones no deseadas antes de que impacten en las tablas, emitiendo mensajes de error claros y personalizados en lugar de fallos genéricos del motor.

---

## 3. Implementación en SQL Server

Se implementaron en el esquema principal de la base de datos `sistema_matiensos`:

* La tabla auxiliar `dbo.auditoria_producto` en `sql/tecnico/tablas/auditoria_producto.sql`.
* El trigger de auditoría `dbo.tr_auditoria_producto` en `sql/tecnico/triggers/tr_auditoria_producto.sql`.
* El trigger de control de integridad `dbo.tr_control_delete_categoria` en `sql/tecnico/triggers/tr_control_delete_categoria.sql`.

---

## 4. Caso Concreto Aplicado a Matiensos

1. **Trigger `dbo.tr_auditoria_producto`:**
* **Problema de Negocio:** Supervisar cualquier alteración en el catálogo de productos (precios de venta y niveles de stock) o borrado accidental de mercadería. Cada vez que ocurre un `UPDATE` o `DELETE`, el trigger extrae de la tabla virtual `deleted` el estado previo del artículo y lo archiva en la tabla auxiliar `auditoria_producto`.


2. **Trigger `dbo.tr_control_delete_categoria`:**
* **Problema de Negocio:** Evitar la eliminación accidental de rubros comerciales (ej. "Mates", "Termos") que contengan artículos asignados. Al ser un trigger `INSTEAD OF DELETE`, evalúa si existen productos vinculados antes de ejecutar la acción; de haberlos, cancela la operación emitiendo un mensaje de negocio y evita que salte el error técnico de clave foránea.



---

## 5. Código DDL / DML de Creación

```sql
-- Creo la tabla auxiliar de auditoría para producto
-- Almacena los valores ANTERIORES al cambio/borrado más datos de control
CREATE TABLE auditoria_producto (
    id_auditoria      INT IDENTITY(1,1) NOT NULL,
    id_producto       INT           NOT NULL,
    nombre_ant        VARCHAR(150)  NOT NULL,
    stock_actual_ant  INT           NOT NULL,
    precio_ant        DECIMAL(10,2) NOT NULL,
    esta_activo_ant   CHAR(1)       NOT NULL,
    id_categoria_ant  INT           NOT NULL,
    operacion         VARCHAR(10)   NOT NULL, -- 'UPDATE' o 'DELETE'
    usuario_bd        VARCHAR(128)  NOT NULL, -- Usuario de la base de datos
    fecha_hora        DATETIME2     NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_auditoria_producto PRIMARY KEY (id_auditoria)
);
GO

-- Creo el trigger que se dispara después de actualizar o eliminar un producto
CREATE OR ALTER TRIGGER tr_auditoria_producto
ON producto
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Variable para saber si la acción fue UPDATE o DELETE
    DECLARE @operacion VARCHAR(10);

    -- Si existen filas en inserted, significa que se actualizaron datos (UPDATE).
    -- Si inserted está vacío, significa que se eliminaron (DELETE).
    IF EXISTS (SELECT 1 FROM inserted)
        SET @operacion = 'UPDATE';
    ELSE
        SET @operacion = 'DELETE';

    -- Insertamos los datos viejos (desde la tabla virtual 'deleted') hacia la tabla auxiliar
    INSERT INTO auditoria_producto (
        id_producto,
        nombre_ant,
        stock_actual_ant,
        precio_ant,
        esta_activo_ant,
        id_categoria_ant,
        operacion,
        usuario_bd
    )
    SELECT 
        d.id_producto,
        d.nombre,
        d.stock_actual,
        d.precio,
        d.esta_activo,
        d.id_categoria,
        @operacion,
        SUSER_SNAME() -- Obtiene el usuario conectado a la base de datos
    FROM deleted d;
END;
GO

-- Creo un trigger para emitir un mensaje que impida borrar una categoría si tiene productos asociados
CREATE OR ALTER TRIGGER tr_control_delete_categoria
ON categoria
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar si alguna de las categorías que se intentan borrar tiene productos asociados
    IF EXISTS (
        SELECT 1
        FROM producto p
        INNER JOIN deleted d ON p.id_categoria = d.id_categoria
    )
    BEGIN
        -- Emite mensaje descriptivo y cancela la operación
        RAISERROR('Operación cancelada: No es posible eliminar una categoría que tenga productos asociados.', 16, 1);
        RETURN;
    END;

    -- Si ninguna de las categorías a borrar tenía productos, permitimos el borrado normal
    DELETE FROM categoria
    WHERE id_categoria IN (SELECT id_categoria FROM deleted);
END;
GO

```

---

## 6. Script de Demostración y Resultados Obtenidos

### Demostración 1: Auditoría de Modificación Puntual (`UPDATE`)

```sql
-- Actualiza precio y stock del Mate Imperial (id_producto = 1)
UPDATE producto
SET precio = 49000.00, stock_actual = 20
WHERE id_producto = 1;

-- Comprueba el registro histórico en auditoría
SELECT 
    id_auditoria,
    id_producto,
    nombre_ant,
    stock_actual_ant,
    precio_ant,
    operacion,
    usuario_bd,
    CONVERT(VARCHAR(19), fecha_hora, 120) AS fecha_hora
FROM auditoria_producto
WHERE id_producto = 1;

```

#### Resultados Obtenidos

| id_auditoria | id_producto | nombre_ant | stock_actual_ant | precio_ant | operacion | usuario_bd | fecha_hora |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **1** | 1 | Mate Imperial Calabaza Cuero Cincelado | 25 | $ 45.000,00 | **UPDATE** | sa | 2026-10-28 19:55:39 |

---

### Demostración 2: Auditoría Masiva por Lote (`UPDATE` en Conjunto)

```sql
-- Aumento del 10% a todos los productos de la categoría Termos (id_categoria = 3)
UPDATE producto
SET precio = precio * 1.10
WHERE id_categoria = 3;

-- Comprueba las filas insertadas en lote por el trigger
SELECT 
    id_auditoria,
    id_producto,
    nombre_ant,
    precio_ant,
    operacion,
    usuario_bd,
    CONVERT(VARCHAR(19), fecha_hora, 120) AS fecha_hora
FROM auditoria_producto
WHERE id_producto IN (8, 9, 10, 18, 19, 20)
ORDER BY id_auditoria DESC;

```

#### Resultados Obtenidos

| id_auditoria | id_producto | nombre_ant | precio_ant | operacion | usuario_bd | fecha_hora |
| --- | --- | --- | --- | --- | --- | --- |
| **7** | 8 | Termo Media Manija Acero 1 Litro | $ 65.000,00 | **UPDATE** | sa | 2026-10-28 19:58:54 |
| **6** | 9 | Termo Bala Inoxidable 1 Litro Doble Capa | $ 48.000,00 | **UPDATE** | sa | 2026-10-28 19:58:54 |
| **5** | 10 | Termo Manija Móvil Clásico 1.2 Litros | $ 58.000,00 | **UPDATE** | sa | 2026-10-28 19:58:54 |
| **4** | 18 | Termo Media Manija Acero 1 Litro | $ 65.000,00 | **UPDATE** | sa | 2026-10-28 19:58:54 |
| **3** | 19 | Termo Bala Inoxidable 1 Litro Doble Capa | $ 48.000,00 | **UPDATE** | sa | 2026-10-28 19:58:54 |
| **2** | 20 | Termo Manija Móvil Clásico 1.2 Litros | $ 58.000,00 | **UPDATE** | sa | 2026-10-28 19:58:54 |

---

### Demostración 3: Auditoría ante Borrado Definitivo (`DELETE`)

```sql
-- Elimina el registro duplicado del termo (id_producto = 20)
DELETE FROM producto 
WHERE id_producto = 20;

-- Verifica la traza histórica dejada por la baja física
SELECT 
    id_auditoria,
    id_producto,
    nombre_ant,
    stock_actual_ant,
    precio_ant,
    operacion,
    usuario_bd,
    CONVERT(VARCHAR(19), fecha_hora, 120) AS fecha_hora
FROM auditoria_producto 
WHERE id_producto = 20;

```

#### Resultados Obtenidos

| id_auditoria | id_producto | nombre_ant | stock_actual_ant | precio_ant | operacion | usuario_bd | fecha_hora |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **2** | 20 | Termo Manija Móvil Clásico 1.2 Litros | 20 | $ 58.000,00 | UPDATE | sa | 2026-10-28 19:58:54 |
| **8** | 20 | Termo Manija Móvil Clásico 1.2 Litros | 20 | $ 63.800,00 | **DELETE** | sa | 2026-10-28 20:00:54 |

---

### Demostración 4: Control Preventivo de Borrado en Categoría

```sql
-- Intento de borrado de la categoría Mates (id_categoria = 1) que contiene productos activos
DELETE FROM categoria 
WHERE id_categoria = 1;

```

#### Resultados Obtenidos

```text
Msg 50000, Level 16, State 1, Procedure tr_control_delete_categoria, Line 16
Operación cancelada: No es posible eliminar una categoría que tenga productos asociados.

```

---

## 7. Conclusiones Técnicas en Base a las Pruebas Realizadas

1. **Preservación Transparente del Estado Previo:** El disparador `AFTER UPDATE, DELETE` demostró capturar fielmente el estado anterior de los datos mediante la pseudo-tabla `deleted`. Esto resuelve el registro histórico sin sobrecargar el modelo original de `producto` con columnas innecesarias.
2. **Procesamiento Eficiente por Conjuntos (*Set-Based*):** Durante el `UPDATE` masivo a la categoría de termos, el trigger insertó simultáneamente las 6 filas en `auditoria_producto` dentro de una única transacción, confirmando que la sintaxis `INSERT ... SELECT` aprovecha la arquitectura orientada a conjuntos de SQL Server sin recurrir a cursores.
3. **Intercepción Preventiva Limpia:** La implementación del trigger `INSTEAD OF DELETE` sobre `categoria` evitó que el motor emitiera un error de violación de clave foránea críptico, permitiendo validar las dependencias de negocio en memoria y devolver una respuesta clara y controlada al usuario.