/* ============================================================================
   SISTEMA DE VENTAS MATIENSOS - PRUEBA DE EXPOSICION
   TEMA 5: OPTIMIZACION DE CONSULTAS MEDIANTE INDICES

   EXPLICACION TEORICA:
   - Los indices son estructuras (arboles B+) que permiten localizar filas sin
     recorrer toda la tabla (evitan Table Scan / Clustered Index Scan).
   - Un indice no agrupado (NONCLUSTERED) con INCLUDE agrega columnas en el
     nivel hoja, resolviendo la consulta sin leer la tabla base (Index Seek).
   - Los indices mejoran lecturas, pero consumen espacio y afectan
     ligeramente INSERT/UPDATE/DELETE.

   CASO PRACTICO EN MATIENSOS:
   - Se genera Venta_Masiva con 1.000.000 de registros.
   - Se consulta el primer trimestre de 2023.
   - Se compara: sin indice (escaneo) vs. indice de cobertura (busqueda directa).

   RESULTADO ESPERADO (aproximado):
   - Sin indice: ~5.346 lecturas logicas, ~141 ms CPU.
   - Con indice de cobertura: ~165 lecturas logicas, 0 ms CPU.
   - Mejora aproximada: 96,91% menos lecturas logicas.

   NOTA: script pesado; puede demorar unos segundos en cargar 1.000.000 filas.
   ============================================================================ */
USE sistema_matiensos;
GO
SET NOCOUNT ON;
GO

PRINT '=========================================================================';
PRINT 'TEMA 5: OPTIMIZACION DE CONSULTAS MEDIANTE INDICES';
PRINT '=========================================================================';

-- Recreacion idempotente de la tabla de pruebas.
IF OBJECT_ID('dbo.Venta_Masiva', 'U') IS NOT NULL
    DROP TABLE dbo.Venta_Masiva;
GO

CREATE TABLE dbo.Venta_Masiva (
    id_venta     BIGINT IDENTITY(1,1) NOT NULL,
    fecha_venta  DATE NOT NULL,
    total_venta  DECIMAL(12,2) NOT NULL,
    CONSTRAINT PK_Venta_Masiva PRIMARY KEY CLUSTERED (id_venta)
);
GO

PRINT 'Cargando 1.000.000 de registros simulados...';
WITH Numeros AS (
    SELECT TOP (1000000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.objects a
    CROSS JOIN sys.objects b
    CROSS JOIN sys.objects c
)
INSERT INTO dbo.Venta_Masiva (fecha_venta, total_venta)
SELECT
    DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 1825, '2020-01-01'),
    RAND(CHECKSUM(NEWID())) * 10000
FROM Numeros;
GO

PRINT 'Carga finalizada.';
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

PRINT '';
PRINT '=========================================================================';
PRINT 'PRUEBA 1: CONSULTA SIN INDICE (Clustered Index Scan)';
PRINT '=========================================================================';

SELECT id_venta, fecha_venta, total_venta
FROM dbo.Venta_Masiva
WHERE fecha_venta BETWEEN '2023-01-01' AND '2023-03-31';
GO

-- Se quita la clave primaria agrupada para poder crear un indice agrupado por fecha.
ALTER TABLE dbo.Venta_Masiva DROP CONSTRAINT PK_Venta_Masiva;
GO

PRINT '';
PRINT '=========================================================================';
PRINT 'PRUEBA 2: CONSULTA CON INDICE AGRUPADO POR FECHA (Clustered Index Seek)';
PRINT '=========================================================================';

CREATE CLUSTERED INDEX IX_Venta_Fecha
ON dbo.Venta_Masiva (fecha_venta);
GO

SELECT id_venta, fecha_venta, total_venta
FROM dbo.Venta_Masiva
WHERE fecha_venta BETWEEN '2023-01-01' AND '2023-03-31';
GO

PRINT '';
PRINT '=========================================================================';
PRINT 'PRUEBA 3: CONSULTA CON INDICE DE COBERTURA (Index Seek)';
PRINT '=========================================================================';

DROP INDEX IX_Venta_Fecha ON dbo.Venta_Masiva;
GO

CREATE NONCLUSTERED INDEX IX_Venta_Fecha_Cobertura
ON dbo.Venta_Masiva (fecha_venta)
INCLUDE (total_venta);
GO

SELECT fecha_venta, total_venta
FROM dbo.Venta_Masiva
WHERE fecha_venta BETWEEN '2023-01-01' AND '2023-03-31';
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

PRINT '';
PRINT 'Prueba de optimizacion finalizada. La tabla Venta_Masiva queda disponible para verificacion.';
GO

/* PREGUNTA PROBABLE DEL PROFESOR:
   "¿Por que el indice de cobertura mejora tanto?"
   Respuesta: porque incluye total_venta en el nivel hoja; el motor resuelve la
   consulta solo con el indice (Index Seek) sin acceder a la tabla base. */
GO