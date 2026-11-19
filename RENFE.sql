-- ==============================================================================
-- PRÁCTICA 1: EER y DDL - TEMÁTICA: RENFE
-- ==============================================================================

SET AUTOCOMMIT on;
SET SERVEROUTPUT on; -- COMPROBACIÓN DE RESTRICCIONES (Pruebas Negativas envueltas en EXCEPTION para no romper el script)

-- ==============================================================================
-- 1. SENTENCIAS DE INICIALIZACIÓN (DROP'S)
-- ==============================================================================
-- Se ejecutan con bloque PL/SQL para que no fallen en la primera ejecución si 
-- las tablas o vistas no existen. Todas las sentencias DROP incluyen CASCADE CONSTRAINTS
-- para eliminar también las restricciones asociadas (FKs, PKs, CHECKs) en el orden
-- inverso de creación, evitando errores de dependencias residuales.

-- Vistas (Nombres exactos creados más abajo)
DROP VIEW VISTA_VIAJES_COMPLETOS;
DROP VIEW VISTA_PASAJEROS_BASICO;

-- Tablas de relaciones N:M y entidades dependientes. Se usan CASCADE CONSTRAINTS
-- para limpiar las FKs que referencian estas tablas antes de eliminarlas.
DROP TABLE PASAJERO_VIAJE CASCADE CONSTRAINTS; -- Tabla asociación pasajero-viaje
DROP TABLE REVISOR_VIAJE CASCADE CONSTRAINTS; -- Tabla asociación revisor-viaje
DROP TABLE VIAJE CASCADE CONSTRAINTS; -- Viajes tren+ruta
DROP TABLE BILLETE_ESPECIAL CASCADE CONSTRAINTS; -- Billetes con descuento
DROP TABLE BILLETE_CLASICO CASCADE CONSTRAINTS;  -- Billetes sin descuento
DROP TABLE BILLETE CASCADE CONSTRAINTS; -- Billetes básicos
DROP TABLE INSTALACION CASCADE CONSTRAINTS; -- Instalaciones pieza-tren

-- Subtipos de Empleado. Cada tabla hija incluye CASCADE CONSTRAINTS en su propia
-- sentencia DROP para mantener la integridad al eliminar en orden inverso.
DROP TABLE SEGURIDAD CASCADE CONSTRAINTS; -- Empleado seguridad
DROP TABLE TECNICO CASCADE CONSTRAINTS; -- Empleado técnico
DROP TABLE REVISOR CASCADE CONSTRAINTS; -- Empleador revisor
DROP TABLE MAQUINISTA CASCADE CONSTRAINTS; -- Empleado maquinista

-- Vagones y Trenes (Subtipos). Orden importante: vagones y trenes específicos antes
-- que las jerarquías generales.
DROP TABLE VAGON CASCADE CONSTRAINTS; -- Vagones asociados a trenes
DROP TABLE TREN_MERCANCIA CASCADE CONSTRAINTS; -- Trenes de mercancía
DROP TABLE TREN_PASAJEROS CASCADE CONSTRAINTS; -- Trenes de pasajeros
DROP TABLE TREN CASCADE CONSTRAINTS; -- Entidad tren base

-- Entidades débiles o dependientes restantes. CASCADE CONSTRAINTS necesario para
-- eliminar las FKs que apuntan a sus padres fuertes.
DROP TABLE RECLAMACION CASCADE CONSTRAINTS; -- Reclamaciones pasajero
DROP TABLE ANDEN CASCADE CONSTRAINTS; -- Andenes de estación
DROP TABLE PIEZA CASCADE CONSTRAINTS; -- Piezas de material
DROP TABLE BULTO CASCADE CONSTRAINTS; -- Equipaje de pasajero
DROP TABLE TAQUILLA CASCADE CONSTRAINTS; -- Taquillas de estación

-- Entidades fuertes (principales). Se eliminan con CASCADE CONSTRAINTS para
-- limpiar todas las FKs que las referencian de las entidades dependientes.
DROP TABLE PROVEEDOR CASCADE CONSTRAINTS; -- Proveedores de piezas
DROP TABLE RUTA CASCADE CONSTRAINTS; -- Rutas ferroviarias
DROP TABLE PASAJERO CASCADE CONSTRAINTS; -- Pasajeros del sistema
DROP TABLE EMPLEADO CASCADE CONSTRAINTS; -- Empleados del sistema
DROP TABLE ALMACEN CASCADE CONSTRAINTS; -- Almacenes de material
DROP TABLE ESTACION CASCADE CONSTRAINTS; -- Estaciones del réseau

-- ==============================================================================
-- 2. CREACIÓN DE TABLAS Y RESTRICCIONES (DDL)
-- ==============================================================================

-- ENTIDADES FUERTES / INDEPENDIENTES --

CREATE TABLE Estacion (
    cod_estacion VARCHAR2(10) CONSTRAINT pk_estacion PRIMARY KEY,
    nombre VARCHAR2(100) CONSTRAINT nn_estacion_nombre NOT NULL,
    calle VARCHAR2(100),
    numero VARCHAR2(10),
    ciudad VARCHAR2(50),
    cp VARCHAR2(5),
    num_vias NUMBER(3) CONSTRAINT chk_estacion_vias CHECK (num_vias > 0),
    telefono VARCHAR2(15)
); -- Tabla base de estaciones. Sin ON DELETE CASCADE porque es entidad fuerte
-- raíz; su eliminación debe ser manual controlada para preservar historial.

CREATE TABLE Almacen (
    cod_alm VARCHAR2(10) CONSTRAINT pk_almacen PRIMARY KEY,
    telefono VARCHAR2(15),
    max_trenes NUMBER(4) CONSTRAINT chk_almacen_max CHECK (max_trenes >= 0),
    calle VARCHAR2(100),
    numero VARCHAR2(10),
    ciudad VARCHAR2(50),
    cp VARCHAR2(5)
); -- Tabla de almacenes. Sin borrado en cascada: un almacén puede
-- desactivarse sin borrar su historial de movimiento de trenes.

CREATE TABLE Pasajero (
    dni VARCHAR2(9) CONSTRAINT pk_pasajero PRIMARY KEY,
    nombre VARCHAR2(100) CONSTRAINT nn_pasajero_nombre NOT NULL,
    correo VARCHAR2(100) CONSTRAINT uk_pasajero_correo UNIQUE,
    edad NUMBER(3) CONSTRAINT chk_pasajero_edad CHECK (edad >= 0)
); -- Tabla de pasajeros. Sin ON DELETE CASCADE: los pasajeros son
-- registros persistentes incluso si dejan de usar el sistema.

CREATE TABLE Ruta (
    cod_ruta VARCHAR2(10) CONSTRAINT pk_ruta PRIMARY KEY,
    lugar_inicio VARCHAR2(50) CONSTRAINT nn_ruta_inicio NOT NULL,
    lugar_fin VARCHAR2(50) CONSTRAINT nn_ruta_fin NOT NULL,
    distancia NUMBER(6,2) CONSTRAINT chk_ruta_distancia CHECK (distancia > 0)
); -- Tabla de rutas ferroviarias. Sin borrado en cascada: las rutas
-- históricas se mantienen para análisis aunque no estén activas.

CREATE TABLE Proveedor (
    cif VARCHAR2(15) CONSTRAINT pk_proveedor PRIMARY KEY,
    nombre VARCHAR2(100) CONSTRAINT nn_proveedor_nombre NOT NULL,
    calle VARCHAR2(100),
    numero VARCHAR2(10),
    ciudad VARCHAR2(50),
    cp VARCHAR2(5),
    email VARCHAR2(100)
); -- Tabla de proveedores. Sin ON DELETE CASCADE: las relaciones
-- comerciales se registran independientemente de la actividad del proveedor.

CREATE TABLE Empleado (
    dni VARCHAR2(9) CONSTRAINT pk_empleado PRIMARY KEY,
    nss VARCHAR2(15) CONSTRAINT uk_empleado_nss UNIQUE NOT NULL,
    nombre VARCHAR2(100) CONSTRAINT nn_empleado_nombre NOT NULL,
    f_nac DATE,
    telefono1 VARCHAR2(15),
    telefono2 VARCHAR2(15)
); -- Tabla base de empleados. Sin ON DELETE CASCADE: el empleado
-- puede cesar sin afectar automáticamente sus subtipos especializados.

-- ENTIDADES DEPENDIENTES Y SUBTIPOS DE EMPLEADO --

CREATE TABLE Maquinista (
    dni VARCHAR2(9) CONSTRAINT pk_maquinista PRIMARY KEY,
    horas_conduccion NUMBER(6) CONSTRAINT chk_maq_horas CHECK (horas_conduccion >= 0),
    CONSTRAINT fk_maquinista_emp FOREIGN KEY (dni) REFERENCES Empleado(dni) ON DELETE CASCADE
); -- ON DELETE CASCADE: un maquinista es un empleado especializado.
-- Si se elimina el empleado, su registro de maquinista también debe
-- desaparecer para evitar registros huérfanos de personal ferroviario.

CREATE TABLE Revisor (
    dni VARCHAR2(9) CONSTRAINT pk_revisor PRIMARY KEY,
    idiomas VARCHAR2(255),
    CONSTRAINT fk_revisor_emp FOREIGN KEY (dni) REFERENCES Empleado(dni) ON DELETE CASCADE
); -- ON DELETE CASCADE: un revisor es un empleado especializado.
-- Su eliminación automática mantiene la coherencia con la tabla base.

CREATE TABLE Tecnico (
    dni VARCHAR2(9) CONSTRAINT pk_tecnico PRIMARY KEY,
    especialidad VARCHAR2(100),
    dni_supervisor VARCHAR2(9), -- FK reflexiva más abajo
    CONSTRAINT fk_tecnico_emp FOREIGN KEY (dni) REFERENCES Empleado(dni) ON DELETE CASCADE
); -- ON DELETE CASCADE: un técnico es un empleado especializado.
-- A continuación se añade la FK reflexiva SIN ON DELETE CASCADE (ver comentario abajo).

-- Añadimos la FK Reflexiva para Técnicos. No usamos borrado en cascada para evitar 
-- borrar todo un árbol de supervisión por accidente. Si un técnico es eliminado,
-- sus subordinados directos deben reasignarse o mantenerse, no destruirse masivamente.
ALTER TABLE Tecnico ADD CONSTRAINT fk_tecnico_supervisor 
    FOREIGN KEY (dni_supervisor) REFERENCES Tecnico(dni);

CREATE TABLE Seguridad (
    dni VARCHAR2(9) CONSTRAINT pk_seguridad PRIMARY KEY,
    nivel VARCHAR2(50),
    cod_estacion VARCHAR2(10) CONSTRAINT nn_seg_estacion NOT NULL,
    CONSTRAINT fk_seguridad_emp FOREIGN KEY (dni) REFERENCES Empleado(dni) ON DELETE CASCADE,
    CONSTRAINT fk_seguridad_est FOREIGN KEY (cod_estacion) REFERENCES Estacion(cod_estacion)
); -- ON DELETE CASCADE en fk_seguridad_emp: un empleado de seguridad
-- cuando deja la empresa, su registro de seguridad también debe eliminirse
-- para evitar permisos huérfanos. La FK a Estación NO usa cascada porque
-- un guardia puede reasignarse a otra estación.

-- ENTIDADES DÉBILES (DEPENDEN DE FUERTES) --

CREATE TABLE Anden (
    cod_estacion VARCHAR2(10),
    num_anden NUMBER(3),
    longitud NUMBER(5,2) CONSTRAINT chk_anden_long CHECK (longitud > 0),
    CONSTRAINT pk_anden PRIMARY KEY (cod_estacion, num_anden),
    CONSTRAINT fk_anden_estacion FOREIGN KEY (cod_estacion) REFERENCES Estacion(cod_estacion) ON DELETE CASCADE
); -- ON DELETE CASCADE: un andén pertenece exclusivamente a una estación.
-- Si se elimina la estación, sus andenes quedan sin sentido y se eliminan
-- automáticamente. No tiene sentido mantener andenes de una estación inexistente.

CREATE TABLE Taquilla (
    cod_estacion VARCHAR2(10),
    num_taquilla NUMBER(3),
    estado VARCHAR2(20) CONSTRAINT chk_taq_estado CHECK (estado IN ('Abierta', 'Cerrada', 'En mantenimiento')),
    turno VARCHAR2(20),
    CONSTRAINT pk_taquilla PRIMARY KEY (cod_estacion, num_taquilla),
    CONSTRAINT fk_taquilla_estacion FOREIGN KEY (cod_estacion) REFERENCES Estacion(cod_estacion) ON DELETE CASCADE
); -- ON DELETE CASCADE: una taquilla es específica de una estación.
-- Si se cierra o elimina la estación, su taquilla associated también debe
-- eliminirse. No tiene sentido conservar taquillas de una estación desaparecida.

CREATE TABLE Bulto (
    dni_pasajero VARCHAR2(9),
    num_bulto NUMBER(3),
    peso_kg NUMBER(5,2) CONSTRAINT chk_bulto_peso CHECK (peso_kg > 0),
    ancho NUMBER(5,2),
    largo NUMBER(5,2),
    CONSTRAINT pk_bulto PRIMARY KEY (dni_pasajero, num_bulto),
    CONSTRAINT fk_bulto_pasajero FOREIGN KEY (dni_pasajero) REFERENCES Pasajero(dni) ON DELETE CASCADE
); -- ON DELETE CASCADE: un bulto viaja con un pasajero específico.
-- Si el pasajero se borra del sistema (por ejemplo, por baja definitive),
-- su equipaje registrarse también debe eliminirse por coherencia lógica.
-- En un escenario real podría protegerse, pero el diseño propone cascada.

CREATE TABLE Reclamacion (
    id_reclamacion VARCHAR2(10) CONSTRAINT pk_reclamacion PRIMARY KEY,
    fecha DATE DEFAULT SYSDATE,
    motivo VARCHAR2(500),
    dni_pasajero VARCHAR2(9) CONSTRAINT nn_reclamacion_pasajero NOT NULL,
    CONSTRAINT fk_reclamacion_pasajero FOREIGN KEY (dni_pasajero) REFERENCES Pasajero(dni) ON DELETE CASCADE
); -- ON DELETE CASCADE: una reclamación está asociada a un pasajero.
-- Si el pasajero se da de baja, sus reclamaciones registradas también
-- deben eliminirse para mantener un historial coherente por usuario.

CREATE TABLE Pieza (
    cod_pieza VARCHAR2(10) CONSTRAINT pk_pieza PRIMARY KEY,
    nombre VARCHAR2(100) CONSTRAINT nn_pieza_nombre NOT NULL,
    descripcion VARCHAR2(255),
    precio NUMBER(8,2) CONSTRAINT chk_pieza_precio CHECK (precio >= 0),
    cif_proveedor VARCHAR2(15) CONSTRAINT nn_pieza_prov NOT NULL,
    CONSTRAINT fk_pieza_proveedor FOREIGN KEY (cif_proveedor) REFERENCES Proveedor(cif)
); -- Sin ON DELETE CASCADE: una pieza puede cambiar de proveedor o
-- mantenerse en el inventario aunque el proveedor original haya dejado
-- de suministrar. La relación es de asignación, no de dependencia total.

-- TREN Y VAGONES --

CREATE TABLE Tren (
    num_serie VARCHAR2(15) CONSTRAINT pk_tren PRIMARY KEY,
    modelo VARCHAR2(50),
    potencia NUMBER(6),
    fecha_fabr DATE,
    num_max_vagones NUMBER(3) CONSTRAINT chk_tren_maxvag CHECK (num_max_vagones > 0),
    cod_alm VARCHAR2(10) CONSTRAINT nn_tren_alm NOT NULL,
    destino_cod_estacion VARCHAR2(10) CONSTRAINT nn_tren_dest_est NOT NULL,
    destino_num_anden NUMBER(3) CONSTRAINT nn_tren_dest_and NOT NULL,
    CONSTRAINT fk_tren_almacen FOREIGN KEY (cod_alm) REFERENCES Almacen(cod_alm),
    CONSTRAINT fk_tren_anden FOREIGN KEY (destino_cod_estacion, destino_num_anden) REFERENCES Anden(cod_estacion, num_anden)
); -- Sin ON DELETE CASCADE en fk_tren_almacen: un tren puede moverse
-- a otro almacén sin necesidad de borrarse. La FK a Anden indica el destino
-- actual, no una dependencia de destrucción mutua.

CREATE TABLE Tren_Pasajeros (
    num_serie VARCHAR2(15) CONSTRAINT pk_tren_pas PRIMARY KEY,
    clase VARCHAR2(50),
    CONSTRAINT fk_trenpas_tren FOREIGN KEY (num_serie) REFERENCES Tren(num_serie) ON DELETE CASCADE
); -- ON DELETE CASCADE: Tren_Pasajeros es una subtipo de Tren. Si se
-- elimina el tren base, su variante de pasajeros también debe desaparecer
-- ya que no tiene sentido existir sin el tren padre.

CREATE TABLE Tren_Mercancia (
    num_serie VARCHAR2(15) CONSTRAINT pk_tren_mer PRIMARY KEY,
    tipo_mercancia VARCHAR2(100),
    CONSTRAINT fk_trenmer_tren FOREIGN KEY (num_serie) REFERENCES Tren(num_serie) ON DELETE CASCADE
); -- ON DELETE CASCADE: igual que Tren_Pasajeros, Tren_Mercancia es una
-- especialización del tren base. Su eliminación es automática cuando el tren
-- padre es dado de baja.

CREATE TABLE Vagon (
    num_serie_tren VARCHAR2(15),
    num_vagon NUMBER(3),
    tipo_vagon VARCHAR2(20) CONSTRAINT chk_vagon_tipo CHECK (tipo_vagon IN ('Pasajeros', 'Restaurante', 'Mercancías')),
    capacidad NUMBER(6) CONSTRAINT chk_vagon_cap CHECK (capacidad > 0),
    anho_fab NUMBER(4),
    -- Relación reflexiva: número del vagón acoplado a continuación (mismo tren)
    vagon_sig_num NUMBER(3),
    CONSTRAINT pk_vagon PRIMARY KEY (num_serie_tren, num_vagon),
    CONSTRAINT chk_vagon_sig CHECK (vagon_sig_num <> num_vagon),
    CONSTRAINT fk_vagon_tren FOREIGN KEY (num_serie_tren) REFERENCES Tren(num_serie) ON DELETE CASCADE,
    CONSTRAINT fk_vagon_reflexiva FOREIGN KEY (num_serie_tren, vagon_sig_num)REFERENCES Vagon(num_serie_tren, num_vagon)
); -- ON DELETE CASCADE en fk_vagon_tren: los vagones forman parte de un tren.
-- Si el tren se destruye, sus vagones también deben eliminirse. Sin embargo,
-- la FK reflexiva fk_vagon_reflexiva NO usa ON DELETE CASCADE porque el vagón
-- "siguiente" puede reacoplarse a otro tren o mantenerse en el parque de
-- vagones independientemente de la destrucción del tren original.

-- BILLETES --

CREATE TABLE Billete (
    localizador      VARCHAR2(10) CONSTRAINT pk_billete PRIMARY KEY,
    tipo_billete     VARCHAR2(15) CONSTRAINT nn_billete_tipo NOT NULL,
    f_compra         DATE DEFAULT SYSDATE CONSTRAINT nn_billete_fcompra NOT NULL,
    precio           NUMBER(6,2) CONSTRAINT chk_billete_precio CHECK (precio >= 0),
    asiento          VARCHAR2(10),
    cod_estacion_taq VARCHAR2(10) CONSTRAINT nn_billete_est NOT NULL,
    num_taquilla     NUMBER(3)    CONSTRAINT nn_billete_taq NOT NULL,
    dni_pasajero     VARCHAR2(9)  CONSTRAINT nn_billete_pas NOT NULL,
    CONSTRAINT chk_billete_tipo CHECK (tipo_billete IN ('Clasico', 'Especial')),
    CONSTRAINT uq_billete_loc_tipo UNIQUE (localizador, tipo_billete),
    CONSTRAINT fk_billete_taquilla FOREIGN KEY (cod_estacion_taq, num_taquilla) REFERENCES Taquilla(cod_estacion, num_taquilla),
    CONSTRAINT fk_billete_pasajero FOREIGN KEY (dni_pasajero) REFERENCES Pasajero(dni)
);
-- Sin ON DELETE CASCADE en fk_billete_pasajero: el billete es un registro
-- histórico de compra y no debe desaparecer al borrar al pasajero
-- (Oracle rechazará el borrado mientras tenga billetes).
-- Sin ON DELETE CASCADE en fk_billete_taquilla: la venta debe conservarse
-- aunque se modifique o elimine la taquilla.

CREATE TABLE Billete_Clasico (
    localizador  VARCHAR2(10) CONSTRAINT pk_billete_cla PRIMARY KEY,
    tipo_billete VARCHAR2(15) DEFAULT 'Clasico' CONSTRAINT nn_billetecla_tipo NOT NULL,
    -- atributos propios de billete clásico (si los hay)
    CONSTRAINT chk_billetecla_tipo CHECK (tipo_billete = 'Clasico'),
    CONSTRAINT fk_billetecla_billete FOREIGN KEY (localizador, tipo_billete) REFERENCES Billete(localizador, tipo_billete) ON DELETE CASCADE
);
-- ON DELETE CASCADE: participación total y dependencia de existencia.
-- Un billete clásico no puede existir sin su fila en Billete, así que al
-- borrar el billete se borra también su extensión.

CREATE TABLE Billete_Especial (
    localizador    VARCHAR2(10) CONSTRAINT pk_billete_esp PRIMARY KEY,
    tipo_billete   VARCHAR2(15) DEFAULT 'Especial' CONSTRAINT nn_billeteesp_tipo NOT NULL,
    porcentaje_dto NUMBER(5,2) CONSTRAINT chk_billete_dto CHECK (porcentaje_dto BETWEEN 1 AND 100),
    motivo_dto     VARCHAR2(255),
    CONSTRAINT chk_billeteesp_tipo CHECK (tipo_billete = 'Especial'),
    CONSTRAINT fk_billeteesp_billete FOREIGN KEY (localizador, tipo_billete) REFERENCES Billete(localizador, tipo_billete) ON DELETE CASCADE
);
-- ON DELETE CASCADE: igual que en Billete_Clasico, la fila de
-- Billete_Especial depende de la de Billete y no tiene sentido sin ella.

-- RELACIÓN TERNARIA --

CREATE TABLE Instalacion (
    dni_tecnico VARCHAR2(9),
    cod_pieza VARCHAR2(10),
    num_serie_tren VARCHAR2(15),
    fecha_instalacion DATE,
    CONSTRAINT pk_instalacion PRIMARY KEY (dni_tecnico, cod_pieza, num_serie_tren, fecha_instalacion),
    CONSTRAINT fk_inst_tecnico FOREIGN KEY (dni_tecnico) REFERENCES Tecnico(dni),
    CONSTRAINT fk_inst_pieza FOREIGN KEY (cod_pieza) REFERENCES Pieza(cod_pieza),
    CONSTRAINT fk_inst_tren FOREIGN KEY (num_serie_tren) REFERENCES Tren(num_serie)
);

-- AGREGACIÓN VIAJE (TREN + RUTA) --

CREATE TABLE Viaje (
    num_serie_tren VARCHAR2(15),
    cod_ruta VARCHAR2(10),
    fecha_salida DATE,
    fecha_llegada DATE,
    -- Generamos la duración en días mediante una columna virtual si es Oracle reciente o con trigger.
    -- En Oracle podemos usar GENERATED ALWAYS AS
    duracion NUMBER GENERATED ALWAYS AS (fecha_llegada - fecha_salida) VIRTUAL,
    dni_maquinista VARCHAR2(9) CONSTRAINT nn_viaje_maq NOT NULL,
    CONSTRAINT pk_viaje PRIMARY KEY (num_serie_tren, cod_ruta, fecha_salida),
    CONSTRAINT chk_viaje_fechas CHECK (fecha_llegada >= fecha_salida),
    CONSTRAINT fk_viaje_tren FOREIGN KEY (num_serie_tren) REFERENCES Tren(num_serie),
    CONSTRAINT fk_viaje_ruta FOREIGN KEY (cod_ruta) REFERENCES Ruta(cod_ruta),
    CONSTRAINT fk_viaje_maquinista FOREIGN KEY (dni_maquinista) REFERENCES Maquinista(dni)
); -- Sin ON DELETE CASCADE: Viaje es un registro de viaje programado.
-- Si se elimina un tren, los viajes asociados podrían maintense o borrarse
-- según la política de negocio; aquí se conserva el historial de viajes aunque
-- el tren ya no exista en el parque activo.

CREATE TABLE Revisor_Viaje (
    dni_revisor VARCHAR2(9),
    num_serie_tren VARCHAR2(15),
    cod_ruta VARCHAR2(10),
    fecha_salida DATE,
    incidencias NUMBER(3) DEFAULT 0 CONSTRAINT chk_revviaje_inc CHECK (incidencias >= 0),
    CONSTRAINT pk_revisor_viaje PRIMARY KEY (dni_revisor, num_serie_tren, cod_ruta, fecha_salida),
    CONSTRAINT fk_revviaje_revisor FOREIGN KEY (dni_revisor) REFERENCES Revisor(dni) ON DELETE CASCADE,
    -- El ON DELETE CASCADE en fk_revviaje_revisor procede porque un revisor
    -- asignado a un viaje concreto, cuando es dado de baja, sus registros
    -- de participación en viajes deben desaparecer para evitar asignaciones
    -- de personal inexistente. El comentario anterior se refiere a que la
    -- existencia del viaje en sí no depende del revisor.
    -- No hay delete on cascade porque un viaje es un registro de hechos ocurridos, no una parte de un tren o de una ruta. Que la PK incluya num_serie_tren y 
    --cod_ruta no implica que deba borrarse con ellos.
    CONSTRAINT fk_revviaje_viaje FOREIGN KEY (num_serie_tren, cod_ruta, fecha_salida) REFERENCES Viaje(num_serie_tren, cod_ruta, fecha_salida) ON DELETE CASCADE
); -- ON DELETE CASCADE en fk_revviaje_viaje: el registro de participación
-- de un revisor en un viaje concreto se elimina cuando el viaje se da de baja,
-- ya que ese registro de asignación pierde sentido sin el viaje padre. Es
-- distinto de la FK del revisor individual (anterior), que depende de la persona.

CREATE TABLE Pasajero_Viaje (
    dni_pasajero VARCHAR2(9),
    num_serie_tren VARCHAR2(15),
    cod_ruta VARCHAR2(10),
    fecha_salida DATE,
    CONSTRAINT pk_pasajero_viaje PRIMARY KEY (dni_pasajero, num_serie_tren, cod_ruta, fecha_salida),
    CONSTRAINT fk_pasviaje_pasajero FOREIGN KEY (dni_pasajero) REFERENCES Pasajero(dni) ON DELETE CASCADE,
    CONSTRAINT fk_pasviaje_viaje FOREIGN KEY (num_serie_tren, cod_ruta, fecha_salida) REFERENCES Viaje(num_serie_tren, cod_ruta, fecha_salida) ON DELETE CASCADE
); -- ON DELETE CASCADE en fk_pasviaje_pasajero: si un pasajero se da de
-- baja del sistema, sus historiales de viaje también deben eliminirse para
-- mantener la coherencia del registro de movilidad del usuario.
-- ON DELETE CASCADE en fk_pasviaje_viaje: el registro de asistencia de un
-- pasajero a un viaje concreto desaparece cuando el viaje se cancela, ya que
-- no tiene sentido registrar la presencia en un viaje inexistente.

-- ==============================================================================
-- 3. CREACIÓN DE VISTAS OBLIGATORIAS
-- ==============================================================================

-- Vista 1: NO ACTUALIZABLE (contiene JOIN de varias tablas)
-- Finalidad: Muestra los viajes programados junto con la información del maquinista asignado 
-- y el tren utilizado, útil para paneles de información en la estación.
-- Al utilizar múltiples tablas (JOIN), y especialmente columnas derivadas (duracion), la vista 
-- es inherentemente no actualizable para ciertas columnas según las reglas de Oracle.
CREATE OR REPLACE VIEW VISTA_VIAJES_COMPLETOS AS
SELECT 
    v.num_serie_tren,
    t.modelo AS modelo_tren,
    v.cod_ruta,
    r.lugar_inicio,
    r.lugar_fin,
    v.fecha_salida,
    v.duracion,
    m.nombre AS nombre_maquinista
FROM Viaje v
JOIN Tren t ON v.num_serie_tren = t.num_serie
JOIN Ruta r ON v.cod_ruta = r.cod_ruta
JOIN Empleado m ON v.dni_maquinista = m.dni; -- Vista de solo lectura que combina información
-- desnormalizada para paneles de estación. No es updatable debido a la combinación
-- de múltiples tablas y la columna virtual duracion.

-- Vista 2: ACTUALIZABLE (basada en una sola tabla sin agrupaciones)
-- Finalidad: Modificar y consultar los datos de contacto y datos básicos del pasajero por atención al cliente.
-- Solo incluye atributos de una tabla, lo que asegura que cumpla las reglas para ser updatable.
CREATE OR REPLACE VIEW VISTA_PASAJEROS_BASICO AS
SELECT dni, nombre, correo, edad
FROM Pasajero; -- Vista updatable sobre una sola tabla simple, cumple las condiciones
-- de actualización de Oracle al no contener JOINs ni columnas derivadas.

-- ==============================================================================
-- 4. COMPROBACIONES, INSERCIONES Y PRUEBAS
-- ==============================================================================

-- Inserciones básicas de datos maestros para pruebas
INSERT INTO Estacion (cod_estacion, nombre, calle, numero, ciudad, cp, num_vias, telefono) 
VALUES ('EST-01', 'Atocha', 'Plaza del Emperador', '1', 'Madrid', '28045', 15, '912320320');

INSERT INTO Almacen (cod_alm, telefono, max_trenes, ciudad) 
VALUES ('ALM-01', '912334455', 5, 'Madrid');

INSERT INTO Anden (cod_estacion, num_anden, longitud) 
VALUES ('EST-01', 1, 300);

INSERT INTO Taquilla (cod_estacion, num_taquilla, estado, turno) 
VALUES ('EST-01', 1, 'Abierta', 'Mañana');

INSERT INTO Pasajero (dni, nombre, correo, edad) 
VALUES ('12345678A', 'Juan Perez', 'juan@email.com', 35);

INSERT INTO Empleado (dni, nss, nombre, f_nac, telefono1) 
VALUES ('87654321B', 'SS-123456789', 'Carlos Maquinista', TO_DATE('1980-01-01', 'YYYY-MM-DD'), '600111222');

INSERT INTO Maquinista (dni, horas_conduccion) VALUES ('87654321B', 1200);

INSERT INTO Tren (num_serie, modelo, potencia, num_max_vagones, cod_alm, destino_cod_estacion, destino_num_anden) 
VALUES ('TRN-100', 'AVE S-103', 8800, 10, 'ALM-01', 'EST-01', 1);

INSERT INTO Ruta (cod_ruta, lugar_inicio, lugar_fin, distancia) 
VALUES ('RUT-01', 'Madrid', 'Barcelona', 600.5);

COMMIT;

-- COMPROBACIÓN DE VISTA ACTUALIZABLE (Con Rollback)
BEGIN
    INSERT INTO VISTA_PASAJEROS_BASICO (dni, nombre, correo, edad) 
    VALUES ('11111111H', 'Pasajero Prueba', 'prueba@email.com', 25);
    
    UPDATE VISTA_PASAJEROS_BASICO SET edad = 26 WHERE dni = '11111111H';
    
    -- Revertimos para confirmar que solo era una comprobación
    ROLLBACK;
END;
/

SET SERVEROUTPUT ON
DECLARE
    -- Sentencia que DEBE fallar con un código ORA concreto
    PROCEDURE esperar_error(p_desc VARCHAR2, p_sql VARCHAR2, p_codigo NUMBER) IS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || p_desc || ' (debería haber fallado).');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE = p_codigo THEN
            DBMS_OUTPUT.PUT_LINE('OK: ' || p_desc || ' rechazado (ORA-' || LPAD(ABS(p_codigo), 5, '0') || ').');
        ELSE
            DBMS_OUTPUT.PUT_LINE('ERROR: ' || p_desc || ' falló por otra causa: ' || SQLERRM);
        END IF;
    END;

    -- Sentencia que DEBE funcionar
    PROCEDURE esperar_ok(p_desc VARCHAR2, p_sql VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
        DBMS_OUTPUT.PUT_LINE('OK: ' || p_desc);
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || p_desc || ' - ' || SQLERRM);
    END;
BEGIN
    -- ===== BILLETE =====
    esperar_ok('Billete Clasico válido',
        q'[INSERT INTO Billete (localizador, tipo_billete, f_compra, precio, asiento, cod_estacion_taq, num_taquilla, dni_pasajero)
           VALUES ('LOC-00', 'Clasico', SYSDATE, 50, '1A', 'EST-01', 1, '12345678A')]');

    esperar_ok('Billete_Clasico sobre un billete Clasico', -- NUEVO
        q'[INSERT INTO Billete_Clasico (localizador)
           VALUES ('LOC-00')]');

    esperar_error('CHECK precio negativo en Billete',
        q'[INSERT INTO Billete (localizador, tipo_billete, f_compra, precio, asiento, cod_estacion_taq, num_taquilla, dni_pasajero)
           VALUES ('LOC-01', 'Clasico', SYSDATE, -10, '1B', 'EST-01', 1, '12345678A')]', -2290);

    esperar_error('CHECK tipo_billete inválido en Billete', -- NUEVO
        q'[INSERT INTO Billete (localizador, tipo_billete, f_compra, precio, asiento, cod_estacion_taq, num_taquilla, dni_pasajero)
           VALUES ('LOC-03', 'Otro', SYSDATE, 30, '3A', 'EST-01', 1, '12345678A')]', -2290);

    esperar_error('NOT NULL tipo_billete en Billete (participación total)', -- NUEVO
        q'[INSERT INTO Billete (localizador, tipo_billete, f_compra, precio, asiento, cod_estacion_taq, num_taquilla, dni_pasajero)
           VALUES ('LOC-04', NULL, SYSDATE, 30, '4A', 'EST-01', 1, '12345678A')]', -1400);

    esperar_error('Billete_Especial sobre un billete Clasico (exclusión)',
        q'[INSERT INTO Billete_Especial (localizador, porcentaje_dto, motivo_dto)
           VALUES ('LOC-00', 20, 'Familia numerosa')]', -2291);

    esperar_ok('Billete Especial válido',
        q'[INSERT INTO Billete (localizador, tipo_billete, f_compra, precio, asiento, cod_estacion_taq, num_taquilla, dni_pasajero)
           VALUES ('LOC-02', 'Especial', SYSDATE, 40, '2A', 'EST-01', 1, '12345678A')]');

    esperar_ok('Billete_Especial sobre un billete Especial',
        q'[INSERT INTO Billete_Especial (localizador, porcentaje_dto, motivo_dto)
           VALUES ('LOC-02', 20, 'Familia numerosa')]');

    esperar_error('Billete_Clasico sobre un billete Especial (exclusión)', -- NUEVO
        q'[INSERT INTO Billete_Clasico (localizador)
           VALUES ('LOC-02')]', -2291);

    esperar_error('Cambiar a Clasico un billete que ya tiene datos de descuento',
        q'[UPDATE Billete SET tipo_billete = 'Clasico' WHERE localizador = 'LOC-02']', -2292);

    esperar_ok('ON DELETE CASCADE: borrar Billete borra Billete_Especial', -- NUEVO
        q'[DELETE FROM Billete WHERE localizador = 'LOC-02']');

    -- ===== PASAJERO / TREN =====
    esperar_error('UNIQUE correo duplicado en Pasajero',
        q'[INSERT INTO Pasajero (dni, nombre, correo, edad)
           VALUES ('99999999Z', 'Ana', 'juan@email.com', 28)]', -1);

    esperar_error('NOT NULL destino en Tren',
        q'[INSERT INTO Tren (num_serie, modelo, num_max_vagones, cod_alm, destino_cod_estacion, destino_num_anden)
           VALUES ('TRN-200', 'Talgo', 5, 'ALM-01', NULL, NULL)]', -1400);

    -- ===== VIAJE =====
    esperar_ok('Viaje válido (fechas lógicas)',
        q'[INSERT INTO Viaje (num_serie_tren, cod_ruta, fecha_salida, fecha_llegada, dni_maquinista)
           VALUES ('TRN-100', 'RUT-01', TO_DATE('2026-10-10 08:00','YYYY-MM-DD HH24:MI'),
                   TO_DATE('2026-10-10 14:00','YYYY-MM-DD HH24:MI'), '87654321B')]');

    esperar_error('CHECK fecha_llegada < fecha_salida en Viaje',
        q'[INSERT INTO Viaje (num_serie_tren, cod_ruta, fecha_salida, fecha_llegada, dni_maquinista)
           VALUES ('TRN-100', 'RUT-01', TO_DATE('2026-10-11 14:00','YYYY-MM-DD HH24:MI'),
                   TO_DATE('2026-10-11 08:00','YYYY-MM-DD HH24:MI'), '87654321B')]', -2290);

    esperar_error('Borrar un Tren con viajes (sin ON DELETE CASCADE)',
        q'[DELETE FROM Tren WHERE num_serie = 'TRN-100']', -2292);

    -- ===== VAGON =====
    esperar_ok('Vagon 2 (último, sin siguiente)',
        q'[INSERT INTO Vagon (num_serie_tren, num_vagon, tipo_vagon, capacidad, vagon_sig_num)
           VALUES ('TRN-100', 2, 'Pasajeros', 80, NULL)]');

    esperar_ok('Vagon 1 con siguiente = 2',
        q'[INSERT INTO Vagon (num_serie_tren, num_vagon, tipo_vagon, capacidad, vagon_sig_num)
           VALUES ('TRN-100', 1, 'Pasajeros', 80, 2)]');

    esperar_error('Vagon siguiente de sí mismo',
        q'[INSERT INTO Vagon (num_serie_tren, num_vagon, tipo_vagon, capacidad, vagon_sig_num)
           VALUES ('TRN-100', 3, 'Pasajeros', 80, 3)]', -2290);

    esperar_error('Vagon con siguiente inexistente',
        q'[INSERT INTO Vagon (num_serie_tren, num_vagon, tipo_vagon, capacidad, vagon_sig_num)
           VALUES ('TRN-100', 4, 'Pasajeros', 80, 99)]', -2291);
END;
/
COMMIT;