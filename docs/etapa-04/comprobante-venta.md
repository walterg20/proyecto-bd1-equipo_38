# Caso 1 — Comprobante y Emisión de Tickets de Venta

---

## 1. Introducción y Contexto

En el marco de la **Etapa 04**, se implementan consultas SQL orientadas a la generación estructurada de comprobantes de compra (tickets de venta) para el sistema **Matiensos**. Estas consultas permiten desglosar cada transacción comercial reflejando tanto la cabecera del comprobante como el detalle línea por línea de los artículos adquiridos.

El diseño de las consultas responde a los siguientes criterios técnicos y de negocio:

1. **Modelado y desglose transaccional:** Integra las entidades de cabecera (`Venta`) y detalle (`DetalleVenta`), vinculando cada ítem vendido con su catálogo físico (`Producto`).
2. **Identificación de intervinientes y roles:** Resuelve la doble relación hacia la tabla `Persona` para individualizar tanto al empleado emisor (`Vendedor`) como al destinatario (`Cliente`), contemplando ventas nominadas e innominadas.
3. **Manejo de nulos y subconsultas de resolución dinámica:** Gestiona la ausencia de datos del cliente mediante expresiones condicionales (`CASE`) y localiza comprobantes de interés histórico mediante subconsultas escalares sin valores estáticos en código.

---

## 2. Catálogo de Consultas de Comprobantes

### Consulta 1: Emisión de Comprobante por Identificador de Venta

#### A. Problema de Negocio

Emitir el comprobante físico o digital correspondiente a una transacción específica (`id_venta = 1`). La consulta debe mostrar la fecha de emisión, el medio de cobro utilizado, el empleado que atendió en el punto de venta, los datos del cliente (o rotularlo como 'Consumidor Final' si la venta no fue nominada) y el desglose de cada producto con su cantidad, precio histórico congelado, subtotal por ítem y el total liquidado de la operación.

#### B. Justificación Técnica

* **Tablas vinculadas (5 tablas / 6 relaciones lógicas):** `Venta`, `MedioPago`, `Persona` (instanciada dos veces: vendedor y cliente), `DetalleVenta` y `Producto`.
* **Estrategia de combinación (`INNER JOIN` y `LEFT JOIN`):**
* Se utiliza `INNER JOIN` con `MedioPago`, `DetalleVenta`, `Producto` y el vendedor (`Persona pv`), garantizando la integridad de los datos esenciales de la transacción.
* Se implementa `LEFT JOIN` con el cliente (`Persona p`), evitando la pérdida de registros en aquellas ventas no registradas a nombre de un cliente específico (`id_persona_cliente IS NULL`).


* **Lógica condicional (`CASE`):** Evalúa la presencia de datos del cliente; si el identificador es nulo devuelve el literal `'Consumidor Final'`, caso contrario concatena el nombre y apellido del titular registrado.

```sql
SELECT  v.id_venta AS Ticket,
        v.fecha_hora AS FechaHora,
        CONCAT(pv.nombre, ' ', pv.apellido) AS Nom_Ape_Vendedor,
        mp.tipo AS MedioPago,
        CASE
            WHEN v.id_persona_cliente IS NULL THEN 'Consumidor Final'
            ELSE CONCAT(p.nombre, ' ', p.apellido)
        END AS Nom_Ape_Cliente,
        pr.nombre AS Producto,
        dv.cantidad AS Cantidad,
        dv.precio_congelado AS PrecioUnitario,
        (dv.cantidad * dv.precio_congelado) AS Subtotal,
        v.total_venta AS Total
FROM Venta v 
INNER JOIN MedioPago mp ON v.id_medio_pago = mp.id_medio_pago
LEFT JOIN Persona p ON v.id_persona_cliente = p.id_persona
INNER JOIN Persona pv ON v.id_persona_usuario = pv.id_persona 
INNER JOIN DetalleVenta dv ON dv.id_venta = v.id_venta
INNER JOIN Producto pr ON dv.id_producto = pr.id_producto
WHERE v.id_venta = 1;

```

---

### Consulta 2: Emisión del Último Ticket Emitido a Consumidor Final

#### A. Problema de Negocio

Recuperar y fiscalizar el comprobante de la última operación comercial registrada en el local bajo la modalidad de 'Consumidor Final' (venta mostrador sin registrar cliente). Permite al área de auditoría o caja reimprimir o verificar la última transacción de este segmento sin necesidad de conocer de antemano el número de ticket generado.

#### B. Justificación Técnica

* **Tablas vinculadas (5 tablas):** `Venta`, `MedioPago`, `Persona` (vendedor), `DetalleVenta` y `Producto`.
* **Simplificación del modelo de unión:** Al estar garantizado que el cliente no está identificado, se omite el `LEFT JOIN` hacia la entidad de cliente y se asigna el rótulo estático `'Consumidor Final'`, optimizando el procesamiento de la consulta.
* **Subconsulta escalar en `WHERE`:** Evalúa `WHERE v.id_venta = (SELECT MAX(id_venta) FROM Venta WHERE id_persona_cliente IS NULL)`. Esta técnica calcula de forma dinámica el identificador de venta más reciente que cumpla la condición de cliente nulo, evitando valores fijos en código.

```sql
SELECT 
    v.id_venta AS Ticket,
    v.fecha_hora AS FechaHora,
    mp.tipo AS MedioPago,
    CONCAT(pv.nombre, ' ', pv.apellido) AS Nom_Ape_Vendedor,
    'Consumidor Final' AS Nom_Ape_Cliente,
    pr.nombre AS Producto,
    dv.cantidad AS Cantidad,
    dv.precio_congelado AS PrecioUnitario,
    (dv.cantidad * dv.precio_congelado) AS Subtotal,
    v.total_venta AS TotalFinal
FROM Venta v 
INNER JOIN MedioPago mp ON v.id_medio_pago = mp.id_medio_pago
INNER JOIN Persona pv ON v.id_persona_usuario = pv.id_persona 
INNER JOIN DetalleVenta dv ON dv.id_venta = v.id_venta
INNER JOIN Producto pr ON dv.id_producto = pr.id_producto
WHERE v.id_venta = (
    SELECT MAX(id_venta) 
    FROM Venta 
    WHERE id_persona_cliente IS NULL
);

```

---

## 3. Resumen de Cumplimiento de Criterios

| Consulta | Tablas Vinculadas | Tratamiento de Entidades | Filtro / Técnica Aplicada | Finalidad del Comprobante |
| --- | --- | --- | --- | --- |
| **Consulta 1** | 5 tablas (`Venta`, `MedioPago`, `Persona` ×2, `DetalleVenta`, `Producto`) | `INNER JOIN` + `LEFT JOIN` para contemplar ventas nominadas e innominadas | `WHERE v.id_venta = 1` + lógica condicional `CASE` | Emisión y desglose completo de un ticket puntual por identificador transaccional. |
| **Consulta 2** | 5 tablas (`Venta`, `MedioPago`, `Persona`, `DetalleVenta`, `Producto`) | `INNER JOIN` en todas sus entidades transaccionales y de catálogo | `WHERE` + Subconsulta escalar (`MAX`) con filtro `IS NULL` | Auditoría y reimpresión dinámica del último comprobante emitido a consumidor final. |
