# Caso 3 — Consultas de Negocios Avanzadas
---

## 1. Introducción y Contexto

En el marco de la **Etapa 04**, se implementan consultas SQL avanzadas orientadas a la explotación de datos y soporte para la toma de decisiones empresariales. El sistema **Matiensos** gestiona la venta y distribución de mates artesanales, bombillas, termos y accesorios afines.

Todas las consultas desarrolladas cumplen estrictamente con las siguientes pautas técnicas y académicas:
1. **Participación de entidades centrales:** Utilizan conjuntamente las tablas `Cliente`, `Venta`, `DetalleVenta` y `Producto` (además de `Persona`).
2. **Operaciones de combinación:** Integran **3 o más tablas mediante `INNER JOIN`**, preservando la integridad referencial y las relaciones del modelo relacional.
3. **Filtros condicionales avanzados:** Aplican filtros basados en agregaciones mediante la cláusula **`HAVING`** y/o filtros condicionales avanzados mediante **`Subconsultas`** (escalares y de ordenamiento analítico).
---

## 2. Catálogo de Consultas de Negocio

### Consulta 1: Clientes con Gasto Acumulado Superior al Promedio General

#### A. Problema de Negocio
Identificar a aquellos clientes cuyo gasto total acumulado en compras supere el promedio general de facturación por cliente de todo el sistema, y que además cuenten con al menos 2 ventas registradas. Esta información permite a la gerencia focalizar promociones, recompensas y líneas de atención personalizada.

#### B. Justificación Técnica
- **Tablas vinculadas (5 tablas):** `Cliente`, `Persona`, `Venta`, `DetalleVenta`, `Producto`.
- **Cláusula JOIN:** Vincula la superclase `Persona` con `Cliente`, luego con sus transacciones en `Venta`, sus líneas de artículos en `DetalleVenta` y la información del artículo en `Producto`.
- **Filtro HAVING y Subconsulta:** Emplea `HAVING COUNT(DISTINCT v.id_venta) >= 2` para filtrar clientes recurrentes y compara la suma total invertida (`SUM(dv.cantidad * dv.precio_congelado)`) contra una **subconsulta escalar** que calcula el promedio del gasto acumulado de todos los clientes en la base de datos.

---

### Consulta 2: Clientes con Compras en Productos de precios elevados (Sobre Precio Promedio de Catálogo)

#### A. Problema de Negocio
Analizar el comportamiento de los clientes que compran artículos cuyo precio supera el precio promedio de todos los artículos activos del catálogo de la tienda y que han acumulado más de $50.000 en estas líneas exclusivas. Facilita el lanzamiento de nuevos productos artesanales y de edición limitada.

#### B. Justificación Técnica
- **Tablas vinculadas (5 tablas):** `Cliente`, `Persona`, `Venta`, `DetalleVenta`, `Producto`.
- **Subconsulta en WHERE:** Evalúa `pr.precio > (SELECT AVG(precio) FROM Producto WHERE esta_activo = '1')`, seleccionando dinámicamente aquellos productos situados por encima de la media de precios del catálogo activo.
- **Filtro HAVING:** Aplica `COUNT(DISTINCT v.id_venta) >= 1` y `SUM(dv.cantidad * dv.precio_congelado) > 50000.00`, asegurando que solo aparezcan clientes con un volumen monetario significativo en este segmento de precios elevados.
---

### Consulta 3: Análisis de Penetración del Producto Más Vendido

#### A. Problema de Negocio
Determinar qué clientes compraron el producto más vendido en unidades físicas en la historia de Matiensos, evaluando la magnitud de su demanda y el total económico que cada cliente aportó a dicho producto líder.

#### B. Justificación Técnica
- **Tablas vinculadas (5 tablas):** `Cliente`, `Persona`, `Venta`, `DetalleVenta`, `Producto`.
- **Subconsulta TOP 1 en WHERE:** Mediante `WHERE pr.id_producto = (SELECT TOP 1 dv_top.id_producto FROM DetalleVenta dv_top GROUP BY dv_top.id_producto ORDER BY SUM(dv_top.cantidad) DESC)`, la consulta no requiere valores fijos codificados ("hardcoded"), sino que calcula de forma dinámica cuál es el artículo líder en ventas de todo el historial.
- **Filtro HAVING:** Asegura la correcta agrupación y filtra clientes que hayan comprado al menos 1 unidad (`SUM(dv.cantidad) >= 1`).
---

## 3. Resumen de Cumplimiento de Criterios

| Consulta | Tablas en JOIN (Mín. 3) | Uso de Cliente, Venta, DetalleVenta y Producto | Filtro Condicional Aplicado | Finalidad de Negocio |
| :--- | :--- | :--- | :--- | :--- |
| **Consulta 1** | 5 tablas (`Persona`, `Cliente`, `Venta`, `DetalleVenta`, `Producto`) | Sí | `HAVING` + Subconsulta escalar (`AVG`) | Detección de clientes con gasto acumulado superior a la media general. |
| **Consulta 2** | 5 tablas (`Persona`, `Cliente`, `Venta`, `DetalleVenta`, `Producto`) | Sí | `WHERE` + Subconsulta escalar (`AVG`) + `HAVING` | Identificación de compradores de artículos con precios por encima del promedio del catálogo (> $50.000). |
| **Consulta 3** | 5 tablas (`Persona`, `Cliente`, `Venta`, `DetalleVenta`, `Producto`) | Sí | `WHERE` + Subconsulta analítica (`TOP 1`) + `HAVING` | Análisis de clientes y facturación asociados al producto con mayor volumen histórico de ventas. |
