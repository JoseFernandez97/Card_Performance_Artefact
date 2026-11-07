--------------------------------------------
--DESAFIO ARTEFACT
--Postulante: José Fernández Sánchez - Perú
-------------------------------------------

/*
Tabla	      Campo	        Descripción
db_transac	card_id	        Número único de tarjeta
db_transac	product_name	Nombre del producto (Tarjeta)
db_transac	product_type	Tipo de producto (Crédito, Débito o Prepago)
db_transac	amt	            Monto de la transacción en USD
db_transac	is_xb	        Indicador (flag) que es 1 cuando la transacción es internacional
db_transac	is_contactless	Indicador (flag) que es 1 cuando la transacción fue usando tecnología contactless
db_transac	prch_date	    Fecha de la transacción
db_transac	prch_time	    Hora de la transacción
db_transac	ctry_card	    País de emisión de la tarjeta
db_transac	ctry_mrch	    País donde se realizó la compra (país del comercio)
db_transac	mrch	        Nombre del comercio
db_transac	mcg_id	        Identificador de MCG (Merchant Category Group o Código de Categoría del Comercio)
mcg_list	mcg	            Identificador de MCG (Merchant Category Group o Código de Categoría del Comercio)
mcg_list	mcg_name	    Nombre de la categoría del comercio
-*/

--------------------------------------------------------------------------------------------------------------
--1. CARGA DE DATOS
--------------------------------------------------------------------------------------------------------------
CREATE TABLE DB_TRANSAC AS
SELECT * FROM read_csv_auto('C:\Users\JOSE\Desktop\PRUEBA TECNICA NOV 2026\db_transac.csv') ;

CREATE TABLE MCG_LIST AS
SELECT * FROM read_xlsx('C:\Users\JOSE\Desktop\PRUEBA TECNICA NOV 2026\mcg_list.xlsx');

SELECT * FROM DB_TRANSAC LIMIT 9;
SELECT * FROM MCG_LIST;

-----------------------------------------------------------------------------------------------------------
--2. LIMPIEZA DE DATOS
----------------------------------------------------------------------------------------------------------
CREATE TABLE DB_CARDS AS
SELECT 
CARD_ID,
PRODUCT_NAME,
CASE lower(strip_accents(replace(TRIM(A.PRODUCT_TYPE), ' ', '')))
        WHEN 'credit'  THEN 'Credit'
        WHEN 'credito' THEN 'Credit'
        WHEN 'debit'   THEN 'Debit'
        WHEN 'debito'  THEN 'Debit'
    END PRODUCT_TYPE,
AMT ,
A.IS_XB ,
A.IS_CONTACTLESS ,
CAST(try_strptime(replace(TRIM(A.PRCH_TIME), '.', ':'), '%H:%M:%S') AS TIME) AS HORA_TRX,
CAST(year(COALESCE(try_strptime(TRIM(A.PRCH_DATE), '%d/%m/%Y'),
                       try_strptime(TRIM(A.PRCH_DATE), '%d-%m-%Y'))) AS SMALLINT) AS ANIO,
'T' ||CAST(quarter(COALESCE(try_strptime(TRIM(A.PRCH_DATE), '%d/%m/%Y'),
                          try_strptime(TRIM(A.PRCH_DATE), '%d-%m-%Y'))) AS TINYINT) AS QUARTER,
CAST(COALESCE(try_strptime(TRIM(A.PRCH_DATE), '%d/%m/%Y'),
               try_strptime(TRIM(A.PRCH_DATE), '%d-%m-%Y')) AS DATE) AS DATE,
COALESCE(
        CASE lower(strip_accents(replace(TRIM(A.CTRY_CARD), ' ', '')))
                WHEN 'brazil' THEN 'Brazil'
                WHEN 'brasil' THEN 'Brazil'
                WHEN 'mexico' THEN 'Mexico'
                WHEN 'argentina' THEN 'Argentina'
                WHEN 'colombia' THEN 'Colombia'
                WHEN 'chile' THEN 'Chile'
                WHEN 'ecuador' THEN 'Ecuador'
                WHEN 'peru' THEN 'Peru'
                WHEN 'panama' THEN 'Panama'
                WHEN 'guatemala' THEN 'Guatemala'
                WHEN 'bolivia' THEN 'Bolivia'
                WHEN 'republicadominicana' THEN 'Republica Dominicana'
                WHEN 'elsalvador' THEN 'El Salvador'
                WHEN 'uruguay' THEN 'Uruguay'
                WHEN 'costarica' THEN 'Costa Rica'
                WHEN 'honduras' THEN 'Honduras'
                WHEN 'nicaragua' THEN 'Nicaragua'
                WHEN 'paraguay' THEN 'Paraguay'
        END,
        strip_accents(TRIM(A.CTRY_CARD))
    )                                                             AS CTRY_CARD,
COALESCE(
        CASE lower(strip_accents(replace(TRIM(A.CTRY_MRCH), ' ', '')))
                WHEN 'brazil' THEN 'Brazil'
                WHEN 'brasil' THEN 'Brazil'
                WHEN 'mexico' THEN 'Mexico'
                WHEN 'argentina' THEN 'Argentina'
                WHEN 'colombia' THEN 'Colombia'
                WHEN 'chile' THEN 'Chile'
                WHEN 'ecuador' THEN 'Ecuador'
                WHEN 'peru' THEN 'Peru'
                WHEN 'panama' THEN 'Panama'
                WHEN 'guatemala' THEN 'Guatemala'
                WHEN 'bolivia' THEN 'Bolivia'
                WHEN 'republicadominicana' THEN 'Republica Dominicana'
                WHEN 'elsalvador' THEN 'El Salvador'
                WHEN 'uruguay' THEN 'Uruguay'
                WHEN 'costarica' THEN 'Costa Rica'
                WHEN 'honduras' THEN 'Honduras'
                WHEN 'nicaragua' THEN 'Nicaragua'
                WHEN 'paraguay' THEN 'Paraguay'
        END,
        strip_accents(TRIM(A.CTRY_MRCH))
    )                                                             AS CTRY_MRCH,
MRCH ,
B.MCG_NAME 
FROM DB_TRANSAC A
LEFT JOIN MCG_LIST B 
ON  A.MCG_ID = B.MCG
;

--------------------------------------------------------------------------------------------------------
--EMPEZANDO CON EL TEST
---------------------------------------------------------------------------------------------------------
--PREGUNTA 1: Cantidad de tarjetas por tipo, que han realizado transacciones en cada trimestre.
---------------------------------------------------------------------------------------------------------
SELECT 
ANIO,
QUARTER,
PRODUCT_TYPE ,
COUNT(DISTINCT CARD_ID) AS CARDS
FROM DB_CARDS 
WHERE AMT > 0 
GROUP BY ANIO,QUARTER,PRODUCT_TYPE ;

--Comentario: Se asume que transacciones < 0 son reembolsos, por tal motivo se filtra para el análisis. Vemos un incremento de tarjetas que realizaron transacciones para el segundo trimestre

--------------------------------------------------------------------------------------------------
--PREGUNTA 2:Ticket Trimestral: Gasto promedio por tarjeta de crédito por trimestre.
---------------------------------------------------------------------------------------------------

SELECT 
ANIO,
QUARTER,
PRODUCT_TYPE ,
ROUND(SUM(AMT) / COUNT(DISTINCT CARD_ID), 2)    AS GASTO_PROM
FROM DB_CARDS 
WHERE PRODUCT_TYPE = 'Credit' and AMT > 0 
GROUP BY ANIO,QUARTER,PRODUCT_TYPE ;

--Comentario: Tenemos un mayor gasto prom por TC en el Trim2, concentrandose en los productos 4 y 5.

SELECT *  FROM DB_CARDS limit 10

SELECT 
ANIO,
QUARTER,
PRODUCT_TYPE ,
product_name,
ROUND(SUM(AMT) / COUNT(DISTINCT CARD_ID), 2)    AS GASTO_PROM
FROM DB_CARDS 
WHERE PRODUCT_TYPE = 'Credit' and AMT > 0 and quarter='T2'
GROUP BY ANIO,QUARTER,PRODUCT_TYPE, PRODUCT_NAME 
order by gasto_prom desc;


---------------------------------------------------------------------------------------------------
--PREGUNTA 3: Monto de transacción promedio de tarjetas de crédito por producto en países de Sudamérica.
---------------------------------------------------------------------------------------------------
SELECT CTRY_CARD FROM DB_CARDS GROUP BY CTRY_CARD ;

SELECT 
PRODUCT_NAME ,
ROUND(AVG(AMT),2) AS MTO_PROM,
count(*) as TRANSACCIONES
FROM DB_CARDS 
WHERE
  PRODUCT_TYPE = 'Credit'
  AND AMT > 0
  AND CTRY_CARD IN ('Peru', 'Colombia', 'Brazil', 'Chile', 'Argentina',
                    'Ecuador', 'Paraguay', 'Bolivia', 'Uruguay')
GROUP BY PRODUCT_NAME
ORDER BY PRODUCT_NAME;


--Comentario: A nivel de Sudamérica, el producto 5 tiene un ticket 15 veces mayor pero con una décima parte de transacciones, puede ser que el producto 1 sea de uso diario

-----------------------------------------------------------------------------------------
--PREGUNTA 4: Top Comercios: Ranking Top 10 de porcentaje de gasto por nombre de MCG (Merchant Category Group).
---------------------------------------------------------------------------------------------------
SELECT * FROM DB_CARDS LIMIT 10 ;

SELECT product_type, SUM(AMT) FROM DB_CARDS  WHERE AMT > 0  AND MCG_NAME IS NOT NULL group by product_type 

SELECT 
MCG_NAME,
ROUND(SUM(AMT), 2)  AS GASTO,
ROUND(100 * SUM(AMT) / (SELECT SUM(AMT) FROM DB_CARDS  WHERE AMT > 0), 2)    AS GASTO_PCT
FROM DB_CARDS 
WHERE
   AMT > 0  AND MCG_NAME IS NOT NULL
GROUP BY MCG_NAME
ORDER BY GASTO DESC
LIMIT 10;   

--Comentario: El comercio que mayor gasto tiene es Groceries and Supermarkets, con un mayor gasto en tarjetas de crédito y en el producto 4

SELECT 
product_type, product_name,
MCG_NAME,
ROUND(SUM(AMT), 2)  AS GASTO,
ROUND(100 * SUM(AMT) / (SELECT SUM(AMT) FROM DB_CARDS  WHERE AMT > 0), 2)    AS GASTO_PCT
FROM DB_CARDS 
WHERE
   AMT > 0  AND MCG_NAME =  'Groceries and Supermarkets'
GROUP BY MCG_NAME,product_type,product_name
ORDER BY GASTO DESC


-----------------------------------------------------------------------------------------
--PREGUNTA 5: Adopción Tecnológica: Porcentaje de gasto contactless ordenado por país.
---------------------------------------------------------------------------------------------------

SELECT 
CTRY_CARD ,
ROUND(SUM(AMT), 2)  AS GASTO,
ROUND(SUM(
       CASE WHEN IS_CONTACTLESS = 1 THEN AMT 
       ELSE 0  END), 2) AS GASTO_CONTACTLESS,
ROUND(100 * SUM(CASE WHEN IS_CONTACTLESS = 1 THEN AMT ELSE 0 END)  / SUM(AMT), 2)   AS CONTACTLESS_PCT
FROM DB_CARDS 
WHERE
   AMT > 0  
GROUP BY CTRY_CARD
ORDER BY CONTACTLESS_PCT DESC;

--Comentario: Los países grandes con respecto al uso de algún medio tecnológico para realizar la transacción son Mexico, Colombia, Brazil, Argentina y Chile que estàn por encima del 70%



-----------------------------
/* RETO: CAMPAÑA MAYO 2024*/ 
-----------------------------

--MASTERPLOP
--MAYO24
--TC CHILE
--PREMIO 7% CASHBACK MES, COMPRAS FUERA DE CHILE
--TOPE 50USD X TC
--Cuál es el costo total del cashback de la campaña para Masterplop? ¿A cuántas tarjetas impactó realmente?


SELECT 
COUNT(*) AS TARJETAS_IMPACTADAS,
ROUND(SUM(AMT), 2)    AS GASTO_TOT,
ROUND(SUM(LEAST(0.07 * AMT, 50)), 2)   AS CASHBACK,
SUM(
CASE WHEN 0.07 * AMT >= 50 THEN 1 ELSE 0 END
) AS TARJETAS_CON_TOPE
FROM 
(
SELECT CARD_ID, SUM(AMT) AS AMT FROM DB_CARDS
WHERE
   PRODUCT_TYPE='Credit'
 AND CTRY_CARD = 'Chile'  AND CTRY_MRCH <> 'Chile'
 AND MONTH(DATE) = 5 
 AND AMT > 0 
 GROUP BY CARD_ID
  ) 

  --Comentario: La campaña pudo llegar a más de 4 mil tarjetas impactando a 4029 tarjetas de credito.El 66% de las tarjetas estuvieron el tope del cashback.
  --      El costo total del cashback es 178.608,19 usd      
  
