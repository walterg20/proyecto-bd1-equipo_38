-- 1. Crear la tabla de pruebas masiva adaptada a Matiensos
CREATE TABLE Venta_Masiva (
    id_venta BIGINT IDENTITY(1,1) PRIMARY KEY,
    fecha_venta DATE NOT NULL,
    total_venta DECIMAL (12,2) NOT NULL
);
GO

-- 2. Carga masiva de 1.000.000 de registros simulados (Puede demorar unos segundos)
SET NOCOUNT ON;
WITH Numeros AS (
    SELECT TOP (1000000) ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS n
    FROM sys.objects a CROSS JOIN sys.objects b CROSS JOIN sys.objects c
)
INSERT INTO Venta_Masiva(fecha_venta, total_venta)
SELECT 
    DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 1825, '2020-01-01'),
    RAND(CHECKSUM(NEWID())) * 10000
FROM Numeros;
GO

-- 3. Activar estadísticas del motor para medir tiempos reales en milisegundos
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

/* ==========================================================================================
   PRUEBA 1: Consulta SIN índice (Genera un "Table Scan" lento)
   ========================================================================================== */
SELECT id_venta, fecha_venta, total_venta
FROM Venta_Masiva
WHERE fecha_venta BETWEEN '2023-01-01' AND '2023-03-31';
GO

/* ==========================================================================================
   PRUEBA 2: Consulta CON Índice Agrupado (Genera un "Clustered Index Seek" rápido)
   ========================================================================================== */
CREATE CLUSTERED INDEX IX_Venta_Fecha
ON Venta_Masiva (fecha_venta);
GO

SELECT id_venta, fecha_venta, total_venta
FROM Venta_Masiva
WHERE fecha_venta BETWEEN '2023-01-01' AND '2023-03-31';
GO

/* ==========================================================================================
   PRUEBA 3: Consulta CON Índice de Cobertura (Máxima optimización)
   ========================================================================================== */
-- Eliminamos el índice anterior para probar el nuevo
DROP INDEX IX_Venta_Fecha ON Venta_Masiva;
GO

-- Creamos el índice incluyendo la columna total_venta para que el motor no lea la tabla original
CREATE NONCLUSTERED INDEX IX_Venta_Fecha_Cobertura
ON Venta_Masiva (fecha_venta)
INCLUDE (total_venta);
GO

SELECT fecha_venta, total_venta
FROM Venta_Masiva
WHERE fecha_venta BETWEEN '2023-01-01' AND '2023-03-31';
GO
