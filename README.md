# Desafío Analytic Engineer – Masterplop

Análisis de transacciones de tarjetas en 17 países de América (enero a junio de 2024), con respuestas en SQL a las cinco preguntas de negocio, el reto de la campaña de cashback de mayo de 2024 y un dashboard en Power BI con la identidad visual de Masterplop.

**Repositorio:** [github.com/JoseFernandez97/Card_Performance_Artefact](https://github.com/JoseFernandez97/Card_Performance_Artefact)
**Dashboard publicado:** [Dashboard Card Performance](https://app.powerbi.com/view?r=eyJrIjoiYmJiNmM1Y2ItOGYwMC00MDUyLTk2NGEtYjYyNzYwMTZhNGMxIiwidCI6ImRmODY3OWNkLWE4MGUtNDVkOC05OWFjLWM4M2VkN2ZmOTVhMCJ9)
**Usuario:** MASTERPLOP · **Contraseña:** 2026
**Archivos:** `Desafio_Jose Fernandez.sql` (consultas) · `Dashboard Card Performance.pbix` (dashboard)

---

## Contenido del repositorio

| Archivo | Descripción |
|---|---|
| `Desafio_Jose Fernandez.sql` | Carga, limpieza y consultas de las cinco preguntas y del reto de la campaña. |
| `Dashboard Card Performance.pbix` | Dashboard de Power BI. |
| `README.md` | Este documento: decisiones, justificaciones y bitácora de uso de IA. |

---

## I. Desafío Analytics

### 1. Datos y limpieza

Se trabajó con dos archivos: `db_transac.csv` (2.400.000 transacciones) y `mcg_list.xlsx` (25 categorías de comercio).

### Perfil de calidad (antes de limpiar)

- **Vacíos y valores no convertibles:** ninguno en las 12 columnas.
- **Variantes de texto:** `product_type` tenía 6 variantes (Credit / Credito / Crédito y Debit / Debito / Débito). Los países tenían 4 pares con y sin tilde (Perú/Peru, México/Mexico, Panamá/Panama, República/Republica Dominicana) y Brasil/Brazil en español e inglés.
- **Fechas:** convivían los formatos `dd/mm/aaaa` y `dd-mm-aaaa`.
- **Código de categoría sin correspondencia:** 12.000 transacciones tienen `mcg_id = 35`, que no existe en `mcg_list`.

### Limpieza aplicada (`desafio_fernandez.sql`, sección 2)

- `product_type` se normaliza a `Credit` y `Debit` quitando espacios y tildes.
- Los países se homologan a un solo nombre en español o inglés, y se conservan los valores no reconocidos.
- Las fechas se convierten con los dos formatos y se crean `ANIO`, `QUARTER` y `DATE`.
- `MCG_NAME` se obtiene con un `LEFT JOIN` contra `mcg_list`. Los 12.000 registros sin categoría quedan con valor nulo y se muestran como "Sin dato".


---

### 2. Respuestas a las preguntas

**Criterio general:** se consideran compras solo los montos positivos (`AMT > 0`). Los montos negativos son devoluciones (2.400 filas) y se excluyen de los indicadores de gasto, no de la pregunta de volumen de tarjetas.

### Pregunta 1 – Volumen: tarjetas por tipo y trimestre

```sql
SELECT
ANIO,
QUARTER,
PRODUCT_TYPE ,
COUNT(DISTINCT CARD_ID) AS CARDS
FROM DB_CARDS
WHERE AMT > 0
GROUP BY ANIO,QUARTER,PRODUCT_TYPE ;
```

Cuenta las tarjetas distintas por año, trimestre y tipo de producto, usando solo montos positivos.

| Trimestre | Tipo | Tarjetas |
|---|---|---|
| T1 2024 | Crédito | 46.747 |
| T1 2024 | Débito | 8.224 |
| T2 2024 | Crédito | 51.037 |
| T2 2024 | Débito | 8.960 |

**Comentario:** las tarjetas de crédito activas crecen 9 % de T1 a T2, y las de débito, 9 %. Las devoluciones (`AMT < 0`) no cuentan como actividad.

### Pregunta 2 – Ticket trimestral: gasto promedio por tarjeta de crédito

```sql
SELECT
ANIO,
QUARTER,
PRODUCT_TYPE ,
ROUND(SUM(AMT) / COUNT(DISTINCT CARD_ID), 2)    AS GASTO_PROM
FROM DB_CARDS
WHERE PRODUCT_TYPE = 'Credit' and AMT > 0
GROUP BY ANIO,QUARTER,PRODUCT_TYPE ;
```

Gasto total dividido entre el número de tarjetas distintas, por trimestre.

| Trimestre | Gasto promedio por tarjeta |
|---|---|
| T1 2024 | USD 3.232,46 |
| T2 2024 | USD 5.024,57 |

**Comentario:** Tenemos un mayor gasto prom por tarjeta de crédito en el Trim2, concentrándose en los productos 4 y 5.

### Pregunta 3 – Monto promedio por producto en Sudamérica

```sql
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
```

Se filtra por país de emisión de la tarjeta (`CTRY_CARD`) en Argentina, Bolivia, Brasil, Chile, Colombia, Ecuador, Paraguay, Perú y Uruguay. Se excluyen México, Centroamérica, el Caribe y Panamá.

| Producto | Monto promedio | Transacciones |
|---|---|---|
| P1 | USD 67,72 | 487.704 |
| P2 | USD 118,46 | 410.708 |
| P3 | USD 187,15 | 282.437 |
| P4 | USD 593,29 | 139.957 |
| P5 | USD 1.010,47 | 69.399 |

**Comentario:** P5 tiene un ticket unas 15 veces mayor que P1, pero la décima parte de sus transacciones. P1 parece ser el producto de uso diario.

### Pregunta 4 – Top 10 de categorías por porcentaje de gasto

```sql
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
```

Se agrupa por `MCG_NAME`, se excluyen los nulos y el porcentaje se calcula sobre el gasto total positivo.

| Categoría | Gasto (USD) | % del gasto |
|---|---|---|
| Groceries and Supermarkets | 95.428.524 | 22,16 % |
| Restaurants and Dining | 73.724.863 | 17,12 % |
| Entertainment | 57.705.484 | 13,40 % |
| Travel and Transportation | 44.493.695 | 10,33 % |
| Clothing and Accessories | 34.928.914 | 8,11 % |
| Electronics and Appliances | 27.269.995 | 6,33 % |
| Health and Wellness | 21.230.790 | 4,93 % |
| Home Improvement | 16.437.835 | 3,82 % |
| Automotive | 12.788.960 | 2,97 % |
| Education and Books | 9.955.326 | 2,31 % |

**Comentario:** se usa categoría y no comercio porque cada comercio aparece en varias categorías. El porcentaje incluye todo el gasto positivo, así que los 10 primeros suman el 91,5 % y el resto corresponde a otras categorías.

### Pregunta 5 – Adopción tecnológica: gasto contactless por país

```sql
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
```

| País | Gasto (USD) | Gasto contactless (USD) | % contactless |
|---|---|---|---|
| Mexico | 101.846.353,7 | 71.576.648,3 | 70,28 % |
| Colombia | 50.585.354,9 | 35.530.595,3 | 70,24 % |
| Brazil | 104.058.006,4 | 72.973.291,1 | 70,13 % |
| Argentina | 77.468.241,8 | 54.265.698,6 | 70,05 % |
| Chile | 41.006.749,7 | 28.707.346,1 | 70,01 % |
| El Salvador | 2.168.038,7 | 450.531,5 | 20,78 % |
| Costa Rica | 2.193.529,5 | 445.544,3 | 20,31 % |
| Bolivia | 3.200.000,5 | 643.865,4 | 20,12 % |
| Republica Dominicana | 3.217.168,2 | 647.004,6 | 20,11 % |
| Peru | 14.357.936,1 | 2.878.721,6 | 20,05 % |
| Uruguay | 2.111.170,3 | 421.115,8 | 19,95 % |
| Ecuador | 10.143.613,9 | 2.023.358,1 | 19,95 % |
| Panama | 10.215.946,4 | 2.018.220,7 | 19,76 % |
| Nicaragua | 1.024.423,8 | 201.606,0 | 19,68 % |
| Honduras | 1.917.501,3 | 375.673,6 | 19,59 % |
| Guatemala | 4.021.793,3 | 787.560,3 | 19,58 % |
| Paraguay | 1.016.328,1 | 194.847,3 | 19,17 % |

**Comentario:** Los países grandes con respecto al uso de algún medio tecnológico para realizar la transacción son Mexico, Colombia, Brazil, Argentina y Chile que están por encima del 70%

---

### 3. Reto: campaña de cashback de mayo 2024

**Regla:** 7 % de cashback sobre las compras de tarjetas de crédito emitidas en Chile, realizadas en comercios fuera de Chile en mayo de 2024, con tope de USD 50 por tarjeta.

### Consulta

```sql
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
```

**Comentario:** La campaña pudo llegar a más de 4 mil tarjetas impactando a 4029 tarjetas de crédito. El 66% de las tarjetas estuvieron en el tope del cashback. El costo total del cashback es 178.608,19 usd.

### Resultados

| Indicador | Valor |
|---|---|
| Tarjetas impactadas | **4.029** |
| Compras elegibles | USD 7.327.231,90 |
| **Costo total del cashback** | **USD 178.608,19** |
| Tarjetas que llegaron al tope | 2.681 (66,5 %) |
| Costo sin tope (7 % plano) | USD 512.906 |
| Ahorro por el tope | USD 334.298 |
| Cashback efectivo sobre compras | 2,44 % |

### Cómo se calcula

1. Se suman las compras positivas de cada tarjeta que cumple la regla.
2. Se aplica `MIN(50, 0,07 × compra)` a cada tarjeta.
3. Se suma el resultado de todas las tarjetas.

### Lectura para el negocio

- El costo es bajo porque el tope limita el premio a las tarjetas con mayor gasto. Dos de cada tres tarjetas lo alcanzaron.

---

## II. Los datos y la marca

### 4. Dashboard

El dashboard tiene una portada de presentación y tres páginas: **Home**, **Overview** y **Details**. Usa la identidad visual de Masterplop (azul `#1A56DB`, amarillo `#FBBF24`, morado `#7C3AED`).

- **Portada:** pantalla de inicio con campo de contraseña. Es parte del diseño de presentación, no un mecanismo de seguridad. Las páginas se ocultan visualmente, y el botón de ingreso se activa solo con la contraseña correcta.
- **Overview:** tarjetas, monto, transacciones, contactless y devoluciones, con tablas y gráficos por país, tipo de tarjeta y producto.
- **Details:** análisis por categoría, devoluciones y campaña de cashback. La página muestra también el resultado de la campaña: costo total, tarjetas impactadas y porcentaje de tarjetas con tope.

Todos los datos son ficticios y provienen del desafío.

Para abrirlo, instala Power BI Desktop (gratuito) y abre `Dashboard Card Performance.pbix` con doble clic.

### Proceso de diseño

1. **Referencia de estructura:** se usó el [Property Management Dashboard de Microsoft Fabric Community](https://community.fabric.microsoft.com/discussions/ThemesGallery/property-management-dashboard/5376950) como base de distribución regional, navegación y jerarquía visual.
2. **Paleta:** se partió de los colores oficiales del logo y se usó [paletadecolores.org](https://paletadecolores.org/paleta-desde-imagen.html) para extraer una paleta completa a partir de ellos. Paleta final: `#1A56DB` (azul, confianza), `#FBBF24` (amarillo, transacciones rápidas), `#7C3AED` (morado, innovación), `#295F94` (navy) y `#779ADA` (azul claro).
3. **Inspiración visual:** la [página de reportes y ebooks de Artefact](https://www.artefact.com/es/insights/reports/) se usó como referencia de estilo, tipografía y tono ejecutivo.
4. **Brief de diseño:** el mockup se construyó a partir de un prompt de especificación que pedía fondo blanco o gris muy claro, navegación vertical (Home, Overview, Details), filtros en un panel lateral, máximo 6 KPIs por página, tablas ejecutivas y tooltips para análisis adicional.
5. **Criterio de lectura:** cada página debe responder en menos de 10 segundos qué pasa, qué cambió, dónde está el riesgo, qué requiere acción y dónde profundizar.

---

## III. AI Log

Herramienta utilizada: Claude.

| Prompt (resumido) | Problema que resolvió | Qué aportó el modelo |
|---|---|---|
| Perfil de calidad de datos sobre `db_transac` | No sabía qué revisar antes de limpiar | Propuso revisar vacíos, variantes, coherencia entre columnas y estadísticas de montos |
| Revisar el SQL de la campaña | Filtro por mes sin año | Propuso un CTE con rango de fechas |
| Diseñar el tooltip de Power BI | Texto cortado en 320 × 240 | Propuso una estructura compacta y ajusté los espaciados |
| Diseñar el dashboard a partir de un brief de marca y una plantilla de Microsoft | Necesitaba distribución, paleta y navegación coherentes con la marca | Propuso la estructura por páginas, la paleta completa a partir de los colores del logo y la distribución de KPIs, tablas y gráficos |
| Crear en el modelo las tablas LOGIN y Calendario, la columna Región y las medidas generales | Necesitaba preparar el modelo para el dashboard sin escribir cada paso a mano | Propuso cada objeto con su DAX y verificó cada resultado con una consulta |

**Qué aprendí:** la IA ayuda a encontrar errores de lógica en DAX y SQL, pero cada resultado lo verifiqué contra los datos. Los supuestos de negocio, como la tasa de intercambio, deben confirmarse con el equipo.

---

### Prompts utilizados

**1. Perfil de calidad de datos** (antes de limpiar):

<details>
<summary>Ver prompt</summary>

```text
Actúa como analista de calidad de datos. Te paso las columnas de una tabla "db_transac":
card_id: Número único de tarjeta
product_name: Nombre del producto (Tarjeta)
product_type: Tipo de producto (Crédito, Débito o Prepago)
amt: Monto de la transacción en USD
is_xb: Indicador (flag) que es 1 cuando la transacción es internacional
is_contactless: Indicador (flag) que es 1 cuando la transacción fue usando tecnología contactless
prch_date: Fecha de la transacción
prch_time: Hora de la transacción
ctry_card: País de emisión de la tarjeta
ctry_mrch: País donde se realizó la compra (país del comercio)
mrch: Nombre del comercio
mcg_id: Identificador de MCG (Merchant Category Group o Código de Categoría del Comercio)

Hay una tabla dimensión "mcg_list" con los siguientes campos:
mcg: Identificador de MCG (Merchant Category Group o Código de Categoría del Comercio)
mcg_name: Nombre de la categoría del comercio

Para cada columna: (1) cuenta valores vacíos y valores no convertibles a su tipo esperado; (2) si es categórica, lista todos los valores distintos con su frecuencia; (3) detecta valores que sean iguales al normalizar (minúsculas, sin acentos, sin espacios) o que tengan variantes de idioma; (4) para cada par de columnas que deberían ser coherentes entre sí, mide qué porcentaje de filas se contradice. Para columnas numéricas, reporta mínimo, máximo, mediana, percentiles 1 y 99, cantidad de negativos y cantidad de valores fuera de 1,5 veces el rango intercuartílico. No propongas reglas de limpieza: solo muestra los hallazgos con sus conteos.
```

</details>

**2. Prompt de diseño del dashboard** (con el brief de marca y la referencia de Microsoft):

<details>
<summary>Ver prompt</summary>

```text
Eres un especialista senior en Power BI, Business Intelligence, UX Analytics, Data Visualization y Storytelling Ejecutivo. Diseñas reportes y dashboards para VP, gerencias y comités, siguiendo el estilo visual corporativo del equipo.

Para diseñar la propuesta del dashboard, genera una idea de mockup, diseño, distribución del mockup utiliza la imagen adjunta de un dashboard utiliza como referencia la imagen adjunta: property management dashboard en power bi. Úsala como base principal, respeta su estilo, distribución regional y por países, navegación y jerarquía. Adicionalmente, te adjunto la interfaz de inicio de sesión, la primera página del dashboard ya creada para que continúes con la paleta de colores aplicada en el resto de páginas.

Además, utiliza el archivo CSV adjunto como base y mantén la lógica del negocio.

Mejora solo experiencia visual, navegación, distribución, espacio, storytelling y eficiencia de lectura. No cambies la esencia del diseño si ya tiene un estilo corporativo definido.

Sigue el siguiente estándar visual corporativo de la marca: MASTERPLOP, logo adjunto.
La marca utiliza los principales colores que tienen un significado:
- Azul: #1A56DB (Confianza y seguridad)
- Amarillo: #FBBF24 (Energía y transacciones rápidas)
- Morado: #7C3AED (Innovación tecnológica)

Con estos principales colores utiliza esta paleta: #1A56DB, #7C3AED, #FBBF24, #295F94, #779ADA.

- El equipo solicitante es de Marketing, utiliza UX y UI para el desarrollo del dashboard, deberán reflejar la identidad visual y el buen ambiente que existe dentro.
- Fondo blanco o gris muy claro.
- Encabezado superior limpio con logo Masterplop o corporativo a la izquierda.
- Título principal con subtítulo ejecutivo debajo.
- Navegación superior entre vistas: pestaña activa y pestañas secundarias (podría ir como un panel de navegación a la izquierda).
- Filtros ocultos en un panel lateral (a la derecha), con ícono de filtro visible, contador de filtros aplicados y un componente "Filtro aplicado / Filtros aplicados".
- KPIs compactos (máximo 6 por página).
- Tablas ejecutivas financieras.
- Gráficos funcionales, que apliquen UX y UI; evalúa realizar los gráficos con HTML.
- Bordes suaves gris claro. Encabezados por bloque.
- Tooltips para análisis adicional y drill-through para detalle.
- Colores: blanco, gris claro, gris oscuro para texto, rojo suave para alertas relevantes. Semáforos solo cuando aporten valor.
- Panel de navegación vertical a la izquierda del lienzo. Que sean las páginas Home, Overview, Details.
- Diseño ejecutivo y limpio, con máximo aprovechamiento del espacio.

Evita: exceso de tarjetas, exceso de colores, gráficos decorativos, diseños recargados, demasiadas páginas, duplicidad de información y visuales que no ayuden a decidir.

El objetivo de lectura de esta propuesta debe responder en menos de 10 segundos:
1. ¿Qué está pasando?
2. ¿Qué cambió?
3. ¿Dónde está el riesgo?
4. ¿Qué requiere acción?
5. ¿Dónde puedo profundizar?

Como metodología ten en cuenta estos puntos:
1. Entendimiento del negocio: objetivo, audiencia, decisiones que soporta, KPIs principales y secundarios, indicadores operativos, alertas, campañas, riesgos y nivel de detalle. Si falta información, infiere una propuesta base razonable sin preguntar más.
2. Estructura: define para cada página su nombre ejecutivo, objetivo, orden, navegación, botones, drill-through, tooltips, visuales principales y KPIs visibles.

Para el entregable final, el resultado siempre debe incluir una representación visual tipo mockup en Power BI, limpia, ejecutiva y alineada al estándar del equipo.
1. Diagnóstico general
2. Hallazgos principales: Volumen, Ticket Trimestral, Ticket Regional, Top Comercios y Adopción Tecnológica.
3. Estructura recomendada del dashboard
4. Nombre ejecutivo de cada vista
5. Layout recomendado por vista
6. Recomendaciones de tooltips
7. Recomendaciones de drill-through
8. Wireframe textual (encabezado, logo o placeholder, título, subtítulo, navegación, panel de filtros, KPIs, visual principal, tabla, alertas, botones, drill-through y tooltips)
```

</details>

**3. Conexión y medidas en Power BI Desktop (MCP):**

```text
Conéctate al reporte de Power BI Desktop que tienes abierto.

CREA UNA TABLA DIMENSION CON LOS CAMPOS USER Y PASS Y COMO REGISTROS QUE SEA MASTERPLOP Y 2026. RENOMBRA LA TABLA A LOGIN

CREA UNA TABLA CALENDARIO DONDE TOMES LA MINIMA Y MAXIMA FECHA DE LA TABLA: DB_CARDS_202611061020

CREA UNA MEDIDA EN LA TABLA MEDIDAS_DAX: Olvidaste tu contraseña? , NOMBRAS A LA MEDIDA: CONTRA_TEXTO

en la tabla medidas_dax. crea las siguientes medidas:
Monto_trx = suma del campo amt
Nro_tarjetas = un conteo unico de las card_id
Prom_amt = promedio del campo amt

crea una columna calculada Region en la tabla DB_CARDS_202611061020. en funcion al campo ctry_card cuando sea igual a Peru, Colombia, Brazil, Chile, Argentina, Ecuador, Paraguay, Bolivia o Uruguay sea igual a Sudamerica, cuando sea igual a Mexico y Republica Dominicana debera ser Norteamerica y los otros paises debera ser igual a Centroamerica
```

## IV. Cómo ejecutar las consultas

1. Instala [DBeaver](https://dbeaver.io/) o usa Python con `pip install duckdb pandas`.
2. Abre `Desafio_Jose Fernandez.sql`.
3. Cambia la ruta de `read_csv_auto` por la de tu `db_transac.csv`.
4. Ejecuta las secciones en orden: carga, limpieza y preguntas.
