-- ADVERTENCIA
-- Antes de crear el procedimiento ejecutar el siguiente codigo para crear la tabla donde se agregaran las ventas

DROP TABLE venta_agg;
CREATE TABLE venta_agg(
    totalpesos NUMBER,
    codproducto NUMBER(5),
    marca VARCHAR2(100),
    tipo VARCHAR2(100)
);
-- Procedimiento almacenado para el punto 2
CREATE OR REPLACE PROCEDURE punto2
(input IN VARCHAR2)
IS
  v_codproducto NUMBER;
  v_totalpesos NUMBER;
  v_marca VARCHAR2(100);
  p_producto NUMBER;
  -- registrado o no
  registrado BOOLEAN;
  -- variable para guardar la cantidad de totalpesos de no registrados
  noreg NUMBER;
  v_tipo VARCHAR2(100);
  valido VARCHAR2(100);
BEGIN
        --Sacamos los valores tipo de la tabla producto para verificar que el input sea valido
    FOR producto IN (SELECT EXTRACTVALUE(p, '/Producto/Tipoprod') AS tipo FROM producto) 
    LOOP
      IF input=producto.tipo THEN
          valido:='El tipo de producto existe';
          DBMS_OUTPUT.PUT_LINE('Informe para ' || input ||' por año y marca:');
        -- Consulta para sacar los años y organizarlos de manera ascendente, luego se itera para sacar los datos por año
          FOR year IN (SELECT DISTINCT EXTRACT(YEAR FROM TO_DATE(JSON_VALUE(jventa, '$.fecha'), 'DD-MM-YYYY')) AS year
                        FROM venta ORDER BY year)
          LOOP
            DBMS_OUTPUT.PUT_LINE(year.year);
            DBMS_OUTPUT.PUT_LINE(RPAD('MARCA', 30) || RPAD('TOTALPESOS', 10));
            -- Aca se hace clear de los datos en tabla agg,se limpia por acada iteración de año
            DELETE FROM venta_agg;
            noreg:=0;
            -- Se itera sobre cada item JSON en la tabla venta para sacar luego los valores individuales 
            FOR rec IN (
              SELECT v.id AS venta_id,
                    jt.*
              FROM venta v,
                  JSON_TABLE(v.jventa, '$.items[*]'
                    COLUMNS (
                      codproducto NUMBER PATH '$.codproducto',
                      totalpesos NUMBER PATH '$.totalpesos'
                    )
                  ) jt
                  --se filtra según el año en el que se esta iterando
                  WHERE EXTRACT(YEAR FROM TO_DATE(JSON_VALUE(v.jventa, '$.fecha'), 'DD-MM-YYYY')) = year.year)
              LOOP
                --Sacamos los valores de marca y tipo de la tabla producto
                FOR producto IN (SELECT EXTRACTVALUE(p, '/Producto/@plNro') AS codprod,
                EXTRACTVALUE(p, '/Producto/Marca') AS marca,
          EXTRACTVALUE(p, '/Producto/Tipoprod') AS tipo
                FROM producto) LOOP
                  --se verifica para cada valor de XML que el codproducto de ventas se encuentre en la tabla producto
                  registrado := false;
            IF rec.codproducto = producto.codprod THEN
                    --En caso de que se encuentre match entre codproducto ventas y codproducto de producto pasamos a asignarle el valor de marca y tipo a las variables
                    registrado := true;
                    v_marca := producto.marca;
                    v_tipo := producto.tipo;
                  END IF;
                    --Una vez se compruebe que hubo algún match con algun producto nos salimos del loop
                    EXIT WHEN registrado = true;
                  IF registrado = false THEN
                    --En caso de que no haya ni un solo match cuando termine de iterar los valores de las variables seran seteados aca
                    v_marca := 'Sin registrar';
                    v_tipo := 'Sin tipo';
                  END IF; 	
          END LOOP;
              --Se actualizara la tabla auxiliar venta_agg cuando se encuentre un registro con el mismo codproducto y se sumaran su totalpesos
              UPDATE venta_agg
              SET totalpesos = totalpesos + rec.totalpesos
              WHERE codproducto = rec.codproducto;

              -- en caso que no haya un registro asociado con algun codproducto se procede a insertar estos datos en la tabla auxiliar
              IF SQL%NOTFOUND THEN
                  INSERT INTO venta_agg (codproducto, totalpesos,marca,tipo)
                    VALUES (rec.codproducto, rec.totalpesos,v_marca,v_tipo);
              END IF;
            END LOOP;
            --Ahora vamos a iterar sobre los valores de la tabla auxiliar
            FOR rec_agg IN (SELECT marca, totalpesos,tipo FROM venta_agg)
            LOOP
                --En caso que el valor coincida con el filtro especificado en input o que no este registrada en la tabla producto
                IF rec_agg.tipo = input OR rec_agg.tipo = 'Sin tipo' THEN 
                  --En el caso que sea un sin registrar se suma al contador
                  IF rec_agg.marca = 'Sin registrar' THEN
                    noreg := noreg+rec_agg.totalpesos;
                  ELSE
                    --En caso que no imprimimos los valores de la marca y total pesos finales asociados
                    DBMS_OUTPUT.PUT_LINE(rec_agg.marca || '                  ' || rec_agg.totalpesos);
                  END IF;
                END IF;
            END LOOP;
            DBMS_OUTPUT.PUT_LINE('Total de los productos no registrados en la tabla producto:  ' || noreg);
          END LOOP;--Final del loop por año
          EXIT WHEN valido='El tipo de producto existe';
          DBMS_OUTPUT.PUT_LINE(valido);
      ELSE
        valido := 'No existe';
      END IF;
    END LOOP;--Final del loop para verificar input correcto
    DBMS_OUTPUT.PUT_LINE(valido);
END;
