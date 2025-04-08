-- Creación de la tabla 'roles'
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL
);

-- Creación de la tabla 'usuarios'
CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    id_rol INT NOT NULL,
    correo VARCHAR(100) UNIQUE NOT NULL,
    FOREIGN KEY (id_rol) REFERENCES roles(id)
);

-- Creación de la tabla 'direcciones'
CREATE TABLE direcciones (
    id SERIAL PRIMARY KEY,
    descripcion TEXT NOT NULL,
    id_usuario INT NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id)
);

-- Creación de la tabla 'flores'
CREATE TABLE flores (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT
);

-- Creación de la tabla 'arreglos'
CREATE TABLE arreglos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    precio DECIMAL(10, 2) NOT NULL
);

-- Creación de la tabla 'pedidos'
CREATE TABLE pedidos (
    id SERIAL PRIMARY KEY,
    id_usuario INT NOT NULL,
    id_direccion INT NOT NULL,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(50) NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id),
    FOREIGN KEY (id_direccion) REFERENCES direcciones(id)
);

-- Creación de la tabla 'detalle_pedidos'
CREATE TABLE detalle_pedidos (
    id SERIAL PRIMARY KEY,
    id_pedido INT NOT NULL,
    nombre_arreglo VARCHAR(100) NOT NULL,
    precio DECIMAL(10, 2) NOT NULL,
    mensaje TEXT,
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id)
);

-- Creación de la tabla 'detalle_arreglo'
CREATE TABLE detalle_arreglo (
    id SERIAL PRIMARY KEY,
    id_detalle_pedido INT NOT NULL,
    id_flor INT NOT NULL,
    cantidad INT NOT NULL,
    FOREIGN KEY (id_detalle_pedido) REFERENCES detalle_pedidos(id),
    FOREIGN KEY (id_flor) REFERENCES flores(id)
);

-- Creación de la tabla 'inventario'
CREATE TABLE inventario (
    id SERIAL PRIMARY KEY,
    id_flor INT NOT NULL UNIQUE,
    stock INT NOT NULL,
    FOREIGN KEY (id_flor) REFERENCES flores(id)
);

-- Creación de la tabla 'historial_clientes'
CREATE TABLE historial_clientes (
    id SERIAL PRIMARY KEY,
    id_usuario INT NOT NULL,
    id_pedido INT NOT NULL,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id),
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id)
);

-- Creación de la tabla 'historial_cambios_producto'
CREATE TABLE historial_cambios_producto (
    id SERIAL PRIMARY KEY,
    id_arreglo INT NOT NULL,
    campo_modificado VARCHAR(100) NOT NULL,
    valor_anterior TEXT,
    valor_actual TEXT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modificado_por INT NOT NULL,
    FOREIGN KEY (id_arreglo) REFERENCES arreglos(id),
    FOREIGN KEY (modificado_por) REFERENCES usuarios(id)
);

-- Creación de la tabla 'historial_cambios_usuario'
CREATE TABLE historial_cambios_usuario (
    id SERIAL PRIMARY KEY,
    id_usuario INT NOT NULL,
    campo_modificado VARCHAR(100) NOT NULL,
    valor_anterior TEXT,
    valor_actual TEXT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modificado_por INT NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id),
    FOREIGN KEY (modificado_por) REFERENCES usuarios(id)
);

-- Creación de la tabla 'repartidor_pedido'
CREATE TABLE repartidor_pedido (
    id SERIAL PRIMARY KEY,
    id_pedido INT NOT NULL,
    id_repartidor INT NOT NULL,
    fecha_estimada_entrega DATE NOT NULL,
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id),
    FOREIGN KEY (id_repartidor) REFERENCES usuarios(id)
);

-- Creación de la tabla 'historial_entregas'
CREATE TABLE historial_entregas (
    id SERIAL PRIMARY KEY,
    id_pedido INT NOT NULL,
    fecha_entrega DATE NOT NULL,
    observaciones TEXT,
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id)
);