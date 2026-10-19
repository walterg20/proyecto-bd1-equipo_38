USE [sistema_matiensos];
GO
--Sumo uno para probar el disparo de Trigger
UPDATE DetalleVenta
SET cantidad = cantidad + 1;
GO
--Resto uno para probar el disparo de Trigger si vuelve el importe original
UPDATE DetalleVenta
SET cantidad = cantidad - 1;
GO