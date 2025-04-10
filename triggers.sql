-- ################# 1. INSERT #################

-- BEFORE INSERT: Validar stock antes de insertar un detalle de arreglo
CREATE OR REPLACE FUNCTION validar_stock_flor()
RETURNS TRIGGER AS $$
DECLARE 
    stock_actual INT;
BEGIN 
    SELECT stock INTO stock_actual 
    FROM inventario
    WHERE id_flor = NEW.id_flor;

    IF stock_actual IS NULL THEN 
        RAISE EXCEPTION 'La flor con ID % no existe en inventario.', NEW.id_flor;
    END IF;

    IF NEW.cantidad > stock_actual THEN 
        RAISE EXCEPTION 'Stock insuficiente para flor de ID %. Disponible: %, Solicitado: %.',
            NEW.id_flor, stock_actual, NEW.cantidad;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_detalle_arreglo 
BEFORE INSERT ON detalle_arreglo
FOR EACH ROW 
EXECUTE FUNCTION validar_stock_flor();


-- AFTER INSERT: Descontar del inventario después de insertar
CREATE OR REPLACE FUNCTION descontar_stock_flor()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE inventario
    SET stock = stock - NEW.cantidad
    WHERE id_flor = NEW.id_flor;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_insert_detalle_arreglo
AFTER INSERT ON detalle_arreglo 
FOR EACH ROW 
EXECUTE FUNCTION descontar_stock_flor();

-- ################# 2. UPDATE #################

-- BEFORE UPDATE: Validar precio y rol de usuario antes de actualizar
CREATE OR REPLACE FUNCTION aviso_actualizacion_precio()
RETURNS TRIGGER AS $$  
DECLARE
    rol_usuario TEXT;
BEGIN 
    IF NEW.precio < 0 THEN
        RAISE EXCEPTION 'El precio no puede ser negativo';
    END IF;
    
    SELECT r.nombre INTO rol_usuario
    FROM usuarios u 
    JOIN roles r ON u.id_rol = r.id
    WHERE u.id = NEW.modificado_por;

    IF rol_usuario IS DISTINCT FROM 'admin' THEN
        RAISE EXCEPTION 'Solo los administradores pueden modificar el precio del arreglo.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_update_precio_arreglo
BEFORE UPDATE ON arreglos
FOR EACH ROW 
WHEN (OLD.precio IS DISTINCT FROM NEW.precio)
EXECUTE FUNCTION aviso_actualizacion_precio();

-- AFTER UPDATE REGISTRAR EN LA TABLA HISTORIAL CAMBIOS PRODUCTO SI SE CAMBIA UN ARREGLO
CREATE OR REPLACE FUNCTION registrar_cambios_arreglo()
RETURNS TRIGGER AS $$
BEGIN
    -- Si cambia el nombre
    IF NEW.nombre IS DISTINCT FROM OLD.nombre THEN
        INSERT INTO historial_cambios_producto(id_arreglo, campo_modificado, valor_anterior, valor_actual, modificado_por)
        VALUES (OLD.id, 'nombre', OLD.nombre, NEW.nombre, NEW.modificado_por);
    END IF;

    -- Si cambia el precio
    IF NEW.precio IS DISTINCT FROM OLD.precio THEN
        INSERT INTO historial_cambios_producto(id_arreglo, campo_modificado, valor_anterior, valor_actual, modificado_por)
        VALUES (OLD.id, 'precio', OLD.precio::TEXT, NEW.precio::TEXT, NEW.modificado_por);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_update_arreglos
AFTER UPDATE ON arreglos
FOR EACH ROW
EXECUTE FUNCTION registrar_cambios_arreglo();


-- ################# 3. DELETE #################

-- BEFORE DELETE: Mostrar aviso antes de borrar un detalle de arreglo
CREATE OR REPLACE FUNCTION aviso_borrado()
RETURNS TRIGGER AS $$  
BEGIN 
    RAISE NOTICE 'Se quiso borrar un registro de detalle_arreglo con ID %', OLD.id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_delete_detalle_arreglo
BEFORE DELETE ON detalle_arreglo 
FOR EACH ROW 
EXECUTE FUNCTION aviso_borrado();

-- AFTER DELETE: Registrar en log la eliminación
CREATE OR REPLACE FUNCTION log_delete_detalle_arreglo()
RETURNS TRIGGER AS $$  
BEGIN 
    INSERT INTO log_eliminaciones(tabla, id_eliminado)
    VALUES ('detalle_arreglo', OLD.id);
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_delete_log_detalle_arreglo 
AFTER DELETE ON detalle_arreglo 
FOR EACH ROW 
EXECUTE FUNCTION log_delete_detalle_arreglo();

-- ################# 4. TRUNCATE #################


-- BEFORE TRUNCATE: VERIFICA QUE LA PERSONA QUE INTENTA HACER TRUNCATE EN LA TABLA DE LOS DE LOG ELIMINACIONES TENGA PERMISOS DE ADMINISTRADOR

CREATE OR REPLACE FUNCTION bloquear_truncate_si_no_es_admin()
RETURNS TRIGGER AS $$
DECLARE
    rol_usuario TEXT;
BEGIN
    SELECT rol INTO rol_usuario
    FROM usuarios
    WHERE nombre = current_user;

    IF rol_usuario IS DISTINCT FROM 'admin' THEN
        RAISE EXCEPTION 'Acceso denegado: solo los administradores pueden truncar la tabla log_eliminaciones. Usuario: %', current_user;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_truncate_log_eliminaciones
BEFORE TRUNCATE ON log_eliminaciones
FOR EACH STATEMENT
EXECUTE FUNCTION bloquear_truncate_si_no_es_admin();

-- AFTER TRUNCATE: Registrar los cambios despues de truncar los pedidos

CREATE OR REPLACE FUNCTION registrar_truncate()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO log_truncates(tabla_afectada, usuario)
    VALUES (TG_TABLE_NAME, current_user);

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_truncate_log_eliminaciones
AFTER TRUNCATE ON log_eliminaciones
FOR EACH STATEMENT
EXECUTE FUNCTION registrar_truncate();


