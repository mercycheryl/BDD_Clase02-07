
-- CREACIÓN DE BASE DE DATOS
CREATE DATABASE IF NOT EXISTS turnos_medicos;
USE turnos_medicos;

-- TABLAS PRINCIPALES
CREATE TABLE especialidades (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);

CREATE TABLE medicos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100),
    especialidad_id INT,
    FOREIGN KEY (especialidad_id) REFERENCES especialidades(id)
);

CREATE TABLE pacientes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100),
    cedula VARCHAR(20),
    fecha_nacimiento DATE
);

CREATE TABLE turnos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    paciente_id INT,
    medico_id INT,
    fecha DATE,
    hora TIME,
    estado VARCHAR(20) DEFAULT 'pendiente',
    FOREIGN KEY (paciente_id) REFERENCES pacientes(id),
    FOREIGN KEY (medico_id) REFERENCES medicos(id)
);

CREATE TABLE log_turnos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    turno_id INT,
    accion VARCHAR(50),
    fecha_log DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE auditoria_pacientes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    paciente_id INT,
    fecha_auditoria DATETIME DEFAULT CURRENT_TIMESTAMP,
    descripcion TEXT
);

USE turnos_medicos;
INSERT INTO especialidades (nombre) VALUES
('Pediatría'), ('Cardiología'), ('Dermatología'), ('Neurología');

-- REGISTROS PARA MÉDICOS
INSERT INTO medicos (nombre, especialidad_id) VALUES
('Dra. Ana Torres', 1),
('Dr. Luis Pérez', 2),
('Dra. Carla Gómez', 3),
('Dr. Jorge Lima', 4);

-- REGISTROS PARA PACIENTES
INSERT INTO pacientes (nombre, cedula, fecha_nacimiento) VALUES
('María López', '1102233445', '1990-04-15'),
('Pedro González', '1103344556', '1985-06-20'),
('Lucía Martínez', '1104455667', '2002-09-10'),
('Carlos Herrera', '1105566778', '1978-12-05');

-- REGISTROS PARA TURNOS
INSERT INTO turnos (paciente_id, medico_id, fecha, hora) VALUES
(1, 1, CURDATE(), '10:00:00'),
(2, 2, CURDATE(), '11:00:00'),
(3, 3, CURDATE(), '12:00:00'),
(4, 4, CURDATE() + INTERVAL 1 DAY, '09:30:00');






-- FUNCIONES
DELIMITER //
CREATE FUNCTION obtener_edad(fecha_nac DATE)
RETURNS INT
DETERMINISTIC
BEGIN
    RETURN TIMESTAMPDIFF(YEAR, fecha_nac, CURDATE());
END;
//

CREATE FUNCTION total_turnos_paciente(p_id INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE total INT;
    SELECT COUNT(*) INTO total FROM turnos WHERE paciente_id = p_id;
    RETURN total;
END;
//

CREATE FUNCTION nombre_medico(m_id INT)
RETURNS VARCHAR(100)
DETERMINISTIC
BEGIN
    DECLARE nombre VARCHAR(100);
    SELECT nombre INTO nombre FROM medicos WHERE id = m_id;
    RETURN nombre;
END;
//

CREATE FUNCTION turnos_por_dia(dia DATE)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE total INT;
    SELECT COUNT(*) INTO total FROM turnos WHERE fecha = dia;
    RETURN total;
END;
//
DELIMITER ;



-- PROCEDIMIENTOS
DELIMITER //
CREATE PROCEDURE registrar_paciente(IN nom VARCHAR(100), IN ced VARCHAR(20), IN fnac DATE)
BEGIN
    INSERT INTO pacientes(nombre, cedula, fecha_nacimiento)
    VALUES (nom, ced, fnac);
END;
//

CREATE PROCEDURE crear_turno(IN p_id INT, IN m_id INT, IN f DATE, IN h TIME)
BEGIN
    INSERT INTO turnos(paciente_id, medico_id, fecha, hora) VALUES (p_id, m_id, f, h);
END;
//

CREATE PROCEDURE cancelar_turno(IN t_id INT)
BEGIN
    DELETE FROM turnos WHERE id = t_id;
END;
//

CREATE PROCEDURE actualizar_estado_turno(IN t_id INT, IN nuevo_estado VARCHAR(20))
BEGIN
    UPDATE turnos SET estado = nuevo_estado WHERE id = t_id;
END;
//
DELIMITER ;

-- TRIGGERS
DELIMITER //
CREATE TRIGGER trg_validar_fecha_turno
BEFORE INSERT ON turnos
FOR EACH ROW
BEGIN
    IF NEW.fecha < CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se pueden agendar turnos en fechas pasadas';
    END IF;
END;
//

CREATE TRIGGER trg_log_cambios_turnos
AFTER UPDATE ON turnos
FOR EACH ROW
BEGIN
    INSERT INTO log_turnos(turno_id, accion) VALUES (OLD.id, 'Actualización');
END;
//


CREATE TRIGGER trg_auditar_paciente_nuevo
AFTER INSERT ON pacientes
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_pacientes(paciente_id, descripcion)
    VALUES (NEW.id, CONCAT('Nuevo paciente registrado: ', NEW.nombre));
END;
//

CREATE TRIGGER trg_auto_estado_turno
AFTER INSERT ON turnos
FOR EACH ROW
BEGIN
    IF NEW.fecha < CURDATE() THEN
        UPDATE turnos SET estado = 'atrasado' WHERE id = NEW.id;
    END IF;
END;
//
DELIMITER ;

-- VISTAS
CREATE VIEW vista_turnos_activos AS
SELECT t.id, p.nombre AS paciente, m.nombre AS medico, t.fecha, t.hora, t.estado
FROM turnos t
JOIN pacientes p ON t.paciente_id = p.id
JOIN medicos m ON t.medico_id = m.id
WHERE t.estado = 'pendiente';

CREATE VIEW vista_detalle_paciente AS
SELECT p.id, p.nombre, obtener_edad(p.fecha_nacimiento) AS edad,
       total_turnos_paciente(p.id) AS total_turnos
FROM pacientes p;

CREATE VIEW vista_disponibilidad_medicos AS
SELECT m.id, m.nombre, e.nombre AS especialidad
FROM medicos m
JOIN especialidades e ON m.especialidad_id = e.id
WHERE m.id NOT IN (
    SELECT medico_id FROM turnos WHERE fecha = CURDATE()
);

CREATE VIEW vista_citas_por_especialidad AS
SELECT e.nombre AS especialidad, COUNT(*) AS total_citas
FROM turnos t
JOIN medicos m ON t.medico_id = m.id
JOIN especialidades e ON m.especialidad_id = e.id
GROUP BY e.nombre;
