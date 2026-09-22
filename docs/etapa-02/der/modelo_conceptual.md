# Diagrama Entidad-conceptualn: BDI-Grupo38

    PERSONA {
        int id_persona PK
        string dni
        string nombre
        string apellido
        string telefono
        string correo
    }

    USUARIO {
        string nombre_usuario
        string contrasena
    }

    CLIENTE {
        string tipo
    }

    ROL {
        int id_rol PK
        string nombre
        string descripcion
    }

    PROVEEDOR {
        int id_proveedor PK
        string cuit
        string razon_social
        string telefono
    }

    PRODUCTO {
        int id_producto PK
        string nombre
        decimal precio
        int stock_actual
    }

    CATEGORIA {
        int id_categoria PK
        string nombre
        string descripcion
    }

    VENTA {
        int id_venta PK
        datetime fecha_hora
        decimal total_venta
    }

    DETALLE_VENTA {
        int cantidad
        decimal precio_congelado
    }

    MEDIO_PAGO {
        int id_medio_pago PK
        string tipo
    }

    %% Jerarquía / Especialización (Disjunta)
    PERSONA ||--o| USUARIO : "es_un"
    PERSONA ||--o| CLIENTE : "es_un"

    %% Relaciones
    ROL ||--|{ USUARIO : "tiene"
    USUARIO ||--o{ VENTA : "genera"
    CLIENTE ||--o{ VENTA : "compra"

    VENTA ||--|{ DETALLE_VENTA : "contiene"
    PRODUCTO ||--o{ DETALLE_VENTA : "esta"

    CATEGORIA ||--|{ PRODUCTO : "tiene"
    PROVEEDOR ||--|{ PRODUCTO : "provee"
    VENTA }|--|| MEDIO_PAGO : "tiene"