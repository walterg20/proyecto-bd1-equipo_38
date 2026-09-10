# Decisiones de diseño

#Generalizacion
El equipo tomó la decisión de aplicar una generalización para las entidades PERSONA, USUARIO y CLIENTE. Dado que comparten varios campos, agrupamos los datos comunes en la entidad PERSONA y mantuvimos los atributos específicos en cada uno de sus respectivos subtipos dentro del modelo conceptual de la base de datos.

#Relacion de Muchos a Muchos VENTA-PRODUCTO
Para el diseño del modelo conceptual, el equipo decidió representar Detalle_venta como una entidad débil en lugar de mantener una relación clásica de muchos a muchos entre PRODUCTO y VENTA. 
Esta estructura modela con mayor precisión la realidad del negocio, ya que cada línea del detalle carece de existencia propia y depende estrictamente de la entidad fuerte VENTA para su identificación y persistencia, además de permitir almacenar atributos específicos como la cantidad y el precio de forma óptima.