# 2. Manejo de Transacciones
---

## 1. Definición y Objetivo
Una **transacción** es un conjunto de una o más sentencias SQL que se ejecutan como una única unidad lógica de trabajo indivisible. Su objetivo principal es preservar la integridad de la base de datos asegurando que, si cualquiera de las operaciones que componen el bloque falla, todas las modificaciones previas se deshagan en su totalidad, garantizando las propiedades **ACID**:
- **Atomicidad (*Atomicity*):** Principio de "todo o nada". La transacción se completa al 100% o no deja ningún efecto residual en el sistema.
- **Consistencia (*Consistency*):** Asegura que la base de datos pase de un estado válido a otro estado válido, respetando todas las restricciones de integridad y reglas del modelo.
- **Aislamiento (*Isolation*):** Las operaciones intermedias no son visibles para otras transacciones concurrentes hasta confirmarse.
- **Durabilidad (*Durability*):** Una vez confirmados los cambios con `COMMIT`, estos persisten de manera definitiva ante cualquier fallo del sistema o corte de energía.

---

## 2. Ventajas y Aplicaciones
- **Prevención de inconsistencias contables:** En una venta comercial participan múltiples tablas (`Venta`, `DetalleVenta` y `Producto`). Si se insertara la venta pero el sistema fallara antes de descontar el stock, se generaría un desfasaje grave entre el stock físico y el registrado.
- **Eliminación de registros huérfanos:** Evita comprobantes de venta registrados sin sus renglones de detalle asociados.
- **Control de concurrencia:** Garantiza que dos vendedores no puedan vender simultáneamente la última unidad de un producto sin stock disponible.

---

## 3. Implementación en SQL Server Express
Se implementó un control transaccional explícito mediante:
- `BEGIN TRANSACTION`: Delimita el inicio formal de la unidad lógica de trabajo.
- `SCOPE_IDENTITY()`: Recupera de forma segura el valor autonumérico asignado por la propiedad `IDENTITY` de la tabla `Venta`.
- `COMMIT TRANSACTION`: Confirma permanentemente todos los cambios en el motor.
- `ROLLBACK TRANSACTION`: Revierte todas las operaciones al estado previo ante cualquier anomalía.
- Bloque estructurado `BEGIN TRY ... BEGIN CATCH`: Captura excepciones de motor o errores de negocio lanzados mediante `RAISERROR`.
- Script de demostración ubicado en `sql/tecnico/transacciones/demo_transacciones_stock.sql`.

---

## 4. Caso Concreto Aplicado a Matiensos
- **Escenario de Negocio:** Venta en mostrador con validación y descuento de existencias físicas de artículos materos.
- **Regla crítica de negocio:** Si un cliente solicita adquirir unidades de un producto y el stock actual es menor a dicha cantidad:
  - **No** se genera el registro en `Venta`.
  - **No** se inserta ninguna fila en `DetalleVenta`.
  - **No** se descuenta ni altera el campo `stock_actual` en la tabla `Producto`.

---

## 5. Script de Demostración y Resultados Obtenidos

Se ejecutaron dos escenarios de prueba controlados para verificar el comportamiento del motor:

### A. Demo 1: Caso Exitoso (Venta con Stock Disponible -> COMMIT)
Se solicitó la compra de 2 unidades del producto *Mate Imperial* contando con existencias suficientes:
- **Stock inicial:** 25 unidades.
- **Acción ejecutada:** Inserción de cabecera en `Venta`, captura de ID autoincremental con `SCOPE_IDENTITY()`, inserción en `DetalleVenta` y descuento de existencias en `Producto`.
- **Resultado en consola:**
  ```text
  Stock inicial del producto 1: 25
  >> Transacción confirmada exitosamente con COMMIT. ID Venta: 52
  Stock final del producto: 23 (Disminuyó en 2)

#### B. Demo 2: Caso Fallido (Venta con Stock Insuficiente -> ROLLBACK)
Se simuló un intento de compra por 99.999 unidades del mismo producto:
- **Stock inicial:** 25 unidades.
- **Acción ejecutada:** El motor detectó que `stock_actual < cantidad_solicitada` y disparó un error de negocio (`RAISERROR`).
- **Respuesta del motor:** El bloque `CATCH` capturó el error y ejecutó inmediatamente `ROLLBACK TRANSACTION`.
- **Resultado en consola y comprobación de atomicidad:**
    ```text
    Stock inicial antes del intento: 23
    >> SE CAPTURÓ LA EXCEPCIÓN: Falta de existencias: Stock insuficiente para cubrir la demanda solicitada.
    >> Se ejecutó ROLLBACK TRANSACTION con éxito.
    Stock verificado tras el Rollback: 23 (INTACTO)
    >> COMPROBACIÓN EXITOSA: No quedó ningún registro huérfano en la tabla Venta (Se revirtió el INSERT).