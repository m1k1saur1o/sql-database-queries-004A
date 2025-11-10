-- 1

SELECT 
  CASE
    WHEN LENGTH(numrut_cli) = 7 THEN TO_CHAR(numrut_cli, '9G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' ) || '-' || dvrut_cli
    WHEN LENGTH(numrut_cli) = 8 THEN TO_CHAR(numrut_cli, '99G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' ) || '-' || dvrut_cli
    WHEN LENGTH(numrut_cli) = 9 THEN TO_CHAR(numrut_cli, '999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' ) || '-' || dvrut_cli
    END AS "RUT Cliente",
  nombre_cli || ' ' || appaterno_cli || ' ' || apmaterno_cli AS "Nombre Completo Cliente",
  direccion_cli AS "Dirección Cliente",
  TO_CHAR(renta_cli, '$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''' ) AS "Renta Cliente",
  '0' || SUBSTR(TO_CHAR(celular_cli), 1, 1) || '-' ||
    SUBSTR(TO_CHAR(celular_cli), 2, 3) || '-' ||
    SUBSTR(TO_CHAR(celular_cli), 5, 4) AS "Celular Cliente",
  CASE
    WHEN renta_cli > 500000 THEN 'TRAMO 1'
    WHEN renta_cli BETWEEN 400000 AND 500000 THEN 'TRAMO 2'
    WHEN renta_cli BETWEEN 200000 AND 399999 THEN 'TRAMO 3'
    WHEN renta_cli < 200000 THEN 'TRAMO 4'
  END AS "Trama Renta Cliente"
FROM cliente
WHERE celular_cli IS NOT NULL
  AND renta_cli BETWEEN &RENTA_MINIMA AND &RENTA_MAXIMA
ORDER BY "Nombre Completo Cliente" ASC;

-- 2

SELECT 
  id_categoria_emp AS "CODIGO_CATEGORIA",
  DECODE ( id_categoria_emp,
              1, 'Gerente',
              2, 'Supervisor',
              3, 'Ejecutivo de Arriendo',
              4, 'Auxiliar'
          ) AS "DESCRIPICION_CATEGORIA",
  COUNT(*) AS "TOTAL_EMPLEADOS",
  DECODE ( id_sucursal,
              10, 'Sucursal Las Condes',
              20, 'Sucursal Santiago Centro',
              30, 'Sucursal Providencia',
              40, 'Sucursal Vitacura'
          ) AS "SUCURSAL",
  TO_CHAR(AVG(sueldo_emp), '$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''') AS "SUELDO_PROMEDIO"
FROM empleado
GROUP BY 
  id_categoria_emp,
  DECODE ( id_categoria_emp,
              1, 'Gerente',
              2, 'Supervisor',
              3, 'Ejecutivo de Arriendo',
              4, 'Auxiliar'
          ),
  id_sucursal,
  DECODE ( id_sucursal,
              10, 'Sucursal Las Condes',
              20, 'Sucursal Santiago Centro',
              30, 'Sucursal Providencia',
              40, 'Sucursal Vitacura'
          )
HAVING AVG(sueldo_emp) > &SUELDO_PROMEDIO_MINIMO
ORDER BY "SUELDO_PROMEDIO" DESC;

--3

SELECT
  id_tipo_propiedad AS "CODIGO_TIPO",
    CASE 
      WHEN id_tipo_propiedad = 'A' THEN 'CASA'
      WHEN id_tipo_propiedad = 'B' THEN 'DEPARTAMENTO'
      WHEN id_tipo_propiedad = 'C' THEN 'LOCAL'
      WHEN id_tipo_propiedad = 'D' THEN 'PARCELA SIN CASA'
      WHEN id_tipo_propiedad = 'E' THEN 'PARCELA CON CASA'
    END AS "DESCRIPCION_TIPO",
  COUNT(*) AS "TOTAL_PROPIEDADES",
  TO_CHAR(AVG(valor_arriendo), '$999G999G999', 'NLS_NUMERIC_CHARACTERS='',.''') AS "PROMEDIO_ARRIENDO",
  TO_CHAR(AVG(superficie), '999G999D99', 'NLS_NUMERIC_CHARACTERS='',.''') AS "PROMEDIO_SUPERFICIE",
  TO_CHAR(ROUND(AVG(valor_arriendo / superficie)), '$999G999', 'NLS_NUMERIC_CHARACTERS='',.''') AS "VALOR_ARRIENDO_M2",
  CASE
    WHEN ROUND(AVG(valor_arriendo) / AVG(superficie)) < 5000 THEN 'Económico'
    WHEN ROUND(AVG(valor_arriendo) / AVG(superficie)) BETWEEN 5000 AND 10000 THEN 'Medio'
    WHEN ROUND(AVG(valor_arriendo) / AVG(superficie)) > 10000 THEN 'Alto'
  END AS "CLASIFICACION"
FROM propiedad
GROUP BY id_tipo_propiedad   
HAVING ROUND(AVG(valor_arriendo) / AVG(superficie)) > 1000
ORDER BY "VALOR_ARRIENDO_M2" DESC