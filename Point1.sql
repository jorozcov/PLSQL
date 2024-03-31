-- ADVERTENCIA
-- Antes de crear el procedimiento ejecutar el siguiente codigo para crear la tabla auxiliar

DROP TABLE auxiliarp1;
CREATE TABLE auxiliarp1(
    totalpesos NUMBER,
    estrato VARCHAR2(100),
    genero VARCHAR2(100)
);

-- Procedimiento almacenado para el punto 1
CREATE OR REPLACE PROCEDURE punto1
(mes IN NUMBER, anio IN NUMBER)
IS
    -- tabla auxiliar de regsitros sin orden, solo importa que se agrupen por estrato y genero
    TYPE t_record IS RECORD (
    totalpesos NUMBER,
    estrato VARCHAR2(100),
    genero VARCHAR2(100)
    );
    TYPE t_table IS TABLE OF t_record INDEX BY VARCHAR2(200); -- indexado por clave que es estrato + genero
    v_table t_table;
    clave VARCHAR2(200);
    v_index VARCHAR2(200);

    -- registrado o no 
    registrado BOOLEAN;

BEGIN 

    FOR vent IN (SELECT JSON_VALUE(v.jventa, '$.codcliente') AS codcliente, SUM(totalpesos) AS totalpesos
               FROM venta v, 
               JSON_TABLE(v.jventa, '$.items[*]' COLUMNS (totalpesos NUMBER PATH '$.totalpesos')) j
               WHERE EXTRACT(MONTH FROM TO_DATE(JSON_VALUE(v.jventa, '$.fecha'), 'DD-MM-YYYY')) = mes -- mes
               AND EXTRACT(YEAR FROM TO_DATE(JSON_VALUE(v.jventa, '$.fecha'), 'DD-MM-YYYY')) = anio -- año
               GROUP BY JSON_VALUE(v.jventa, '$.codcliente')) LOOP

        registrado := false; 

        FOR client IN (SELECT EXTRACTVALUE(c, '/Cliente/@clNro') AS codcliente,
                    EXTRACTVALUE(c, '/Cliente/Estrato') AS estrato,
                    EXTRACTVALUE(c, '/Cliente/Genero') AS genero
                    FROM cliente) LOOP

            IF vent.codcliente = client.codcliente THEN
                clave := client.estrato || TO_CHAR(client.genero);
                registrado := true;

                IF v_table.EXISTS(clave) THEN
                v_table(clave).totalpesos := v_table(clave).totalpesos + vent.totalpesos;
                ELSE
                v_table(clave).totalpesos := vent.totalpesos;
                v_table(clave).estrato := client.estrato;
                v_table(clave).genero := client.genero;
                END IF;
            
                EXIT WHEN registrado = true; -- break cliente registrado
            END IF;
        END LOOP;
	
        -- Clientes no registrados
        IF registrado = false THEN 
        clave := 'Ausente';
            IF v_table.EXISTS(clave) THEN
            v_table(clave).totalpesos := v_table(clave).totalpesos + vent.totalpesos;
            ELSE
            v_table(clave).totalpesos := vent.totalpesos;
            v_table(clave).estrato := 'Ausente';
            v_table(clave).genero := 'Ausente';
            END IF;
        END IF;

    END LOOP;

    -- Llenar tabla auxiliar con los datos
    v_index := v_table.FIRST;
    WHILE v_index IS NOT NULL LOOP
      INSERT INTO auxiliarp1 VALUES (v_table(v_index).totalpesos, v_table(v_index).estrato, v_table(v_index).genero);
      v_index := v_table.NEXT(v_index);
    END LOOP;

    -- Verificar no si hay registro con estrato y genero ausente en auxiliarp1 para agregarlo
    IF NOT v_table.EXISTS('Ausente') THEN
      INSERT INTO auxiliarp1 VALUES (0, 'Ausente', 'Ausente');
    END IF;

   -- Imprimir tabla auxiliarp1 ordenada de forma descendente
    DBMS_OUTPUT.PUT_LINE('Informe para ' || mes || '-' || anio || ':');
    DBMS_OUTPUT.PUT_LINE(RPAD('Totalpesos', 12) || RPAD('Estrato', 10) || 'Genero');
    FOR i IN (SELECT * FROM auxiliarp1 ORDER BY totalpesos DESC) LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(TO_CHAR(i.totalpesos), 12) || RPAD(i.estrato, 10) || i.genero);
    END LOOP;

    -- Borrar registros de auxiliarp1
    DELETE FROM auxiliarp1;
END;