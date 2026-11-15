CARÁTULA

**UNIVERSIDAD NACIONAL DEL NORDESTE**

# **FACULTAD DE CIENCIAS EXACTAS Y NATURALES Y AGRIMENSURA**

## **CARRERA: Licenciatura en Sistemas de Información**

## **ASIGNATURA: Base de Datos I**

## **N° DEL GRUPO: Equipo 38**


**TEMA:**  
*Implementación y Análisis Técnico de Base de Datos en SQL Server Express para el Sistema de Ventas Matienzos*


**A) INTRODUCCIÓN**

El desarrollo de sistemas de información modernos requiere una arquitectura de base de datos relacional robusta, capaz de garantizar la integridad de los datos, la alta disponibilidad, el rendimiento optimizado y la seguridad de la información corporativa. En este marco, la presente monografía aborda el análisis y la implementación técnica realizada sobre el motor de base de datos Microsoft SQL Server Express para el proyecto del Sistema de Ventas "Matiensos", correspondiente al Equipo 38 en la asignatura Base de Datos I de la Licenciatura en Sistemas de Información de la Universidad Nacional del Nordeste (UNNE).


El objetivo central de esta investigación técnica es consolidar y evaluar las soluciones desarrolladas en la base de datos sistema\_matiensos, abarcando cinco pilares fundamentales de la gestión avanzada de bases de datos: procedimientos almacenados y funciones escalares, control transaccional explícito, disparadores de auditoría e integridad preventiva, esquemas de seguridad granular con encadenamiento de propiedad, y optimización de consultas mediante índices de cobertura.


La justificación práctica de este trabajo radica en la trascendencia de trasladar la lógica operativa crítica directamente al motor de la base de datos. Este enfoque evita la dispersión de reglas de negocio en capas externas de la aplicación, reduce el tráfico de red, minimiza el consumo de recursos en la CPU mediante el reúso de planes de ejecución y previene inconsistencias de datos en entornos de concurrencia activa.

**B) DESARROLLO PROPIAMENTE DICHO**

**1. Procedimientos Almacenados y Funciones Escalares**

# **1.1 Definición y Objetivos Técnicos**

Los procedimientos almacenados (*Stored Procedures*) son programas modulares escritos en lenguaje T-SQL guardados en el catálogo de la base de datos que reciben parámetros de entrada y salida, ejecutan operaciones DML (INSERT, UPDATE, DELETE) y gestionan transacciones complejas. Por su parte, las funciones definidas por el usuario (User Defined Functions - UDF) son rutinas auxiliares de solo lectura diseñadas para calcular y retornar un valor único escalar o una tabla, integrándose dinámicamente en cláusulas SELECT, WHERE y JOIN.

# **1.2 Ventajas de Implementación**

- **Mantenibilidad Centralizada:** Al modificar la regla de descuento en la función almacenada, el cambio se aplica instantáneamente a todos los clientes del sistema sin recompilar aplicaciones externas.

- **Reutilización de Planes de Ejecución:** SQL Server reutiliza el plan optimizado en memoria (*Plan Cache*), reduciendo drásticamente el uso del procesador.

- **Seguridad Granular:** Permite otorgar el permiso GRANT EXECUTE sobre la rutina a usuarios del sistema, revocando el acceso directo a tablas sensibles.

# **1.3 Caso Concreto: Fidelización de Clientes y Venta de Mostrador**

En el proyecto Matiensos, se implementaron dos objetos interconectados:


1. Función Escalar dbo.fn\_CalcularDescuentoCliente: Evalúa el historial acumulado de compras de un cliente en Venta y DetalleVenta:

   - Gasto histórico superior a $500.000,00 → 10% de descuento (0,10).

   - Gasto histórico superior a $200.000,00 → 5% de descuento (0,05).

   - Gasto menor a $200.000,00 o Consumidor Final → 0% de descuento (0,00).

2. Procedimiento Almacenado dbo.sp\_RegistrarVentaCompleta: Centraliza la venta de mostrador. Valida existencias en Producto, invoca la función de descuento, genera la cabecera en Venta, graba el ítem congelando el precio histórico en DetalleVenta y descuenta las unidades del stock.


Tabla 1: Matriz de descuento según facturación acumulada del cliente


| ID Cliente | Nombre del Cliente | Total Gastado Histórico | Descuento Aplicable |
| - | - | - | - |
| 4 | Juan Pérez | $ 640.000,00 | 10% (0,10) |
| 5 | María López | $ 285.000,00 | 5% (0,05) |
| 6 | Carlos Rodríguez | $ 95.000,00 | 0% (0,00) |

# **1.4 Algoritmo de Implementación**

CREATE FUNCTION dbo.fn\_CalcularDescuentoCliente (@id\_persona\_cliente INT)

RETURNS DECIMAL(4,2)

AS

BEGIN

    DECLARE @TotalAcumulado DECIMAL(12,2) = 0.00;

    DECLARE @PorcentajeDescuento DECIMAL(4,2) = 0.00;


    IF @id\_persona\_cliente IS NULL RETURN 0.00;


    SELECT @TotalAcumulado = ISNULL(SUM(dv.cantidad \* dv.precio\_congelado), 0.00)

    FROM Venta v

    INNER JOIN DetalleVenta dv ON v.id\_venta = dv.id\_venta

    WHERE v.id\_persona\_cliente = @id\_persona\_cliente;


    IF @TotalAcumulado \> 500000.00 SET @PorcentajeDescuento = 0.10;

    ELSE IF @TotalAcumulado \> 200000.00 SET @PorcentajeDescuento = 0.05;

    ELSE SET @PorcentajeDescuento = 0.00;


    RETURN @PorcentajeDescuento;

END;



Algoritmo 1: Función escalar para cálculo de descuento acumulado

**2. Manejo de Transacciones y Propiedades ACID**

# **2.1 Principios ACID y Control Transaccional**

Una transacción es una unidad lógica de trabajo indivisible. La implementación asegura las cuatro propiedades fundamentales:


- Atomicidad (Atomicity): Garantiza que todas las sentencias de la venta se confirmen o todas se reviertan ("todo o nada").

- Consistencia (Consistency): Asegura que la base de datos pase de un estado válido a otro respetando las restricciones de integridad.

- Aislamiento (Isolation): Evita que modificaciones intermedias sean visibles para otras transacciones antes de su confirmación.

- Durabilidad (Durability): Una vez ejecutado el COMMIT, los cambios persistirán de forma permanente.

# **2.2 Control Estructurado mediante TRY/CATCH**

El control explícito se implementó mediante BEGIN TRANSACTION, COMMIT TRANSACTION y ROLLBACK TRANSACTION, combinados con bloques de manejo de excepciones BEGIN TRY ... BEGIN CATCH y validaciones con RAISERROR.


BEGIN TRY

    BEGIN TRANSACTION;


    IF (SELECT stock\_actual FROM Producto WHERE id\_producto = @ProductoId) \< @CantidadComprar

    BEGIN

        RAISERROR('Stock insuficiente para concretar la venta.', 16, 1);

    END;


    INSERT INTO Venta (fecha\_hora, total\_venta, id\_medio\_pago, id\_persona\_usuario, id\_persona\_cliente)

    VALUES (GETDATE(), 90000.00, 1, 2, 4);


    SELECT @IdVentaGenerada = SCOPE\_IDENTITY();


    INSERT INTO DetalleVenta (id\_venta, id\_producto, precio\_congelado, cantidad)

    VALUES (@IdVentaGenerada, @ProductoId, 45000.00, @CantidadComprar);


    UPDATE Producto SET stock\_actual = stock\_actual - @CantidadComprar

    WHERE id\_producto = @ProductoId;


    COMMIT TRANSACTION;

END TRY

BEGIN CATCH

    IF @@TRANCOUNT \> 0 ROLLBACK TRANSACTION;

END CATCH;



*Algoritmo 2: Control de transacción con validación de existencia y rollback*

# **2.3 Evaluación de Escenarios Prácticos**

- **Escenario de Éxito (COMMIT):** Con un stock inicial de 25 unidades, se concreta la venta de 2 unidades. El motor confirma la operación, genera el ticket comprobante N° 52 y reduce el stock final exactamente a 23 unidades.

- **Escenario de Excepción (ROLLBACK):** Al solicitar 99.999 unidades con solo 23 en stock, la condición invalida la venta y ejecuta RAISERROR. El bloque CATCH intercepta el error y dispara ROLLBACK TRANSACTION, dejando el stock intacto en 23 unidades y evitando la creación de ventas huérfanas.

**3. Triggers (Disparadores) de Auditoría e Integridad Preventiva**

# **3.1 Definición y Mecanismos de Activación**

Los *triggers* son bloques especiales de código T-SQL vinculados a una tabla que se ejecutan automáticamente cuando ocurre un evento DML (INSERT, UPDATE, DELETE). Los disparadores operan utilizando las tablas temporales del sistema inserted y deleted.

# **3.2 Tipos de Triggers Implementados**

1. **Trigger de Auditoría Histórica dbo.tr\_auditoria\_producto (AFTER UPDATE, DELETE):** Ante cualquier actualización o borrado sobre producto, extrae la foto previa del registro desde deleted y la graba en auditoria\_producto, capturando además la identidad del usuario (SUSER\_SNAME()) y la estampa temporal (SYSDATETIME()).

2. **Trigger de Integridad Preventiva dbo.tr\_control\_delete\_categoria (INSTEAD OF DELETE):** Intercepta la sentencia de borrado sobre categoria. Si la categoría contiene artículos asociados en producto, cancela la acción emitiendo un mensaje de negocio y evita errores no controlados de clave foránea.


*Tabla 2: Registro histórico almacenado en la tabla de auditoría ante una actualización*


| ID Aud. | ID Prod. | Nombre Anterior | Stock Ant. | Precio Ant. | Operación | Usuario BD | Fecha y Hora |
| - | - | - | - | - | - | - | - |
| 1 | 1 | Mate Imperial Calabaza | 25 | $ 45.000,00 | UPDATE | sa | 2026-10-28 19:55:39 |

**4. Seguridad: Permisos, Roles y Encadenamiento de Propiedad**

# **4.1 Principio de Mínimo Privilegio**

El esquema de seguridad distingue formalmente entre Inicios de Sesión (*Logins*) a nivel de servidor y Usuarios de Base de Datos / Roles a nivel del esquema sistema\_matiensos.


Tabla 3: Asignación de roles y matriz de permisos del sistema


| Entidad | Tipo | Rol Asignado | Permisos Efectivos Concedidos |
| - | - | - | - |
| usuario\_admin | Usuario BD | db\_owner | Acceso y control total (DDL, DML, DCL). |
| usuario\_lector | Usuario BD | Directo | GRANT SELECT general, con DENY SELECT sobre Usuario(contraseña). |
| rol\_vendedor | Rol BD | Personalizado | GRANT SELECT en tablas operativas, DENY en sensibles, GRANT EXECUTE en SP. |
| usuario\_vendedor | Usuario BD | rol\_vendedor | Hereda estrictamente los permisos del rol. |

# **4.2 Encadenamiento de Propiedad (Ownership Chaining)**

El encadenamiento de propiedad permite otorgar al usuario\_vendedor el permiso de ejecutar dbo.sp\_RegistrarVenta sin concederle permisos directos de INSERT o UPDATE sobre Venta y Producto. Como el procedimiento almacenado y las tablas pertenecen al mismo propietario (dbo), SQL Server verifica únicamente la autorización EXECUTE sobre el procedimiento, permitiendo realizar la venta de forma encapsulada y segura.

**5. Optimización de Consultas mediante Índices**

# **5.1 Estructura de Índices y Cobertura**

Los índices optimizan la recuperación de filas mediante estructuras de árbol B+, evitando el recorrido completo de la tabla (Table Scan). Un índice no agrupado (Nonclustered) con cláusula INCLUDE agrega columnas adicionales en el nivel hoja, permitiendo resolver la consulta íntegramente mediante un acceso directo (Index Seek).

# **5.2 Caso Experimental y Medición de Rendimiento**

Se creó la tabla masiva Venta\_Masiva con 1.000.000 de registros para evaluar la consulta del primer trimestre del año 2023. Se activaron las herramientas de diagnóstico SET STATISTICS TIME ON y SET STATISTICS IO ON.


Tabla 4: Comparativa de rendimiento ante consultas masivas en SQL Server


| Escenario de Prueba | Tiempo CPU (ms) | Tiempo Total (ms) | Lecturas Lógicas | Operación en Plan de Ejecución |
| - | - | - | - | - |
| Sin índice (escaneo de tabla) | 141 ms | 181 ms | 5.346 | Clustered Index Scan |
| Con índice de cobertura | 0 ms | 0 ms | 165 | Index Seek |


Cálculo de la reducción porcentual en lecturas lógicas:


(5346 - 165) / 5346 \* 100 = 96.91% (1)


La implementación del índice de cobertura representó una mejora del 96,91% en consumo de memoria I/O y redujo a cero el tiempo de procesamiento en la CPU.

**C) CONCLUSIONES**

La realización de esta monografía técnica permite concluir que el traslado de las reglas operativas, el control transaccional, las políticas de seguridad y la optimización de consultas al propio motor relacional Microsoft SQL Server Express es indispensable para asegurar la calidad de un software empresarial.


En primer lugar, los procedimientos almacenados y las funciones escalares demostraron su capacidad para centralizar cálculos complejos de facturación y descuentos, promoviendo la reutilización de código y disminuyendo el uso de procesador. En segundo lugar, el manejo explícito de transacciones garantizó la atomicidad de las operaciones comerciales, impidiendo la existencia de tickets huérfanos o actualizaciones inconsistentes de stock. En tercer lugar, los disparadores demostraron ser mecanismos eficaces tanto para mantener trazas de auditoría pasiva como para prevenir el borrado accidental de datos mediante reglas lógicas.


En cuarto lugar, el esquema de seguridad basado en roles y encadenamiento de propiedad posibilitó otorgar la máxima capacidad operativa a los usuarios finales bajo el principio de mínimo privilegio. Finalmente, los ensayos de optimización con índices de cobertura evidenciaron reducciones drásticas del 96,91% en lecturas de entrada/salida y consumo de CPU, demostrando la alta eficiencia que alcanza un motor relacional adecuadamente configurado.

**D) REFERENCIAS BIBLIOGRÁFICAS**

\[1\] Cátedra de Base de Datos I, "Formato de presentación de monografías," Universidad Nacional del Nordeste, Corrientes, Argentina, Pautas de la Cátedra, 2024.


\[2\] Equipo 38, "Conceptos Técnicos — Sistema de Ventas Matiensos," Universidad Nacional del Nordeste, Corrientes, Argentina, Documento técnico interno, 2026.


\[3\] IEEE Standard for Systems and Software Documentation, IEEE Std 829-2008, IEEE Computer Society, 2008.


\[4\] Microsoft Corporation, "SQL Server Technical Documentation: Stored Procedures, Transactions, Triggers and Index Optimization," Microsoft Learn, 2024.


\[5\] Cátedra de Base de Datos I, "Resumen de cuestiones prácticas de SQL y orden lógico de ejecución," Universidad Nacional del Nordeste, Corrientes, Argentina, 2024.
