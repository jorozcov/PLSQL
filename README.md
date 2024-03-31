# PLSQL project
Project for the subject Data Bases 2

Team members:
- Juan Carlos Munera Arango
- Juan Nicolas Piedrahita Salas
- Julian Orozco Vanegas

# Problem description

## For point 1 and 2 this description was considered 

There is a table of XML documents that stores data about clients as follows:

```sql
DROP TABLE cliente;
CREATE TABLE cliente(
  id NUMBER(8) PRIMARY KEY,
  c XMLTYPE NOT NULL);

INSERT INTO cliente VALUES 
(1, XMLTYPE('<Cliente clNro="445">  
             <Estrato>5</Estrato>
             <Genero>m</Genero>
             </Cliente>'));

INSERT INTO cliente VALUES 
(2, XMLTYPE('<Cliente clNro="800">  
             <Estrato>88</Estrato>
             <Genero>x</Genero>
             </Cliente>'));
```

**Note:** It is guaranteed that all XML documents of the clients will have this structure and that they have valid values ​​as shown in the previous examples: all numbers are positive integers. The 'gender' column contains any lowercase letter. It is guaranteed that there are no two clients with the same 'clNro'.


Also there is a table of XML documents that stores data about products as follows:

```sql
DROP TABLE producto;
CREATE TABLE producto(
  id NUMBER(8) PRIMARY KEY,
  p XMLTYPE NOT NULL);

INSERT INTO producto VALUES 
(1, XMLTYPE('<Producto plNro="100">  
             <Marca>Micerdito Azul</Marca>
             <Tipoprod>Carnico</Tipoprod>
             </Producto>'));


INSERT INTO producto VALUES 
(4, XMLTYPE('<Producto plNro="111">  
             <Marca>Acme</Marca>
             <Tipoprod>Mueble de Oficina</Tipoprod>
             </Producto>'));
```

**Note:** It is guaranteed that all XML documents of the products will have this structure and that they have valid values ​​as shown in the previous examples: all numbers are positive integers. It is guaranteed that there are no two products with the same 'plNro'.

There is a table of JSON documents that stores sales data as follows:

```sql
DROP TABLE venta;
CREATE TABLE venta(
  id  NUMBER(8) PRIMARY KEY,
  jventa JSON NOT NULL
);
```

Each JSON document represents a sale made to a client. Let's see an example of a sale:

```sql
INSERT INTO venta VALUES (1,
'{
  "codventa": 66,
  "fecha": "29-11-2023",
  "codcliente": 445,
  "items": [
    {
      "codproducto": 100,
      "nrounidades": 3,
      "totalpesos": 75
    },
    {
      "codproducto": 111,
      "nrounidades": 1,
      "totalpesos": 1000
    },
    {
      "codproducto": 100,
      "nrounidades": 1,
      "totalpesos": 26
    }
  ]
}'
);
```

Note that in the same sale, the same product may appear in different cells of the 'items' array (for example, product 100 appears in two cells). Each sale follows the JSON structure shown in the example and has valid values ​​as shown in the example: the 'date' column is handled in this format: dd-mm-yyyy, so the date 05-12-2022 corresponds to December 5, 2022. All numbers are positive integers. The 'items' array of each sale can have any number of cells, minimum one cell. In the example, the array has three cells. Each cell is a JSON document with three columns: 'codproducto', 'nrounidades', and 'totalpesos'.

- There may be sales that in their 'codcliente' column have client codes that do NOT exist in the client table ('clNro'). These are unregistered clients, but sales can be made to them.
- There may be sales that in their 'codproducto' column have product codes that do NOT exist in the product table ('plNro'). These are products not registered in the product table, but are still sold.

Create PL/SQL programs for each of the following points.

### Point 1

The program receives a month and a year as parameters. Example: 02 and 2022 (meaning, February 2022). The program should print the total pesos sold to each stratum and gender corresponding to all sales of that month and year. That is, the following should appear on the screen:

![image](https://github.com/jorozcov/PLSQL/assets/78501518/34fe5436-932c-4848-a37e-98574ab42856)

The report on the screen (i.e., what is in green) should be sorted in descending order by totalpesos and should have an identical structure to the one shown. This way, the user can easily know, for example, which stratum and gender buy the most. The totalpesos corresponding to unregistered clients should appear with stratum "Ausente" and gender "Ausente," as shown in the example. Note: in case there are no unknowns (i.e., when all the clients in the sales are registered), it should appear: 0 Ausente Ausente.

### Point 2

The program receives the name of a product type as a parameter. Example: "Mueble de Oficina". The program should print the total pesos sold for each brand of that product type in each year. The report should be sorted in ascending order by year. In each year, each brand appears with its total pesos. That is, it should appear on the screen like this (assuming the earliest year in the sales table is 2014):

![image](https://github.com/jorozcov/PLSQL/assets/78501518/1a2dff17-0e43-4cc8-a939-c62400e3b9a3)

Note that the last line of each year should include the total pesos corresponding to the products not registered in the product table. If the product type entered as a parameter does not exist, print "No existe".

## For point 3 this description was considered 

There is a table named "casamatriz" as follows:

```sql
DROP TABLE casamatriz;
CREATE TABLE casamatriz(
id NUMBER(8) PRIMARY KEY,
capitalp NUMBER(8) NOT NULL CHECK(capitalp > 0)
);
```

Examples:

```sql
INSERT INTO casamatriz VALUES(1, 1000);
INSERT INTO casamatriz VALUES(2, 2000);
INSERT INTO casamatriz VALUES(3, 1000);
```

There is a table named "casahija" as follows:

```sql
DROP TABLE casahija;
CREATE TABLE casahija(
id NUMBER(8) PRIMARY KEY,
capitalh NUMBER(8) NOT NULL CHECK(capitalh > 0),
casapadre NUMBER(8) NOT NULL REFERENCES casamatriz
);
```

Examples:

```sql
INSERT INTO casahija VALUES(1, 300, 1);
INSERT INTO casahija VALUES(2, 300, 1);
INSERT INTO casahija VALUES(3, 350, 1);
INSERT INTO casahija VALUES(4, 400, 2);
INSERT INTO casahija VALUES(5, 1500, 2);
```

### Point 3

Perform the following triggers

- When inserting a row into "casahija", it must be verified that the sum of the capitals of all daughters of the same matrix house does not exceed the capital of the matrix house. Considering the previous examples, if the following row is to be inserted into "casahija":
  
```sql
  INSERT INTO casahija VALUES(9, 125, 2);
```
The trigger must prevent this insertion because the sum of the daughters of house 2 would be 2025, and matrix house number 2 has only a capital of 2000. Now, if the following row is to be inserted into "casahija":
```sql
INSERT INTO casahija VALUES(11, 80, 2);
```
This insertion is accepted because the sum would be 1980, which is less than 2000.


- When decreasing the capital of a matrix house (i.e., capitalp), it must be ensured that the new capital of the matrix house is greater than or equal to the sum of the capital of its daughters. In the previous examples, if the capital (capitalp) of matrix house 1 is lowered to 990, it is accepted (in the example, the sum of the daughters of house 1 is 950), but if it is lowered to 949, it is rejected.

-  When increasing the capital of a daughter house (i.e., capitalh), it must be controlled that the sum of the capital of the daughters (of the same matrix house) does not exceed the capital of its corresponding matrix house. In the example, if the capital of daughter house number 1 is raised from 300 to 400, it is rejected, but if it is raised, for example, to 349, it is accepted.

-  Additionally, it must be controlled for insertion that the maximum number of daughters that a matrix house can have is 5. Furthermore, for the update, it is not allowed for a daughter house to change its matrix house.

