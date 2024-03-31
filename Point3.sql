-- oracle 19c

DROP TABLE casahija;
DROP TABLE casamatriz;
CREATE TABLE casamatriz(
    id NUMBER(8) PRIMARY KEY,
    capitalp NUMBER(8) NOT NULL CHECK(capitalp > 0)
);

CREATE TABLE casahija(
    id NUMBER(8) PRIMARY KEY,
    capitalh NUMBER(8) NOT NULL CHECK(capitalh > 0),
    casapadre NUMBER(8) NOT NULL REFERENCES casamatriz
);

-- punto 3.1 ----------------------------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER punto3_1
BEFORE INSERT ON casahija
FOR EACH ROW
DECLARE
    suma_capitalh NUMBER; -- no se sabe que tan grande pueda llegar a ser la suma, por lo que se usa NUMBER
    capital_padre NUMBER(8);
BEGIN
    -- el valor retornado no puede ser nulo , ya que capitalh y casapadre no pueden ser nulos
    SELECT SUM(ch.capitalh) INTO suma_capitalh FROM casahija ch WHERE ch.casapadre = :NEW.casapadre;

    SELECT c.capitalp INTO capital_padre FROM casamatriz c WHERE c.id = :NEW.casapadre;

    -- si la suma de los capitales de las casas hijas (mas el nuevo registro) supera el capital de la casa matriz
    IF (suma_capitalh + :NEW.capitalh) > capital_padre THEN
        RAISE_APPLICATION_ERROR(-20000, 'La suma de los capitales de las casas hijas no puede superar el capital de la casa matriz');
    END IF;

END;
----------------------------------------------------------------------------------------------------------------

-- punto 3.2 ---------------------------------------------------------------------------------------------------
-- en la version web de oracle no funcionaba la clausula WHEN, por lo que se uso un IF
CREATE OR REPLACE TRIGGER punto3_2
BEFORE UPDATE OF capitalp ON casamatriz
FOR EACH ROW
--WHEN (NEW.capitalp < OLD.capitalp)
DECLARE
    num_hijas NUMBER;
    suma_capitalh NUMBER;
BEGIN
    IF :NEW.capitalp < :OLD.capitalp THEN
        SELECT COUNT(*) INTO num_hijas FROM casahija WHERE casapadre = :OLD.id;
        SELECT NVL(SUM(capitalh), 0) INTO suma_capitalh FROM casahija WHERE casapadre = :OLD.id; -- si la casa matriz no tiene hijas, la suma es 0

        -- si la casa matriz tiene al menos 1 hija y el nuevo capital es menor a la suma de los capitales de las hijas
        IF num_hijas > 0 AND :NEW.capitalp < suma_capitalh THEN
            RAISE_APPLICATION_ERROR(-20000, 'No se puede reducir el capital de la casa matriz si la suma de los capitales de las casas hijas es mayor');
        END IF;
    END IF;
END;
---------------------------------------------------------------------------------------------------------------

-- tabla para controlar la suma de los capitales de las casas hijas y el numero de hijas de una casa matriz
CREATE TABLE control_casamatriz(
    id_casamatriz NUMBER(8) PRIMARY KEY,
    suma_capitalh NUMBER NOT NULL,  -- suma total de los capitales de las casas hijas
    num_hijas NUMBER NOT NULL,      -- numero de casas hijas
    CONSTRAINT fk_control_casamatriz FOREIGN KEY (id_casamatriz) REFERENCES casamatriz
);

-- trigger para inicializar valores de control_casamatriz
CREATE OR REPLACE TRIGGER registrar_control_casamatriz
AFTER INSERT ON casamatriz
FOR EACH ROW
BEGIN
    INSERT INTO control_casamatriz VALUES(:NEW.id, 0, 0);
END;

-- punto 3.3 -------------------------------------------------------------------------------------------------

-- trigger para actualizar los valores de control_casamatriz
CREATE OR REPLACE TRIGGER actualizar_control_casamatriz
BEFORE INSERT OR DELETE OR UPDATE OF capitalh ON casahija
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        UPDATE control_casamatriz SET suma_capitalh = suma_capitalh + :NEW.capitalh, num_hijas = num_hijas + 1 WHERE id_casamatriz = :NEW.casapadre;
    ELSIF DELETING THEN
        UPDATE control_casamatriz SET suma_capitalh = suma_capitalh - :OLD.capitalh, num_hijas = num_hijas - 1 WHERE id_casamatriz = :OLD.casapadre;
    ELSIF UPDATING THEN
        UPDATE control_casamatriz SET suma_capitalh = suma_capitalh - :OLD.capitalh + :NEW.capitalh WHERE id_casamatriz = :NEW.casapadre;
    END IF;
END;

-- en la version web de oracle no funcionaba la clausula WHEN, por lo que se uso un IF
CREATE OR REPLACE TRIGGER punto3_3
BEFORE UPDATE OF capitalh ON casahija
FOR EACH ROW
FOLLOWS actualizar_control_casamatriz
-- WHEN (NEW.capitalh > OLD.capitalh)
DECLARE
    suma_capitalh NUMBER;
    capitalp_casapadre casamatriz.capitalp%TYPE;
BEGIN
    IF (:NEW.capitalh > :OLD.capitalh) THEN
        SELECT ccm.suma_capitalh INTO suma_capitalh FROM control_casamatriz ccm WHERE ccm.id_casamatriz = :NEW.casapadre;
        SELECT c.capitalp INTO capitalp_casapadre FROM casamatriz c WHERE c.id = :NEW.casapadre;

        -- si la suma de los capitales de las casas hijas es mayor al capital de la casa matriz
        IF suma_capitalh >= capitalp_casapadre THEN
            UPDATE control_casamatriz SET suma_capitalh = suma_capitalh - :NEW.capitalh + :OLD.capitalh WHERE id_casamatriz = :NEW.casapadre;
            RAISE_APPLICATION_ERROR(-20000, 'No se puede actualizar el capital de la casa hija si la suma de los capitales de las casas hijas es mayor al capital de la casa matriz');
        END IF;
    END IF;
END;
---------------------------------------------------------------------------------------------------------------

-- punto 3.4 ---------------------------------------------------------------------------------------------------

-- controlar que una casamatriz pueda tener maximo 5 casas hijas
CREATE OR REPLACE TRIGGER punto3_4_p1
BEFORE INSERT ON casahija
FOR EACH ROW
DECLARE
    num_hijas NUMBER;
BEGIN
    -- numero de hijas + 1 de la casa matriz
    SELECT (ccm.num_hijas + 1) INTO num_hijas FROM control_casamatriz ccm WHERE ccm.id_casamatriz = :NEW.casapadre;
    IF num_hijas > 5 THEN
        RAISE_APPLICATION_ERROR(-20000, 'No se puede agregar mas de 5 casas hijas a una casa matriz');
    END IF;
END;

-- controlar que una casahija no se pueda cambiar de casa matriz
CREATE OR REPLACE TRIGGER punto3_4_p2
BEFORE UPDATE OF casapadre ON casahija
FOR EACH ROW
BEGIN
    IF :NEW.casapadre != :OLD.casapadre THEN
        RAISE_APPLICATION_ERROR(-20000, 'No se puede cambiar la casa matriz de una casa hija');
    END IF;
END;

----------------------------------------------------------------------------------------------------------------


INSERT INTO casamatriz VALUES(1, 1000);
INSERT INTO casamatriz VALUES(2, 2000);
INSERT INTO casamatriz VALUES(3, 1000);


INSERT INTO casahija VALUES(1, 300, 1);
INSERT INTO casahija VALUES(2, 300, 1);
INSERT INTO casahija VALUES(3, 350, 1);
INSERT INTO casahija VALUES(4, 400, 2);
INSERT INTO casahija VALUES(5, 1500, 2);