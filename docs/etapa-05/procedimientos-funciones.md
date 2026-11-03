# 1. Procedimientos y Funciones Almacenadas
---

## 1. Definición y Objetivo
- **Procedimientos Almacenados (*Stored Procedures*):** Son programas modulares en código T-SQL guardados directamente en el catálogo de la base de datos que pueden recibir parámetros, modificar el estado de múltiples tablas mediante operaciones DML (`INSERT`, `UPDATE`, `DELETE`), gestionar transacciones y devolver valores de salida. Su objetivo es encapsular y centralizar la lógica operativa de la empresa en el propio motor de datos.
- **Funciones Almacenadas (*Functions - UDF*):** Son rutinas auxiliares que reciben parámetros de entrada y devuelven obligatoriamente un valor único (escalar) o un conjunto de filas (tabla). Su objetivo es resolver cálculos de solo lectura y reglas de derivación de datos sin alterar el estado de la base de datos, pudiendo integrarse naturalmente en sentencias `SELECT`, `WHERE` y `JOIN`.

---

## 2. Ventajas y Aplicaciones
- **Reutilización y Mantenibilidad:** Evita la dispersión de reglas de negocio en múltiples aplicaciones externas. Si cambia la política de descuentos, se actualiza la función en la base de datos sin recompilar código externo.
- **Rendimiento:** SQL Server genera y reutiliza planes de ejecución optimizados y compilados en memoria (*Plan Cache*), reduciendo el consumo de CPU.
- **Seguridad Granular:** Permite otorgar permisos de ejecución (`GRANT EXECUTE`) sobre el procedimiento o función a los cajeros, revocando su acceso directo a las tablas sensibles de ventas o inventario.

---

## 3. Implementación en SQL Server Express
Se implementaron en el esquema principal de la base de datos `sistema_matiensos`:
- La función escalar `dbo.fn_CalcularDescuentoCliente` en `sql/tecnico/funciones/fn_CalcularDescuentoCliente.sql`.
- El procedimiento almacenado `dbo.sp_RegistrarVentaCompleta` en `sql/tecnico/procedimientos/sp_RegistrarVentaCompleta.sql`.

---

## 4. Caso Concreto Aplicado a Matiensos
1. **Función `dbo.fn_CalcularDescuentoCliente`:**
   - **Problema de Negocio:** Estimular la fidelidad premiando a clientes frecuentes con un descuento automático según su gasto acumulado:
     - Más de $500.000 -> 10% de descuento.
     - Más de $200.000 -> 5% de descuento.
     - Menor a $200.000 o Consumidor Final -> 0%.
2. **Procedimiento `dbo.sp_RegistrarVentaCompleta`:**
   - **Problema de Negocio:** Centralizar en un único proceso la venta de mostrador: valida stock, calcula el descuento del cliente llamando a la función, crea el ticket en `Venta`, graba el ítem en `DetalleVenta` congelando el precio histórico y descuenta el stock en `Producto`.

---

## 5. Script de Demostración y Resultados Obtenidos

### Demostración de la Función
```sql
SELECT 
    c.id_persona_cliente AS id_cliente,
    p.nombre + ' ' + p.apellido AS cliente,
    ISNULL(SUM(dv.cantidad * dv.precio_congelado), 0.00) AS total_gastado_historico,
    dbo.fn_CalcularDescuentoCliente(c.id_persona_cliente) AS descuento_aplicable
FROM Cliente c
INNER JOIN Persona p ON c.id_persona_cliente = p.id_persona
LEFT JOIN Venta v ON c.id_persona_cliente = v.id_persona_cliente
LEFT JOIN DetalleVenta dv ON v.id_venta = dv.id_venta
GROUP BY c.id_persona_cliente, p.nombre, p.apellido; 
```

### Resultados Obtenidos
| id_cliente | cliente | total_gastado_historico | descuento_aplicable |
| :---: | :--- | :---: | :---: |
| **4** | Juan Pérez | $ 640.000,00 | **0.10 (10%)** |
| **5** | María López | $ 285.000,00 | **0.05 (5%)** |
| **6** | Carlos Rodríguez | $ 95.000,00 | **0.00 (0%)** |

### Demostración Procedimiento Almacenado
```sql
DECLARE @IdNuevaVenta INT;

-- Ejecuta la venta de 1 Mate Imperial (id_producto = 1) para el cliente 4 atendido por el vendedor 2
EXEC dbo.sp_RegistrarVentaCompleta
    @id_persona_usuario = 2,
    @id_persona_cliente = 4,
    @id_medio_pago = 1,
    @id_producto = 1,
    @cantidad = 1,
    @id_venta_generada = @IdNuevaVenta OUTPUT;

-- Verifica el comprobante emitido
SELECT * FROM Venta WHERE id_venta = @IdNuevaVenta;
```