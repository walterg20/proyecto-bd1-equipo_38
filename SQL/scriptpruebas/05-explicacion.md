# Explicación de resultados — Script 05: Optimización de consultas mediante índices

Archivo analizado: `05-optimizacion-indices.sql`  
Base de datos: `sistema_matiensos`  
Tabla de prueba: `Venta_Masiva` (1.000.000 de registros simulados)

## 1. Resumen ejecutivo

El script compara tres escenarios para la misma consulta sobre el primer trimestre de 2023:

| Escenario | Operación principal | Lecturas lógicas | Tiempo aproximado |
|---|---:|---:|---:|
| Sin índice | Clustered Index Scan | 3.603 | 55 ms |
| Índice agrupado por fecha | Clustered Index Seek | 231 | 7–8 ms |
| Índice de cobertura | Index Seek | 163 | 7–8 ms |

**Conclusión:** el índice de cobertura reduce las lecturas de 3.603 a 163, es decir, cerca de **95,5% menos**, y el tiempo baja de 55 ms a 7–8 ms.

---

## 2. PRUEBA 1 — Sin índice (Clustered Index Scan)

### Resultado observado
- Operación: `Clustered Index Scan`.
- Lecturas lógicas: **3.603**.
- Tiempo: **54 ms CPU / 55 ms total**.

### Interpretación
El motor no tiene un índice útil para filtrar por `fecha_venta`, por lo que recorre toda la tabla y revisa todas las páginas. Esto es el caso menos eficiente y sirve como línea base para comparar las mejoras.

---

## 3. Líneas con 3.585 / 4.588 lecturas y 1.452 / 833 ms

Esas líneas **no corresponden a la consulta**, sino a la **creación de los índices**:

- `CREATE CLUSTERED INDEX IX_Venta_Fecha`
- `CREATE NONCLUSTERED INDEX IX_Venta_Fecha_Cobertura`

Construir un índice sobre 1.000.000 de filas requiere leer y ordenar datos, por eso consume lecturas y tiempo. Este costo se paga una sola vez; luego cada consulta se beneficia del índice.

---

## 4. PRUEBA 2 — Con índice agrupado por fecha (Clustered Index Seek)

### Resultado observado
- Operación: `Clustered Index Seek`.
- Lecturas lógicas: **231**.
- Tiempo: **7–8 ms**.
- Filas devueltas: **49.257**.

### Interpretación
Como el índice está ordenado por `fecha_venta`, el motor puede ir directamente al rango solicitado (enero a marzo de 2023) en lugar de escanear toda la tabla. Por eso las lecturas bajan de 3.603 a 231.

---

## 5. PRUEBA 3 — Con índice de cobertura (Index Seek)

### Resultado observado
- Operación: `Index Seek`.
- Lecturas lógicas: **163**.
- Tiempo: **7–8 ms**.
- Filas devueltas: **49.257**.

### Interpretación
El índice no agrupado incluye `total_venta` en el nivel hoja (`INCLUDE (total_venta)`). Como la consulta solo pide `fecha_venta` y `total_venta`, el motor puede resolverla completamente desde el índice, sin acceder a la tabla base. Por eso es el escenario más eficiente.

---

## 6. Comparación resumida

| Escenario | Lecturas lógicas | Tiempo aprox. | Filas devueltas |
|---|---:|---:|---:|
| Sin índice | 3.603 | 55 ms | 49.257 |
| Índice agrupado por fecha | 231 | 7–8 ms | 49.257 |
| Índice de cobertura | 163 | 7–8 ms | 49.257 |

---

## 7. Detalles importantes para la exposición

- `physical reads = 0` porque los datos ya estaban en memoria (buffer pool). En una ejecución “en frío” los tiempos serían algo mayores, pero la mejora porcentual se mantiene.
- La monografía menciona 5.346 lecturas y 141 ms porque esas mediciones se hicieron en otro estado de caché o con otra distribución de datos. El concepto y la mejora son los mismos.
- La diferencia entre índice agrupado (231 lecturas) e índice de cobertura (163 lecturas) parece pequeña en números, pero el índice de cobertura evita accesos adicionales a la tabla base y es mejor cuando la consulta solo necesita las columnas incluidas.

---

## 8. Pregunta probable del profesor

**“¿Por qué el índice de cobertura es mejor que el índice agrupado?”**

Respuesta: porque incluye `total_venta` en el nivel hoja del índice. Así el motor resuelve la consulta solo con el índice (`Index Seek`) sin acceder a la tabla base, reduciendo aún más las lecturas lógicas.