USE sistema_matiensos;
GO

/* =============================================================================
    TEMA 1: FUNCIONES ALMACENADAS
    Script: dbo.fn_CalcularDescuentoCliente
    Función escalar que calcula el porcentaje de descuento comercial
    aplicable a un cliente en función de su histórico de compras acumuladas.
   ============================================================================= */

IF OBJECT_ID('dbo.fn_CalcularDescuentoCliente', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_CalcularDescuentoCliente;
GO

CREATE FUNCTION dbo.fn_CalcularDescuentoCliente
(
    @id_persona_cliente INT
)
RETURNS DECIMAL(4,2)
AS
BEGIN
    DECLARE @TotalAcumulado DECIMAL(12,2) = 0.00;
    DECLARE @PorcentajeDescuento DECIMAL(4,2) = 0.00;

    -- Si no se envía cliente (Consumidor Final / NULL), no aplica descuento
    IF @id_persona_cliente IS NULL
        RETURN 0.00;

    -- Calculo del total histórico facturado
    SELECT @TotalAcumulado = ISNULL(SUM(dv.cantidad * dv.precio_congelado), 0.00)
    FROM Venta v
    INNER JOIN DetalleVenta dv ON v.id_venta = dv.id_venta
    WHERE v.id_persona_cliente = @id_persona_cliente;
    
    IF @TotalAcumulado > 500000.00 -- Más de $500.000 -> 10% descuento
        SET @PorcentajeDescuento = 0.10;
    ELSE IF @TotalAcumulado > 200000.00 -- Más de $200.000 -> 5% descuento
        SET @PorcentajeDescuento = 0.05;
    ELSE
        SET @PorcentajeDescuento = 0.00; -- Caso contrario -> 0% descuento
    RETURN @PorcentajeDescuento;
END;
GO